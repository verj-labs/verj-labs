class_name MoveResult
extends RefCounted
## What happened when a player tried to play or pass.

const REASON_GAME_OVER := "game_over"
const REASON_NOT_YOUR_TURN := "not_your_turn"
const REASON_NOT_A_SET := "not_a_set"
const REASON_CARDS_NOT_IN_HAND := "cards_not_in_hand"
const REASON_MUST_LEAD := "must_lead"  ## Passing is not allowed on an empty table.

var accepted: bool = false
## Empty when accepted. Otherwise a REASON_* here or a PlayResult.REASON_*.
var reason: String = ""
## PlayResult.Effect of the play (NONE for a pass).
var effect: int = PlayResult.Effect.NONE
## True if this move emptied the player's hand.
var player_finished: bool = false
## Player who won the round if this move ended it, otherwise -1.
var round_won_by: int = -1
var game_over: bool = false
## Seat that was skipped by this play (same rank as the pile), or -1.
var skipped_player: int = -1


static func ok() -> MoveResult:
	var result := MoveResult.new()
	result.accepted = true
	return result


static func rejected(p_reason: String) -> MoveResult:
	var result := MoveResult.new()
	result.reason = p_reason
	return result
