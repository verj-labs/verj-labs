> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). BE-EP-005 and BE-EP-006 were merged into one feature epic.
> **Replaced by:** [EP-005 — Real-Time Game Play](../epics/EP-005-realtime-game-play.md) · [tickets.json](../tickets.json) → T-041–T-048

---

# BE-EP-005 — WebSocket Gateway & Event System

| Field | Value |
|---|---|
| **ID** | BE-EP-005 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | BE-EP-001, BE-EP-002, BE-EP-003 |
| **Blocks** | FE-EP-005, BE-EP-006 |
| **Estimated Effort** | M (4–6 days) |

---

## Description

This epic builds the real-time communication layer of Shah Exchange — the Socket.IO WebSocket gateway that connects players to live game state. All in-game actions (plays, passes), notifications (turn changes, round endings, player finishes), and lobby events (player joined, match started) flow through this gateway.

The gateway is the nervous system of the application: it receives player intents and broadcasts game state updates to all players in a room.

---

## Background & Motivation

Shah Exchange is a synchronous multiplayer game. When one player makes a move, all other players need to see the result within milliseconds. HTTP polling would be too slow and wasteful. WebSockets (via Socket.IO) are the correct mechanism, providing persistent bidirectional connections with built-in room support for scoping broadcasts to a specific match.

---

## Goals

- Establish Socket.IO gateway with NestJS `@WebSocketGateway`
- Authenticate connections using session tokens (from BE-EP-002)
- Manage player connections and disconnections gracefully
- Route incoming events to appropriate service handlers
- Broadcast outgoing events to the correct socket rooms
- Define a complete, versioned event contract (all event names and payload shapes)
- Handle reconnection: restore player to their active match on reconnect
- Implement per-event rate limiting to prevent flooding

---

## Detailed Scope

### 1. Gateway Setup

```typescript
@WebSocketGateway({
  cors: { origin: process.env.FRONTEND_URL, credentials: true },
  namespace: '/',
  transports: ['websocket', 'polling'],
})
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;
}
```

Configure CORS to allow only the known frontend origin.

### 2. Connection Lifecycle

**`handleConnection(client: Socket)`**
- Extract token from `client.handshake.auth.token`
- Validate token via `AuthService.validateToken()`
- If invalid → `client.disconnect(true)`
- If valid:
  - Attach `player` to socket data: `client.data.player`
  - Look up player's active match in Redis
  - If in active match → call `client.join(`match:${matchId}`)` and emit current match state to this socket only
  - Store socket-to-player mapping in Redis: `socket:{socketId}` → `{ playerId, matchId }`
  - Emit `player:connected` to the match room (other players notified)

**`handleDisconnect(client: Socket)`**
- Look up player from socket data
- If in active match: emit `player:disconnected` to the match room
- If match is in 'lobby' and player was NOT yet in-game: remove from lobby (call MatchService)
- If match is 'in_progress': do NOT remove from game — allow reconnect window (5 minutes)
- Clean up Redis socket mapping

### 3. Client → Server Event Handlers

All handlers must:
1. Validate the player is authenticated (via guard or inline check)
2. Validate the player is in the relevant match
3. Delegate to the appropriate service
4. Return a confirmation or error to the calling socket

```typescript
// Lobby events
@SubscribeMessage('match:ready')
handleReady(client: Socket): void

@SubscribeMessage('match:start')
handleStart(client: Socket): void

// Game events
@SubscribeMessage('game:play')
handlePlay(client: Socket, payload: { cards: CardDto[] }): void

@SubscribeMessage('game:pass')
handlePass(client: Socket): void

// Reconnection
@SubscribeMessage('player:reconnect')
handleReconnect(client: Socket, payload: { matchId: string }): void
```

### 4. Server → Client Event Definitions

Define all event names as a TypeScript enum/const:

```typescript
export const GameEvents = {
  // Lobby
  MATCH_UPDATED: 'match:updated',
  MATCH_STARTED: 'match:started',
  HOST_CHANGED: 'match:host_changed',

  // Game
  GAME_STARTED: 'game:started',
  GAME_STATE_UPDATED: 'game:state_updated',
  PLAY_ACCEPTED: 'game:play_accepted',
  PLAY_REJECTED: 'game:play_rejected',
  ROUND_ENDED: 'game:round_ended',
  PLAYER_SKIPPED: 'game:player_skipped',
  PILE_RESET: 'game:pile_reset',
  PLAYER_FINISHED: 'game:player_finished',
  GAME_FINISHED: 'game:finished',
  EXCHANGE_COMPLETE: 'game:exchange',

  // Match
  MATCH_FINISHED: 'match:finished',

  // Player
  PLAYER_CONNECTED: 'player:connected',
  PLAYER_DISCONNECTED: 'player:disconnected',
  PLAYER_RECONNECTED: 'player:reconnected',
} as const;
```

Each event must have a corresponding TypeScript interface for its payload in `src/shared/types/events.types.ts`.

### 5. Room Management Helpers

```typescript
// Broadcast to all players in a match
broadcastToMatch(matchId: string, event: string, payload: unknown): void {
  this.server.to(`match:${matchId}`).emit(event, payload);
}

// Emit only to a specific socket (private message)
emitToPlayer(socketId: string, event: string, payload: unknown): void {
  this.server.to(socketId).emit(event, payload);
}
```

### 6. Rate Limiting
Implement a simple in-memory token-bucket per socket:
- `game:play` and `game:pass` → max 10 events per second per socket
- If rate limit exceeded → emit `error: { code: 'RATE_LIMITED' }` to that socket only
- Consider using `nestjs-throttler` with WebSocket adapter or a custom interceptor

### 7. Event DTOs & Validation
All incoming payloads must be validated with `class-validator`:

```typescript
class PlayIntentDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CardDto)
  cards: CardDto[];
}

class CardDto {
  @IsIn(['hearts','diamonds','clubs','spades'])
  suit: Suit;

  @IsIn(['3','4','5','6','7','8','9','10','J','Q','K','A','2'])
  rank: Rank;
}
```

Invalid payloads are rejected with a typed error event, without crashing the gateway.

### 8. Reconnect Flow
When a player reconnects:
1. They connect with their token (normal connection flow)
2. `handleConnection` detects they have an active match in Redis
3. Join them back to the socket room
4. Emit the current full `GameState` to their socket only (they missed updates)
5. Broadcast `player:reconnected` to rest of room
6. Cancel any "player abandoned" timeout if one was pending

### 9. Logging
Log all socket connection, disconnection, and game events with:
- Socket ID
- Player ID + display name
- Match ID
- Event name
- Timestamp

Use NestJS Logger with appropriate log levels.

---

## Acceptance Criteria

- [ ] Socket.IO server starts on the correct port and accepts connections
- [ ] Connection with invalid token is rejected (client disconnected immediately)
- [ ] Connection with valid token attaches player to their match room
- [ ] `game:play` event reaches the GameService and state is updated
- [ ] `game:pass` event reaches the GameService and state is updated
- [ ] All `GameEvents` constants are defined with TypeScript payloads
- [ ] Broadcast to match room reaches all connected players in that room
- [ ] Private emits reach only the target socket
- [ ] Disconnection emits `player:disconnected` to the room
- [ ] Reconnection restores player to their room and emits full current state
- [ ] Rate limiting rejects excessive events with an error
- [ ] Invalid payloads return typed error events (no crash/500)
- [ ] All events and payloads are documented in `src/shared/types/events.types.ts`
- [ ] Integration tests cover connect/disconnect/play/pass flows

---

## Out of Scope

- Admin monitoring of sockets
- Chat/emote events
- Spectator connections

---

## Technical Notes

- Use `@nestjs/platform-socket.io` (already in NestJS ecosystem)
- For future horizontal scaling, use `@socket.io/redis-adapter` — wire it up now even if single-instance initially
- All socket events should go through the gateway — no other module should emit socket events directly
- The gateway should be thin (delegate all business logic to services)
