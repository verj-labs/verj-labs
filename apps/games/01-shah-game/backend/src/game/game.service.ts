import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import type Redis from 'ioredis';
import {
  type EngineResult,
  type GameEvent,
  type PlayIntent,
} from '../shared/types/events.types';
import {
  type Direction,
  type GameState,
  type GameStateView,
  type Player,
  type PlayerView,
  type RoundState,
} from '../shared/types/game-state.types';
import { type MatchState } from '../shared/types/match.types';
import {
  type ExchangeSummaryPayload,
  type GameStartedPayload,
  type RoundEndedPayload,
  type StateUpdatedPayload,
} from '../shared/types/socket-payloads.types';
import { DeckService } from '../game-engine/deck.service';
import { ExchangeService } from '../game-engine/exchange.service';
import { GameEngineService } from '../game-engine/game-engine.service';
import { determineDirection } from '../game-engine/turn.utils';
import { GameEvents } from '../gateway/events.enum';
import { SocketBroadcastService } from '../gateway/socket-broadcast.service';
import { PrismaService } from '../prisma/prisma.service';
import { REDIS_CLIENT } from '../redis/redis.constants';
import type {
  GameStatus as PrismaGameStatus,
  Prisma,
} from '../../generated/prisma/client';

const GAME_STATE_TTL = 86_400; // 24 h
const RECONNECT_WINDOW_SECONDS = 300; // 5 min
const NEXT_GAME_DELAY_MS = 3_000;
const EXCHANGE_DISPLAY_MS = 5_000;

/**
 * Simple in-process mutex keyed by game ID.
 * Prevents concurrent `handlePlayerIntent` calls from creating a read-modify-write
 * race condition on the same game state in Redis.
 *
 * NOTE: This works for a single Node process. For multi-process deployments,
 * replace with a Redis-based lock (e.g., Redlock).
 */
class GameLock {
  private readonly locks = new Map<string, Promise<void>>();

  async acquire(gameId: string): Promise<() => void> {
    // Wait for any existing lock on this game
    while (this.locks.has(gameId)) {
      await this.locks.get(gameId);
    }

    let release!: () => void;
    const promise = new Promise<void>((resolve) => {
      release = resolve;
    });
    this.locks.set(gameId, promise);

    return () => {
      this.locks.delete(gameId);
      release();
    };
  }
}

const gameLock = new GameLock();

@Injectable()
export class GameService {
  private readonly logger = new Logger(GameService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly deckService: DeckService,
    private readonly engine: GameEngineService,
    private readonly broadcast: SocketBroadcastService,
    private readonly exchangeService: ExchangeService,
  ) {}

  // ─── Match start → first game ─────────────────────────────────────────────

  async initGame(matchId: string): Promise<void> {
    const matchRaw = await this.redis.get(`match:${matchId}:state`);
    if (!matchRaw)
      throw new NotFoundException('Match state not found in cache.');
    const matchState = JSON.parse(matchRaw) as MatchState;

    const gameNumber = 1;
    const startPlayerIndex = Math.floor(
      Math.random() * matchState.players.length,
    );
    const gameState = await this.dealAndPersist(
      matchId,
      matchState,
      gameNumber,
      startPlayerIndex,
      'clockwise',
    );

    await this.broadcastGameStarted(matchId, gameState);
  }

  // ─── Intent handling ──────────────────────────────────────────────────────

  async handlePlayerIntent(
    gameId: string,
    matchId: string,
    playerId: string,
    intent: Omit<PlayIntent, 'playerId'>,
    requestingSocketId: string | null,
  ): Promise<void> {
    // Acquire per-game mutex to prevent concurrent read-modify-write races
    const release = await gameLock.acquire(gameId);
    try {
      await this._handlePlayerIntent(
        gameId,
        matchId,
        playerId,
        intent,
        requestingSocketId,
      );
    } finally {
      release();
    }
  }

