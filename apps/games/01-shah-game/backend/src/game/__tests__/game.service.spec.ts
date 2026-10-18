import { Test } from '@nestjs/testing';
import { GameService } from '../game.service';
import { DeckService } from '../../game-engine/deck.service';
import { ExchangeService } from '../../game-engine/exchange.service';
import { GameEngineService } from '../../game-engine/game-engine.service';
import { SocketBroadcastService } from '../../gateway/socket-broadcast.service';
import { PrismaService } from '../../prisma/prisma.service';
import { REDIS_CLIENT } from '../../redis/redis.constants';
import { type GameState } from '../../shared/types/game-state.types';
import { type MatchState } from '../../shared/types/match.types';
import {
  card,
  makeGameState,
  makePlayer,
} from '../../game-engine/__tests__/game-state.factory';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function makeMatchState(overrides: Partial<MatchState> = {}): MatchState {
  return {
    id: 'match-1',
    roomCode: 'ABCD',
    hostPlayerId: 'p0',
    status: 'in_progress',
    playerCount: 4,
    players: [
      { playerId: 'p0', displayName: 'Alice', seatIndex: 0 },
      { playerId: 'p1', displayName: 'Bob', seatIndex: 1 },
      { playerId: 'p2', displayName: 'Carol', seatIndex: 2 },
      { playerId: 'p3', displayName: 'Dave', seatIndex: 3 },
    ],
    ...overrides,
  };
}

function makeFullGameState(): GameState {
  const state = makeGameState({
    activePlayerIndex: 0,
    players: [
      makePlayer('p0', 0, [card('7'), card('8')]),
      makePlayer('p1', 1, [card('J'), card('Q')]),
      makePlayer('p2', 2, [card('K'), card('A')]),
      makePlayer('p3', 3, [card('2'), card('3')]),
    ],
  });
  return { ...state, id: 'game-1', matchId: 'match-1' };
}

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockRedis = {
  get: jest.fn(),
  set: jest.fn(),
  del: jest.fn(),
  exists: jest.fn(),
};

