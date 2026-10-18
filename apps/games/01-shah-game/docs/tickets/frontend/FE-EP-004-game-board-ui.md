> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-005 — Real-Time Game Play](../epics/EP-005-realtime-game-play.md) · [tickets.json](../tickets.json) → T-049–T-054

---

# FE-EP-004 — Game Board UI

| Field | Value |
|---|---|
| **ID** | FE-EP-004 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P0 — Critical Path |
| **Status** | READY |
| **Depends On** | FE-EP-001, FE-EP-002, FE-EP-003 |
| **Blocks** | FE-EP-005, FE-EP-006 |
| **Estimated Effort** | L (7–10 days) |

---

## Description

This is the central epic of the entire frontend: the game board screen where Shah Exchange is actually played. It renders the game table, all players' positions, the pile, the local player's hand, action controls, and game status. It needs to communicate the full game state clearly while handling the complex turn-based flow visually.

The game board must be intuitive without instructions: a player should understand whose turn it is, what is on the pile, and what actions they can take at any given moment.

---

## Background & Motivation

The game board is the player's primary environment during a match — they may spend 20–30 minutes on this screen per session. It must:
- Be clear and readable at a glance
- Communicate complex state (active player, pile, skip, pass counts) without overwhelming
- Facilitate quick decision-making (card selection + play/pass)
- Work at multiple screen widths (prioritize desktop; mobile is a stretch goal)

---

## Goals

- Full game board layout with all structural sections rendered
- Display opponent hand sizes (card backs, no values shown)
- Display the current pile prominently
- Local player's hand is fully interactive (card selection)
- Play button + Pass button with correct enabled/disabled states
- Turn indicator clearly highlights the active player
- Status bar shows game number, direction, round info
- Post-round and post-game transitional states
- All components are driven by `gameStore` (populated by WebSocket in FE-EP-005)

---

## Detailed Scope

### 1. Page Layout

The `/game/:matchId` page uses a full-viewport layout with no scrolling:

```
┌──────────────────────────────────────────────────────────┐
│  GameStatusBar: Game #2 | → Clockwise | Round 4          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│   [Opponent]    [Opponent]    [Opponent]                 │
│                                                          │
│              ┌─────────────────┐                        │
│              │   TABLE / PILE  │                        │
│              │   [Cards shown] │                        │
│              │    Pass: 2/4    │                        │
│              └─────────────────┘                        │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │         YOUR HAND (selectable cards)              │  │
│   └──────────────────────────────────────────────────┘  │
│          [PLAY SELECTED]       [PASS]                   │
└──────────────────────────────────────────────────────────┘
```

### 2. Component Breakdown

#### `<GameStatusBar>`
- Left: "Game 3 of ?" — displays current game number
- Center: Direction indicator (`→ Clockwise` or `← Counterclockwise`) with arrow icon
- Right: Round counter, active player name ("Alice's turn")

#### `<OpponentSection>`
Renders all non-local players in the appropriate seating positions:

```typescript
<OpponentSection players={opponentPlayers} activePlayerId={activePlayerId} />
```

Distributed around the top/sides of the table based on player count:
- 4 players: 1 opponent at top, 1 on left, 1 on right
- 5–6 players: distributed along top arc
- 7–8 players: denser distribution

#### `<OpponentHand>`
Per opponent:
- `<PlayerAvatar>` with display name
- Row of face-down `<Card>` components (count matches hand size)
- "Finished" badge if player has emptied hand (with rank: 1st, 2nd, etc.)
- "(passed)" text below if they passed this round
- Active turn: glowing outline or subtle pulse animation
- Skipped: slightly dimmed with "(skipped)" label

#### `<TableArea>`
Center of the screen — the game table:

**`<PileDisplay>`**
- If pile is empty: "Table clear — play anything" placeholder text
- If pile has cards: show the top play prominently
  - Display the set of cards (e.g., two Queen of Hearts overlapping)
  - Label: "Double Q" or "Single 7"
  - Show the suit icons for visual identification
- "Reset!" animation when a 2 resets the pile

**`<PassIndicator>`**
- Shows consecutive pass count: "Passed: 2 / 3" (2 of 3 other players passed)
- Visual progress dots

#### `<LocalPlayerHand>`
The critical interactive component:

```typescript
<LocalPlayerHand
  cards={hand}
  selectedCards={selectedCards}
  isMyTurn={isLocalPlayerTurn}
  pileTopPlay={pile.topPlay}
  onToggleCard={handleToggleCard}
/>
```

