# Flintkeep: game design

**One line:** an endless fortress defense for phones. Hold a central Keep against goblin
raiders, build a castle around it ring by ring during the run, and research permanent upgrades
between runs so the next one goes further.

**Setting:** flintlock fantasy. Muskets, cannons and rifle nests alongside arcane spires, set
at night, with glowing shots and magic. We chose it because fantasy does
far better than sci-fi on the mobile top-grossing charts, and few mobile games use the
gunpowder-and-magic mix.

All numbers live in `godot/core/defs.gd` (runs) and `godot/core/research.gd` (research).
This document explains the intent; the code is the source of truth for values.

## Look and feel

Casual cartoon, built for a two-inch screen and a player who glances: every object reads from
its silhouette alone.

- **Sprites:** chunky shapes in a 3/4 top-down view, two or three flat colour bands per surface
  (light left, base, shadow right), a thick dark-brown outline around each silhouette, and a
  glossy white highlight in the same top-left spot on every object. Saturated colours: lavender
  stone, red, blue and green roofs, orange wood, cyan and violet crystals, green goblins.
- **Battlefield:** a sunny checkered meadow with grass tufts and flowers, a sandy courtyard that
  is strongest at the Keep and fades out past the outer wall, and trodden paths along each ring.
- **Walls:** each ring's wall is one continuous white-stone ring with outlined battlements.
  Hurt sections turn brown, and broken ones fall to rubble.
- **Slots:** stone foundations marked with a cross. They glow when you can afford a tower, and
  the tutorial bounces an arrow over the first one.
- **Gradients** fade from the source outward: the courtyard, a selected tower's range, and shot
  tracers (bright at the muzzle).
- **UI:** wood panels holding cream cards; glossy rounded buttons with a dark outline, a darker
  lip underneath and white outlined text; a blue sky behind the menus. Lilita One for titles,
  buttons and numbers; Fredoka (rounded) for everything else.
- **Sound:** soft pops, chimes and little bugle calls (not harsh chiptune), plus a bouncy
  music loop. Rapid-fire sounds are quieter and rate-limited so a big wave stays pleasant.

## Camera and depth

The battlefield is seen by a camera tilted about 50 degrees: the ground layer (grass,
courtyard, paths, range circles) is squashed vertically to 60%, while walls, pedestals,
towers, enemies and decorations are drawn upright and sorted back to front. Walls have
height with a lit face on the near side. It is still 2D (cheap on phones); the code is in
`game/battle_view.gd` (`proj()`) and `game/wall_drawer.gd`.

## Tower looks

Each weapon has three looks, one new detail per step: level 1 plain, level 5 adds a gold band
and a banner, level 10 adds a golden crown and a gem.

## Retention features

- **First-run tutorial:** five short tips: build a tower (with a pointer), what waves are,
  build a wall, upgrade, and spend coins in Research. Shown once.
- **Daily missions:** three goals a day picked from a pool (defeat enemies, shoot down flyers,
  reach a wave, build or upgrade towers, build walls, defeat a Juggernaut), sized to the
  player's best wave, each paying coins. The day is chosen by date, so the list is stable across
  restarts. The menu's Missions button turns green when one is ready to claim.
- **Offline earnings:** while the game is closed the garrison collects coins (6 + 2 x best
  wave x tier per hour, for up to 8 hours), shown on a "Welcome back" card.
- **Call the next wave early:** once a wave has finished arriving, the >> button starts the
  next one immediately and pays cash for the time skipped.

## The loop

1. **Defend (a run).** Tap DEFEND. Waves arrive every 24 seconds and never stop. Kills pay
   **cash** (spent only in this run) and a trickle of **coins** (kept forever). The run ends
   when the Keep falls, or when you retreat. Your score is the wave reached, with a best
   score per tier.
2. **Research (between runs).** Spend coins on permanent upgrades. Each takes real time in
   one of two labs and keeps running while the game is closed.
3. **Repeat.** Research makes the next run start stronger and go further, which pays more
   coins. Reaching wave 25 unlocks the next tier: tougher enemies, more coins.

Two time scales keep players coming back. A run is a 5–15 minute session (idle games
average about 8 minutes). Research timers are a reason to check back in a few hours.

## Currencies

| | Cash | Coins |
|---|---|---|
| Earned | every kill (grows 7.5% per wave) | kills (roughly a fifth of the cash) + a bonus each wave (wave number × multiplier) |
| Spent on | towers, walls, Keep upgrades, economy upgrades | research |
| Lasts | this run only | forever |

