# CLAUDE.md

This file provides guidance to AI agents working with code in this repository.

## Project Overview

**Shah Exchange** — a real-time multiplayer card game platform (3–8 players). The project is in its early implementation phase.

## Source of Truth Hierarchy

This order is strict. When anything conflicts, the higher item wins.

1. **`01-shah-game/docs/GAME_RULES.md`** — the constitution. Absolute source of truth for all game logic and rules. If the system design, tickets, or any implementation conflicts with GAME_RULES.md, GAME_RULES.md wins. The system exists to serve the game — adapt the architecture, not the rules.
2. **`01-shah-game/docs/SYSTEM_DESIGN.md`** — architecture reference and strong default. This is a living document; update it when architectural decisions change. It is not a constraint.
3. **`01-shah-game/docs/tickets/tickets.json`** — implementation helper providing task breakdown, acceptance criteria, and dependency order. Always check the `status` field before picking up a ticket.

## Monorepo Structure

```
verj-games/
└── 01-shah-game/
    ├── backend/          # NestJS server (TypeScript)
    ├── frontend/         # Vite + React 19 (TypeScript)
    └── docs/
        ├── GAME_RULES.md       # Absolute source of truth — do not contradict
        ├── SYSTEM_DESIGN.md    # Architecture guide (living document)
        ├── changelog/          # Per-session change summaries (see Changelog Policy)
        └── tickets/            # Implementation tickets and epics
```

## Commands

All commands use **pnpm** (v10.30.1). Run from the respective subdirectory.

### Backend (`01-shah-game/backend`)
```bash
pnpm start:dev      # Development with hot reload (port 3000)
pnpm build          # Compile TypeScript
pnpm test           # Jest unit tests
pnpm test:watch     # Jest watch mode
pnpm test:cov       # Coverage report
pnpm test:e2e       # Integration tests (uses real test DB — never mocked)
pnpm lint           # ESLint with auto-fix
pnpm format         # Prettier format
```

### Frontend (`01-shah-game/frontend`)
```bash
pnpm dev            # Vite dev server (port 5173)
pnpm build          # TypeScript check + Vite build
pnpm lint           # ESLint check
pnpm preview        # Preview production build
```

## Architecture

### Backend
NestJS application with 6 modules: `AuthModule`, `PlayerModule`, `MatchModule`, `GameModule`, `GameEngineModule`, `GatewayModule`. Key infrastructure:
- **PostgreSQL 16** (via Docker) with Prisma ORM
- **Redis 7** (via Docker) for pub/sub and caching
- **Socket.IO** gateway for real-time game events

State machine: **Match → Game → Round**. Domain model: `Card`, `Play`, `Pile`, `Player`, `Round`, `Game`, `Match`.

### Frontend
React 19 + Vite with **React Compiler** enabled (babel plugin in `vite.config.ts`). Stack: React Router v6, Zustand, Socket.IO client, Tailwind CSS v4, shadcn/ui, Framer Motion.

### WebSocket Protocol
24 total events documented in `docs/SYSTEM_DESIGN.md` — 13 client→server, 11 server→client. Read that file before implementing any real-time features.

## Tooling

### shadcn/ui (Frontend)
`.mcp.json` at the workspace root configures the shadcn MCP server (`npx shadcn@latest mcp`). For **any frontend work involving shadcn/ui components**:
- Use the MCP tool to browse components, fetch source and usage examples, and get the correct CLI add command
- **Prefer MCP over external docs** — it reflects the exact registry version configured for this project

### Playwright (End-to-End & Multiplayer Testing)
Playwright is the E2E testing tool for this project. It lives at `01-shah-game/e2e/` and is the **only way to verify real-time multiplayer behaviour** — unit and integration tests cannot cover multi-player WebSocket synchronisation.

#### Setup
```bash
cd 01-shah-game/e2e
pnpm install
pnpm exec playwright install chromium   # install browser binary
```

#### Commands (`01-shah-game/e2e`)
```bash
pnpm test                  # run all E2E tests (headless)
pnpm test:headed           # run with visible browser windows — use to debug
pnpm test:ui               # Playwright UI mode — interactive test explorer
pnpm test:debug            # pause on each step with inspector
pnpm test -- --grep @smoke # run only smoke-tagged tests
```

