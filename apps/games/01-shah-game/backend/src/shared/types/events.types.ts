import { type Card } from './card.types';
import { type GameState } from './game-state.types';

export type GameEventType =
  | 'PILE_UPDATED'
  | 'PILE_RESET'
  | 'PLAYER_SKIPPED'
  | 'PLAYER_PASSED'
  | 'ROUND_ENDED'
  | 'PLAYER_FINISHED'
  | 'GAME_FINISHED'
  | 'TURN_ADVANCED'
  | 'CARD_EXCHANGE';

export interface GameEvent {
  type: GameEventType;
  payload?: unknown;
}

/** Intent sent by a client to the engine */
export interface PlayIntent {
  playerId: string;
  type: 'play' | 'pass';
  /** Present only when type === 'play' */
  cards?: Card[];
}

/** What the engine returns after processing an intent */
export interface EngineResult {
  newState: GameState;
  events: GameEvent[];
  /** Set when the intent is invalid; newState equals the input state unchanged */
  error?: string;
}

/** Describes one card transfer during the post-game exchange */
export interface ExchangeAction {
  giverId: string;
  receiverId: string;
  cards: Card[];
}
