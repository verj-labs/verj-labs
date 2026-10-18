> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). BE-EP-005 and BE-EP-006 were merged into one feature epic.
> **Replaced by:** [EP-005 — Real-Time Game Play](../epics/EP-005-realtime-game-play.md) · [tickets.json](../tickets.json) → T-041–T-048

---

# BE-EP-006 — Game Lifecycle Orchestration

| Field | Value |
|---|---|
| **ID** | BE-EP-006 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | BE-EP-003, BE-EP-004, BE-EP-005 |
| **Blocks** | BE-EP-007 |
| **Estimated Effort** | L (6–8 days) |

---

## Description

This epic ties together the Game Engine (BE-EP-004) and the WebSocket Gateway (BE-EP-005) into a fully functional, end-to-end playable game. The `GameService` acts as the orchestrator: it receives intent events from the gateway, calls the pure engine to compute the next state, persists the result, and instructs the gateway to broadcast the outcome.

This epic covers the full lifecycle from "match started" through multiple games, including inter-game direction determination and state management.

---

## Background & Motivation

The game engine is stateless and pure. The gateway is I/O-only. This epic is the "glue layer" that:
- Manages the authoritative live state in Redis
- Calls the engine with each player intent
- Translates engine results into appropriate socket events
- Orchestrates game-to-game transitions (detect game over, trigger next game setup)
- Manages start conditions (first game: random start, subsequent: winner starts)

---

## Goals

- `GameService` orchestrating full end-to-end game play
- First game start: random starting player, cards dealt
- Subsequent games: winner starts, direction determined from 2nd place seat
- Full round lifecycle managed (start round, play/pass, round end, next round)
- Game-over detection and transition to card exchange phase
- Next game initialization after card exchange completes
- All game state changes persisted in Redis (and partially to Postgres via event log)
- All state changes broadcast to the correct socket room

---

## Detailed Scope

### 1. GameService Responsibilities

```typescript
class GameService {
  startMatch(matchId: string): Promise<void>
  handlePlayerIntent(matchId: string, playerId: string, intent: PlayIntent): Promise<void>
  handleGameFinished(matchId: string, gameState: GameState): Promise<void>
  startNextGame(matchId: string, previousGameState: GameState): Promise<void>
}
```

### 2. Match Start Flow

Triggered by `MatchService` when host calls `POST /match/:id/start`:

1. Load `MatchState` from Redis
2. Assign random `startPlayerIndex` (random seat among all players)
3. Call `DeckService.dealHands(playerCount)` → get hands
4. Build initial `GameState`:
   - `gameNumber: 1`
   - `direction: 'clockwise'` (default for game 1)
   - `startPlayerIndex` = random
   - `activePlayerIndex` = `startPlayerIndex`
   - Each player gets their dealt hand
   - `pile.topPlay = null`
   - `consecutivePassCount = 0`
   - `status = 'in_progress'`
5. Store `GameState` in Redis: `game:{gameId}:state`
6. Persist `Game` record to Postgres
7. Broadcast `game:started` event to match room with full `GameState`
   - **Important:** each player's socket event should contain **only their own hand**, not other players' hands. Other players' hands are represented as card counts only.
   - Server sends the full state including all hands — but the frontend should only display the local player's cards face-up. The server can send a player-specific projection of game state.

### 3. Player Intent Processing

Called by gateway on `game:play` or `game:pass` event:

1. Load current `GameState` from Redis
2. Call `GameEngineService.processIntent(state, intent)`
3. If `result.error` → emit `game:play_rejected` to the requesting socket only with error reason
4. If success:
   a. Save new state to Redis
   b. Log game events to Postgres (BE-EP-008)
   c. Translate `result.events` into appropriate socket events:
      - `PILE_RESET` → emit `game:pile_reset`
      - `PLAYER_SKIPPED` → emit `game:player_skipped`
      - `PLAYER_FINISHED` → emit `game:player_finished`
      - `ROUND_ENDED` → emit `game:round_ended`
      - `GAME_FINISHED` → call `handleGameFinished()`
   d. Always emit `game:state_updated` with the new game state (player-projected) to the match room

### 4. Game State Projection (Privacy)

When broadcasting `GameState` to the room:
- Create a `GameStateProjection` per player that includes:
  - Their own full hand
  - Other players' card counts only (not actual cards)
- Broadcast via individual emits per socket, NOT a single broadcast
- Or: broadcast common state (no hands) + send each player their hand separately

This prevents a player from seeing others' cards by inspecting the WebSocket payload.

### 5. Game Finished Flow

When `GAME_FINISHED` event is received from the engine:

1. Save final `GameState` to Redis (status: 'finished')
2. Update `Game` record in Postgres with `ended_at`
3. Save `GameRanking` records to Postgres
4. Emit `game:finished` to match room with final rankings
5. Wait briefly (3–5 seconds configurable pause for UI to display results)
6. Trigger card exchange: delegate to `ExchangeService` (BE-EP-007)
7. After exchange, start next game (or end match if host chose to end)

### 6. Next Game Initialization

After exchange cards have been applied:

1. Determine new start player: winner (1st place) of previous game
2. Determine direction: call `GameEngineService.determineDirection(winnerSeat, 2ndPlaceSeat, n)`
3. Deal new hands (fresh deck, shuffled)
4. Apply exchange results to hands before dealing (or apply post-deal)
5. Create new `GameState` with `gameNumber++`
6. Store in Redis, persist to Postgres
7. Broadcast `game:started` to room

### 7. Active Player Count Management

Players can "leave" a match mid-game (disconnect with no reconnect). Define policy:
- If a player disconnects, they get a 5-minute reconnect window
- During this window, the game continues — the disconnected player auto-passes their turns
- After 5 minutes with no reconnect, the player is removed from the game
- If player count drops below 2 active players, the game ends (edge case — unlikely but must handle)

### 8. Match Completion

A match ends when:
- The host explicitly ends the match after a game finishes (no auto-end)
- OR all players except one have left

On match completion:
- Update `Match.status = 'finished'` in Redis and Postgres
- Emit `match:finished` with overall match summary
- Clean up Redis keys after a delay (60 minutes)

---

## Acceptance Criteria

- [ ] `startMatch()` deals cards, assigns start player, broadcasts `game:started` with player-specific hands
- [ ] Other players' hands are never exposed in socket payloads
- [ ] `handlePlayerIntent()` loads state from Redis, processes via engine, saves result, broadcasts
- [ ] Invalid plays broadcast `game:play_rejected` only to requesting socket
- [ ] Valid plays broadcast `game:state_updated` to all room members
- [ ] All engine events (`PILE_RESET`, `PLAYER_SKIPPED`, etc.) result in correct socket events
- [ ] Game finishes correctly when all players have emptied hands
- [ ] Final rankings are persisted to Postgres
- [ ] Card exchange is triggered automatically after game ends
- [ ] Next game starts with winner as start player and correct direction
- [ ] Disconnected player auto-passes; reconnect restores their state
- [ ] Integration tests simulate a full game from start to finish
- [ ] Integration tests cover multi-game match (at least 2 games)

---

## Out of Scope

- Card exchange logic itself (BE-EP-007)
- Event log persistence details (BE-EP-008)
- Frontend concerns

---

## Technical Notes

- Redis game state should be versioned: include a `version: number` field that increments with each state change. Use this as an optimistic concurrency check if concurrent event handling becomes a concern (use Redis transactions/WATCH).
- Consider using a Redis-backed queue (BullMQ) for sequential processing of game intents if concurrent plays become a race condition risk on a single game.
- Keep `GameService` thin — game logic stays in the engine, I/O stays in the gateway.
