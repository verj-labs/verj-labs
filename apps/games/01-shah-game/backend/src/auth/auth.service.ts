import {
  Inject,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import Redis from 'ioredis';
import { PlayerService } from '../player/player.service';
import { REDIS_CLIENT } from '../redis/redis.constants';
import { type SessionPayload } from '../shared/types/session.types';

const SESSION_TTL_SECONDS = 86_400; // 24 h

export interface SessionCreatedDto {
  token: string;
  player: { id: string; displayName: string };
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly playerService: PlayerService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async createSession(displayName: string): Promise<SessionCreatedDto> {
    const trimmed = displayName.trim();
    const token = randomUUID();

    const player = await this.playerService.createPlayer(trimmed, token);

    const payload: SessionPayload = {
      playerId: player.id,
      displayName: player.displayName,
      matchId: null,
    };

    try {
      await this.redis.set(
        `session:${token}`,
        JSON.stringify(payload),
        'EX',
        SESSION_TTL_SECONDS,
      );
    } catch (err) {
      this.logger.error(`Redis write failed in createSession: ${String(err)}`);
      throw new InternalServerErrorException(
        'Session storage is currently unavailable.',
      );
    }

    this.logger.log(`Session created for player ${player.id}`);

    return {
      token,
      player: { id: player.id, displayName: player.displayName },
    };
  }

  async getSession(token: string): Promise<SessionPayload | null> {
    let raw: string | null;
    try {
      raw = await this.redis.get(`session:${token}`);
    } catch (err) {
      this.logger.error(`Redis read failed in getSession: ${String(err)}`);
      throw new InternalServerErrorException(
        'Session storage is currently unavailable.',
      );
    }
    if (!raw) return null;
    return JSON.parse(raw) as SessionPayload;
  }

  async refreshSession(token: string): Promise<void> {
    try {
      await this.redis.expire(`session:${token}`, SESSION_TTL_SECONDS);
    } catch (err) {
      // Non-fatal: TTL refresh failure does not break the current request
      this.logger.warn(
        `Redis expire failed in refreshSession (token=${token}): ${String(err)}`,
      );
    }
  }

  async updateSessionMatchId(
    token: string,
    matchId: string | null,
  ): Promise<void> {
    const session = await this.getSession(token);
    if (!session) return;
    session.matchId = matchId;
    try {
      await this.redis.set(
        `session:${token}`,
        JSON.stringify(session),
        'EX',
        SESSION_TTL_SECONDS,
      );
    } catch (err) {
      this.logger.warn(
        `Redis write failed in updateSessionMatchId: ${String(err)}`,
      );
    }
  }

  async deleteSession(token: string): Promise<void> {
    try {
      await this.redis.del(`session:${token}`);
    } catch (err) {
      this.logger.error(`Redis delete failed in deleteSession: ${String(err)}`);
      throw new InternalServerErrorException(
        'Session storage is currently unavailable.',
      );
    }
    this.logger.log('Session deleted');
  }
}
