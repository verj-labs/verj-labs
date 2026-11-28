# Undermound: game design

**One line:** a 3D colony sim set inside a living glass ant farm. You are the mind of the colony:
you dig the nest, lay scent trails and set priorities, and thousands of ants make it happen.

**Hook:** *Every tunnel you dig, your colony fills.*

**Platform:** PC (Steam), mouse and keyboard. **Price (planned):** US$15–20.

**Steam tags (planned):** Colony Sim, Base Building, Simulation, Strategy, Nature, Sandbox,
Relaxing (for the peaceful mode).

**Engine:** the first version is built in **Godot 4.7 with C#**. The simulation lives in plain C#
with no engine types (`godot/core/`), so it can move to **Unity** later almost unchanged; only the
3D view (`godot/game/`) would be rebuilt. See [`DECISIONS.md`](DECISIONS.md).

Numbers in this document are starting values. Once code exists, the code is the source of truth
(`godot/core/SimConfig.cs`).

---

## 1. Why this game

- **Colony sim is the best-odds niche we measured:** 13.7% of games reach 1,000 reviews, 3.3× the
  Steam average, with supply growing near the Steam average
  ([market research](../../03-quiverhold/docs/MARKET_RESEARCH.md)).
- **Digging is a proven satisfying verb:** A Game About Digging a Hole sold 1.2M+ copies.
- **The audience is real:** the ant strategy game Empires of the Undergrowth has about 19,000
  Steam reviews at 94% positive. It is a hex-map strategy game where you command armies through
  missions; ours is a hand-dug sandbox with weather, a different feel.
- **It teaches the tech Quiverhold needs:** thousands of agents, flow fields, grids that spread and
  fade. Undermound is the smaller game to learn it on.

## 2. Pillars

1. **The nest is yours.** You shape every tunnel and chamber by hand; no two colonies look alike.
2. **A living, readable colony.** You can follow any ant and see what it is doing and carrying.
3. **Nature pushes back.** Rain, drought, cold, predators and rivals test the nest you built.
4. **Real ants.** Behaviour and species are grounded in real biology; this is a selling point.

## 3. Look and feel: stylised-realistic

- **The ant farm:** a cross-section slab of soil seen through glass, framed in wood like a real
  ant farm on a desk. Soil layers (dark topsoil, red clay, pale sand, grey rock) with pebbles,
  roots and the odd buried bottle cap. Tunnels are hollow, so you see the darker back wall and the
  ants inside them.
- **The surface:** above the slab, a macro garden. Grass blades tower over the ants, a dropped
  berry is a mountain of food, and soft depth of field gives the close-up, miniature look.
- **The money shot:** the camera rising from a deep tunnel up into the giant garden. This opens
  the trailer.
- **Ants:** real anatomy (head, thorax, abdomen, six legs, antennae), glossy dark chitin, no faces
  or eyes drawn as a cartoon. Each ant shows what it carries: a soil pellet, a crumb, an egg.
- **Light:** warm afternoon sun on the surface; inside the slab, light falls off with depth.
  Scent trails glow faintly when the scent view is on.

## 4. How you play

You never control single ants. You give orders to the colony:

| Tool | What it does |
|---|---|
| **Dig** | Paint soil to dig. Ants dig it out, carry the soil up and pile it into a mound. |
| **Nursery** | Mark dug space as a nursery. The queen lays eggs there; larvae grow there. |
| **Food store** | Mark dug space as a store. Foragers bring food here. |
| **Cancel** | Remove dig orders or a room's purpose. |
| **Scent** (later) | Paint "food here", "danger" or "avoid" trails on the surface. |
| **Priorities** | Sliders for how many ants dig, forage and nurse. |

Speed: pause, 1×, 2×, 4×.

## 5. The colony

- **The queen** sits in the nursery and lays an egg every 12 s while the colony has food and the
  nursery has room.
- **Eggs** hatch into **larvae** after 20 s; larvae eat and become **workers** after 30 s more.
- **Workers** dig, forage, nurse and haul. They eat a little food over time; if the store runs
  out they slowly starve.
- **Food** comes from the surface: crumbs, seeds, fallen berries, dead insects. Each source holds a
  limited amount; new ones appear over time.
- **Soil** dug out is carried to the surface and builds a visible mound around the entrance.
- **Later castes:** soldiers (fight), nurses (faster brood), scouts (find food, lay trails).

## 6. Foraging and scent

