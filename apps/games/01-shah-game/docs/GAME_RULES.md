# 🃏 The Shah Exchange` Game (Official Rules Spec v1.0)

This document defines the complete ruleset for a multiplayer card game played using a standard deck of playing cards.  
It is written as a developer-friendly specification for implementation.

---

## 1. Game Overview

- **Deck:** Standard 52-card deck (no jokers)
- **Players:** 3 to 8
- **Goal:** Get rid of all cards in hand before everyone else
- **Game Flow:** Multiple Games can be played in a Match session
- **Core Mechanics:**
  - Singles / Doubles / Triples / Quads
  - Passing
  - Skip turn when same value is played
  - Power card `2` resets the pile and extends turn
  - Round ends when all players pass
  - End-of-game ranking determines card exchange for next game
  - Winner starts next game
  - 2nd place determines direction (clockwise vs counterclockwise)

---

## 2. Terminology

### 2.1 Match
A **Match** is a session containing multiple full Games.

Example:
- "We played a match of 12 games."

---

### 2.2 Game
A **Game** starts when cards are dealt and ends when all players have emptied their hands.

A Game determines:
- 1st place
- 2nd place
- ...
- last place

After a Game ends, a **card exchange** happens before the next Game begins.

---

### 2.3 Round
A **Round** is a phase of play where there is an active pile on the table (single/double/triple/quad).

A Round ends when:
- all players pass consecutively, OR
- a valid reset occurs via a `2`

When a Round ends:
- the pile is cleared
- the last player who played wins the Round and starts the next Round immediately

---

## 3. Card Ranking

### 3.1 Standard Rank Order (Low → High)

`3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A`

### 3.2 Special Card: 2
- `2` is a **power card**
- it is not treated as a normal card for beating higher ranks
- it is used only for reset mechanics (see Section 10)

---

## 4. Player Count & Dealing Rules

Shuffle the deck and deal evenly.

| Players | Cards Each | Discarded Cards |
|--------|------------|----------------|
| 3      | 17         | 1 |
| 4      | 13         | 0 |
| 5      | 10         | 2 |
| 6      | 8          | 4 |
| 7      | 7          | 3 |
| 8      | 6          | 4 |

Discarded cards are removed face-down and do not participate in the game.

---

## 5. Objective

A player finishes when their hand reaches `0 cards`.

Ranking is determined by finish order:
- First player to finish = 1st place
- Second player to finish = 2nd place
- ...
- Last remaining player = last place

Game ends only when all players finish.

---

## 6. Turn Order and Direction

### 6.1 First Game Start Player
In the first Game of a Match, the starting player is chosen randomly.

### 6.2 Next Games Start Player
In all subsequent Games, the starting player is the **winner (1st place)** of the previous Game.

### 6.3 Direction Rule (Clockwise / Counterclockwise)

At the start of each Game:
- Winner of previous Game sits at an assumed reference position ("12 o'clock").
- The player who finished **2nd place** determines direction based on seating:

If the 2nd place player is seated:
- on the winner’s **right side** → direction is **clockwise**
- on the winner’s **left side** → direction is **counterclockwise**

Direction remains fixed for the entire Game.

---

## 7. Valid Plays

Players may play sets of cards of equal rank.

### 7.1 Allowed Set Sizes
- **Single:** 1 card
- **Double:** 2 cards (same rank)
- **Triple:** 3 cards (same rank)
- **Quad:** 4 cards (same rank)

Examples:
- single 7
- double K
- triple 4
- quad A

---

## 8. Starting a Round

If the pile/table is empty, the active player may start the Round with any valid play:

- any single
- any double
- any triple
- any quad

---

## 9. Continuing a Round (Beating the Pile)

If there is an active pile on the table, the next player must either:

### 9.1 Play a Valid Set
To play a valid set, a player must:

#### Rule A: Match the pile size
The set size must match the current pile size.

