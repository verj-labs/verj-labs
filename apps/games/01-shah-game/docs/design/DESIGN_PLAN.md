# Shah Exchange — Design Improvement Plan

**Document type:** Implementation plan
**References:** [DESIGN_GUIDE.md](./DESIGN_GUIDE.md)
**Theme:** Street Cards Chaotic

---

## Objective

Transform the current UI from a functional-but-plain scaffold into a chaotic, juicy, friend-group game UI — while keeping the codebase maintainable and tests green.

This plan is broken into 6 phases. Each phase is independently shippable. Start phases sequentially but tasks within a phase can be parallelized.

---

## Scope Map (Existing Components)

| File | Phase |
|---|---|
| `src/index.css` + `src/App.css` | Phase 1 (foundation) |
| `src/main.tsx` | Phase 1 (fonts) |
| `components/ui/button.tsx` (shadcn) | Phase 1 (overrides) |
| `components/ui/card.tsx` (shadcn) | Phase 1 (overrides) |
| `pages/LandingPage.tsx` | Phase 2 (microcopy + layout) |
| `pages/LobbyPage.tsx` | Phase 2 (microcopy + layout) |
| `pages/RoomPage.tsx` | Phase 2 (waiting room layout) |
| `pages/GamePage.tsx` | Phase 3 (game board layout) |
| `components/ui/PlayingCard.tsx` | Phase 3 (card visuals) |
| `components/ui/PileDisplay.tsx` | Phase 3 (pile hero) |
| `components/ui/SeatSlot.tsx` | Phase 3 (player seat) |
| `components/ui/LocalPlayerHand.tsx` | Phase 3 (hand layout) |
| `components/ui/OpponentHand.tsx` | Phase 3 (opponent hand) |
| `components/ui/ActionBar.tsx` | Phase 3 (action tray) |
| `components/ui/PassIndicator.tsx` | Phase 3 (pass state) |
| `components/ui/GameStatusBar.tsx` | Phase 3 (header) |
| `components/ui/LoadingSpinner.tsx` | Phase 2 (microcopy) |
| `components/ui/ConnectionBanner.tsx` | Phase 2 (microcopy) |
| `features/game/CardExchangeView.tsx` | Phase 4 (exchange animation) |
| `features/game/GameFinishedOverlay.tsx` | Phase 4 (event overlay) |
| _(new)_ `features/game/SkipOverlay.tsx` | Phase 4 (SKIP animation) |
| _(new)_ `features/game/ResetOverlay.tsx` | Phase 4 (RESET animation) |
| _(new)_ `features/game/RoundWonOverlay.tsx` | Phase 4 (round win) |

---

## Phase 0 — Audit (Before Any Code)

**Goal:** Understand what exists before overwriting. Short audit, not a blocker.

### Tasks

- [ ] Read `src/index.css` — note any existing CSS variables already defined
- [ ] Read `src/App.css` — identify and plan removal of any clashing styles
- [ ] Check `components.json` — confirm shadcn theme keys present
- [ ] Check `vite.config.ts` — confirm fonts plugin or static import approach
- [ ] Check `package.json` — confirm `framer-motion` is already installed
- [ ] Note all hardcoded color values in components (grep for `#`, `text-white`, `bg-gray`)

**Deliverable:** Short audit note added to `docs/tasks/todo.md`.

---

## Phase 1 — Design Foundation

**Goal:** Tokens, fonts, global styles, and ShadCN overrides land in one coordinated change. Nothing visually changes except background and font. No components broken.

### 1.1 — Google Fonts

**File:** `index.html` (frontend root)

