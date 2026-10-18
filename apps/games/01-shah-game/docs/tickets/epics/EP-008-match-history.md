# EP-008 — Match History

| Field | Value |
|---|---|
| **ID** | EP-008 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P2 |
| **Status** | READY |
| **Depends On** | EP-007 |
| **Blocks** | Nothing |
| **Tickets** | T-068 – T-069 |
| **Estimated Effort** | S (2–3 days across BE + FE) |

---

## Description

Allows players to browse their past matches and view the full breakdown of any historical match. Covers the paginated match history API endpoint and the frontend history list page. Leverages the existing `GET /match/:id/summary` endpoint (T-065) for the detail view — the only new backend work is the list endpoint.

---

## Background & Motivation

Without history, every match is forgotten the moment the player leaves the results page. A history page adds lightweight retention: players can revisit how a close multi-game match played out, share room codes they want to recreate, and have a sense of progression across sessions.

This epic is scoped to read-only views of existing data — all the data is already in Postgres from earlier epics. This is a presentation layer epic, not a data modelling one.

---

## Goals

### Backend
- Implement `GET /player/me/matches` — paginated list of matches the authenticated player participated in, including their best finish

### Frontend
- Build the Match History list page with loading skeleton, empty state, relative timestamps, and infinite-load pagination
- Link each match entry to the existing results page at `/results/:matchId`

---

## Detailed Scope

### Backend (T-068)

#### GET /player/me/matches

```
GET /player/me/matches?page=1&limit=10
Auth: required
```

Query params:
- `page` — default `1`; must be ≥ 1
- `limit` — default `10`; max `50`; validated via DTO with `class-validator` (returns 400 if out of range)

Response shape:
```typescript
interface MatchHistoryResponse {
  data: MatchHistoryItem[];
  total: number;      // total count of matches for this player
  page: number;
  limit: number;
  hasMore: boolean;   // total > page * limit
}

interface MatchHistoryItem {
  matchId: string;
  roomCode: string;
  playerCount: number;
  gamesPlayed: number;          // count of finished Game records
  playerBestFinish: number;     // lowest rank achieved in any game of this match
  playerAverageRank: number;    // mean across all games
  status: MatchStatus;
  createdAt: string;
  endedAt: string | null;
}
```

Implementation notes:
- Query: join `match_players` for the authenticated player → join `matches` → left join `games` + `game_rankings`
- Sort by `matches.created_at DESC`
- Use Prisma `skip` / `take` for pagination
- Count query runs in parallel with the data query for efficiency

---

### Frontend (T-069)

#### Match History Page

`src/pages/HistoryPage.tsx` — accessible at `/history`.

**Data loading**: calls `GET /player/me/matches` on mount. Subsequent pages appended via "Show more" button (no infinite scroll — explicit pagination).

**Page sections:**

*Page header*: "Your Match History" + player display name.

*Match list*: each item is a card showing:
- Relative timestamp ("3 hours ago", "Yesterday", "Feb 12") using a date utility (e.g. `date-fns` `formatDistanceToNow`)
- Room code (monospaced)
- Player count: "6 players"
- Games played: "8 games"
- Player's best finish in the match: "Best: 1st place" (with rank badge colour)
- Match status badge: green "Finished" or amber "In Progress" (if a match was left mid-game)

Clicking any match card navigates to `/results/:matchId` (the existing ResultsPage in historical data mode).

**Loading state**: shadcn `<Skeleton>` cards rendered for the initial load (3 skeleton cards while fetching).

**Empty state**: large centred illustration (SVG placeholder acceptable) with the message "No matches yet. Create a room to get started." and a "Create Room" button linking to `/lobby`.

**"Show more" pagination**: a button at the bottom of the list, shown only when `hasMore: true`. On click: fetches the next page and appends to the existing list. Shows a small inline spinner on the button during loading.

**Error state**: if the API call fails, show an inline error with a "Try again" retry button (no full-page error screen).

---

## Acceptance Criteria

### Backend
- [ ] `GET /player/me/matches` returns a paginated list with correct `total`, `hasMore`, and match data
- [ ] Only matches where the authenticated player appears in `match_players` are returned
- [ ] `limit` above 50 returns 400; `page` below 1 returns 400
- [ ] Integration tests: player with 0 matches → empty list; player with 15 matches → page 1 returns 10, page 2 returns 5 with `hasMore: false`
- [ ] `playerBestFinish` is the minimum rank across all games, not the last game's rank

### Frontend
- [ ] Loading skeleton renders during the initial API call
- [ ] Empty state shows correctly for a player with no match history
- [ ] Relative timestamps are humanly readable ("2 hours ago", not a raw ISO string)
- [ ] "Show more" loads the next page and appends without replacing existing items
- [ ] "Show more" button is hidden when `hasMore: false`
- [ ] Clicking a match card navigates to the correct `/results/:matchId` URL
- [ ] API error state shows a retry button that re-triggers the fetch

---

## Dependencies

- Requires: EP-007 (results page must exist for the history list to link to)
- Blocks: nothing — this is the final epic

---

## Reference
- `SYSTEM_DESIGN.md §8.2` (REST endpoints: `/match/:id/history`)
- `GAME_RULES.md` — no direct rule dependency
- [`tickets.json`](../tickets.json) → `EP-008`, tickets T-068 – T-069
