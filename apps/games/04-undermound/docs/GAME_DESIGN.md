# Undermound: the vision

**One line:** a 3D colony sim inside a living glass ant farm. You are the mind of the colony:
you dig the nest, lay scent trails and set priorities, and thousands of ants make it happen
through a full year in the garden.

**Hook:** *Every tunnel you dig, your colony fills.*

**Platform:** PC (Steam), mouse and keyboard. Later: Steam Deck, then a Switch-class console.
**Price (planned):** US$15–20 at Early Access.
**Steam tags (planned):** Colony Sim, Base Building, Simulation, Strategy, Nature, Sandbox,
Relaxing (for the peaceful mode).

**Engine:** built in **Godot 4.7 with C#**. The simulation (`godot/core/`) is plain C# with no
engine types and can move to **Unity** almost unchanged; only the 3D view (`godot/game/`) would
be rebuilt. See §14.

Numbers below are the values the build uses today; the code (`godot/core/SimConfig.cs`) is the
source of truth.

---

## 1. The fantasy

You lean over a glass ant farm on a sunny windowsill and, for once, you are not just watching.
You are the colony. You decide where the tunnels go, which chambers hold the eggs and which hold
the food, how many ants dig and how many go out into a garden where every blade of grass is a
tree and a single blackberry is a mountain.

Then the year turns. Spring rain runs down the shaft you dug too straight. A wolf spider waits
by the entrance. Summer brings plenty, and with plenty, the colony's real purpose: **winged
queens**, raised in the nursery, who climb the mound one hot afternoon after a storm and lift
into the air to found colonies of their own. Autumn is a race to fill the granary. Winter is
silence: the colony packed deep and still, waiting. Then the snow melts, and the meltwater
finds every mistake you made.

A good year is not one where nothing goes wrong. It is one where the colony you built carries
itself through what does.

## 2. Pillars

1. **The nest is yours.** You shape every tunnel and chamber by hand; no two colonies look alike.
   The shape of the nest *is* the strategy: depth means warmth, low points flood, distance costs
   time.
2. **A living, readable colony.** Any ant can be followed: what it is doing, what it carries,
   where it is going. Problems are visible before they are numbers.
3. **Nature pushes back, fairly.** Rain, frost, drought and the spider are telegraphed, physical
   and answerable by digging and planning, never by reflexes.
4. **Real ants.** Behaviour, castes and species come from real biology: pheromone trails, brood
   care, nuptial flights, winter diapause. The real thing is strange and wonderful enough.
5. **Calm hands, tense moments.** Most minutes are quiet building; the tension arrives in short,
   memorable bursts (a flood, a spider, the flight) that make great clips.

## 3. Why this game (market)

- **Colony sim is the best-odds niche we measured:** 13.7% of games reach 1,000 reviews, 3.3× the
  Steam average, with supply growing near the Steam average
  ([market research](../../03-quiverhold/docs/MARKET_RESEARCH.md)).
- **Digging is a proven satisfying verb:** A Game About Digging a Hole sold 1.2M+ copies.
- **The audience is real and loyal:** the ant strategy game Empires of the Undergrowth has about
  19,000 Steam reviews at 94% positive. It is a hex-map strategy game where you command armies
  through missions; Undermound is a hand-dug sandbox with seasons, weather and a garden, a
  different feel.
- **A built-in community:** ant-keeping is a large hobby with very active YouTube channels and
  forums; "how real leafcutters do it" content spreads by itself.
- **It teaches the tech Quiverhold needs:** thousands of agents, flow fields, grids that spread
  and fade.

## 4. Look and feel: stylised-realistic

- **The ant farm:** a cross-section slab of soil seen as a cut face, framed in wood like a real
  ant farm. Soil in layers (dark topsoil, red clay, pale sand, grey rock) with soft blends
  between them. Tunnels are hollow: you see the darker back wall, the walls and floors in depth,
  and the ants inside. Inside corners are rounded where they meet the face, so tunnels look dug,
  not stamped.
- **Rooms** read through a warm tint on the back wall: rosy for nurseries, amber for stores.
  Planned digs are amber stripes on the soil face that fade as the ants dig.
- **Water** is a deep blue, gently shimmering fill that you can watch run down a shaft and pool.
- **The surface:** a macro garden. Grass towers over the ants, pebbles are boulders, a berry is a
  landmark. Soft depth of field in close-ups gives the miniature look. The garden changes
  colour through the year: fresh green, sun-bleached summer, orange autumn with falling leaves,
  white winter with drifting snow.