- Foragers leave the nest and search along the surface. When one finds food it carries a piece
  home and lays a **scent trail** behind it.
- Others follow the strongest scent; trails fade over time, so dead trails disappear by
  themselves. Busy routes glow brightest.
- This is real ant behaviour, and it looks good: you watch the colony discover a berry and a line
  of ants form toward it.

## 7. Pressure

| Threat | What happens | Your answer |
|---|---|---|
| **Rain** | Water pours into the entrance and runs down the tunnels, pooling in low chambers. Ants in water are slowed and can drown; flooded brood dies. Soil slowly soaks it up. | Dig drains and sumps, keep the nursery high, build a raised entrance. |
| **Drought** | No new food for a while. | A big food store, honeypot species. |
| **Winter** | Cold near the surface slows ants; the colony must cluster deep. | Dig deep warm chambers. |
| **Spiders and beetles** | Hunt foragers on the surface; some dig in. | Soldiers, narrow entrances. |
| **Rival colony** | Raids your stores for food. | Soldiers, chokepoints. |
| **The garden owner** | A lawnmower shakes the ground; the garden hose floods everything. | Depth and drains. |

The first version builds rain; the rest come later.

## 8. A run

- One run is one **year**: spring, summer, autumn, winter (about 60–90 minutes).
- You **win** by surviving to the next spring and sending out a **nuptial flight**: winged queens
  leave to start new colonies. The number of queens is your score.
- Flights unlock new **species** and **homes** (maps).
- A **peaceful mode** has no predators or rivals, for players who just want to build.

## 9. Species (content plan)

| Species | Play style |
|---|---|
| Black garden ant | The starter. Balanced. |
| Leafcutter | Cuts leaves to farm fungus; the economy is gardening. |
| Honeypot | Living storage ants; strong in drought. |
| Fire ant | Aggressive; raids rivals; survives floods by rafting. |
| Army ant | No fixed nest; always on the move. |

## 10. Homes (maps)

Back garden (starter), desert, rainforest floor, picnic site, a crack in a city pavement.

## 11. Technical design

- **Simulation apart from the view.** `godot/core/` is plain C#: the soil grid, ants, colony,
  scent and water, stepped at a fixed 10 ticks per second. `godot/game/` draws it in 3D and turns
  input into orders. This split is what lets the simulation move to Unity later.
- **The world is a 2D grid on one plane.** Gameplay happens on the cross-section; the 3D view gives
  it depth. Grid: 160 × 90 cells underground plus a surface lane.
- **Movement:** flow fields (breadth-first distance maps) over the tunnels, rebuilt when the nest
  changes: to the entrance, to dig sites, to the nursery, to the food store. Every ant reads one
  step from its cell, so thousands are cheap.
- **Scent:** a 1D field along the surface that ants add to and that fades each tick.
- **Water:** a cellular simulation: water falls, spreads sideways, pools, and soaks slowly into the
  soil.
- **Rendering:** the soil slab is built as meshes in chunks (rebuilt only where it changed); ants
  and carried items are drawn with MultiMesh; water, dig orders and room colours are textures laid
  over the slab.
- **Tests:** a console project (`tests/`) runs the core without the engine: digging, carrying,
  flow fields, foraging, brood and water.
- **Screenshots:** a scripted mode renders shots from the command line (`tools/screenshots.sh`),
  used to check the look from this cloud environment.

## 12. Scope and milestones (estimates, solo)

| Milestone | Contents |
|---|---|
| **0.1 first playable** (this build) | Dig, carry soil, mound, foraging with scent, food store, queen, eggs, larvae, workers, rain and flooding, 3D ant farm and surface, HUD, tests, screenshots |
| **0.2** | Proper ant model and walk animation, priorities, scent painting, seasons, spider |
| **0.3** | Vertical slice: one full year, nuptial flight, score, sound, tutorial |
| **Steam page** | With 0.3: the camera-rise trailer shot |
| **Early Access** | 7–10 months: 3 species, 3 homes, all threats in §7, peaceful mode |

## 13. Risks

| Risk | Answer |
|---|---|
| Thousands of ants cost too much | Flow fields and MultiMesh from the start; profile at 2,000 ants. |
| Players compare it to Empires of the Undergrowth | Lead with digging, weather and the garden, not combat. |
| Water feels random or unfair | Show rain coming; make flow readable; drains that clearly work. |
| The move to Unity costs more than expected | Keep `core/` free of Godot types; tests guard behaviour across the move. |
