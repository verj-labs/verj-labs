import { type INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, type TestingModule } from '@nestjs/testing';
import * as request from 'supertest';
import { SessionGuard } from '../auth/auth.guard';
import { AuthService } from '../auth/auth.service';
import { GameService } from '../game/game.service';
import { SocketBroadcastService } from '../gateway/socket-broadcast.service';
import { type MatchState } from '../shared/types/match.types';
import { MatchController } from './match.controller';
import { MatchService } from './match.service';

const mockMatchService = {
  createMatch: jest.fn(),
  joinMatch: jest.fn(),
  getMatch: jest.fn(),
  leaveMatch: jest.fn(),
  startMatch: jest.fn(),
  endMatch: jest.fn(),
  getMatchSummary: jest.fn(),
};

const mockAuthService = {
  getSession: jest.fn(),
  refreshSession: jest.fn(),
};

const mockGameService = {
  initGame: jest.fn(),
};

const mockBroadcastService = {
  toRoom: jest.fn(),
  socketsInRoom: jest.fn().mockResolvedValue([]),
  server: null,
};

const VALID_SESSION = {
  playerId: 'player-1',
  displayName: 'Alice',
  matchId: null,
};

const BASE_STATE: MatchState = {
  id: 'match-1',
  roomCode: 'ABCD',
  hostPlayerId: 'player-1',
  status: 'lobby',
  players: [{ playerId: 'player-1', displayName: 'Alice', seatIndex: 0 }],
  playerCount: 1,
};

