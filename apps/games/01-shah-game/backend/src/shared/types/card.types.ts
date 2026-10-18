export type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades';

export type Rank =
  | '3'
  | '4'
  | '5'
  | '6'
  | '7'
  | '8'
  | '9'
  | '10'
  | 'J'
  | 'Q'
  | 'K'
  | 'A'
  | '2';

/** The number of cards in a single play (set) */
export type SetSize = 1 | 2 | 3 | 4;

export interface Card {
  rank: Rank;
  suit: Suit;
}
