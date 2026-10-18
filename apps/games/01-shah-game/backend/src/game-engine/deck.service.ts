import { Injectable } from '@nestjs/common';
import { type Card, type Rank, type Suit } from '../shared/types/card.types';

const SUITS: Suit[] = ['hearts', 'diamonds', 'clubs', 'spades'];

const RANKS: Rank[] = [
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  'J',
  'Q',
  'K',
  'A',
  '2',
];

/** Cards dealt per player, keyed by player count */
const CARDS_PER_PLAYER: Record<number, number> = {
  3: 17,
  4: 13,
  5: 10,
  6: 8,
  7: 7,
  8: 6,
};

/**
 * Mulberry32 — a fast seeded PRNG returning values in [0, 1).
 * Used so shuffle results are reproducible in tests.
 */
function mulberry32(seed: number): () => number {
  let s = seed;
  return function (): number {
    s += 0x6d2b79f5;
    let t = Math.imul(s ^ (s >>> 15), s | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4_294_967_296;
  };
}

@Injectable()
export class DeckService {
  /**
   * Build a complete, ordered 52-card deck.
   * Pure function — always returns the same output.
   */
  buildDeck(): Card[] {
    const deck: Card[] = [];
    for (const suit of SUITS) {
      for (const rank of RANKS) {
        deck.push({ rank, suit });
      }
    }
    return deck;
  }

  /**
   * Fisher-Yates shuffle.
   * @param deck  Source deck — not mutated.
   * @param seed  Optional numeric seed for deterministic output.
   */
  shuffleDeck(deck: Card[], seed?: number): Card[] {
    const result = [...deck];
    const rand = seed !== undefined ? mulberry32(seed) : Math.random;
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }

  /**
   * Deal cards to `playerCount` players from the top of the deck.
   * Remaining cards are returned as `discarded`.
   * @throws Error when playerCount is not 4–8.
   */
  dealHands(
    playerCount: number,
    deck: Card[],
  ): { hands: Card[][]; discarded: Card[] } {
    const cardsEach = CARDS_PER_PLAYER[playerCount];
    if (cardsEach === undefined) {
      throw new Error(
        `Invalid player count: ${playerCount}. Must be between 3 and 8.`,
      );
    }

    const hands: Card[][] = [];
    let cursor = 0;
    for (let i = 0; i < playerCount; i++) {
      hands.push(deck.slice(cursor, cursor + cardsEach));
      cursor += cardsEach;
    }

    return { hands, discarded: deck.slice(cursor) };
  }
}
