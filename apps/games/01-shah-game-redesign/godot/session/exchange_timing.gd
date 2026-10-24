class_name ExchangeTiming
extends RefCounted
## How long the card-exchange animation runs. The screens play it, and the server holds the
## first move of the next game for the same time so nobody acts before it finishes.

const INTRO_SECONDS := 1.2
const MOVE_SECONDS := 0.75
const MOVE_STAGGER := 0.14
const STEP_PAUSE := 0.45
const FINISH_PAUSE := 0.4


## `my_transfers` is how many of the transfers involve the player (0 to 2).
static func seconds(my_transfers: int) -> float:
	var one_step := MOVE_SECONDS + MOVE_STAGGER * 2 + STEP_PAUSE
	return INTRO_SECONDS + my_transfers * one_step + FINISH_PAUSE