Add font preconnects and imports:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
```

### 1.2 — CSS Design Tokens

**File:** `src/index.css`

Replace or extend existing CSS variables with the full Dark Street palette (see DESIGN_GUIDE §1 and §11). Set font-family defaults:

```css
@theme {
  /* Base palette */
  --color-bg-0: #0B0B10;
  --color-bg-1: #12121A;
  --color-surface: #191926;
  --color-border: #2A2A3A;
  --color-text-primary: #F4F4F8;
  --color-text-muted: #A7A7B5;

  /* Neon accents */
  --color-neon-lime: #33FF7A;
  --color-electric-yellow: #FFD400;
  --color-hot-pink: #FF3D9A;
  --color-danger-red: #FF3B3B;
  --color-info-blue: #2E9BFF;

  /* Typography */
  --font-family-heading: 'Space Grotesk', sans-serif;
  --font-family-body: 'Inter', sans-serif;

  /* Radius */
  --radius-sm: 6px;
  --radius-default: 8px;
  --radius-lg: 12px;
}

body {
  background-color: var(--color-bg-0);
  color: var(--color-text-primary);
  font-family: var(--font-family-body);
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-family-heading);
  font-weight: 700;
}
```

### 1.3 — ShadCN Theme Override

**File:** `src/index.css` (inside `:root` and `.dark` blocks)

Map ShadCN's CSS variables to the game palette:
```css
:root {
  --background: #0B0B10;
  --foreground: #F4F4F8;
  --card: #191926;
  --card-foreground: #F4F4F8;
  --popover: #191926;
  --popover-foreground: #F4F4F8;
  --primary: #33FF7A;
  --primary-foreground: #0B0B10;
  --secondary: #191926;
  --secondary-foreground: #F4F4F8;
  --muted: #12121A;
  --muted-foreground: #A7A7B5;
  --accent: #FFD400;
  --accent-foreground: #0B0B10;
  --destructive: #FF3B3B;
  --border: #2A2A3A;
  --input: #2A2A3A;
  --ring: #33FF7A;
  --radius: 8px;
}
```

### 1.4 — Global Utility Classes

**File:** `src/index.css`

Add reusable game utilities:
```css
.neon-glow-lime {
  box-shadow: 0 0 12px 3px #33FF7A66;
}
.neon-glow-pink {
  box-shadow: 0 0 12px 3px #FF3D9A66;
}
.neon-glow-yellow {
  box-shadow: 0 0 12px 3px #FFD40066;
}
```

### 1.5 — ShadCN Button Variant

**File:** `components/ui/button.tsx`

Ensure the `default` variant uses `--primary` (lime) correctly. Add a `cta` variant for yellow CTAs:
```typescript
cta: 'bg-electric-yellow text-bg-0 font-heading font-bold hover:brightness-110',
ghost: 'text-text-muted hover:text-text-primary hover:bg-surface border border-border',
```

### Acceptance Criteria — Phase 1
- [ ] App background is `#0B0B10`, not white or default grey
- [ ] Headings render in Space Grotesk
- [ ] Body text renders in Inter
- [ ] ShadCN `Button` default is lime green
- [ ] No existing tests broken (`pnpm test` passes)

---

## Phase 2 — Pre-Game Screens

**Goal:** Landing, Lobby, and Room pages receive layout, microcopy, and visual treatment. Game screen not touched yet.

### 2.1 — LandingPage.tsx

**Target file:** `pages/LandingPage.tsx`

Changes:
- Background: `bg-bg-0`
- Game title: Space Grotesk 700, large, `text-neon-lime` accent on "Shah"
- CTA buttons:
  - "Start the Madness" — yellow CTA variant, large
  - "Jump In" — lime default variant, large
- Minimalist layout: logo/title centered, two big buttons below
- Remove any placeholder or default ShadCN card wrappers that look SaaS-y

### 2.2 — LobbyPage.tsx

**Target file:** `pages/LobbyPage.tsx`

Changes:
- "Create Room" → "Start the Madness"
- "Join Room" → "Jump In"
- Room code input: large font, bold, monospace feel, `border-electric-yellow`
- "Room Code" label → "Code"

### 2.3 — RoomPage.tsx (Waiting Room)

**Target file:** `pages/RoomPage.tsx`

Changes:
- Room code: large, yellow, monospace, easy to read-aloud
- Player list: sticker badge slots (preview of SeatSlot component style)
- "Need 2 more chaos agents" style dynamic count
- "Waiting for players…" removed
- "Start Game" button: large lime CTA, disabled state clearly muted — not just greyed
- "Back to Lobby" → small ghost button

