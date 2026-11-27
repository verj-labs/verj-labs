# Flintkeep: balancing guide

How to check the game's balance, what "balanced" means here, and the rules that keep it that
way. Read this before adding an upgrade, an enemy, a hero, a perk or a research item, or before
changing any number in `godot/core/`.

The decisions log (`DECISIONS.md`) says *why* the current numbers are what they are; this guide
says *how* to measure and change them safely.

## 1. What balanced means

A run is endless in principle, but it must **always end**, and **what you bring in decides how
far you get**:

1. **Every run ends.** The enemies must out-grow anything a run can buy. A run that never ends
   (or stalls with hundreds of raiders piled up) is a bug, however strong the setup.
2. **Progress is steady.** Each workshop or lab level should add a predictable number of waves.
   A big jump between two neighbouring setups is a *cliff* and feels random to players.
3. **Runs are repeatable.** The same setup should end within a few percent of the same wave on
   different seeds. A setup that dies at wave 12 on one seed and 800 on another is broken.
4. **New players get a fair start.** A fresh profile should reach the 30s; light research the
   40s; tiers unlock at wave 100, so tier 2 is a goal for players with some research.

### Current targets (simulated player, 4 seeds, tier 1)

| Profile (`tools/balance.gd`) | What it is | Waves reached now |
|---|---|---|
| `fresh` | nothing researched | 28–32 |
| `early` | a few workshop levels, cannon unlocked | 32–42 |
| `mid` | ~20 workshop levels, ring 2, some labs | ~450 |
| `late` | most research | 1,000 (the cap) |

Workshop ladder (`tools/ladder.gd`, light research): 0 → ~30, 3 → ~42, 5 → ~250, 10 → ~300,
20 → ~350, 30 → ~430. Past wave 250, runs end just after a returning champion (every 50th wave),
so the ladder climbs in 50-wave steps: each champion is a gate. **Known issue:** the jump between
3 and 5 levels (about 40 → 250) is the one cliff left.

If your change moves these numbers, either it was meant to (write down why in `DECISIONS.md`)
or it needs tuning.

## 2. The tools

Run everything from `godot/` (the project folder). Set `GODOT_BIN` if `godot` is not on your PATH.

```bash
# The balance report: waves reached per profile, 4 seeds each
godot --headless --path . -s ../tools/balance.gd -- [fresh early mid late] [seeds=4] [tier=1] [hero=captain] [cap=1000] [seconds=60]

# The workshop ladder: waves per workshop level (looks for cliffs)
godot --headless --path . -s ../tools/ladder.gd -- [levels=0,3,5,10,20,30] [seeds=3]

# Try changes side by side without touching the project (copies, run in parallel)
python3 ../tools/sweep.py --variant "" --variant "upgrades.SCALE_C=0.04" -- fresh mid seeds=3
python3 ../tools/sweep.py --variant 'defs~"warlord": \{"hp": 450\.0~"warlord": {"hp": 600.0' -- mid

# Frame time in a crowded late battle (needs a window; xvfb-run works on Linux)
godot --path . --resolution 540x1170 -s ../tools/bench.gd -- [enemies=70] [day=night]

# The tests, including tests/test_balance.gd (a fresh run ends in minutes, upgrades push runs
# much further, higher tiers are harder)
../test.sh
```

How to read them:

- **`N+`** means the run was still alive when the time limit hit (`seconds=`). Below the wave
  cap that is a **runaway or a stall**: find out why before anything else (see section 4).
- `late` reaching the cap (1,000) is fine: it is the maximum setup.
- Look at the **spread** across seeds, not just the average. 401/451/451 is fine;
  12/280/290 is a cliff.
- `sweep.py` edits are `FILE.CONST=VALUE` (a `const` in `godot/core/FILE.gd`) or
  `FILE~REGEX~REPLACEMENT` (for dictionary entries such as enemy stats). Separate several edits
  in one variant with `;`. Always include `""` as the baseline in the same sweep: the
  simulation is deterministic per seed, so compare like with like.

The **AutoPlayer** (`core/auto_player.gd`) is a greedy bot: it builds, buys the cheapest
weighted upgrade, casts powers and the hero ability. It plays worse than a good player and
better than a careless one, which makes it a fair yardstick. **If you add something a player
can buy, teach the AutoPlayer to buy it too**, or the balance runs will not see it.

## 3. The rules that keep runs finite

These came from real bugs (see `DECISIONS.md`). Break one and runs stop ending.

