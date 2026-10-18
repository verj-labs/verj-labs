> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary backend detail.
> **Replaced by:** [EP-003 — Lobby & Room Management](../epics/EP-003-lobby-room-management.md) · [tickets.json](../tickets.json) → T-021–T-024

---

# BE-EP-003 — Match & Lobby Management

| Field | Value |
|---|---|
| **ID** | BE-EP-003 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | BE-EP-001, BE-EP-002 |
| **Blocks** | BE-EP-005, BE-EP-006 |
| **Estimated Effort** | M (4–5 days) |

---

## Description

This epic covers all functionality for creating, discovering, joining, and managing Match rooms — the pre-game lobby phase of the application. A Match is a session container that holds 4–8 players, tracks their readiness, and transitions into active Game play when the host starts it.

The lobby is the "waiting room" before cards are dealt. This epic ensures players can reliably coordinate around a room code before the game engine takes over.

---

## Background & Motivation

Before any card game logic can execute, players need a reliable mechanism to:
1. Create a named room with a shareable 4-character code
2. Allow other players to join via that code
3. See who's in the room and their ready status
4. Allow the host to start when enough players have joined

This epic is entirely about orchestrating the pre-game phase and the match container that persists across multiple Games within a session.

---

## Goals

- Create a Match with a unique, readable room code (4 uppercase alphanumeric chars)
- Allow players to join a match by room code
- Enforce player count constraints (4 minimum, 8 maximum)
- Allow the host to start the match
- Persist Match and participant data to Postgres
- Broadcast lobby state changes in real-time via WebSocket (plugs into BE-EP-005)
- Allow players to leave the lobby before the match starts
- Handle the host disconnecting (host migration or room closure)

---

## Detailed Scope

### 1. Match Entity (Postgres)
```
id: UUID
room_code: CHAR(4), UNIQUE
host_id: UUID (FK → players.id)
status: enum('lobby', 'in_progress', 'finished')
player_count: INT (denormalized for quick lookup)
created_at: TIMESTAMPTZ
ended_at: TIMESTAMPTZ nullable
```

### 2. Match Players Junction (Postgres)
```
match_id: UUID (FK)
player_id: UUID (FK)
seat_index: INT (0-based, assigned on join, determines seating order)
is_ready: BOOLEAN DEFAULT false
joined_at: TIMESTAMPTZ
PK: (match_id, player_id)
```

### 3. Room Code Generation
- Generate a random 4-character code (uppercase A-Z, digits 2-9 — exclude 0,1,O,I for readability)
- Check for uniqueness in Postgres before issuing
- Retry up to 5 times on collision (collision probability is very low with ~1 million possible codes)
- Codes are scoped to active matches only; finished match codes can be reused after 24h

### 4. REST Endpoints

**`POST /match`** — Create a match
- Auth required
- Creates Match record (status: 'lobby'), adds creator as player with `seat_index: 0`
- Sets creator as host
- Stores match state in Redis
- Response: `{ matchId, roomCode, match: MatchState }`

**`POST /match/join`** — Join a match by code
- Auth required
- Body: `{ roomCode: string }`
- Validates: room exists, status is 'lobby', not already at max players, player not already in room
- Assigns next available seat_index
- Updates match in Redis + Postgres
- Response: `{ matchId, match: MatchState }`

**`GET /match/:id`** — Get current match state
- Auth required
- Returns full MatchState (including players, status, current game if in_progress)

**`DELETE /match/:id/leave`** — Leave the lobby
- Auth required
- Player must be in the match and match must be in 'lobby' status
- If player is host and others remain → trigger host migration (next player by seat becomes host)
- If last player leaves → delete the match

**`POST /match/:id/start`** — Start the match
- Auth required, only host can call this
- Validates: status is 'lobby', player count is 4–8
- Transitions match status to 'in_progress'
- Triggers game creation (kicks off BE-EP-006 flow via GameService)

### 5. Match State in Redis
Cache the full `MatchState` object in Redis:
- Key: `match:{matchId}:state`
- TTL: 24h (extended when match is active)
- Updated on every join / leave / start event
- Serves fast reads for the WebSocket gateway

### 6. Seat Assignment Logic
- Seats are assigned sequentially (0, 1, 2, ...) as players join
- Seat index determines seating order and is used to calculate turn direction after Game 1
- Seats do NOT reshuffle between games within a match

### 7. Host Migration
When the host disconnects or leaves the lobby:
- The player with the lowest seat_index (among remaining players) becomes the new host
- A `match:host_changed` WebSocket event is broadcast to the room
- If no players remain, the match is deleted

### 8. Player Count & Validation
| Condition | HTTP Response |
|---|---|
| Room not found | 404 |
| Room not in 'lobby' status | 409 Conflict |
| Room already at 8 players | 409 Conflict |
| Player already in this room | 409 Conflict |
| Player already in a different active room | 409 Conflict |
| Starting with fewer than 4 players | 400 Bad Request |

### 9. Match Summary for History
After a match ends, persist a `MatchSummary` to Postgres (used by BE-EP-008):
- Total games played
- Final standings per player (aggregate ranking)
- Duration

---

## Acceptance Criteria

- [ ] `POST /match` creates a match and returns a 4-char room code
- [ ] Room codes are unique among active matches
- [ ] `POST /match/join` with valid code adds the player to the room
- [ ] Joining a full room (8 players) returns 409
- [ ] Joining a non-existent code returns 404
- [ ] Joining a match already `in_progress` returns 409
- [ ] Host can call `POST /match/:id/start` — non-hosts cannot (403)
- [ ] Starting with fewer than 4 players returns 400
- [ ] Match state is stored and retrievable from Redis
- [ ] `DELETE /match/:id/leave` removes the player; host migrates correctly
- [ ] All state changes are reflected in Postgres
- [ ] WebSocket events are emitted for all lobby state changes (stub integration — full delivery in BE-EP-005)
- [ ] Unit tests cover: code generation, join validation, host migration, leave logic

---

## Out of Scope

- Private vs public rooms
- Password-protected rooms
- Spectator slots
- Invite links (only room code join is supported in v1.0)

---

## Technical Notes

- The `MatchService` should emit events to the `EventEmitter2` (or similar) that the WebSocket Gateway (BE-EP-005) subscribes to. This keeps MatchService decoupled from the Gateway.
- Match state stored in Redis is the authoritative live state; Postgres is the durable record.
- Consider using a `MatchStateMapper` to convert between Postgres entities and the MatchState type used over the wire.