### 2.4 — LoadingSpinner + ConnectionBanner

**Files:** `components/ui/LoadingSpinner.tsx`, `components/ui/ConnectionBanner.tsx`

- Loading text: "Loading the chaos…" with lime spinner
- Reconnecting banner: use `--danger-red` background, "Connection lost — reconnecting…"

### Acceptance Criteria — Phase 2
- [ ] Landing page renders in dark theme with Space Grotesk headings
- [ ] Lobby CTAs are lime/yellow variants, no default blue/grey
- [ ] Room code is prominently displayed in yellow
- [ ] Waiting room shows "Need X more chaos agents" phrasing
- [ ] `pnpm test` still passing

---

## Phase 3 — Game Board

**Goal:** The main game screen becomes the "Street Cards Chaotic" experience. This is the highest-impact phase.

### 3.1 — GamePage.tsx Layout

**Target file:** `pages/GamePage.tsx`

Implement the layout hierarchy from DESIGN_GUIDE §9:
```
┌─────────────────────────────────────────┐
│  GameStatusBar (header)                 │
├──────────────┬──────────────────────────┤
│  Opponents   │   PileDisplay (hero)     │
│  SeatSlots   │                          │
├──────────────┴──────────────────────────┤
│  LocalPlayerHand                        │
├─────────────────────────────────────────┤
│  ActionBar                              │
└─────────────────────────────────────────┘
```
Use CSS Grid (`grid-rows`, `grid-cols`) on the outer container. Pile area must take at least 40% of the viewport width.

### 3.2 — PlayingCard.tsx

**Target file:** `components/ui/PlayingCard.tsx`

Visual overhaul:
- Card face: `#F7F7FB` background, `1px solid #D3D3E0` border
- Corner rank: bold, `lg` font size
- Suit: simplified SVG or unicode, not emoji
- State handling:
  - `selected`: `3px solid #33FF7A` outline, `rotate-1`, `translateY-8px` — all via Framer Motion `whileTap`/`animate`
  - `hover` (desktop): `translateY-4px`, `scale-1.02`
  - `invalid` flash: red glow + shake (see effects)
  - `played`: scale and translate to pile using `layoutId`

Use `data-testid="card-{rank}{suit}"` on the root element.

```typescript
// Motion props pattern:
<motion.div
  layoutId={`card-${rank}${suit}`}
  whileHover={{ y: -4, scale: 1.02 }}
  animate={selected ? { y: -8, rotate: 1.5, scale: 1.03 } : { y: 0, rotate: 0, scale: 1 }}
  transition={{ type: 'spring', stiffness: 400, damping: 25 }}
>
```

### 3.3 — PileDisplay.tsx

**Target file:** `components/ui/PileDisplay.tsx`

- Centered hero element
- Top card rank: `text-4xl font-bold` using Space Grotesk
- Top 2–3 cards visible with slight fan/offset
- Direction indicator: arrow icon, `text-info-blue`
- Empty state: dashed border circle, "Play to start the pile" muted text
- Add `data-testid="pile-top"` to the rank display

### 3.4 — SeatSlot.tsx

**Target file:** `components/ui/SeatSlot.tsx`

Arcade slot treatment:
- Circle avatar, thick border (2px default, 3px active)
- State borders:
  - Active: `border-neon-lime` + `neon-glow-lime` class
  - Passed: `opacity-50`, desaturated
  - Skipped: brief hot-pink flash ring (via Framer Motion)
- State overlay emoji (inside small badge, absolute positioned top-right):
  - Active turn: none, just the glow
  - Thinking: ⏳
  - Just skipped: 😈 (2s then clears)
  - Passed: 💤
  - Out/finished: 🏁
  - Leader/Shah: 👑
- Card count badge: bottom of avatar, small pill

Add `data-testid="seat-{playerId}"`.

### 3.5 — LocalPlayerHand.tsx

**Target file:** `components/ui/LocalPlayerHand.tsx`

