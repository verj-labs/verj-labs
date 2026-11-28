# Ten small sim and tycoon ideas

Research done on 2026-11-28. The goal: **simple to build, a real chance at US$100,000 gross on
Steam, and all in one studio identity: resource, simulation and tycoon games.**

**Engine and dimension are chosen per game.** The "why simple" notes below assume the simplest
version of each idea; any of them can be made in 3D (Unity, Unreal or Godot), which adds art time.

## The studio identity

> **Verj Games makes small games about keeping something running.**
> Build a thing that flows, then watch something threaten it.

Flintkeep (hold the Keep) and Quiverhold (keep the supply lines alive) already fit this. Every idea
below has the same three parts:

1. **a flow** you build (goods, water, people, logs);
2. **a pressure** on it (a horde, a deadline, physics, the weather);
3. **a moment that clips well**: the collapse, the wipeout, the eruption.

## What $100,000 means

- At $9.99 that is about 10,000 copies; at $14.99, about 6,700.
- By the rule of thumb that 1,000 Steam reviews ≈ $150,000 gross, $100,000 is about 650–700 reviews,
  a little under the "hit" bar used in the genre data below.
- Gross is before Steam's 30%, refunds and taxes; expect roughly half of it as income.
- For context: the median paid game released on Steam in 2026 has grossed about $1,700
  ([Game World Observer](https://gameworldobserver.com/2026/09/01/the-median-revenue-of-games-on-steam-has-been-declining-for-12-consecutive-years)).
  Most games never reach $100,000; these ideas are picked to improve the odds, not to promise it.

## What the research says works for small games

**Small, simple games that sold well** (most figures are developer- or publisher-reported):

| Game | Team, time | Price (approx.) | Result | Why it worked |
|---|---|---|---|---|
| A Game About Digging a Hole | small team, ~3 weeks | $5 | 1.2M+ on PC ([Game*Spark](https://www.gamespark.jp/article/2025/12/09/160359.html)) | one satisfying verb, a title that is the pitch |
| Rusty's Retirement | solo | $4.99 | 500k+ ([GamesRadar](https://gamesradar.com/games/simulation/after-selling-100000-copies-of-its-idle-stardew-valley-like-rustys-retirement-dev-celebrates-spawning-a-genre-of-games-that-run-at-the-bottom-of-your-screen)) | a new format: a farm at the bottom of your screen |
| Tiny Glade | 2 people | ~$15 | 616k in a month ([GameDiscoverCo](https://newsletter.gamediscover.co/p/how-tiny-glade-built-its-way-to-600k)) | a toy that feels great in the hand, gorgeous clips |
| TCG Card Shop Simulator | solo, bought assets | ~$15 | 1M+ ([Malay Mail](https://malaymail.com/news/life/2024/11/06/meet-the-solo-malaysian-developer-behind-tcg-card-shop-simulator-the-buatan-malaysia-video-game-thats-a-hit-with-fans-worldwide-video/155444)) | a fantasy everyone has (running a card shop) |
| Hydroneer | small | ~$20 | 500k ([Game Developer](https://www.gamedeveloper.com/game-platforms/this-game-sold-500k-copies-why-didn-t-you-know-about-it-)) | physical mining and machines you build by hand |
| Dome Keeper | 2 people | ~$18 | ~100k and ~$1M in the first month ([GameSensor](https://gamesensor.info/news/dome_keeper)) | mining plus defence, one clear loop |
| Potion Craft | small | ~$15 | 100k in 3 days ([Gamespress](https://gamespress.com/Potion-Craft-sells-100k-copies-in-the-first-three-days)) | a hands-on crafting process as the whole game |
| Gnorp Apologue | small | low | 200k ([Steam patch notes](https://store.steampowered.com/app/1473350)) | an idle game with physical, chunky feedback |
| Poly Bridge | small | ~$10 | ~390k, ~$3.3M (estimate, [Raijin](https://raijin.gg/app/367450/Poly_Bridge)) | physics building, funny failures |
| Beltmatic | solo | ~$5 | 45–90k (estimate, [Steam Page Analyzer](https://www.steampageanalyzer.com/games/2674590)) | factory plus maths, a fresh twist on belts |

**Patterns:**
- **One verb that feels good** (dig, place, pour, stack) beats a long feature list.
- **A title or a five-second clip that is the whole pitch.**
- **Physics failures are free marketing:** collapses and wipeouts get shared.
- **Low prices ($5–15) for small games.** It is easier to sell 10,000 copies at $10 than 2,000 at $50.

**Niches to stay out of, or enter only with a twist** (2026 releases against the same weeks of
2025, [Steam Page Analyzer](https://www.steampageanalyzer.com/niches)): shop keeper +634%, bullet
heaven +406%, automation +170%, idle +150% (around 500 idle demos at one Next Fest), cozy +143%.
**Better niches:** colony sim (13.7% hit rate, 3.3× the Steam average), city builder (10.5%),
farming (8%), with supply growing near the Steam average.

---

## The ten ideas

Time estimates are mine, for one developer, to a sellable 1.0 or Early Access.

### 1. Undermound: an ant colony you dig yourself

**Hook:** *"Every tunnel you dig, your colony fills."*

A side-view ant farm. You draw tunnels with the mouse; soil falls away in satisfying chunks. Ants
haul food from the surface, the queen lays eggs in chambers you dig, and fungus gardens feed the
colony. Rain floods the low tunnels and rival insects attack from neighbouring nests, so you dig
drains and guard chambers.

- **Why it could work:** colony sim is the best-odds niche we found (13.7%). Digging is proven
  satisfying (A Game About Digging a Hole, 1.2M). The ant RTS Empires of the Undergrowth has about
  19,000 Steam reviews at 94% positive
  ([Notebookcheck](https://www.notebookcheck.net/Unusual-RTS-with-94-positive-reviews-drops-to-just-7-50-from-30-on-Steam.1430132.0.html)),
  so the audience is real. It is a hex-map strategy game; ours is a hand-dug, side-view sim, a
  different feel.
- **Why simple:** gameplay on a side-view grid of soil cells (it can be rendered in 3D as a glass
  ant farm), ants follow simple pheromone paths, and the rival raids reuse the wave ideas from
  Flintkeep and the flow fields from Quiverhold.
- **The clip:** a rainstorm floods a tunnel and ants rush the eggs to higher chambers.
- **Risk:** keeping hundreds of ants cheap to simulate (same flow-field approach as Quiverhold).
- **Time:** 5–7 months. **Price:** $12–15.

### 2. Ashfall: build a town on a volcano

**Hook:** *"The richest soil on Earth. Mind the mountain."*

A small city builder on the slopes of a live volcano. Volcanic soil grows the best crops, the hot
springs power forges, obsidian sells high. The higher you build, the richer you get, and the closer
you are to the crater. Tremors warn of eruptions; lava flows downhill along the terrain, and you dig
channels and raise walls to steer it away from the town.

- **Why it could work:** city builder is a good-odds niche (10.5%, supply +27%). The greed-against-
  safety tension is the same one that drives Quiverhold. Disasters make the clips.
- **Why simple:** one map per level, lava as a simple cell simulation that flows downhill, a small
  building list (10–15). Levels can be hand-made "volcanoes" of rising difficulty.
- **The clip:** an eruption, lava racing down, and the channel you dug saving the town by one tile.
- **Competition:** an unannounced volcano city builder (Steam app 3294080) and Isle Forge (a god game
  about volcanic islands). Check them before committing.
- **Risk:** making lava feel fair, not random. Tremor warnings and readable slopes solve most of it.
- **Time:** 5–7 months. **Price:** $12–15.

### 3. Powder: run a ski mountain, watch the wipeouts

**Hook:** *"Build the runs. They'll find a way to crash."*

A ski resort tycoon on one mountain. Place lifts, cut runs, build lodges and hire patrols. Skiers
are physics ragdolls: they ride your runs, and badly designed slopes send them tumbling. Ticket
money builds the resort out; injuries and avalanches cost you.

- **Why it could work:** tycoon plus physics comedy is the shareable mix (Poly Bridge ~$3.3M
  estimated). The existing ski builder, Snowtopia, sits at Mixed reviews (about 800) at $24.99
  ([SteamDB](https://steamdb.info/app/1124260)), so the space is there and not well served.
  Sledding Game (a solo debut) sold 100,000 in five days
  ([GamesRadar](https://www.gamesradar.com/games/co-op/solo-dev-stunned-as-his-first-ever-video-game-sells-100-000-copies-in-5-days-on-steam-while-97-percent-overwhelmingly-positive-reviews-pour-in/)),
  so snow and sliding sell.
- **Why simple:** one mountain per level, 2.5D view, Godot's physics for ragdolls, a short building
  list.
- **The clip:** a chain of skiers wiping out at a jump you built too steep.
- **Risk:** the tycoon side must be deep enough to keep players after the laughs.
- **Time:** 4–6 months. **Price:** $10–15.

### 4. Marble Mill: a factory where every ore is a marble

**Hook:** *"No belts. Just gravity."*

A side-view physics factory. Ore comes out of a mine as marbles; you build ramps, funnels, sorters,
lifts and crushers, and gravity does the rest. Orders on the wall ask for so many red and blue
marbles a minute. Badly built lines jam, overflow and spill everywhere.

- **Why it could work:** automation has a strong hit rate (8.4%), and the twist keeps it out of the
  crowd of belt factories (supply +170%). Marble runs are already a hugely watched kind of video.
  Beltmatic shows a fresh twist on factories can sell as a small game.
- **Why simple:** 2D physics, a small set of pieces, levels as puzzles first and a sandbox later.
- **The clip:** a jammed line bursting and marbles cascading down the screen.
- **Risk:** physics with thousands of marbles; pool and simplify bodies early. It is still in a
  crowded genre, so the clip has to carry it.
- **Time:** 4–5 months. **Price:** $8–12.

### 5. Overloaded: a shipping company that packs its own ships

**Hook:** *"Pack it right, or it sinks."*

You run a small cargo line. Contracts arrive (crates, barrels, cars, a piano), and you pack them
onto your ship by hand. The physics are real: a badly balanced load lists, a loose stack shifts in
a storm, an overloaded hull sinks. Money buys bigger ships, cranes and new routes.

- **Why it could work:** packing is a satisfying verb (the Tetris feeling), and capsizing is a
  strong clip. It is a management game with a physics skill at its centre, like Potion Craft's
  hands-on crafting.
- **Why simple:** one dock scene and one ship view; a 2D or simple 3D physics hull; content is new
  cargo shapes and routes.
- **The clip:** a perfectly stacked ship hit by one wave, then everything sliding off the deck.
- **Risk:** a few packing games exist; ours is a company tycoon, not a single puzzle. Check the
  current market before committing.
- **Time:** 4–6 months. **Price:** $10–12.

### 6. Last Light: keep the lighthouse burning (or don't)

**Hook:** *"Keep the light on. Wrecks pay better."*

You are the keeper of a remote lighthouse. Gather driftwood and oil, mend the lamp and keep it lit
through storms. Every ship that passes pays a toll; every ship that wrecks washes salvage onto your
shore, which pays more. The game tracks what kind of keeper you become, and the company (and the
town) notice.

- **Why it could work:** a survival resource sim with a moral hook that people argue about, which
  drives word of mouth. Short, intense sessions (one season per run).
- **Why simple:** one island screen, a small resource set (wood, oil, food, parts), storms as the
  pressure.
- **The clip:** a ship's lights in the storm and the keeper's hand hovering over the lamp switch.
- **Competition:** there are several lighthouse keeper games (Fathom's End, Lighthouse Keeper,
  Little Lighthouse of Horror); the "wrecks pay better" tycoon angle is the difference.
- **Risk:** the moral choice must change the game, not only the ending.
- **Time:** 3–4 months. **Price:** $8–10.

### 7. Saltlines: draw a line, start a trade empire

**Hook:** *"Draw a line. Start an empire."*

A minimal trade tycoon on an archipelago. Each island makes something (salt, spice, timber, wine)
and wants something else. You draw sea routes with the mouse, assign boats, and prices rise and fall
as you flood or starve each market. Pirates and storms close routes.

- **Why it could work:** Mini Metro's elegance applied to a trade tycoon, a gap between the very
  simple puzzle games and very heavy trade sims. A clean, beautiful look makes the Steam page.
- **Why simple:** 2D map, lines and dots, a small economy model; content is new maps (the "nice
  levels" route).
- **The clip:** a map going from three dots to a web of glowing routes.
- **Risk:** it must look distinctive; minimal games live or die by their art direction.
- **Time:** 3–5 months. **Price:** $8–12.

### 8. Ice Road: logistics on a lake that is melting

**Hook:** *"The road melts in spring."*

A winter haulage company drives supplies across frozen lakes to mining camps. You plan routes on
the ice, balance load against ice thickness, and race the season: every week the ice thins, cracks
spread, and heavy trucks become a gamble. Profit comes from cutting it fine.

- **Why it could work:** a fresh setting for a logistics tycoon, with a built-in countdown and a
  risk the player chooses. Ice cracking is a tense, visual moment.
- **Why simple:** one lake per level, a top-down view, a grid of ice cells with thickness, a few
  truck types. Levels are hand-made lakes.
- **The clip:** a truck halfway across as the cracks race toward it.
- **Risk:** the core loop must stay varied over many lakes; new cargo, weather and hazards per level.
- **Time:** 4–5 months. **Price:** $10–12.

### 9. Timber Run: a lumber mill fed by the river

**Hook:** *"Fell it. Float it. Sell it."*

A logging tycoon on one valley. Fell trees on the slopes, slide them down chutes into the river,
and shape the river with booms and dams so the logs reach your mill. Jams build, floods break dams,
and over-logging turns slopes into mudslides, so you replant to keep the valley alive.

- **Why it could work:** physical resource flow (logs you can see tumbling and floating) is the
  satisfying part of Hydroneer and A Game About Digging a Hole, applied to a tycoon. The sustainable
  forestry layer adds a long-term strategy.
- **Why simple:** 2D or 2.5D, simple water flow along a fixed river, logs as physics bodies, a small
  building list.
- **The clip:** a log jam bursting through a dam and a hundred logs racing downriver.
- **Risk:** water and logs together must stay stable in physics; keep the river path fixed per level.
- **Time:** 4–6 months. **Price:** $10–12.

### 10. Moonshine Hollow: brew it, hide it, sell it

**Hook:** *"Brew it. Hide it. Sell it."*

A Prohibition-era bootlegger tycoon in the hills. Grow corn, build stills, age barrels and run
bottles to the town's speakeasies. Revenue agents patrol; you hide stills in the woods, bribe the
sheriff and choose between a small safe operation and a big risky one. A raid can take it all.

- **Why it could work:** an illicit production-and-distribution sim is the theme of Schedule I,
  2025's biggest-selling indie (8M+ copies). A historical setting gives it a different, warmer
  look, and the production chain plus raids fits our "flow and pressure" identity exactly.
- **Why simple:** top-down 2D valley, a short production chain (corn → mash → still → barrel →
  bottle), patrols on simple routes. Single-player.
- **The clip:** the agents' lanterns coming through the trees as you rush the still into the barn.
- **Risk:** Schedule I clones will multiply; the setting and the hiding mechanic must be clear in the
  first five seconds of the trailer.
- **Time:** 4–6 months. **Price:** $10–15.

---

## Scoring

Scores are my judgment, 1 (weak) to 5 (strong), using the data above where it applies.

| Idea | Niche odds | Simple to build | Clip strength | Fresh in market | Fits identity | Total |
|---|---|---|---|---|---|---|
| **Undermound** | 5 (colony sim) | 3 | 4 | 4 | 5 | **21** |
| **Ashfall** | 4 (city builder) | 3 | 5 | 4 | 5 | **21** |
| **Powder** | 3 | 3 | 5 | 4 | 4 | **19** |
| Moonshine Hollow | 3 | 4 | 4 | 3 | 5 | 19 |
| Timber Run | 3 | 3 | 5 | 4 | 4 | 19 |
| Last Light | 3 | 5 | 3 | 3 | 4 | 18 |
| Saltlines | 3 | 4 | 3 | 4 | 4 | 18 |
| Ice Road | 3 | 4 | 4 | 4 | 3 | 18 |
| Overloaded | 3 | 3 | 5 | 3 | 3 | 17 |
| Marble Mill | 2 (automation is filling) | 4 | 5 | 3 | 3 | 17 |

**Top three:**
1. **Undermound:** best niche odds and a proven audience; shares tech with Quiverhold.
2. **Ashfall:** best clip and the clearest greed-against-safety hook.
3. **Powder:** the easiest of the three to make people laugh and share; an under-served space.

## How to test any of these cheaply

1. **Hook test (a day):** post the one-line hook and one mock image on r/gamedev's feedback threads
   or to people who play the genre. Do they ask "when can I play it?"
2. **Toy test (a week):** build only the one verb (dig, pour, stack, ski) with no game around it.
   Is it fun to fiddle with for ten minutes?
3. **Clip test (two weeks):** record the money moment and post it as a short on TikTok, YouTube
   Shorts and Reddit. Compare the reach of the ideas against each other.
4. **Steam page:** put up the winner's page as early as possible and track wishlists through a Next
   Fest demo.

## Sources

Genre data: [Steam Page Analyzer niche index](https://www.steampageanalyzer.com/niches),
[Immutable genre benchmarks](https://www.immutable.com/insights/steam-genre-revenue-benchmarks),
[HowToMarketAGame 2025 review](https://howtomarketagame.com/2026/01/27/what-the-hell-happened-in-2025/).
Game figures are linked in the tables and idea entries above. Most sales numbers are developer or
publisher statements or third-party estimates; Valve publishes none.
