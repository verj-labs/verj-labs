# EP-005 — Real-Time Game Play

| Field | Value |
|---|---|
| **ID** | EP-005 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | EP-001, EP-002, EP-003, EP-004 |
| **Blocks** | EP-006, EP-007 |
| **Tickets** | T-041 – T-058 |
| **Estimated Effort** | XL (12–15 days across BE + FE) |

---

## Description

The main event. This epic wires together the game engine (EP-004) with the WebSocket gateway, game lifecycle orchestration, and the full game board frontend. After this epic closes, a complete game can be played end-to-end in a browser: deal cards, take turns, play sets, pass, reset the pile, finish, and transition to the next game.

---

## Background & Motivation

This is the largest epic because it integrates every domain: auth (who is playing), match management (which room), the game engine (are plays valid), persistence (record what happened), and the game board UI (what does the player see). The WebSocket gateway is the central coordinator — all real-time state updates flow through it.

Key architectural constraint: **the client only sends intent** (`game:play`, `game:pass`). The server validates, applies the engine, and broadcasts the authoritative new state to all players. Clients never modify game state locally — they only react to `game:state_updated` events.

---

## Goals

### Backend
- Create `Game`, `GameRanking`, `GameEvent` Prisma models and migration
- Build the WebSocket gateway with token auth and room joining
- Define all `GameEvents` constants and typed event payload interfaces
- Implement `GameService.startMatch()`: deal cards, build initial state, broadcast `game:started`
- Implement `game:play` and `game:pass` socket event handlers
- Implement game-finished flow: persist rankings, determine next game setup, emit `game:finished`
- Implement player reconnect + auto-pass on disconnect
- Asynchronously append all engine events to the `game_events` table (fire-and-forget)

### Frontend
- Build the game board layout (5 structural sections)
- Build `OpponentHand` and `OpponentSection` components
- Build `PileDisplay` and `PassIndicator` components
- Build `LocalPlayerHand` with card selection
- Build `ActionBar` with Play and Pass buttons
- Implement `gameStore` (Zustand) with derived state
- Implement the Socket.IO client singleton and `useSocketSetup` hook
- Wire all server→client game events to store and UI
- Wire ActionBar outgoing events to socket
- Handle socket reconnection with connection-lost banner

---

## Detailed Scope

### Backend (T-041 – T-048)

#### Game Models + Migration (T-041)
```prisma
enum Direction { CLOCKWISE COUNTERCLOCKWISE }
enum GameStatus { WAITING IN_PROGRESS FINISHED }

model Game {
  id         String     @id @default(uuid())
  match_id   String
  game_number Int
  direction  Direction
  status     GameStatus @default(IN_PROGRESS)
  started_at DateTime   @default(now())
  ended_at   DateTime?
  match      Match      @relation(fields: [match_id], references: [id])
  rankings   GameRanking[]
  events     GameEvent[]
}

model GameRanking {
  game_id   String
  player_id String
  rank      Int
  @@id([game_id, player_id])
}

model GameEvent {
  id           BigInt    @id @default(autoincrement())
  game_id      String
  round_number Int
  event_type   String
  player_id    String?
  payload      Json
  created_at   DateTime  @default(now())
  @@index([game_id])
}
```

#### WebSocket Gateway (T-042)
`src/gateway/game.gateway.ts`

`handleConnection(socket)`:
1. Extract `token` from `socket.handshake.auth.token`
2. Validate via `AuthService.validateToken()` — if invalid, `socket.disconnect()` and return
3. Populate `socket.data = { playerId, displayName }`
4. If player has an active match in Redis: join socket to `match:{matchId}` room

`handleDisconnect(socket)`:
1. Emit `player:disconnected` to the match room
2. Set `game_reconnect:{playerId}` in Redis with 5-minute TTL to track reconnect window

#### GameEvents Enum and Types (T-043)
`src/gateway/events.enum.ts` — constants for every event name (no raw string literals anywhere):

```typescript
export const GameEvents = {
  // Server → Client
  GAME_STARTED: 'game:started',
  STATE_UPDATED: 'game:state_updated',
  PLAY_REJECTED: 'game:play_rejected',
  ROUND_ENDED: 'game:round_ended',
  PLAYER_SKIPPED: 'game:player_skipped',
  PILE_RESET: 'game:pile_reset',
  PLAYER_FINISHED: 'game:player_finished',
  GAME_FINISHED: 'game:finished',
  MATCH_UPDATED: 'match:updated',
  HOST_CHANGED: 'match:host_changed',
  PLAYER_DISCONNECTED: 'player:disconnected',
  PLAYER_RECONNECTED: 'player:reconnected',
  // Client → Server
  PLAY: 'game:play',
  PASS: 'game:pass',
} as const;
```

Typed payload interface for every event in `src/shared/types/events.types.ts`.

#### GameService.startMatch() (T-044)
Called when host presses "Start Game" (from `POST /match/:id/start`):

