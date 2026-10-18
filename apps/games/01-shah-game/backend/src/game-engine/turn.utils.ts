import { type Direction } from '../shared/types/game-state.types';
import { type GameState } from '../shared/types/game-state.types';

/**
 * Find the index of the next active (non-finished) player to take a turn.
 *
 * @param state         Current game state (used for direction + player list).
 * @param currentIndex  The player index whose turn is currently ending.
 * @param skipCount     Extra active players to skip beyond the normal one-step
 *                      advance.  Pass 1 for the same-rank skip rule.
 * @returns The index of the next active player, or -1 if none remain
 *          (game should have already transitioned to FINISHED before this occurs).
 */
export function getNextActivePlayerIndex(
  state: GameState,
  currentIndex: number,
  skipCount: number = 0,
): number {
  const { players, direction } = state;
  const n = players.length;
  if (n === 0) return -1;

  const step = direction === 'clockwise' ? 1 : -1;
  let idx = currentIndex;

  // We need to consume (1 + skipCount) active player slots.
  // Finished players are traversed over without consuming a slot.
  let activesNeeded = 1 + skipCount;

  // Safety bound: at most n full laps around the table.
  for (let attempt = 0; attempt < n * n; attempt++) {
    idx = (((idx + step) % n) + n) % n;
    if (!players[idx].isFinished) {
      activesNeeded--;
      if (activesNeeded === 0) return idx;
    }
  }

  return -1; // all remaining players finished
}

/**
 * Determine the play direction for a new game based on the seating of the
 * winner (1st place) and the runner-up (2nd place).
 *
 * From GAME_RULES.md §6.3:
 *   - If 2nd place is on the winner's right side → clockwise
 *   - If 2nd place is on the winner's left side  → counterclockwise
 *   - Exactly opposite (even player count)       → clockwise (tie-break)
 *
 * @param winnerSeatIndex       Seat index of the game winner.
 * @param secondPlaceSeatIndex  Seat index of the 2nd-place finisher.
 * @param totalPlayers          Total number of players (4–8).
 */
export function determineDirection(
  winnerSeatIndex: number,
  secondPlaceSeatIndex: number,
  totalPlayers: number,
): Direction {
  if (winnerSeatIndex === secondPlaceSeatIndex) {
    // Guard: should never happen in a real game.
    return 'clockwise';
  }

  // Number of clockwise steps from the winner to 2nd place.
  const stepsClockwise =
    (((secondPlaceSeatIndex - winnerSeatIndex) % totalPlayers) + totalPlayers) %
    totalPlayers;

  // If the clockwise distance is ≤ half the table, 2nd is on the right → clockwise.
  // This also handles the exactly-opposite tie-break (stepsClockwise === n/2).
  return stepsClockwise <= Math.floor(totalPlayers / 2)
    ? 'clockwise'
    : 'counterclockwise';
}
