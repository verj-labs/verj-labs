---
description: Always loaded — applies to all files in this repository
applyTo: "**"
---

# Shah Exchange — GitHub Copilot Agent Instructions

> **Source of truth**: `CLAUDE.md` at the workspace root is the canonical reference for all agent instructions. If anything in this file conflicts with `CLAUDE.md`, treat `CLAUDE.md` as correct and update this file to match before proceeding.

## Project overview
Real-time multiplayer card game platform (3–8 players). Monorepo: `01-shah-game/backend/` (NestJS + Prisma + PostgreSQL + Redis) and `01-shah-game/frontend/` (React 19 + Vite + Zustand + Tailwind CSS v4 + shadcn/ui).

## Authority hierarchy (strictly ordered)
1. `01-shah-game/docs/GAME_RULES.md` — absolute ruleset; never contradict it
2. `01-shah-game/docs/SYSTEM_DESIGN.md` — living architecture doc; update when decisions change
3. `01-shah-game/docs/tickets/tickets.json` — check `status` before starting any ticket

## Developer workflows
```bash
# Backend (run from 01-shah-game/backend/)
pnpm start:dev          # hot-reload server, port 3000
pnpm test               # Jest unit tests
pnpm test:e2e           # integration tests against real test DB (never mocked)
npx prisma generate     # REQUIRED after any prisma/schema.prisma change

# Frontend (run from 01-shah-game/frontend/)
pnpm dev                # Vite dev server, port 5173
pnpm build              # TypeScript check + production build

# E2E (run from 01-shah-game/e2e/ — both servers must be running first)
pnpm test               # Playwright headless
pnpm test:headed        # with visible browser windows
```

## Architecture
- State machine: **Match → Game → Round**
- `GameEngineModule` is pure/stateless — no DB/Redis — making it fully unit-testable
- Prisma client is generated into `backend/generated/prisma/` (not `node_modules`); stale client = TS compile errors
- WebSocket: 24 events (13 client→server, 11 server→client) documented in `SYSTEM_DESIGN.md §WebSocket Protocol` — read before touching real-time code
- Card exchange rules: 3 players → 1st↔last only (2 cards); 4+ players → also 2nd↔2nd-to-last (1 card)

## Key conventions
- **shadcn/ui**: use the MCP server (configured in `.mcp.json`) to browse components and get the correct `add` command — do not guess CLI flags from memory
- **E2E tests**: always use `data-testid` selectors; assert from recipient's perspective; minimum 3 players per test; `waitForSelector` not `sleep`
- **No `console.log`** anywhere — `Logger` on backend, logger utility on frontend
- **DTOs** with `class-validator` on all backend incoming data
- **Zod** for all frontend input validation
- TypeScript strict mode; no bare `any` without inline justification comment
- State is never mutated directly — use spreads, `structuredClone`, or Immer
- Functions < 50 lines, files < 300 lines, max nesting 3 levels

## Useful entry points
- Backend gateway: `src/gateway/game.gateway.ts`
- Frontend stores: `src/store/`
- Frontend hooks: `src/hooks/`
- Deck/dealing logic: `src/game-engine/deck.service.ts`
- Exchange logic: `src/game-engine/exchange.service.ts`