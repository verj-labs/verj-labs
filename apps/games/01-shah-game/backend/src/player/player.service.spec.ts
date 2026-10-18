import { Test, type TestingModule } from '@nestjs/testing';
import { type Player } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PlayerService } from './player.service';

const mockPrismaService = {
  player: {
    create: jest.fn(),
    findUnique: jest.fn(),
  },
  match: {
    findMany: jest.fn(),
    count: jest.fn(),
  },
};

const mockPlayer: Player = {
  id: 'uuid-1',
  displayName: 'Alice',
  sessionToken: 'token-abc',
  createdAt: new Date(),
};

const PLAYER_ID = 'uuid-1';
const NOW = new Date('2026-03-01T00:00:00Z');

describe('PlayerService', () => {
  let service: PlayerService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlayerService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<PlayerService>(PlayerService);
  });

  describe('createPlayer', () => {
    it('inserts a record and returns it (happy path)', async () => {
      mockPrismaService.player.create.mockResolvedValue(mockPlayer);

      const result = await service.createPlayer('Alice', 'token-abc');

      expect(mockPrismaService.player.create).toHaveBeenCalledWith({
        data: { displayName: 'Alice', sessionToken: 'token-abc' },
      });
      expect(result).toEqual(mockPlayer);
    });

    it('propagates persistence errors', async () => {
      mockPrismaService.player.create.mockRejectedValue(
        new Error('DB connection failed'),
      );

      await expect(service.createPlayer('Alice', 'token-abc')).rejects.toThrow(
        'DB connection failed',
      );
    });
  });

  describe('findById', () => {
    it('returns the player when found (happy path)', async () => {
      mockPrismaService.player.findUnique.mockResolvedValue(mockPlayer);

      const result = await service.findById('uuid-1');

      expect(mockPrismaService.player.findUnique).toHaveBeenCalledWith({
        where: { id: 'uuid-1' },
      });
      expect(result).toEqual(mockPlayer);
    });

    it('returns null for unknown IDs (does not throw)', async () => {
      mockPrismaService.player.findUnique.mockResolvedValue(null);

      const result = await service.findById('unknown-id');

      expect(result).toBeNull();
    });
  });

  describe('findByToken', () => {
    it('returns the player when the session token matches (happy path)', async () => {
      mockPrismaService.player.findUnique.mockResolvedValue(mockPlayer);

      const result = await service.findByToken('token-abc');

      expect(mockPrismaService.player.findUnique).toHaveBeenCalledWith({
        where: { sessionToken: 'token-abc' },
      });
      expect(result).toEqual(mockPlayer);
    });

    it('returns null for an unknown session token (does not throw)', async () => {
      mockPrismaService.player.findUnique.mockResolvedValue(null);

      const result = await service.findByToken('no-such-token');

      expect(result).toBeNull();
    });
  });

  // ─── getMatchHistory ─────────────────────────────────────────────────────────

  describe('getMatchHistory', () => {
    function buildMatch(overrides: {
      id?: string;
      gamesPlayed?: number;
      bestRank?: number | null;
      status?: 'lobby' | 'in_progress' | 'finished';
      playerCount?: number;
    } = {}) {
      const gamesPlayed = overrides.gamesPlayed ?? 2;
      const bestRank = overrides.bestRank ?? 1;
      return {
        id: overrides.id ?? 'match-1',
        roomCode: 'ABCD',
        status: overrides.status ?? ('finished' as const),
        createdAt: NOW,
        _count: { matchPlayers: overrides.playerCount ?? 4 },
        games: Array.from({ length: gamesPlayed }, (_, i) => ({
          id: `game-${i}`,
          gameRankings:
            bestRank !== null
              ? [{ finishRank: bestRank + i }]
              : [],
        })),
      };
    }

    it('returns paginated history with correct shape (happy path)', async () => {
      const match = buildMatch({ gamesPlayed: 2, bestRank: 1 });
      mockPrismaService.match.findMany.mockResolvedValue([match]);
      mockPrismaService.match.count.mockResolvedValue(1);

      const result = await service.getMatchHistory(PLAYER_ID, 1, 10);

      expect(result.total).toBe(1);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
      expect(result.items).toHaveLength(1);
      expect(result.items[0]).toMatchObject({
        matchId: 'match-1',
        roomCode: 'ABCD',
        playerCount: 4,
        gamesPlayed: 2,
        bestFinish: 1,
        status: 'finished',
        createdAt: NOW.toISOString(),
      });
    });

    it('returns empty items list for a player with no matches', async () => {
      mockPrismaService.match.findMany.mockResolvedValue([]);
      mockPrismaService.match.count.mockResolvedValue(0);

      const result = await service.getMatchHistory(PLAYER_ID, 1, 10);

      expect(result.total).toBe(0);
      expect(result.items).toHaveLength(0);
    });

    it('sets bestFinish to null when no games have been played', async () => {
      const match = buildMatch({ gamesPlayed: 0, bestRank: null });
      mockPrismaService.match.findMany.mockResolvedValue([match]);
      mockPrismaService.match.count.mockResolvedValue(1);

      const result = await service.getMatchHistory(PLAYER_ID, 1, 10);

      expect(result.items[0].bestFinish).toBeNull();
    });

    it('picks the lowest finish rank across multiple games', async () => {
      const match = {
        ...buildMatch({ gamesPlayed: 0 }),
        games: [
          { id: 'g1', gameRankings: [{ finishRank: 3 }] },
          { id: 'g2', gameRankings: [{ finishRank: 1 }] },
          { id: 'g3', gameRankings: [{ finishRank: 2 }] },
        ],
      };
      mockPrismaService.match.findMany.mockResolvedValue([match]);
      mockPrismaService.match.count.mockResolvedValue(1);

      const result = await service.getMatchHistory(PLAYER_ID, 1, 10);

      expect(result.items[0].bestFinish).toBe(1);
    });

    it('paginates correctly: page 2 with limit 10 uses skip=10', async () => {
      mockPrismaService.match.findMany.mockResolvedValue([]);
      mockPrismaService.match.count.mockResolvedValue(15);

      const result = await service.getMatchHistory(PLAYER_ID, 2, 10);

      expect(mockPrismaService.match.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 10, take: 10 }),
      );
      expect(result.page).toBe(2);
      expect(result.total).toBe(15);
    });
  });
});