1. Load `MatchState` from Redis
2. Assign a random `startPlayerIndex`
3. Call `DeckService.shuffleDeck()` + `DeckService.dealHands(playerCount)`
4. Build initial `GameState` and store in Redis: `game:{gameId}:state`
5. Create `Game` record in Postgres
6. For each player: emit `game:started` with a **player-projected** payload — only their own hand cards; other players get card counts only

```typescript
// Player-projected payload
interface GameStartedPayload {
  gameId: string;
  gameNumber: number;
  direction: Direction;
  yourHand: Card[];                          // only your cards
  players: Array<{
    id: string;
    displayName: string;
    seatIndex: number;
    cardCount: number;                       // opponent card counts
  }>;
  activePlayerIndex: number;
  pile: Pile;
}
```

#### game:play + game:pass Handlers (T-045)
```typescript
@SubscribeMessage(GameEvents.PLAY)
async handlePlay(socket: Socket, payload: PlayIntentDto) { ... }

@SubscribeMessage(GameEvents.PASS)
async handlePass(socket: Socket) { ... }
```

On play:
1. Load `GameState` from Redis (keyed by `game:active:{matchId}`)
2. Build `PlayIntent` from DTO + `socket.data.playerId`
3. Call `GameEngineService.processIntent(state, intent)`
4. On error: emit `game:play_rejected` to requesting socket only
5. On success: store new state in Redis, emit `game:state_updated` (player-projected) to match room
6. Emit specific sub-events for each engine event in `result.events`

On pass:
- Same flow; always succeeds (no validation failure)

#### game-finished Flow + Next Game (T-046)
When `GAME_FINISHED` event is in `processIntent()` results:

1. Persist `GameRanking` records for all players
2. Update `Game.status = FINISHED`, set `ended_at`
3. Emit `game:finished` to match room with player rankings
4. After 3-second delay: call `ExchangeService.computeExchange()` (stub in EP-005; real algorithm in EP-006)
5. Build next `GameState`: winner is start player; call `determineDirection()`; deal new hands
6. Create new `Game` record in Postgres
7. Emit `game:started` for the new game (per-player projected payloads)

#### Reconnect + Auto-Pass (T-047)
During a player's active turn while they are disconnected:
- Auto-emit a `pass` intent on their behalf via `GameEngineService.processIntent()`
- Repeat each time their turn comes until they reconnect or the 5-minute TTL expires

On reconnect (detected by `game_reconnect:{playerId}` key existing in Redis):
- Load full current `GameState`, emit to their socket
- Emit `player:reconnected` to the match room
- Delete the reconnect Redis key

#### Event Log Persistence (T-048)
After every successful `processIntent()` call:
- Fire-and-forget `PrismaService.gameEvent.create(...)` — **do not await**
- Log persistence errors with `Logger.error()` but do not let them affect the game response
- Include `round_number`, `event_type`, `player_id`, and a typed `payload` for each engine event

---

### Frontend (T-049 – T-058)

#### Game Board Layout (T-049)
`src/pages/GamePage.tsx` — 5-section full-viewport layout, no scroll:

```
┌────────────────────────────────────────┐
│           GameStatusBar                │  ← game number, direction indicator
├────────────────────────────────────────┤
│        OpponentSection                 │  ← other players' hands (face-down)
├──────────────────┬─────────────────────┤
│   PileDisplay    │   PassIndicator     │  ← table area
├────────────────────────────────────────┤
│         LocalPlayerHand                │  ← your cards (face-up, selectable)
├────────────────────────────────────────┤
│            ActionBar                   │  ← Play / Pass buttons + status
└────────────────────────────────────────┘
```

#### OpponentHand + OpponentSection (T-050)
`OpponentHand` props: `player`, `isActive`, `isPassed`, `isDisconnected`
- Face-down card backs count matches `player.cardCount`
- Active player → glowing outline
- Finished → rank badge, no cards
- Passed → "(passed)" label
- Disconnected → semi-transparent overlay with disconnected icon

`OpponentSection`: arranges `OpponentHand` components around the top arc/sides of the table based on player count (4, 5, 6, 7, 8 all tested).

#### PileDisplay + PassIndicator (T-051)
`PileDisplay`:
- Empty pile → "Table clear — play anything"
- Active pile → top play cards face-up, set type label ("Single J", "Double K", etc.)
- Reset animation hook (cleared by `game:pile_reset` event)

`PassIndicator`: row of `n-1` dots (n = active player count), filled dots represent consecutive passes.

#### LocalPlayerHand (T-052)
`LocalPlayerHand`:
- Renders `<PlayingCard>` components in a fanned row
- Cards are clickable only when `isLocalPlayerTurn === true` (from gameStore)
- Clicking toggles inclusion in `selectedCards`
- Playable cards (match pile set size or pile is empty) get a subtle green border hint
- Non-playable cards (wrong set size or rank too low given current selection) are dimmed
- Cards are visually non-interactive when it is not the player's turn

