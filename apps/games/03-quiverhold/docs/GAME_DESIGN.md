# Quiverhold: game design

**One line:** a base-building survival strategy game where your economy makes the ammunition your
defences fire. Build anywhere on an open map, expand toward resources, and keep the supply lines
running when the horde comes.

**Pitch:** *Your walls are only as strong as your supply lines.* An archer tower with no arrows is
a wooden post. Every lumber camp, fletcher and carrier is part of the defence, and every step
toward a rich resource field is a longer road to protect.

**Platform:** PC first (Steam), mouse and keyboard. Made in Godot 4.7 like Flintkeep. A console or
mobile port is a later question, only if the PC version sells.

**Price (planned):** US$14.99 to 19.99 in Early Access.

**Steam tags (planned):** Colony Sim, City Builder, Base Building, Survival, RTS, Strategy, Resource
Management, with Tower Defense as a secondary tag. **Not** "Open World Survival Craft": that tag
means a third-person explorer-crafter (Valheim), a different audience. See
[`MARKET_RESEARCH.md`](MARKET_RESEARCH.md).

Numbers in this document are starting values to tune in the prototype, not final balance. Once
code exists, the code is the source of truth for values, as in Flintkeep.

---

## 1. Inspirations and what we take from each

| Game | What we take | What we leave |
|---|---|---|
| Command & Conquer / Red Alert | Build anywhere inside a build radius; the base itself is the strategy; a harvest-and-power economy; the feeling of a base under siege | Unit control, unit micro, multiplayer |
| Surviving the Aftermath | A survival settlement on an open map; scarcity; expansion to resource spots | Colonist needs and moods; the city-survival focus (we focus on defence) |
| They Are Billions | Horde waves and a final siege on a map of about an hour or two; walls and towers against huge numbers | Towers that fire forever without supply |
| Factorio | Production chains; seeing items move; defences fed by the factory | Conveyor belts and factory scale (we stay a settlement, not a factory) |
| Thronefall | Simple to learn; a clean, readable look | Its minimal economy |

## 2. Design pillars

1. **Ammo is the economy.** Defences consume what the settlement produces. Running dry is the main
   way to lose, and keeping supply flowing is the main skill.
2. **Greed against safety.** The best resources are far away. Reaching them means a bigger
   perimeter and longer supply lines. Every expansion is a bet.
3. **You can read it at a glance.** Carriers visibly carry bundles; towers show ammo; a dry tower
   looks dry. A five-second clip should explain the game without words.
4. **Depth in decisions, not menus.** Few resources and buildings, many interesting choices about
   where to put them and how to connect them.
5. **Built to ship solo.** Every feature has to justify its cost. See the cut list (§12).

## 3. Setting and tone

A frontier valley in a grounded medieval-fantasy world. Settlers have come to the edge of the map
for its forests, stone and iron. From the nests at the edges comes **the Blight**, a creeping rot,
and the **Hollowed**: husks and beasts it has taken.

- Tone: tense but not grim. Warm firelight, hand-made wooden defences, a settlement you feel proud
  of.
- Why medieval fantasy: arrows, bolts and stone shot are readable ammunition that anyone
  understands. It suits wood-to-weapon chains, and it stays close to Flintkeep's art skills.
- Why a horde of "the Blight" and not zombies: zombie hordes are where They Are Billions lives.
  A rot that spreads also gives a visual of the map getting worse over time.

## 4. Look and feel

- **Camera:** top-down, tilted about 50 degrees (as in Flintkeep): the ground is squashed and
  buildings, units and props stand upright, sorted back to front. 2D sprites, so art stays fast to
  make and hundreds of units stay cheap to draw. Zoom from the whole map to one tower.
- **Art direction:** stylised and readable, a little more grounded than Flintkeep's casual cartoon,
  because the Steam strategy audience trusts a calmer look. Strong silhouettes, a warm palette for
  the settlement, cold desaturated purples and greens for the Blight.
- **Readability rules:**
  - Every carrier shows what it carries (a bundle of arrows, a log, a stone).
  - Every tower shows an ammo pip bar; at 25% it flashes amber; when dry, its flag drops and its
    crew stands idle.
  - Blighted ground is visibly darker and spreads in soft fingers from the nests.
- **Day and night:** a cycle like Flintkeep's. Waves arrive at dusk; nights are lit by torches and
  braziers (light radius matters for seeing what comes).
- **Sound:** wood creaks, saws, hammering and a horn that warns of each wave. Music builds with the
  wave timer.

## 5. A game session

A session is one **map**: about 60 to 120 minutes, ending in a **final siege**.

1. **Landing (minute 0 to 5).** Place your Town Hall. You start with a few settlers, some wood and
   food. Fog covers most of the map.
