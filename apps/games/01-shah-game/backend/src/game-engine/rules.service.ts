import { Injectable } from '@nestjs/common';
import { type Card } from '../shared/types/card.types';
import { type GameState } from '../shared/types/game-state.types';
import { type PlayIntent } from '../shared/types/events.types';
import { comparePlayRank, getResetRequirement, isReset } from './rank.utils';

export interface ValidationResult {
  valid: boolean;
  reason?: string;
  /** true when the play is valid AND constitutes a pile reset */
  isReset?: boolean;
}

/** Return true if `subset` is fully contained within `superset`. */
function containsAllCards(superset: Card[], subset: Card[]): boolean {
  const counts = new Map<string, number>();
  for (const card of superset) {
    const key = `${card.rank}:${card.suit}`;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  for (const card of subset) {
    const key = `${card.rank}:${card.suit}`;
    const remaining = counts.get(key) ?? 0;
    if (remaining === 0) return false;
    counts.set(key, remaining - 1);
  }
  return true;
}

@Injectable()
export class RulesService {
  /**
   * Validate a play intent against the current game state.
   *
   * Handles both the normal-play path and the reset path (all cards rank '2').
   * Returns `{ valid: true }` or `{ valid: false, reason }`.
   */
  validatePlay(state: GameState, intent: PlayIntent): ValidationResult {
    if (intent.type === 'pass') {
      return { valid: true };
    }

    const cards = intent.cards ?? [];
    if (cards.length === 0) {
      return { valid: false, reason: 'No cards provided.' };
    }

    // Find the player
    const player = state.players.find((p) => p.id === intent.playerId);
    if (!player) {
      return { valid: false, reason: 'Player not found.' };
    }

    // Rule: must be your turn
    if (state.players[state.activePlayerIndex]?.id !== player.id) {
      return { valid: false, reason: 'It is not your turn.' };
    }

    // Rule: all cards must be in the player's hand
    if (!containsAllCards(player.hand, cards)) {
      return {
        valid: false,
        reason: 'One or more cards are not in your hand.',
      };
    }

    // Rule: all cards must share the same rank
    const playRank = cards[0].rank;
    if (cards.some((c) => c.rank !== playRank)) {
      return {
        valid: false,
        reason: 'All played cards must have the same rank.',
      };
    }

    const pile = state.currentRound.pile;
    const pileTopPlay = pile.topPlay;

    // ── Reset path (all cards are '2' and pile is active) ──────────────────────
    if (isReset(playRank) && pileTopPlay !== null) {
      const pileSize = pileTopPlay.cards.length;
      const required = getResetRequirement(pileSize as 1 | 2 | 3 | 4);

      if (cards.length !== required) {
        const word = required === 1 ? 'one 2' : `${required} 2s`;
        return {
          valid: false,
          reason: `Need exactly ${word} to reset a ${pileSize}-card pile.`,
        };
      }

      return { valid: true, isReset: true };
    }

    // ── Normal play path ───────────────────────────────────────────────────────

    // If pile is active, enforce set-size and rank constraints
    if (pileTopPlay !== null) {
      // Rule: set size must match the pile
      const setSize = cards.length;
      const pileSetSize = pileTopPlay.cards.length;

      if (setSize !== pileSetSize) {
        return {
          valid: false,
          reason: `Must play a ${pileSetSize}-card set to match the pile.`,
        };
      }

      // Rule: rank must be >= pile rank
      const pileRank = pileTopPlay.cards[0].rank;

      // '2' on an active pile with a non-'2' rule rank comparison is fine
      // (already handled above for reset; here pileRank won't be '2')
      if (!isReset(playRank)) {
        if (comparePlayRank(playRank, pileRank) < 0) {
          return {
            valid: false,
            reason: `Must play rank ${pileRank} or higher.`,
          };
        }
      }
    }

    return { valid: true, isReset: false };
  }
}
