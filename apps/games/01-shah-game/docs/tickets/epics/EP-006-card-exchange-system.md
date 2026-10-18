# EP-006 — Card Exchange System

| Field | Value |
|---|---|
| **ID** | EP-006 |
| **Type** | Epic |
| **Team** | Full-Stack |
| **Priority** | P1 |
| **Status** | READY |
| **Depends On** | EP-004, EP-005 |
| **Blocks** | EP-007 |
| **Tickets** | T-059 – T-063 |
| **Estimated Effort** | M (4–5 days across BE + FE) |

---

## Description

Implements the post-game card exchange mechanic. After each game, 1st place gives their 2 worst cards to last place and receives the 2 best in return; 2nd place and 2nd-last exchange 1 card each. For exchange purposes, `2` is the most valuable card. The backend computes the exchange algorithmically and integrates it into the game lifecycle. The frontend visualises the exchange with animated card transfers before the next game begins.

---

## Background & Motivation

The card exchange is one of the defining features of Shah Exchange — it creates a feedback loop that makes rankings matter within a match (not just in a single game). Without it, each game is independent. With it, bad finishes compound across games (last place keeps losing their `2`s), and comebacks become narratively interesting.

The algorithm is also the most asymmetric part of the system: givers have no choice (they must give their worst/best), but the specific cards transferred affect every subsequent game. Getting this correct — and verifying it with thorough tests — is essential before it ships.

---

## Goals

### Backend
- Implement `ExchangeService.getBestCards()` and `getWorstCards()` with exchange rank ordering
- Implement `ExchangeService.computeExchange()` for all player counts (4–8)
- Integrate exchange into `GameService.handleGameFinished()` — apply updated hands before next deal
- Emit `game:exchange` to the match room with the full `ExchangeSummary`

### Frontend
- Build `GameFinishedOverlay` — full-screen rankings display after `game:finished`
- Build `CardExchangeView` — animated card transfers with Framer Motion, then countdown to next game

---

## Detailed Scope

### Backend (T-059 – T-061)

#### Best/Worst Card Selection (T-059)
`src/game-engine/exchange.service.ts`

Exchange rank order (worst → best): `3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2`

```typescript
getWorstCards(hand: Card[], count: number): Card[]
getBestCards(hand: Card[], count: number): Card[]
```

For ties in rank (same rank value), use suit as a deterministic tiebreaker:
`spades < clubs < diamonds < hearts` (alphabetical → heart > diamond > club > spade)

Edge cases:
- `count > hand.length` → return all available cards (do not throw)
- Empty hand → return `[]`

#### computeExchange() (T-060)
```typescript
interface ExchangeResult {
  actions: ExchangeAction[];                     // what was given and by whom
  updatedHands: Map<string, Card[]>;             // playerId → new hand
}

computeExchange(rankedPlayers: Player[]): ExchangeResult
```

Exchange pairs by finish rank:
| Pair | Giver | Cards Given | Receiver |
|---|---|---|---|
| 1st ↔ Last | 1st place | 2 worst cards | Last place |
| Last ↔ 1st | Last place | 2 best cards | 1st place |
| 2nd ↔ 2nd-last | 2nd place | 1 worst card | 2nd-last place |
| 2nd-last ↔ 2nd | 2nd-last place | 1 best card | 2nd place |

For player counts where there is no distinct "2nd-last" from "last" (e.g., exactly 3 remaining pairs), only the 1st/last exchange applies. With ≥ 4 players, both exchanges always occur.

Validate: total cards per player must be identical before and after exchange (no cards lost or duplicated — checked in tests via card count + unique identity).

#### Integration into Game Lifecycle (T-061)
In `GameService.handleGameFinished()` (replacing the stub from T-046):

