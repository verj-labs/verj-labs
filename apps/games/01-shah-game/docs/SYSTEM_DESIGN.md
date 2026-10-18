# Shah Exchange — System Design Document

**Version:** 1.0  
**Status:** Draft  
**Authors:** Game Design & Engineering Team  
**Date:** 2026-02-25

---

## Table of Contents

1. [Overview](#overview)
2. [Goals & Non-Goals](#goals--non-goals)
3. [Architecture Overview](#architecture-overview)
4. [Technology Stack](#technology-stack)
5. [Core Domain Model](#core-domain-model)
6. [Game State Machine](#game-state-machine)
7. [Database Schema](#database-schema)
8. [Backend Design](#backend-design)
9. [Frontend Design](#frontend-design)
10. [Real-Time Communication (WebSocket)](#real-time-communication-websocket)
11. [Security & Validation](#security--validation)
12. [Scalability Considerations](#scalability-considerations)

---

## 1. Overview

Shah Exchange is a real-time, multiplayer card game for 3–8 players, played over a WebSocket-connected browser interface. Players are dealt cards, take turns playing sets (singles, doubles, triples, quads), and the first to empty their hand wins. A Match consists of multiple Games, with rankings determining card exchanges between Games.

This document defines the system architecture, data models, API contracts, real-time event flows, and front-end structure required to implement a fully functional, production-grade version of the game.

---

## 2. Goals & Non-Goals

### Goals
- Real-time multiplayer gameplay (3–8 players) via WebSockets
- Full implementation of the Shah Exchange ruleset (v1.0)
- Persistent match/game history
- Room-based lobby system (create/join rooms)
- Turn-based game engine with server-side rule enforcement
- Player authentication (at minimum: display name + session token)
- Responsive frontend playable on desktop browsers

### Non-Goals (v1.0)
- Mobile-native app
- Spectator mode
- AI/bot opponents
- Ranked matchmaking / ELO system
- Monetization or user accounts with passwords (OAuth deferred)
- Chat / emotes

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Browser (React + Vite)                      │
│                                                                     │
│   Lobby UI  ──►  Game Board UI  ──►  End-of-Game UI                │
│      │                 │                                            │
│   REST API         WebSocket (Socket.IO client)                    │
└────────┬────────────────┬────────────────────────────────────────── ┘
         │                │
         ▼                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      NestJS Backend                                 │
│                                                                     │
│   REST Controllers   WebSocket Gateway   Game Engine (Service)     │
│        │                    │                    │                  │
│   Auth Module          Room Manager        Match / Game / Round     │
│                              │               State Manager         │
│                         Session Store                               │
│                              │                                      │
│                         PostgreSQL (via TypeORM / Prisma)           │
│                         Redis (session + pub/sub for scale-out)      │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Real-time transport | Socket.IO (on top of WebSocket) | Room namespacing, reconnect handling, fallback |
| Game logic location | **Server-side only** | Prevents cheating; single source of truth |
| State storage | In-memory (Redis) for active games, Postgres for completed | Low-latency live state, durable history |
| Frontend state | Zustand + socket events | Lightweight, predictable, no over-engineering |
| Validation | Server enforces all rules | Clients send *intent*, server validates and broadcasts result |

---

## 4. Technology Stack

### Backend
| Layer | Technology |
|---|---|
| Framework | NestJS (TypeScript) |
| Runtime | Node.js 20+ |
| WebSocket | Socket.IO via `@nestjs/platform-socket.io` |
| ORM | TypeORM or Prisma |
| Database | PostgreSQL |
| Cache / Pub-Sub | Redis (`ioredis`) |
| Validation | `class-validator` + `class-transformer` |
| Testing | Jest + Supertest |
| Package Manager | pnpm |

### Frontend
| Layer | Technology |
|---|---|
| Framework | React 18 (TypeScript) |
| Build Tool | Vite |
| Routing | React Router v6 |
| State Management | Zustand |
| WebSocket Client | Socket.IO client |
| Styling | Tailwind CSS |
| Component Library | shadcn/ui (Radix primitives) |
| Animation | Framer Motion |
| Testing | Vitest + React Testing Library |

---

## 5. Core Domain Model

### 5.1 Card

```typescript
type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades';
type Rank = '3'|'4'|'5'|'6'|'7'|'8'|'9'|'10'|'J'|'Q'|'K'|'A'|'2';

interface Card {
  rank: Rank;
  suit: Suit;
}
```

**Rank ordering (for comparison):**
- Standard game play: `3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A`  
- Exchange evaluation: `3 < 4 < ... < A < 2`  
- `2` is NOT part of the standard rank ladder for beating cards; it resets.

---

### 5.2 Play (a set played on the pile)

```typescript
type SetSize = 1 | 2 | 3 | 4;

interface Play {
  cards: Card[];      // length must equal setSize
  rank: Rank;         // rank of all cards in the set
  setSize: SetSize;
  isReset: boolean;   // true if the rank is '2' and triggers a reset
}
```

---

### 5.3 Pile

```typescript
interface Pile {
  topPlay: Play | null;   // most recently played set
  history: Play[];        // all plays this round (for audit)
}
```

---

### 5.4 Player (in-game representation)

```typescript
interface Player {
  id: string;             // socket session ID or persistent user ID
  displayName: string;
  hand: Card[];
  seatIndex: number;      // 0-based seating position
  isFinished: boolean;
  finishRank: number | null;  // 1 = 1st place, null = not finished yet
}
```

---

### 5.5 Round State

```typescript
interface RoundState {
  pile: Pile;
  activePlayerIndex: number;
  consecutivePassCount: number;
  skippedPlayerIndex: number | null;  // the player skipped due to same-rank rule
}
```

---

### 5.6 Game State

```typescript
type GameStatus = 'waiting' | 'dealing' | 'in_progress' | 'finished';
type Direction = 'clockwise' | 'counterclockwise';

interface GameState {
  id: string;
  matchId: string;
  status: GameStatus;
  players: Player[];           // ordered by seatIndex
  direction: Direction;
  startPlayerIndex: number;    // who goes first this Game
  currentRound: RoundState;
  finishedPlayers: string[];   // player IDs in finish order
  gameNumber: number;          // which game in the match (1-based)
}
```

---

### 5.7 Match State

```typescript
type MatchStatus = 'lobby' | 'in_progress' | 'finished';

interface MatchState {
  id: string;
  roomCode: string;            // short join code (e.g. "XJKQ")
  hostPlayerId: string;
  players: Player[];
  status: MatchStatus;
  currentGame: GameState | null;
  gameHistory: GameSummary[];
  playerCount: number;         // 3–8
}
```

---

## 6. Game State Machine

### 6.1 Match Lifecycle

```
LOBBY  ──(host starts)──►  IN_PROGRESS  ──(all games done / host ends)──►  FINISHED
```

### 6.2 Game Lifecycle

```
WAITING  ──(deal cards)──►  IN_PROGRESS  ──(all players finish)──►  FINISHED
                                                                          │
                                                              Card Exchange occurs
                                                                          │
                                                              Next Game begins
```

### 6.3 Round Lifecycle

```
ROUND_START (pile empty, active player picks a play)
     │
     ▼
PLAYER_TURN
  ├── play valid set
  │    ├── is reset (rank = 2)?  ──►  PILE_RESET  ──►  same player's PLAYER_TURN
  │    ├── same rank as pile?  ──►  SKIP_NEXT_PLAYER  ──►  PLAYER_TURN (skipped)
  │    └── higher rank?  ──►  UPDATE_PILE  ──►  next PLAYER_TURN
  └── pass
       └── consecutivePassCount++
           ├── == activePlayers - 1?  ──►  ROUND_END  ──►  last-play winner starts next ROUND_START
           └── else  ──►  next PLAYER_TURN
```

### 6.4 Win Condition Check
After every valid play, check: `player.hand.length === 0`  
- If so: record finish rank, mark player as finished, remove from turn order
- If all players finished: transition game to `FINISHED`

### 6.5 Card Exchange (between Games)
Happens after `FINISHED`, before next game `WAITING`:

| Exchange Pair | Giver | Cards Given | Receiver |
|---|---|---|---|
| 1st ↔ Last | 1st place | 2 worst cards | Last place |
| Last ↔ 1st | Last place | 2 best cards | 1st place |
| 2nd ↔ 2nd-Last | 2nd place | 1 worst card | 2nd-last place |
| 2nd-Last ↔ 2nd | 2nd-last place | 1 best card | 2nd place |

Card ranking for "best/worst": `3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2`

---

## 7. Database Schema

### 7.1 Tables

```sql
-- Users / Players
CREATE TABLE players (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name VARCHAR(32) NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Matches
CREATE TABLE matches (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code   CHAR(4) NOT NULL UNIQUE,
  host_id     UUID REFERENCES players(id),
  status      VARCHAR(16) NOT NULL DEFAULT 'lobby',
  player_count INT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  ended_at    TIMESTAMPTZ
);

-- Match participants
CREATE TABLE match_players (
  match_id    UUID REFERENCES matches(id),
  player_id   UUID REFERENCES players(id),
  seat_index  INT NOT NULL,
  PRIMARY KEY (match_id, player_id)
);

-- Games within a match
CREATE TABLE games (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id    UUID REFERENCES matches(id),
  game_number INT NOT NULL,
  direction   VARCHAR(16),
  status      VARCHAR(16) NOT NULL DEFAULT 'in_progress',
  started_at  TIMESTAMPTZ DEFAULT now(),
  ended_at    TIMESTAMPTZ
);

-- Final rankings per game
CREATE TABLE game_rankings (
  game_id     UUID REFERENCES games(id),
  player_id   UUID REFERENCES players(id),
  rank        INT NOT NULL,  -- 1 = winner
  PRIMARY KEY (game_id, player_id)
);

-- Full event log (append-only audit trail)
CREATE TABLE game_events (
  id          BIGSERIAL PRIMARY KEY,
  game_id     UUID REFERENCES games(id),
  round_number INT NOT NULL,
  event_type  VARCHAR(32) NOT NULL,  -- 'play', 'pass', 'reset', 'skip', 'round_end', 'game_end'
  player_id   UUID REFERENCES players(id),
  payload     JSONB,
  created_at  TIMESTAMPTZ DEFAULT now()
);
```

### 7.2 Redis Keys (active game state)

```
match:{matchId}:state       → full MatchState JSON
game:{gameId}:state         → full GameState JSON
session:{socketId}          → { playerId, matchId, displayName }
room:{roomCode}             → matchId
```

---

## 8. Backend Design

### 8.1 Module Structure

```
src/
├── app.module.ts
├── main.ts
│
├── auth/                     # Session token issuance & validation
│   ├── auth.module.ts
│   ├── auth.service.ts
│   └── auth.guard.ts
│
├── player/                   # Player entity management
│   ├── player.module.ts
│   ├── player.service.ts
│   └── player.entity.ts
│
├── match/                    # Room/lobby management
│   ├── match.module.ts
│   ├── match.controller.ts   # REST: create/join/leave room
│   ├── match.service.ts
│   └── match.entity.ts
│
├── game/                     # Game orchestration
│   ├── game.module.ts
│   ├── game.service.ts       # Manages game lifecycle, exchange
│   └── game.entity.ts
│
├── game-engine/              # Pure game logic (stateless, testable)
│   ├── game-engine.module.ts
│   ├── game-engine.service.ts
│   ├── deck.service.ts       # Shuffle & deal
│   ├── rules.service.ts      # Validate plays, reset, skip logic
│   ├── exchange.service.ts   # Card exchange logic
│   └── __tests__/
│
├── gateway/                  # WebSocket gateway
│   ├── game.gateway.ts
│   └── events.enum.ts
│
└── shared/
    ├── types/
    │   ├── card.types.ts
    │   ├── game-state.types.ts
    │   └── events.types.ts
    └── utils/
```

### 8.2 REST API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/session` | Create anonymous session (display name → JWT token) |
| `GET` | `/auth/me` | Verify token and return current player |
| `DELETE` | `/auth/session` | Logout (invalidate session) |
| `POST` | `/match` | Create new match room → `{ matchId, roomCode, match }` |
| `POST` | `/match/join` | Join room by code → match state |
| `GET` | `/match/:id` | Get current match state |
| `POST` | `/match/:id/start` | Host starts the match (triggers first Game) |
| `DELETE` | `/match/:id/leave` | Leave the room (host migrates to next seat) |
| `POST` | `/match/:id/end` | Host ends the match → emits `match:finished` to all |
| `GET` | `/match/:id/summary` | Get aggregate match summary and per-game rankings |
| `GET` | `/player/me/matches` | Paginated match history for the authenticated player |

### 8.3 Game Engine Service (Core Logic)

The `GameEngineService` is a pure, stateless service that accepts the current `GameState` + a player intent, and returns the new `GameState` + side effects list. No I/O. Fully unit-testable.

```typescript
interface PlayIntent {
  playerId: string;
  type: 'play' | 'pass';
  cards?: Card[];   // present only when type === 'play'
}

interface EngineResult {
  newState: GameState;
  events: GameEvent[];  // e.g. ['PILE_UPDATED', 'NEXT_PLAYER_SKIPPED', 'PLAYER_FINISHED', ...]
  error?: string;       // validation failure message
}

class GameEngineService {
  processIntent(state: GameState, intent: PlayIntent): EngineResult;
  dealCards(playerCount: number): Card[][];
  performExchange(rankings: Player[]): ExchangeAction[];
  determineDirection(winnerSeat: number, secondPlaceSeat: number): Direction;
}
```

---

## 9. Frontend Design

### 9.1 Page/View Structure

```
/                       → Landing / Name entry
/lobby                  → Create or join a room
/history                → Paginated match history list
/room/:code             → Waiting room (lobby) — shows players, ready states
/game/:matchId          → Active game board
/results/:matchId       → End-of-match summary (live or historical)
```

### 9.2 Component Tree (Game Board)

```
<GamePage>
  ├── <GameStatusBar>         # Current game #, direction indicator, active player
  ├── <OpponentHands>         # All non-local players (card backs + count)
  │    └── <OpponentHand />   # Per player: seat, name, card count, finished badge
  ├── <TableArea>
  │    ├── <PileDisplay>      # Current pile cards (or "pile cleared" animation)
  │    └── <RoundInfo>        # Round number, consecutive pass count
  ├── <LocalPlayerHand>       # Your cards, selectable
  │    └── <Card />           # Individual card component
  ├── <ActionBar>             # Play / Pass buttons, validation messages
  └── <TurnIndicator>         # Whose turn it is (with timer if desired)
```

### 9.3 State Management (Zustand Stores)

```typescript
// matchStore.ts
interface MatchStore {
  matchId: string | null;
  roomCode: string | null;
  players: Player[];
  status: MatchStatus;
  // actions
  setMatch: (match: MatchState) => void;
  updatePlayers: (players: Player[]) => void;
}

// gameStore.ts
interface GameStore {
  gameState: GameState | null;
  localPlayerId: string | null;
  selectedCards: Card[];
  // actions
  setGameState: (state: GameState) => void;
  toggleCard: (card: Card) => void;
  clearSelection: () => void;
}

// socketStore.ts
interface SocketStore {
  socket: Socket | null;
  connected: boolean;
  connect: (token: string) => void;
  disconnect: () => void;
}
```

### 9.4 Card Selection & Play Validation (Client-Side UX only)
The client performs lightweight pre-validation before sending an intent to the server. This is **UX only** — the server re-validates everything.

- Disable "Play" button if selected cards have mismatched ranks
- Disable "Play" button if selected count doesn't match pile size (when pile active)
- Highlight valid playable cards proactively
- Show inline error toast on server rejection

---

## 10. Real-Time Communication (WebSocket)

### 10.1 Socket.IO Rooms
Each Match has a Socket.IO room: `match:{matchId}`  
Each player joins this room on connection.

### 10.2 Client → Server Events (emitted by client)

| Event | Payload | Description |
|---|---|---|
| `game:play` | `{ cards: Card[] }` | Player plays a set |
| `game:pass` | `{}` | Player passes |
| `match:ready` | `{}` | Player signals ready in lobby |
| `match:start` | `{}` | Host starts the match |
| `player:reconnect` | `{ token: string }` | Rejoin after disconnect |

### 10.3 Server → Client Events (broadcast to room)

| Event | Payload | Description |
|---|---|---|
| `match:updated` | `MatchState` | Lobby state changed (player joined/left) |
| `game:started` | `GameState` | New game began, hands dealt |
| `game:state_updated` | `GameState` | Game state changed after any action |
| `game:play_accepted` | `{ play: Play, nextState: GameState }` | A valid play was made |
| `game:play_rejected` | `{ reason: string }` | Your play was invalid |
| `game:round_ended` | `{ winnerId: string, nextState: GameState }` | Round over |
| `game:player_finished` | `{ playerId: string, rank: number }` | A player emptied their hand |
| `game:player_skipped` | `{ playerId: string }` | A player was skipped |
| `game:pile_reset` | `{ playerId: string, resetCard: Card }` | Pile was reset with a 2 |
| `game:exchange` | `ExchangeSummary` | Card exchange results |
| `game:finished` | `GameSummary` | Game over, rankings |
| `match:finished` | `MatchSummary` | All games done |
| `player:disconnected` | `{ playerId: string }` | Player dropped |
| `player:reconnected` | `{ playerId: string }` | Player rejoined |

### 10.4 Reconnection Strategy
- On reconnect, client emits `player:reconnect` with their session token
- Server re-hydrates state from Redis and sends `game:state_updated` with full current state to that socket only
- Other players get `player:reconnected` notification

---

## 11. Security & Validation

- All game rule validation **must** happen server-side (GameEngineService)
- Client sends *intent* only; never trusts client-computed state
- Session tokens are short-lived JWTs or UUID-based opaque tokens stored in Redis
- Rate limiting on socket events to prevent spam/flooding
- Room codes are 4-char alphanumeric, randomly generated, expire when match ends
- Input sanitized via `class-validator` DTOs on all REST and socket payloads

---

## 12. Scalability Considerations

For v1.0 (single instance), in-memory + Redis state is sufficient.

For horizontal scaling:
- Redis pub/sub enables multi-instance Socket.IO via `socket.io-redis` adapter
- Game state lives in Redis (shared across instances)
- Postgres handles durable persistence
- Stateless game engine can run on any instance

Load estimates (v1.0 target):
- ~50 concurrent rooms (200–400 concurrent players)
- Single Node.js instance + Redis handles this comfortably

---

## Appendix A: Game Reset Decision Tree

```
Player wants to play cards on current pile:

Is pile empty?
  YES → Play any valid set (any rank, any set size) → Round starts
  NO  →
    Are cards all rank '2'?
      YES → Does set size meet reset requirements for current pile?
              pile is single or double → need 1× '2' (single 2)
              pile is triple           → need 2× '2' (double 2)
              pile is quad             → need 3× '2' (triple 2)
            YES → RESET: pile clears, player continues
            NO  → INVALID play
      NO  →
        Does set size match pile set size?
          NO  → INVALID play
          YES →
            Is rank >= pile rank?
              NO  → INVALID play
              YES →
                Is rank == pile rank?
                  YES → Play valid, SKIP next player
                  NO  → Play valid, no skip
```

---

## Appendix B: Card Exchange Algorithm

```typescript
function performExchange(rankedPlayers: Player[]): ExchangeAction[] {
  const n = rankedPlayers.length;
  const actions: ExchangeAction[] = [];

  if (n < 3) return actions; // no exchange below minimum

  // Sort hand by exchange value: 3(worst) → 2(best)
  const exchangeRank = ['3','4','5','6','7','8','9','10','J','Q','K','A','2'];
  const byValue = (a: Card, b: Card) =>
    exchangeRank.indexOf(a.rank) - exchangeRank.indexOf(b.rank);

  const first = rankedPlayers[0];
  const last = rankedPlayers[n - 1];

  // 1st gives 2 worst to last; last gives 2 best to 1st
  const firstGives = [...first.hand].sort(byValue).slice(0, 2);
  const lastGives = [...last.hand].sort(byValue).reverse().slice(0, 2);
  actions.push({ from: first.id, to: last.id, cards: firstGives });
  actions.push({ from: last.id, to: first.id, cards: lastGives });

  // 2nd gives 1 worst to 2nd-last; 2nd-last gives 1 best to 2nd
  if (n >= 4) {
    const secondGives = [...second.hand].sort(byValue).slice(0, 1);
    const secondLastGives = [...secondLast.hand].sort(byValue).reverse().slice(0, 1);
    actions.push({ from: second.id, to: secondLast.id, cards: secondGives });
    actions.push({ from: secondLast.id, to: second.id, cards: secondLastGives });
  }

  return actions;
}
```