#### ActionBar (T-053)
`ActionBar`:
- "Play Selected" button: enabled when `selectedCards.length > 0` AND all selected cards share the same rank
- "Pass" button: enabled when `isLocalPlayerTurn`
- Both show spinners when `isActionPending`
- `lastActionError` message shown below buttons (auto-clears on next `game:state_updated`)
- "Waiting for [name]..." when it is not the local player's turn

#### gameStore (T-054)
`src/store/gameStore.ts`:

```typescript
interface GameStore {
  gameState: GameState | null;
  localPlayerId: string | null;
  selectedCards: Card[];
  isActionPending: boolean;
  lastActionError: string | null;

  // Derived selectors
  localPlayer: Player | null;
  isLocalPlayerTurn: boolean;
  activePile: Pile | null;

  // Actions
  setGameState: (state: GameState) => void;  // also clears selectedCards
  toggleCard: (card: Card) => void;          // clears selection on rank mismatch
  clearSelection: () => void;
  setActionPending: (v: boolean) => void;
  setActionError: (msg: string | null) => void;
}
```

#### Socket Singleton + useSocketSetup (T-055)
`src/services/socket.ts`:
- Lazy-initialised Socket.IO singleton
- Auth token pulled from `sessionStore` at connection time (not from a stale closure)
- `connectSocket()`, `disconnectSocket()`, `getSocket()`

`src/hooks/useSocketSetup.ts`:
- Calls `connectSocket()` on mount; `disconnectSocket()` on unmount
- Registers all server→client event listeners
- Cleans up with `socket.off()` in the teardown

#### Wire Server→Client Events (T-056)

| Event | Action |
|---|---|
| `game:started` | `setGameState()`, navigate to `/game/:matchId` |
| `game:state_updated` | `setGameState()`, `setActionPending(false)` |
| `game:play_rejected` | `setActionError(reason)`, `setActionPending(false)` |
| `game:round_ended` | Toast: "Round over — [name] starts again" |
| `game:player_skipped` | Flash animation on skipped player's hand |
| `game:pile_reset` | Toast: "[name] reset the pile!" + trigger scatter animation |
| `game:player_finished` | Toast: "[name] finished — Xth place" |
| `game:finished` | Show `GameFinishedOverlay` |
| `player:disconnected` | Mark opponent as disconnected in `gameStore` |
| `player:reconnected` | Remove disconnected marker |

#### ActionBar Outgoing Events (T-057)
`src/services/gameActions.ts`:
```typescript
sendPlay(cards: Card[]) → emits 'game:play'
sendPass()              → emits 'game:pass'
```

On action: `setActionPending(true)`, `clearSelection()`. If no `game:state_updated` or `game:play_rejected` arrives within 10 seconds: `setActionPending(false)` with a timeout error message.

#### Reconnection + Connection-Lost Banner (T-058)
Handle `socket.on('disconnect')` and `socket.on('connect_error')`:
- Show a fixed top banner: "Connection lost — reconnecting..."
- Socket.IO's built-in reconnect fires in the background
- On `socket.on('connect')` after disconnect: banner hides; full state is restored via the next `game:state_updated` sent by the server's reconnect handler

Page refresh mid-game: `restoreSession()` + `connectSocket()` → server sends full state.

---

## Acceptance Criteria

### Backend
- [ ] Connecting to the gateway without a token disconnects the socket immediately
- [ ] `game:started` payload contains only the local player's hand cards; opponents show card counts
- [ ] `game:play` with invalid cards returns `game:play_rejected` to that socket only, not to the room
- [ ] `game:play` with a valid play updates Redis state and emits `game:state_updated` to all players in the room
- [ ] GAME_FINISHED triggers ranking persistence, `game:finished` broadcast, and next-game initialization
- [ ] Disconnected player's turns are auto-passed for up to 5 minutes
- [ ] Reconnecting within 5 minutes receives the current game state and emits `player:reconnected`
- [ ] `game_events` records are written asynchronously; their failure does not crash the game handler

### Frontend
- [ ] Full game board renders without horizontal/vertical overflow for 4 players and for 8 players
- [ ] Clicking a card when it is not your turn has no effect (card is visually non-interactive)
- [ ] Cards of different ranks in the selection are blocked (selecting a 2nd rank clears to new selection)
- [ ] "Play Selected" is only enabled with ≥ 1 card where all shares the same rank
- [ ] `game:state_updated` clears `isActionPending` and reflects new board state for all players
- [ ] `game:play_rejected` shows an error message to the sending player and clears the pending state
- [ ] Connection-lost banner appears on disconnect; disappears and board restores on reconnect
- [ ] Page refresh mid-game lands back on the game board with the correct state

---

## Dependencies

- Requires: EP-001, EP-002, EP-003, EP-004
- Blocks: EP-006 (exchange requires game:finished flow), EP-007 (results requires match:finished flow)

---

## Reference
- `GAME_RULES.md §5–§13` (all play rules, win condition)
- `SYSTEM_DESIGN.md §8.2` (REST), `§8.3` (GameEngineService), `§9` (frontend), `§10` (WebSocket event contract)
- [`tickets.json`](../tickets.json) → `EP-005`, tickets T-041 – T-058
