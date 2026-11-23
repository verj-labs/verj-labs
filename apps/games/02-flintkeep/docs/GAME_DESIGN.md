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

- Smooth vector art in a 3/4 top-down view, lit from the top left: round stone towers with
  roofs and weapons on top, goblin raiders, and a stone Keep with a glowing arcane crystal.
- Each ring's wall is one continuous stone ring with battlements. Hurt sections darken and
  broken ones fall to rubble.
- Empty build slots are stone foundations marked with a cross. They glow softly when you can
  afford a tower. Tap one to choose what to build; tap a tower to upgrade or sell it.
- Gradients are strongest at the source and fade outwards: the courtyard (darkest at the Keep,
  fading into the grass past the outer wall), a selected tower's range, and each shot's tracer
  (bright at the muzzle, fading towards the target).
- Interface: rounded walnut panels with brass trim and parchment text. Cinzel for titles,
  Barlow for numbers and everything you read while playing.

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
- **Walls:** each ring can be walled for cash. A wall is split into one section per slot.
  Ground enemies stop at the first intact section in their path and hack at it; once it
  breaks they march to the next ring in, or to the Keep. Walls can be reinforced (more HP,
  fully healed) or repaired. Flyers ignore walls.
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

- Sound and music (chiptune, generated like the Shah Exchange redesign).
- Several weapon mounts per tower (for example a cannon plus a rifle on one stone bastion).
- Ranged enemies that shoot towers, and towers that can be damaged.
- Daily missions, offline earnings, cards or perks, cosmetics.
- Gems (premium currency), ads or IAP, leaderboards.
- Settings (reset progress, sound toggles) and a short tutorial for the first run.
- Store screenshots and adaptive Android icon layers.
