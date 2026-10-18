# 2026-03-01 — EP-008: Match History

## What Changed

### Backend (T-068)
- **`GET /player/me/matches`** — new paginated endpoint returning the authenticated player's match history.
  - Query params: `page` (default 1) and `limit` (default 10, max 50) validated via `MatchHistoryQueryDto`.
  - Each item includes: `matchId`, `roomCode`, `playerCount`, `gamesPlayed`, `bestFinish` (lowest finish rank across all games, or `null`), `status`, `createdAt`.
  - Implemented as `PlayerService.getMatchHistory()` using a Prisma `match.findMany` query filtered via the `matchPlayers` relation, with nested game rankings included.
  - `PlayerController` created (previously the Player module had no controller).
  - `PlayerModule` updated to register the new controller.
  - **14 new unit tests** across `player.service.spec.ts` and `player.controller.spec.ts` — total backend suite: **226 tests**.

### Frontend (T-069)
- **`HistoryPage`** at `/history` — match history list with:
  - Loading skeletons while the API call is in flight.
  - Empty state with CTA to create a room for new players.
  - Match cards showing room code, relative timestamp (built-in `Intl` — no extra dependency), player count, games played, and best finish (highlighted gold for 1st place).
  - "Show more" button for pagination — appends next page to existing list.
  - Clicking a card navigates to `/results/:matchId`.
  - Status badge (Finished / In progress / Lobby).
- **Router** updated — `/history` added as a protected route.
- **LobbyPage** updated — "View match history" link added below the join card.
- **`player.service.ts`** created — `getMatchHistory(page, limit)` API call.
- **9 unit tests** in `HistoryPage.test.tsx` — total frontend suite: **115 tests**.
- All **8 E2E tests** continue to pass.

## Decisions & Trade-offs

- **No external relative-time library** (e.g. `date-fns`): a simple inline helper covers the needed granularity (minutes → months) without adding a dependency.
- **Results page reuse** for history navigation: `/results/:matchId` already handles both live and historical display modes (live from socket payload; historical from `GET /match/:id/summary`), so no new page was needed.

## Docs Updated
- `SYSTEM_DESIGN.md §8.2` — REST endpoint table corrected (was stale) and `GET /player/me/matches` added.
- `SYSTEM_DESIGN.md §9.1` — `/history` route added to the page/view structure.
- `tickets.json` — T-068 and T-069 marked `done`; all 69 tickets are now complete.
