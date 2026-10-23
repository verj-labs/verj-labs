class_name Direction
extends RefCounted
## Turn direction (GAME_RULES section 6.3). Seats are numbered clockwise: seat + 1 is the
## next seat clockwise.

const CLOCKWISE := 1
const COUNTER_CLOCKWISE := -1


## Direction for the next game. The previous winner sits at "12 o'clock"; the 2nd-place
## player's seat decides it. 2nd place on the winner's right (the clockwise half of the table)
## -> clockwise, on the left -> counter-clockwise.
## Directly opposite (even player counts) is not covered by the rules: we use clockwise.
## See docs/OPEN_QUESTIONS.md.
static func for_next_game(player_count: int, winner: int, second_place: int) -> int:
	var offset := posmod(second_place - winner, player_count)
	if offset * 2 > player_count:
		return COUNTER_CLOCKWISE
	return CLOCKWISE
