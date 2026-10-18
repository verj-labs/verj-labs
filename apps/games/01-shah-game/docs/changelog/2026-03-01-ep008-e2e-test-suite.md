# 2026-03-01 — Comprehensive Playwright E2E Test Suite

## What Changed

Added 13 new E2E tests and 8 new helper functions covering the complete game
lifecycle from setup through card exchange to match results.

### New helpers (`e2e/helpers/game.ts`)

| Helper | Purpose |
|--------|---------|
| `setupGame` | Full register → create → join → start → wait-for-board sequence |
| `findActivePage` | Finds the player whose pass-button is currently enabled |
| `tryPlayFirstCard` | Plays on empty pile (lead), passes on non-empty pile |
| `waitForTurnToAdvance` | Waits for ActionBar to indicate turn advanced |
| `getHandCount` | Returns count of cards in local hand |
| `waitForGameFinishedDialog` | Waits for `[aria-label="Game results"]` dialog |
| `waitForExchangeDialog` | Waits for `[aria-label="Card exchange"]` dialog |
| `driveFullGame` | Loops until game:finished dialog — drives the full game |

### New test files (13 tests)

- `tests/gameplay/pile-rules.spec.ts` — 3 tests: first play visible, turn enforcement, pile clear
- `tests/gameplay/full-game.spec.ts` — 3 tests: game completion, hand count, winner display
- `tests/exchange/card-exchange.spec.ts` — 3 tests: exchange dialog, transfer list, next game
- `tests/match/match-lifecycle.spec.ts` — 3 tests: end-match, results page, back-to-lobby
- `tests/gameplay/turn-enforcement.spec.ts` — +1 test: exactly one active player at start

## Bugs Found and Fixed During Implementation

### Bug 1: `locator.isEnabled()` hangs when ActionBar unmounts
**Root cause**: `isEnabled()` waits up to `actionTimeout` (15s) for the element to appear.
When the game ends and `ActionBar` unmounts, `pass-button` disappears. The 15-retry loop
in `findActivePage` would hang until the next game started (3s), then detect the next
game's active player — rolling the loop silently into subsequent games.

**Fix**: Replace `isEnabled()` with `page.evaluate(() => !!(btn && !btn.disabled))`.
`evaluate()` is an instant DOM snapshot with zero waiting.

### Bug 2: AnimatePresence keeps pile-top visible during exit animation
**Root cause**: `PileDisplay` uses `<AnimatePresence mode="wait">` which keeps the
outgoing card in the DOM for ~200ms during its exit animation. Our original check on
`data-testid="pile-top"` returned `isVisible()=true` even after `topPlay` became null.
This caused the round leader to incorrectly pass (thinking pile has cards) instead of
playing (leading a new round).

**Fix**: Check the pile label text `getByText('Pile (empty)', { exact: true })` instead.
This label updates instantly (it's outside AnimatePresence) when `pile.history = []`.

### Bug 3: `isVisible()` also has actionTimeout latency
Same issue as Bug 1 but for dialog visibility checks in `driveFullGame`. The game:finished
dialog only shows for 3 seconds; if `isVisible()` waits 15s for the element, we miss the
window and roll into the next game.

**Fix**: Created `isGameResultsVisible()` using `page.evaluate()` for instant DOM checking.

### Bug 4: `waitForTurnToAdvance` took 5s when game ended
**Root cause**: `expect(...).toBeDisabled()` waited up to 5s for a missing element (ActionBar
gone, pass-button doesn't exist). During those 5s the game:finished dialog opened and closed.

**Fix**: Replaced with `page.waitForFunction(() => !btn || btn.disabled)` which resolves
immediately when the button is gone (`!btn`) or disabled.

## Decisions / Trade-offs

- **Pile driving strategy**: "Play on empty pile, pass otherwise" — deterministic and fast.
  One player leads; others pass until the pile clears; leader plays again. A 4-player game
  completes in ~130 turns (~30 seconds). Trying to play valid cards would require reading
  card ranks and comparing against the pile, which was deemed over-engineered for test helpers.

- **`page.evaluate()` over locator methods**: Locator methods (`isEnabled`, `isVisible`) were
  designed for assertions (with retries and waits). For tight game-loop polling, instant DOM
  snapshots via `evaluate()` are the correct tool.

- **Out-of-scope**: Skip rule, power card 2 reset, counterclockwise direction, and exact card
  exchange correctness — these require seeded decks or internal state inspection not available
  from the UI. Covered by existing backend unit tests.