  private async _handlePlayerIntent(
    gameId: string,
    matchId: string,
    playerId: string,
    intent: Omit<PlayIntent, 'playerId'>,
    requestingSocketId: string | null,
  ): Promise<void> {
    const stateRaw = await this.redis.get(`game:${gameId}:state`);
    if (!stateRaw) {
      if (requestingSocketId) {
        this.broadcast.toSocket(requestingSocketId, GameEvents.PLAY_REJECTED, {
          reason: 'Game state not found.',
        });
      }
      return;
    }

    const state = JSON.parse(stateRaw) as GameState;
    if (state.status === 'finished') return;

    const fullIntent: PlayIntent = { ...intent, playerId };
    const result: EngineResult = this.engine.processIntent(state, fullIntent);

    if (result.error) {
      if (requestingSocketId) {
        this.broadcast.toSocket(requestingSocketId, GameEvents.PLAY_REJECTED, {
          reason: result.error,
        });
      }
      return;
    }

    const newState = result.newState;
    await this.saveGameState(gameId, newState);

    // Fire-and-forget event log (T-048)
    this.persistEngineEvents(
      gameId,
      newState.roundNumber,
      playerId,
      result.events,
    );

    // Emit sub-events before the main state update
    this.emitSubEvents(matchId, result.events, newState);

    // Broadcast projected state to every player in the room
    await this.broadcastStateUpdate(matchId, newState);

    // Handle game-over
    if (newState.status === 'finished') {
      await this.handleGameFinished(gameId, matchId, newState);
      return;
    }

    // Auto-pass for disconnected active player
    await this.scheduleAutoPassIfNeeded(gameId, matchId, newState);
  }

  // ─── Projection ──────────────────────────────────────────────────────────

  projectStateForPlayer(
    state: GameState,
    viewingPlayerId: string,
  ): GameStateView {
    const { passedThisRound, ...roundWithoutPassed } = state.currentRound;

    return {
      id: state.id,
      matchId: state.matchId,
      gameNumber: state.gameNumber,
      roundNumber: state.roundNumber,
      direction: state.direction,
      status: state.status,
      activePlayerIndex: state.activePlayerIndex,
      players: state.players.map(
        (p): PlayerView => ({
          id: p.id,
          displayName: p.displayName,
          seatIndex: p.seatIndex,
          handCount: p.hand.length,
          isFinished: p.isFinished,
          finishRank: p.finishRank,
          passed: passedThisRound.includes(p.id),
        }),
      ),
      localHand:
        state.players.find((p) => p.id === viewingPlayerId)?.hand ?? [],
      currentRound: roundWithoutPassed,
      finishedPlayers: state.finishedPlayers,
    };
  }

  // ─── Disconnect / reconnect ───────────────────────────────────────────────

  async markDisconnected(playerId: string): Promise<void> {
    await this.redis.set(
      `game:reconnect:${playerId}`,
      '1',
      'EX',
      RECONNECT_WINDOW_SECONDS,
    );
  }

  async cancelReconnect(playerId: string): Promise<void> {
    await this.redis.del(`game:reconnect:${playerId}`);
  }

  async isDisconnected(playerId: string): Promise<boolean> {
    return (await this.redis.exists(`game:reconnect:${playerId}`)) === 1;
  }

  // ─── Get current game for a match ─────────────────────────────────────────

  async getActiveGameId(matchId: string): Promise<string | null> {
    return this.redis.get(`game:active:${matchId}`);
  }

  async getMatchState(matchId: string): Promise<MatchState | null> {
    const raw = await this.redis.get(`match:${matchId}:state`);
    return raw ? (JSON.parse(raw) as MatchState) : null;
  }

  async getGameState(gameId: string): Promise<GameState | null> {
    const raw = await this.redis.get(`game:${gameId}:state`);
    return raw ? (JSON.parse(raw) as GameState) : null;
  }

  // ─── Private: game initialisation ────────────────────────────────────────

