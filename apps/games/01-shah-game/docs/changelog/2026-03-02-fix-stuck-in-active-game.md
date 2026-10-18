# Fix: "Stuck in active game" — rejoin flow + stale-check in createMatch

## What changed

### Backend — `match.service.ts`
- Extracted the stale-membership guard into a new private method `resolveStaleMatch(playerId, excludeMatchId?)`.
  - `lobby` status → unchanged: auto-removes the stale entry.
  - `in_progress` status → throws `ConflictException` with a **structured body** `{ message, matchId }` so clients can offer a rejoin link without guessing.
- **`createMatch` now also calls `resolveStaleMatch`** before creating the new match record. Previously the stale guard only ran in `joinMatch`, so a player stuck in an `in_progress` game could still create (but not join) a new room — silently producing conflicting DB state.

### Frontend — `LobbyPage.tsx`
- `parseJoinError` now returns `{ message: string, rejoinMatchId?: string }` instead of a plain string; it reads `matchId` from the 409 response body.
- Added `rejoinMatchId` state; both `handleCreate` and `handleJoin` populate it on active-game errors.
- Added a **"You still have an active game" banner** (`data-testid="rejoin-game-button"`) that appears above the create/join cards whenever `rejoinMatchId` is set. Clicking it navigates to `/game/:matchId`.
- Inline error text for create/join is suppressed when the banner is showing (avoids redundant messaging).

## Why

The error message "Still in an active game — wait for it to finish or rejoin it." had been appearing when a player navigated away from an in-progress game and returned to the lobby. There was no UI way to get back into the game, leaving the player permanently locked out of creating/joining until an admin cleared the DB row.

The design session changes were purely visual and did not introduce this bug; the underlying stale-guard logic was always present. The bug became more visible after improving the `parseJoinError` message.

## Decisions

- The 409 response shape changed from `string` → `{ message, matchId }`. All existing frontend `parseJoinError` consumers are in this file only so no other callers are affected.
- Did NOT add an "abandon match" endpoint — the game rules require the host to explicitly end a match. The rejoin flow is sufficient for the happy path.
