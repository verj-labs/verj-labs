class_name TableState
extends RefCounted
## Everything one player is allowed to know about the table right now: their own hand, how many
## cards everyone else holds, the pile, whose turn it is. The table screen draws from this and
## nothing else, so the same screen works for a local game and for an online one.

var game_number: int = 0
var player_count: int = 0
## Your seat, or -1 when nobody at this device is playing (all-bot demos).
var my_seat: int = -1
var names: Array[String] = []
var kinds: Array[String] = []  ## "human" or "bot" per seat.
var hand_sizes: Array[int] = []
var my_hand: Array[Card] = []
var pile: Play = null
var pile_owner: int = -1
var current_player: int = -1
var direction: int = Direction.CLOCKWISE
var finished: Array[int] = []
var skipped: int = -1
var declined: Array[int] = []


static func from_game(game: Game, seat: int, p_names: Array[String], p_kinds: Array[String], p_game_number: int) -> TableState:
	var state := TableState.new()
	state.game_number = p_game_number
	state.player_count = game.player_count
	state.my_seat = seat
	state.names = p_names.duplicate()
	state.kinds = p_kinds.duplicate()
	for index in game.player_count:
		state.hand_sizes.append(game.hand_of(index).size())
	if seat >= 0:
		state.my_hand = game.hand_of(seat).duplicate()
	state.pile = game.pile
	state.pile_owner = game.pile_owner
	state.current_player = game.current_player
	state.direction = game.direction
	state.finished = game.finished.duplicate()
	state.skipped = game.skipped_player()
	state.declined = game.declined_players()
	return state


func hand_size(seat: int) -> int:
	return hand_sizes[seat]


func is_over() -> bool:
	return current_player == -1


func is_finished(seat: int) -> bool:
	return finished.has(seat)


func is_skipped(seat: int) -> bool:
	return skipped == seat


func has_declined(seat: int) -> bool:
	return declined.has(seat)


## What would happen if you made `candidate` on the current pile.
func evaluate(candidate: Play) -> PlayResult:
	return PlayRules.evaluate(pile, candidate)


## Every play you could legally make with your hand on the current pile.
func legal_plays() -> Array[Play]:
	return PlayRules.legal_plays(my_hand, pile)


func to_dict() -> Dictionary:
	var hand_codes: Array[String] = []
	for card in my_hand:
		hand_codes.append(card.to_code())
	return {
		"game_number": game_number,
		"player_count": player_count,
		"my_seat": my_seat,
		"names": names,
		"kinds": kinds,
		"hand_sizes": hand_sizes,
		"my_hand": hand_codes,
		"pile": null if pile == null else pile.to_codes(),
		"pile_owner": pile_owner,
		"current_player": current_player,
		"direction": direction,
		"finished": finished,
		"skipped": skipped,
		"declined": declined,
	}


## Rebuilds a state from `to_dict()` output (e.g. from the network). Returns null if the data
## is malformed, so a bad message can never crash the screen.
static func from_dict(data: Variant) -> TableState:
	if not data is Dictionary:
		return null
	var d: Dictionary = data
	for key in ["game_number", "player_count", "my_seat", "names", "kinds", "hand_sizes", "my_hand",
			"pile", "pile_owner", "current_player", "direction", "finished", "skipped", "declined"]:
		if not d.has(key):
			return null
	var state := TableState.new()
	state.game_number = int(d["game_number"])
	state.player_count = int(d["player_count"])
	state.my_seat = int(d["my_seat"])
	if state.player_count < 3 or state.player_count > 8:
		return null
	for item in d["names"]:
		state.names.append(str(item))
	for item in d["kinds"]:
		state.kinds.append(str(item))
	for item in d["hand_sizes"]:
		state.hand_sizes.append(int(item))
	if state.names.size() != state.player_count or state.kinds.size() != state.player_count \
			or state.hand_sizes.size() != state.player_count:
		return null
	for code in d["my_hand"]:
		var card := Card.from_code(str(code))
		if card == null:
			return null
		state.my_hand.append(card)
	if d["pile"] != null:
		state.pile = Play.from_codes(d["pile"])
		if state.pile == null:
			return null
	state.pile_owner = int(d["pile_owner"])
	state.current_player = int(d["current_player"])
	state.direction = int(d["direction"])
	for item in d["finished"]:
		state.finished.append(int(item))
	state.skipped = int(d["skipped"])
	for item in d["declined"]:
		state.declined.append(int(item))
	return state