- **Ants:** real anatomy (head, thorax, petiole, gaster, six jointed legs, elbowed antennae),
  glossy dark chitin, no cartoon faces. They walk with a tripod gait, wave their antennae and
  bob as they go. Off the floor they crawl on the back wall, as ants do in a real farm.
  Soldiers have big heads and heavy jaws and are reddish; winged queens are long and heavy with
  two pairs of clear, faintly oily wings.
- **The wolf spider:** large (four ants long), banded legs, a row of dark eyes. It reads as a
  threat at any zoom.
- **Light:** warm sun that rides lower and cooler toward winter; the sky greys over in rain.
- **Sound:** a garden ambience of breeze and birds, wind in winter, rain hiss, the crunch of
  digging, a small chime as new workers emerge, an alarm chirp for the spider, a rising
  arpeggio for the flight, a soft bell when the season turns. All synthesised in code today;
  recorded foley later.

### The camera rise (the trailer's opening shot)

Start inside a dark tunnel, close on an ant carrying an egg. Pull back through the cut face to
the whole farm, then rise over the top edge into the garden, grass towering, as the first winged
queen lifts off the mound into the sun.

## 5. How you play: orders, not ants

You never steer single ants. You give the colony orders:

| Tool | Key | What it does |
|---|---|---|
| **Dig** | 1 | Paint soil to dig. Ants dig it out, carry the soil up and pile it into a mound. |
| **Nursery** | 2 | Mark dug space as a nursery. The queen settles in the deepest dry nursery cell; brood piles around her. |
| **Store** | 3 | Mark dug space as a food store. Every store cell holds 4 food. |
| **Trail** | 4 | Paint a lasting trail on the surface. Foragers follow it like scent: lead them to food you can see. |
| **Avoid** | 5 | Plant a red flag on the surface. Foragers will not walk past it. |
| **Cancel** | 6 | Remove dig orders, rooms, trails and flags (Shift + drag erases with any tool). |

**Priorities** (sliders): how workers split between **digging**, **foraging** and **nursing**,
and what share of new brood is raised as **soldiers** (0–40%).

**Time:** pause, 1×, 2×, 4×. Brush size with `[` `]`.

## 6. The colony

### 6.1 The queen

- She settles in the **deepest dry nursery cell**, and moves when it gets wet. If every nursery
  cell floods, workers carry her to the deepest dry tunnel anywhere.
- She lays an egg every 8 s while it is warm enough (her cell at 10°C or more, not winter), the
  nursery has room (2 brood per nursery cell) and there is food (1 per egg, 3 for a queen egg).
- **She can die:** 30 s under water drowns her; a winter spent in freezing soil kills her. Either
  ends the game. Everything in the design protects her or threatens her.

### 6.2 Brood

- **Eggs** hatch into **larvae** after 40 s; larvae become adults after 60 s (90 s for queens).
- **Growth depends on warmth and care.** Below 6°C brood stops growing; at 14°C it grows at full
  speed. Nurses speed it up: with one nurse per three brood, brood grows 1.4×; untended, 0.6×.
- **Larvae eat** (0.02 food/s each); in a famine larvae starve first.
- **Floods:** brood in water for 8 s drowns, but workers carry wet brood to the driest nursery
  cell (or any dry tunnel) as fast as they can, one at a time; more nurses, faster rescue.

### 6.3 Castes

| Caste | How it appears | What it does |
|---|---|---|
| **Worker** | Most brood | Digs, forages, nurses, rests. Eats 0.004 food/s. |
| **Soldier** | The soldier share of new brood | Guards the ground around the entrance, fights the spider. 10 hit points; eats 1.5×. Stays in during winter and rain. |
| **Winged queen (alate)** | In early summer, when the colony has 40+ ants and the store is 40% full, some brood is raised as queens (up to 12 at once) | Waits in the nursery, eats 2×, then flies on the nuptial flight. |

### 6.4 Food

- Food appears on the surface: **berries** (summer), **crumbs**, **seeds** (autumn, larger piles),
  and the **body of a spider** your soldiers killed (60 food).
- New food appears every 25–50 s, faster in summer, slower in autumn, **never in winter**.
- Capacity: 15 plus 4 per store cell. A store that is too small is the classic first-winter death.
- **Winter appetite:** dormant ants eat 15% as much, and starve that much slower too.

### 6.5 Foraging and scent

- Foragers leave the nest, choose the side that smells of food (or of your trail), and search.
  When one finds food it carries a piece home along the shortest path and lays **scent** behind
  it. Others follow the strongest scent; trails fade (3.5% a second), so dead trails clear
  themselves.
- **Painted trails** last much longer (0.4% a second) and steer the choice at the entrance.
- **Avoid flags** turn foragers back. **Alarm scent** (left where a spider strikes) makes
  foragers turn for home and keeps new foragers inside.

## 7. The year

