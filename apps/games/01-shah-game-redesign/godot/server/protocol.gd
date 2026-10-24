class_name Protocol
extends RefCounted
## Names, limits and validators for the wire protocol (see docs/ONLINE.md).

const VERSION := 1
const MAX_NAME := 12
const CODE_LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"
const CODE_LENGTH := 4

const E_BAD_MESSAGE := "bad_message"
const E_BAD_VERSION := "bad_version"
const E_BAD_NAME := "bad_name"
const E_NOT_IN_ROOM := "not_in_room"
const E_ALREADY_IN_ROOM := "already_in_room"
const E_NO_SUCH_ROOM := "no_such_room"
const E_ROOM_FULL := "room_full"
const E_ROOM_STARTED := "room_started"
const E_NOT_HOST := "not_host"
const E_NOT_YOUR_TURN := "not_your_turn"
const E_ILLEGAL_MOVE := "illegal_move"
const E_NOT_ENOUGH_PLAYERS := "not_enough_players"
const E_RATE_LIMITED := "rate_limited"
const E_SERVER_BUSY := "server_busy"
const E_REPLACED := "replaced"

## Bot thinking seconds and human turn seconds for each speed name.
const THINK_SECONDS := {"slow": 1.8, "normal": 1.2, "fast": 0.6}
const TURN_SECONDS := {"slow": 60.0, "normal": 20.0, "fast": 10.0}

static var _name_pattern: RegEx


## A cleaned-up display name (upper case, single spaces), or "" if the input is not acceptable.
static func clean_name(raw: Variant) -> String:
	if not raw is String:
		return ""
	if _name_pattern == null:
		_name_pattern = RegEx.new()
		_name_pattern.compile("^[A-Za-z0-9 _.\\-]+$")
	var text := (raw as String).strip_edges()
	while text.contains("  "):
		text = text.replace("  ", " ")
	if text.is_empty() or text.length() > MAX_NAME:
		return ""
	if _name_pattern.search(text) == null:
		return ""
	return text.to_upper()


static func is_valid_code(raw: Variant) -> bool:
	if not raw is String or (raw as String).length() != CODE_LENGTH:
		return false
	for letter in (raw as String):
		if not CODE_LETTERS.contains(letter):
			return false
	return true


## The cards of a `play` message, or an empty array if the field is not 1-4 valid card codes.
static func parse_cards(raw: Variant) -> Array[Card]:
	var cards: Array[Card] = []
	if not raw is Array:
		return cards
	var items: Array = raw
	if items.size() < Play.MIN_SIZE or items.size() > Play.MAX_SIZE:
		return cards
	for item in items:
		if not item is String:
			return [] as Array[Card]
		var card := Card.from_code(item)
		if card == null:
			return [] as Array[Card]
		cards.append(card)
	return cards


static func difficulty_value(name: Variant) -> int:
	match name:
		"easy":
			return Bot.Difficulty.EASY
		"medium":
			return Bot.Difficulty.MEDIUM
		_:
			return -1


static func is_speed(name: Variant) -> bool:
	return name is String and THINK_SECONDS.has(name)


## Match length in games: one of ShahMatch.GAME_OPTIONS (10 or 20). JSON numbers arrive as floats.
static func is_games(value: Variant) -> bool:
	return (value is int or value is float) and ShahMatch.GAME_OPTIONS.has(int(value))


static func effect_name(effect: int) -> String:
	match effect:
		PlayResult.Effect.SKIP:
			return "skip"
		PlayResult.Effect.RESET:
			return "reset"
		_:
			return "none"


static func effect_value(name: String) -> int:
	match name:
		"skip":
			return PlayResult.Effect.SKIP
		"reset":
			return PlayResult.Effect.RESET
		_:
			return PlayResult.Effect.NONE


static func error(code: String, message: String = "") -> Dictionary:
	return {"type": "error", "code": code, "message": message if message != "" else code}


## JSON has only floats; clients turn whole numbers back into ints. Applied recursively.
static func whole_numbers(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, roundf(value)):
		return int(value)
	if value is Array:
		var items: Array = []
		for item in value:
			items.append(whole_numbers(item))
		return items
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = whole_numbers(value[key])
		return result
	return value