2. **Building up (days 1 to 3).** Scout with the Town Hall's sight and watchtowers. Find forest,
   stone, iron and fertile land. Build lumber camps, a fletcher and the first archer towers. Small
   probes test your edges.
3. **Expansion (middle days).** Rich resources sit far out, often near Blight nests. Raise outposts
   to extend the build radius, run roads, build depots near the walls. Waves grow and new enemy
   types arrive.
4. **Final siege (last night).** A countdown is shown from the start. On the last night every nest
   empties. Survive until dawn and you win.

**Losing:** the Town Hall falls, or every settler is dead.

**Game speed:** active pause plus 1×, 2× and 3×. Pausing is allowed at any time, including during
waves (the genre expects it).

**Difficulty:** settings for the size of the horde, the number of days and the starting resources;
a score at the end (days survived, settlers lost, buildings lost, ammo left).

## 6. The core loop

```
 gather            make              carry              fire
forest ──► lumber camp ──► fletcher ──► carriers ──► archer tower ──► horde
   ▲                         ▲             │               │
   │                         │             ▼               ▼
expand toward       more workers ◄── food, houses    bounty / safety
 resources                                           to expand further
```

Per minute the player:
- reads alerts (a tower low on ammo, an attack direction, a starving camp);
- fixes the weakest link (another fletcher, a depot nearer the wall, a second road);
- decides whether to push toward a new resource before the next wave.

## 7. Systems

### 7.1 Map and building

- **Grid:** 1 tile ≈ 2 m. Buildings have footprints (1×1 to 4×4). Free placement on the grid, no
  fixed slots.
- **Build radius:** you can only build inside the territory of your Town Hall and outposts (the C&C
  rule). An outpost costs wood and stone and pushes the radius out by about 12 tiles.
- **Construction:** placing a building creates a site. Carriers bring its materials, builders put
  it up. A site under attack stops. This makes building near the front slow and risky, as it
  should be.
- **Roads:** drawn by dragging. Carriers walk 1.5× faster on roads. Roads are free but take time to
  lay.
- **Walls:** drawn by dragging. Palisade (wood) first, stone later. Gates let your carriers through
  and the horde not. Walls stop the horde; towers stand behind or on them.
- **Resource nodes:** forests (they regrow slowly near a forester), stone outcrops, iron veins,
  fertile soil, fishing water. Nodes are limited; the richest are far out.

### 7.2 Population and workers

- **Settlers** are a number, not characters with needs. Houses raise the cap. Food grows the
  population; no food stops growth and then slows work.
- Each production building takes a fixed number of **workers** (1 to 4). The player can raise or
  lower a building's priority.
- Settlers left over become **carriers** and **builders** automatically. A slider sets the share
  of carriers versus builders.
- **Why no needs or moods:** colonist AI is the largest scope trap for one developer, and the
  game is about defence, not about a happy town. See DECISIONS.md.

### 7.3 Goods and production chains (launch set)

| Chain | Steps | Feeds |
|---|---|---|
| **Wood** | forest → Lumber Camp → logs | building, palisades, Fletcher, Charcoal Kiln |
| **Arrows** | logs → Fletcher → arrows (10 per log) | Archer Tower |
| **Stone** | outcrop → Quarry → stone | stone walls, towers, Stonecutter |
| **Shot** | stone → Stonecutter → stone shot (4 per stone) | Catapult |
| **Iron** | vein → Mine → ore; logs → Charcoal Kiln → charcoal; ore + charcoal → Smelter → iron | Blacksmith, upgrades |
| **Bolts** | iron → Blacksmith → bolts (6 per iron) | Ballista |
| **Food** | soil → Farm, water → Fishery, forest → Forager → food | houses, worker speed |
| **Pitch** (late) | forest → Tar Pit → pitch | fire arrows, Pitch Cauldron |

Four chains are enough for the vertical slice (wood/arrows, stone/shot, iron/bolts, food). Pitch is
the first addition after that.

**Buffers:** every building holds a small input and output store (for example, a Fletcher holds 10
logs and 100 arrows). When the output is full, it stops. This makes bottlenecks visible.

### 7.4 Logistics: the heart of the game

Goods do not teleport. Carriers walk them from where they are made to where they are needed.

- **Requests and offers.** Each building posts *requests* (a tower wants arrows when below 60%) and
  *offers* (a fletcher has 100 arrows). The job system matches them every simulation tick by
  priority, then distance.
- **Priority order:**
  1. towers in combat or below 25% ammo;
  2. other towers below their refill threshold;
  3. construction sites;
  4. production inputs;
  5. moving surplus to storage.
- **Storage:** the **Stockpile** holds anything. The **Depot** (armory) holds only ammunition and is
  meant to stand near the walls, so towers refill fast during a wave. Where to put depots is one of
  the main decisions in the game.