const mockPrisma = {
  game: {
    create: jest.fn(),
    update: jest.fn(),
  },
  gameRanking: {
    create: jest.fn(),
  },
  gameEvent: {
    create: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockDeckService = {
  buildDeck: jest.fn().mockReturnValue([{ rank: '7', suit: 'hearts' }]),
  shuffleDeck: jest.fn().mockImplementation((deck) => deck),
  dealHands: jest.fn(),
};

const mockEngine = {
  processIntent: jest.fn(),
};

const mockBroadcast = {
  server: null as unknown,
  toRoom: jest.fn(),
  toSocket: jest.fn(),
  socketsInRoom: jest.fn().mockResolvedValue([]),
};

const mockExchange = {
  computeExchange: jest.fn().mockReturnValue({
    actions: [],
    updatedHands: new Map(),
  }),
  getWorstCards: jest.fn().mockReturnValue([]),
  getBestCards: jest.fn().mockReturnValue([]),
};

// ─── Test suite ─────────────────────────────────────────────────────────────────

describe('GameService', () => {
  let svc: GameService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module = await Test.createTestingModule({
      providers: [
        GameService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: REDIS_CLIENT, useValue: mockRedis },
        { provide: DeckService, useValue: mockDeckService },
        { provide: GameEngineService, useValue: mockEngine },
        { provide: SocketBroadcastService, useValue: mockBroadcast },
        { provide: ExchangeService, useValue: mockExchange },
      ],
    }).compile();

    svc = module.get(GameService);
  });

  // ─── initGame ─────────────────────────────────────────────────────────────

  describe('initGame()', () => {
    it('throws NotFoundException when match state is missing from Redis', async () => {
      mockRedis.get.mockResolvedValue(null);
      await expect(svc.initGame('match-1')).rejects.toThrow(
        'Match state not found',
      );
    });

    it('creates a Game Prisma record and stores state in Redis', async () => {
      const matchState = makeMatchState();
      mockRedis.get.mockResolvedValue(JSON.stringify(matchState));
      mockRedis.set.mockResolvedValue('OK');
      mockDeckService.dealHands.mockReturnValue({
        hands: [[card('7')], [card('8')], [card('9')], [card('10')]],
        discarded: [],
      });
      mockPrisma.game.create.mockResolvedValue({ id: 'game-1' });

      await svc.initGame('match-1');

      expect(mockPrisma.game.create).toHaveBeenCalledTimes(1);
      expect(mockRedis.set).toHaveBeenCalledWith(
        'game:game-1:state',
        expect.any(String),
        'EX',
        expect.any(Number),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'game:active:match-1',
        'game-1',
        'EX',
        expect.any(Number),
      );
    });

    it('calls broadcastGameStarted after creating the game', async () => {
      const matchState = makeMatchState();
      mockRedis.get.mockResolvedValue(JSON.stringify(matchState));
      mockRedis.set.mockResolvedValue('OK');
      mockDeckService.dealHands.mockReturnValue({
        hands: [[card('7')], [card('8')], [card('9')], [card('10')]],
        discarded: [],
      });
      mockPrisma.game.create.mockResolvedValue({ id: 'game-1' });
      mockBroadcast.socketsInRoom.mockResolvedValue([]);

      await svc.initGame('match-1');

      expect(mockBroadcast.socketsInRoom).toHaveBeenCalledWith('match:match-1');
    });
  });

  // ─── projectStateForPlayer ────────────────────────────────────────────────

  describe('projectStateForPlayer()', () => {
    it("includes the viewing player's hand in localHand", () => {
      const state = makeFullGameState();
      const view = svc.projectStateForPlayer(state, 'p0');
      expect(view.localHand).toEqual([card('7'), card('8')]);
    });

    it("hides other players' hands (shows only handCount)", () => {
      const state = makeFullGameState();
      const view = svc.projectStateForPlayer(state, 'p0');
      const p1View = view.players.find((p) => p.id === 'p1')!;
      expect(p1View.handCount).toBe(2);
      expect((p1View as unknown as { hand?: unknown }).hand).toBeUndefined();
    });

    it('returns empty localHand when viewer is not a player', () => {
      const state = makeFullGameState();
      const view = svc.projectStateForPlayer(state, 'unknown-player');
      expect(view.localHand).toEqual([]);
    });

    it('marks passed players correctly', () => {
      const state = makeFullGameState();
      state.currentRound.passedThisRound = ['p1', 'p2'];
      const view = svc.projectStateForPlayer(state, 'p0');
      const p1 = view.players.find((p) => p.id === 'p1')!;
      const p0 = view.players.find((p) => p.id === 'p0')!;
      expect(p1.passed).toBe(true);
      expect(p0.passed).toBe(false);
    });
  });

  // ─── handlePlayerIntent ───────────────────────────────────────────────────

  describe('handlePlayerIntent()', () => {
    it('emits play_rejected if game state is missing from Redis', async () => {
      mockRedis.get.mockResolvedValue(null);
      await svc.handlePlayerIntent(
        'game-1',
        'match-1',
        'p0',
        { type: 'pass' },
        'socket-1',
      );
      expect(mockBroadcast.toSocket).toHaveBeenCalledWith(
        'socket-1',
        'game:play_rejected',
        expect.objectContaining({ reason: expect.any(String) }),
      );
    });

    it('emits play_rejected on engine error', async () => {
      const state = makeFullGameState();
      mockRedis.get.mockResolvedValue(JSON.stringify(state));
      mockEngine.processIntent.mockReturnValue({
        newState: state,
        events: [],
        error: 'Not your turn.',
      });

      await svc.handlePlayerIntent(
        'game-1',
        'match-1',
        'p0',
        { type: 'pass' },
        'socket-1',
      );

      expect(mockBroadcast.toSocket).toHaveBeenCalledWith(
        'socket-1',
        'game:play_rejected',
        { reason: 'Not your turn.' },
      );
    });

    it('saves updated state and broadcasts on successful intent', async () => {
      const state = makeFullGameState();
      const newState = makeFullGameState();
      newState.activePlayerIndex = 1;
      mockRedis.get.mockResolvedValue(JSON.stringify(state));
      mockRedis.set.mockResolvedValue('OK');
      mockEngine.processIntent.mockReturnValue({ newState, events: [] });
      mockBroadcast.socketsInRoom.mockResolvedValue([]);

      await svc.handlePlayerIntent(
        'game-1',
        'match-1',
        'p0',
        { type: 'pass' },
        'socket-1',
      );

      expect(mockRedis.set).toHaveBeenCalledWith(
        'game:game-1:state',
        expect.any(String),
        'EX',
        expect.any(Number),
      );
      expect(mockBroadcast.socketsInRoom).toHaveBeenCalled();
    });
  });

  // ─── Redis presence helpers ───────────────────────────────────────────────

  describe('disconnect/reconnect helpers', () => {
    it('markDisconnected sets Redis key with TTL', async () => {
      mockRedis.set.mockResolvedValue('OK');
      await svc.markDisconnected('p0');
      expect(mockRedis.set).toHaveBeenCalledWith(
        'game:reconnect:p0',
        '1',
        'EX',
        expect.any(Number),
      );
    });

    it('cancelReconnect deletes Redis key', async () => {
      mockRedis.del.mockResolvedValue(1);
      await svc.cancelReconnect('p0');
      expect(mockRedis.del).toHaveBeenCalledWith('game:reconnect:p0');
    });

    it('isDisconnected returns true when key exists', async () => {
      mockRedis.exists.mockResolvedValue(1);
      expect(await svc.isDisconnected('p0')).toBe(true);
    });

    it('isDisconnected returns false when key missing', async () => {
      mockRedis.exists.mockResolvedValue(0);
      expect(await svc.isDisconnected('p0')).toBe(false);
    });
  });

  // ─── getActiveGameId / getGameState ──────────────────────────────────────

  describe('getActiveGameId()', () => {
    it('returns gameId from Redis', async () => {
      mockRedis.get.mockResolvedValue('game-1');
      expect(await svc.getActiveGameId('match-1')).toBe('game-1');
      expect(mockRedis.get).toHaveBeenCalledWith('game:active:match-1');
    });

    it('returns null when not found', async () => {
      mockRedis.get.mockResolvedValue(null);
      expect(await svc.getActiveGameId('match-1')).toBeNull();
    });
  });

  describe('getGameState()', () => {
    it('returns parsed GameState', async () => {
      const state = makeFullGameState();
      mockRedis.get.mockResolvedValue(JSON.stringify(state));
      const result = await svc.getGameState('game-1');
      expect(result?.id).toBe(state.id);
    });

    it('returns null when not found', async () => {
      mockRedis.get.mockResolvedValue(null);
      expect(await svc.getGameState('game-1')).toBeNull();
    });
  });
});