- Cards displayed in a horizontal row, scrollable on small screens
- Slight fan effect on mobile (optional): cards overlap with z-index stagger
- Selected cards lift and glow (driven by `PlayingCard` state props)
- "Your move 👀" banner when it is the local player's turn (lime highlight strip)

### 3.6 — ActionBar.tsx

**Target file:** `components/ui/ActionBar.tsx`

- Always bottom-center
- Min button height 44px (accessible touch target)
- "Play" button: lime, large, disabled when no card selected
- "Pass" button: ghost / muted, never competes with Play
- Button labels updated per microcopy guide
- No more than 3 items visible at once — overflow into a `...` menu if needed

### 3.7 — GameStatusBar.tsx

**Target file:** `components/ui/GameStatusBar.tsx`

- Room code: small, yellow, top-right
- Round number: top-left, muted text
- Game/round status ("Round 2 of 5", "Game 2") — concise

### 3.8 — PassIndicator.tsx

**Target file:** `components/ui/PassIndicator.tsx`

- Replace with SeatSlot state (💤 + opacity) rather than separate banner if possible
- If kept as a banner: short, punchy "[Name] passed 💤", appears 1s then fades

### Acceptance Criteria — Phase 3
- [ ] Game board uses grid layout with pile as hero element
- [ ] Cards have correct visual states (selected, hover, default)
- [ ] Player seats show correct states (active, passed, skipped)
- [ ] All `data-testid` attributes present for E2E tests
- [ ] Layout is not broken on 1280×800 (common laptop resolution) or 375×812 (iPhone)
- [ ] `pnpm test` passing

---

## Phase 4 — Animation & Event Overlays

**Goal:** The juice layer. Framer Motion animations, event overlays, and the SKIP! experience.

### 4.1 — Verify Framer Motion Installation

```bash
cd 01-shah-game/frontend
pnpm list framer-motion
# if missing:
pnpm add framer-motion
```

### 4.2 — SKIP! Overlay

**New file:** `features/game/SkipOverlay.tsx`

```typescript
// Props: { skippedPlayerName: string; phrase: string; visible: boolean }
// Render inside AnimatePresence

<AnimatePresence>
  {visible && (
    <motion.div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: { duration: 0.45 } }}
    >
      <motion.div
        style={{ rotate: randomRotation, color: '#FF3D9A' }}
        initial={{ scale: 0.5, opacity: 0 }}
        animate={{ scale: [0.5, 1.15, 1.0], opacity: 1 }}
        transition={{ duration: 0.15, type: 'spring', stiffness: 600 }}
        className="font-heading font-bold text-7xl select-none"
      >
        SKIP!
        <p className="text-xl mt-2 text-center">{phrase}</p>
      </motion.div>
    </motion.div>
  )}
</AnimatePresence>
```

Phrases pool: `["sit down 😭", "no turn for you", "get cooked", "skipped like a stone 🪨", "next time maybe 💅"]`

Auto-dismiss after 900ms. Trigger from `gameStore` via an event queue (not raw state).

### 4.3 — RESET! Overlay

**New file:** `features/game/ResetOverlay.tsx`

Similar to SkipOverlay:
- Text: "RESET!"
- Color: `--hot-pink`
- Add brief pile-card scatter animation (cards translateX ±30px + fade out with stagger)
- Duration: 700ms

### 4.4 — Round Won Overlay

**Update file:** `features/game/GameFinishedOverlay.tsx`

When a round ends:
- Winner name + "WINS!" in `--electric-yellow`
- 👑 animates down onto the winner's seat using `layoutId` or `motion.div`
- `canvas-confetti` or Framer Motion particle burst on their seat (not full screen)
- Duration: 1500ms, then auto-close

When the full game ends:
- Full screen "Game Over" treatment
- Rankings listed with rank badges (1st = 👑 yellow, last = 🦆 muted)
- "That's a wrap 🎬" heading

### 4.5 — Card Exchange Animation

**Update file:** `features/game/CardExchangeView.tsx`

