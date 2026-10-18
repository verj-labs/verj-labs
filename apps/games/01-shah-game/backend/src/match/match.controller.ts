import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Logger,
  Param,
  Post,
  Req,
} from '@nestjs/common';
import { type Request } from 'express';
import { type MatchState } from '../shared/types/match.types';
import { type MatchFinishedPayload } from '../shared/types/socket-payloads.types';
import { type MatchSummary } from './match.service';
import { JoinMatchDto } from './dto/join-match.dto';
import { GameService } from '../game/game.service';
import { MatchService } from './match.service';
import { SocketBroadcastService } from '../gateway/socket-broadcast.service';
import { GameEvents } from '../gateway/events.enum';

@Controller('match')
export class MatchController {
  private readonly logger = new Logger(MatchController.name);

  constructor(
    private readonly matchService: MatchService,
    private readonly gameService: GameService,
    private readonly broadcast: SocketBroadcastService,
  ) {}

  /** POST /match — create a new room */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createMatch(
    @Req() req: Request,
  ): Promise<{ matchId: string; roomCode: string; match: MatchState }> {
    const { playerId, displayName } = req.user!;
    const match = await this.matchService.createMatch(playerId, displayName);
    return { matchId: match.id, roomCode: match.roomCode, match };
  }

  /** POST /match/join — join a room by code */
  @Post('join')
  @HttpCode(HttpStatus.OK)
  async joinMatch(
    @Body() dto: JoinMatchDto,
    @Req() req: Request,
  ): Promise<MatchState> {
    const { playerId, displayName } = req.user!;
    const match = await this.matchService.joinMatch(
      dto.roomCode,
      playerId,
      displayName,
    );
    // Broadcast the updated lobby state to all players already in the room
    const room = `match:${match.id}`;
    const roomSockets = await this.broadcast.socketsInRoom(room);
    this.logger.debug(
      `joinMatch broadcast → room ${room} | joiner: ${displayName} | sockets in room: ${roomSockets.length}`,
    );
    this.broadcast.toRoom(room, GameEvents.MATCH_UPDATED, match);
    return match;
  }

  /** GET /match/:id — get current match state */
  @Get(':id')
  async getMatch(@Param('id') matchId: string): Promise<MatchState> {
    return this.matchService.getMatch(matchId);
  }

  /** DELETE /match/:id/leave — leave a room (lobby or in-progress forfeit) */
  @Delete(':id/leave')
  @HttpCode(HttpStatus.NO_CONTENT)
  async leaveMatch(
    @Param('id') matchId: string,
    @Req() req: Request,
  ): Promise<void> {
    const result = await this.matchService.leaveMatch(
      matchId,
      req.user!.playerId,
    );

    if (result.matchEnded) {
      // Broadcast match:finished if the match was abandoned with a payload
      if (result.payload) {
        this.broadcast.toRoom(
          `match:${matchId}`,
          GameEvents.MATCH_FINISHED,
          result.payload,
        );
      }
      return;
    }

    // Match still running — broadcast updated lobby/game state to remaining players
    try {
      const updatedState = await this.matchService.getMatch(matchId);
      this.broadcast.toRoom(
        `match:${matchId}`,
        GameEvents.MATCH_UPDATED,
        updatedState,
      );
    } catch {
      // Match state may not be accessible — nothing to broadcast
    }
  }

  /** POST /match/:id/start — host starts the match */
  @Post(':id/start')
  async startMatch(
    @Param('id') matchId: string,
    @Req() req: Request,
  ): Promise<MatchState> {
    const match = await this.matchService.startMatch(
      matchId,
      req.user!.playerId,
    );
    await this.gameService.initGame(matchId);
    return match;
  }

  /** POST /match/:id/end — host ends the match and broadcasts final standings */
  @Post(':id/end')
  async endMatch(
    @Param('id') matchId: string,
    @Req() req: Request,
  ): Promise<MatchFinishedPayload> {
    const payload = await this.matchService.endMatch(
      matchId,
      req.user!.playerId,
    );
    this.broadcast.toRoom(
      `match:${matchId}`,
      GameEvents.MATCH_FINISHED,
      payload,
    );
    return payload;
  }

  /** GET /match/:id/summary — full match summary for participants */
  @Get(':id/summary')
  async getMatchSummary(
    @Param('id') matchId: string,
    @Req() req: Request,
  ): Promise<MatchSummary> {
    return this.matchService.getMatchSummary(matchId, req.user!.playerId);
  }
}
