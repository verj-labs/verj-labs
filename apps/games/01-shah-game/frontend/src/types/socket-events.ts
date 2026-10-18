/**
 * Frontend mirror of backend/src/shared/types/socket-payloads.types.ts
 *
 * Keep this file in sync with the backend source.
 */
import { type Card } from './card';
import { type GameStateView } from './game-state';

// ─── Server → Client ─────────────────────────────────────────────────────────

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
  rankings: Array<{
    playerId: string;
    displayName: string;
    rank: number;
  }>;
}

export interface ExchangeSummaryPayload {
  gameId: string;
  exchanges: Array<{
    giverId: string;
    giverName: string;
    receiverId: string;
    receiverName: string;
    cardsGiven: Card[];
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

// ─── Client → Server ─────────────────────────────────────────────────────────

export interface PlayPayload {
  cards: Card[];
}
