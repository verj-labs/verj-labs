# Undermound: decisions log

Newest first, with the reasons.

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
