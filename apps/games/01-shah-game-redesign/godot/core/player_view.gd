class_name PlayerView
extends RefCounted
## Everything one player is allowed to know: their own hand, the table, and how many cards
## everybody else holds. Bots decide using only this, so they cannot peek at other hands.

var seat: int
var player_count: int
var hand: Array[Card] = []
var pile: Play = null
var pile_owner: int = -1
var current_player: int = -1
var direction: int = Direction.CLOCKWISE
## Cards held by every seat (index = seat), including this player.
var hand_sizes: Array[int] = []
var finished: Array[int] = []
var legal_plays: Array[Play] = []
var can_pass: bool = false


## True if some other player who is still in the game is close to going out.
func opponent_close_to_out(threshold: int = 2) -> bool:
	for other in player_count:
		if other != seat and not finished.has(other) and hand_sizes[other] <= threshold:
			return true
	return false
