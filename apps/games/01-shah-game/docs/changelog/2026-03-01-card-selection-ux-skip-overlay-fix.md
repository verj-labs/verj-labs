# 2026-03-01 — Card Selection UX + SkipOverlay Fix

## What Changed

### New: `frontend/src/lib/playable.ts`
Client-side utility for computing which cards in a player's hand are playable
against the current pile state. Used solely for UX disabling — the backend
remains authoritative for validation.

Key exports:
- `cardKey(card): string` — `"rank|suit"` composite key for Set lookups
- `computePlayableCards(hand, topPlay): Set<string>` — returns playable card
  keys, honouring RESET_REQUIREMENT rules for '2' power cards

### Modified: `frontend/src/components/ui/LocalPlayerHand.tsx`
Added two independent disabling layers on top of the existing `!isMyTurn ||
isActionPending` gate:

1. **Pile-based disabling** (`pileBlocks`) — when facing an active pile, any
   card that cannot legally beat it (wrong rank, insufficient count, or
   insufficient '2's for a reset) is disabled immediately, before the player
   selects anything.
2. **Same-rank selection filter** (`rankBlocks`) — after the player selects one
   card, all cards of a different rank are disabled, preventing illegal
   mixed-rank submissions.

Both guards are lifted when the card is already in the selection set
(`!isSelected` guard), so a selected card is never auto-disabled.

### Modified: `frontend/src/features/game/SkipOverlay.tsx`

**Bug fixed**: overlay never dismissed when a `game:state_updated` event fired
within the 900 ms dismiss window.

Root cause: the timer `useEffect` listed `gameState?.players` in its deps array.
Any game state update (which always arrives ≈50 ms after `game:player_skipped`)
triggered cleanup → cancelled the active `setTimeout`. The re-run bailed because
`lastIdRef.current === skippedPlayerId`, so the timer was never restarted.

Fix: extracted player-list access into a separate `useRef<PlayerView[]>` synced
by its own `useEffect([gameState?.players])`. The timer effect now depends only
on `[skippedPlayerId]`, so player-list updates cannot cancel an in-flight timer.

### New: `e2e/tests/gameplay/card-selection.spec.ts`
Three E2E tests covering the new UX:

| # | Test | What it verifies |
|---|------|-----------------|
| 1 | Same-rank filter | After selecting card X, DOM `disabled` attribute set on all non-X-rank cards |
| 2 | Pile-based filter | After a single is played, next player's disabled cards all have rank < pile rank |
| 3 | Skip overlay dismiss | Overlay appears and disappears within 2 s each time; not visible after game ends |

Test 3 logs a warning if no skip event fires in the run (stochastic card
distribution). The test still passes — it is valid as a non-regression check.

## Why
- Player UX complaint: no visual feedback that a card is unplayable before you
  try to submit — resulted in confusing error toasts.
- Skip overlay was effectively broken in production-like conditions: the event
  ordering between `game:player_skipped` and `game:state_updated` always
  triggered the timer-cancel bug.

## Trade-offs / Decisions
- Client-side `computePlayableCards` duplicates a subset of backend logic. This
  is intentional: it is view-only UX, not validation. Keeping backend
  authoritative avoids any security concern while giving rich immediate feedback.
- `RESET_REQUIREMENT` map in `playable.ts` is defined locally (not re-exported
  from game-engine). If reset rules change, both locations must be updated — a
  comment in the code notes this.
- The SkipOverlay fix uses the `ref-sync` pattern (separate effect → ref → read
  in timer effect). Alternative (useCallback memoised lookup) was considered but
  adds more indirection for no benefit.

## Test Results
`pnpm test` in `01-shah-game/e2e/`: **27/27 passed** (24 pre-existing + 3 new).
