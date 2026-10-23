class_name PlayRules
extends RefCounted
## Pure rule checks for a single play against the pile. No state, no side effects.
##
## A 2 is always a reset and never stays on the table (decided by Waqas, see
## docs/OPEN_QUESTIONS.md). Against a pile it must be the right number of 2s (table in
## section 12.1). On an empty table, including straight after another reset, any set of 2s is
## a reset: nothing is left to clear and the same player simply keeps going. That is also how
## a player holding only 2s goes out.

## Pile size -> size of the set of 2s that resets it (section 12.1).
const RESET_SIZE_FOR_PILE := {1: 1, 2: 1, 3: 2, 4: 3}


## `pile` is the top play on the table, or null when the table is empty (new round).
static func evaluate(pile: Play, play: Play) -> PlayResult:
	if play.is_two():
		return _evaluate_two(pile, play)
	if pile == null:
		return PlayResult.allowed(PlayResult.Effect.NONE)
	return _evaluate_normal(pile, play)


static func _evaluate_two(pile: Play, play: Play) -> PlayResult:
	if pile == null or play.size == RESET_SIZE_FOR_PILE[pile.size]:
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
