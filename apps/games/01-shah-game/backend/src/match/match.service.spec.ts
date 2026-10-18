import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Test, type TestingModule } from '@nestjs/testing';
import { REDIS_CLIENT } from '../redis/redis.constants';
import { PrismaService } from '../prisma/prisma.service';
import { MatchService } from './match.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  match: {
    create: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  matchPlayer: {
    create: jest.fn(),
    findFirst: jest.fn(),
    findMany: jest.fn(),
    delete: jest.fn(),
    deleteMany: jest.fn(),
  },
  $queryRaw: jest.fn(),
  $transaction: jest.fn(),
};

const mockRedis = {
  set: jest.fn(),
  get: jest.fn(),
  del: jest.fn(),
  scan: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const HOST_ID = 'host-uuid';
const PLAYER_ID = 'player-uuid';
const MATCH_ID = 'match-uuid';
const ROOM_CODE = 'ABCD';

const baseMatch = {
  id: MATCH_ID,
  roomCode: ROOM_CODE,
  hostPlayerId: HOST_ID,
  status: 'lobby' as const,
  playerCount: 1,
  startedAt: null,
  endedAt: null,
};

function buildMatchWithPlayers(
  players = [{ playerId: HOST_ID, displayName: 'Alice', seatIndex: 0 }],
) {
  return {
    ...baseMatch,
    playerCount: players.length,
    matchPlayers: players.map((p) => ({
      matchId: MATCH_ID,
      playerId: p.playerId,
      seatIndex: p.seatIndex,
      joinedAt: new Date(),
      player: { displayName: p.displayName },
    })),
  };
}

const GAME_ID = 'game-uuid';

/** Four-player in-progress match with one finished game */
function buildFinishedMatch(
  players = [
    { playerId: HOST_ID, displayName: 'Alice', seatIndex: 0 },
    { playerId: PLAYER_ID, displayName: 'Bob', seatIndex: 1 },
    { playerId: 'p2', displayName: 'Carol', seatIndex: 2 },
    { playerId: 'p3', displayName: 'Dave', seatIndex: 3 },
  ],
) {
  return {
    ...baseMatch,
    status: 'in_progress' as const,
    playerCount: players.length,
    matchPlayers: players.map((p) => ({
      matchId: MATCH_ID,
      playerId: p.playerId,
      seatIndex: p.seatIndex,
      joinedAt: new Date(),
      player: { displayName: p.displayName },
    })),
    games: [
      {
        id: GAME_ID,
        gameNumber: 1,
        direction: 'asc',
        status: 'finished',
        startedAt: new Date(),
        endedAt: new Date(),
        gameRankings: players.map((p, i) => ({
          playerId: p.playerId,
          finishRank: i + 1,
          player: { displayName: p.displayName },
        })),
      },
    ],
  };
}

// ─── Suite ────────────────────────────────────────────────────────────────────

describe('MatchService', () => {
  let service: MatchService;

  beforeEach(async () => {
    jest.clearAllMocks();
    mockRedis.set.mockResolvedValue('OK');
    mockRedis.get.mockResolvedValue(null);
    mockRedis.del.mockResolvedValue(1);
    mockRedis.scan.mockResolvedValue(['0', []]); // default: no hand keys found
    mockPrisma.$queryRaw.mockResolvedValue([{ player_count: 1 }]);
    mockPrisma.matchPlayer.findMany.mockResolvedValue([]);
    mockPrisma.$transaction.mockImplementation(
      async (
        ops:
          | Array<Promise<unknown>>
          | ((tx: typeof mockPrisma) => Promise<unknown>),
      ) => {
        if (typeof ops === 'function') {
          // Interactive transaction — pass mockPrisma as the transaction client
          return ops(mockPrisma);
        }
        return Promise.all(ops);
      },
    );

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MatchService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: REDIS_CLIENT, useValue: mockRedis },
      ],
    }).compile();

    service = module.get<MatchService>(MatchService);
  });

  // ─── generateRoomCode ───────────────────────────────────────────────────────

  describe('generateRoomCode', () => {
    const VALID_CHARS = new Set('ABCDEFGHJKLMNPQRSTUVWXYZ23456789');

    it('returns a 4-character code', () => {
      const code = service.generateRoomCode();
      expect(code).toHaveLength(4);
    });

    it('only uses valid characters (no 0, 1, O, I)', () => {
      for (let i = 0; i < 100; i++) {
        const code = service.generateRoomCode();
        for (const char of code) {
          expect(VALID_CHARS.has(char)).toBe(true);
        }
      }
    });

    it('generates different codes (probabilistically)', () => {
      const codes = new Set(
        Array.from({ length: 20 }, () => service.generateRoomCode()),
      );
      expect(codes.size).toBeGreaterThan(1);
    });
  });

  // ─── createMatch ────────────────────────────────────────────────────────────

  describe('createMatch', () => {
    it('creates a match and stores state in Redis (happy path)', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(null); // code is unique
      mockPrisma.match.create.mockResolvedValue(baseMatch);

      const result = await service.createMatch(HOST_ID, 'Alice');

      expect(mockPrisma.match.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            hostPlayerId: HOST_ID,
            status: 'lobby',
            playerCount: 1,
          }),
        }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        `match:${MATCH_ID}:state`,
        expect.any(String),
        'EX',
        86400,
      );
      expect(result.hostPlayerId).toBe(HOST_ID);
      expect(result.players).toHaveLength(1);
      expect(result.players[0].displayName).toBe('Alice');
    });

    it('retries code generation on collision and succeeds on 3rd attempt', async () => {
      const fakeExistingMatch = { ...baseMatch };
      mockPrisma.match.findUnique
        .mockResolvedValueOnce(fakeExistingMatch) // 1st code taken
        .mockResolvedValueOnce(fakeExistingMatch) // 2nd code taken
        .mockResolvedValue(null); // 3rd code free
      mockPrisma.match.create.mockResolvedValue(baseMatch);

      const result = await service.createMatch(HOST_ID, 'Alice');

      expect(mockPrisma.match.findUnique).toHaveBeenCalledTimes(3);
      expect(result.id).toBe(MATCH_ID);
    });

    it('throws ConflictException when all retry attempts fail', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(baseMatch); // always collides

      await expect(service.createMatch(HOST_ID, 'Alice')).rejects.toThrow(
        ConflictException,
      );
    });
  });

  // ─── joinMatch ──────────────────────────────────────────────────────────────

  describe('joinMatch', () => {
    it('adds a player and returns updated state (happy path)', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(buildMatchWithPlayers());
      mockPrisma.matchPlayer.findFirst.mockResolvedValue(null);
      mockPrisma.matchPlayer.create.mockResolvedValue({});
      mockPrisma.match.update.mockResolvedValue({});
      // Interactive transaction: $queryRaw returns locked player_count=1,
      // findMany returns Alice + Bob after the insert
      mockPrisma.$queryRaw.mockResolvedValue([{ player_count: 1 }]);
      mockPrisma.matchPlayer.findMany.mockResolvedValue([
        {
          matchId: MATCH_ID,
          playerId: HOST_ID,
          seatIndex: 0,
          joinedAt: new Date(),
          player: { displayName: 'Alice' },
        },
        {
          matchId: MATCH_ID,
          playerId: PLAYER_ID,
          seatIndex: 1,
          joinedAt: new Date(),
          player: { displayName: 'Bob' },
        },
      ]);

      const result = await service.joinMatch(ROOM_CODE, PLAYER_ID, 'Bob');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(result.players).toHaveLength(2);
      expect(result.players[1].displayName).toBe('Bob');
      expect(result.playerCount).toBe(2);
    });

    it('throws NotFoundException when room does not exist', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(null);

      await expect(service.joinMatch('ZZZZ', PLAYER_ID, 'Bob')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('throws ConflictException when match is in_progress', async () => {
      mockPrisma.match.findUnique.mockResolvedValue({
        ...buildMatchWithPlayers(),
        status: 'in_progress',
      });

      await expect(
        service.joinMatch(ROOM_CODE, PLAYER_ID, 'Bob'),
      ).rejects.toThrow(ConflictException);
    });

    it('throws ConflictException when room is full (8 players)', async () => {
      const eightPlayers = Array.from({ length: 8 }, (_, i) => ({
        playerId: `p${i}`,
        displayName: `Player${i}`,
        seatIndex: i,
      }));
      mockPrisma.match.findUnique.mockResolvedValue(
        buildMatchWithPlayers(eightPlayers),
      );

      await expect(
        service.joinMatch(ROOM_CODE, 'new-player', 'New'),
      ).rejects.toThrow(ConflictException);
    });

    it('returns current state when player is already in room (idempotent)', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(buildMatchWithPlayers());

      const result = await service.joinMatch(ROOM_CODE, HOST_ID, 'Alice');
      // Should return the existing state rather than throwing
      expect(result.players.some((p) => p.playerId === HOST_ID)).toBe(true);
      // Should NOT create a new matchPlayer row
      expect(mockPrisma.matchPlayer.create).not.toHaveBeenCalled();
    });
  });

  // ─── leaveMatch ─────────────────────────────────────────────────────────────

  describe('leaveMatch', () => {
    it('removes the player and updates state', async () => {
      const twoPlayerMatch = buildMatchWithPlayers([
        { playerId: HOST_ID, displayName: 'Alice', seatIndex: 0 },
        { playerId: PLAYER_ID, displayName: 'Bob', seatIndex: 1 },
      ]);
      mockPrisma.match.findUnique.mockResolvedValue(twoPlayerMatch);
      mockPrisma.matchPlayer.delete.mockResolvedValue({});
      mockPrisma.match.update.mockResolvedValue({});

      await service.leaveMatch(MATCH_ID, PLAYER_ID);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockRedis.set).toHaveBeenCalled();
    });

    it('migrates host to next-seat player when host leaves', async () => {
      const twoPlayerMatch = buildMatchWithPlayers([
        { playerId: HOST_ID, displayName: 'Alice', seatIndex: 0 },
        { playerId: PLAYER_ID, displayName: 'Bob', seatIndex: 1 },
      ]);
      mockPrisma.match.findUnique.mockResolvedValue(twoPlayerMatch);
      mockPrisma.matchPlayer.delete.mockResolvedValue({});
      mockPrisma.match.update.mockResolvedValue({});

      await service.leaveMatch(MATCH_ID, HOST_ID);

      // The update should set the newHostId to PLAYER_ID (next seat)
      expect(mockPrisma.$transaction).toHaveBeenCalled();
      const redisPayload = JSON.parse(
        (mockRedis.set.mock.calls[0] as string[])[1],
      ) as { hostPlayerId: string };
      expect(redisPayload.hostPlayerId).toBe(PLAYER_ID);
    });

    it('deletes match entirely when last player leaves', async () => {
      const singleMatch = buildMatchWithPlayers([
        { playerId: HOST_ID, displayName: 'Alice', seatIndex: 0 },
      ]);
      mockPrisma.match.findUnique.mockResolvedValue(singleMatch);
      mockPrisma.matchPlayer.deleteMany.mockResolvedValue({});
      mockPrisma.match.delete.mockResolvedValue({});

      await service.leaveMatch(MATCH_ID, HOST_ID);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
      expect(mockRedis.del).toHaveBeenCalledWith(`match:${MATCH_ID}:state`);
      expect(mockRedis.set).not.toHaveBeenCalled();
    });

    it('throws NotFoundException for unknown match', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(null);

      await expect(service.leaveMatch(MATCH_ID, HOST_ID)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── startMatch ─────────────────────────────────────────────────────────────

  describe('startMatch', () => {
    it('transitions status to in_progress (happy path, 4 players)', async () => {
      const fourPlayers = Array.from({ length: 4 }, (_, i) => ({
        playerId: i === 0 ? HOST_ID : `p${i}`,
        displayName: `Player${i}`,
        seatIndex: i,
      }));
      mockPrisma.match.findUnique.mockResolvedValue(
        buildMatchWithPlayers(fourPlayers),
      );
      mockPrisma.match.update.mockResolvedValue({});

      const result = await service.startMatch(MATCH_ID, HOST_ID);

      expect(mockPrisma.match.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: 'in_progress' }),
        }),
      );
      expect(result.status).toBe('in_progress');
    });

    it('throws ForbiddenException when non-host tries to start', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(buildMatchWithPlayers());

      await expect(service.startMatch(MATCH_ID, 'not-host')).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('throws ConflictException when fewer than 4 players', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(buildMatchWithPlayers());

      await expect(service.startMatch(MATCH_ID, HOST_ID)).rejects.toThrow(
        ConflictException,
      );
    });
  });

  // ─── endMatch ───────────────────────────────────────────────────────────────

  describe('endMatch', () => {
    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('marks match as finished and returns standings (happy path)', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(buildFinishedMatch());
      mockPrisma.match.update.mockResolvedValue({});

      const result = await service.endMatch(MATCH_ID, HOST_ID);

      expect(mockPrisma.match.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: 'finished' }),
        }),
      );
      expect(result.matchId).toBe(MATCH_ID);
      expect(result.totalGames).toBe(1);
      expect(result.standings).toHaveLength(4);
      // Alice ranked 1st in the only game → should lead standings
      expect(result.standings[0].playerId).toBe(HOST_ID);
      expect(result.standings[0].wins).toBe(1);
    });

    it('throws NotFoundException for unknown match', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(null);

      await expect(service.endMatch(MATCH_ID, HOST_ID)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('throws ConflictException when match is already finished', async () => {
      mockPrisma.match.findUnique.mockResolvedValue({
        ...buildFinishedMatch(),
        status: 'finished',
      });

      await expect(service.endMatch(MATCH_ID, HOST_ID)).rejects.toThrow(
        ConflictException,
      );
    });

    it('throws ForbiddenException when non-host tries to end', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(buildFinishedMatch());

      await expect(service.endMatch(MATCH_ID, 'not-host')).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('sets bestFinish to 0 when player has no game rankings', async () => {
      const matchWithoutGames = {
        ...buildFinishedMatch(),
        games: [],
      };
      mockPrisma.match.findUnique.mockResolvedValue(matchWithoutGames);
      mockPrisma.match.update.mockResolvedValue({});

      const result = await service.endMatch(MATCH_ID, HOST_ID);

      expect(result.standings.every((s) => s.bestFinish === 0)).toBe(true);
      expect(result.standings.every((s) => s.gamesPlayed === 0)).toBe(true);
    });
  });

  // ─── getMatchSummary ─────────────────────────────────────────────────────────

  describe('getMatchSummary', () => {
    it('returns full summary for a participant (happy path)', async () => {
      mockPrisma.match.findUnique.mockResolvedValue({
        ...buildFinishedMatch(),
        status: 'finished',
        createdAt: new Date('2024-01-01'),
        endedAt: new Date('2024-01-02'),
      });

      const result = await service.getMatchSummary(MATCH_ID, HOST_ID);

      expect(result.matchId).toBe(MATCH_ID);
      expect(result.games).toHaveLength(1);
      expect(result.aggregate).toHaveLength(4);
      expect(result.aggregate[0].playerId).toBe(HOST_ID);
      expect(result.aggregate[0].wins).toBe(1);
    });

    it('throws NotFoundException for unknown match', async () => {
      mockPrisma.match.findUnique.mockResolvedValue(null);

      await expect(
        service.getMatchSummary(MATCH_ID, HOST_ID),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ForbiddenException when caller is not a participant', async () => {
      mockPrisma.match.findUnique.mockResolvedValue({
        ...buildFinishedMatch(),
        createdAt: new Date(),
        endedAt: null,
      });

      await expect(
        service.getMatchSummary(MATCH_ID, 'outsider-id'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // ─── getMatch ────────────────────────────────────────────────────────────────

  describe('getMatch', () => {
    it('returns cached state from Redis', async () => {
      const cachedState = JSON.stringify({
        id: MATCH_ID,
        roomCode: ROOM_CODE,
        players: [],
      });
      mockRedis.get.mockResolvedValue(cachedState);

      const result = await service.getMatch(MATCH_ID);

      expect(result.id).toBe(MATCH_ID);
      expect(mockPrisma.match.findUnique).not.toHaveBeenCalled();
    });

    it('falls back to DB when Redis cache is empty', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.match.findUnique.mockResolvedValue(buildMatchWithPlayers());

      const result = await service.getMatch(MATCH_ID);

      expect(mockPrisma.match.findUnique).toHaveBeenCalled();
      expect(result.id).toBe(MATCH_ID);
    });

    it('throws NotFoundException when match not in Redis or DB', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.match.findUnique.mockResolvedValue(null);

      await expect(service.getMatch('unknown-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
