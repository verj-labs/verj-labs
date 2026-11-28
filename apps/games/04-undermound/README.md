# Undermound

A 3D colony sim inside a living glass ant farm. Dig the nest, mark nurseries and food stores, and
guide your colony through a year in the garden: rain and floods, a wolf spider at the entrance,
winged queens in summer, a race for food in autumn and a frozen winter. *Every tunnel you dig,
your colony fills.*

The vision: [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md). Decisions: [`docs/DECISIONS.md`](docs/DECISIONS.md).

![Spring overview](docs/screenshots/03-spring.png)

| | |
|---|---|
| ![The wolf spider at the entrance](docs/screenshots/05-spider.png) | ![The nuptial flight](docs/screenshots/07-flight.png) |
| ![The queen and her brood](docs/screenshots/04-nest.png) | ![Autumn](docs/screenshots/09-autumn.png) |
| ![Winter](docs/screenshots/10-winter.png) | ![Spring meltwater](docs/screenshots/12-melt.png) |

Built in **Godot 4.7 with C#** (.NET 8). The simulation (`godot/core/`) is plain C# with no Godot
types, so it can move to Unity later; the 3D view is in `godot/game/`.

## Status: 0.2, a full year

- [x] Dig tunnels by painting; ants dig, carry soil up and build a mound
- [x] Nursery and food store rooms; the queen settles in the deepest dry nursery cell
- [x] Brood grows with warmth and nurses' care; castes: workers, soldiers, winged queens
- [x] Foraging with scent trails; painted trails to lead foragers; avoid flags; alarm scent
- [x] Priority sliders: dig, forage, nurse, and the soldier share of new brood
- [x] A year of four seasons with temperature by depth: winter stops laying and foraging and
      freezes the shallow soil; snow builds up and melts into the nest in spring
- [x] Rain and floods: water runs down shafts, pools and soaks away; ants climb out of deep
      water; workers carry brood and the queen to dry cells; sumps and the mound help
- [x] The wolf spider hunts on the surface; soldiers fight it; a dead spider is food
- [x] The nuptial flight: winged queens leave after a summer rain; the year report counts them
- [x] Game over when the queen dies or the colony is gone; title screen; year report
- [x] 3D: soil layers, hollow tunnels with rounded corners, room tints, the wooden frame, a macro
      garden that changes with the seasons, rain, snow and falling leaves; ants with a walk
      cycle that crawl on the back wall; soldiers, winged queens, the spider
- [x] Sound synthesised in code: garden, wind, rain, digging, chimes, alarm, flight, seasons
- [x] 35 core tests and a scripted-year screenshot run

Next (0.3): a tutorial year, save and load, follow-an-ant camera, recorded sound, a balance pass
with players, and the first version of the lineage map (see the vision, §10 and §16).

## Run it

Needs the Godot 4.7 **.NET** edition and the .NET 8 SDK.

```bash
cd godot
dotnet build              # compile the C#
godot --path .            # or open project.godot in the Godot editor and press F5
```

| Control | Does |
|---|---|
| Left drag | Use the tool (Shift + drag erases) |
| 1–6 | Tools: Dig, Nursery, Store, Trail, Avoid, Cancel |
| `[` `]` | Brush size |
| Right drag, WASD | Move the camera |
| Mouse wheel | Zoom toward the pointer |
| R | Rain now |
| T | Show or hide scent trails |
| Space, `+`, `-` | Pause and speed (1×, 2×, 4×) |

Trail, Avoid and Cancel work on the surface (above the ground line); the other tools on the soil.

## Tests and screenshots

```bash
./tools/test.sh                 # 35 core simulation tests, no engine needed
./tools/test.sh spider          # only tests whose name contains "spider"
./tools/screenshots.sh out/     # plays a scripted year and saves 13 PNGs (xvfb on Linux)
```
