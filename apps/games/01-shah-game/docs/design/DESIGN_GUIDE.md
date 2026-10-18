# Shah Exchange — Design Guide

**Theme: Street Cards Chaotic**
A "party game UI" — loud cues, playful microcopy, juicy motion. Readable at a glance. Fun to play.

> Not casino luxury. Not corporate SaaS. Chaotic friend-group energy with just enough structure to stay playful.

---

## Design Principles

| Principle | What it means |
|---|---|
| **Fast readability** | Card rank and turn state must be obvious within 0.5 seconds |
| **Juicy feedback** | Every important event has a visual reaction (play, skip, reset, round win) |
| **Playful, not cringe** | Short, punchy labels. No corporate tone. Tasteful chaos |
| **Chaos with rules** | One palette, a limited effect set (glow, shake, pop). Consistent = trustworthy |

---

## 1. Color System

### Base Palette — Dark Street

| Token | Hex | Use |
|---|---|---|
| `--bg-0` | `#0B0B10` | Main app background |
| `--bg-1` | `#12121A` | Panels, trays, lobby cards |
| `--surface` | `#191926` | Raised cards, modals, dialogs |
| `--border` | `#2A2A3A` | Default borders (visible, game-like) |
| `--text-primary` | `#F4F4F8` | Primary readable text |
| `--text-muted` | `#A7A7B5` | Secondary text, hints, timestamps |

### Neon Accents — Chaotic but Controlled

| Token | Hex | Name | Use |
|---|---|---|---|
| `--neon-lime` | `#33FF7A` | Neon Lime | Your turn, selected cards, active rings |
| `--electric-yellow` | `#FFD400` | Electric Yellow | CTAs, room code, "winner" state |
| `--hot-pink` | `#FF3D9A` | Hot Pink | Event moments only: SKIP, 2♠ reset, round won |
| `--danger-red` | `#FF3B3B` | Danger Red | Invalid plays, error states, warnings |
| `--info-blue` | `#2E9BFF` | Info Blue | System info, direction arrows, passive indicators |

### Accent Usage Rules

- **Lime** → "your turn" ring, selected card outline, active states
- **Yellow** → primary CTAs ("Jump In", "Start the Madness"), room code display
- **Pink** → event moments only; not for navigation or persistent UI
- **Red** → errors and invalid states only; should feel alarming
- **Blue** → neutral info; never for interactable primary actions

---

## 2. Typography

### Font Stack

| Role | Font | Weight | Notes |
|---|---|---|---|
| Headings | **Space Grotesk** | 700 | Playful + modern balance |
| Body | **Inter** | 500 | Highly legible, pairs well |
| (Alt heading) | Bebas Neue | 400 | Very loud; pair with Inter body only |

All via Google Fonts. Load only the weights used.

### Scale (Tailwind-compatible)

```
xs   → 0.75rem  (12px) — room code labels, seat tooltips
sm   → 0.875rem (14px) — body, status text
base → 1rem     (16px) — default interactive text
lg   → 1.125rem (18px) — card rank display
xl   → 1.25rem  (20px) — player names, important labels
2xl  → 1.5rem   (24px) — section headings
4xl  → 2.25rem  (36px) — pile rank hero
6xl  → 3.75rem  (60px) — SKIP/event overlay text
```

---

## 3. Spacing & Radius

| Token | Value | Use |
|---|---|---|
| Radius small | `6px` | Chips, badges, small buttons |
| Radius default | `8px` (`rounded-lg`) | Cards, panels, buttons |
| Radius large | `12px` | Modals, dialogs |
| **No `rounded-2xl` or `rounded-3xl`** | — | Looks too corporate |

Borders: always `1px solid var(--border)` on raised surfaces. Borderless UI feels flat and game-less.

---

## 4. Visual Style — Sprites

### A) Playing Cards

```
Card face:   #F7F7FB (slightly off-white, not pure white)
Card border: 1px solid #D3D3E0
Corner rank: Bold, larger than standard playing card convention
Suit icons:  Simplified. Not ultra-detailed.
```

