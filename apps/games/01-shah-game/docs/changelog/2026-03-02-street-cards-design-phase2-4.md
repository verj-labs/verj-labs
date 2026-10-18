# Design Implementation: Street Cards Chaotic — Phases 2–4 Completion

**Date:** 2026-03-02
**Scope:** Frontend — all remaining theme cleanup + new event overlay components

---

## Summary

Continued from the prior session which landed the design foundation (tokens, fonts, ShadCN overrides) and updated most gameplay components. This session finishes the remaining file migrations and delivers the Phase 4 animation overlays.

---

## Files Changed

### Theme cleanup (old green/white → dark street tokens)

| File | Change |
|---|---|
| `src/router/ProtectedRoute.tsx` | `bg-(--color-table)` → `bg-[var(--color-bg-0)]` |
| `src/pages/HistoryPage.tsx` | All `bg-white/10`, `text-white`, `text-yellow-400` → design tokens; skeleton pulses use `--color-border`; empty-state uses `variant="cta"` button |
| `src/features/game/GameFinishedOverlay.tsx` | `text-yellow-400` (win screen) → `text-[var(--color-electric-yellow)]` |
| `src/components/ui/PileDisplay.tsx` | Reset glow rgba → `rgba(255,59,59,n)` matching `--color-danger-red` |
| `src/pages/RoomPage.tsx` | Removed unused `hostPlayer` declaration (TS error) |
| `src/components/ui/ActionBar.tsx` | Reverted error display from `COPY.invalidPlay` back to `{lastActionError}` so server messages show correctly |

### New components (Phase 4)

**`src/features/game/SkipOverlay.tsx`** (new)
- Full-viewport flash on `game:player_skipped`; reads `skippedPlayerId` from gameStore, resolves display name from `gameState.players`
- Hot-pink `SKIP!` in Space Grotesk, random ±rotation (−12° to +12°), random skip phrase from `COPY.skipPhrases`
- `AnimatePresence` spring in + fade-out exit (450ms); respects `prefers-reduced-motion`
- `pointer-events-none` — never blocks input; auto-dismisses after 900ms
- `aria-live="assertive"` for screen readers

**`src/features/game/ResetOverlay.tsx`** (new)
- Full-viewport flash on `game:pile_reset`; reads `pileResetPending` from gameStore
- Hot-pink `RESET!` + "pile cleared 🧹" subtitle
- Same animation pattern as SkipOverlay; auto-dismisses after 700ms (matching PileDisplay scatter)
- `pointer-events-none`, `aria-live="assertive"`

Both overlays wired into `src/pages/GamePage.tsx` alongside existing `<GameFinishedOverlay />` and `<CardExchangeView />`.

---

## Tests

- `src/test/LandingPage.test.tsx` — updated label selector `/display name/i` → `/your name/i`; generic error matcher → `/something broke/i`
- `src/test/LobbyPage.test.tsx` — updated label selector `/room code/i` → `/^code/i` (room code label is now just "Code" via COPY)
- `src/test/PlayingCard.test.tsx` — snapshots regenerated (class names changed: removed old fallback values from CSS vars)
- **Result:** 115/115 tests passing, build clean

---

## Design Phase Status

| Phase | Status |
|---|---|
| 0 — Audit | ✅ Complete |
| 1 — Foundation (tokens, fonts, ShadCN, button) | ✅ Complete |
| 2 — Pre-game screens | ✅ Complete |
| 3 — Game board components | ✅ Complete |
| 4 — Animation & event overlays (SkipOverlay, ResetOverlay) | ✅ Partial (SkipOverlay + ResetOverlay done; RoundWonOverlay, CardExchange animation, SeatSlot pulse still pending) |
| 5 — Microcopy pass | ✅ Near complete (COPY used in all key components) |
| 6 — Polish / QA | ❌ Not started |

### Remaining Phase 4 items (not in this session)
- `RoundWonOverlay.tsx` (new) — "X WINS!" in yellow + 👑
- `SeatSlot.tsx` — pulsing lime glow on active seat (Phase 4.6)
- `CardExchangeView.tsx` — card-flight animation with Framer Motion `layoutId`
