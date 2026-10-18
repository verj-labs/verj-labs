# EP-007 — Game End, Rankings & Results

| Field | Value |
|---|---|
| **ID** | EP-007 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P1 |
| **Status** | READY |
| **Depends On** | EP-005, EP-006 |
| **Blocks** | EP-008 |
| **Tickets** | T-064 – T-067 |
| **Estimated Effort** | M (4–5 days across BE + FE) |

---

## Description

Completes the match lifecycle: the match ends when a host decides to stop (or after a configurable number of games). The backend emits a `match:finished` event, persists aggregate stats, and cleans up Redis. The frontend presents a rich results page with per-player aggregate standings, per-game breakdowns, and a path back to the lobby. Also covers the card interaction animations on the game board (Framer Motion) that make the game feel polished.

---

## Background & Motivation

The results page is the last thing a player sees before returning to the lobby. It needs to:
1. Give every player a clear summary of how they performed across all games
2. Be visually satisfying (they just played a full match)
3. Be accessible in two modes: live (just finished) and historical (from match history in EP-008)

The Framer Motion animations (card deal, card play, reset burst, skip flash, finish badge) are in this epic because they depend on the socket events being wired (EP-005) and are purely additive polish — they do not affect any game logic.

---

## Goals

### Backend
- Implement match:finished event emission with aggregate stats
- Implement Redis cleanup scheduled 60 minutes after match end
- Implement `GET /match/:id/summary` REST endpoint with access control

### Frontend
- Build the Results page (live + historical modes, aggregate standings, per-game accordion)
- Add Framer Motion animations to the game board (deal, play, reset, skip, finish)

---

## Detailed Scope

### Backend (T-064 – T-065)

#### match:finished + Redis Cleanup (T-064)
Triggered when the match host ends the match (or when a configurable game limit is reached — default: no limit in v1.0, host manually ends):

1. Set `Match.status = FINISHED`, `Match.ended_at = now()` in Postgres
2. Compute aggregate stats per player across all games in the match:
   ```typescript
   interface PlayerMatchStat {
     playerId: string;
     displayName: string;
     gamesPlayed: number;
     wins: number;           // count of 1st place finishes
     averageRank: number;    // mean of all game finish ranks (lower is better)
     bestFinish: number;     // lowest rank number achieved
   }
   ```
3. Emit `match:finished` to the room:
   ```typescript
   interface MatchFinishedPayload {
     matchId: string;
     totalGames: number;
     standings: PlayerMatchStat[];  // sorted by averageRank asc
   }
   ```
4. Schedule Redis cleanup: after 60 minutes, delete `match:{matchId}:state` and `game:{gameId}:state` for all games in the match. Use a setTimeout or a Redis TTL approach — do not use a persistent job queue in v1.0.

A player who reconnects after `match:finished` receives the `match:finished` event payload (not stale game state).

#### GET /match/:id/summary (T-065)
```
GET /match/:id/summary
Auth: required
```

Access control: requesting player must have a row in `match_players` for this match (403 otherwise). Returns 404 for unknown `matchId`.

Response shape:
```typescript
interface MatchSummary {
  matchId: string;
  roomCode: string;
  status: MatchStatus;
  createdAt: string;
  endedAt: string | null;
  players: Array<{ id, displayName, seatIndex }>;
  aggregate: PlayerMatchStat[];    // sorted by averageRank
  games: Array<{
    gameId: string;
    gameNumber: number;
    direction: Direction;
    status: GameStatus;
    startedAt: string;
    endedAt: string | null;
    rankings: Array<{ playerId, displayName, rank }>;
  }>;
}
```

Works for both in-progress matches (partial data) and completed matches. Queries Postgres only — does not depend on Redis (important for historical access long after Redis TTL has expired).

---

### Frontend (T-066 – T-067)

#### Results Page (T-066)
`src/pages/ResultsPage.tsx` — accessible at `/results/:matchId`.

