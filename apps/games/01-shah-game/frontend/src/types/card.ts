export type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades';

export type Rank =
  | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '10'
  | 'J' | 'Q' | 'K' | 'A' | '2';

/** Number of cards in a set played to the pile */
export type SetSize = 1 | 2 | 3 | 4;

/** A single playing card */
export interface Card {
  rank: Rank;
  suit: Suit;
}

export const SUIT_SYMBOLS: Record<Suit, string> = {
  hearts: '♥',
  diamonds: '♦',
  clubs: '♣',
  spades: '♠',
};

export const RED_SUITS: Suit[] = ['hearts', 'diamonds'];

export function isRedSuit(suit: Suit): boolean {
  return RED_SUITS.includes(suit);
}

/**
 * Numeric rank values for sorting – 3 is lowest, 2 is highest.
 * Matches the Shah Exchange rank ordering defined in GAME_RULES.md.
 */
export const RANK_ORDER: Record<Rank, number> = {
  '3': 1, '4': 2, '5': 3, '6': 4, '7': 5, '8': 6,
  '9': 7, '10': 8, 'J': 9, 'Q': 10, 'K': 11, 'A': 12, '2': 13,
};

/** Stable suit ordering used as a tiebreaker when sorting by rank. */
export const SUIT_ORDER: Record<Suit, number> = {
  clubs: 0, diamonds: 1, hearts: 2, spades: 3,
};

/** Returns a new sorted array: low ranks on the left, high on the right. */
export function sortCards(cards: Card[]): Card[] {
  return [...cards].sort(
    (a, b) =>
      RANK_ORDER[a.rank] - RANK_ORDER[b.rank] ||
      SUIT_ORDER[a.suit] - SUIT_ORDER[b.suit],
  );
}
