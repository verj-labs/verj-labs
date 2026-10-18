> **⚠️ Superseded — Reference Only**
> Epics are now feature-based (not BE/FE split). This file is retained for supplementary frontend detail.
> **Replaced by:** [EP-007 — Game End, Rankings & Results](../epics/EP-007-game-end-rankings-results.md) (animations — T-067) · [tickets.json](../tickets.json)

---

# FE-EP-006 — Card Interactions & UX Polish

| Field | Value |
|---|---|
| **ID** | FE-EP-006 |
| **Type** | Epic |
| **Team** | Frontend |
| **Priority** | P1 |
| **Status** | READY |
| **Depends On** | FE-EP-004, FE-EP-005 |
| **Blocks** | None |
| **Estimated Effort** | M (4–6 days) |

---

## Description

This epic transforms the functional game board (FE-EP-004 + FE-EP-005) into a polished, delightful experience. It covers all animations, micro-interactions, sound design hooks, and UX refinements that make the game feel alive: cards dealing from a deck, played cards flying to the pile, the pile clearing on a reset, and satisfying visual feedback for every action.

---

## Background & Motivation

A technically correct game can still feel flat without good UX. The card game genre has established conventions (animated deals, card transitions) that players expect. These animations also serve a functional purpose: they communicate game logic visually (e.g., seeing the pile clear on a reset is more communicative than just text).

---

## Goals

- Smooth card dealing animation at game start (cards "fly" to each player)
- Card play animations: selected cards fly from hand to pile
- Pile reset animation: cards scatter/disappear on reset
- Skip animation: visual flash on the skipped player
- Round-end animation: pile clears back to the winner
- Hand card fan/reorder animations as cards are played
- Turn indicator transitions (smooth highlight movement between players)
- Sound design hooks (play sound file stubs — actual audio is a stretch goal)
- Accessibility: all animations respect `prefers-reduced-motion`
- Mobile-responsive card layout adjustments

---

## Detailed Scope

### 1. Framer Motion Integration

All animations use Framer Motion (`motion` components + `AnimatePresence`).

Key animation patterns to implement:

**Card Deal Animation (game start):**
- Cards start at center (deck position) with opacity 0 and scale 0.5
- Each card flies to its assigned player position with a stagger delay
- Local player's cards flip face-up after landing
- Duration: ~800ms total with stagger

**Card Play Animation:**
- When the local player clicks "Play":
  - Selected cards lift slightly (translateY) on selection
  - On play confirmation from server: cards animate from hand position to pile center
  - Use `layoutId` on cards for FLIP animations so Framer Motion calculates the path
- When an opponent plays: a stack of face-down cards slides from their position to the pile, then flips face-up

**Pile Reset Animation:**
- When `game:pile_reset` is received:
  - Pile cards briefly shake/pulse
  - Then burst/scatter outward and fade out
  - "RESET!" text overlay appears briefly over the pile

**Round End Animation:**
- All pile cards briefly hover, then fly to the round winner's position
- Winner's avatar gets a brief gold outline pulse

**Skip Animation:**
- Skipped player's hand and avatar get a brief "crossing out" effect (red X or strikethrough flash)
- "SKIPPED" badge appears for 1.5 seconds then fades

**Player Finish Animation:**
- When a player empties hand:
  - Their position gets a confetti burst (subtle, on-position only)
  - Rank badge (`🥇 1st`) slides in with spring animation
  - Hand area smoothly collapses

**Turn Indicator:**
- Active player highlight uses a spring-animated border that morphs between player positions
- Smooth enough that it's clear who is active but not distracting

### 2. Hand Layout Improvements

**Card Fan:**
- Cards are displayed in an overlapping fan with slight rotation
- Cards count-based spacing: fewer cards = wider spread; many cards = tighter overlap
- Selected card: translateY(-20px) + brighter border
- Hover (desktop): card peeks up slightly

