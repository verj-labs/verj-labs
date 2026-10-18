import { Module } from '@nestjs/common';
import { DeckService } from './deck.service';
import { ExchangeService } from './exchange.service';
import { GameEngineService } from './game-engine.service';
import { RulesService } from './rules.service';

@Module({
  providers: [GameEngineService, DeckService, RulesService, ExchangeService],
  exports: [GameEngineService, DeckService, RulesService, ExchangeService],
})
export class GameEngineModule {}
