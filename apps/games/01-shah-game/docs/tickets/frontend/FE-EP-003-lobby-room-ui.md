> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-003 — Lobby & Room Management](../epics/EP-003-lobby-room-management.md) · [tickets.json](../tickets.json) → T-025–T-027

---

# FE-EP-003 — Lobby & Room Management UI

| Field | Value |
|---|---|
| **ID** | FE-EP-003 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | FE-EP-001, FE-EP-002 |
| **Blocks** | FE-EP-004 |
| **Estimated Effort** | M (3–5 days) |

---

## Description

This epic covers the full pre-game lobby experience: the page where a player chooses to create a new room or join an existing one by code, the waiting room screen where all players in the room are visible before the game starts, and the host controls to start the match.

This is the "social" layer of the game — the gathering point before cards are dealt.

---

## Background & Motivation

Players need a coordinated meeting point before a game can begin. The lobby serves this purpose: it is where room codes are shared, players gather, and readiness is established. A clear, responsive lobby UI is essential for a smooth game start experience.

---

## Goals

- Lobby page: create a room or join by code
- Waiting room page: see all joined players in real time
- Real-time updates as players join/leave (via WebSocket — stubbed until FE-EP-005, but UI should be wired for it)
- Host-only "Start Game" button (enabled when 4+ players have joined)
- Non-host players see a "Waiting for host to start" state
- Visual seat indicators showing which slots are filled
- Handle edge cases: room full, room not found, match already started

---

## Detailed Scope

### 1. Lobby Page (`/lobby`)

**Two options presented:**

**Create a Room:**
- Large "Create Room" button
- Calls `POST /match`
- On success: navigate to `/room/:code` (the waiting room)
- Show loading state during creation

**Join a Room:**
- Text input: "Enter room code" (4 chars, uppercase enforced)
- "Join" button
- Calls `POST /match/join` with the code
- On success: navigate to `/room/:code`
- Clear error states: "Room not found", "Room is full", "Game already started"

**Layout:**
- Two side-by-side cards (on desktop), stacked (on mobile)
- Player's display name visible in top-right header area
- Option to change display name links to modal or back to `/`

### 2. Waiting Room Page (`/room/:code`)

Accessible to all players in the match. Fetches initial state from `GET /match/:id` and then subscribes to WebSocket events for real-time updates.

**Components:**

**Room Code Display:** Large, prominent room code with a "Copy" button
```
Room: XJKQ  [📋 Copy]
```

**Player List:** Visual grid of 4–8 seat slots:
- Each filled slot: player avatar + display name + "Ready" badge if ready
- Empty slots: outlined slot with "Empty" placeholder
- Current player's slot highlighted
- Host indicated with a crown icon

**Player Count Indicator:** "3 / 4–8 players joined" below the grid

**Start Button (host only):**
- Enabled: when ≥ 4 players are in the room
- Disabled state with tooltip: "Need at least 4 players to start"
- Calls `POST /match/:id/start`
- After click: loading state, then transition triggers `game:started` WebSocket event → navigate to `/game/:matchId`

**Waiting Message (non-host):**  
"Waiting for [HostName] to start the game..."

**Leave Room Button:**
- Calls `DELETE /match/:id/leave`
- Navigates back to `/lobby`
- If host leaves with others remaining: host migrates (WebSocket event updates UI)

### 3. Real-Time Updates in Waiting Room

Subscribe to socket events (stubs now, full integration in FE-EP-005):
- `match:updated` → refresh player list
- `match:host_changed` → update host badge
- `game:started` → navigate to `/game/:matchId`
- `player:disconnected` → show disconnected indicator on player slot

Use a `useMatchSocket()` hook that sets up listeners and dispatches to the `matchStore`.

### 4. Match Store (`src/store/matchStore.ts`)

```typescript
interface MatchStore {
  matchId: string | null;
  roomCode: string | null;
  hostPlayerId: string | null;
  players: MatchPlayer[];
  status: MatchStatus;
  // Actions
  setMatch: (match: MatchState) => void;
  updatePlayers: (players: MatchPlayer[]) => void;
  setHost: (playerId: string) => void;
  clearMatch: () => void;
}
```

### 5. Error States & Edge Cases

| Scenario | UI Response |
|---|---|
| Joining a non-existent code | Inline error: "Room not found. Check the code and try again." |
| Joining a full room (8 players) | Inline error: "This room is full." |
| Joining a match in progress | Inline error: "This game has already started." |
| Host leaving | All other players see: "[OldHost] left. [NewHost] is now the host." |
| Player disconnected in lobby | Their slot shows a "(disconnected)" badge |
| Navigating to `/room/:code` for a match you're not in | 404 redirect or error page |
| Network error creating/joining room | Toast: "Failed to connect. Please try again." |

### 6. Seat Visualization

Display seats in a circular or grid layout that hints at the table layout:
- 4 players: 2×2 grid
- 5–6 players: 2×3 grid  
- 7–8 players: 2×4 grid
- Each slot has an index number (Seat 1, Seat 2...) for reference
- This sets player expectations before the game starts

---

## Acceptance Criteria

- [ ] `/lobby` shows create + join options
- [ ] Creating a room calls API, navigates to `/room/:code`, and shows the waiting room
- [ ] Joining with a valid code navigates to `/room/:code`
- [ ] Joining with an invalid code shows the correct inline error message
- [ ] All players in the room are visible in the player list
- [ ] The host sees "Start Game" button; non-hosts see "Waiting for host" message
- [ ] "Start Game" is disabled when fewer than 4 players are present
- [ ] Host can click "Start Game" and all players transition to the game screen
- [ ] "Leave Room" removes the player and navigates to `/lobby`
- [ ] Room code can be copied to clipboard
- [ ] WebSocket updates (player joined, player left, host changed) update the UI
- [ ] Disconnected players show a visual indicator

---

## Out of Scope

- Ready/unready toggle per player (all players are considered "ready" — only host controls start)
- Game settings or configuration in lobby
- Chat in the waiting room

---

## Technical Notes

- The room code input should auto-uppercase as the user types and limit input to 4 characters
- After joining, store the `matchId` in the session store (update `session:{token}` client-side) so reconnection can find the match
- If the host starts the game, a `game:started` WebSocket event is the primary navigation trigger — don't rely solely on the REST response