One run is one **year** of four seasons, 18 minutes each (72 minutes in all at 1×; speed up
when you want).

| Season | Air | What changes |
|---|---|---|
| **Spring** | 11–14°C | Laying resumes. Rain is frequent. The snow from winter melts into the nest. |
| **Summer** | ~25°C | Food is plentiful. Rain is rarer. Big colonies raise winged queens; they fly after a summer rain (or late in summer at the latest). |
| **Autumn** | 11°C falling | Seeds. The race to fill the granary. Leaves fall. |
| **Winter** | down to −4°C, −7°C in snow | No food appears, no foraging, no laying. The surface and shallow soil freeze; ants there slow, then die. The colony packs into the warm deep. Snow builds up. |

**Temperature with depth:** deep soil stays near 11°C all year; near the top it follows the air
(the difference fades over about 14 rows). So a deep nursery is warm in winter and cool in
summer, but deep is also where water ends up. **Depth against water is the central tension.**

## 8. Pressure

| Threat | What happens | Your answer |
|---|---|---|
| **Rain** | Water runs into every entrance, falls down shafts, pools in the lowest chambers and slowly soaks into the soil (sand drinks fast, clay slowly, rock not at all). Ants climb out of deep water and will not wade into it; brood is carried to dry cells. | Dig **sumps** below the nursery for the water to find first; keep the nursery off the bottom; a bigger mound around the entrance lets in less water. |
| **Snowmelt** | At the start of spring, the winter's snow melts into the nest for a minute or more. | The same as rain, but bigger and certain: plan for it in autumn. |
| **Frost** | In winter the surface and top rows freeze. | A deep nursery; a granary filled in autumn. |
| **Famine** | No food in winter; too little store capacity. | Dig stores; set foragers high in autumn. |
| **Wolf spider** | Appears from the edge every 4–7 minutes outside winter, hunts the nearest ant on the surface, holds it, eats it, hunts again. Leaves after three meals, after 100 s, or when bitten down to 40% health. Never enters the tunnels. | Soldiers bite back (4 damage/s each against 40 health); workers nip weakly. Alarm keeps foragers home. Kill it and its body feeds the colony. |

Later threats (planned): **rival colony** raids, **beetle larvae** that dig in, **drought**
(food and water scarce), the **garden owner** (a lawnmower that shakes the ground; a hose that
floods everything), **antlion pits** in sandy homes.

## 9. Strategy: the decisions that matter

- **Where is the nursery?** Deep enough to stay warm in winter, high enough (or drained enough)
  to stay dry in rain and melt.
- **Where does the water go?** Every shaft is a drain. A sump below the nursery, a side pocket
  at the bottom of the main shaft, a raised mound: plumbing is half the game.
- **How big is the granary?** A colony of 200 needs about 200 food for one winter at the
  winter appetite. That is 50 store cells.
- **How many soldiers?** Each soldier eats 1.5× and does no work; too few and the spider takes a
  forager every 10 seconds while it stays.
- **How many nurses?** Faster brood means more ants by summer, which means queens.
- **When to push?** Growing past 40 ants by early summer is what raises queens; growing too fast
  empties the store before autumn.

## 10. Winning, losing and the lineage

- **You lose** if the queen dies (drowned, frozen) or the last ant and brood are gone.
- **A year ends** when the next spring begins: a report shows queens flown, the largest colony,
  cells dug, food gathered, spiders driven off and losses. Then the colony goes on.
- **Score:** winged queens flown is the measure of a good year.

### The lineage (meta progression, planned)

Every winged queen that flies is a possible next colony. After a year, you choose one of your
daughters to follow into a **new home** (a new map), and she brings a **trait** inherited from
the colony that raised her (raised in a well-fed colony: lays faster; raised under spider
pressure: more soldiers; raised in a cold nest: hardier in winter). Over runs you grow a family
tree of colonies across the garden: a lineage map that is your progress screen and the thing
players screenshot and share.

## 11. Species (content plan)

| Species | Play style | Unlocked by |
|---|---|---|
| **Black garden ant** | The starter. Balanced. | Start |
| **Leafcutter** | Cuts leaves to farm fungus underground; the food economy is gardening, and fungus chambers need warmth and humidity. | Fly 10 queens |
| **Honeypot** | Some workers become living food stores hanging in chambers; strong in drought and winter. | Survive a drought year |
| **Fire ant** | Aggressive soldiers; colonies raft together to survive floods. | Kill 5 spiders |
| **Army ant** | No fixed nest: the colony moves each season and raids; a completely different game. | Late unlock |

## 12. Homes (maps)

