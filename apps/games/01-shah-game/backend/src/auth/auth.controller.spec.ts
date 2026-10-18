import { type INestApplication, ValidationPipe } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, type TestingModule } from '@nestjs/testing';
import * as request from 'supertest';
import { SessionGuard } from './auth.guard';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

const mockAuthService = {
  createSession: jest.fn(),
  getSession: jest.fn(),
  deleteSession: jest.fn(),
  refreshSession: jest.fn(),
};

describe('AuthController (integration)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
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

  describe('POST /auth/session', () => {
    it('returns 201 with token and player on valid name (happy path)', async () => {
      mockAuthService.createSession.mockResolvedValue({
        token: 'test-token',
        player: { id: 'pid', displayName: 'Alice' },
      });

      const res = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: 'Alice' });

      expect(res.status).toBe(201);
      expect(res.body).toMatchObject({
        token: 'test-token',
        player: { id: 'pid', displayName: 'Alice' },
      });
    });

    it('returns 400 when displayName is shorter than 2 chars', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: 'A' });

      expect(res.status).toBe(400);
      expect(mockAuthService.createSession).not.toHaveBeenCalled();
    });

    it('returns 400 when displayName is whitespace-only (trims before validation)', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: '   ' });

      expect(res.status).toBe(400);
      expect(mockAuthService.createSession).not.toHaveBeenCalled();
    });

    it('returns 400 when displayName exceeds 32 chars', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/session')
        .send({ displayName: 'A'.repeat(33) });

      expect(res.status).toBe(400);
    });

    it('returns 400 when body is missing displayName', async () => {
      const res = await request(app.getHttpServer())
        .post('/auth/session')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('GET /auth/me', () => {
    it('returns 200 with player info for valid session', async () => {
      mockAuthService.getSession.mockResolvedValue({
        playerId: 'p1',
        displayName: 'Bob',
        matchId: null,
      });

      const res = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', 'Bearer valid-token');

      expect(res.status).toBe(200);
      expect(res.body).toEqual({
        player: { id: 'p1', displayName: 'Bob' },
        matchId: null,
      });
    });

    it('returns 401 when no token is provided', async () => {
      const res = await request(app.getHttpServer()).get('/auth/me');
      expect(res.status).toBe(401);
    });

    it('returns 401 for an expired/unknown token', async () => {
      mockAuthService.getSession.mockResolvedValue(null);

      const res = await request(app.getHttpServer())
        .get('/auth/me')
        .set('Authorization', 'Bearer expired');

      expect(res.status).toBe(401);
    });
  });

  describe('DELETE /auth/session', () => {
    it('returns 204 and deletes the session', async () => {
      mockAuthService.getSession.mockResolvedValue({
        playerId: 'p1',
        displayName: 'Alice',
        matchId: null,
      });
      mockAuthService.deleteSession.mockResolvedValue(undefined);

      const res = await request(app.getHttpServer())
        .delete('/auth/session')
        .set('Authorization', 'Bearer valid-token');

      expect(res.status).toBe(204);
      expect(mockAuthService.deleteSession).toHaveBeenCalledWith('valid-token');
    });
  });
});