- **Carrier capacity:** a carrier takes 20 arrows, 1 log, 1 stone, 8 shot or 6 bolts per trip.
- **Carts (mid-game upgrade):** a Stable unlocks carts that carry 4× as much but only on roads.
- **Danger:** carriers are units the horde can kill. A carrier near an enemy drops the job and runs
  to the nearest shelter. Runner and flyer enemies hunt carriers on purpose.
- **Supply view (overlay):** a key toggles a view that dims everything except towers (coloured by
  ammo), depots, and the paths carriers take. This is the screen the player lives in during waves.
- **Alerts:** "North Gate archer tower out of arrows", "Fletcher idle: no logs", with a click to
  jump to the spot.
- **No conveyor belts.** We stay a settlement, not a factory. Carriers make supply something you
  can see, and they can be killed, which makes supply something you can lose.

### 7.5 Defences

Each tower has a magazine, a use per shot, and a range. Values are starting points.

| Defence | Ammo | Magazine | Fire | Role |
|---|---|---|---|---|
| Archer Tower | arrows, 1 per shot | 60 | 1 shot/s | cheap, hits ground and air, weak against armour |
| Watchtower | none | — | — | sight only; reveals fog and gives early warning |
| Catapult | stone shot, 1 per shot | 12 | 1 shot/5 s | splash damage, long range, cannot hit close or flying targets |
| Ballista | bolts, 1 per shot | 20 | 1 shot/2.5 s | pierces armour, hits a line of enemies |
| Pitch Cauldron (late) | pitch, 1 per pour | 6 | on demand | sits on a gate or wall, burns everything below |
| Fire arrows (upgrade) | arrows + pitch | — | — | archer towers set enemies alight; costs both goods |

- **Upgrades** cost goods (stone, iron) and raise range, damage or magazine size.
- **Garrison:** each tower takes one worker as crew. No crew, no fire, so population matters.
- **Walls** have hit points; broken sections must be repaired with materials (carried there by
  carriers, during the wave if needed).
- **The Town Hall** has a small built-in bow so a careless start does not end in seconds.

### 7.6 The horde (the Blight)

- **Nests** at the map edges spawn every wave. Blight spreads slowly from each nest; blighted
  forest and fields yield 50% less. Late in the game, the best nodes are blighted.
- **Waves:** a horn and an arrow on the edge of the screen show where the next wave comes from, with
  a countdown. Waves grow by day.
- **Pathfinding:** the horde walks a flow field toward the nearest target. It goes around walls if
  a way round is short, and breaks through if not.
- **Target choice:** most enemies attack the nearest building. Some types go for supply on purpose
  (see table), which makes logistics part of the fight.

| Enemy | First seen | Behaviour |
|---|---|---|
| Husk | day 1 | slow, many; attacks the nearest building |
| Runner | day 2 | fast and fragile; hunts carriers and roads |
| Gnawer | day 3 | goes for stockpiles and depots, eats what is stored |
| Brute | day 4 | armoured and tough; needs bolts or catapults |
| Crow swarm | day 5 | flies over walls, attacks carriers and archer crews |
| Wallbreaker | day 6 | huge damage against walls and gates |
| Blight Heart (boss) | final siege | a walking nest; spawns husks as it goes |

### 7.7 Between maps (meta progression)

