import { Test, type TestingModule } from '@nestjs/testing';
import { type Request } from 'express';
import { PlayerController } from './player.controller';
import { type MatchHistoryPage, PlayerService } from './player.service';

const mockPlayerService = {
  getMatchHistory: jest.fn(),
};

const mockRequest = (playerId: string) =>
  ({ user: { playerId } }) as unknown as Request;

describe('PlayerController', () => {
  let controller: PlayerController;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PlayerController],
      providers: [{ provide: PlayerService, useValue: mockPlayerService }],
    }).compile();

    controller = module.get<PlayerController>(PlayerController);
  });

  // ─── GET /player/me/matches ──────────────────────────────────────────────────

  describe('GET /player/me/matches', () => {
    const mockPage: MatchHistoryPage = {
      total: 2,
      page: 1,
      limit: 10,
      items: [
        {
          matchId: 'm1',
          roomCode: 'ABCD',
          playerCount: 4,
          gamesPlayed: 3,
          bestFinish: 1,
          status: 'finished',
          createdAt: new Date().toISOString(),
        },
        {
          matchId: 'm2',
          roomCode: 'EFGH',
          playerCount: 5,
          gamesPlayed: 1,
          bestFinish: 2,
          status: 'finished',
          createdAt: new Date().toISOString(),
        },
      ],
    };

    it('returns paginated history for the authenticated player (happy path)', async () => {
      mockPlayerService.getMatchHistory.mockResolvedValue(mockPage);

      const result = await controller.getMatchHistory(
        mockRequest('player-1'),
        { page: 1, limit: 10 },
      );

      expect(mockPlayerService.getMatchHistory).toHaveBeenCalledWith(
        'player-1',
        1,
        10,
      );
      expect(result.total).toBe(2);
      expect(result.items).toHaveLength(2);
    });

    it('uses defaults (page=1, limit=10) when no query params provided', async () => {
      mockPlayerService.getMatchHistory.mockResolvedValue({
        ...mockPage,
        total: 0,
        items: [],
      });

      await controller.getMatchHistory(mockRequest('player-1'), {
        page: 1,
        limit: 10,
      });

      expect(mockPlayerService.getMatchHistory).toHaveBeenCalledWith(
        'player-1',
        1,
        10,
      );
    });

    it('forwards custom page and limit to the service', async () => {
      mockPlayerService.getMatchHistory.mockResolvedValue({
        ...mockPage,
        page: 3,
        limit: 20,
        total: 50,
        items: [],
      });

      await controller.getMatchHistory(mockRequest('player-2'), {
        page: 3,
        limit: 20,
      });

      expect(mockPlayerService.getMatchHistory).toHaveBeenCalledWith(
        'player-2',
        3,
        20,
      );
    });
  });
});