- Exchange cards animate between shah and runt seats using Framer Motion `layoutId`
- Each card: `~400ms`, stagger 200ms if multiple
- Visual context: both seats visible, directional arrow between them
- Tone: slightly more deliberate, less chaotic than gameplay

### 4.6 — Turn Indicator Pulse

**Update file:** `components/ui/SeatSlot.tsx`

For active seat: add pulsing lime ring using:
```typescript
<motion.div
  animate={{ boxShadow: ['0 0 6px 2px #33FF7A44', '0 0 14px 5px #33FF7A99', '0 0 6px 2px #33FF7A44'] }}
  transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
/>
```

### Acceptance Criteria — Phase 4
- [ ] SKIP! overlay appears and disappears within ~900ms when triggered
- [ ] Overlay uses random phrase from pool
- [ ] RESET! overlay appears when pile resets
- [ ] Round won shows winner name in yellow with 👑
- [ ] Card exchange animates smoothly between seats
- [ ] Active player seat has pulsing lime glow
- [ ] No animation jank on 60fps (Chrome DevTools check)

---

## Phase 5 — Microcopy Pass

**Goal:** Every user-facing string aligned with the friend-group voice guide.

### Systematic Search & Replace

Run a full-text search for each term and update all occurrences:

| Find | Replace |
|---|---|
| `"Create Room"` | `"Start the Madness"` |
| `"Join Room"` | `"Jump In"` |
| `"Room Code"` | `"Code"` |
| `"Waiting for"` | `"placeholder"` (manual review) |
| `"Your turn"` | `"Your move 👀"` |
| `"Invalid play"` | `"Can't do that"` |
| `"Game Over"` | `"That's a wrap 🎬"` |
| `"Round complete"` | `"Round done!"` |
| `"Player passed"` | `"[Name] passed 💤"` |
| `"Connecting"` | `"Loading the chaos…"` |
| `"Error"` | Context-dependent; review individually |

### Microcopy Constants File

**New file:** `src/lib/copy.ts`

Centralise all UI copy into one typed constants file:
```typescript
export const COPY = {
  createRoom: 'Start the Madness',
  joinRoom: 'Jump In',
  roomCodeLabel: 'Code',
  yourTurn: 'Your move 👀',
  waitingForPlayers: (needed: number) => `Need ${needed} more chaos agent${needed !== 1 ? 's' : ''}`,
  playerThinking: (name: string) => `${name} is plotting…`,
  playerPassed: (name: string) => `${name} passed 💤`,
  invalidPlay: "Can't do that",
  gameOver: "That's a wrap 🎬",
  roundDone: 'Round done!',
  connecting: 'Loading the chaos…',
  disconnected: 'Connection lost — reconnecting…',
} as const;
```

Import and use `COPY.*` everywhere instead of string literals.

### Acceptance Criteria — Phase 5
- [ ] `src/lib/copy.ts` exists and is used in all user-facing string outputs
- [ ] No hardcoded "Create Room", "Join Room", "Waiting for…" strings remain in TSX files
- [ ] All tests that assert on microcopy strings updated to use `COPY.*`

---

## Phase 6 — Polish & QA

**Goal:** Cross-device smoke test, performance check, and final visual consistency pass.

### 6.1 — Responsive Smoke Test

