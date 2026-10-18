/**
 * Typed payloads for every server → client and client → server socket event.
 *
 * Keep in sync with frontend/src/types/socket-events.ts
 */

import { type GameStateView } from './game-state.types';

// ── Server → Client ──────────────────────────────────────────────────────────

export interface GameStartedPayload {
  gameId: string;
  matchId: string;
  gameState: GameStateView;
}

export interface StateUpdatedPayload {
  gameState: GameStateView;
}

export interface PlayRejectedPayload {
  reason: string;
}

export interface RoundEndedPayload {
  roundNumber: number;
  winnerId: string | null;
  winnerDisplayName: string | null;
}

export interface PlayerSkippedPayload {
  skippedPlayerId: string;
  skippedDisplayName: string;
}

export interface PileResetPayload {
  byPlayerId: string;
  byDisplayName: string;
}

export interface PlayerFinishedPayload {
  playerId: string;
  displayName: string;
  finishRank: number;
}

export interface GameFinishedPayload {
  gameId: string;
  rankings: Array<{ playerId: string; displayName: string; rank: number }>;
}

export interface ExchangeSummaryPayload {
  gameId: string;
  exchanges: Array<{
    giverId: string;
    giverName: string;
    receiverId: string;
    receiverName: string;
    cardsGiven: import('./card.types').Card[];
  }>;
}

export interface PlayerDisconnectedPayload {
  playerId: string;
  displayName: string;
}

export interface PlayerReconnectedPayload {
  playerId: string;
  displayName: string;
}

export interface MatchUpdatedPayload {
  matchId: string;
  players: Array<{ playerId: string; displayName: string; seatIndex: number }>;
  hostPlayerId: string;
}

export interface MatchHostChangedPayload {
  hostPlayerId: string;
}

export interface PlayerMatchStat {
  playerId: string;
  displayName: string;
  gamesPlayed: number;
  wins: number;
  averageRank: number;
  bestFinish: number;
}

export interface MatchFinishedPayload {
  matchId: string;
  totalGames: number;
  standings: PlayerMatchStat[];
}

// ── Client → Server ──────────────────────────────────────────────────────────

export interface CardPayload {
  rank: string;
  suit: string;
}

export interface PlayPayload {
  cards: CardPayload[];
}

export interface MatchSubscribePayload {
  matchId: string;
}