| Home | Soil and threats |
|---|---|
| **Back garden** (now) | Mixed soil, berries and crumbs, the wolf spider. |
| **Sandy heath** | Sand drains fast but collapses; antlions; seeds. |
| **Rainforest floor** | Daily rain, fungus, leafcutter country. |
| **Picnic site** | Huge food windfalls, ant traps, people. |
| **Pavement crack** | A narrow, rocky world; heat and drought. |

## 13. Modes

- **Year** (the main mode): one year at a time with the report and the lineage.
- **Peaceful:** no spider, gentler weather; for players who want to build.
- **Challenges:** fixed scenarios (the flood year, the long winter, spider valley) with a goal.
- **Endless:** no lineage; how many years can one colony last?

## 14. Technical design

- **Simulation apart from the view.** `godot/core/` is plain C#: the soil grid, ants, colony,
  scent, temperature, water, weather and the spider, stepped at a fixed 10 ticks per second.
  `godot/game/` draws it in 3D and turns input into orders. This split is what lets the
  simulation move to Unity later.
- **The world is a 2D grid on one plane:** 160 × 90 cells underground plus a surface lane. The 3D
  view gives it depth.
- **Movement:** breadth-first flow fields over the tunnels, rebuilt when the nest changes: to the
  surface, to dig fronts, to stores, to nurseries. Every ant reads one step from its cell, so
  thousands are cheap. A full year with 250 ants simulates in about 18 seconds without drawing.
- **Water:** a cellular simulation (fall, spread, overflow, soak) at two sub-steps per tick.
- **Rendering:** the soil slab is built as meshes in 16 × 16 chunks, rebuilt only where cells
  change; ants (three castes), carried items and brood are drawn with MultiMesh; water, dig
  orders, scent, trails and alarm are small textures read by shaders; the spider and the walk
  cycle are animated in vertex shaders.
- **Tests:** a console project (`tests/`) runs 35 tests on the core without the engine: digging,
  flow fields, foraging, scent, trails and flags, brood, care, castes, seasons, temperature,
  frost, rain, sumps, melt, the spider and soldiers, the flight, game over and the year report.
- **Screenshots:** `tools/screenshots.sh` plays a scripted year and saves pictures; used to check
  the look from a machine with no display.
- **Unity move (when ready):** copy `core/` into a Unity project as a plain C# assembly (no
  changes beyond namespaces), port the tests to NUnit, rebuild the view with ECS/Entities
  Graphics for the ants and a chunked mesh for the soil. Estimate: 4–6 weeks for parity.

## 15. Business

- **Steam page** with the camera-rise trailer and three GIFs: the flood, the spider, the flight.
- **Marketing:** short clips for TikTok and YouTube Shorts (a flood rescue, a spider fight, a
  nuptial flight); posts on r/ants, r/AntsCanada-style communities, r/CityBuilders and
  r/ColonySim; reaching out to ant-keeping creators with keys.
- **Next Fest demo:** spring and summer of one year in the back garden, ending on the flight.
- **Price:** US$15–20; a launch discount; no microtransactions.

## 16. Roadmap

| Version | Contents | Status |
|---|---|---|
| **0.1 first playable** | Digging, mound, foraging with scent, food store, nursery, queen and brood, rain and flooding, the 3D ant farm and garden, HUD, tests, screenshots | Done |
| **0.2 a full year** | Four seasons and temperature with depth, winter diapause, snow and spring melt; priorities; nursing and care; soldiers; the wolf spider, alarm scent, painted trails and avoid flags; winged queens and the nuptial flight; flood behaviour (ants leave deep water, brood and queen are carried to dry cells); queen death and game over; the year report; title screen; seasonal garden, snow, falling leaves; rounded tunnels; procedural sound; 35 tests | **Done (this build)** |
| **0.3 vertical slice** | Tutorial year, save and load, follow-an-ant camera, an ant info panel, balance pass with playtesters, recorded sound, the lineage map (first version) | Next |
| **Steam page** | With 0.3: the camera-rise trailer | |
| **0.4 demo** | Polish for Next Fest: settings, key rebinding, Steam Deck controls | |
| **Early Access** | 7–10 months from 0.1: 3 species, 3 homes, all threats, peaceful and challenge modes | |

## 17. Risks

| Risk | Answer |
|---|---|
| Thousands of ants cost too much | Flow fields and MultiMesh from the start; profile at 2,000 ants. |
| Compared to Empires of the Undergrowth | Lead with digging, weather, seasons and the garden, not combat. |
| Water feels random or unfair | Rain is announced; water is visible and physical; sumps clearly work; ants and brood get out of the way. |
| A 72-minute year is too long for some | Speed controls; the demo is half a year; later a "short year" option. |
| The move to Unity costs more than expected | `core/` has no Godot types; the tests guard behaviour across the move. |