**Card Reordering:**
- When cards are removed from hand (after play), remaining cards smoothly redistribute
- Use `AnimatePresence` for exit animations, `layout` prop for reflow

**Playability Hints:**
- Cards that form a valid play with the current pile get a subtle green pulsing border
- Cards that cannot be played (wrong rank/size) when pile is active get a slight opacity reduction
- When it's not your turn, entire hand has reduced opacity

### 3. Table Area Polish

**Pile Visual:**
- Cards in the pile are displayed with a slight overlap and shadow layering
- Most recently played set is displayed prominently on top
- Pile "depth" grows visually as more plays are made within a round

**Pass Indicator:**
- Progress bar of dots (one per active player) fills as consecutive passes accumulate
- When the round ends (all pass), the bar completes with a transition

### 4. Sound Design Hooks

Create `src/lib/sounds.ts` with a sound manager:

```typescript
type SoundEffect =
  | 'card_play'
  | 'card_deal'
  | 'card_select'
  | 'pile_reset'
  | 'round_end'
  | 'player_finish'
  | 'turn_change'
  | 'invalid_play';

class SoundManager {
  play(effect: SoundEffect): void;
  mute(): void;
  unmute(): void;
  isMuted: boolean;
}
```

Wire up calls to `sounds.play()` at appropriate game events. Audio files themselves are stubbed (empty or placeholder MP3s) for v1.0 — actual sound design is a future task. Provide a mute toggle in the game UI header.

### 5. `prefers-reduced-motion` Support

Wrap all Framer Motion variant definitions with a check:

```typescript
const shouldReduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const cardPlayVariant = shouldReduceMotion
  ? { opacity: [0, 1] }               // instant, no translate
  : { x: [startX, endX], y: [startY, endY], opacity: [0, 1] };
```

All animations must have reduced-motion fallbacks that still communicate the state change (e.g., fade instead of fly).

### 6. Mobile Layout Adjustments

While the primary target is desktop, ensure:
- `<LocalPlayerHand>` scrolls horizontally on narrow viewports
- `<OpponentHand>` cards scale down gracefully
- `<ActionBar>` stacks vertically on very narrow screens
- `<PileDisplay>` remains readable at small sizes
- Touch events on cards work (tap to select)

### 7. Loading & Skeleton States

While game state is loading (initial socket join, reconnect):
- Show a skeleton layout of the game board (shadcn `<Skeleton>` components)
- Prevent interaction until state is populated
- "Connecting..." overlay if socket is not yet connected

---

## Acceptance Criteria

- [ ] Card dealing animation plays at the start of each game
- [ ] Card play animation fires when a play is confirmed by the server
- [ ] Pile reset animation fires on `game:pile_reset` event
- [ ] Skip animation fires on `game:player_skipped` event
- [ ] Player finish animation and rank badge fire on `game:player_finished`
- [ ] Hand cards reflow smoothly after cards are removed
- [ ] Turn highlight transitions smoothly between players
- [ ] Valid playable cards have a visual hint (green border)
- [ ] Non-playable cards are visually dimmed when pile is active
- [ ] All animations degrade gracefully with `prefers-reduced-motion`
- [ ] Sound hooks are called at the right moments (even with silent stubs)
- [ ] Mute toggle works
- [ ] Hand is horizontally scrollable on narrow viewports
- [ ] No animation causes layout jank (no CLS)

---

## Out of Scope

- Full audio production / mastered sound effects
- 3D card flip effects (too complex for v1.0)
- Particle systems or complex shader effects
- Custom card back designs (use a simple pattern)

---

## Technical Notes

- Use Framer Motion's `layoutId` feature for card FLIP animations — do not hand-calculate positions
- Keep animation durations under 500ms for game actions (don't make the game feel slow)
- Profile with React DevTools to ensure animation performance is smooth
- `AnimatePresence` must wrap card lists — without it, exit animations won't fire
