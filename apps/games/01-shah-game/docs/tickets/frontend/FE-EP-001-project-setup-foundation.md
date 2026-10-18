> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-001 — Infrastructure & Project Setup](../epics/EP-001-infrastructure-project-setup.md) · [tickets.json](../tickets.json) → T-008–T-013

---

# FE-EP-001 — Project Setup & UI Foundation

| Field | Value |
|---|---|
| **ID** | FE-EP-001 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | None |
| **Blocks** | All other frontend epics |
| **Estimated Effort** | M (3–5 days) |

---

## Description

This epic establishes the complete frontend foundation for Shah Exchange: the tooling, folder structure, design system, routing skeleton, and state management scaffolding. The Vite + React project has been initialized but has no additional configuration, libraries, or structure applied.

Before any feature work begins, this epic ensures every developer starts from a consistent, well-configured baseline with a working design system, global styles, and an extensible architecture.

---

## Background & Motivation

A strong frontend foundation prevents accumulating technical debt:
- Without a design system, UI becomes inconsistent and hard to change
- Without global state scaffolding, feature branches create conflicting state approaches
- Without a routing skeleton, screens are harder to link together later
- Without ESLint/Prettier/Husky, code quality degrades quickly across contributors

---

## Goals

- Install and configure all runtime and dev dependencies
- Set up Tailwind CSS + global design tokens (colors, typography, spacing)
- Integrate shadcn/ui component library (select core primitives)
- Set up Zustand for global state management
- Set up React Router v6 with route skeleton
- Configure ESLint + Prettier + Husky pre-commit hooks
- Set up Vitest + React Testing Library
- Establish folder structure and import path aliases
- Create reusable base UI components (Button, Card UI shell, Badge, Modal, Toast)
- Configure environment variables (Vite `import.meta.env`)

---

## Detailed Scope

### 1. Dependencies to Install

**Runtime:**
```
react-router-dom
zustand
socket.io-client
tailwindcss
@tailwindcss/vite
framer-motion
clsx
tailwind-merge
lucide-react
```

**shadcn/ui (via CLI):**
```
button, card, badge, dialog, toast, tooltip, separator, skeleton
```

**Dev:**
```
vitest
@testing-library/react
@testing-library/user-event
@testing-library/jest-dom
jsdom
eslint (extend existing config)
prettier
husky
lint-staged
```

### 2. Tailwind CSS Configuration
- Configure `tailwind.config.ts` with custom design tokens:
  - **Colors:** dark background (slate/zinc family), card-face green table color, suit colors (red hearts/diamonds, black clubs/spades), accent gold/amber for rankings
  - **Typography:** Use Inter (or system font stack)
  - **Custom CSS variables** for theming: `--color-table`, `--color-card-bg`, `--color-active-player`
- Add `tailwindcss` plugin to `vite.config.ts`
- Set up `src/index.css` with base styles and CSS variable definitions

### 3. Folder Structure

```
src/
├── assets/             # Static images, SVGs (card backs, etc.)
├── components/
│   ├── ui/             # shadcn/ui primitives + custom base components
│   ├── layout/         # AppShell, PageContainer, etc.
│   └── game/           # Game-specific components (added in later epics)
├── features/
│   ├── auth/           # Session creation, display name input
│   ├── lobby/          # Room creation, join, waiting room
│   ├── game/           # Game board and all game UI
│   └── history/        # Match history view
├── hooks/              # Custom React hooks (useGame, useSocket, etc.)
├── lib/                # Utility functions, constants, helpers
├── pages/              # Route-level page components
├── store/              # Zustand stores
│   ├── matchStore.ts
│   ├── gameStore.ts
│   └── sessionStore.ts
├── types/              # TypeScript types (mirroring backend shared types)
├── services/           # API client, socket client
│   ├── api.ts          # Axios/fetch wrapper with auth headers
│   └── socket.ts       # Socket.IO client singleton
└── router/
    └── index.tsx       # Route definitions
```

### 4. Import Aliases
Configure `vite.config.ts` and `tsconfig.json` with aliases:
```typescript
'@/*' → './src/*'
'@components/*' → './src/components/*'
'@store/*' → './src/store/*'
'@types/*' → './src/types/*'
```

