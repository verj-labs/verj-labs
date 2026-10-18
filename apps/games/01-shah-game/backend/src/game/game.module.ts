import { Module } from '@nestjs/common';
import { GameEngineModule } from '../game-engine/game-engine.module';
import { PrismaModule } from '../prisma/prisma.module';
import { RedisModule } from '../redis/redis.module';
import { GameService } from './game.service';
import { SocketBroadcastService } from '../gateway/socket-broadcast.service';

@Module({
  imports: [GameEngineModule, PrismaModule, RedisModule],
  providers: [GameService, SocketBroadcastService],
  exports: [GameService, SocketBroadcastService],
})
export class GameModule {}