describe('MatchController (integration)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    jest.clearAllMocks();
    mockAuthService.getSession.mockResolvedValue(VALID_SESSION);
    mockAuthService.refreshSession.mockResolvedValue(undefined);
    mockGameService.initGame.mockResolvedValue(undefined);

    const module: TestingModule = await Test.createTestingModule({
      controllers: [MatchController],
      providers: [
        { provide: MatchService, useValue: mockMatchService },
        { provide: AuthService, useValue: mockAuthService },
        { provide: GameService, useValue: mockGameService },
        { provide: SocketBroadcastService, useValue: mockBroadcastService },
        { provide: Reflector, useClass: Reflector },
      ],
    }).compile();

    app = module.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    const reflector = app.get(Reflector);
    app.useGlobalGuards(
      new SessionGuard(mockAuthService as unknown as AuthService, reflector),
    );
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  const authHeader = { Authorization: 'Bearer valid-token' };

  // ─── POST /match ─────────────────────────────────────────────────────────────

  describe('POST /match', () => {
    it('returns 201 with matchId, roomCode, and match state', async () => {
      mockMatchService.createMatch.mockResolvedValue(BASE_STATE);

      const res = await request(app.getHttpServer())
        .post('/match')
        .set(authHeader);

      expect(res.status).toBe(201);
      expect(res.body.matchId).toBe('match-1');
      expect(res.body.roomCode).toBe('ABCD');
      expect(res.body.match.status).toBe('lobby');
    });

    it('returns 401 when no token is provided', async () => {
      const res = await request(app.getHttpServer()).post('/match');
      expect(res.status).toBe(401);
    });
  });

  // ─── POST /match/join ────────────────────────────────────────────────────────

  describe('POST /match/join', () => {
    const joinState: MatchState = {
      ...BASE_STATE,
      players: [
        { playerId: 'player-1', displayName: 'Alice', seatIndex: 0 },
        { playerId: 'player-2', displayName: 'Bob', seatIndex: 1 },
      ],
      playerCount: 2,
    };

    it('returns 200 with updated match state', async () => {
      mockMatchService.joinMatch.mockResolvedValue(joinState);

      const res = await request(app.getHttpServer())
        .post('/match/join')
        .set(authHeader)
        .send({ roomCode: 'ABCD' });

      expect(res.status).toBe(200);
      expect(res.body.playerCount).toBe(2);
    });

    it('returns 400 when roomCode is missing', async () => {
      const res = await request(app.getHttpServer())
        .post('/match/join')
        .set(authHeader)
        .send({});

      expect(res.status).toBe(400);
    });

    it('returns 400 when roomCode is not 4 chars', async () => {
      const res = await request(app.getHttpServer())
        .post('/match/join')
        .set(authHeader)
        .send({ roomCode: 'AB' });

      expect(res.status).toBe(400);
    });

    it('returns 404 when room does not exist (propagates NotFoundException)', async () => {
      const { NotFoundException } = await import('@nestjs/common');
      mockMatchService.joinMatch.mockRejectedValue(
        new NotFoundException('Room not found.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/join')
        .set(authHeader)
        .send({ roomCode: 'ZZZZ' });

      expect(res.status).toBe(404);
    });

    it('returns 409 when room is full', async () => {
      const { ConflictException } = await import('@nestjs/common');
      mockMatchService.joinMatch.mockRejectedValue(
        new ConflictException('Room is full.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/join')
        .set(authHeader)
        .send({ roomCode: 'ABCD' });

      expect(res.status).toBe(409);
    });

    it('returns 409 when match is in progress', async () => {
      const { ConflictException } = await import('@nestjs/common');
      mockMatchService.joinMatch.mockRejectedValue(
        new ConflictException('Match already started.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/join')
        .set(authHeader)
        .send({ roomCode: 'ABCD' });

      expect(res.status).toBe(409);
    });
  });

  // ─── GET /match/:id ──────────────────────────────────────────────────────────

  describe('GET /match/:id', () => {
    it('returns match state', async () => {
      mockMatchService.getMatch.mockResolvedValue(BASE_STATE);

      const res = await request(app.getHttpServer())
        .get('/match/match-1')
        .set(authHeader);

      expect(res.status).toBe(200);
      expect(res.body.id).toBe('match-1');
    });
  });

  // ─── DELETE /match/:id/leave ─────────────────────────────────────────────────

  describe('DELETE /match/:id/leave', () => {
    it('returns 204 on success', async () => {
      mockMatchService.leaveMatch.mockResolvedValue(undefined);

      const res = await request(app.getHttpServer())
        .delete('/match/match-1/leave')
        .set(authHeader);

      expect(res.status).toBe(204);
    });
  });

  // ─── POST /match/:id/start ──────────────────────────────────────────────────

  describe('POST /match/:id/start', () => {
    it('returns started match state', async () => {
      const started = { ...BASE_STATE, status: 'in_progress' as const };
      mockMatchService.startMatch.mockResolvedValue(started);

      const res = await request(app.getHttpServer())
        .post('/match/match-1/start')
        .set(authHeader);

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('in_progress');
    });

    it('returns 403 when non-host tries to start', async () => {
      const { ForbiddenException } = await import('@nestjs/common');
      mockMatchService.startMatch.mockRejectedValue(
        new ForbiddenException('Only the host can start.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/match-1/start')
        .set(authHeader);

      expect(res.status).toBe(403);
    });

    it('returns 409 when fewer than 4 players', async () => {
      const { ConflictException } = await import('@nestjs/common');
      mockMatchService.startMatch.mockRejectedValue(
        new ConflictException('Need at least 4 players.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/match-1/start')
        .set(authHeader);

      expect(res.status).toBe(409);
    });
  });

  // ─── POST /match/:id/end ──────────────────────────────────────────────────────

  describe('POST /match/:id/end', () => {
    const standings = [
      { playerId: 'player-1', displayName: 'Alice', gamesPlayed: 3, wins: 2, averageRank: 1.33, bestFinish: 1 },
      { playerId: 'player-2', displayName: 'Bob', gamesPlayed: 3, wins: 1, averageRank: 2.0, bestFinish: 1 },
    ];

    it('returns 201 with match finished payload and broadcasts event', async () => {
      const payload = { matchId: 'match-1', totalGames: 3, standings };
      mockMatchService.endMatch.mockResolvedValue(payload);

      const res = await request(app.getHttpServer())
        .post('/match/match-1/end')
        .set(authHeader);

      expect(res.status).toBe(201);
      expect(res.body.matchId).toBe('match-1');
      expect(res.body.totalGames).toBe(3);
      expect(res.body.standings).toHaveLength(2);
      expect(mockBroadcastService.toRoom).toHaveBeenCalledWith(
        'match:match-1',
        'match:finished',
        payload,
      );
    });

    it('returns 403 when non-host tries to end match', async () => {
      const { ForbiddenException } = await import('@nestjs/common');
      mockMatchService.endMatch.mockRejectedValue(
        new ForbiddenException('Only the host can end the match.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/match-1/end')
        .set(authHeader);

      expect(res.status).toBe(403);
    });

    it('returns 409 when match is already finished', async () => {
      const { ConflictException } = await import('@nestjs/common');
      mockMatchService.endMatch.mockRejectedValue(
        new ConflictException('Match is already finished.'),
      );

      const res = await request(app.getHttpServer())
        .post('/match/match-1/end')
        .set(authHeader);

      expect(res.status).toBe(409);
    });
  });

  // ─── GET /match/:id/summary ──────────────────────────────────────────────────

  describe('GET /match/:id/summary', () => {
    const summary = {
      matchId: 'match-1',
      roomCode: 'ABCD',
      status: 'finished',
      createdAt: '2024-01-01T00:00:00.000Z',
      endedAt: '2024-01-02T00:00:00.000Z',
      players: [{ id: 'player-1', displayName: 'Alice', seatIndex: 0 }],
      aggregate: [],
      games: [],
    };

    it('returns 200 with full match summary', async () => {
      mockMatchService.getMatchSummary.mockResolvedValue(summary);

      const res = await request(app.getHttpServer())
        .get('/match/match-1/summary')
        .set(authHeader);

      expect(res.status).toBe(200);
      expect(res.body.matchId).toBe('match-1');
      expect(res.body.status).toBe('finished');
    });

    it('returns 403 when caller is not a participant', async () => {
      const { ForbiddenException } = await import('@nestjs/common');
      mockMatchService.getMatchSummary.mockRejectedValue(
        new ForbiddenException('You did not participate in this match.'),
      );

      const res = await request(app.getHttpServer())
        .get('/match/match-1/summary')
        .set(authHeader);

      expect(res.status).toBe(403);
    });

    it('returns 404 when match not found', async () => {
      const { NotFoundException } = await import('@nestjs/common');
      mockMatchService.getMatchSummary.mockRejectedValue(
        new NotFoundException('Match not found.'),
      );

      const res = await request(app.getHttpServer())
        .get('/match/match-1/summary')
        .set(authHeader);

      expect(res.status).toBe(404);
    });
  });
});
