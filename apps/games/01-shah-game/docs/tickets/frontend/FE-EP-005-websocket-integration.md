> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). FE-EP-004 and FE-EP-005 were merged into one feature epic.
> **Replaced by:** [EP-005 — Real-Time Game Play](../epics/EP-005-realtime-game-play.md) · [tickets.json](../tickets.json) → T-055–T-058

---

# FE-EP-005 — WebSocket Integration & State Sync

| Field | Value |
|---|---|
| **ID** | FE-EP-005 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | FE-EP-001, FE-EP-002, FE-EP-004, BE-EP-005 |
| **Blocks** | FE-EP-006, FE-EP-007 |
| **Estimated Effort** | M (4–6 days) |

---

## Description

This epic wires up the real-time communication layer, connecting the frontend to the backend Socket.IO gateway. It establishes the socket client singleton, handles connection lifecycle (connect, disconnect, reconnect), maps all incoming server events to Zustand store updates, and provides the outgoing event senders (play, pass) that the game board triggers.

After this epic, the game is fully playable end-to-end in a browser.

---

## Background & Motivation

The game board (FE-EP-004) was built against mock data. This epic replaces all mocks with live data flowing from the backend. When one player makes a move, all other players' boards update in real time. Without this epic, the game is just a static UI.

---

## Goals

- Socket.IO client singleton that authenticates with the session token
- Socket lifecycle management: connect on entering game/lobby, disconnect on leaving
- Map all `GameEvents` (defined in BE-EP-005) to corresponding store updates and UI side effects
- Send `game:play` and `game:pass` events from the ActionBar
- Handle disconnection gracefully (show banner, attempt reconnect)
- Handle reconnection (restore full game state from the server)
- Update both `matchStore` and `gameStore` from socket events
- Show toast notifications for significant game events (player finished, round ended, etc.)

---

## Detailed Scope

### 1. Socket Client Singleton (`src/services/socket.ts`)

```typescript
import { io, Socket } from 'socket.io-client';
import { config } from '@/lib/config';

let socket: Socket | null = null;

export function getSocket(): Socket {
  if (!socket) {
    socket = io(config.socketUrl, {
      autoConnect: false,
      transports: ['websocket'],
      auth: { token: getSessionToken() }, // reads from sessionStore
    });
  }
  return socket;
}

export function connectSocket(): void {
  getSocket().connect();
}

export function disconnectSocket(): void {
  getSocket().disconnect();
}
```

Connect when player navigates to `/room/:code` or `/game/:matchId`.  
Disconnect when player is on `/` or `/lobby` (no active match).

### 2. Socket Store (`src/store/socketStore.ts`)

```typescript
interface SocketStore {
  connected: boolean;
  connecting: boolean;
  error: string | null;
  setConnected: (v: boolean) => void;
  setError: (e: string | null) => void;
}
```

### 3. `useSocketSetup()` Hook

Created in `src/hooks/useSocketSetup.ts`. Called once in a top-level component (e.g., `App.tsx` or a `GameProvider`).

Sets up all event listeners:

```typescript
function useSocketSetup() {
  const { setGameState, setActionPending, setActionError, clearSelection } = useGameStore();
  const { setMatch, updatePlayers } = useMatchStore();
  const socket = getSocket();

  useEffect(() => {
    socket.on('connect', handleConnect);
    socket.on('disconnect', handleDisconnect);
    socket.on('connect_error', handleConnectError);

    // Lobby events
    socket.on(GameEvents.MATCH_UPDATED, handleMatchUpdated);
    socket.on(GameEvents.MATCH_STARTED, handleMatchStarted);
    socket.on(GameEvents.HOST_CHANGED, handleHostChanged);

    // Game events
    socket.on(GameEvents.GAME_STARTED, handleGameStarted);
    socket.on(GameEvents.GAME_STATE_UPDATED, handleStateUpdated);
    socket.on(GameEvents.PLAY_REJECTED, handlePlayRejected);
    socket.on(GameEvents.ROUND_ENDED, handleRoundEnded);
    socket.on(GameEvents.PLAYER_SKIPPED, handlePlayerSkipped);
    socket.on(GameEvents.PILE_RESET, handlePileReset);
    socket.on(GameEvents.PLAYER_FINISHED, handlePlayerFinished);
    socket.on(GameEvents.GAME_FINISHED, handleGameFinished);
    socket.on(GameEvents.EXCHANGE_COMPLETE, handleExchange);
    socket.on(GameEvents.MATCH_FINISHED, handleMatchFinished);

    // Player events
    socket.on(GameEvents.PLAYER_DISCONNECTED, handlePlayerDisconnected);
    socket.on(GameEvents.PLAYER_RECONNECTED, handlePlayerReconnected);

    return () => { socket.removeAllListeners(); };
  }, []);
}
```

