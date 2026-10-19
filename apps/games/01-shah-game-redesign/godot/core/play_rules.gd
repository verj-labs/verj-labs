class_name PlayRules
extends RefCounted
## Pure rule checks for a single play against the pile. No state, no side effects.
##
## Decision (open question, see docs/OPEN_QUESTIONS.md #1): 2s may be LED onto an empty
## pile like any set, otherwise a player holding only 2s could never go out. Against a
## pile a 2 never "beats" by rank; it can only reset, per the table in section 12.1.

## Pile size -> size of the set of 2s that resets it (section 12.1).
const RESET_SIZE_FOR_PILE := {1: 1, 2: 1, 3: 2, 4: 3}


## `pile` is the top play on the table, or null when the table is empty (new round).
static func evaluate(pile: Play, play: Play) -> PlayResult:
	if pile == null:
		return PlayResult.allowed(PlayResult.Effect.NONE)
	if play.is_two():
		return _evaluate_two(pile, play)
	return _evaluate_normal(pile, play)


static func _evaluate_two(pile: Play, play: Play) -> PlayResult:
	if play.size == RESET_SIZE_FOR_PILE[pile.size]:
		return PlayResult.allowed(PlayResult.Effect.RESET)
	return PlayResult.rejected(PlayResult.REASON_INVALID_RESET)


static func _evaluate_normal(pile: Play, play: Play) -> PlayResult:
	if play.size != pile.size:
		return PlayResult.rejected(PlayResult.REASON_SIZE_MISMATCH)
	if play.strength() < pile.strength():
		return PlayResult.rejected(PlayResult.REASON_RANK_TOO_LOW)
	if play.strength() == pile.strength():
		return PlayResult.allowed(PlayResult.Effect.SKIP)
	return PlayResult.allowed(PlayResult.Effect.NONE)