### 5. Router Skeleton
Set up routes in `src/router/index.tsx`:
```
/                    → <LandingPage>       (name entry)
/lobby               → <LobbyPage>         (create or join)
/room/:code          → <WaitingRoomPage>   (pre-game lobby)
/game/:matchId       → <GamePage>          (active game)
/results/:matchId    → <ResultsPage>       (end of match)
```
Each page is a placeholder component that renders its route name — actual content added in subsequent epics.

### 6. Base UI Components to Build

**`<Button>`** — Wraps shadcn Button with variant system: `primary`, `secondary`, `danger`, `ghost`

**`<Card>`** — The playing card component (critical, used everywhere):
- Props: `rank`, `suit`, `faceDown?`, `selected?`, `disabled?`, `size?: 'sm' | 'md' | 'lg'`
- Render face-up cards with rank + suit icon, correct color
- Render face-down cards with card back design
- Selection state: lifted/highlighted border
- Accessibility: aria-label with "rank of suit"

**`<PlayerAvatar>`** — Circular avatar with display name initial, colored by player slot

**`<Badge>`** — Rank badge (1st, 2nd, etc.) with color coding

**`<Toast>`** — Notification system (error toasts for invalid plays, info for game events) — wire up shadcn Toaster

**`<Modal / Dialog>`** — Generic overlay wrapper (used in exchange UI, confirm dialogs)

**`<LoadingSpinner>`** — Animated loading indicator

**`<PageContainer>`** — Centered, max-width layout wrapper

### 7. Environment Variables

`.env.example`:
```
VITE_API_URL=http://localhost:3000
VITE_SOCKET_URL=http://localhost:3000
```

Create `src/lib/config.ts` that reads and validates these at startup:
```typescript
export const config = {
  apiUrl: import.meta.env.VITE_API_URL ?? 'http://localhost:3000',
  socketUrl: import.meta.env.VITE_SOCKET_URL ?? 'http://localhost:3000',
};
```

### 8. API Service Base

```typescript
// src/services/api.ts
const api = axios.create({ baseURL: config.apiUrl });

// Attach session token to all requests
api.interceptors.request.use((req) => {
  const token = sessionStore.getToken();
  if (token) req.headers.Authorization = `Bearer ${token}`;
  return req;
});
```

### 9. TypeScript Types Mirror

Copy/adapt shared types from the backend into `src/types/`:
- `card.types.ts` — `Card`, `Rank`, `Suit`
- `game-state.types.ts` — `GameState`, `Player`, `Pile`, `RoundState`, etc.
- `events.types.ts` — WebSocket event names and payload shapes

Keep in sync manually (or via a shared package in a future monorepo refactor).

---

## Acceptance Criteria

- [ ] `pnpm install` succeeds; `pnpm dev` starts dev server at `localhost:5173`
- [ ] Tailwind CSS applies correctly (test with a colored div)
- [ ] All 5 routes render their placeholder pages without errors
- [ ] `<Card>` component renders face-up and face-down variants with correct styling
- [ ] Zustand store scaffolds exist and are importable
- [ ] `pnpm lint` passes with zero errors
- [ ] `pnpm test` runs Vitest and passes (empty test suite is acceptable)
- [ ] Import aliases (`@/*`) resolve correctly in IDE and at build time
- [ ] `.env.example` is committed; `.env` is gitignored
- [ ] shadcn/ui Toaster is wired into the app root

---

## Out of Scope

- Actual API calls to the backend (stubbed/mocked)
- Socket connections (set up in FE-EP-005)
- Any game logic implementation

---

## Technical Notes

- Use Tailwind CSS v4 (latest) with the `@tailwindcss/vite` plugin rather than the PostCSS approach
- The `<Card>` component is the most important UI primitive — invest time in making it pixel-perfect and accessible early
- shadcn/ui components should be added via the CLI (`pnpm dlx shadcn@latest add button`) — do not copy-paste manually
- TypeScript strict mode must be enabled (`"strict": true`)