1. **Enemies out-grow the run by a clear margin.** Enemy strength is one curve,
   `Upgrades.enemy_scale(wave)` = `exp(A·ln(1 + w/B) + C·w)`: steep early (A, B), then
   ~`C` a wave. A run's power grows roughly as `cash^0.78` and cash as `enemy_scale^0.45`
   (`cash_scale`), so the run falls behind by about **2% a wave** late. Below ~1% a wave, a good
   start lasts hundreds of waves (the old cliff). Change `SCALE_C` or the cash exponent only
   with a sweep.
2. **Prices grow faster than effects.** Every in-run upgrade's price growth must beat its effect
   growth (`test_prices_grow_faster_than_effects`). Income upgrades (bounty, cash per wave)
   need a much bigger margin, because income buys more income: at x1.03 / x1.04 a level they
   made cash grow almost as fast as the enemies.
3. **Shares of something that grows must be capped.** Anything that is a percentage of a
   growing number (regeneration of max health, thorns, lifesteal) must be an additive upgrade
   with a maximum, and capped in total. Regeneration that compounded on top of health once
   healed thousands of times the Keep's health a second.
4. **Never scale a defence with enemy health.** Thorns hand back a share of the damage taken,
   lifesteal heals from damage dealt by the Keep only: not shares of enemy health, which grows
   with the curve.
5. **Walls must be breakable.** Anything that restores walls has to leave a way through:
   broken sections regrow as rubble that raiders walk through and only block again at 50%
   health, and they do not regrow while raiders stand on them. Paid repairs were removed for
   the same reason: cheap late repairs made walls unbreakable and runs stalled.
6. **Bounded add-ons.** Capped upgrades (crit chance, armour, multishot, bounce) add up to a big
   one-time multiplier. That is what carries runs from ~40 to ~250 (the known cliff), so do not
   add more capped multipliers without checking the ladder.
7. **Visual systems never touch the rules.** Day and night, effects and art are cosmetic, so a
   player choosing a time of day cannot change the balance.

## 4. Checklist for new content

**A new upgrade / research / workshop item**
- [ ] Price growth > effect growth (and much more for income).
- [ ] Percentages of growing numbers are additive and capped.
- [ ] The AutoPlayer knows about it (`WEIGHTS`, `ADDON_WEIGHTS` or an option in `_buy_one`).
- [ ] `balance.gd` and `ladder.gd` before and after; numbers within the targets above.

**A new enemy**
- [ ] Stats relative to existing ones (health, damage per second, speed, armour, ward, cash).
- [ ] An entry in `Defs.ENEMY_ROSTER`: arrival wave on a wave ending in 5 (never with a boss),
      or a tier lock; or a champion slot. The schedule tests will check it.
- [ ] Art (`tools/make_art.py`), `Art.WIDTH` / `Art.FOOT`, bestiary text.
- [ ] `balance.gd` with the profiles that reach its arrival wave.

**A new hero, perk or power**
- [ ] Passive bonuses are multipliers of at most ~10–15%; abilities have cooldowns.
- [ ] The AutoPlayer uses it (`cast_hero`, `cast`, perk choice).
- [ ] `balance.gd -- mid hero=NAME` against no hero: it should help, not double the run.

**Any change**
- [ ] `../test.sh` passes (it includes balance tests).
- [ ] Spread across seeds is still small; no `N+` below the cap.
- [ ] The new numbers and the reason go in `DECISIONS.md`; update the targets in section 1 here.

## 5. When a run never ends: how to find out why

Every runaway so far was found the same way. Write a short probe that plays one stuck seed and
prints, every 50 waves: the Keep's damage against an enemy's health, the Keep's health against
an enemy's damage per second, regeneration, cash per wave, enemies alive and what they are
doing (`attacking` -1 marching, 0 the Keep, 1–4 a wall), and the upgrade levels. Then look for:

- **Enemies piling up while the Keep stays at full health:** something blocks them for ever
  (walls that cannot break, pushback with no cooldown).
- **Regeneration far above maximum health, or thorns/lifesteal larger than the damage taken:**
  an uncapped share (rule 3) or a defence scaling with enemy health (rule 4).
- **Cash growing faster than enemy health:** an income upgrade compounding (rule 2).
- **Player power falling behind by less than ~1% a wave:** the curve margin is too small (rule 1).

Fix the cause, add a test that would have caught it, and rerun the report.
