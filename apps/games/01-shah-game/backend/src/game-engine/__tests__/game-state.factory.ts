import { type Card, type Rank, type Suit } from '../../shared/types/card.types';
import {
  type Direction,
  type GameState,
  type Player,
} from '../../shared/types/game-state.types';

// ─── Card shortcuts ───────────────────────────────────────────────────────────

export function card(rank: Rank, suit: Suit = 'spades'): Card {
  return { rank, suit };
}

/** Build a hand of n sequential cards (for filling a hand quickly). */
export function handOf(cards: Card[]): Card[] {
  return [...cards];
}

// ─── Player builder ───────────────────────────────────────────────────────────

export function makePlayer(
  id: string,
  seatIndex: number,
  hand: Card[] = [],
  overrides: Partial<Player> = {},
): Player {
  return {
    id,
    displayName: `Player ${id}`,
    seatIndex,
    hand,
    isFinished: false,
    finishRank: null,
    ...overrides,
  };
}

// ─── GameState builder ────────────────────────────────────────────────────────

export interface MakeStateOptions {
  players?: Player[];
  activePlayerIndex?: number;
  direction?: Direction;
  consecutivePassCount?: number;
  lastPlayerId?: string | null;
  topPlay?: import('../../shared/types/game-state.types').Play | null;
  finishedPlayers?: string[];
  gameNumber?: number;
  status?: import('../../shared/types/game-state.types').GameStatus;
}

export function makeGameState(opts: MakeStateOptions = {}): GameState {
  const players =
    opts.players ??
    [0, 1, 2, 3].map((i) =>
      makePlayer(`p${i}`, i, [
        card('3'),
        card('4'),
        card('5'),
        card('6'),
        card('7'),
        card('8'),
        card('9'),
        card('10'),
        card('J'),
        card('Q'),
        card('K'),
      ]),
    );

  return {
    id: 'game-1',
    matchId: 'match-1',
    gameNumber: opts.gameNumber ?? 1,
    roundNumber: 1,
    direction: opts.direction ?? 'clockwise',
    status: opts.status ?? 'in_progress',
    players,
    activePlayerIndex: opts.activePlayerIndex ?? 0,
    currentRound: {
      pile: {
        topPlay: opts.topPlay !== undefined ? opts.topPlay : null,
        history: opts.topPlay ? [opts.topPlay] : [],
      },
      consecutivePassCount: opts.consecutivePassCount ?? 0,
      lastPlayerId: opts.lastPlayerId !== undefined ? opts.lastPlayerId : null,
      skippedPlayerIndex: null,
      passedThisRound: [],
    },
    finishedPlayers: opts.finishedPlayers ?? [],
  };
}

/** Helper to create a Play object (used for setting topPlay in tests). */
export function makePlay(
  cards: Card[],
  playerId: string = 'p0',
  isReset = false,
): import('../../shared/types/game-state.types').Play {
  return { cards, playerId, isReset };
}