- Renders all cards in the local player's hand as `<Card>` components in a horizontal fan/row
- Cards are clickable when it is the local player's turn
- Clicking a card: adds/removes it from `selectedCards` in `gameStore`
- Card highlighting:
  - `selected`: raised, glowing border
  - `playable`: subtle green border (client-side hint: same rank or higher)
  - `not-playable`: slightly dimmed (wrong size or too low)
  - `disabled`: when it's not your turn, all cards are non-interactive

**Card Fan Layout:**
- Cards overlap with a slight arc effect for large hands
- Fan grows/shrinks as cards are played
- Smooth transition when cards leave the hand (Framer Motion)

#### `<ActionBar>`
Shown below the local player's hand:

```typescript
<ActionBar
  canPlay={isValidSelectionToPlay}
  onPlay={handlePlay}
  onPass={handlePass}
  isLoading={isActionPending}
  errorMessage={lastActionError}
/>
```

- **"Play" button:** green, prominent, enabled only when selected cards form a valid play (client-side pre-check only)
- **"Pass" button:** secondary style, always enabled on your turn
- **Loading state:** spinner on button when action is in-flight (awaiting server confirmation)
- **Error display:** inline error text when server rejects a play: "You must match the pile size" etc.
- **Not your turn:** entire ActionBar is hidden or shows "Waiting for [PlayerName]..."

### 3. Game Store (`src/store/gameStore.ts`)

```typescript
interface GameStore {
  gameState: GameState | null;
  localPlayerId: string | null;
  selectedCards: Card[];
  isActionPending: boolean;
  lastActionError: string | null;

  // Derived (computed from gameState)
  localPlayer: Player | null;
  isLocalPlayerTurn: boolean;
  activePile: Pile;

  // Actions
  setGameState: (state: GameState) => void;
  toggleCard: (card: Card) => void;
  clearSelection: () => void;
  setActionPending: (pending: boolean) => void;
  setActionError: (error: string | null) => void;
}
```

### 4. Client-Side Play Validation (UX Only)

Compute `isValidSelectionToPlay` as a derived value:
- `selectedCards.length > 0`
- All selected cards have the same rank
- Set size matches pile size (if pile active)
- Rank >= pile rank (if pile active, non-reset scenario)
- OR: selected cards are all rank `2` with correct count for a reset

This is purely for UX (enables/disables the Play button). Server does the real check.

### 5. Turn Highlight & Visual Feedback

- Active player (whoever's turn it is): bright outline around their avatar/hand
- If local player's turn: `<ActionBar>` becomes prominent, cards glow
- When a card is played by someone else: animate it flying to the pile
- When the round ends: brief "Round over!" overlay, then clear
- When a player finishes: confetti burst (subtle) + rank badge appears on their position

### 6. Finished Players Display

When a player empties their hand:
- Their hand area shows their rank badge: "🥇 1st", "🥈 2nd", etc.
- Cards are gone (hand area collapses or shows empty state)
- They are grayed out / marked as inactive in the seating layout

### 7. Skip Visual

When the skip rule triggers:
- A brief "SKIP!" flash overlay appears on the skipped player's position
- The active player indicator jumps over them

### 8. Disconnected Player Indicator

- If a player disconnects mid-game: their slot shows a "disconnected" overlay
- Game continues — they auto-pass until they reconnect (per backend rules)
- Toast notification: "[PlayerName] disconnected — auto-passing their turns"

---

## Acceptance Criteria

- [ ] Full game board renders with correct layout for 4–8 players
- [ ] Local player's hand is displayed with all their cards face-up
- [ ] Opponents' hands show correct card count as face-down backs
- [ ] Card selection toggles correctly; selected cards have visual distinction
- [ ] "Play" button is enabled only when selected cards are a valid play attempt
- [ ] "Pass" button is always enabled on the local player's turn
- [ ] During opponent's turn, cards are non-interactive and ActionBar shows waiting state
- [ ] Active player is visually highlighted (opponent positions + local hand)
- [ ] Pile displays the current top play correctly
- [ ] Empty pile displays "Table clear" state
- [ ] `<GameStatusBar>` shows correct game number, direction, and active player name
- [ ] Finished players display their rank badge
- [ ] Components correctly re-render when `gameStore.gameState` updates
- [ ] Snapshot/visual tests for major board components

---

## Out of Scope

- Animations and motion (FE-EP-006)
- WebSocket data integration (FE-EP-005) — use mock/stub gameStore data
- Card exchange UI (FE-EP-007)
- Chat or emotes

---

## Technical Notes

- Use a mock `GameState` object in development to work on the board UI without a backend
- Build a Storybook-style component showcase or a `?debug=true` URL param rendering a sample game state for rapid UI development
- The `<Card>` component built in FE-EP-001 is used extensively here — ensure it handles all sizes well
- Consider performance: with 8 players × up to 13 cards = 104 card components. Use `React.memo` on `<Card>` and `<OpponentHand>`.