  private async dealAndPersist(
    matchId: string,
    matchState: MatchState,
    gameNumber: number,
    startPlayerIndex: number,
    direction: Direction,
  ): Promise<GameState> {
    const deck = this.deckService.shuffleDeck(this.deckService.buildDeck());
    const { hands } = this.deckService.dealHands(matchState.playerCount, deck);

    const players: Player[] = matchState.players.map((mp, i) => ({
      id: mp.playerId,
      displayName: mp.displayName,
      seatIndex: mp.seatIndex,
      hand: hands[i] ?? [],
      isFinished: false,
      finishRank: null,
    }));

    // Create Game record in Postgres
    const game = await this.prisma.game.create({
      data: {
        matchId,
        gameNumber,
        status: 'in_progress' as PrismaGameStatus,
        startedPlayerId: players[startPlayerIndex]?.id,
        direction: direction === 'clockwise' ? 'clockwise' : 'counterclockwise',
        startedAt: new Date(),
      },
    });

    const initialRound: RoundState = {
      pile: { topPlay: null, history: [] },
      consecutivePassCount: 0,
      lastPlayerId: null,
      skippedPlayerIndex: null,
      passedThisRound: [],
    };

    const gameState: GameState = {
      id: game.id,
      matchId,
      gameNumber,
      roundNumber: 1,
      direction,
      status: 'in_progress',
      players,
      activePlayerIndex: startPlayerIndex,
      currentRound: initialRound,
      finishedPlayers: [],
    };

    await this.saveGameState(game.id, gameState);
    await this.redis.set(
      `game:active:${matchId}`,
      game.id,
      'EX',
      GAME_STATE_TTL,
    );

    this.logger.log(
      `Game ${game.id} initialised for match ${matchId} (game #${gameNumber})`,
    );
    return gameState;
  }

  // ─── Private: broadcasting helpers ───────────────────────────────────────

  private async broadcastGameStarted(
    matchId: string,
    gameState: GameState,
  ): Promise<void> {
    const room = `match:${matchId}`;
    const sockets = await this.broadcast.socketsInRoom(room);

    this.logger.log(
      `[broadcastGameStarted] game ${gameState.id} | room ${room} | ` +
        `sockets in room: ${sockets.length}`,
    );

    if (sockets.length === 0) {
      this.logger.warn(
        `[broadcastGameStarted] NO sockets in room ${room} — ` +
          `game:started will NOT be delivered to anyone. ` +
          `Clients will receive state via match:subscribe catch-up instead.`,
      );
      return;
    }

    for (const socket of sockets) {
      const { playerId, displayName } = socket.data as {
        playerId?: string;
        displayName?: string;
      };
      if (!playerId) {
        this.logger.warn(
          `[broadcastGameStarted] Skipping socket ${socket.id} — no playerId`,
        );
        continue;
      }

      this.logger.log(
        `[broadcastGameStarted] Sending game:started to ${displayName ?? playerId} (socket ${socket.id})`,
      );
      const payload: GameStartedPayload = {
        gameId: gameState.id,
        matchId,
        gameState: this.projectStateForPlayer(gameState, playerId),
      };
      socket.emit(GameEvents.GAME_STARTED, payload);
    }
  }

  async broadcastStateUpdate(
    matchId: string,
    gameState: GameState,
  ): Promise<void> {
    const sockets = await this.broadcast.socketsInRoom(`match:${matchId}`);
    for (const socket of sockets) {
      const { playerId } = socket.data as { playerId?: string };
      if (!playerId) continue;

      const payload: StateUpdatedPayload = {
        gameState: this.projectStateForPlayer(gameState, playerId),
      };
      socket.emit(GameEvents.STATE_UPDATED, payload);
    }
  }

