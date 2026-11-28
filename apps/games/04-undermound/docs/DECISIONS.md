# Undermound: decisions log

Newest first, with the reasons.

## 2026-11-28: 0.2, a full year

### A year of four 18-minute seasons

- A run needs a shape: build up in spring, flourish in summer, prepare in autumn, endure winter.
  18 minutes a season (72 in all) leaves time to build between events; the speed controls cover
  players who want it faster.
- The game opens in a mild spring (11°C): each season's typical temperature arrives a quarter of
  the way in, so the cold comes with the first days of winter, not halfway through autumn.

### Temperature with depth is the core tension

- Deep soil stays near 11°C; the top follows the air. A deep nursery is warm in winter, but deep
  is also where water collects. Making depth both safe and risky turns nest layout into the main
  decision.

### Ants get out of the water; workers carry brood and the queen

- In testing, the first spring rain drowned the starter colony because ants stood in pooled
  water and walked back into it. Real ants evacuate and rescue brood, so the sim does too: ants
  in deep water climb out, do not wade back in, and brood (and the queen) is moved to the
  driest nursery cell or, failing that, any dry tunnel.
- Floods still matter: brood that cannot be moved in time drowns, a sealed nest still kills the
  queen, and flooded chambers block digging until they drain.

### A sump in the starter nest; lighter rain

- The starter nest has a small pit under the nursery that catches the first rain; it teaches the
  idea of drainage by example. Rain was lowered from 1.2 to 0.7 per entrance per second.

### Winter appetite and starvation at 15%

- At full appetite an unmanaged colony starved within the first third of winter however well it
  had done; at 15% (dormant ants), a colony with a decent granary survives, and one without
  still shrinks hard. Starvation deaths slow in step, so famine is a pressure, not a wipe-out.

### Priorities are sliders, not per-ant control

- Three worker weights (dig, forage, nurse) and a soldier share for new brood. It keeps the
  "you are the colony" fantasy and scales to any colony size.

### The spider stays on the surface

- A predator that cannot enter the nest makes the entrance the front line and gives soldiers a
  clear job. Its body becomes food when killed, so fighting pays.

### Winged queens fly after a summer rain

- Real nuptial flights follow warm rain; it ties two systems together and gives the flight a
  moment the player can anticipate. Late in summer they fly anyway, so a dry summer does not
  lose them.

### Sound is synthesised for now

- Procedural sound in code keeps the build self-contained; recorded foley comes with 0.3.

## 2026-11-28: starting decisions

### Undermound is the next game to build

- It scored highest of the ten ideas in [`../../ideas/SIM_TYCOON_IDEAS.md`](../../ideas/SIM_TYCOON_IDEAS.md):
  colony sim has the best measured odds (13.7% hit rate), and the ant-game audience is proven.
- It is smaller than Quiverhold and uses the same hard tech (thousands of agents, flow fields),
  so it is the right game to learn that tech on.

### Godot 4.7 with C# first, Unity later

- The target engine is Unity, but Unity's licence needs a sign-in with the developer's Unity
  account, so it cannot run in the cloud environment where the first version is built and
  screenshotted. Godot runs there, including 3D on a software GPU.
- C#, not GDScript, because Unity uses C#: the simulation in `godot/core/` has no Godot types and
  can be moved to Unity almost unchanged. Only the 3D view in `godot/game/` is engine-specific.

### Stylised-realistic, not cartoon

- Real ant anatomy and behaviour with warm, toy-like lighting and no cartoon faces. It suits the
  ant-keeping audience (a large hobby community online) and makes the macro garden shots striking.

### 3D view of a 2D cross-section

- The game is played on one plane, like a real glass ant farm. That keeps digging, movement and
  water simple and readable, while the 3D view gives depth, lighting and the camera rise into the
  garden.

### You command the colony, not single ants

- Orders (dig here, this room is a nursery) instead of selecting ants. It is how real colonies
  work, and it scales to thousands of ants.