Light, so that each map stands on its own:
- Beating a map unlocks the next map and one new building or defence.
- A few **doctrines** chosen before a map (for example, "Fletchers' Guild: arrows +20%, stone
  −10%"), unlocked by playing. No grind for permanent stat upgrades (that is Flintkeep's mobile
  model, not the PC strategy audience's).
- Later: an **endless mode** on a large map, and **challenge maps** with fixed rules (arrows only,
  no walls, one depot).

## 8. Interface

- **Bottom bar:** build menu by category (Gather, Make, Store, Defend, Walls and Roads, Homes).
- **Top bar:** settlers, food, the key goods and their rate per minute (+/−), and the day and wave
  countdown.
- **Building panel:** inputs and outputs, workers, priority, a pause button.
- **Overlays:** supply view (see 7.4), build radius, blight, tower ranges.
- **Alerts** on the right, click to jump.
- **Tutorial:** the first map teaches one thing per day: wood → arrows → towers on day 1, depots on
  day 2, stone and walls on day 3, and so on.

## 9. Audio

- A horn before every wave, distinct for the final siege.
- Hammering, saws and carts that grow louder as the settlement grows: the sound of a working town.
- Tower "click" sounds that change when ammo is low, so the player hears trouble.
- Music in three layers (calm, wave coming, under siege), the same idea as Flintkeep's adaptive
  tracks.

## 10. Technical design (Godot 4.7)

- **Simulation apart from drawing.** A fixed simulation tick (10 per second) runs the economy, jobs
  and enemies; drawing interpolates between ticks. This keeps the game the same at any frame rate
  and at 3× speed.
- **Grid:** one array of tiles (terrain, building id, wall, blight, road). Buildings are records in
  arrays, not a node each, in the "only redraw what changes" spirit of Flintkeep 0.4.
- **Horde pathfinding:** flow fields over the grid, one per target group, recomputed in the
  background when walls or buildings change. Hundreds of enemies then read one direction from their
  tile, which is cheap.
- **Carrier pathfinding:** A* on the grid with a lower cost on roads, cached per pair of buildings
  and cleared when roads change.
- **Rendering:** MultiMeshInstance2D (or batched sprites) for enemies and carriers; the static
  settlement drawn into cached layers.
- **Job system:** a priority queue of requests matched against offers, in a plain GDScript module
  with no nodes, so it can be unit tested.
- **Saving:** the whole map state (grid, buildings, buffers, carriers in flight, enemies, timers) as
  versioned JSON, with tests that save, load and compare.
- **Tests:** like Flintkeep: rules tests (chains, jobs, ammo use), save tests, and a headless
  **balance bot** that plays a map with a simple build order and reports the day it fell.
- **Performance targets:** 60 fps with 1,000 enemies and 150 carriers on a mid-range laptop.

## 11. Steam page and marketing plan

- **The clip that sells it:** a wave hits the north wall, Runners kill the carriers on the road, the
  towers' ammo bars drain and they fall silent one by one, then the player drops a depot behind the
  wall and the arrows start again.
- **The capsule:** a lit wooden fort at night, a line of carriers with arrow bundles on their backs,
  the horde in the dark beyond.
- **Short line for the store:** "Build anywhere. Make your own ammo. Keep the supply lines alive."
- **Where to post:** r/RTS, r/CityBuilders, r/BaseBuildingGames, r/TowerDefense, r/IndieDev, TikTok
  and YouTube Shorts (the clip above).
- **Steam Next Fest** with a demo of one map (about 30 to 45 minutes) ending in a smaller siege.

## 12. Scope: what is in and what is cut

**In for Early Access:** 4 to 6 hand-made maps, 4 production chains plus pitch, 5 defences, 7 enemy
types plus a boss, final sieges, doctrines, the tutorial map, save and load, settings, achievements.

**Cut (not in Early Access, and most never):**
- multiplayer of any kind;
- colonist needs, moods, names or relationships;
- controlling units (no armies, no heroes to steer);
- procedural maps (hand-made maps first; procedural only if the game sells);
- conveyor belts and a factory scale;
- a story campaign with dialogue.

## 13. Milestones

These are estimates for one developer.

| Milestone | Time | Contents | Done when |
|---|---|---|---|
| **M0: prototype** | 2 to 3 weeks | grid, Town Hall, Lumber Camp, Fletcher, carriers, 2 archer towers with magazines, husks in waves, a supply view | the test below passes |
| **M1: vertical slice** | about 3 months | 4 chains, depots, walls, 5 enemy types, one good map with a final siege, placeholder art, save and load, balance bot | 10 testers play a full map; most want another |
| **Steam page** | with M1 | capsule, the clip, a short trailer | page live; wishlists start counting |
| **M2: demo** | about 6 months | real art for the demo map, tutorial, audio | Next Fest demo |
| **M3: Early Access** | 9 to 15 months | 4 to 6 maps, all content in §12 | launch on Steam |

**The prototype test (M0).** Play it yourself and with three to five people who like strategy
games. The one question: **is it tense when the arrows run low?** If players lean in when the ammo
bars drain and feel clever when they fix the supply, build the game. If they do not, more
resources and enemies will not save it; change the core idea first.

**Wishlist checkpoints (rule of thumb, not data from our research):** a few thousand wishlists by
Next Fest is the floor for going on; above 10,000 means real interest.

## 14. Risks

| Risk | What we do about it |
|---|---|
| Competitors with ammo logistics: **Resupply** (turrets fed by workers, belts and bots; Q1 2027), **Infinitory**, **Feed the Front**, **Terrors of War** (WW2 depots feed defences) | Ship the demo early; our difference is a medieval settlement with real production chains and expansion tension, not a turret game with belts. Watch their launches and learn from their reviews. |
| "It's They Are Billions with arrows" | Lead every clip and the store page with supply, the thing They Are Billions does not have. |
| Pathfinding and many units cost too much CPU | Flow fields from day one; the performance target in §10; test with 1,000 enemies in the prototype. |
| Balance gets out of hand as chains interact | Keep to 4 chains; the balance bot; one change at a time with a log, as in Flintkeep's BALANCE.md. |
| Scope creep | The cut list in §12 is binding until Early Access sells. |
| The hook is not fun | That is what the M0 test is for, before most of the work. |
