/**
 * Frontend play-validity helpers.
 *
 * These mirror the backend rules.service.ts logic but run client-side so the
 * UI can disable cards that can never form a valid play given the current pile.
 * The backend remains the authoritative validator — this is UX-only.
 */
import { type Card, type Rank, RANK_ORDER } from '@/types/card';
import { type Play } from '@/types/game-state';

// ─── Types ────────────────────────────────────────────────────────────────────

/**
 * Stable string key for a card — used in Sets for O(1) lookup.
 * Format: "rank|suit"  (pipe avoids ambiguity with multi-char ranks like "10")
 */
export function cardKey(card: Card): string {
  return `${card.rank}|${card.suit}`;
}

// ─── Reset requirement (mirrors GAME_RULES.md §12.1) ─────────────────────────

/**
 * Number of '2' cards required to reset a pile of a given size.
 *
 * pile size 1 (single)  → single 2  (1 card)
 * pile size 2 (double)  → single 2  (1 card)
 * pile size 3 (triple)  → double 2  (2 cards)
 * pile size 4 (quad)    → triple 2  (3 cards)
 */
const RESET_REQUIREMENT: Record<1 | 2 | 3 | 4, number> = {
  1: 1,
  2: 1,
  3: 2,
  4: 3,
};

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Given the player's hand and the current top play on the pile, returns the
 * set of card keys that can participate in a valid play.
 *
 * Rules:
 *  - Empty pile → every card is a valid round opener → return all keys.
 *  - Active pile:
 *      For rank R in hand where R ≠ '2':
 *        if count(R in hand) >= pileSize AND RANK_ORDER[R] >= RANK_ORDER[pileRank]
 *        → all cards of rank R are playable
 *      For rank '2':
 *        if count('2' in hand) >= RESET_REQUIREMENT[pileSize]
 *        → all '2' cards in hand are playable (player can pick which ones)
 */
export function computePlayableCards(
  hand: Card[],
  topPlay: Play | null,
): Set<string> {
  // Empty pile — any card (and any set size) is a valid opener
  if (topPlay === null) {
    return new Set(hand.map(cardKey));
  }

  const pileSize = topPlay.cards.length as 1 | 2 | 3 | 4;
  const pileRank = topPlay.cards[0].rank;
  const pileRankValue = RANK_ORDER[pileRank];

  // Count cards per rank in hand
  const rankCounts = new Map<Rank, number>();
  for (const card of hand) {
    rankCounts.set(card.rank, (rankCounts.get(card.rank) ?? 0) + 1);
  }

  const playable = new Set<string>();

  for (const card of hand) {
    const count = rankCounts.get(card.rank) ?? 0;

    if (card.rank === '2') {
      // Reset path: need at least RESET_REQUIREMENT[pileSize] twos
      const required = RESET_REQUIREMENT[pileSize];
      if (count >= required) {
        playable.add(cardKey(card));
      }
    } else {
      // Normal path: rank must be >= pile rank AND have enough copies for the set size
      const rankValue = RANK_ORDER[card.rank];
      if (rankValue >= pileRankValue && count >= pileSize) {
        playable.add(cardKey(card));
      }
    }
  }

  return playable;
}
