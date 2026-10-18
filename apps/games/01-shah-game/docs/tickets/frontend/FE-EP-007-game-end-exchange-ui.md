> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-006 — Card Exchange System](../epics/EP-006-card-exchange-system.md) (T-062–T-063) and [EP-007 — Game End, Rankings & Results](../epics/EP-007-game-end-rankings-results.md) (T-066) · [tickets.json](../tickets.json)

---

# FE-EP-007 — Game End, Rankings & Card Exchange UI

| Field | Value |
|---|---|
| **ID** | FE-EP-007 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P1 |
| **Status** | READY |
| **Depends On** | FE-EP-005 |
| **Blocks** | FE-EP-008 |
| **Estimated Effort** | M (3–5 days) |

---

## Description

This epic covers the end-of-game and inter-game experience: the rankings overlay that appears when a game ends, the card exchange animation and reveals, and the transition into the next game. It also covers the match-end state where all games are concluded and final aggregate standings are shown.

The end-of-game moment is emotionally significant — it should feel rewarding and clear, especially for the winner.

---

## Background & Motivation

The card exchange is a core feature of Shah Exchange and a key source of drama. Visualizing it — showing which cards move between players and who "gave up" to whom — creates a memorable moment. Getting this UX right reinforces the game's identity and ensures players understand the handicap system going into the next game.

---

## Goals

- End-of-game rankings overlay (who finished in what place)
- Card exchange breakdown: show what each pair of players gave/received
- Animation: cards visually "fly" between players during exchange
- Local player sees their updated hand before the next game
- "Next game" countdown timer or host-confirms flow
- Match-end summary: aggregate rankings across all games
- Graceful handling of the "last game" vs "more games" distinction

---

## Detailed Scope

### 1. Game Finished Overlay

Triggered by `game:finished` socket event.

**Layout:** Full-screen semi-transparent overlay on top of the (frozen) game board.

**Content:**
```
🏆  Game 3 Results

1st  🥇  Alice      (finished first)
2nd  🥈  Bob
3rd      Carol
4th  💀  Dave       (last place)

[Card Exchange beginning in 3...]
```

- Rank icons: 🥇 🥈 🥉 for top 3; skull/down arrow for last
- Current player highlighted
- Countdown timer before exchange begins (3 seconds) — gives time to read

**Animations:**
- Rankings slide in from bottom with stagger (1st first, then 2nd, etc.) using Framer Motion
- Trophy icon bounces for 1st place

### 2. Card Exchange Phase UI

After the countdown, the overlay transitions to show the exchange:

**Exchange Card UI:**
```
💫 Card Exchange

  Alice (1st)  ←  [K♠][A♥]   (receives from Dave)
  Alice (1st)  →  [3♣][4♦]   (gives to Dave)

  Bob (2nd)    ←  [Q♥]       (receives from Carol)
  Bob (2nd)    →  [5♠]       (gives to Carol)
```

**Animation:**
- Cards animate flying between player positions (use `layoutId` + absolute positioned cards)
- Given cards: fly from giver to receiver
- Color coding: positive (receiving good cards) vs negative (giving good cards)
- "Best" cards received: subtle gold shimmer
- Duration: ~1.5 seconds per exchange pair

**Local Player Perspective:**
- After exchange animation: "Your new hand" section shows updated cards
- Cards you gave are gone; new cards you received are highlighted (brief glow on new cards)

### 3. Next Game Transition

After exchange is shown:

**If more games are continuing:**
- "Next game starting in 5..." countdown
- All players see the same countdown (driven by the server or synchronized from GameService)
- No host action required — automatic is the default for v1.0
- At 0: overlay closes, `game:started` is emitted, board transitions to new deal animation

**Alternative (if desired): host confirms:**
- Add a "Start Next Game" button visible only to the host
- Others see "Waiting for host to start the next game..."
- (This is a product decision — flag for grooming)

### 4. Match Finished Screen (`/results/:matchId`)

Shown when `match:finished` event is received. Navigates all players to `/results/:matchId`.

**Content:**
- "Match Complete!" heading with the room code
- Aggregate scoreboard: each player + games won + average ranking
- Per-game breakdown (collapsible): who finished where in each game
- "Play again" button (creates a new match with the same players — room code changes, sends invites)
- "Return to lobby" button (back to `/lobby`)

**Layout:**
```
Match Complete!  Room: XJKQ  (5 games)

Player     1st  2nd  3rd  4th  Avg Rank
────────────────────────────────────────
Alice       3    1    0    1    1.8 🏆
Bob         1    2    1    1    2.4
Carol       1    1    2    1    2.6
Dave        0    1    2    2    3.2
```

Highlight the overall winner (best average rank, most 1st places as tiebreaker).

### 5. Edge Case: Only 1 Player Left

If 3 players finish and the last remaining player is the only one without a rank:
- They are automatically assigned last place
- `game:finished` is emitted with full rankings
- Normal end-game flow proceeds

### 6. "You Won!" Special Screen

If the local player is 1st place:
- A special full-screen celebration moment before the standard rankings overlay
- Brief confetti burst (full-screen, not just player position)
- Large "🏆 You won!" text
- Shrinks into the rankings overlay after 2 seconds

---

## Acceptance Criteria

- [ ] `game:finished` event triggers the rankings overlay
- [ ] Rankings are displayed in correct order (1st through last)
- [ ] Local player's position is visually highlighted
- [ ] Card exchange pairs are displayed clearly (who gave what to whom)
- [ ] Exchange cards animate between positions
- [ ] Local player's updated hand is shown after exchange
- [ ] Countdown timer counts down and triggers next game
- [ ] `match:finished` event navigates to `/results/:matchId`
- [ ] Match summary shows aggregate stats per player
- [ ] 1st place player (locally) sees the celebration screen
- [ ] "Return to lobby" button navigates correctly
- [ ] All animations respect `prefers-reduced-motion`

---

## Out of Scope

- Persistent win/loss statistics across sessions
- Leaderboards
- Social sharing of results

---

## Technical Notes

- The exchange animation is the most complex animation in the project. Use Framer Motion's `LayoutGroup` and `layoutId` to animate cards between their "giver's hand" and "receiver's hand" positions.
- The exchange summary data comes from the `game:exchange` socket event (type `ExchangeSummary` from the backend)
- Ensure the overlay is accessible: can be navigated with keyboard, rank info is in `aria-label` attributes, not just emoji
