import { Test, type TestingModule } from '@nestjs/testing';
import { REDIS_CLIENT } from '../redis/redis.constants';
import { PlayerService } from '../player/player.service';
import { AuthService } from './auth.service';

const mockPlayerService = { createPlayer: jest.fn() };

const mockRedis = {
  set: jest.fn(),
  get: jest.fn(),
  del: jest.fn(),
  expire: jest.fn(),
};

const now = new Date();
const playerRecord = {
  id: 'player-uuid',
  displayName: 'Alice',
  sessionToken: 'will-be-overridden',
  createdAt: now,
};

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PlayerService, useValue: mockPlayerService },
        { provide: REDIS_CLIENT, useValue: mockRedis },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('createSession', () => {
    it('creates player, stores token in Redis, returns dto (happy path)', async () => {
      mockPlayerService.createPlayer.mockResolvedValue(playerRecord);
      mockRedis.set.mockResolvedValue('OK');

      const result = await service.createSession('Alice');

      expect(mockPlayerService.createPlayer).toHaveBeenCalledWith(
        'Alice',
        expect.any(String),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        expect.stringMatching(/^session:/),
        expect.any(String),
        'EX',
        86400,
      );
      expect(result).toMatchObject({
        token: expect.any(String),
        player: { id: 'player-uuid', displayName: 'Alice' },
      });
    });

    it('trims whitespace from display name', async () => {
      mockPlayerService.createPlayer.mockResolvedValue(playerRecord);
      mockRedis.set.mockResolvedValue('OK');

      await service.createSession('  Alice  ');

      expect(mockPlayerService.createPlayer).toHaveBeenCalledWith(
        'Alice',
        expect.any(String),
      );
    });
  });

  describe('getSession', () => {
    it('returns parsed payload for a valid token', async () => {
      const payload = { playerId: 'p1', displayName: 'Bob', matchId: null };
      mockRedis.get.mockResolvedValue(JSON.stringify(payload));

      const result = await service.getSession('valid-token');

      expect(result).toEqual(payload);
    });

    it('returns null for an unknown/expired token', async () => {
      mockRedis.get.mockResolvedValue(null);

      const result = await service.getSession('expired');

      expect(result).toBeNull();
    });
  });

  describe('deleteSession', () => {
    it('calls redis.del with correct key', async () => {
      mockRedis.del.mockResolvedValue(1);

      await service.deleteSession('tok');

      expect(mockRedis.del).toHaveBeenCalledWith('session:tok');
    });
  });

  describe('refreshSession', () => {
    it('calls redis.expire with 86400 TTL', async () => {
      mockRedis.expire.mockResolvedValue(1);

      await service.refreshSession('tok');

      expect(mockRedis.expire).toHaveBeenCalledWith('session:tok', 86400);
    });
  });
});
