# EP-004 — Core Game Engine

| Field | Value |
|---|---|
| **ID** | EP-004 |
| **Type** | Epic |
| **Team** | Backend (+ type sync to Frontend) |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | EP-001 |
| **Blocks** | EP-005, EP-006 |
| **Tickets** | T-028 – T-040 |
| **Estimated Effort** | L (7–10 days) |

---

## Description

Implements the complete Shah Exchange ruleset as a **pure, stateless, server-side game engine**. The engine has no database access, no Redis access, no HTTP calls — it is a deterministic function: `(GameState, PlayIntent) → (GameState, GameEvent[])`. This isolation makes it exhaustively unit-testable. A single frontend ticket (T-040) mirrors the type definitions.

This is the most test-critical module in the project. A bug here breaks the game experience for every player in every match. Target: **90%+ line coverage** on the `game-engine/` module.

---

## Background & Motivation

The game has numerous interacting rules:

- Set sizing constraint (singles beat singles, doubles beat doubles, etc.)
- Standard rank comparison (`3 < 4 < ... < A`, with `2` excluded from the normal ladder)
- Skip-next-player when the same rank is played
- Power card `2` resets the pile and extends the current player's turn (with complex set-size requirements)
- Consecutive-pass detection → round end → next round start
- Player finish detection + rank assignment
- Turn direction (`clockwise` / `counterclockwise`) based on seating geometry
- Card exchange ranking (`3 < 4 < ... < A < 2`)

By isolating all of this into one pure module:
1. Each rule can be unit-tested independently
2. The WebSocket layer and persistence layer cannot accidentally affect rule outcomes
3. The engine is replayable from any saved state

---

## Goals

- Define all shared TypeScript types for the entire game domain
- Implement `DeckService`: build, shuffle (seeded), and deal hands
- Implement rank comparison utilities and reset requirement lookup
- Implement `RulesService.validatePlay()` for both normal and reset paths
- Implement `GameEngineService.processIntent()`: pass branch, normal play branch, reset branch
- Implement turn advancement with direction + skip logic
- Implement `determineDirection()` from seating geometry
- Mirror all shared types to the frontend
- Achieve ≥ 90% line coverage on the `game-engine/` module

---

## Detailed Scope

### Shared Types (T-028)

Location: `src/shared/types/` — three files, zero logic.

```typescript
// card.types.ts
type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades';
type Rank = '3'|'4'|'5'|'6'|'7'|'8'|'9'|'10'|'J'|'Q'|'K'|'A'|'2';
type SetSize = 1 | 2 | 3 | 4;
interface Card { rank: Rank; suit: Suit; }

// game-state.types.ts
type Direction = 'clockwise' | 'counterclockwise';
type GameStatus = 'waiting' | 'dealing' | 'in_progress' | 'finished';
type MatchStatus = 'lobby' | 'in_progress' | 'finished';

interface Play { cards: Card[]; playerId: string; isReset: boolean; }
interface Pile { topPlay: Play | null; history: Play[]; }
interface Player { id: string; displayName: string; seatIndex: number; hand: Card[]; isFinished: boolean; finishRank: number | null; }
interface RoundState { pile: Pile; consecutivePassCount: number; lastPlayerId: string | null; skippedPlayerIndex: number | null; }
interface GameState { id: string; matchId: string; gameNumber: number; direction: Direction; status: GameStatus; players: Player[]; activePlayerIndex: number; currentRound: RoundState; finishedPlayers: string[]; }
interface MatchState { id: string; roomCode: string; hostPlayerId: string; players: Array<{ id: string; displayName: string; seatIndex: number }>; status: MatchStatus; playerCount: number; }

// events.types.ts
type GameEventType = 'PILE_UPDATED' | 'PILE_RESET' | 'PLAYER_SKIPPED' | 'PLAYER_PASSED' | 'ROUND_ENDED' | 'PLAYER_FINISHED' | 'GAME_FINISHED' | 'TURN_ADVANCED';
interface PlayIntent { playerId: string; type: 'play' | 'pass'; cards?: Card[]; }
interface EngineResult { newState: GameState; events: Array<{ type: GameEventType; payload?: unknown }>; error?: string; }
interface ExchangeAction { giverId: string; receiverId: string; cards: Card[]; }
```