### 4. Outgoing Event Senders

Create `src/services/gameActions.ts`:

```typescript
export function sendPlay(cards: Card[]): void {
  getSocket().emit('game:play', { cards });
}

export function sendPass(): void {
  getSocket().emit('game:pass');
}

export function sendReady(): void {
  getSocket().emit('match:ready');
}

export function sendStartMatch(): void {
  getSocket().emit('match:start');
}
```

The `ActionBar` component calls `sendPlay(selectedCards)` or `sendPass()`.  
After sending, set `isActionPending: true` in `gameStore`.  
Clear pending state on `GAME_STATE_UPDATED` or `PLAY_REJECTED`.

### 5. Incoming Event Handlers

#### `handleGameStarted(payload: GameState)`
- Call `gameStore.setGameState(payload)`
- Navigate to `/game/:matchId` (if not already there)
- Clear any selected cards
- Show "Game started!" toast

#### `handleStateUpdated(payload: GameState)`
- Call `gameStore.setGameState(payload)`
- Set `isActionPending: false`
- Clear `selectedCards` if it was this player's play that was processed

#### `handlePlayRejected(payload: { reason: string })`
- Set `gameStore.actionError = payload.reason`
- Set `isActionPending: false`
- Show error toast

#### `handleRoundEnded(payload: { winnerId, nextState })`
- Call `gameStore.setGameState(payload.nextState)`
- Brief UI notification: "[Player] wins the round!"
- Small delay before next round begins

#### `handlePlayerSkipped(payload: { playerId })`
- Trigger skip animation on the skipped player's position
- Show brief "SKIPPED" overlay

#### `handlePileReset(payload: { playerId, resetCard, nextState })`
- Trigger pile-clear animation
- Show "Reset!" toast mentioning the player
- Call `gameStore.setGameState(payload.nextState)`

#### `handlePlayerFinished(payload: { playerId, rank, nextState })`
- Show rank badge animation for that player
- Toast: "[Player] finished — Rank #N"
- Update game state

#### `handleGameFinished(payload: GameSummary)`
- Show end-of-game overlay with rankings
- Transition to exchange phase UI (FE-EP-007)

#### `handlePlayerDisconnected(payload: { playerId })`
- Set disconnected indicator on that player's avatar
- Toast: "[Player] disconnected"

#### `handlePlayerReconnected(payload: { playerId })`
- Clear disconnected indicator
- Toast: "[Player] reconnected"

### 6. Reconnection Flow

If the socket disconnects unexpectedly:
1. Show a dismissible "Connection lost" banner at the top of the screen
2. Socket.IO's built-in auto-reconnect fires (with exponential backoff)
3. On reconnect, the server sends the full current `GameState` to this socket
4. `handleStateUpdated` restores the board
5. Banner clears

If the player manually refreshes the page:
1. `restoreSession()` reads the token from `localStorage`
2. Socket connects with the token
3. Server detects active match and emits current `GameState`
4. Board is re-initialized

### 7. Connection Timing

- Connect socket when navigating TO `/room/:code` or `/game/:matchId`
- Disconnect socket when navigating TO `/` or `/lobby` (or on logout)
- Use React Router's `useNavigate` + cleanup in `useEffect` for this

---

## Acceptance Criteria

- [ ] Socket connects when player enters the waiting room or game
- [ ] Socket disconnects when player logs out or returns to lobby
- [ ] `game:started` event navigates all players to the game board and populates `gameStore`
- [ ] Playing a card emits `game:play` and sets `isActionPending: true`
- [ ] `game:state_updated` clears `isActionPending` and updates all players' boards
- [ ] `game:play_rejected` shows an error to the acting player only
- [ ] Round-end events show toast notification for round winner
- [ ] Player-finished events animate the rank badge
- [ ] Disconnected player's avatar shows a disconnected indicator
- [ ] Page refresh during a game restores the full board state
- [ ] Connection loss shows a banner; reconnection clears it and restores state
- [ ] All event listeners are cleaned up when the component unmounts
- [ ] Integration test: emit mocked socket events and assert store + UI updates

---

## Out of Scope

- Animations (FE-EP-006)
- Exchange UI sequence (FE-EP-007)
- Match history (FE-EP-008)

---

## Technical Notes

- The socket singleton must be initialized with the token from `sessionStore`, not from `localStorage` directly — ensure the store is already populated before connecting
- Use `socket.once()` for one-time events and `socket.on()` for recurring ones
- In testing, use `socket.io-mock` or a test server to simulate server events
- Do NOT call `socket.connect()` in the service file's module scope — connect lazily via `connectSocket()`
