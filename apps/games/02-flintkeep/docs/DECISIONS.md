# Flintkeep: decisions log

Product and design decisions, newest first, with the reasons. The code is the source of truth for
numbers (`godot/core/upgrades.gd`, `defs.gd`, `workshop.gd`, `research.gd`, `perks.gd`, `powers.gd`).

## 0.2: progression rework (for a long, idle-friendly run)

### The goal: a run you can leave running

- **Waves go to 1,000** (`Defs.MAX_WAVE`). After wave 1,000 the last wave repeats until the
  Keep falls or the player retreats. (10,000 was considered and dropped as too long.)
- **The game should play itself:** players put the phone down while the towers keep fighting
  and levelling. That drove auto-buy, auto-cast powers and the perk timer below.
- **Game speed is researched:** 1x at the start; the labs' *Game speed* research unlocks 2x,
  3x, 4x and 5x, one level each.

### Why the old balance hit a wall around wave 10-20

- Enemy health grew 11.5% a wave, while cash income allowed only about 9% a wave of player
  growth. Every run fell behind by about 7-8% a wave, whatever you did.
- Research added flat percentages to that losing curve (+15% damage was worth about 1 wave).
- Research that raised a tower's starting level also raised its upgrade prices (upgrades were
  priced by level), so it often made runs harder.

### The new curve

- **Enemy strength is one smooth curve**, `Upgrades.enemy_scale(wave)`: steep for the first
  waves, then a steady ~2% a wave. Health uses it directly, enemy damage `^0.97`, and cash
  per kill `^0.7`.
- **Tiers are the same curve, raised:** tier N multiplies every enemy's health by 2.2^(N-1)
  (damage by its square root), so the shape stays the same and only sits higher. Tier N also
  pays more coins.
- **The rule that keeps runs finite:** every in-run upgrade gets pricier faster than it gets
  stronger (tested in `test_prices_grow_faster_than_effects`), and income upgrades much faster.
  So a run's power grows a little slower than the enemies and every run eventually ends.
  How far it gets is decided by what you bring in.
- **What you bring in multiplies:** workshop levels compound (×1.08 per level), and research
  unlocks weapons, powers, rings, speed and *Siege lore*, which slows enemy growth itself.
  Multipliers matter more the later the wave, because the curve flattens there.
- **Tower upgrade prices count only levels bought in the run**, so starting higher from
  research is never a penalty.
- **Bugs found while tuning:** stats that scaled with *enemy* health made the Keep immortal,
  so they were changed:
  - **Thorns** now hand back a share of the damage taken (not a share of the attacker's
    health).
  - **Lifesteal** heals only from the Keep's own shots, counting only damage that lands.
  - **Pushback** works at most once every 2 seconds per enemy.
  - **Wall regeneration** is capped at 3% a second.
  - **Cash-per-wave** used to grow exactly as fast as its price, which made cash explode
    (10^16 by wave 300).

### Currencies

- **Coins every wave:** a few (2 at the start), raised by the Economy tab's new *Coins per
  wave* upgrade. They replace the old "wave number × coins" payout, which grew too fast.
  Coins per kill and offline earnings remain.

### Workshop and labs (the "Upgrades" screen)

- **Workshop (new):** instant permanent stat upgrades for coins. They are deliberately
  expensive (150-300 coins to start, +16-20% a level) and compound: Keep damage, health,
  regeneration, fire rate, critical chance, tower damage, cash bonus, starting cash and masonry.
  The stat research from 0.1 moved here, and old saves keep their levels.
- **Labs (timed):** game speed, Siege lore, coin bonus, Quartermaster, weapons, powers and
  rings.

### Battle panel: five tabs, two-column cards

| Tab | Upgrades |
|---|---|
| Attack | damage, fire rate, range, critical chance, critical damage, multishot, bounce (max 80%), pushback chance (max 80%), pushback distance |
| Defense | health, regeneration, armour, absolute defense, thorns, lifesteal (max 5%) |
| Walls | per-ring build all / repair / +HP, wall regeneration |
| Economy | cash bounty, coin bounty, cash per wave, coins per wave, interest |
| Powers | Arrow Rain, Freeze, Thunderstorm, Golden Hour: cast, or switch each to auto |

- Every upgrade tab has an **Auto-buy** switch: it buys the cheapest affordable upgrade in that
  tab every half second. On the Walls tab it builds missing sections and repairs.
- Critical hits, multishot, bounce and pushback apply to every shot (Keep and towers).

### Perks

- **Every 50 waves** (`Defs.PERK_EVERY`) the player picks one of three perks for the rest of the
  run. If nobody chooses within 20 seconds, one is **picked at random** and the game carries on.
  (Every 10 waves was too often; every 100 was too rare for 1,000 waves.)

### Fortress layout

- **Rings 1 and 2 have four towers each.** Ring 1 is an **X** (diagonals), so no tower hides
  behind the Keep; ring 2 is a **plus** (N, E, S, W). Rings 3 and 4 have 8 and 12.

### Feedback and quality of life

- The **Keep's range is always shown** (soft fill, dashed edge).
- **Critical-hit numbers**, a **boss health bar**, a "**New enemy**" warning the first time each
  type arrives, and **screen shake** on blasts, boss kills and powers.
- **Targeting per tower:** First, Strongest, Closest or Flyers.
- **Run report:** share of damage by source and what broke the Keep.
- **Bigger tap targets** for towers and wall arcs, and a short vibration on taps and purchases.

### Still to do

- Finer balance: the simulated player shows the curve has a "cliff". Runs that survive the
  first ~25 waves tend to go far. A longer tuning pass with real play data should smooth it, so
  that each workshop and lab level adds a predictable number of waves.
- Store assets, release signing, monetisation (gems, optional ads).

## 0.1

- Endless fortress defense with the Keep, four rings, buyable wall sections between towers,
  research labs, daily missions, offline coins, tilted pseudo-3D view, casual-cartoon art.
  See `GAME_DESIGN.md`.
