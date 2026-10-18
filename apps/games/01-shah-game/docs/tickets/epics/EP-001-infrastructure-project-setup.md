# EP-001 — Infrastructure & Project Setup

| Field | Value |
|---|---|
| **ID** | EP-001 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | None |
| **Blocks** | All other epics |
| **Tickets** | T-001 – T-013 |
| **Estimated Effort** | M (4–6 days across BE + FE) |

---

## Description

Establishes the complete development foundation for both the NestJS backend and Vite/React frontend. Neither feature epic should begin until this epic is fully closed. Covers project structure, tooling, database connectivity, Redis, CI pipeline, design system setup, and base UI primitives.

---

## Background & Motivation

The NestJS and Vite projects are CLI-scaffolded but otherwise empty. Before any feature work:
- The backend needs a working module tree, database, Redis, and CI
- The frontend needs a consistent folder structure, design system, and test runner
- Both need linting, formatting, and pre-commit enforcement

Skipping this groundwork results in structural divergence across feature branches and painful rework.

---

## Goals

### Backend
- Establish the NestJS module shell structure (all modules empty but wired)
- Set up Docker Compose with Postgres 16 and Redis 7
- Configure Prisma with initial schema migration (all tables from `SYSTEM_DESIGN.md §7`)
- Build a Redis injectable module (`ioredis`)
- Publish a `GET /health` endpoint that reports Postgres + Redis status
- Configure ESLint, Prettier, and Husky pre-commit hooks
- Bootstrap a GitHub Actions CI pipeline

### Frontend
- Establish the `src/` folder structure with path aliases (`@/*`)
- Configure Tailwind CSS v4 with design tokens (card table green, suit colours, highlights)
- Integrate shadcn/ui core primitives (Button, Badge, Card, Dialog, Toast, Tooltip, Skeleton, Separator)
- Build the `PlayingCard` UI primitive component (reused everywhere in the game)
- Set up Vitest + React Testing Library with jsdom
- Configure environment variables and the `api.ts` service wrapper with auth interceptors

---

## Detailed Scope

### Backend (T-001 – T-007)

#### Module Shell Structure (T-001)
Create the following empty NestJS module shells under `src/`:
- `auth/` — `AuthModule`, `AuthService`, `AuthController`
- `player/` — `PlayerModule`, `PlayerService`
- `match/` — `MatchModule`, `MatchService`, `MatchController`
- `game/` — `GameModule`, `GameService`
- `game-engine/` — `GameEngineModule`, `GameEngineService`
- `gateway/` — `GatewayModule`, `GameGateway`

Each module must be registered in `AppModule`. No logic — just structure and DI wiring.

#### Docker Compose (T-002)
`docker-compose.yml` at the backend root with:
- `postgres:16` on port 5432 with named volume
- `redis:7` on port 6379 with named volume
- All credentials via `.env` (not hardcoded)
- `.env.example` with `DATABASE_URL`, `REDIS_URL`, `PORT`, `NODE_ENV`, `SESSION_SECRET`

#### Prisma Setup (T-003)
Install Prisma and configure `PrismaService` as a global NestJS provider. Schema must include all models from the system design:

```prisma
model Player { ... }          // id, display_name, created_at
model Match { ... }           // id, room_code, host_id, status, player_count, started_at, ended_at
model MatchPlayer { ... }     // matchId + playerId (composite PK), seat_index, joined_at
model Game { ... }            // id, match_id, game_number, direction, status, started_at, ended_at
model GameRanking { ... }     // game_id + player_id (composite PK), rank
model GameEvent { ... }       // id (BigInt), game_id, round_number, event_type, player_id, payload (Json), created_at
```

Run initial migration. `synchronize: false` always — migrations only.

#### Redis Module (T-004)
Create `RedisModule` using `ioredis`, reading `REDIS_URL` from config. Expose `REDIS_CLIENT` injection token. Startup connectivity check logs success/warning. Register globally.

#### Health Check (T-005)
`GET /health` using `@nestjs/terminus`: checks HTTP, Postgres (`$queryRaw`), Redis (PING). Returns 200 when all healthy; 503 when any service is down. No auth required.

#### Linting & Husky (T-006)
Extend `eslint.config.mjs` with `@typescript-eslint` rules: `no-explicit-any`, `no-unused-vars`, `explicit-function-return-type`. Add `lint-staged` + Husky pre-commit hook: lint + format all staged `.ts` files.

#### CI Pipeline (T-007)
`.github/workflows/backend-ci.yml` running on PRs to `main`:
1. `pnpm install`
2. `pnpm lint`
3. `pnpm test` (unit + integration)
4. `pnpm build`