  private emitSubEvents(
    matchId: string,
    events: GameEvent[],
    state: GameState,
  ): void {
    const room = `match:${matchId}`;

    for (const ev of events) {
      switch (ev.type) {
        case 'PILE_RESET': {
          const payload = ev.payload as { play: { playerId: string } };
          const player = state.players.find(
            (p) => p.id === payload.play.playerId,
          );
          this.broadcast.toRoom(room, GameEvents.PILE_RESET, {
            byPlayerId: payload.play.playerId,
            byDisplayName: player?.displayName ?? '',
          });
          break;
        }
        case 'PLAYER_SKIPPED': {
          const payload = ev.payload as { skippedPlayerIndex: number };
          const skipped = state.players[payload.skippedPlayerIndex];
          this.broadcast.toRoom(room, GameEvents.PLAYER_SKIPPED, {
            skippedPlayerId: skipped?.id ?? '',
            skippedDisplayName: skipped?.displayName ?? '',
          });
          break;
        }
        case 'PLAYER_FINISHED': {
          const payload = ev.payload as {
            playerId: string;
            finishRank: number;
          };
          const player = state.players.find((p) => p.id === payload.playerId);
          this.broadcast.toRoom(room, GameEvents.PLAYER_FINISHED, {
            playerId: payload.playerId,
            displayName: player?.displayName ?? '',
            finishRank: payload.finishRank,
          });
          break;
        }
        case 'ROUND_ENDED': {
          const roundEvPayload = ev.payload as {
            nextPlayerIndex: number;
            endedRoundNumber?: number;
          };
          const lastPlayerId = state.currentRound.lastPlayerId;
          const winner = lastPlayerId
            ? state.players.find((p) => p.id === lastPlayerId)
            : null;
          const roundPayload: RoundEndedPayload = {
            roundNumber: roundEvPayload.endedRoundNumber ?? state.roundNumber,
            winnerId: winner?.id ?? null,
            winnerDisplayName: winner?.displayName ?? null,
          };
          this.broadcast.toRoom(room, GameEvents.ROUND_ENDED, roundPayload);
          break;
        }
        default:
          break;
      }
    }
  }

  // ─── Private: game finished ───────────────────────────────────────────────

  private async handleGameFinished(
    gameId: string,
    matchId: string,
    state: GameState,
  ): Promise<void> {
    const rankings = state.finishedPlayers.map((playerId, idx) => {
      const p = state.players.find((pl) => pl.id === playerId)!;
      return { playerId, displayName: p.displayName, rank: idx + 1 };
    });

    // Persist rankings and close Game record
    await this.prisma.$transaction([
      ...rankings.map((r) =>
        this.prisma.gameRanking.create({
          data: { gameId, playerId: r.playerId, finishRank: r.rank },
        }),
      ),
      this.prisma.game.update({
        where: { id: gameId },
        data: { status: 'finished' as PrismaGameStatus, endedAt: new Date() },
      }),
    ]);

    this.broadcast.toRoom(`match:${matchId}`, GameEvents.GAME_FINISHED, {
      gameId,
      rankings,
    });

    this.logger.log(
      `Game ${gameId} finished. Scheduling next game in ${NEXT_GAME_DELAY_MS}ms`,
    );

    // Schedule next game after delay
    setTimeout(() => {
      void this.startNextGame(matchId, state);
    }, NEXT_GAME_DELAY_MS);
  }

