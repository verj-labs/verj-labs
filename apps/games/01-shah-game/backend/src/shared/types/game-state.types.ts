import { type Card } from './card.types';

export type Direction = 'clockwise' | 'counterclockwise';

export type GameStatus = 'waiting' | 'dealing' | 'in_progress' | 'finished';

/** A single play placed on the pile */
export interface Play {
  cards: Card[];
  playerId: string;
  /** true when the played rank is '2' against an active pile (triggers reset) */
  isReset: boolean;
}

/** The current state of the central discard pile */
export interface Pile {
  topPlay: Play | null;
  /** Ordered history of all plays in the current round */
  history: Play[];
}

/** One player's in-game state */
export interface Player {
  id: string;
  displayName: string;
  /** Seat around the table, 0-indexed */
  seatIndex: number;
  hand: Card[];
  isFinished: boolean;
  /** 1 = 1st place, null = not finished yet */
  finishRank: number | null;
}

/** State for a single round (one pile lifecycle) */
export interface RoundState {
  pile: Pile;
  /** Number of consecutive passes since the last valid play */
  consecutivePassCount: number;
  /** playerId of the last person to play a valid set (null = nobody has played this round) */
  lastPlayerId: string | null;
  /** The player index that is currently skipped (same-rank rule); null = none */
  skippedPlayerIndex: number | null;
  /** PlayerIds who have passed in this round (reset when a valid play is made or round ends) */
  passedThisRound: string[];
}

/** Full state of one Game within a Match */
export interface GameState {
  id: string;
  matchId: string;
  gameNumber: number;
  /** 1-based index of the current round within this game */
  roundNumber: number;
  direction: Direction;
  status: GameStatus;
  players: Player[];
  /** Index into `players` of the player whose turn it currently is */
  activePlayerIndex: number;
  currentRound: RoundState;
  /** Ordered list of playerIds who have finished (1st → last) */
  finishedPlayers: string[];
}

// ─── Projection types (what the server sends to each client) ──────────────────

/** A player as visible to all other players — hand cards are hidden */
export interface PlayerView {
  id: string;
  displayName: string;
  seatIndex: number;
  /** Number of cards remaining in hand */
  handCount: number;
  isFinished: boolean;
  finishRank: number | null;
  /** Did this player pass in the current round? */
  passed: boolean;
}

/** The game state delivered to one specific player over the socket */
export interface GameStateView {
  id: string;
  matchId: string;
  gameNumber: number;
  roundNumber: number;
  direction: Direction;
  status: GameStatus;
  activePlayerIndex: number;
  players: PlayerView[];
  /** The viewing player's own hand */
  localHand: Card[];
  currentRound: Omit<RoundState, 'passedThisRound'>;
  finishedPlayers: string[];
}
