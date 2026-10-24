class_name OnlineText
extends RefCounted
## Friendly wording for server error codes and "you left" reasons.

const ERRORS := {
	"bad_version": "This game is out of date. Please update.",
	"bad_name": "Name: 1-12 letters, numbers or spaces.",
	"bad_message": "Something went wrong. Try again.",
	"not_in_room": "You are not in a room.",
	"already_in_room": "You are already in a room.",
	"no_such_room": "No room with that code.",
	"room_full": "That room is full.",
	"room_started": "That game has already started.",
	"not_host": "Only the host can do that.",
	"not_your_turn": "It is not your turn.",
	"illegal_move": "That play is not allowed.",
	"not_enough_players": "Need at least 3 players. Add a bot!",
	"rate_limited": "Too fast! Slow down.",
	"server_busy": "The server is busy. Try again soon.",
	"replaced": "You signed in somewhere else.",
}

const LEFT := {
	"kicked": "The host removed you from the room.",
	"room_closed": "The room was closed.",
	"left": "",
}


static func explain(code: String) -> String:
	return ERRORS.get(code, "Error: %s" % code)


static func why_left(reason: String) -> String:
	return LEFT.get(reason, "You left the room.")
