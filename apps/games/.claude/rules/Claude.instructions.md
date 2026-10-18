---
description: Always loaded — applies to all files in this repository
applyTo: "**"
---

# Shah Exchange — AI Agent Instructions

> **Source of truth**: `CLAUDE.md` at the workspace root is the canonical reference for all agent instructions. If anything in this file conflicts with `CLAUDE.md`, treat `CLAUDE.md` as correct and update this file to match before proceeding.

## Project
Real-time multiplayer card game (3–8 players). NestJS backend + React 19 frontend in a pnpm monorepo under `01-shah-game/`.

## Authority hierarchy (strictly ordered)
1. `01-shah-game/docs/GAME_RULES.md` — game logic is absolute; adapt architecture to serve the rules, never the reverse
2. `01-shah-game/docs/SYSTEM_DESIGN.md` — living architecture reference; update when decisions change
3. `01-shah-game/docs/tickets/tickets.json` — check `status` before picking up any ticket

## Commands
```bash
# Backend (01-shah-game/backend)
pnpm start:dev   # port 3000
pnpm test        # Jest unit tests
pnpm test:e2e    # integration tests — real DB, never mocked
npx prisma generate  # run after schema.prisma changes — regenerates generated/prisma/

# Frontend (01-shah-game/frontend)
pnpm dev         # Vite, port 5173
pnpm build       # TS check + build
```

## Critical patterns

### Prisma
Generated client lives in `backend/generated/prisma/` (not `node_modules`). After any schema change run `npx prisma generate` from `backend/` or the TS compiler will error on missing/stale types.

### Backend modules
`AuthModule` → `PlayerModule` → `MatchModule` → `GameModule` + `GameEngineModule` + `GatewayModule`. Game engine is **pure/stateless** — no DB or Redis access — enabling exhaustive unit testing.

### WebSocket events
24 events total (13 client→server, 11 server→client). Read `docs/SYSTEM_DESIGN.md` before touching any real-time feature. Gateway is `src/gateway/game.gateway.ts`.

### State machine
`Match → Game → Round`. Exchange only runs after a game ends; with 3 players only 1st↔last swap (2 cards); with 4+ players 2nd↔2nd-to-last also runs (1 card).

### Frontend state
Zustand stores in `src/store/`. Socket connection managed via custom hooks in `src/hooks/`. Input validation via Zod; no `console.log` — use logger utility.

## Code standards
- TypeScript strict mode; no bare `any` without inline justification comment
- Functions < 50 lines, files < 300 lines, max nesting 3 levels
- No magic strings/numbers — use constants or enums
- Backend: NestJS `Logger` not `console.log`; DTOs with `class-validator` on all input
- State: never mutate directly — spreads, `structuredClone`, or Immer
- Tests: 1 happy-path + 1 edge-case + 1 error test per business-logic function; game engine targets 90%+ coverage

## Changelog
After every session with code/arch/doc changes create `01-shah-game/docs/changelog/YYYY-MM-DD-short-description.md`.