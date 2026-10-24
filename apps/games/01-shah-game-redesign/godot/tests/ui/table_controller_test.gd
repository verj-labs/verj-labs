extends GdUnitTestSuite
## The table controller: bots take turns by themselves and a human can play through it.
## think_time is 0 so these finish in a moment.


func _controller(players: int, human_seat: int, seed_value: int) -> TableController:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var controller := TableController.new()
	add_child(controller)
	auto_free(controller)
	controller.think_time = 0.0
	controller.setup(players, Bot.Difficulty.MEDIUM, rng, human_seat)
	return controller


## Waits (frame by frame) until the current game is over. Fails the test if it never ends.
func _wait_for_game_over(controller: TableController) -> void:
	var frames := 0
	while not controller.game.is_over() and frames < 5000:
		frames += 1
		await get_tree().process_frame
	assert_bool(controller.game.is_over()).is_true()


func test_all_bot_game_plays_itself_to_the_end() -> void:
	var controller := _controller(5, -1, 1)
	controller.start_next_game()
	await _wait_for_game_over(controller)
	assert_int(controller.game.ranking().size()).is_equal(5)


func test_a_second_game_can_follow_the_first() -> void:
	var controller := _controller(4, -1, 2)
	controller.start_next_game()
	await _wait_for_game_over(controller)
	var winner := controller.game.ranking()[0]
	var starters: Array[int] = []
	controller.game_started.connect(func() -> void: starters.append(controller.game.current_player))
	controller.start_next_game()
	await _wait_for_game_over(controller)
	assert_int(controller.match_session.games_played).is_equal(2)
	assert_int(starters[0]).is_equal(winner)
	assert_int(controller.game.ranking().size()).is_equal(4)


