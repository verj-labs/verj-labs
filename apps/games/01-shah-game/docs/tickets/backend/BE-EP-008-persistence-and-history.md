> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary backend detail.
> **Replaced by:** [EP-007 — Game End, Rankings & Results](../epics/EP-007-game-end-rankings-results.md) (T-064–T-065) and [EP-008 — Match History](../epics/EP-008-match-history.md) (T-068) · [tickets.json](../tickets.json)

---

# BE-EP-008 — Persistence & Game History

| Field | Value |
|---|---|
| **ID** | BE-EP-008 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P1 |
| **Status** | READY |
| **Depends On** | BE-EP-001, BE-EP-004, BE-EP-006 |
| **Blocks** | FE-EP-008 |
| **Estimated Effort** | M (3–5 days) |

---

## Description

This epic ensures that all gameplay data is durably persisted to PostgreSQL for history, auditing, and replay purposes. While active game state lives in Redis for performance, the complete event log, rankings, and match summaries must be written to Postgres. This epic also exposes REST endpoints for querying match history, which powers the match summary UI (FE-EP-008).

---

## Background & Motivation

Without persistence:
- Players cannot review their game history after a match
- There is no audit trail for debugging disputes or rule edge cases
- A server restart wipes all knowledge of completed games

The event log (append-only per game) is the core of this epic. Every action — each play, pass, reset, round end, exchange, and game end — is recorded as a structured event. This forms a complete replay-able record of what happened in every game.

---

## Goals

- Write an append-only event log to `game_events` table for all game actions
- Persist final game rankings to `game_rankings` table
- Persist match and game metadata to `matches` and `games` tables
- Create REST endpoints for querying match history
- Support replay capability (full reconstruction of any game from events)
- Ensure persistence is non-blocking (does not slow down the real-time game loop)

---

## Detailed Scope

### 1. Event Log Persistence

After each `processIntent()` call in `GameService`, persist the resulting events to `game_events`:

```sql
game_events:
  id: BIGSERIAL PK
  game_id: UUID FK
  round_number: INT
  event_type: VARCHAR(32)  -- 'play', 'pass', 'reset', 'skip', 'round_end', 'player_finish', 'game_end', 'exchange'
  player_id: UUID FK (nullable for system events)
  payload: JSONB
  created_at: TIMESTAMPTZ DEFAULT now()
```

**Event payloads by type:**

| `event_type` | Payload fields |
|---|---|
| `play` | `{ cards: Card[], pileRank, pileSize, wasReset: bool, triggeredSkip: bool }` |
| `pass` | `{ consecutivePassCount }` |
| `reset` | `{ resetCards: Card[], previousPileRank, previousPileSize }` |
| `skip` | `{ skippedPlayerId }` |
| `round_end` | `{ roundNumber, roundWinnerId, totalRounds }` |
| `player_finish` | `{ playerId, finishRank, handWasEmpty: true }` |
| `game_end` | `{ finalRankings: Array<{playerId, rank}> }` |
| `exchange` | `{ actions: ExchangeAction[] }` |

**Async persistence:**
- Write to `game_events` asynchronously (fire-and-forget after state update)
- Use a per-game write queue to maintain event ordering
- Failures log an error but do NOT fail the player's action (game continues)

### 2. Rankings Persistence

On game finish:
```sql
game_rankings:
  game_id: UUID FK
  player_id: UUID FK
  rank: INT (1 = winner)
  PK: (game_id, player_id)
```

### 3. Match & Game Metadata

**Match** (written on creation, updated on status change):
```sql
matches:
  id, room_code, host_id, status, player_count, created_at, ended_at
```

**Match Players** (written on join):
```sql
match_players:
  match_id, player_id, seat_index, joined_at
```

**Game** (written on start, updated on finish):
```sql
games:
  id, match_id, game_number, direction, status, started_at, ended_at
```

### 4. REST API for History

**`GET /match/:id/summary`**
Response:
```json
{
  "matchId": "...",
  "roomCode": "XJKQ",
  "status": "finished",
  "players": [{ "id": "...", "displayName": "Alice", "seatIndex": 0 }],
  "games": [
    {
      "gameNumber": 1,
      "direction": "clockwise",
      "rankings": [{ "playerId": "...", "displayName": "Alice", "rank": 1 }],
      "startedAt": "...",
      "endedAt": "..."
    }
  ],
  "totalGamesPlayed": 3
}
```

**`GET /match/:id/game/:gameNumber/events`**
- Returns the full ordered event log for a specific game
- Useful for debugging and future replay feature
- Response: `{ events: GameEvent[] }`
- Protected: only players who were in the match can view (auth check)

**`GET /player/me/matches`**
- Returns paginated list of matches the authenticated player participated in
- Response: `{ matches: MatchSummary[], total: int, page: int }`

### 5. TypeORM/Prisma Repositories

Create typed repositories for:
- `MatchRepository`
- `GameRepository`
- `GameEventRepository`
- `GameRankingRepository`
- `PlayerRepository`

All database writes should go through repositories, never via raw queries in services.

### 6. Database Migration
Ensure all tables from `SYSTEM_DESIGN.md §7` have corresponding migration files. This epic should produce the final, complete migration set (building on the initial schema from BE-EP-001).

### 7. Query Optimization
- Add indexes on: `game_events.game_id`, `game_events.created_at`, `matches.room_code`, `match_players.player_id`, `game_rankings.game_id`
- Use `EXPLAIN ANALYZE` to validate common query patterns
- Limit event log queries with pagination (`LIMIT`/`OFFSET` or cursor-based)

---

## Acceptance Criteria

- [ ] Every `play`, `pass`, `reset` action writes an event to `game_events` in correct order
- [ ] Game rankings are persisted on game finish
- [ ] Match and game records have correct `started_at`/`ended_at` timestamps
- [ ] `GET /match/:id/summary` returns correct structured summary with all games
- [ ] `GET /match/:id/game/:gameNumber/events` returns full ordered event log
- [ ] `GET /player/me/matches` returns paginated list of player's matches
- [ ] Persistence failures do not crash or block the live game
- [ ] All tables have correct indexes
- [ ] A game can be fully reconstructed by replaying its event log through the engine (test this)
- [ ] Unit tests cover: all event type serializations, repository layer, history endpoints

---

## Out of Scope

- Full game replay UI (future feature)
- Analytics dashboards
- Data exports

---

## Technical Notes

- Use `@nestjs/schedule` or a simple `setImmediate` pattern for async event writes
- Consider wrapping all persistence in a `PersistenceService` that `GameService` calls — keeps game logic separate from database concerns
- The event log is append-only: never update or delete `game_events` rows
- Keep payload schema versioned: include a `schemaVersion: 1` field in all payloads to enable future migrations
