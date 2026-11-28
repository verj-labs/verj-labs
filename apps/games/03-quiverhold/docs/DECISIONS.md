# Quiverhold: decisions log

Product and design decisions, newest first, with the reasons. The numbers behind them are in
[`MARKET_RESEARCH.md`](MARKET_RESEARCH.md).

## 2026-11-28: the starting decisions

### Genre: a base-building survival game with defence, not a tower defense

- The first idea was Satisfactory plus Command & Conquer as a tower defense. Tower defense has a
  below-average Steam hit rate (3.5% against 4.2%); colony sims and city builders sit at 2.5–3.3×
  the average. So defence is the feature and base building is the genre.
- Factory automation is filling fast (+170% releases in 2026), so we take production chains from it
  but not its scale or belts.

### The hook: ammunition is the economy

- Towers fire what the settlement makes, and carriers bring it to them. The big games in this space
  (They Are Billions, Diplomacy is Not an Option) have towers that fire forever.
- It makes a clip that explains itself: a supply line cut, towers falling silent.

### Platform: PC (Steam) first

- Building a settlement needs a mouse. PC grew 13% in 2025 while mobile was flat, and this genre's
  money is on Steam at $15–25. This is the opposite of Flintkeep (mobile) on purpose.

### No colonist needs, no unit control, no multiplayer

- Colonist AI with moods and needs is the largest scope trap for one developer, and our game is
  about defence. Settlers are a count; workers and carriers are assigned automatically.
- Steering units (Command & Conquer's armies) and multiplayer are where RTS cost lives, and RTS is
  commercially weak right now. We keep C&C's base building and leave its armies.

### Carriers instead of conveyor belts

- Carriers make supply visible and vulnerable: the horde can kill them, so supply can be lost. Belts
  would push us into the crowded factory genre.

### Maps of 60–120 minutes ending in a final siege

- A session with an end replays well and can be shipped by one person with hand-made maps. An
  endless sandbox needs far more content and procedural generation. Endless mode is a later
  addition.

### Medieval fantasy and the Blight

- Arrows, bolts and stone shot are ammunition anyone understands, and they fit wood-to-weapon
  chains. "The Blight" instead of zombies keeps us away from They Are Billions' look and gives a
  map that visibly gets worse.

### Tagging: not "Open World Survival Craft"

- "Open world" here means an open map with free building. Steam's Open World Survival Craft tag
  means a character exploring and crafting (Valheim); using it would bring the wrong players and bad
  reviews.

### Prototype before production

- Two to three weeks with one chain (wood → arrows), carriers, two towers and waves. It tests the
  fun (is it tense when the arrows run low?) and the two hardest systems (logistics and
  pathfinding) before most of the work.
