import { type Rank, type SetSize } from '../shared/types/card.types';

/**
 * Rank order for normal game play.
 * The power card '2' is intentionally excluded — it is handled separately via
 * reset mechanics and is not part of the standard "beat the pile" ladder.
 */
export const PLAY_RANK_ORDER: Rank[] = [
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
];

/**
 * Rank order used for the post-game card exchange.
 * '2' is the best card for exchange purposes.
 */
export const EXCHANGE_RANK_ORDER: Rank[] = [...PLAY_RANK_ORDER, '2'];

/**
 * Compare two ranks for normal play purposes.
 * Returns negative when `a < b`, 0 when equal, positive when `a > b`.
 * Passing '2' for either argument is undefined behaviour — use `isReset()` first.
 */
export function comparePlayRank(a: Rank, b: Rank): number {
  return PLAY_RANK_ORDER.indexOf(a) - PLAY_RANK_ORDER.indexOf(b);
}

/**
 * Compare two ranks for exchange evaluation purposes.
 * Returns negative when `a < b`, 0 when equal, positive when `a > b`.
 */
export function compareExchangeRank(a: Rank, b: Rank): number {
  return EXCHANGE_RANK_ORDER.indexOf(a) - EXCHANGE_RANK_ORDER.indexOf(b);
}

/**
 * Returns true only for the power card '2'.
 */
export function isReset(rank: Rank): boolean {
  return rank === '2';
}

/**
 * How many '2' cards are required to reset a pile of the given size.
 *
 * From GAME_RULES.md §12.1:
 *   Single pile  → 1 two
 *   Double pile  → 1 two
 *   Triple pile  → 2 twos
 *   Quad pile    → 3 twos
 */
export function getResetRequirement(pileSize: SetSize): SetSize {
  if (pileSize <= 2) return 1;
  if (pileSize === 3) return 2;
  return 3;
}
