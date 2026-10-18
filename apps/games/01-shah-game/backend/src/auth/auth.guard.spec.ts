import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test, type TestingModule } from '@nestjs/testing';
import { type SessionPayload } from '../shared/types/session.types';
import { SessionGuard } from './auth.guard';
import { AuthService } from './auth.service';
import { IS_PUBLIC_KEY } from './public.decorator';

const mockAuthService = {
  getSession: jest.fn(),
};

const mockReflector = {
  getAllAndOverride: jest.fn(),
};

function buildContext(
  headers: Record<string, string>,
  _handlerMetadata = false,
): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ headers, user: undefined, sessionToken: undefined }),
    }),
    getHandler: () => ({}),
    getClass: () => ({}),
  } as unknown as ExecutionContext;
}

const sessionPayload: SessionPayload = {
  playerId: 'player-1',
  displayName: 'Alice',
  matchId: null,
};

describe('SessionGuard', () => {
  let guard: SessionGuard;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SessionGuard,
        { provide: AuthService, useValue: mockAuthService },
        { provide: Reflector, useValue: mockReflector },
      ],
    }).compile();

    guard = module.get<SessionGuard>(SessionGuard);
  });

  it('allows @Public() endpoints without a token', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(true);
    const ctx = buildContext({});

    const result = await guard.canActivate(ctx);

    expect(result).toBe(true);
    expect(mockAuthService.getSession).not.toHaveBeenCalled();
  });

  it('throws 401 when no Authorization header is present', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    const ctx = buildContext({});

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('throws 401 for an expired/unknown token', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    mockAuthService.getSession.mockResolvedValue(null);
    const ctx = buildContext({ authorization: 'Bearer bad-token' });

    await expect(guard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
  });

  it('attaches user and sessionToken for a valid token', async () => {
    mockReflector.getAllAndOverride.mockReturnValue(false);
    mockAuthService.getSession.mockResolvedValue(sessionPayload);

    const request = {
      headers: { authorization: 'Bearer valid-token' },
      user: undefined,
      sessionToken: undefined,
    };
    const ctx = {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => ({}),
      getClass: () => ({}),
    } as unknown as ExecutionContext;

    const result = await guard.canActivate(ctx);

    expect(result).toBe(true);
    expect(request.user).toEqual(sessionPayload);
    expect(request.sessionToken).toBe('valid-token');
  });

  it('uses IS_PUBLIC_KEY metadata key', () => {
    expect(IS_PUBLIC_KEY).toBe('isPublic');
  });
});