Coins are not a fixed ratio of cash. Cash has to grow very fast to keep up with upgrade
prices, so tying coins to it would break the research economy. Coins have their own formula
with their own multipliers (Coin Bounty during a run, Coin Bonus in research, and the tier
multiplier).

## The fortress

```
              . . . ring 4: 12 slots (every 30°)
          . . ring 3: 8 slots (every 45°)
        . ring 2: 6 slots (hexagon)
      ring 1: 4 slots (N, E, S, W)
          [ KEEP ]
```

- **The Keep** sits in the centre. It always shoots (cyan arcane bolts) and has its own
  upgrades: damage, fire rate, range, health, regen and armour. If it falls, the run ends.
- **Rings 1–4** hold build slots: 4 / 6 / 8 / 12, so 30 at most. Ring 1 is open from the
  start; rings 2–4 are unlocked by research, in order. Slots grow with ring size, so a new
  player has 4 decisions and a veteran has 30. We used 4 rather than 2 for ring 1 because
  enemies come from every side.
- **Towers stand on the walls.** Every slot is a stone pedestal on its ring's wall line, and
  the wall **sections are the arcs between neighbouring towers** (ring 1: N-E, E-S, S-W, W-N).
  Tap an arc to buy that section; the Walls tab can also buy all missing sections at once.
  Finishing every section of a ring **fortifies** it: +50% wall HP and +15% damage for that
  ring's towers. Ground enemies stop at the first built, intact section in their path and hack
  at it; gaps let them through. Walls can be reinforced (more HP, fully healed) or repaired.
  Flyers ignore walls.
- The camera starts close and zooms out once you have three rings, so the castle always
  fills the screen.

## Weapons (built in slots with cash)

| Weapon | Hits | Role | Unlock |
|---|---|---|---|
| Musket Tower | ground + air | cheap, steady | free |
| Cannon Battery | ground | splash damage | research |
| Volley Gun | air | shreds flyers | research |
| Rifle Nest | ground + air | long range, armour-piercing, targets the biggest enemy | research |
| Arcane Spire | ground + air | magic damage (ignores armour), chains to 2 more enemies | research |

Each tower levels up with cash: +32% damage, +4% fire rate and a little range per level.
Selling refunds half of what you spent on it.

**Weapon research:** the first level unlocks a weapon, and each level after that makes its
towers **start one level higher** and makes their in-run upgrades 4% cheaper (up to 50%).

## Enemies (goblin raiders)

| Enemy | From wave | Notes |
|---|---|---|
| Raider | 1 | the basic footman |
| Runner | 3 | fast, fragile |
| War Balloon | 5 | flyer; drops bombs on the Keep |
| Brute | 6 | armoured: blocks 50% of physical damage, so bring cannons or magic |
| Wyvern | 12 | fast flyer; warded: blocks 50% of magic |
| Sapper | 8 | carries a bomb: blows up against the first wall (or the Keep) and pays nothing |
| Shaman | 15 | heals raiders within reach by 4% of their health a second |
| Juggernaut | every 10th wave | boss: huge health, armour and ward |

Enemy health grows 11.5% per wave, damage 7% per wave. Each tier multiplies enemy stats
by 2.2× and coins by +75%.

## Damage types

Physical damage (muskets, cannons, rifles, the Keep) is reduced by **armour**; rifles pierce
60% of it. Magic damage (arcane) ignores armour but is reduced by **ward**. Mixing weapons
beats stacking one.

## Research (coins, in labs)

| Group | Items |
|---|---|
| Keep | damage, health, regen, fire rate |
| Economy | cash bonus, coin bonus, starting cash, Quartermaster (cheaper cash upgrades) |
| Arsenal | muskets, cannons, volley guns, rifle nests, arcane spires (unlock, then start level) |
| Fortress | second / third / fourth ring, masonry (wall HP) |

Prices grow about 1.55–1.8× per level and times about 1.45–1.55×, capped at 12 hours. Early
levels take seconds to minutes, so the first sessions feel quick.

## Balance targets (checked by `tests/test_balance.gd`)

- A brand-new player reaches about wave 12 (about 5 minutes) and earns enough coins for
  several early researches.
- A handful of research levels pushes that past wave 30. Mid-game research reaches 50+.
- Higher tiers end sooner for the same research.

`tools/balance.gd` prints waves and coins for several research setups; run it after
changing numbers.

## Not built yet (next steps)

- Several weapon mounts per tower (for example a cannon plus a rifle on one stone bastion).
- Ranged enemies that shoot towers, and towers that can be damaged.
- Offline earnings, cards or perks, cosmetics (tower skins), achievements.
- Gems (premium currency), ads or IAP, leaderboards.
- Store screenshots and adaptive Android icon layers.
