> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-008 — Match History](../epics/EP-008-match-history.md) · [tickets.json](../tickets.json) → T-069

---

# FE-EP-008 — Match History & Summary

| Field | Value |
|---|---|
| **ID** | FE-EP-008 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P2 |
| **Status** | READY |
| **Depends On** | FE-EP-002, FE-EP-007, BE-EP-008 |
| **Blocks** | None |
| **Estimated Effort** | S–M (2–4 days) |

---

## Description

This epic delivers the match history feature: a view where players can review their past matches, see game-by-game breakdowns, and track their performance over time. It is the lowest priority epic but adds meaningful value for players who want to review their performance or relive memorable games.

---

## Background & Motivation

After a session ends, players often want to know: "How did we all finish overall?" or "Which game was closest?". This feature satisfies that curiosity and adds replay value. It also provides a user-facing proof that the persistence system (BE-EP-008) is working correctly.

---

## Goals

- "My Matches" page listing recent matches for the authenticated player
- Individual match summary page (already covered partially in FE-EP-007 at `/results/:matchId`)
- Paginated match list
- Per-match detail: all games, rankings, directions
- Basic filtering (most recent, completed only)
- Clean empty state for new players

---

## Detailed Scope

### 1. "My Matches" Page

Add a route accessible from the lobby header: `/history`

**Page content:**
- Heading: "Your Match History"
- List of matches, sorted by most recent
- Each match card shows:
  - Date played (relative: "2 hours ago", "Yesterday")
  - Room code
  - Number of games played
  - Number of players
  - Your best finish in the match (e.g., "Best: 1st place")
  - Match outcome (Winner badge if you won the most games)
- Pagination: "Show more" button (load next 10)
- Empty state: "You haven't played any matches yet. [Create a Room]"

**API:** `GET /player/me/matches?page=1&limit=10`

### 2. Match Detail Page (`/results/:matchId`)

Already partially scoped in FE-EP-007 (shown live after match ends). This epic extends it to also work for historical matches fetched from the API.

**Extended content for historical view:**
- Game-by-game accordion: click to expand each game's results
- Per-game details:
  - Final rankings
  - Direction (clockwise/counterclockwise)
  - Number of rounds played
  - Duration

**API:** `GET /match/:id/summary`

### 3. Match History Store

```typescript
interface HistoryStore {
  matches: MatchSummary[];
  currentPage: number;
  total: number;
  isLoading: boolean;
  // Actions
  fetchMatches: (page: number) => Promise<void>;
  fetchMatchDetail: (matchId: string) => Promise<MatchDetail>;
}
```

### 4. Navigation

Add "History" link to the lobby header (small text link, not prominent).  
From the match results page, add "View Full History" link to `/history`.

---

## Acceptance Criteria

- [ ] `/history` displays a paginated list of the player's past matches
- [ ] Each match card shows correct date, game count, and best finish
- [ ] "Show more" loads the next page of results
- [ ] Clicking a match card navigates to `/results/:matchId`
- [ ] Historical match detail shows per-game rankings
- [ ] Empty state is shown for new players with no history
- [ ] Loading skeleton is shown while data is fetching
- [ ] Handles API errors gracefully (retry button, error toast)

---

## Out of Scope

- Event-level game replay (watching a game move by move)
- Filtering by date range or player
- Exporting history to CSV
- Global leaderboards

---

## Technical Notes

- The `/results/:matchId` page must handle two modes: live (just finished — data from Zustand) and historical (loaded from API). Use a URL query param `?source=live` or detect whether `gameStore` has active match data.
- Use `React.Suspense` with a fallback skeleton for the history list
- Dates should use `Intl.RelativeTimeFormat` for relative times and `Intl.DateTimeFormat` for absolute dates on hover (tooltip)
