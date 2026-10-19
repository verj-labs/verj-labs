# Shah Exchange - redesign

A ground-up rebuild of `../01-shah-game`: an offline single-player game against bots in Godot,
then a backend designed around what the game actually needs.

## Status

- [x] Godot project skeleton, menu screen, placeholder table
- [x] Cards, plays, beating the pile, skip and 2-reset (`godot/core/`) with tests
- [ ] Round / game flow (turns, passing, direction, finishing, card exchange)
- [ ] Bots (`godot/bots/`)
- [ ] Playable table UI
- [ ] Android / iOS export
- [ ] Multiplayer backend

## Run it

Install Godot 4.7 (`brew install --cask godot`), then run `./run.sh` (or `./run.sh editor`). Or open `godot/project.godot` in the
editor and press F5, or from a terminal:

```bash
godot --path godot
```

## Test it

```bash
./test.sh          # all tests; prints failures and a summary, exit code 0 = all passed
./test.sh core     # only tests/core
./test.sh -v       # full output
```

Tests use gdUnit4 (vendored in `godot/addons/gdUnit4`). Write them to read like the rulebook,
e.g. `_legal("9H 9S", "10H 10S")` is a double 10 on a double 9. Rule ambiguities are tracked
in `docs/OPEN_QUESTIONS.md`.

## Layout

```
docs/GAME_RULES.md   source of truth for rules (copied from 01-shah-game; to be re-verified)
docs/OPEN_QUESTIONS.md  rule gaps and the decision the engine currently makes
godot/core/          pure game logic, no scene or node dependencies (testable, reusable on a server)
godot/bots/          bot players
godot/ui/            screens and UI helpers
godot/scenes/        .tscn files (thin: each just attaches a ui/ script)
godot/tests/         gdUnit4 tests
```

## Ground rules

1. `core/` never touches nodes, scenes or timers: state + move in, new state or error out.
2. Rules come from `docs/GAME_RULES.md`, not from the old backend code.
3. Every rule gets a test before it gets UI.