Test on these viewports:
- 375×812 (iPhone 12 / SE)
- 768×1024 (iPad portrait)
- 1280×800 (MacBook 13")
- 1920×1080 (desktop)

Critical checks:
- Card hand doesn't overflow / truncate without scrollability
- Pile is always visible above the hand
- Action bar buttons are always reachable
- SKIP overlay is readable on small screens

### 6.2 — Animation Performance

- Open Chrome DevTools → Rendering → FPS meter
- Play a round, trigger SKIP, RESET, round-win
- Target: no sustained drop below 55fps during transitions
- Common fix: add `will-change: transform` to animated card elements

### 6.3 — Accessibility Baseline

- All interactive elements have `aria-label` or visible text label
- Focus ring visible (use lime ring via `focus-visible:ring-neon-lime`)
- Color is never the only way to convey information (state text labels alongside colors)
- `data-testid` attributes present on all key game elements

### 6.4 — E2E Visual Smoke Run

With both servers running, trigger the Playwright smoke tests:
```bash
cd 01-shah-game/e2e
pnpm test -- --grep @smoke
```
Confirm no tests broken by UI changes (selector drift). Fix any `data-testid` mismatches.

### Acceptance Criteria — Phase 6
- [ ] Game playable on mobile (375px width) without horizontal scroll on the game board
- [ ] No layout issues at 1280×800
- [ ] FPS stays above 55 during all animations
- [ ] All `@smoke` E2E tests pass
- [ ] No TypeScript errors (`pnpm build` in frontend succeeds)

---

## New Files Summary

| File | Phase | Description |
|---|---|---|
| `docs/design/DESIGN_GUIDE.md` | — | The design system reference |
| `docs/design/DESIGN_PLAN.md` | — | This file |
| `src/lib/copy.ts` | 5 | Centralised UI copy constants |
| `features/game/SkipOverlay.tsx` | 4 | SKIP! full-screen event overlay |
| `features/game/ResetOverlay.tsx` | 4 | RESET! pile-clear overlay |

## Modified Files Summary

| File | Phase | Changes |
|---|---|---|
| `index.html` | 1 | Google Fonts link tags |
| `src/index.css` | 1 | Design tokens, ShadCN overrides, utility classes |
| `components/ui/button.tsx` | 1 | `cta` variant, ghost variant |
| `components/ui/card.tsx` | 1 | Token-aligned defaults |
| `pages/LandingPage.tsx` | 2 | Layout + microcopy |
| `pages/LobbyPage.tsx` | 2 | Microcopy + CTA variants |
| `pages/RoomPage.tsx` | 2 | Waiting room text + room code display |
| `components/ui/LoadingSpinner.tsx` | 2 | Copy + color |
| `components/ui/ConnectionBanner.tsx` | 2 | Copy + error color |
| `pages/GamePage.tsx` | 3 | Grid layout |
| `components/ui/PlayingCard.tsx` | 3 | Full visual overhaul + Framer Motion |
| `components/ui/PileDisplay.tsx` | 3 | Hero styling + data-testid |
| `components/ui/SeatSlot.tsx` | 3+4 | Arcade slot style + pulse animation |
| `components/ui/LocalPlayerHand.tsx` | 3 | Hand layout + turn indicator |
| `components/ui/ActionBar.tsx` | 3 | Touch-target sizing + microcopy |
| `components/ui/GameStatusBar.tsx` | 3 | Compact header |
| `components/ui/PassIndicator.tsx` | 3 | Inline into SeatSlot if possible |
| `features/game/GameFinishedOverlay.tsx` | 4 | Round won + game over treatment |
| `features/game/CardExchangeView.tsx` | 4 | Exchange animation |

---

## Dependencies & Risks

| Risk | Mitigation |
|---|---|
| Framer Motion `layoutId` conflicts if same card appears in hand and pile | Use unique layout IDs: `card-hand-{id}` vs `card-pile-{index}` |
| CSS custom property naming collision with ShadCN defaults | Audit existing `:root` variables before Phase 1 write |
| Test assertions on text content break after microcopy changes | Move to `data-testid` selectors in Phase 5; update affected tests |
| Google Fonts load time | Use `display=swap`, preconnect tags, and consider self-hosting for production |
| Animation performance on lower-end Android devices | Use `transform` only (no layout-triggering properties), add `will-change` judiciously |

---

## Execution Order Recommendation

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
```

Phases 2–4 can partially overlap once Phase 1 tokens are stable. Phase 5 (microcopy) can be done as a quick sweep at any point after Phase 2 establishes the pages.

The single biggest visual impact, in order:
1. **Phase 1** (dark theme, fonts) — transforms every screen instantly
2. **Phase 3.2–3.3** (PlayingCard + PileDisplay) — game board becomes recognisable
3. **Phase 4.2** (SKIP! overlay) — the signature chaotic moment
