> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary backend detail.
> **Replaced by:** [EP-004 — Core Game Engine](../epics/EP-004-core-game-engine.md) · [tickets.json](../tickets.json) → T-028–T-039

---

# BE-EP-004 — Core Game Engine

| Field | Value |
|---|---|
| **ID** | BE-EP-004 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | BE-EP-001 |
| **Blocks** | BE-EP-006, BE-EP-007 |
| **Estimated Effort** | L (7–10 days) |

---

## Description

This is the most technically critical epic in the entire project. The Core Game Engine implements the complete Shah Exchange ruleset as a pure, stateless, strongly-typed service. It takes a `GameState` and a player intent, validates the intent against the rules, and returns a new `GameState` plus a list of events that occurred.

Being pure and stateless means this module has **no database access, no Redis access, no HTTP calls** — it is a deterministic function. This makes it independently testable to a very high degree of coverage, which is essential for a game where incorrect rule enforcement directly breaks the player experience.

---

## Background & Motivation

The game has numerous interacting rules (set sizing, rank comparison, skip mechanics, 2-card resets, consecutive pass counting, win detection, etc.). These rules must be enforced 100% server-side to prevent cheating and ensure all players see a consistent state. A dedicated, isolated engine service is the correct architectural pattern — it separates business logic from I/O concerns and enables exhaustive unit testing.

---

## Goals

- Implement all rules from `GAME_RULES.md` and `SYSTEM_DESIGN.md §6`
- Provide a single `processIntent()` entry point for the orchestration layer
- Provide a `dealCards()` function for distributing hands at game start
- Implement `determineDirection()` for Game 2+ seating logic
- Cover all edge cases with unit tests (target: 90%+ coverage on engine module)
- Document all rule assumptions/interpretations inline with comments

---

## Detailed Scope

### 1. Types & Interfaces

All types defined in `src/shared/types/`:

```typescript
// Card
type Suit = 'hearts' | 'diamonds' | 'clubs' | 'spades';
type Rank = '3'|'4'|'5'|'6'|'7'|'8'|'9'|'10'|'J'|'Q'|'K'|'A'|'2';

interface Card { rank: Rank; suit: Suit; }

// Play intent submitted by a player
interface PlayIntent {
  playerId: string;
  type: 'play' | 'pass';
  cards?: Card[];
}

// Result of processing an intent
interface EngineResult {
  newState: GameState;
  events: GameEvent[];
  error?: string; // present when intent is invalid
}

// Events emitted by the engine
type GameEventType =
  | 'PILE_UPDATED'
  | 'PILE_RESET'
  | 'PLAYER_SKIPPED'
  | 'PLAYER_PASSED'
  | 'ROUND_ENDED'
  | 'PLAYER_FINISHED'
  | 'GAME_FINISHED'
  | 'TURN_ADVANCED';
```

### 2. DeckService — Card Generation & Dealing

**`buildDeck(): Card[]`**
- Returns full 52-card deck (all suits × all ranks)

**`shuffleDeck(deck: Card[]): Card[]`**
- Fisher-Yates shuffle, pure function (accepts deck, returns shuffled deck)
- Seeded shuffle option for testing

**`dealHands(playerCount: number): { hands: Card[][], discarded: Card[] }`**
- Implements the dealing rules from `GAME_RULES.md §4`
- Correctly computes cards-per-player and discarded cards
- Returns one array per player + discarded pile

| Players | Cards Each | Discarded |
|---------|------------|-----------|
| 4 | 13 | 0 |
| 5 | 10 | 2 |
| 6 | 8 | 4 |
| 7 | 7 | 3 |
| 8 | 6 | 4 |

### 3. RulesService — Play Validation

**`validatePlay(state: GameState, intent: PlayIntent): ValidationResult`**

Validation must check (in order):
1. It is the player's turn (`state.currentRound.activePlayerIndex`)
2. The player has not already finished
3. If `intent.type === 'pass'` → always valid
4. If `intent.type === 'play'`:
   a. `cards` must be non-empty
   b. All cards exist in the player's hand (exact suit+rank match)
   c. All cards in the set are the same rank
   d. Set size is 1–4
   e. **If pile is empty** → any valid set is allowed (start of round)
   f. **If pile has a top play**:
      - Cards must be rank `'2'` (reset path) OR same-size-and-higher-rank path
      - **Reset path:** set size must match reset requirement for current pile type (see below)
      - **Normal path:** set size must equal pile size AND rank >= pile rank
5. Return `{ valid: true }` or `{ valid: false, reason: string }`

**Reset validation table:**
| Pile Size | Required reset play size |
|-----------|--------------------------|
| 1 (single) | 1× `2` |
| 2 (double) | 1× `2` |
| 3 (triple) | 2× `2` |
| 4 (quad) | 3× `2` |

### 4. GameEngineService — State Transitions

**`processIntent(state: GameState, intent: PlayIntent): EngineResult`**

This is the top-level engine function. It:

1. Calls `RulesService.validatePlay()` → if invalid, return `{ newState: state, events: [], error: reason }`
2. If valid pass:
   - Increment `consecutivePassCount`
   - Advance turn (skip finished players, respect direction)
   - Check round-end condition: `consecutivePassCount === activePlayers - 1`
     - If round ends: clear pile, reset pass count, last-play-winner becomes active player
   - Emit: `PLAYER_PASSED`, possibly `ROUND_ENDED`, `TURN_ADVANCED`