- single must be beaten by single
- double must be beaten by double
- triple must be beaten by triple
- quad must be beaten by quad

#### Rule B: Match or beat the rank
The rank must be >= current pile rank.

Example:
- pile: double 9
- valid: double 9, double 10, double Q, double A

### 9.2 Pass
If the player cannot play or chooses not to play, they may pass.

---

## 10. Skip Rule (Playing Same Rank)

If a player plays the **same rank** as the current pile (same value, same set size):

- the next player's turn is skipped

Applies to:
- singles
- doubles
- triples
- quads

Example:
- pile: single 8
- player plays: single 8
- next player: skipped

Example:
- pile: double Q
- player plays: double Q
- next player: skipped

---

## 11. Passing & Round End Rule

### 11.1 Passing
A player may pass voluntarily or because they cannot play.

### 11.2 Ending a Round
A Round ends when all players pass consecutively (no one can beat the pile).

### 11.3 Winning a Round
The last player who played a valid set before everyone passed is considered the Round winner.

### 11.4 Next Round Start
The Round winner immediately starts the next Round (pile resets/clears).

---

## 12. Power Card Rule: 2 (Reset Mechanic)

The card rank `2` is a power card that can reset the pile.

When a valid reset occurs:
- the pile clears immediately
- the current player's turn is extended
- the same player may play again immediately (start a new Round)

---

### 12.1 Reset Requirements by Pile Size

| Current Pile Type | Required Reset Play |
|------------------|---------------------|
| Single           | single 2 |
| Double           | single 2 |
| Triple           | double 2 |
| Quad             | triple 2 |

Examples:
- pile: single 10 → single 2 resets
- pile: double K → single 2 resets
- pile: triple 7 → double 2 resets
- pile: quad 9 → triple 2 resets

---

### 12.2 Multiple 2s Usage
A player may play multiple `2`s one by one (if available).

Each `2` continues resetting the pile.

The player may then choose to play any valid set after the final reset.

---

### 12.3 Turn Extension Rule
Whenever a player plays a valid reset using `2`, their turn continues.

They must be allowed to immediately play again after the reset.

---

## 13. Winning the Game

A player is considered finished when their hand becomes empty.

They no longer take turns, but rankings continue until all players finish.

---

## 14. End of Game Card Exchange

After the Game ends, players exchange cards based on ranking.

### 14.1 1st and Last Place Exchange
- 1st place gives **two worst cards** to last place
- last place gives **two best cards** to 1st place

### 14.2 2nd and Second-Last Exchange
- 2nd place gives **one worst card** to second-last
- second-last gives **one best card** to 2nd place

### 14.3 Definition of Best/Worst Cards for Exchange
For exchange purposes, "best" means strongest strategic cards, where `2` is considered extremely valuable.

Suggested ranking for exchange evaluation:

Worst → Best:
`3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2`

---

## 15. Game State Requirements (Implementation Notes)

### 15.1 Required State Variables
An implementation should track:

- list of players
- current direction (clockwise / counterclockwise)
- current active player index
- player hands (list of cards)
- current pile:
  - pileRank (3..A)
  - pileSize (1..4)
- consecutivePassCount
- finishedPlayers list (ranking order)
- gameStartPlayer (winner of previous game or random)

### 15.2 Round Reset Conditions
A Round reset occurs if:
- consecutivePassCount == (number of active players - 1)
- OR a valid `2` reset is played

When reset occurs:
- pile is cleared
- consecutivePassCount resets to 0
- Round winner becomes active player

---

## 16. Summary (Short Rules)

- Players must match the pile size (single/double/triple/quad)
- Players must play same rank or higher
- Playing same rank skips next player
- Players may pass
- If everyone passes, last player wins the Round and starts again
- `2` resets the pile and extends the turn
- Game ends when all players finish
- Winner starts next game
- 2nd place chooses direction based on seating position
- Rankings determine card exchange

---
