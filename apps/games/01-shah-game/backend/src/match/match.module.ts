import { Module } from '@nestjs/common';
import { GameModule } from '../game/game.module';
import { MatchController } from './match.controller';
import { MatchService } from './match.service';

@Module({
  imports: [GameModule],
  controllers: [MatchController],
  providers: [MatchService],
  exports: [MatchService],
})
export class MatchModule {}
