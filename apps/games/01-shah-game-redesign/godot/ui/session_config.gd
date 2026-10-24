class_name SessionConfig
extends RefCounted
## Choices made on the setup screen, read by the table. (Plain static data: no autoload needed.)

const MIN_PLAYERS := 3
const MAX_PLAYERS := 8

static var player_count: int = 4
## Set by the online lobby just before the table opens; the table takes it over (and clears it).
static var online_source: TableSource = null
static var difficulty: int = Bot.Difficulty.MEDIUM
## How many games a single-player match lasts (one of ShahMatch.GAME_OPTIONS).
static var match_games: int = ShahMatch.DEFAULT_GAMES

enum Speed { SLOW, NORMAL, FAST }

## Bot "thinking" seconds for each speed. Every other pause in the game scales from this.
const THINK_SECONDS := {Speed.SLOW: 1.8, Speed.NORMAL: 1.2, Speed.FAST: 0.6}

## Seconds the human has for each turn.
const TURN_SECONDS := {Speed.SLOW: 60.0, Speed.NORMAL: 20.0, Speed.FAST: 10.0}

static var speed: int = Speed.NORMAL


static func think_seconds() -> float:
	return THINK_SECONDS[speed]


static func speed_name(value: int) -> String:
	return ["Slow", "Normal", "Fast"][value]


static func turn_seconds() -> float:
	return TURN_SECONDS[speed]
