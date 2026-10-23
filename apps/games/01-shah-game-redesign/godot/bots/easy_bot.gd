class_name EasyBot
extends Bot
## Plays a random legal move and sometimes passes for no reason. Good for learning the game.

const PASS_CHANCE := 0.25

var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


func choose(view: PlayerView) -> Play:
	if view.legal_plays.is_empty():
		return null
	if view.can_pass and _rng.randf() < PASS_CHANCE:
		return null
	return view.legal_plays[_rng.randi_range(0, view.legal_plays.size() - 1)]