Uses `postgres:16` and `redis:7` GitHub Actions service containers.

---

### Frontend (T-008 – T-013)

#### Folder Structure & Aliases (T-008)
Set up `src/` tree:
```
src/
├── assets/
├── components/
│   └── ui/          # shadcn primitives + PlayingCard
├── features/        # feature-specific components (game/, lobby/, auth/)
├── hooks/           # shared hooks
├── lib/             # config, utils
├── pages/           # route-level page components
├── router/          # router config + ProtectedRoute
├── services/        # api.ts, socket.ts, gameActions.ts
├── store/           # Zustand stores
├── test/            # Vitest setup
└── types/           # TypeScript types (mirrored from backend)
```

Configure `@/*` alias in `vite.config.ts` and `tsconfig.app.json`.

#### Tailwind CSS v4 (T-009)
Install `tailwindcss` + `@tailwindcss/vite`. Define CSS custom properties in `src/index.css`:

```css
:root {
  --color-table: #1a5c2a;
  --color-card-bg: #ffffff;
  --color-active-player: #f59e0b;
  --color-suit-red: #dc2626;
  --color-suit-black: #111827;
}
```

Map properties to Tailwind theme via `@theme`.

#### shadcn/ui Core Primitives (T-010)
Initialise via CLI. Install: `button`, `badge`, `card`, `dialog`, `toast`, `tooltip`, `skeleton`, `separator`. Mount `<Toaster />` in `App.tsx`.

> **Tooling note:** The **shadcn MCP tool** is available in this VS Code workspace. Use it to fetch component source, browse usage examples, and generate the correct `pnpm dlx shadcn@latest add <component>` command instead of copying from external docs.

#### PlayingCard Component (T-011)
`src/components/ui/PlayingCard.tsx` — the single card atom used across the entire game board.

Props:
```typescript
interface PlayingCardProps {
  rank: Rank;
  suit: Suit;
  faceDown?: boolean;      // default false
  selected?: boolean;      // elevated, accent border
  disabled?: boolean;      // reduced opacity, no onClick
  size?: 'sm' | 'md' | 'lg';
  onClick?: () => void;
}
```

Behaviour:
- Face-up: shows rank + suit symbol, red for hearts/diamonds, black for clubs/spades
- Face-down: card back pattern, no rank/suit visible
- `selected`: raised shadow + gold border
- `aria-label`: `"{rank} of {suit}"` for accessibility

#### Vitest Setup (T-012)
Install `vitest`, `@testing-library/react`, `@testing-library/user-event`, `@testing-library/jest-dom`, `jsdom`. Configure `vite.config.ts` test options with `jsdom` environment and `setup.ts` file that imports jest-dom matchers.

#### Environment Config & API Service (T-013)
`.env.example` with `VITE_API_URL`, `VITE_SOCKET_URL`. Create:
- `src/lib/config.ts`: reads and validates env vars (fails fast with a descriptive error if missing)
- `src/services/api.ts`: fetch/axios wrapper that injects `Authorization: Bearer <token>` from `sessionStore` on every request; handles 401 by clearing session and navigating to `/`

---

## Acceptance Criteria

### Backend
- [ ] All 6 NestJS modules exist and are registered in `AppModule`; `pnpm start:dev` boots cleanly
- [ ] `docker-compose up -d` starts Postgres + Redis; both are reachable on their default ports
- [ ] `pnpm prisma migrate dev` creates all 6 tables; schema matches `SYSTEM_DESIGN.md §7`
- [ ] `GET /health` returns 200 with `{ status: 'ok' }` when all services are up; 503 when any are down
- [ ] `git commit` with a lint error is rejected by the pre-commit hook
- [ ] CI pipeline runs and passes on a clean PR

### Frontend
- [ ] `import '@/store/sessionStore'` resolves correctly in IDE and at runtime
- [ ] `pnpm dev` starts without errors; Tailwind class `bg-[--color-table]` renders the correct green
- [ ] All 8 shadcn primitives are importable; `<Toaster />` is mounted
- [ ] `<PlayingCard rank="A" suit="hearts" />` renders a red Ace; face-down renders no rank
- [ ] `pnpm test` finds and passes the smoke test
- [ ] `api.ts` attaches the Bearer token and clears session on 401

---

## Dependencies

- None upstream
- Blocks: EP-002, EP-003, EP-004, EP-005, EP-006, EP-007, EP-008

---

## Reference
- `SYSTEM_DESIGN.md §4` (tech stack), `§7` (DB schema), `§8.1` (module structure), `§9.2` (component tree)
- [`tickets.json`](../tickets.json) → `EP-001`, tickets T-001 – T-013
