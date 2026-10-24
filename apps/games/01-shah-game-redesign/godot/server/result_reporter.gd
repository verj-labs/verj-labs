class_name ResultReporter
extends RefCounted
## Told when a game finishes. The default does nothing (v1 has no database); accounts and
## leaderboards later plug in a reporter that sends the result to the accounts service.


## `ranking` lists the players 1st place first: [{"name", "kind" ("human"/"bot"), "user_id"}].
func report_game(_room_code: String, _game_number: int, _ranking: Array[Dictionary]) -> void:
	pass
