import { Module } from '@nestjs/common';
import { PlayerModule } from '../player/player.module';
import { AuthController } from './auth.controller';
import { SessionGuard } from './auth.guard';
import { AuthService } from './auth.service';
import { SlidingSessionInterceptor } from './sliding-session.interceptor';

@Module({
  imports: [PlayerModule],
  controllers: [AuthController],
  providers: [AuthService, SessionGuard, SlidingSessionInterceptor],
  exports: [AuthService, SessionGuard, SlidingSessionInterceptor],
})
export class AuthModule {}
