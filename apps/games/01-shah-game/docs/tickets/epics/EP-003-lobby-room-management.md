# EP-003 — Lobby & Room Management

| Field | Value |
|---|---|
| **ID** | EP-003 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | EP-001, EP-002 |
| **Blocks** | EP-005 |
| **Tickets** | T-021 – T-027 |
| **Estimated Effort** | M (4–5 days across BE + FE) |

---

## Description

Full-stack feature for creating match rooms, joining by a 4-character code, the waiting room experience (live player list, host controls), and starting a match. Includes real-time player list updates via WebSocket so all players in a room see arrivals and departures immediately.

---

## Background & Motivation

Before any game can be played, 4–8 players need to be assembled in a room. The lobby system is the social entry point of the game — it needs to be frictionless (one field of input to join) and responsive (joining appears immediately on all screens). The host has special permissions (migrate on leave, start the game), and the waiting room must clearly communicate those roles.

---

## Goals

### Backend
- Model the `Match` and `MatchPlayer` tables + run migration
- Implement `MatchService.createMatch()` with unique 4-char room code generation
- Implement `POST /match` and `POST /match/join` REST endpoints
- Implement `DELETE /match/:id/leave` with host migration logic
- Stub `POST /match/:id/start` (full wiring in EP-005)
- Emit `match:updated` WebSocket events on join/leave/host-change

### Frontend
- Build the Lobby page (create or join by code)
- Build the Waiting Room page (player seat grid, host badge, start/leave controls)
- Implement `matchStore` (Zustand) for lobby state
- Wire `match:updated`, `match:host_changed`, `game:started` socket events in the waiting room

---

## Detailed Scope

### Backend (T-021 – T-024)

#### Match & MatchPlayer Schema (T-021)
```prisma
enum MatchStatus { LOBBY IN_PROGRESS FINISHED }

model Match {
  id           String      @id @default(uuid())
  room_code    String      @unique @db.Char(4)
  host_id      String
  status       MatchStatus @default(LOBBY)
  player_count Int
  created_at   DateTime    @default(now())
  ended_at     DateTime?
  host         Player      @relation(fields: [host_id], references: [id])
  players      MatchPlayer[]
}

model MatchPlayer {
  match_id   String
  player_id  String
  seat_index Int
  joined_at  DateTime @default(now())
  @@id([match_id, player_id])
}
```

#### Room Code Generation + createMatch() (T-022)
`generateRoomCode()`: random 4-char uppercase string from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (excludes `0`, `1`, `O`, `I` to prevent misreading). Retries up to 5 times on uniqueness collision.

`createMatch(hostPlayerId)`:
1. Generate unique room code
2. Insert `Match` record (status: `LOBBY`)
3. Insert `MatchPlayer` for host at `seat_index: 0`
4. Store initial `MatchState` in Redis: `match:{matchId}:state`
5. Return full `MatchState`

#### POST /match + POST /match/join (T-023)
```
POST /match
Auth: required
Response 201: { matchId, roomCode, match: MatchState }

POST /match/join
Auth: required
Body: { roomCode: string }
Response 200: { matchId, match: MatchState }
```

Join validation:
- Room exists → 404 if not
- `status === LOBBY` → 409 if `IN_PROGRESS`
- Player count < 8 → 409 if full
- Player not already in an active match → 409 if yes

On success: assign next available `seat_index`, update Redis state, emit `match:updated` to room.

#### DELETE /match/:id/leave + Host Migration (T-024)
`MatchService.leaveMatch(matchId, playerId)`:
- Remove `MatchPlayer` record
- If player was host and others remain: assign host to the connected player with the lowest `seat_index`; emit `match:host_changed` to room
- If no players remain: delete `Match` record and Redis keys
- Emit `match:updated` to room

`POST /match/:id/start`:
- Guard: requesting player must be the host (403 otherwise)
- Guard: `players.length >= 4` (400 otherwise)
- Transitions `Match.status` to `IN_PROGRESS` in Postgres + Redis
- Full game-start logic is wired in EP-005 (T-044)

---

### Frontend (T-025 – T-027)

#### Lobby Page (T-025)
`src/pages/LobbyPage.tsx` — the authenticated player's home before joining a room.

Two-panel layout:
- **Create Room**: single button → calls `POST /match` → navigates to `/room/:code`
- **Join Room**: 4-char code input (auto-uppercase, max 4 chars) + button → calls `POST /match/join` → navigates to `/room/:code`

Error handling:
- `404` from API → inline error: "Room not found"
- `409` (full) → "Room is full"
- `409` (in-progress) → "Game already in progress"

Both buttons disable + show spinner during API calls. Player's display name is shown in the page header/navbar.

#### Waiting Room Page (T-026)
`src/pages/WaitingRoomPage.tsx` — shown while players assemble before the game.

UI elements:
- Room code display with a one-click **Copy** button
- **Player seat grid**: 4–8 slots rendered; filled slots show display name + avatar initial; empty slots show "Waiting..." placeholder
- **Host badge** (crown icon) on the host's slot
- Player count string: "4/8 players"
- **"Start Game" button** — visible and enabled only for the host when `players.length >= 4`
- **"Waiting for host to start..."** for non-host players
- **"Leave Room"** button → calls `DELETE /match/:id/leave` → navigates to `/lobby`

#### matchStore + Lobby WebSocket Events (T-027)
`src/store/matchStore.ts`:

```typescript
interface MatchState {
  matchId: string | null;
  roomCode: string | null;
  hostPlayerId: string | null;
  players: Array<{ id: string; displayName: string; seatIndex: number }>;
  status: 'LOBBY' | 'IN_PROGRESS' | 'FINISHED';
}
```

Socket event handlers (wired when `WaitingRoomPage` mounts):
- `match:updated` → replace full player list in store
- `match:host_changed` → update `hostPlayerId`
- `game:started` → navigate all players to `/game/:matchId`

Socket connects on `WaitingRoomPage` mount; disconnects on unmount. Uses the socket singleton from T-055.

---

## Acceptance Criteria

### Backend
- [ ] `POST /match` returns 201 with a unique 4-char room code and match state
- [ ] `POST /match/join` adds the player and updates Redis state; all error cases (404, 409 full, 409 in-progress) return correct status codes
- [ ] Leaving as the host with other players present migrates the host to the next-seat player
- [ ] Leaving as the last player deletes the Match and cleans up Redis
- [ ] Non-host calling `POST /match/:id/start` receives 403; host with < 4 players receives 400
- [ ] Integration tests cover all POST /match/join error cases and host migration

### Frontend
- [ ] Join Room input auto-uppercases and limits to 4 characters
- [ ] Correct inline error messages are shown for each failure case
- [ ] Seat grid correctly shows filled/empty slots for all player counts 4–8
- [ ] Only the host sees and can click "Start Game"; enabled when >= 4 players are present
- [ ] All players in the room see the updated player list in real time when someone joins
- [ ] `game:started` navigates all players to `/game/:matchId`

---

## Dependencies

- Requires: EP-001, EP-002
- Blocks: EP-005 (game start)

---

## Reference
- `SYSTEM_DESIGN.md §7` (DB schema), `§8.2` (REST endpoints), `§10` (WebSocket events)
- `GAME_RULES.md §1` (player count: 4–8), `§4` (dealing rules — informs seat count)
- [`tickets.json`](../tickets.json) → `EP-003`, tickets T-021 – T-027