### DeckService (T-029 – T-030)

`src/game-engine/deck.service.ts`

**`buildDeck()`**: Returns all 52 cards (4 suits × 13 ranks). Pure function, no side effects.

**`shuffleDeck(deck, seed?)`**: Fisher-Yates shuffle. Seeded variant uses a deterministic PRNG (e.g. mulberry32) for reproducible test scenarios.

**`dealHands(playerCount, deck)`**: Implements the dealing table from `GAME_RULES.md §4`:

| Players | Cards Each | Cards Discarded |
|---|---|---|
| 4 | 13 | 0 |
| 5 | 10 | 2 |
| 6 | 8 | 4 |
| 7 | 7 | 3 |
| 8 | 6 | 4 |

Returns `{ hands: Card[][], discarded: Card[] }`. Throws for invalid player counts.

### Rank Utilities (T-031)

`src/game-engine/rank.utils.ts`

```typescript
const PLAY_RANK_ORDER = ['3','4','5','6','7','8','9','10','J','Q','K','A']; // 2 excluded
const EXCHANGE_RANK_ORDER = [...PLAY_RANK_ORDER, '2'];                       // 2 is best for exchange

function comparePlayRank(a: Rank, b: Rank): number  // negative = a < b
function isReset(rank: Rank): boolean                // true only for '2'
function getResetRequirement(pileSize: SetSize): SetSize  // how many 2s are needed
```

**Reset requirements** (from `GAME_RULES.md §12.1`):
| Pile Size | 2s Required |
|---|---|
| Single (1) | 1 |
| Double (2) | 1 |
| Triple (3) | 2 |
| Quad (4) | 3 |

### RulesService.validatePlay() (T-032 – T-033)

`src/game-engine/rules.service.ts` — returns `{ valid: true }` or `{ valid: false, reason: string }`.

**Normal play validation (T-032):**
1. It is the player's turn (`state.activePlayerIndex` matches player's `seatIndex`)
2. All played cards are in the player's hand
3. All played cards have the same rank
4. If pile is active: set size matches `pile.topPlay.cards.length`
5. If pile is active: `comparePlayRank(playRank, pileRank) >= 0`

**Reset play validation (T-033):**
When all played cards are rank `'2'`:
1. If pile is active: `play.cards.length === getResetRequirement(pile.topPlay.cards.length)`
2. If pile is empty: valid as a normal play (no reset semantics on an empty pile)

### Turn Advancement (T-034)

`src/game-engine/turn.utils.ts`

```typescript
function getNextActivePlayerIndex(
  state: GameState,
  currentIndex: number,
  skipCount: number = 0
): number
```

- `clockwise` → `(currentIndex + 1 + skipCount) % players.length`, wrapping over finished players
- `counterclockwise` → `(currentIndex - 1 - skipCount + players.length) % players.length`
- Finished players are always skipped automatically
- Returns `-1` if no active players remain (guard case only — game should be finished before this)

### GameEngineService.processIntent() (T-035 – T-037)

`src/game-engine/game-engine.service.ts`

**Entry point — always deep-clones input state before mutation:**
```typescript
processIntent(state: GameState, intent: PlayIntent): EngineResult
```

**Pass branch (T-035):**
1. Increment `consecutivePassCount`
2. Emit `PLAYER_PASSED` event
3. If `consecutivePassCount === activePlayers - 1`: round ends — clear pile, reset pass count, set `activePlayerIndex` = player who last played; emit `ROUND_ENDED`
4. Otherwise: advance turn

**Normal play branch (T-036):**
1. Call `validatePlay()` — on failure return `{ error }`
2. Remove played cards from player's hand
3. Set `pile.topPlay` = play; reset `consecutivePassCount = 0`; emit `PILE_UPDATED`
4. If same rank as pile: set `skip = true` for turn advancement; emit `PLAYER_SKIPPED`
5. Check `player.hand.length === 0` → mark `isFinished = true`, assign `finishRank`, emit `PLAYER_FINISHED`
6. Check all players finished → emit `GAME_FINISHED`
7. Advance turn (with skip if applicable)

