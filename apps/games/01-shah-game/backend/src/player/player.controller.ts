import { Controller, Get, Query, Req } from '@nestjs/common';
import { type Request } from 'express';
import { MatchHistoryQueryDto } from './dto/match-history-query.dto';
import { type MatchHistoryPage, PlayerService } from './player.service';

@Controller('player')
export class PlayerController {
  constructor(private readonly playerService: PlayerService) {}

  /** GET /player/me/matches — paginated match history for the authenticated player */
  @Get('me/matches')
  async getMatchHistory(
    @Req() req: Request,
    @Query() query: MatchHistoryQueryDto,
  ): Promise<MatchHistoryPage> {
    return this.playerService.getMatchHistory(
      req.user!.playerId,
      query.page,
      query.limit,
    );
  }
}
