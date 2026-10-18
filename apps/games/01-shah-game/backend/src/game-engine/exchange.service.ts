import { Injectable } from '@nestjs/common';
import { type Card } from '../shared/types/card.types';
import { type ExchangeAction } from '../shared/types/events.types';
import { type Player } from '../shared/types/game-state.types';

// ─── Ordering constants ────────────────────────────────────────────────────────

/** Exchange rank order: 3 is worst (0), 2 is best (12) */
const EXCHANGE_RANK_INDEX: Record<string, number> = {
  '3': 0,
  '4': 1,
  '5': 2,
  '6': 3,
  '7': 4,
  '8': 5,
  '9': 6,
  '10': 7,
  J: 8,
  Q: 9,
  K: 10,
  A: 11,
  '2': 12,
};

/** Suit tiebreaker: spades worst (0), hearts best (3) */
const SUIT_INDEX: Record<string, number> = {
  spades: 0,
  clubs: 1,
  diamonds: 2,
  hearts: 3,
};

function cardScore(card: Card): number {
  return (
    (EXCHANGE_RANK_INDEX[card.rank] ?? 0) * 10 + (SUIT_INDEX[card.suit] ?? 0)
  );
}

// ─── Result type ───────────────────────────────────────────────────────────────

export interface ExchangeResult {
  actions: ExchangeAction[];
  /** Updated hands keyed by playerId */
  updatedHands: Map<string, Card[]>;
}

// ─── Service ───────────────────────────────────────────────────────────────────

@Injectable()
export class ExchangeService {
  /**
   * Returns the `count` worst cards from `hand` by exchange rank
   * (3 < 4 < … < A < 2; spades < clubs < diamonds < hearts as tiebreaker).
   *
   * If count >= hand.length returns a shallow copy of the full hand.
   * If hand is empty or count <= 0 returns [].
   */
  getWorstCards(hand: Card[], count: number): Card[] {
    if (hand.length === 0 || count <= 0) return [];
    const sorted = [...hand].sort((a, b) => cardScore(a) - cardScore(b));
    return sorted.slice(0, Math.min(count, hand.length));
  }

  /**
   * Returns the `count` best cards from `hand` by exchange rank.
   */
  getBestCards(hand: Card[], count: number): Card[] {
    if (hand.length === 0 || count <= 0) return [];
    const sorted = [...hand].sort((a, b) => cardScore(b) - cardScore(a));
    return sorted.slice(0, Math.min(count, hand.length));
  }

  /**
   * Computes the card exchange after a game ends.
   *
   * @param rankedPlayers - Players ordered by finish rank (index 0 = 1st place / winner)
   *
   * Exchange rules (n ≥ 3 required):
   *   - 1st ↔ last:        1st gives 2 worst, last gives 2 best
   *   - 2nd ↔ 2nd-to-last: 2nd gives 1 worst, 2nd-to-last gives 1 best
   *     (skipped for 3 players — 2nd and 2nd-to-last are the same person)
   *
   * @returns ExchangeResult with action log and per-player updated hands
   */
  computeExchange(rankedPlayers: Player[]): ExchangeResult {
    const n = rankedPlayers.length;

    // Start with independent copies of every player's hand
    const updatedHands = new Map<string, Card[]>(
      rankedPlayers.map((p) => [p.id, [...p.hand]]),
    );
    const actions: ExchangeAction[] = [];

    if (n < 3) {
      return { actions, updatedHands };
    }

    const first = rankedPlayers[0];
    const last = rankedPlayers[n - 1];

    // 1st ↔ last (2 cards)
    this.applyPairExchange(first, last, 2, updatedHands, actions);

    // 2nd ↔ 2nd-to-last (1 card) — only when there are distinct middle players
    if (n >= 4) {
      const second = rankedPlayers[1];
      const secondLast = rankedPlayers[n - 2];
      this.applyPairExchange(second, secondLast, 1, updatedHands, actions);
    }

    return { actions, updatedHands };
  }

  // ─── Private helpers ──────────────────────────────────────────────────────────

  private applyPairExchange(
    winner: Player,
    loser: Player,
    count: number,
    hands: Map<string, Card[]>,
    actions: ExchangeAction[],
  ): void {
    const winnerHand = hands.get(winner.id) ?? [];
    const loserHand = hands.get(loser.id) ?? [];

    const winnerGives = this.getWorstCards(winnerHand, count);
    const loserGives = this.getBestCards(loserHand, count);

    hands.set(
      winner.id,
      this.removeCards(winnerHand, winnerGives).concat(loserGives),
    );
    hands.set(
      loser.id,
      this.removeCards(loserHand, loserGives).concat(winnerGives),
    );

    if (winnerGives.length > 0) {
      actions.push({
        giverId: winner.id,
        receiverId: loser.id,
        cards: winnerGives,
      });
    }
    if (loserGives.length > 0) {
      actions.push({
        giverId: loser.id,
        receiverId: winner.id,
        cards: loserGives,
      });
    }
  }

  private removeCards(hand: Card[], toRemove: Card[]): Card[] {
    const remaining = [...hand];
    for (const card of toRemove) {
      const idx = remaining.findIndex(
        (c) => c.rank === card.rank && c.suit === card.suit,
      );
      if (idx !== -1) remaining.splice(idx, 1);
    }
    return remaining;
  }
}