**Reset branch (T-037):**
When `validatePlay()` identifies a reset (rank `'2'` on active pile):
1. Remove played cards from player's hand
2. Set `pile.topPlay = null`, `pile.history = []`; reset `consecutivePassCount = 0`; emit `PILE_RESET`
3. **Do NOT advance the turn** — same player continues
4. Check if player's hand is now empty (player can finish by resetting)

### determineDirection() (T-038)

```typescript
function determineDirection(
  winnerSeatIndex: number,
  secondPlaceSeatIndex: number,
  totalPlayers: number
): Direction
```

Uses circular seat geometry (seats arranged 0 → n-1 around a table):
- The "right half" from the winner's perspective = seats `(winner+1) % n` through `(winner + Math.floor(n/2)) % n`
- If 2nd place is in the right half → `'clockwise'`
- If in the left half → `'counterclockwise'`
- If exactly opposite (even player count) → `'clockwise'` (tie-break)

### Test Suite (T-039)

`src/game-engine/__tests__/`

Uses a `GameStateFactory` helper to build deterministic states. Covers every rule from `GAME_RULES.md`:

| Scenario Group | Tests |
|---|---|
| Deck | buildDeck() 52 cards, no duplicates; shuffleDeck() is permutation; seeded shuffle is deterministic; dealHands() all player counts |
| Rank utils | comparePlayRank all edges; isReset; getResetRequirement all 4 pile sizes |
| validatePlay — normal | Not player's turn; card not in hand; mixed ranks; wrong set size; rank too low; same rank (valid); empty pile (valid) |
| validatePlay — reset | All 4 pile sizes; insufficient 2s; too many 2s; reset on empty pile |
| processIntent — pass | Single pass; chain of all-pass → round end; round end assigns correct next player |
| processIntent — play | Normal beat; same-rank skip; player finishes; last player finishes → GAME_FINISHED; reset clears pile + keeps turn |
| Turn advancement | Clockwise/counterclockwise wrap; finished players skipped; skipCount=1 |
| determineDirection | All player counts 4–8; both sides; opposite seat tie-break |

**Target**: ≥ 90% line coverage on `src/game-engine/`

### Frontend Type Mirror (T-040)

`src/types/` — manual copy of `card.types.ts`, `game-state.types.ts`, `events.types.ts`. A `README.md` note in the folder explains they must stay in sync with `src/shared/types/` on the backend. The `PlayingCard` component (T-011) is updated to use the `Rank` and `Suit` types from this location.

---

## Acceptance Criteria

### Backend
- [ ] `buildDeck()` returns exactly 52 unique cards
- [ ] `dealHands(5, deck)` returns 5 hands of 10 cards + 2 discarded (all 6 player counts tested)
- [ ] `validatePlay()` returns `{ valid: false }` for each of the 7 invalid scenarios; `{ valid: true }` for valid plays
- [ ] Reset: `single 2 on double pile` → valid; `single 2 on triple pile` → invalid
- [ ] `processIntent()` does not mutate the input state (verified with `Object.freeze` in tests)
- [ ] Pile resets correctly: `pile.topPlay === null`, same player's turn after reset
- [ ] `GAME_FINISHED` is emitted when the last player's hand becomes empty
- [ ] `pnpm test --coverage` reports ≥ 90% lines on `src/game-engine/`
- [ ] All tests are independent and run in < 5 seconds

### Frontend
- [ ] All types are importable from `@/types/`
- [ ] Types compile cleanly in strict mode
- [ ] `PlayingCard` uses `Rank` and `Suit` from the mirrored types

---

## Dependencies

- Requires: EP-001 (project structure, module shells)
- Blocks: EP-005 (T-044 startMatch uses DeckService; T-045 uses processIntent), EP-006 (T-059 uses ExchangeService types)

---

## Reference
- `GAME_RULES.md §3` (rank order), `§4` (dealing), `§7–§12` (play rules, skip, reset, passing), `§14` (exchange ranking)
- `SYSTEM_DESIGN.md §5` (domain model), `§6` (state machine), `§8.3` (GameEngineService interface)
- [`tickets.json`](../tickets.json) → `EP-004`, tickets T-028 – T-040
