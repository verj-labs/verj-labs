import { Logger, UsePipes, ValidationPipe } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

import { AuthService } from '../auth/auth.service';
import { PlayIntentDto } from '../game/dto/play-intent.dto';
import { GameService } from '../game/game.service';
import { GameEvents } from './events.enum';
import { SocketBroadcastService } from './socket-broadcast.service';
import type { MatchSubscribePayload } from '../shared/types/socket-payloads.types';

/** Typed view of the arbitrary socket.data bag */
interface SocketData {
  playerId?: string;
  matchId?: string;
  displayName?: string;
}

@UsePipes(new ValidationPipe({ whitelist: true, transform: true }))
@WebSocketGateway({
  cors: { origin: process.env.FRONTEND_URL ?? '*' },
  namespace: '/',
})
export class GameGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer() server!: Server;
  private readonly logger = new Logger(GameGateway.name);

  // playerId → socket
  private readonly playerSockets = new Map<string, Socket>();

  /**
   * Per-socket promise that resolves when handleConnection finishes.
   * handleMatchSubscribe awaits this so it never sees an unset playerId
   * even when the client emits match:subscribe the instant it connects.
   */
  private readonly connectionReady = new Map<string, Promise<void>>();
  private readonly connectionResolvers = new Map<string, () => void>();

  constructor(
    private readonly authService: AuthService,
    private readonly gameService: GameService,
    private readonly broadcastSvc: SocketBroadcastService,
  ) {}

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  afterInit(server: Server): void {
    this.broadcastSvc.server = server;
    this.logger.log('WebSocket gateway initialised');
  }

  async handleConnection(client: Socket): Promise<void> {
    // Create the ready-promise FIRST so handleMatchSubscribe can await it
    // even if it arrives before we finish the async Redis session lookup.
    let resolve!: () => void;
    this.connectionReady.set(
      client.id,
      new Promise<void>((r) => {
        resolve = r;
        this.connectionResolvers.set(client.id, r);
      }),
    );

    const token: string | undefined =
      ((client.handshake.auth as Record<string, unknown>).token as
        | string
        | undefined) ??
      client.handshake.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      client.disconnect();
      resolve();
      this.connectionReady.delete(client.id);
      this.connectionResolvers.delete(client.id);
      return;
    }

    let sessionPayload:
      | import('../shared/types/session.types').SessionPayload
      | null = null;
    try {
      sessionPayload = await this.authService.getSession(token);
    } catch {
      client.disconnect();
      resolve();
      this.connectionReady.delete(client.id);
      this.connectionResolvers.delete(client.id);
      return;
    }

    if (!sessionPayload) {
      client.disconnect();
      resolve();
      this.connectionReady.delete(client.id);
      this.connectionResolvers.delete(client.id);
      return;
    }

    const { playerId, matchId, displayName } = sessionPayload;
    (client.data as SocketData).playerId = playerId;
    (client.data as SocketData).matchId = matchId ?? undefined;
    (client.data as SocketData).displayName = displayName;

    if (matchId) {
      await client.join(`match:${matchId}`);
      this.logger.log(
        `[connect] Auto-rejoined room match:${matchId} for ${displayName} (from session)`,
      );
    }
    this.playerSockets.set(playerId, client);

    this.logger.log(
      `[connect] ${displayName} (${playerId}) — socket: ${client.id} | ` +
        `total sockets: ${this.playerSockets.size}`,
    );

    // On reconnect: cancel disconnect key and send current game state
    const wasDisconnected = await this.gameService.isDisconnected(playerId);
    if (wasDisconnected) {
      await this.gameService.cancelReconnect(playerId);
      this.broadcastSvc.toRoom(
        `match:${matchId}`,
        GameEvents.PLAYER_RECONNECTED,
        {
          playerId,
          displayName,
        },
      );

      // Send current game state only to the reconnecting socket
      const gameId = await this.gameService.getActiveGameId(matchId as string);
      if (gameId) {
        const gameState = await this.gameService.getGameState(gameId);
        if (gameState) {
          const view = this.gameService.projectStateForPlayer(
            gameState,
            playerId,
          );
          client.emit(GameEvents.STATE_UPDATED, { gameState: view });
        }
      }
    }

    // Signal that handleConnection has finished — any buffered match:subscribe
    // events waiting on connectionReady will now proceed.
    resolve();
    this.connectionReady.delete(client.id);
    this.connectionResolvers.delete(client.id);
  }

  async handleDisconnect(client: Socket): Promise<void> {
    // Clean up any lingering ready-promise (e.g. auth failed mid-connection)
    this.connectionReady.delete(client.id);
    this.connectionResolvers.delete(client.id);

    const { playerId, matchId, displayName } = client.data as SocketData;

    if (!playerId) return;

    this.playerSockets.delete(playerId);
    this.logger.log(
      `[disconnect] ${displayName ?? playerId} disconnected — ` +
        `socket: ${client.id} | matchId: ${matchId ?? 'none'}`,
    );

    if (matchId) {
      await this.gameService.markDisconnected(playerId);
      this.broadcastSvc.toRoom(
        `match:${matchId}`,
        GameEvents.PLAYER_DISCONNECTED,
        {
          playerId,
          displayName: displayName ?? playerId,
        },
      );
    }
  }

  // ─── Incoming events ─────────────────────────────────────────────────────

  @SubscribeMessage(GameEvents.MATCH_SUBSCRIBE)
  async handleMatchSubscribe(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: MatchSubscribePayload,
  ): Promise<void> {
    // If handleConnection is still running its async Redis lookup, wait for it
    // before reading client.data.playerId (otherwise we always see undefined).
    const ready = this.connectionReady.get(client.id);
    if (ready) {
      this.logger.log(
        `[subscribe] Waiting for handleConnection to finish for socket ${client.id}…`,
      );
      await ready;
    }

    const { playerId, displayName } = client.data as SocketData;

    this.logger.log(
      `[subscribe] Received match:subscribe from socket ${client.id} ` +
        `— playerId: ${playerId ?? 'NOT SET YET'} | matchId: ${data.matchId}`,
    );

    if (!playerId) {
      this.logger.warn(
        `[subscribe] Rejecting — socket ${client.id} has no playerId (auth failed?)`,
      );
      return;
    }

    this.logger.log(
      `[subscribe] Player ${displayName ?? playerId} requesting room match:${data.matchId}`,
    );

    // Validate that the player is actually a member of this match
    const matchState = await this.gameService.getMatchState(data.matchId);
    if (
      matchState &&
      !matchState.players.some((p) => p.playerId === playerId)
    ) {
      this.logger.warn(
        `[subscribe] BLOCKED — ${displayName ?? playerId} is NOT a member of match ${data.matchId}`,
      );
      return;
    }

    const room = `match:${data.matchId}`;
    await client.join(room);
    (client.data as SocketData).matchId = data.matchId;

    // Log how many sockets are now in the room
    const roomSockets = await this.server.in(room).allSockets();
    this.logger.log(
      `[subscribe] ${displayName ?? playerId} joined room ${room}. ` +
        `Sockets in room: ${roomSockets.size}`,
    );

    // ── Always send the current match state to the newly-subscribed socket ──
    // This acts as catch-up: if the player missed any `match:updated` broadcasts
    // that fired during the window between their HTTP join and socket subscription
    // (a common race on slow connections or React StrictMode re-mounts), they now
    // get a consistent view without having to wait for the next change.
    if (matchState) {
      this.logger.log(
        `[subscribe] Sending current match state to ${displayName ?? playerId} ` +
          `(${matchState.players.length} players)`,
      );
      client.emit(GameEvents.MATCH_UPDATED, matchState);
    }

    // Persist the matchId in the session so reconnection works
    const token = (client.handshake.auth as Record<string, unknown>).token as
      | string
      | undefined;
    if (token) {
      await this.authService.updateSessionMatchId(token, data.matchId);
    }

    // Send current game state if an active game exists
    const gameId = await this.gameService.getActiveGameId(data.matchId);
    if (gameId) {
      const gameState = await this.gameService.getGameState(gameId);
      const { playerId: pid } = client.data as SocketData;
      if (gameState && pid) {
        this.logger.log(
          `[subscribe] Sending current game state to ${displayName ?? pid}`,
        );
        const view = this.gameService.projectStateForPlayer(gameState, pid);
        client.emit(GameEvents.STATE_UPDATED, { gameState: view });
      }
    }
  }

  @SubscribeMessage(GameEvents.PLAY)
  async handlePlay(
    @ConnectedSocket() client: Socket,
    @MessageBody() dto: PlayIntentDto,
  ): Promise<void> {
    const { playerId, matchId } = client.data as SocketData;

    if (!playerId || !matchId) {
      client.emit(GameEvents.PLAY_REJECTED, { reason: 'Not authenticated.' });
      return;
    }

    const gameId = await this.gameService.getActiveGameId(matchId);
    if (!gameId) {
      client.emit(GameEvents.PLAY_REJECTED, { reason: 'No active game.' });
      return;
    }

    await this.gameService.handlePlayerIntent(
      gameId,
      matchId,
      playerId,
      {
        type: 'play',
        cards: dto.cards.map(
          (c) =>
            ({
              rank: c.rank,
              suit: c.suit,
            }) as import('../shared/types/card.types').Card,
        ),
      },
      client.id,
    );
  }

  @SubscribeMessage(GameEvents.PASS)
  async handlePass(@ConnectedSocket() client: Socket): Promise<void> {
    const { playerId, matchId } = client.data as SocketData;

    if (!playerId || !matchId) {
      client.emit(GameEvents.PLAY_REJECTED, { reason: 'Not authenticated.' });
      return;
    }

    const gameId = await this.gameService.getActiveGameId(matchId);
    if (!gameId) {
      client.emit(GameEvents.PLAY_REJECTED, { reason: 'No active game.' });
      return;
    }

    await this.gameService.handlePlayerIntent(
      gameId,
      matchId,
      playerId,
      { type: 'pass' },
      client.id,
    );
  }
}
