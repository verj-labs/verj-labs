/**
 * Auth integration tests
 *
 * These tests run against a real PostgreSQL + Redis instance (the same service
 * containers as the CI pipeline). No mocks are used; all writes/reads go to the
 * actual database and cache.
 *
 * Cleanup: all player rows created during the test suite are removed in afterAll.
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

describe('Auth (integration)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let redis: Redis;

  /** IDs of players created during this suite — deleted in afterAll */
  const createdPlayerIds: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = module.createNestApplication();

    // Mirror main.ts bootstrap exactly
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
    if (createdPlayerIds.length > 0) {
      await prisma.player.deleteMany({
        where: { id: { in: createdPlayerIds } },
      });
    }
    await app.close();
  });

  // ─── POST /auth/session ───────────────────────────────────────────────────

  describe('POST /auth/session', () => {
    it('creates a session, persists player to Postgres and token to Redis', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: 'IntegrationTester' })
        .expect(201);

      expect(res.body).toMatchObject({
        token: expect.any(String),
        player: { id: expect.any(String), displayName: 'IntegrationTester' },
      });

      const { token, player } = res.body as {
        token: string;
        player: { id: string; displayName: string };
      };
      createdPlayerIds.push(player.id);

      // Postgres: player row exists
      const dbPlayer = await prisma.player.findUnique({
        where: { id: player.id },
      });
      expect(dbPlayer).not.toBeNull();
      expect(dbPlayer!.displayName).toBe('IntegrationTester');

      // Redis: session key exists
      const cached = await redis.get(`session:${token}`);
      expect(cached).not.toBeNull();
      const payload = JSON.parse(cached!) as {
        playerId: string;
        displayName: string;
      };
      expect(payload.playerId).toBe(player.id);
    });

    it('returns 400 when displayName is missing', async () => {
      await request(app.getHttpServer())
        .post('/auth/session')
        .send({})
        .expect(400);
    });

    it('returns 400 when displayName is empty', async () => {
      await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: '' })
        .expect(400);
    });
  });

  // ─── GET /auth/me ─────────────────────────────────────────────────────────

  describe('GET /auth/me', () => {
    it('returns player info for a valid token', async () => {
      const createRes = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: 'MeTester' })
        .expect(201);

      const { token, player } = createRes.body as {
        token: string;
        player: { id: string };
      };
      createdPlayerIds.push(player.id);

      const meRes = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(meRes.body).toMatchObject({
        player: { id: player.id, displayName: 'MeTester' },
        matchId: null,
      });
    });

    it('returns 401 without a token', async () => {
      await request(app.getHttpServer()).get('/auth/me').expect(401);
    });

    it('returns 401 with an invalid token', async () => {
      await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', 'Bearer not-a-real-token')
        .expect(401);
    });
  });

  // ─── DELETE /auth/session ─────────────────────────────────────────────────

  describe('DELETE /auth/session', () => {
    it('deletes the session from Redis and returns 204', async () => {
      const createRes = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: 'DeleteTester' })
        .expect(201);

      const { token, player } = createRes.body as {
        token: string;
        player: { id: string };
      };
      createdPlayerIds.push(player.id);

      await request(app.getHttpServer())
        .delete('/auth/session')
        .set('Authorization', `Bearer ${token}`)
        .expect(204);

      // Subsequent GET /auth/me should be rejected
      await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(401);
    });
  });
});
