> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary backend detail.
> **Replaced by:** [EP-002 — Authentication & Session Management](../epics/EP-002-auth-session-management.md) · [tickets.json](../tickets.json) → T-014–T-017

---

# BE-EP-002 — Authentication & Session Management

| Field | Value |
|---|---|
| **ID** | BE-EP-002 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | BE-EP-001 |
| **Blocks** | BE-EP-003, BE-EP-005 |
| **Estimated Effort** | M (3–4 days) |

---

## Description

This epic delivers the authentication and session layer for Shah Exchange. Because the game does not require full user accounts with passwords at launch, authentication is **anonymous/session-based**: a player provides a display name, receives a session token, and uses that token to authenticate all subsequent HTTP and WebSocket interactions.

The session system must be robust enough to survive WebSocket disconnects and allow players to rejoin active games using their token.

---

## Background & Motivation

Without a session layer, we cannot:
- Know who is making a WebSocket connection
- Prevent impersonation (player A pretending to be player B)
- Reconnect a player to an in-progress game after a disconnect
- Associate actions (plays, passes) to a specific player

The design deliberately avoids OAuth/passwords for v1.0 to reduce complexity while still providing secure, non-forgeable session tokens.

---

## Goals

- Allow any user to create an anonymous session with a display name
- Issue a secure, non-guessable session token (UUID v4 or signed JWT)
- Store session data in Redis with a TTL
- Provide a session guard/middleware that validates tokens on all protected routes and WebSocket events
- Support session refresh / extension when a player is active
- Support reconnection: re-issuing a token or restoring state from existing token
- Persist player records to Postgres (for history linkage)

---

## Detailed Scope

### 1. Player Entity
Define `Player` entity/model in Postgres:
```
id: UUID (PK)
display_name: VARCHAR(32)
created_at: TIMESTAMPTZ
```
Validate `display_name`: 2–32 chars, alphanumeric + spaces, strip leading/trailing whitespace.

### 2. Session Token Strategy
Two approaches (pick during grooming):

**Option A — Opaque UUID Token (Recommended for simplicity)**
- On `POST /auth/session`, create a `Player` record, generate UUID token
- Store in Redis: `session:{token}` → `{ playerId, displayName, matchId? }` with TTL of 24h
- Each request validates by looking up token in Redis
- Lightweight, no JWT library needed, works perfectly for this use case

**Option B — JWT (if future-proofing needed)**
- HS256 JWT with `{ sub: playerId, name: displayName }`
- Short expiry (4h) + refresh token in Redis
- More complexity, more appropriate if future features need stateless validation

Recommendation: **Option A** for v1.0.

### 3. REST Endpoints

**`POST /auth/session`**
- Request body: `{ displayName: string }`
- Creates a Player record in Postgres
- Creates Redis session entry
- Response: `{ token: string, player: { id, displayName } }`
- No authentication required (public endpoint)

**`GET /auth/me`**
- Protected (requires valid token via `Authorization: Bearer <token>` header)
- Returns current player info + active match (if any)

**`DELETE /auth/session`**
- Invalidates the session token (logout)

### 4. Session Guard
Create `SessionGuard` (NestJS `CanActivate`):
- Reads `Authorization: Bearer <token>` header
- Looks up token in Redis
- If valid: attaches `player` object to `request.user`
- If invalid/expired: throws `401 UnauthorizedException`

Apply guard globally (with public endpoint exceptions via `@Public()` decorator).

### 5. WebSocket Authentication
When a Socket.IO client connects, they must pass their token:
- Via handshake auth: `socket = io(url, { auth: { token } })`
- The WebSocket Gateway (BE-EP-005) will validate the token on the `handleConnection` hook using the same Redis lookup
- Invalid token → disconnect immediately

### 6. Session Hydration on Reconnect
When a player reconnects (lost connection, refreshed browser):
- They still have their token (stored in localStorage on client)
- `POST /auth/session` with an existing token header returns existing session (idempotent)
- Or a dedicated `POST /auth/reconnect` endpoint that re-validates and returns current match state

### 7. Session Extension
- Every time a player performs an action, extend their Redis session TTL (sliding window)
- Prevents losing a session mid-game if a match goes long

---

## Acceptance Criteria

- [ ] `POST /auth/session` with valid display name returns a token and player object
- [ ] `POST /auth/session` with invalid display name (too short, bad chars) returns `400`
- [ ] Player record is persisted in Postgres on session creation
- [ ] Token is stored in Redis with correct TTL
- [ ] `GET /auth/me` with valid token returns player info
- [ ] `GET /auth/me` with invalid/expired token returns `401`
- [ ] `SessionGuard` blocks unauthenticated requests to all protected routes
- [ ] `@Public()` decorator bypasses the guard correctly
- [ ] WebSocket connection with invalid token is immediately rejected
- [ ] Session TTL extends on each authenticated action
- [ ] Unit tests cover: session creation, token validation, guard logic, edge cases

---

## Out of Scope

- OAuth / social login
- Email / password accounts
- Role-based access control (admin vs player)
- Password reset flow

---

## Technical Notes

- Display name uniqueness is NOT enforced — players can share names (they are differentiated by ID)
- Token must be included in all subsequent API calls and socket connections
- Consider rate-limiting `POST /auth/session` (5 calls per IP per minute) to prevent abuse
