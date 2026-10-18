# EP-002 — Authentication & Session Management

| Field | Value |
|---|---|
| **ID** | EP-002 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | EP-001 |
| **Blocks** | EP-003, EP-005 |
| **Tickets** | T-014 – T-020 |
| **Estimated Effort** | S (3–4 days across BE + FE) |

---

## Description

Implements anonymous session-based authentication. Players enter a display name, receive an opaque token, and are identified by that token across all HTTP and WebSocket interactions. Sessions must survive page refresh without requiring the player to re-enter their name.

No passwords, no OAuth, no email — this is intentionally lightweight. The focus is on a frictionless entry experience while providing enough identity to run a multi-player session.

---

## Background & Motivation

All subsequent features depend on knowing who a player is. The WebSocket gateway needs to know the `playerId` before accepting any game events. The lobby needs to know who the host is. The game board needs to know which hand belongs to the local player.

The anonymous session model is appropriate for v1.0 because:
- There is no signup friction (critical for a party game)
- Session tokens are stored in Redis with TTL — no server-side session DB needed
- A display name is enough identity for a single-match context

---

## Goals

### Backend
- Create the `players` table and `PlayerService` (create + findById)
- Implement `POST /auth/session` — takes display name, returns opaque token + player record
- Store session in Redis with 24h sliding TTL
- Build `SessionGuard` (global) and `@Public()` decorator
- Implement `GET /auth/me` with session refresh; `DELETE /auth/session` (logout)

### Frontend
- Build the landing page (full-screen, display name form, keyboard-accessible)
- Implement `sessionStore` (Zustand) with `login()`, `restoreSession()`, `logout()`
- Persist token to `localStorage`; restore and re-validate on page load
- Build `ProtectedRoute` + redirect logic; wire `restoreSession()` on app mount

---

## Detailed Scope

### Backend (T-014 – T-017)

#### Player Entity (T-014)
Add `Player` model to Prisma schema and run migration:
```prisma
model Player {
  id           String    @id @default(uuid())
  display_name String    @db.VarChar(32)
  created_at   DateTime  @default(now())
}
```

`PlayerService` methods:
- `createPlayer(displayName: string): Promise<Player>` — validates, inserts
- `findById(id: string): Promise<Player | null>` — null-safe, does not throw

#### POST /auth/session (T-015)
```
POST /auth/session
Body: { displayName: string }   // min 2, max 32 chars, trimmed
Response 201: { token: string, player: { id, displayName } }
```

Behaviour:
1. Validate DTO with `class-validator`
2. Call `PlayerService.createPlayer()`
3. Generate `uuidv4()` token
4. Store in Redis: key `session:{token}`, value `{ playerId, displayName }`, TTL 86400s
5. Return token + player object

#### SessionGuard + @Public() (T-016)
`SessionGuard` (`CanActivate`):
- Reads `Authorization: Bearer <token>` header
- Looks up `session:{token}` in Redis
- If found: attaches `{ id, displayName }` to `request.user`; lets through
- If not found or expired: throws `UnauthorizedException`

Apply as a global guard in `main.ts` via `APP_GUARD`. Apply `@Public()` decorator to `POST /auth/session` and `GET /health`.

#### GET /auth/me + Sliding TTL (T-017)
```
GET /auth/me
Response 200: { player: { id, displayName }, matchId: string | null }
```

Middleware/interceptor: on every authenticated request, call `Redis.EXPIRE session:{token} 86400` to reset the TTL (sliding window).

```
DELETE /auth/session
Response 204
```
Deletes the session key from Redis. Subsequent requests with the same token return 401.

---

### Frontend (T-018 – T-020)

#### Landing Page (T-018)
`src/pages/LandingPage.tsx` — the application entry point for unauthenticated players.

Layout:
- Full viewport, dark green table background (`--color-table`)
- Game title "Shah Exchange" (large, centred)
- Display name input (auto-focused, min 2 / max 32 / trimmed)
- "Enter Game" button
- Inline error message if name < 2 chars (client-side, no API call)
- Spinner + disabled state on submit
- Enter key triggers submit

On success: navigate to `/lobby`.

> Authenticated players visiting `/` are redirected to `/lobby`.

#### sessionStore (T-019)
`src/store/sessionStore.ts` — Zustand store with persistence.

State shape:
```typescript
interface SessionState {
  token: string | null;
  player: { id: string; displayName: string } | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}
```

Actions:
- `login(displayName)` — calls `POST /auth/session`, stores token + player in state and `localStorage` (`shah_session_token`, `shah_player`)
- `restoreSession()` — reads localStorage, calls `GET /auth/me`; if 401, clears storage silently
- `logout()` — calls `DELETE /auth/session`, clears state + localStorage

#### ProtectedRoute + App Bootstrap (T-020)
`src/router/ProtectedRoute.tsx`:
- If `isLoading`: show `<LoadingSpinner />`
- If `!isAuthenticated`: `<Navigate to="/" replace />`
- Otherwise: render `<Outlet />`

Router (`src/router/index.tsx`) with all routes:
```
/                      →  LandingPage       (public)
/lobby                 →  LobbyPage         (protected)
/room/:code            →  WaitingRoomPage   (protected)
/game/:matchId         →  GamePage          (protected)
/results/:matchId      →  ResultsPage       (protected)
/history               →  HistoryPage       (protected)
```

`App.tsx`:
```tsx
useEffect(() => {
  sessionStore.restoreSession();
}, []);
```

---

## Acceptance Criteria

### Backend
- [ ] `POST /auth/session` with a valid name returns 201 with token and player object
- [ ] `POST /auth/session` with name < 2 or > 32 chars returns 400 with a validation message
- [ ] Any protected endpoint returns 401 with no token; 401 with an expired/unknown token
- [ ] `request.user` is populated correctly after a valid token is presented
- [ ] `GET /auth/me` returns player info and refreshes the Redis TTL
- [ ] `DELETE /auth/session` invalidates the token immediately
- [ ] Integration tests cover: happy path, validation failures, expired token, logout

### Frontend
- [ ] Landing page auto-focuses the input and submits on Enter key
- [ ] Name shorter than 2 chars shows an inline error without hitting the API
- [ ] Refresh on `/lobby` restores session and stays on `/lobby`
- [ ] Refresh with an expired token redirects to `/`
- [ ] Authenticated user visiting `/` is redirected to `/lobby`
- [ ] `sessionStore` unit tests cover all 4 actions

---

## Dependencies

- Requires: EP-001 (T-001–T-013)
- Blocks: EP-003 (T-021+), EP-005 (T-042 WebSocket auth)

---

## Reference
- `SYSTEM_DESIGN.md §8.2` (REST endpoints), `§11` (security)
- `GAME_RULES.md` — no direct rule dependency; supports game identity model
- [`tickets.json`](../tickets.json) → `EP-002`, tickets T-014 – T-020
