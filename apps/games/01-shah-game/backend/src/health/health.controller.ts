import { Controller, Get, HttpStatus, Res } from '@nestjs/common';
import { HealthCheckService } from '@nestjs/terminus';
import { Response } from 'express';
import { Public } from '../auth/public.decorator';
import { PrismaHealthIndicator } from './prisma.health';
import { RedisHealthIndicator } from './redis.health';

interface HealthResponse {
  status: 'ok' | 'error';
  components: {
    postgres: boolean;
    redis: boolean;
  };
}

@Public()
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly prismaIndicator: PrismaHealthIndicator,
    private readonly redisIndicator: RedisHealthIndicator,
  ) {}

  @Get()
  async check(@Res() res: Response): Promise<void> {
    const postgresResult = await this.prismaIndicator.isHealthy('postgres');
    const redisResult = await this.redisIndicator.isHealthy('redis');

    const postgresOk = postgresResult['postgres']?.status === 'up';
    const redisOk = redisResult['redis']?.status === 'up';
    const allHealthy = postgresOk && redisOk;

    const body: HealthResponse = {
      status: allHealthy ? 'ok' : 'error',
      components: {
        postgres: postgresOk,
        redis: redisOk,
      },
    };

    res
      .status(allHealthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE)
      .json(body);
  }
}
