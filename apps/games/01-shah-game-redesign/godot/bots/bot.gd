class_name Bot
extends RefCounted
## A computer player. Given what it can see, returns the Play it wants to make, or null to pass.
## Bots must only return plays from view.legal_plays (the tests check this).

enum Difficulty { EASY, MEDIUM }


func choose(_view: PlayerView) -> Play:
	return null