#### Prerequisites before running tests
Both servers must be running. Start them in background terminals:
```bash
# Terminal 1 — backend
cd 01-shah-game/backend && pnpm start:dev

# Terminal 2 — frontend
cd 01-shah-game/frontend && pnpm dev
```
Tests target `http://localhost:5173` (frontend) and `http://localhost:3000` (backend). These are set in `e2e/playwright.config.ts` via `BASE_URL` and `API_URL` env vars — override with a `.env.test` file if ports differ.

#### Directory structure
```
01-shah-game/e2e/
├── playwright.config.ts
├── package.json
├── fixtures/
│   └── game.fixture.ts     # reusable multi-player context setup
├── helpers/
│   ├── auth.ts             # register/login helpers
│   ├── lobby.ts            # create/join room helpers
│   └── game.ts             # play card, assert hand, assert pile helpers
└── tests/
    ├── smoke/
    │   └── connection.spec.ts       # can all players connect and see the room?
    ├── lobby/
    │   └── room-management.spec.ts  # create, join, full room, start game
    ├── gameplay/
    │   ├── turn-enforcement.spec.ts # out-of-turn plays are rejected
    │   ├── card-sync.spec.ts        # card played by P1 visible to all others
    │   ├── pile-rules.spec.ts       # valid/invalid play combinations
    │   └── win-condition.spec.ts    # player empties hand → game ends
    ├── exchange/
    │   └── card-exchange.spec.ts    # post-game card swap between shah and runt
    └── match/
        └── multi-game.spec.ts       # rankings persist across games in a match
```

#### The multi-player context pattern
Every multiplayer test uses **isolated browser contexts** (not tabs — full separate sessions with distinct cookies and WebSocket connections). Use the `createPlayers` fixture from `fixtures/game.fixture.ts`:

```typescript
// fixtures/game.fixture.ts — reference implementation
import { test as base, Browser, BrowserContext, Page } from '@playwright/test';

export type Player = { context: BrowserContext; page: Page; name: string };

export const test = base.extend<{ players: Player[] }>({
  players: async ({ browser }, use) => {
    // Spin up N isolated sessions
    const players = await Promise.all(
      ['Alice', 'Bob', 'Carol', 'Dave'].map(async (name) => {
        const context = await browser.newContext();
        const page = await context.newPage();
        return { context, page, name };
      })
    );
    await use(players);
    // Teardown — close all contexts
    await Promise.all(players.map((p) => p.context.close()));
  },
});
```

Usage in a test:
```typescript
import { test } from '../fixtures/game.fixture';
import { expect } from '@playwright/test';

test('card played by one player is visible to all others', async ({ players }) => {
  const [alice, bob, carol, dave] = players;

  // All players join the same room
  await joinRoom(alice.page, 'room-001');
  await joinRoom(bob.page, 'room-001');
  await joinRoom(carol.page, 'room-001');
  await joinRoom(dave.page, 'room-001');

  // Wait for all to reach the game board
  await Promise.all(players.map((p) => p.page.waitForSelector('[data-testid="game-board"]')));

  // Alice plays a card
  await alice.page.click('[data-testid="card-3H"]');
  await alice.page.click('[data-testid="play-button"]');

  // Assert the pile updated for every other player within 2 seconds
  await Promise.all(
    [bob, carol, dave].map((p) =>
      expect(p.page.locator('[data-testid="pile-top"]')).toHaveText('3H', { timeout: 2000 })
    )
  );
});
```

#### Key rules for writing E2E tests in this project
- **Always use `data-testid` attributes** — never select by CSS class or text content, both change. Add `data-testid` to components when writing FE code.
- **Assert from the recipient's perspective** — after Player A acts, assert on Player B/C/D's UI, not A's. That's the real synchronisation proof.
- **Use `waitForSelector` / `waitFor` instead of arbitrary `sleep`** — flaky sleeps are forbidden. If an event hasn't arrived within the timeout, the test should fail, not wait longer.
- **Set explicit timeouts per assertion** — WebSocket round-trips should complete within 2000ms on localhost. Use `{ timeout: 2000 }` on real-time assertions so failures surface fast.
- **Isolate state between tests** — each test creates a fresh room with a unique ID (use `crypto.randomUUID()` in a `beforeEach`) so tests never share game state.
- **Run at least 3 players** — the game minimum is 3. Tests with fewer players do not reflect real game conditions.
- **Tag smoke tests with `@smoke`** — any test that validates basic connectivity or a happy-path flow that must pass before other tests are meaningful.

