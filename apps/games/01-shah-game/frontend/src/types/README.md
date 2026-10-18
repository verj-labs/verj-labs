# Frontend Types

This directory contains TypeScript types for the Shah card game frontend.
Several of these files are **mirrors** of the canonical backend definitions and
must be kept in sync manually.

## File overview

| File | Description | Mirrors |
|------|-------------|---------|
| `card.ts` | `Suit`, `Rank`, `SetSize`, `Card`, UI helpers | `backend/src/shared/types/card.types.ts` |
| `game-state.ts` | `GameState`, `Player`, `Pile`, `RoundState`, etc. | `backend/src/shared/types/game-state.types.ts` |
| `events.ts` | `GameEvent`, `PlayIntent`, `EngineResult`, etc. | `backend/src/shared/types/events.types.ts` |
| `match.ts` | Lobby-specific match types | — |
| `player.ts` | Player profile types | — |

## Sync policy

The backend is the **source of truth** for all shared types.  Whenever a type
changes in `backend/src/shared/types/`, the corresponding frontend file must be
updated in the same PR/commit.

The three mirrored files (`card.ts`, `game-state.ts`, `events.ts`) intentionally
omit NestJS/Prisma-specific decorators and import only from within `src/types/`.
