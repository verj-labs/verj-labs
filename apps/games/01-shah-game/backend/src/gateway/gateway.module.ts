import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { GameModule } from '../game/game.module';
import { GameGateway } from './game.gateway';

// SocketBroadcastService is provided by GameModule and shared via import
@Module({
  imports: [AuthModule, GameModule],
  providers: [GameGateway],
  exports: [],
})
export class GatewayModule {}