## Changelog Policy

After every session that produces a code change, architectural decision, or documentation update:
1. Create a new file in `01-shah-game/docs/changelog/` named `YYYY-MM-DD-short-description.md`
2. Include: what changed, why, and any decisions or trade-offs made
3. If `SYSTEM_DESIGN.md` was updated, note which section changed and why

## Ticket System

`01-shah-game/docs/tickets/tickets.json` tracks all work. 69 tickets across 8 epics. **Check `status` before picking up any ticket.**

| Epic | Scope |
|------|-------|
| EP-001 | Infrastructure & Project Setup (T-001–T-013) |
| EP-002 | Auth & Session Management (T-014–T-020) |
| EP-003 | Lobby & Room Management (T-021–T-027) |
| EP-004 | Core Game Engine (T-028–T-040) — **90%+ test coverage required** |
| EP-005 | Real-Time Gameplay (T-041–T-058) |
| EP-006 | Card Exchange System (T-059–T-063) |
| EP-007 | Game End, Rankings & Results (T-064–T-067) |
| EP-008 | Match History (T-068–T-069) |

## Code Standards

### TypeScript
- Strict mode — no bare `any` (inline justification comment required if truly unavoidable)
- Prefer explicit types over inference for function signatures and exported values

### General
- Functions single-purpose, <50 lines; files <300 lines
- No magic strings/numbers — use constants or enums
- Max nesting 3 levels — extract to named functions
- No commented-out code
- All async operations handle errors explicitly (`try/catch` or `.catch()`)
- State must never be mutated directly — use spreads, `structuredClone`, or Immer

### Backend
- No `console.log` — use NestJS `Logger`
- DTOs with `class-validator` for all incoming data
- New env vars must be documented in `.env.example`

### Frontend
- No `console.log` — use a logger utility
- Input validation via **Zod**

### Testing
- Every function with business logic: 1 happy-path + 1 edge-case + 1 error-test minimum
- Game engine module (EP-004): hard target of 90%+ line coverage
- Tests must not depend on execution order — each is independently runnable
- Mocks/stubs must be reset between tests
- No `xit` / `xdescribe` / `test.skip` without an explanatory comment
- Integration tests use a real test database (not mocked repositories)
- Frontend component tests use React Testing Library — no Enzyme

---

## Workflow

### 1. Plan First
- Enter plan mode for any non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, stop and re-plan — don't keep pushing
- Write a plan to `docs/tasks/todo.md` with checkable items before starting implementation
- Check in with the user before implementing large or ambiguous changes

### 2. Subagent Strategy
- Use subagents to keep the main context window clean
- Offload research, exploration, and parallel analysis to subagents
- One focused task per subagent for clean execution

### 3. Self-Improvement Loop
- After any correction from the user: update `docs/tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Review `docs/tasks/lessons.md` at session start for relevant patterns

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Run tests, check logs, demonstrate correctness
- Ask: "Would a staff engineer approve this?"
- Diff behavior between `main` and your changes when relevant

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant solution?"
- If a fix feels hacky, implement the elegant solution instead
- Skip for simple, obvious fixes — don't over-engineer

### 6. Autonomous Bug Fixing
- When given a bug report: fix it — don't ask for hand-holding
- Follow logs, errors, and failing tests to resolution
- Fix failing CI without being told how

## Core Principles

- **Game Rules Win**: `GAME_RULES.md` is the constitution — adapt everything else to serve it
- **Simplicity First**: Make every change as simple as possible with minimal footprint
- **No Laziness**: Find root causes — no temporary fixes — senior developer standard
- **Minimal Impact**: Touch only what's necessary; avoid introducing regressions
- **Track Progress**: Mark todo items complete as you go; add a results summary to `docs/tasks/todo.md` and capture lessons in `docs/tasks/lessons.md` after corrections
