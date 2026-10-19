class_name PlayResult
extends RefCounted
## Verdict from PlayRules.evaluate(): is the play legal, and what does it do to the table?

enum Effect {
	NONE,  ## Normal play: turn passes to the next player.
	SKIP,  ## Same rank as the pile: the next player is skipped (section 10).
	RESET,  ## A valid 2 reset: pile clears and the same player plays again (section 12).
}

const REASON_SIZE_MISMATCH := "size_mismatch"
const REASON_RANK_TOO_LOW := "rank_too_low"
const REASON_INVALID_RESET := "invalid_reset"

var legal: bool = false
var effect: int = Effect.NONE
## Empty when legal. Otherwise one of the REASON_* constants.
var reason: String = ""


static func allowed(p_effect: int) -> PlayResult:
	var result := PlayResult.new()
	result.legal = true
	result.effect = p_effect
	return result


static func rejected(p_reason: String) -> PlayResult:
	var result := PlayResult.new()
	result.reason = p_reason
	return result