  private async startNextGame(
    matchId: string,
    prevState: GameState,
  ): Promise<void> {
    const matchRaw = await this.redis.get(`match:${matchId}:state`);
    if (!matchRaw) return;
    const matchState = JSON.parse(matchRaw) as MatchState;

    const winnerId = prevState.finishedPlayers[0];
    const secondId = prevState.finishedPlayers[1];

    const winnerPlayer = prevState.players.find((p) => p.id === winnerId);
    const secondPlayer = prevState.players.find((p) => p.id === secondId);

    const direction =
      winnerPlayer && secondPlayer
        ? determineDirection(
            winnerPlayer.seatIndex,
            secondPlayer.seatIndex,
            prevState.players.length,
          )
        : 'clockwise';

    const startIdx = winnerPlayer
      ? matchState.players.findIndex((mp) => mp.playerId === winnerId)
      : 0;

    // Deal fresh hands for the next game
    let gameState = await this.dealAndPersist(
      matchId,
      matchState,
      prevState.gameNumber + 1,
      startIdx >= 0 ? startIdx : 0,
      direction,
    );

    // ── Card exchange (requires ≥ 3 players) ─────────────────────────────
    const rankedPlayers = prevState.finishedPlayers
      .map((pid) => gameState.players.find((p) => p.id === pid))
      .filter((p): p is Player => p !== undefined);

    if (rankedPlayers.length >= 3) {
      const exchangeResult =
        this.exchangeService.computeExchange(rankedPlayers);

      // Apply exchanged hands to the freshly-dealt game state
      const updatedPlayers = gameState.players.map((p) => ({
        ...p,
        hand: exchangeResult.updatedHands.get(p.id) ?? p.hand,
      }));
      gameState = { ...gameState, players: updatedPlayers };

      // Persist the updated state to Redis
      await this.saveGameState(gameState.id, gameState);

      // Persist CARD_EXCHANGE audit event
      await this.prisma.gameEvent.create({
        data: {
          gameId: gameState.id,
          eventType: 'CARD_EXCHANGE',
          payload: exchangeResult.actions as unknown as Prisma.InputJsonValue,
        },
      });

      // Build the exchange summary payload for clients
      const exchangeSummary: ExchangeSummaryPayload = {
        gameId: gameState.id,
        exchanges: exchangeResult.actions.map((action) => {
          const giver = gameState.players.find((p) => p.id === action.giverId);
          const receiver = gameState.players.find(
            (p) => p.id === action.receiverId,
          );
          return {
            giverId: action.giverId,
            giverName: giver?.displayName ?? '',
            receiverId: action.receiverId,
            receiverName: receiver?.displayName ?? '',
            cardsGiven: action.cards,
          };
        }),
      };

      this.broadcast.toRoom(
        `match:${matchId}`,
        GameEvents.GAME_EXCHANGE,
        exchangeSummary,
      );
      this.logger.log(
        `Game ${gameState.id}: emitted game:exchange (${exchangeResult.actions.length} actions)`,
      );

      // Broadcast game:started after the client-side exchange UI finishes
      const frozenState = gameState;
      setTimeout(() => {
        void this.broadcastGameStarted(matchId, frozenState);
      }, EXCHANGE_DISPLAY_MS);
    } else {
      // No exchange needed — start immediately
      await this.broadcastGameStarted(matchId, gameState);
    }
  }

  // ─── Private: auto-pass for disconnected players ──────────────────────────

  private async scheduleAutoPassIfNeeded(
    gameId: string,
    matchId: string,
    state: GameState,
  ): Promise<void> {
    if (state.status === 'finished') return;

    const activePlayers = state.players.filter((p) => !p.isFinished);
    // Guard: if only one player remains, the game should already be finished
    // (auto-finish last player). Bail to prevent an infinite loop.
    if (activePlayers.length <= 1) return;

    const activePlayer = state.players[state.activePlayerIndex];
    if (!activePlayer) return;

    const disconnected = await this.isDisconnected(activePlayer.id);
    if (!disconnected) return;

    const capturedPlayerId = activePlayer.id;

    // Delay so clients see the state update before the auto-pass
    setTimeout(() => {
      void (async () => {
        // Re-check disconnect status at execution time to avoid auto-passing
        // a player who reconnected within the window
        const stillDisconnected = await this.isDisconnected(capturedPlayerId);
        if (!stillDisconnected) return;

        await this.handlePlayerIntent(
          gameId,
          matchId,
          capturedPlayerId,
          { type: 'pass' },
          null,
        );
      })();
    }, 800);
  }

  // ─── Private: persistence ─────────────────────────────────────────────────

  private async saveGameState(gameId: string, state: GameState): Promise<void> {
    await this.redis.set(
      `game:${gameId}:state`,
      JSON.stringify(state),
      'EX',
      GAME_STATE_TTL,
    );
  }

  private persistEngineEvents(
    gameId: string,
    roundNumber: number,
    playerId: string,
    events: GameEvent[],
  ): void {
    // Fire-and-forget; failures are logged but never surface to the caller
    void (async () => {
      try {
        for (const ev of events) {
          if (ev.type === 'TURN_ADVANCED' || ev.type === 'PILE_UPDATED')
            continue;
          await this.prisma.gameEvent.create({
            data: {
              gameId,
              playerId,
              eventType: ev.type,
              payload: (ev.payload ?? null) as unknown as Prisma.InputJsonValue,
            },
          });
        }
      } catch (err) {
        this.logger.warn(
          `Event log write failed for game ${gameId}: ${String(err)}`,
        );
      }
    })();
  }
}