func test_human_moves_are_validated_and_a_full_game_can_be_played_through_the_controller() -> void:
	var controller := _controller(4, 0, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var done := [false]
	controller.game_finished.connect(func(_ranking: Array[int]) -> void: done[0] = true)
	var rejected_once := false
	controller.start_next_game()
	var guard := 0
	while not done[0] and guard < 3000:
		guard += 1
		if controller.is_human_turn():
			if not rejected_once:
				# Passing on an empty table (the human leads game 1 or a new round) or
				# playing a card we do not hold must be refused and change nothing.
				var before := controller.game.hand_of(0).size()
				var bad := controller.submit_play(TestUtil.cards("AS AS AS AS AS"))
				assert_bool(bad.accepted).is_false()
				assert_int(controller.game.hand_of(0).size()).is_equal(before)
				rejected_once = true
			var view := controller.game.view_for(0)
			if view.can_pass and (view.legal_plays.is_empty() or rng.randf() < 0.3):
				controller.submit_pass()
			else:
				var choice: Play = view.legal_plays[rng.randi_range(0, view.legal_plays.size() - 1)]
				assert_bool(controller.submit_play(choice.cards).accepted).is_true()
		else:
			await get_tree().process_frame
	assert_bool(done[0]).is_true()
	assert_bool(rejected_once).is_true()
	assert_int(controller.game.ranking().size()).is_equal(4)


# --- waiting, the turn timer and pacing -------------------------------------------

## A 3-seat table with hand-picked cards. Seat 0 is the human. Seat 2 (a bot) leads its lowest
## card, a 5, so the human (holding only 3s and 4s) has nothing to play on it.
func _stuck_human_table(turn_seconds: float, think: float = 0.0) -> TableController:
	var controller := _controller(3, 0, 5)
	controller.think_time = think
	controller.turn_seconds = turn_seconds
	controller.game = Game.with_hands(TestUtil.hands(["3H 3S 4H", "6H 7H 8H", "5H AH 10H"]), 2)
	return controller


func test_human_with_nothing_to_play_is_not_passed_automatically() -> void:
	var controller := _stuck_human_table(10.0)
	controller.continue_game()
	assert_bool(controller.is_human_turn()).is_true()
	assert_int(controller.game.current_player).is_equal(0)
	assert_int(controller.game.legal_plays(0).size()).is_equal(0)
	for frame in 30:
		await get_tree().process_frame
	# Still waiting, nothing changed.
	assert_bool(controller.is_human_turn()).is_true()
	assert_int(controller.game.hand_of(0).size()).is_equal(3)
	assert_bool(controller.submit_pass().accepted).is_true()


func test_turn_timer_counts_down_while_waiting() -> void:
	var controller := _stuck_human_table(10.0)
	controller.continue_game()
	var start := controller.time_left
	assert_float(start).is_equal(10.0)
	for frame in 10:
		await get_tree().process_frame
	assert_bool(controller.time_left < start).is_true()


func test_running_out_of_time_passes_for_the_human() -> void:
	var controller := _stuck_human_table(0.15)
	var timed_out := [false]
	var passed := [false]
	controller.timed_out.connect(func() -> void: timed_out[0] = true)
	controller.move_made.connect(func(seat: int, play: Play, _result: MoveResult) -> void:
		if seat == 0 and play == null:
			passed[0] = true
	)
	controller.continue_game()
	var frames := 0
	while not timed_out[0] and frames < 600:
		frames += 1
		await get_tree().process_frame
	assert_bool(timed_out[0]).is_true()
	assert_bool(passed[0]).is_true()


func test_running_out_of_time_while_leading_plays_the_lowest_set() -> void:
	var controller := _controller(3, 0, 6)
	controller.think_time = 0.0
	controller.turn_seconds = 0.15
	controller.game = Game.with_hands(TestUtil.hands(["3H 3S 9H", "6H 7H 8H", "5H AH 10H"]), 0)
	var played: Array[Play] = []
	controller.move_made.connect(func(seat: int, play: Play, _result: MoveResult) -> void:
		if seat == 0:
			played.append(play)
	)
	controller.continue_game()
	var frames := 0
	while played.is_empty() and frames < 600:
		frames += 1
		await get_tree().process_frame
	assert_int(played.size()).is_greater_equal(1)
	assert_int(played[0].rank).is_equal(3)
	assert_int(played[0].size).is_equal(2)


func test_nothing_can_be_submitted_when_it_is_not_your_turn() -> void:
	var controller := _controller(3, 0, 7)
	controller.think_time = 5.0
	controller.game = Game.with_hands(TestUtil.hands(["3H 3S 9H", "6H 7H 8H", "5H AH 10H"]), 1)
	controller.continue_game()
	assert_bool(controller.is_human_turn()).is_false()
	assert_str(controller.submit_pass().reason).is_equal(MoveResult.REASON_NOT_YOUR_TURN)
	assert_str(controller.submit_play(TestUtil.cards("3H")).reason).is_equal(MoveResult.REASON_NOT_YOUR_TURN)


func test_bots_pause_before_moving() -> void:
	var controller := _controller(3, 0, 8)
	controller.think_time = 0.3
	controller.game = Game.with_hands(TestUtil.hands(["3H 3S 9H", "6H 7H 8H", "5H AH 10H"]), 1)
	controller.continue_game()
	# Seat 1 is a bot and has not moved yet...
	assert_int(controller.game.current_player).is_equal(1)
	assert_int(controller.game.hand_of(1).size()).is_equal(3)
	await get_tree().create_timer(0.6).timeout
	# ...but does after its thinking time.
	assert_int(controller.game.hand_of(1).size()).is_less(3)


func test_the_match_ends_after_its_last_game_with_scores_and_standings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var controller := TableController.new()
	add_child(controller)
	auto_free(controller)
	controller.think_time = 0.0
	controller.setup(4, Bot.Difficulty.MEDIUM, rng, -1, 2)
	var finished := []
	controller.game_finished.connect(func(_ranking: Array[int]) -> void:
		finished.append([controller.match_over, controller.scores.duplicate(), controller.standings.duplicate()])
	)
	controller.start_next_game()
	await _wait_for_game_over(controller)
	assert_bool(finished[0][0]).is_false()
	controller.start_next_game()
	await _wait_for_game_over(controller)
	assert_int(finished.size()).is_equal(2)
	assert_bool(finished[1][0]).is_true()
	assert_int(finished[1][1].size()).is_equal(4)
	assert_int(finished[1][2].size()).is_equal(4)
	assert_int(controller.state.total_games).is_equal(2)
