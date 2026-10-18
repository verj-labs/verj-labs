> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary backend detail.
> **Replaced by:** [EP-006 — Card Exchange System](../epics/EP-006-card-exchange-system.md) · [tickets.json](../tickets.json) → T-059–T-061

---

# BE-EP-007 — Card Exchange System

| Field | Value |
|---|---|
| **ID** | BE-EP-007 |
| **Type** | Epic |
| **Team** | Backend |
| **Priority** | P1 |
| **Status** | READY |
| **Depends On** | BE-EP-004, BE-EP-006 |
| **Blocks** | None (feeds into next game start in BE-EP-006) |
| **Estimated Effort** | S (2–3 days) |

---

## Description

This epic implements the card exchange mechanic that occurs at the end of every Game before the next one begins. Based on final rankings, specific cards are transferred between players: 1st ↔ last (2 cards), 2nd ↔ second-last (1 card). The exchange uses a specific value ordering where `2` is considered the best card.

This is a well-scoped, largely algorithmic epic with minimal I/O — most of the complexity is in correctly computing which cards to exchange and applying them to hands.

---

## Background & Motivation

The card exchange is central to the fairness and strategy of the game. It ensures that high-ranked players are slightly penalized (giving away their best cards) while lower-ranked players receive better cards for the next game. Incorrect implementation directly affects game balance and player experience.

---

## Goals

- Implement `ExchangeService` as a pure algorithmic service
- Correctly identify "worst" and "best" cards for each exchange participant
- Apply exchange (mutate hands on copies, return modified hands)
- Support the case where 1st and last are exchange partners AND 2nd and 2nd-last are different players
- Handle edge cases: player count = 4 (1st/last + 2nd/3rd), player count = 5+
- Emit exchange result events via the gateway
- Persist exchange details as game events (BE-EP-008)

---

## Detailed Scope

### 1. Exchange Value Ordering

For exchange purposes, rank cards as follows (worst → best):
```
3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2
```

Suit does not affect exchange value — only rank matters.

If a player has multiple cards of the same exchange rank, choose the one with the highest suit alphabetical order (hearts > diamonds > clubs > spades) for determinism. (This is primarily a tiebreaker for testing consistency, not a game rule.)

### 2. ExchangeService

```typescript
interface ExchangeAction {
  fromPlayerId: string;
  toPlayerId: string;
  cards: Card[];
}

interface ExchangeResult {
  actions: ExchangeAction[];
  updatedHands: Map<string, Card[]>; // playerId → new hand after exchange
}

class ExchangeService {
  computeExchange(rankedPlayers: Player[]): ExchangeResult;
  private getWorstCards(hand: Card[], count: number): Card[];
  private getBestCards(hand: Card[], count: number): Card[];
  private applyActions(players: Player[], actions: ExchangeAction[]): Map<string, Card[]>;
}
```

### 3. Exchange Algorithm

Given `rankedPlayers` sorted by rank (index 0 = 1st place, index n-1 = last):

**Step 1 — Determine exchange pairs:**
- `first` = `rankedPlayers[0]`
- `last` = `rankedPlayers[n-1]`
- `second` = `rankedPlayers[1]`
- `secondLast` = `rankedPlayers[n-2]`

**Step 2 — Validity check:**
- If `n < 4` (safety guard): no exchange (shouldn't happen in a valid game)
- If `n === 4`: `second` and `secondLast` are different players (indices 1 and 2)
  - Careful: do not double-exchange same pair if n=4

**Step 3 — Compute cards to give:**
- `firstGives`: `getWorstCards(first.hand, 2)` — 2 lowest-ranked cards
- `lastGives`: `getBestCards(last.hand, 2)` — 2 highest-ranked cards
- `secondGives`: `getWorstCards(second.hand, 1)` — 1 lowest-ranked card
- `secondLastGives`: `getBestCards(secondLast.hand, 1)` — 1 highest-ranked card

**Step 4 — Apply exchange:**
- Remove `firstGives` from first's hand, add `lastGives`
- Remove `lastGives` from last's hand, add `firstGives`
- Remove `secondGives` from second's hand, add `secondLastGives`
- Remove `secondLastGives` from secondLast's hand, add `secondGives`

**Step 5 — Return both the action list and updated hands**

### 4. Edge Case: What if 1st Place is also 2nd-last? (Player count 4, different scenarios)
In a 4-player game: slots are 1st, 2nd, 3rd (=2nd-last), 4th (=last).
- Exchange pair 1: 1st ↔ 4th (2 cards)
- Exchange pair 2: 2nd ↔ 3rd (1 card)
These are always distinct in a 4-player game. No overlap possible.

In a 5-player game: slots are 1st, 2nd, 3rd, 4th (=2nd-last), 5th (=last).
- Exchange pair 1: 1st ↔ 5th
- Exchange pair 2: 2nd ↔ 4th
Also distinct. Confirmed for all valid game sizes (4–8 players).

### 5. Integration with Game Lifecycle (BE-EP-006)

`GameService` calls `ExchangeService.computeExchange()` after `GAME_FINISHED`:
1. Get `finishedPlayers` ordered by rank from `GameState`
2. Call `computeExchange()`
3. Apply updated hands to player objects for the next game
4. Emit `game:exchange` event to match room with a sanitized exchange summary:
   - Show what each player gave/received
   - Do NOT reveal other players' updated hands (only counts)

### 6. Exchange Summary DTO

```typescript
interface ExchangeSummary {
  exchanges: Array<{
    giverId: string;
    giverName: string;
    receiverId: string;
    receiverName: string;
    cardCount: number;
    // cards given are visible to all (known public info)
    cardsGiven: Card[];
  }>;
}
```

---

## Acceptance Criteria

- [ ] `computeExchange()` returns correct actions for all player counts 4–8
- [ ] `getWorstCards(hand, 2)` returns the 2 lowest-value cards by exchange ranking
- [ ] `getBestCards(hand, 2)` returns the 2 highest-value cards by exchange ranking
- [ ] `2` is treated as the highest card in exchange ranking
- [ ] Exchange is symmetric: what A gives, B receives, and vice versa
- [ ] Updated hands have correct card counts after exchange
- [ ] No card is duplicated or lost during exchange
- [ ] `game:exchange` socket event is emitted with correct summary
- [ ] Unit tests cover: all player counts, hands with multiple 2s, hands without 2s, deterministic tiebreaking
- [ ] `ExchangeService` is pure (no I/O dependencies)

---

## Out of Scope

- UI display of exchange (FE-EP-007)
- Player choosing which cards to give (not part of the rules — exchange is automatic)

---

## Technical Notes

- Card identity: when removing a card from a hand during exchange, match on both `rank` AND `suit`. A hand could theoretically have been dealt cards of the same rank but different suits, so suit is the disambiguator.
- The exchange result (which cards moved) should be persisted as a `game_events` entry of type `'exchange'` with the full action list in the `payload` JSONB column (BE-EP-008).
