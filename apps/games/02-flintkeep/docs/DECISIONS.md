# Flintkeep: decisions log

Product and design decisions, newest first, with the reasons. The code is the source of truth for
numbers (`godot/core/upgrades.gd`, `defs.gd`, `workshop.gd`, `research.gd`, `perks.gd`, `powers.gd`).

## 0.4: performance, tower add-ons, a Towers tab

### Performance (late runs slowed to a crawl on an iPhone 15 Pro, even at 1x)

- **Measured first.** `tools/bench.gd` builds a wave-60 battle (three full rings of upgraded
  towers, 70 raiders) and times the simulation and the drawing separately. Drawing took ~37 ms
  a frame; the simulation 0.5 ms. So the fix was drawing, not game rules.
- **Nothing redraws every frame unless it moves.** Everything standing (wall pieces, towers, the
  Keep, bushes) is its own node under a y-sorted layer, so the engine sorts it, and it redraws
  only when it changes. Enemies are pooled sprites that only move. The ground redraws when the
  fortress or a selection changes.
- **Wall pieces are one mesh each.** A piece used to be dozens of polygons, outlines, battlement
  rectangles and spikes; three rings were ~6,500 draw commands a frame. Now ~200.
- **A bug that logged errors every frame:** the wall face polygon folded over itself where a
  ring runs up the screen, so Godot logged "triangulation failed" (and skipped the face) a
  couple of times a frame. Faces are now drawn as quads.
- **Effects are capped** (90 tracers, 24 floating numbers, 300 sparks; the oldest go first) and
  drawn as one mesh.
- **60 fps cap.** 120 Hz iPhones were drawing everything twice as often.
- **Result** on the benchmark (software renderer): 46.9 ms -> about 24 ms a frame. A phone's
  GPU does the remaining fill work much faster than the software renderer.

### Towers

- **Add-ons:** towers no longer get the Keep's critical hits, bounce and pushback for free. Each
  tower can buy **Critical hits, Multishot, Bounce and Pushback**; a tower with an add-on uses the
  Keep's values from the Attack tab. Price: the build price x 4 (crit), 8 (multishot, bounce)
  or 5 (pushback), x1.35 for every tower that already has that add-on.
- **Towers tab** (sixth tab): upgrade every tower one level, give an add-on to every tower (as
  many as cash allows, cheapest first), set targeting for all, and auto-buy.
- **Smaller outer rings:** ring 3 holds **6** towers (was 8) and ring 4 holds **8** (was 12).

### Balance after the change (simulated player, 3-4 seeds)

- Fresh profile waves 22-33; a light profile ~40; a mid profile ~490-550. Workshop levels add
  waves steadily past the first few (5 levels ~310, 10 ~320, 20 ~390, 30 ~450).



### Research and the workshop

- **Upgrades can be opened during a battle** (the **Lab** button on the battle bar). The battle
  keeps running behind it, and anything finished applies **immediately**: the battle reads the
  profile's research and workshop levels live, and a ring researched mid-run opens at once.
- **Workshop items can be bought or researched.** "Buy" is instant at full price. "Lab" costs
  **40%** of the price and takes lab time (90 s × 1.25 per level, capped at 12 h).
  - A workshop research can be **finished early with coins**: the rest of the difference to the
    full price, shrinking as the timer runs down.
  - **Any** research can be finished early with **gems**: one gem per 10 minutes left.

### Gems (premium currency, earned in play for now)

- **You start with one lab.** Slots 2, 3 and 4 cost **150, 500 and 1,500 gems**. Saves from
  before this change keep the two labs they had.
- **Earned (rarely):**
  - 2–3 gems per daily mission;
  - first-time milestones in each tier (wave 50, 100, 250, 500 and 1,000 pay 10, 20, 40, 80
    and 150);
  - a 15% chance from each Juggernaut.
- **Spent on:** lab slots, instant finishes, and re-rolling a perk choice (10 gems).
- **Later:** in-app purchases and ads are deliberately not built yet.

### Thorns

- **The first Thorns level is an expensive unlock** ($400; later levels are cheap).
- **It works on walls as well as the Keep:** anything hacking at a wall takes a share of the
  damage it deals.
- **It is visible:** walls grow iron spikes along their outer face, a ring of spikes appears
  around the Keep's foot, and red sparks fly when thorns bite.

### Look

- **Range rings are a solid line** with a subtle gradient: clear in the middle, a faint white
  haze growing towards a whitish edge. The Keep's ring is always shown.
- **The Keep throws yellow-orange firebolts** (hot core, orange trail), and its crystal is now an
  ember to match.
- **Towers sit flush on the walls:** walls are as tall as the tower pedestals (they were 2.5
  units lower, which made towers look perched above them).

### Music

- **Three tracks instead of one 34-second loop:** a calm menu theme (76 bpm), a battle theme
  with an A and a B section (112 bpm, about a minute), and a driving boss theme (132 bpm).
- **Adaptive:** a drum layer fades in as the run goes on and when the Keep is hurt, and the boss
  theme crossfades in while a Juggernaut is on the field.
- **Richer sound:** plucked-string lute arpeggios (Karplus-Strong), a detuned lead spread left
  and right, soft strings, bass, shaker, and a small reverb. The loops are seamless.
- **Still generated in code** by `tools/make_audio.py`, so it is free to change.
- **Size:** stereo WAVs in the repo, compressed (QOA) when imported, about 1.2 MB a track in
  the game.

### Balance

Simulated runs showed that, with the same research, one run would die at wave 12 and the next
would never end. Three causes were found and fixed:

- **Regeneration compounded on top of health.** It is a share of max health, but its upgrade
  multiplied itself every level (×1.1), so late runs healed thousands of times their health a
  second. Now each level adds 0.05% (up to 4%/s), and everything together is capped at 8%/s.
- **The run could keep up with the enemies.** The player fell behind by only ~0.7% a wave, so a
  good start lasted 900 waves and doubling your power was worth ~100 waves. Now:
  - enemies grow ~3.6% a wave late (`SCALE_C` 0.02 → 0.035), with a gentler start
    (`SCALE_A` 1.5 → 1.0, `SCALE_B` 10 → 20);
  - cash per kill grows with enemy strength to the power 0.45 (was 0.7);
  - Cash bounty and Cash per wave pay ×1.02 / ×1.025 a level (were ×1.03 / ×1.04) and cost
    ×1.16 (was ×1.15). Income upgrades that pay for themselves were the hidden runaway.
  - waves grow by 0.7 enemies a wave (was 1.2), so the first waves are less of a wall;
  - wyverns arrive at wave 15 (was 12) and are weaker (3 dps, was 5; slower), since they fly
    over walls and were ending most first runs.
- **Results** (simulated player, 4 seeds): fresh profile waves 32–36. Past the first few
  workshop levels each level adds a steady ~4 waves (10 levels ≈ 300, 20 ≈ 370), and runs with
  the same setup end within ±20 waves of each other. Nothing reaches wave 1,000 for ever.
- **Still to tune with real play:** a hump right after the start (3 workshop levels already
  reach ~280). The capped upgrades (crit, armour, multishot, bounce) add up to about ×100 once a
  run can afford them, which carries it a long way.
- **Each wall ring can be repaired once per wave.** Late in a run repairs had become cheap next
  to the cash income, so walls never fell: one simulated run reached wave 830 with 1,200
  raiders piled outside an untouched Keep. Now a heavy wave can break a wall, and
  reinforcing (+HP) and wall regeneration matter more.

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