1. Collect `rankedPlayers` from `GameState.finishedPlayers` order
2. Call `computeExchange(rankedPlayers)`
3. Apply `updatedHands` to the player objects that will be used in the next game deal
4. Build `ExchangeSummary` DTO:
   ```typescript
   interface ExchangeSummary {
     gameId: string;
     actions: Array<{
       giverId: string;
       giverName: string;
       receiverId: string;
       receiverName: string;
       cards: Card[];        // visible to all (what was given)
     }>;
   }
   ```
5. Emit `game:exchange` to match room
6. Proceed to next game initialization with updated hands as the starting hands for the new deal

> The cards exchanged are visible to everyone in the `game:exchange` payload (that's part of the social game experience). Each player's updated full hand is only revealed to them in the next `game:started` per-player projection.

---

### Frontend (T-062 – T-063)

#### GameFinishedOverlay (T-062)
`src/features/game/GameFinishedOverlay.tsx`

Triggered by the `game:finished` socket event. Renders as a full-screen overlay over the frozen game board.

Contents:
- Player rankings list (1st → last): rank number + display name + finishing position badge
- Local player's entry is highlighted (gold border)
- If local player is **1st place**: show a brief "You won!" celebration screen (2 seconds, with confetti or a simple animation) before revealing the full rankings
- Countdown timer (3 seconds) before the exchange phase begins
- "Next: Card Exchange" label during the countdown

Accessibility: `role="dialog"`, `aria-modal="true"`, focus trapped inside.

#### CardExchangeView (T-063)
`src/features/game/CardExchangeView.tsx`

Triggered by the `game:exchange` socket event (displayed after the rankings overlay transitions out).

Contents:
- Exchange pair rows: "[Alice] gave [3♣][4♦] to [Dave]"
- Cards animate flying from giver position to receiver using Framer Motion `layoutId` — the card visually moves across the screen
- After animation completes: show the local player's updated hand briefly ("Your new hand:") with newly-received cards highlighted with a gold border glow
- 5-second countdown timer before next game auto-starts
- "Game X starting in 5..." countdown bar

Motion behaviour:
- `prefers-reduced-motion` respected: when reduced motion is preferred, skip the fly animation and show a clear "before → after" state with no movement
- Animation duration: 600ms per card transfer, cards stagger 150ms apart

---

## Acceptance Criteria

### Backend
- [ ] `getWorstCards([K♠, 3♥, 7♦], 1)` returns `[3♥]`
- [ ] `getBestCards([K♠, 2♣, A♦], 1)` returns `[2♣]` (2 is highest for exchange)
- [ ] `computeExchange()` with 4 players: 1st gives 2 worst, last gives 2 best; 2nd gives 1 worst, 3rd gives 1 best
- [ ] Total card count per player is identical before and after exchange (no cards lost)
- [ ] Works correctly for all player counts 4–8
- [ ] `game:exchange` event is emitted after every game-finished event
- [ ] Next `game:started` payload uses the exchanged hands (not the original dealt hands)
- [ ] Unit tests cover: basic exchange (4 players), exchange with 2s, suit tiebreakers, 8-player layout

### Frontend
- [ ] `GameFinishedOverlay` renders on `game:finished` event with correct player rankings
- [ ] Local 1st-place player sees the "You won!" screen before the rankings
- [ ] Countdown ticks from 3 to 0 before exchange view opens
- [ ] `CardExchangeView` renders exchange actions with correct giver/receiver names and correct cards
- [ ] Newly received cards show a gold highlight in the updated hand preview
- [ ] Animations work and respect `prefers-reduced-motion`
- [ ] 5-second countdown bar is visible and accurate

---

## Dependencies

- Requires: EP-004 (rank utilities, types), EP-005 (game:finished flow stub to replace)
- Blocks: EP-007 (match:finished needs exchange to know final hands state)

---

## Reference
- `GAME_RULES.md §14` (exchange rules: 1st/last, 2nd/2nd-last, exchange rank order)
- `SYSTEM_DESIGN.md §6.5` (card exchange table), `APPENDIX B` (exchange algorithm notes)
- [`tickets.json`](../tickets.json) → `EP-006`, tickets T-059 – T-063
