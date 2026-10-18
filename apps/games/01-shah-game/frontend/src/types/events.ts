/**
 * Frontend mirror of backend/src/shared/types/events.types.ts
 *
 * Keep this file in sync with the backend source.  See types/README.md for
 * the sync policy.
 */
import { type Card } from './card';
import { type GameState } from './game-state';

export type GameEventType =
  | 'PILE_UPDATED'
  | 'PILE_RESET'
  | 'PLAYER_SKIPPED'
  | 'PLAYER_PASSED'
  | 'ROUND_ENDED'
  | 'PLAYER_FINISHED'
  | 'GAME_FINISHED'
  | 'TURN_ADVANCED';

export interface GameEvent {
  type: GameEventType;
  payload?: unknown;
}

/** Intent sent by the client over the WebSocket to perform a play or pass */
export interface PlayIntent {
  playerId: string;
  type: 'play' | 'pass';
  /** Present only when type === 'play' */
  cards?: Card[];
}

/** Payload received from the server after an intent is processed */
export interface EngineResult {
  newState: GameState;
  events: GameEvent[];
  /** Set when the intent is invalid; newState equals the unchanged state */
  error?: string;
}

/** Describes one card transfer during the post-game exchange phase */
export interface ExchangeAction {
  giverId: string;
  receiverId: string;
  cards: Card[];
}