3. If valid play (non-reset):
   - Remove played cards from player's hand
   - Update `pile.topPlay`
   - Reset `consecutivePassCount` to 0
   - Check if player hand is empty → mark as finished, assign rank
   - Check if same rank as pile top → set `skippedPlayerIndex` (next player gets skipped)
   - Advance turn (skip finished players, skip skipped player, respect direction)
   - Check if all players finished → `GAME_FINISHED`
   - Emit appropriate events

4. If valid reset (rank = 2):
   - Remove 2-card(s) from player's hand
   - Clear the pile (`pile.topPlay = null`)
   - Do NOT advance turn (same player's turn continues)
   - Reset `consecutivePassCount` to 0
   - Check player hand empty (can happen!)
   - Emit: `PILE_RESET`, possibly `PLAYER_FINISHED`

### 5. Turn Advancement Logic

**`getNextActivePlayerIndex(state: GameState, currentIndex: number, direction: Direction, skipCount?: number): number`**

- Respects `direction` (clockwise = +1 mod n, counterclockwise = -1 mod n)
- Skips players who are `isFinished = true`
- If `skipCount = 1` (skip next rule), skips one additional player
- If all remaining players are finished (shouldn't happen, but guard against it) → return -1

### 6. Direction Determination

**`determineDirection(winnerSeatIndex: number, secondPlaceSeatIndex: number, totalPlayers: number): Direction`**

- Winner is at "12 o'clock" reference position
- Determine if second place is to winner's right or left based on seat indices
- For a circular arrangement of seats 0..n-1:
  - "Right" of winner (clockwise neighbor): seat = (winnerSeat + 1) % n
  - "Left" of winner (counterclockwise neighbor): seat = (winnerSeat - 1 + n) % n
  - For n > 2, determine which "half" second place falls in
  - Right half → clockwise; Left half → counterclockwise
  - Tie-break (directly opposite) → clockwise (chosen default)

### 7. Rank Comparison Helpers

```typescript
// Standard rank order for playing (2 excluded)
const PLAY_RANK_ORDER = ['3','4','5','6','7','8','9','10','J','Q','K','A'];

// Exchange rank order (2 is highest)
const EXCHANGE_RANK_ORDER = ['3','4','5','6','7','8','9','10','J','Q','K','A','2'];

function comparePlayRank(a: Rank, b: Rank): number // returns neg/0/pos
function isReset(rank: Rank): boolean // rank === '2'
function getResetRequirement(pileSize: SetSize): SetSize
```

### 8. Unit Tests (Comprehensive Coverage Required)

Test scenarios must include at minimum:
- [ ] Dealing: all player counts (4–8), correct hand sizes, correct discarded counts
- [ ] Shuffle: output is a permutation of input, no duplicates
- [ ] Valid single play on empty pile
- [ ] Valid double play on empty pile
- [ ] Valid triple / quad play on empty pile
- [ ] Play beats pile (higher rank, same size)
- [ ] Play matches pile rank (same rank, same size) → skip next player
- [ ] Play lower rank than pile → rejected
- [ ] Mismatched set size → rejected
- [ ] Cards not in player's hand → rejected
- [ ] Not player's turn → rejected
- [ ] Reset single pile with single 2
- [ ] Reset double pile with single 2
- [ ] Reset triple pile with double 2
- [ ] Reset quad pile with triple 2
- [ ] Invalid reset (wrong size 2 play) → rejected
- [ ] Player finishes after playing last cards
- [ ] Player finishes by resetting (last cards are 2s)
- [ ] Consecutive pass count increments → round ends correctly
- [ ] Skip rule applied, skipped player advances correctly
- [ ] Turn advances correctly in clockwise direction
- [ ] Turn advances correctly in counterclockwise direction
- [ ] Finished players are skipped in turn advancement
- [ ] `determineDirection()` for all seat positions
- [ ] `processIntent()` returns full new GameState on success
- [ ] `processIntent()` returns error (no state mutation) on invalid play

---

## Acceptance Criteria

- [ ] `DeckService.buildDeck()` returns exactly 52 unique cards
- [ ] `DeckService.dealHands()` returns correct counts for all player counts 4–8
- [ ] All rules from `GAME_RULES.md` are implemented and verified by tests
- [ ] `processIntent()` never mutates the input `GameState` (pure function — use spread/clone)
- [ ] `processIntent()` returns an error object (does not throw) on invalid input
- [ ] Test coverage of `game-engine` module is ≥ 90%
- [ ] All types are exported from `src/shared/types/`
- [ ] `RulesService` and `GameEngineService` have zero dependencies on NestJS I/O modules

---

## Out of Scope

- Card exchange (covered in BE-EP-007)
- Persisting game events to DB (covered in BE-EP-008)
- WebSocket broadcasting (covered in BE-EP-005)

---

## Technical Notes

- **Immutability is critical:** `processIntent()` must not mutate the input state. Use deep cloning (`structuredClone` or Immer or manual spread) at the start.
- All array access and manipulation should be defensive (bounds-checked)
- The engine knows nothing about HTTP, WebSockets, or databases
- Consider a `GameStateFactory` helper for creating valid initial game states in tests