**Two data modes:**
1. **Live mode**: navigated to when `match:finished` socket event fires. Data already in `matchStore` / `gameStore` — no API call needed initially. Shows immediately.
2. **Historical mode**: navigated to from `/history/:matchId`. Calls `GET /match/:id/summary` on mount. Shows a loading skeleton while fetching.

**Page sections:**

*Header*: match date, room code, "X games played", overall winner highlighted with a trophy badge.

*Aggregate Standings Table*:
| Rank | Player | Wins | Avg Rank | Best Finish |
|---|---|---|---|---|
| 🥇 | Alice | 3 | 1.5 | 1 |
| 🥈 | Bob | 1 | 2.3 | 2 |
| ... | ... | ... | ... | ... |

Local player's row is visually highlighted (gold background tint).

*Per-Game Breakdown*: collapsible accordion with one entry per game. Each entry shows game number, direction, and the finish order for that game (1st → last with player names).

*Actions*:
- "Return to Lobby" → clears `matchStore` + `gameStore`, navigates to `/lobby`
- "View History" → navigates to `/history` (if EP-008 is complete)

#### Game Board Framer Motion Animations (T-067)
Install `framer-motion`. Add animations to the live game board:

| Animation | Trigger | Implementation |
|---|---|---|
| Card deal | `game:started` | Cards fly from a central position to each player's hand area (staggered, 80ms apart) |
| Card play | `game:state_updated` (play confirmed) | Played cards fly from LocalPlayerHand to PileDisplay using `layoutId` |
| Pile reset | `game:pile_reset` | Pile cards scatter outward and fade (scale + translate + opacity); pile area glows briefly |
| Player skipped | `game:player_skipped` | Red flash overlay on the skipped player's OpponentHand |
| Player finish | `game:player_finished` | Rank badge slides in from top with a spring animation; cards area fades out |

**Reduced motion**: All animations check `window.matchMedia('(prefers-reduced-motion: reduce)')`:
- If true: skip all transforms/translates and use instant opacity-only transitions
- Components use Framer Motion's `useReducedMotion()` hook

**Performance**: Use `will-change: transform` only during active animations; clean up after completion to avoid GPU layer bloat.

---

## Acceptance Criteria

### Backend
- [ ] `match:finished` event payload contains correct aggregate standings for all players, sorted by average rank
- [ ] `Match.status` is `FINISHED` and `ended_at` is set in Postgres after `match:finished`
- [ ] Redis keys for the match are cleaned up within 60 minutes of match end
- [ ] `GET /match/:id/summary` returns correct data for both in-progress and completed matches
- [ ] `GET /match/:id/summary` returns 403 for a player not in the match; 404 for unknown matchId
- [ ] Integration test covers the summary endpoint with multiple games and all players

### Frontend
- [ ] Live results page appears immediately on `match:finished` without an API call
- [ ] Historical results page correctly loads data from the API with a loading skeleton
- [ ] Aggregate standings table ranks by average rank (lower is better); local player is highlighted
- [ ] Per-game accordion correctly shows game number, direction, and finish order
- [ ] "Return to Lobby" clears stores and navigates to `/lobby`
- [ ] Card deal animation fires at the start of each game
- [ ] Card play, reset, skip, and finish animations each trigger on the correct socket events
- [ ] All animations are skipped or replaced with instant transitions when `prefers-reduced-motion` is set

---

## Dependencies

- Requires: EP-005 (game lifecycle), EP-006 (exchange must complete before match:finished can fire)
- Blocks: EP-008 (history links to results page)

---

## Reference
- `GAME_RULES.md §5` (finish order), `§6.2` (game start player for next game)
- `SYSTEM_DESIGN.md §6.1` (match lifecycle), `§8.2` (REST API), `§10` (WebSocket events)
- [`tickets.json`](../tickets.json) → `EP-007`, tickets T-064 – T-067