**States:**

| State | Treatment |
|---|---|
| Default | White face, subtle border |
| Hover | Slight lift (translateY -4px), scale 1.02 |
| Selected | Thick neon lime outline (3px), tilt +2°, lift -8px |
| Played | Scale down, translate to pile with spring easing |
| Invalid | Red flash, shake animation (see §6 Effects) |

### B) Player Seats

Style: sticker badge feel. Circle avatar, thick border.

**State Overlays (emoji/icon):**

| Seat State | Overlay | Border |
|---|---|---|
| Active (their turn) | None / subtle pulse | Neon lime glow ring |
| Thinking | ⏳ | Yellow |
| Just skipped someone | 😈 | Hot pink |
| Passed | 💤 | Desaturated, opacity 0.5 |
| Finished / out | 🏁 | Muted border |
| Leader | 👑 | Yellow |

**Layout feel:** arcade slot machine — inactive seats are clearly "not lit".

### C) Pile Area

- Hero element: largest visual on the game board
- Centered, always visible
- Shows top card(s) with slight fan/overlap effect
- Rank of top card displayed prominently in a hero number (`--text-4xl`, bold)
- Direction indicator (clockwise/counter) as an arrow icon, `--info-blue`

---

## 5. Effects (Juice Layer)

Keep effects consistent and small in number. Don't invent new ones mid-project.

| Effect | Trigger | Spec |
|---|---|---|
| **Glow** | Active turn, major events | `box-shadow: 0 0 12px 3px <neon-color>` |
| **Shake** | Invalid play, being skipped | x-axis ±4px, 3 cycles, 400ms total |
| **Pop** | SKIP, RESET, round winner | scale 0.8 → 1.15 → 1.0, spring easing |
| **Lift** | Card hover / selection | translateY -8px, scale 1.03 |
| **Confetti** | End of Game, match winner | One-time burst. Not for rounds. |
| **Pulse ring** | Active player seat | Looping glow pulse, 1.5s period |

---

## 6. SKIP! Global Animation Spec

### Trigger
A player matches the pile rank (same value play), causing the next player to be skipped.

### Full-Screen Overlay

```
Text:       "SKIP!"
Color:      #FF3D9A (Hot Pink)
Rotation:   random -4° to +4° per trigger
Font:       Space Grotesk 700, ~80px
Background: rgba(0,0,0,0.6) (darkens board)
```

**Timing:**

| Phase | Duration |
|---|---|
| Pop-in (scale 0.5 → 1.1 → 1.0) | 150ms (spring) |
| Hold | 300ms |
| Fade-out (opacity 1 → 0) | 450ms |
| **Total** | ~900ms |

**Microcopy (rotate randomly):**
```
"sit down 😭"
"no turn for you"
"get cooked"
"skipped like a stone 🪨"
"next time maybe 💅"
```

### Skipped Player Seat Effect
- Hot pink flash ring (see Glow spec, `--hot-pink`)
- Shake animation applied to seat element
- 400ms, then returns to normal passed state

### Optional Audio
Subtle "record scratch" or short airhorn clip. Volume: ≤40% of UI audio. Off by default, toggled in settings.

---

## 7. Other Event Animations

### 2♠ Reset (Pile Cleared)
```
Text:       "RESET!"
Color:      Hot Pink
Scale pop + shake on pile area
Pile cards briefly scatter (translateX random, fade) before clearing
Duration:   ~700ms
```

### Round Won / Shahf
```
Text:       "[Name] WINS!"
Color:      Electric Yellow (#FFD400)
Crown emoji 👑 animates down onto winner's seat
Confetti burst centered on their seat (not full screen)
Duration:   1500ms
```

### Card Exchange Phase (post-game)
```
Tone:       Slightly more solemn than gameplay
Indicator:  Arrow between shah and runt seats
Cards animate between seats (shared layout animation via Framer Motion)
Duration:   per card ~400ms
```

---

## 8. Microcopy — Friend-Group Voice

### Replace all corporate default text:

| Default / Corporate | Playful / Friend-Group |
|---|---|
| "Create Room" | "Start the Madness" |
| "Join Room" | "Jump In" |
| "Room Code" | "Code" |
| "Waiting for players…" | "Need X more chaos agents" |
| "Waiting for X…" | "X is plotting…" |
| "Your turn" | "Your move 👀" |
| "Invalid play" | "Can't do that" |
| "Game Over" | "That's a wrap 🎬" |
| "Round complete" | "Round done!" |
| "You have been skipped" | "You got cooked 😭" |
| "Card exchange" | "The Trade" |
| "Player passed" | "[Name] passed 💤" |
| "Connecting…" | "Loading the chaos…" |
| "Error" | "Something broke 💀" |

### Voice rules
- Short, punchy. If a label exceeds 4 words, cut it.
- Emoji: use sparingly and purposefully. Max 1 per label.
- No ALL CAPS except event overlays (SKIP, RESET, WINS).
- Never use "please" or "sorry" in UI labels (overly corporate). Use playful alternatives.

---

## 9. Layout Hierarchy

```
┌─────────────────────────────────────────┐
│  HEADER: Room info + player count       │
├──────────────┬──────────────────────────┤
│              │                          │
│  PLAYER      │   PILE AREA (hero)       │
│  SEATS       │   ← biggest element      │
│  (left/top)  │   Top card rank, large   │
│              │   Direction indicator    │
│              │                          │
├──────────────┴──────────────────────────┤
│  YOUR HAND (bottom, scrollable if wide) │
├─────────────────────────────────────────┤
│  ACTION TRAY: Play | Pass | (others)    │
└─────────────────────────────────────────┘
```

**Constraints:**
- Pile area must never be obscured
- Action tray: always bottom-center, buttons large enough for a thumb (min 44px height)
- Your hand: cards fan slightly on mobile, row on desktop
- Player states must be legible without hovering

---

## 10. Animation Library

**Primary:** Framer Motion (already in stack)

| Feature | Framer Motion API |
|---|---|
| Card hover/selection | `whileHover`, `whileTap` |
| Card snap to pile | `layoutId` shared layout animation |
| Event overlays (SKIP etc.) | `AnimatePresence` + `motion.div` |
| Turn indicator pulse | `animate` with looping keyframes |
| Seat state transitions | `animate` prop |
| Confetti | `framer-motion` + custom particle system or `canvas-confetti` |

**React Spring** (optional, v2+): only if card hand fanning/drag interaction is built. Not needed for v1.

---

## 11. Tailwind CSS v4 Configuration Notes

Tailwind v4 uses CSS-first config. Add tokens directly in your global CSS:

```css
/* src/index.css */
@theme {
  --color-bg-0: #0B0B10;
  --color-bg-1: #12121A;
  --color-surface: #191926;
  --color-border: #2A2A3A;
  --color-text-primary: #F4F4F8;
  --color-text-muted: #A7A7B5;
  --color-neon-lime: #33FF7A;
  --color-electric-yellow: #FFD400;
  --color-hot-pink: #FF3D9A;
  --color-danger-red: #FF3B3B;
  --color-info-blue: #2E9BFF;

  --font-family-heading: 'Space Grotesk', sans-serif;
  --font-family-body: 'Inter', sans-serif;

  --radius-sm: 6px;
  --radius-default: 8px;
  --radius-lg: 12px;
}
```

Use these in components as `bg-bg-0`, `text-neon-lime`, etc.

---

## 12. ShadCN/UI Component Overrides

Override the default ShadCN theme in `components.json` and `globals.css` to match the Dark Street palette:

- `background` → `--bg-0`
- `foreground` → `--text-primary`
- `card` → `--surface`
- `primary` → `--neon-lime`
- `destructive` → `--danger-red`
- `border` → `--border`
- `ring` → `--neon-lime`
- `radius` → `8px`

All ShadCN components should feel consistent with the game surfaces. If a component looks "too SaaS", override its variant or replace it with a custom game component.
