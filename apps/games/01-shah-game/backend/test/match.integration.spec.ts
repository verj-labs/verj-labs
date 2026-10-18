/**
 * Match integration tests
 *
 * These tests run against a real PostgreSQL + Redis instance. No mocks are used.
 *
 * Cleanup: all match + player rows created during the suite are removed in afterAll.
 */
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { App } from 'supertest/types';
import { SessionGuard } from '../src/auth/auth.guard';
import { AuthService } from '../src/auth/auth.service';
import { SlidingSessionInterceptor } from '../src/auth/sliding-session.interceptor';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { REDIS_CLIENT } from '../src/redis/redis.constants';
import type Redis from 'ioredis';

/** Helper to create a session and return the token + playerId */
async function createSession(
  server: ReturnType<INestApplication['getHttpServer']>,
  displayName: string,
): Promise<{ token: string; playerId: string }> {
  const res = await request(server)
    .post('/auth/session')
    .send({ displayName })
    .expect(201);
  return {
    token: res.body.token as string,
    playerId: res.body.player.id as string,
  };
}

describe('Match (integration)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let redis: Redis;

  const createdPlayerIds: string[] = [];
  const createdMatchIds: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = module.createNestApplication();

    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );

    const reflector = app.get(Reflector);
    const authService = app.get(AuthService);
    app.useGlobalGuards(new SessionGuard(authService, reflector));
    app.useGlobalInterceptors(new SlidingSessionInterceptor(authService));

    await app.init();

    prisma = app.get(PrismaService);
    redis = app.get<Redis>(REDIS_CLIENT);
  });

  afterAll(async () => {
    if (createdMatchIds.length > 0) {
      await prisma.matchPlayer.deleteMany({
        where: { matchId: { in: createdMatchIds } },
      });
      await prisma.match.deleteMany({ where: { id: { in: createdMatchIds } } });
    }
    if (createdPlayerIds.length > 0) {
      await prisma.player.deleteMany({
        where: { id: { in: createdPlayerIds } },
      });
    }
    await app.close();
  });

  // ─── POST /match ──────────────────────────────────────────────────────────

  describe('POST /match', () => {
    it('creates a match in Postgres and caches state in Redis', async () => {
      const { token, playerId } = await createSession(
        app.getHttpServer(),
        'HostPlayer',
      );
      createdPlayerIds.push(playerId);

      const res = await request(app.getHttpServer())
        .post('/match')
        .set('Authorization', `Bearer ${token}`)
        .expect(201);

      expect(res.body).toMatchObject({
        matchId: expect.any(String),
        roomCode: expect.stringMatching(/^[A-Z0-9]{4}$/),
        match: {
          status: 'lobby',
          hostPlayerId: playerId,
          playerCount: 1,
          players: [{ playerId, seatIndex: 0 }],
        },
      });

      const { matchId, roomCode } = res.body as {
        matchId: string;
        roomCode: string;
      };
      createdMatchIds.push(matchId);

      // Postgres: match row exists
      const dbMatch = await prisma.match.findUnique({ where: { id: matchId } });
      expect(dbMatch).not.toBeNull();
      expect(dbMatch!.roomCode).toBe(roomCode);
      expect(dbMatch!.status).toBe('lobby');

      // Redis: match state cached
      const cached = await redis.get(`match:${matchId}:state`);
      expect(cached).not.toBeNull();
      const state = JSON.parse(cached!) as { id: string; status: string };
      expect(state.id).toBe(matchId);
      expect(state.status).toBe('lobby');
    });

    it('returns 401 without a token', async () => {
      await request(app.getHttpServer()).post('/match').expect(401);
    });
  });

  // ─── POST /match/join ─────────────────────────────────────────────────────

  describe('POST /match/join', () => {
    it('joins an existing lobby and returns updated state', async () => {
      // Create host + match
      const host = await createSession(app.getHttpServer(), 'JoinHost');
      createdPlayerIds.push(host.playerId);

      const createRes = await request(app.getHttpServer())
        .post('/match')
        .set('Authorization', `Bearer ${host.token}`)
        .expect(201);

      const matchId: string = createRes.body.matchId;
      const roomCode: string = createRes.body.roomCode;
      createdMatchIds.push(matchId);

      // Second player joins
      const joiner = await createSession(app.getHttpServer(), 'JoinPlayer');
      createdPlayerIds.push(joiner.playerId);

      const joinRes = await request(app.getHttpServer())
        .post('/match/join')
        .set('Authorization', `Bearer ${joiner.token}`)
        .send({ roomCode })
        .expect(200);

      expect(joinRes.body).toMatchObject({
        id: matchId,
        status: 'lobby',
        playerCount: 2,
        players: expect.arrayContaining([
          expect.objectContaining({ playerId: host.playerId }),
          expect.objectContaining({ playerId: joiner.playerId }),
        ]),
      });
    });

    it('returns 404 for a non-existent room code', async () => {
      const { token, playerId } = await createSession(
        app.getHttpServer(),
        'NoRoomPlayer',
      );
      createdPlayerIds.push(playerId);

      await request(app.getHttpServer())
        .post('/match/join')
        .set('Authorization', `Bearer ${token}`)
        .send({ roomCode: 'ZZZZ' })
        .expect(404);
    });

    it('returns 409 when the player is already in the room', async () => {
      const host = await createSession(app.getHttpServer(), 'DupJoinHost');
      createdPlayerIds.push(host.playerId);

      const createRes = await request(app.getHttpServer())
        .post('/match')
        .set('Authorization', `Bearer ${host.token}`)
        .expect(201);

      const matchId: string = createRes.body.matchId;
      const roomCode: string = createRes.body.roomCode;
      createdMatchIds.push(matchId);

      // Host tries to join their own room again
      await request(app.getHttpServer())
        .post('/match/join')
        .set('Authorization', `Bearer ${host.token}`)
        .send({ roomCode })
        .expect(409);
    });
  });

  // ─── GET /match/:id ───────────────────────────────────────────────────────

  describe('GET /match/:id', () => {
    it('returns the match state for a valid id', async () => {
      const { token, playerId } = await createSession(
        app.getHttpServer(),
        'GetMatchPlayer',
      );
      createdPlayerIds.push(playerId);

      const createRes = await request(app.getHttpServer())
        .post('/match')
        .set('Authorization', `Bearer ${token}`)
        .expect(201);

      const matchId: string = createRes.body.matchId;
      createdMatchIds.push(matchId);

      const getRes = await request(app.getHttpServer())
        .get(`/match/${matchId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(getRes.body).toMatchObject({
        id: matchId,
        status: 'lobby',
        hostPlayerId: playerId,
      });
    });

    it('returns 404 for an unknown match id', async () => {
      const { token, playerId } = await createSession(
        app.getHttpServer(),
        'NoMatchPlayer',
      );
      createdPlayerIds.push(playerId);

      await request(app.getHttpServer())
        .get('/match/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
    });
  });
});
