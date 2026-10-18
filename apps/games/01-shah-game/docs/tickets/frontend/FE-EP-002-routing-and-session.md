> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-002 — Authentication & Session Management](../epics/EP-002-auth-session-management.md) · [tickets.json](../tickets.json) → T-018–T-020

---

# FE-EP-002 — Routing, Landing & Session

| Field | Value |
|---|---|
| **ID** | FE-EP-002 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | FE-EP-001 |
| **Blocks** | FE-EP-003, FE-EP-004 |
| **Estimated Effort** | S (2–3 days) |

---

## Description

This epic implements the player's first interaction with the application: entering a display name to create an anonymous session, persisting the session token, and routing the user appropriately based on auth state. It also covers route guards (redirect unauthenticated users to landing) and session restoration on page refresh.

---

## Background & Motivation

Every flow in the application depends on a session token. Before a player can create or join a room, they need to have identified themselves with a display name and received a token from the backend. This epic ensures:
- First-time users are routed to the landing page to enter their name
- Returning users (page refresh) are restored from `localStorage` without re-entering their name
- All protected routes redirect to `'/'` if no valid session exists
- The session context is available globally via a Zustand store

---

## Goals

- Landing page with display name input form
- Call `POST /auth/session` on form submit; store token in `localStorage`
- Session store in Zustand with `token`, `player` object, and auth status
- Session restoration on app load (`useEffect` that checks `localStorage`)
- Protected route wrapper that redirects to `/` when unauthenticated
- Clear session (logout) utility
- Handle API errors (name too short, network failure) with user-facing feedback

---

## Detailed Scope

### 1. Landing Page (`/`)

**Layout:**
- Centered card on a styled background (game table green)
- Game title "Shah Exchange" with subtitle
- Display name input field (2–32 chars, enforced client-side)
- "Enter Game" submit button
- Loading state while API call is in flight

**Form Behavior:**
- Disable submit while loading
- Show inline validation error for name too short (< 2 chars)
- Show toast error on API failures (e.g., network error, 400 from server)
- On success: store token + player in Zustand + localStorage, redirect to `/lobby`

**UX Details:**
- Auto-focus the input on mount
- Support Enter key to submit
- Name input: trim whitespace, enforce max 32 chars

### 2. Session Store (`src/store/sessionStore.ts`)

```typescript
interface SessionState {
  token: string | null;
  player: { id: string; displayName: string } | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  // Actions
  login: (displayName: string) => Promise<void>;
  restoreSession: () => Promise<void>;
  logout: () => void;
}
```

- `login()` calls `POST /auth/session`, stores result, sets `isAuthenticated: true`
- `restoreSession()` reads token from `localStorage`, calls `GET /auth/me` to validate; on 401 → clears storage
- `logout()` clears Zustand state and `localStorage`

### 3. Session Persistence

Use `localStorage` keys:
- `shah_session_token` → the opaque token string
- `shah_player` → JSON-serialized `{ id, displayName }`

On app init (in `App.tsx` or a `SessionProvider`), call `sessionStore.restoreSession()`.  
Show a loading spinner while restoration is in flight.

### 4. Protected Route Component

```typescript
// src/router/ProtectedRoute.tsx
export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useSessionStore();

  if (isLoading) return <LoadingSpinner />;
  if (!isAuthenticated) return <Navigate to="/" replace />;
  return <>{children}</>;
}
```

Wrap all routes except `/` with `<ProtectedRoute>` in `src/router/index.tsx`.

### 5. Active Session Redirect

If an authenticated user navigates to `/`, redirect them to `/lobby` automatically (they don't need to re-enter their name).

### 6. "Change Name" Flow

Allow players to change their display name from the lobby:
- Small "edit" link next to their name in the header
- Calls `POST /auth/session` again (creates a new session, old token invalidated)
- Updates Zustand store + localStorage

### 7. Error Handling

| Scenario | User-Facing Behavior |
|---|---|
| Name < 2 chars | Inline red error below input: "Name must be at least 2 characters" |
| Name > 32 chars | Input capped at 32 chars (maxLength) |
| API 400 (name invalid server-side) | Toast: "That name isn't valid. Please try again." |
| API network error | Toast: "Could not connect to server. Please check your connection." |
| Session restore 401 | Silently clear session, stay on landing page |
| Session restore network error | Show offline banner, allow re-entry |

---

## Acceptance Criteria

- [ ] Navigating to `/` when unauthenticated shows the landing page with name input
- [ ] Submitting a valid name calls `POST /auth/session` and redirects to `/lobby`
- [ ] Token and player info are saved to `localStorage` after login
- [ ] Refreshing the page with a valid stored token restores session (no re-login required)
- [ ] Refreshing with an expired/invalid token clears storage and shows the landing page
- [ ] All protected routes redirect to `/` when accessed without a session
- [ ] Form shows loading state during API call
- [ ] Invalid names (< 2 chars) show inline error without API call
- [ ] API errors display user-friendly toast messages
- [ ] Entering the landing page while already authenticated redirects to `/lobby`

---

## Out of Scope

- Social login accounts
- Profile editing beyond display name
- Account persistence across devices (session is per-browser)

---

## Technical Notes

- Do not store sensitive data beyond the opaque token — only `displayName` and `playerId` in localStorage
- The `restoreSession()` call should be non-blocking for the initial render; show a minimal loading state
- Consider a `useAuth()` hook that wraps the session store for cleaner component code
