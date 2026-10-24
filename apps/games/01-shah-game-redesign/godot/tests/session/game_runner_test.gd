extends GdUnitTestSuite
## GameRunner on simulated time: bot pacing, the human wait and timer, takeovers, and whole
## matches. No real clock is involved, so these are fast and deterministic.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## 3 seats; seat 0 human (or none). Hand-picked cards so the story is predictable.
func _runner(humans: Array[int], think: float = 1.0, turn: float = 10.0) -> GameRunner:
	var runner := GameRunner.new()
	runner.setup(3, Bot.Difficulty.MEDIUM, _rng(1), humans)
	runner.think_time = think
	runner.turn_seconds = turn
	runner.game = Game.with_hands(TestUtil.hands(["3H 3S 4H", "6H 7H 8H", "5H AH 10H"]), 2)
	return runner


func _advance(runner: GameRunner, seconds: float, step: float = 0.1) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		runner.tick(step)
		elapsed += step


func test_a_bot_waits_its_thinking_time_before_moving() -> void:
	var runner := _runner([0])
	runner.continue_game()
	assert_int(runner.game.hand_of(2).size()).is_equal(3)  # seat 2 (bot) has not moved yet
	_advance(runner, 0.5)
	assert_int(runner.game.hand_of(2).size()).is_equal(3)
	_advance(runner, 0.7)
	assert_int(runner.game.hand_of(2).size()).is_less(3)


func test_zero_think_time_plays_instantly_until_a_human_must_act() -> void:
	var runner := _runner([0], 0.0)
	runner.continue_game()
	assert_int(runner.waiting_seat).is_equal(0)
	assert_int(runner.game.current_player).is_equal(0)


func test_the_human_turn_starts_the_timer_and_waits_forever_without_input() -> void:
	var runner := _runner([0], 0.0, 10.0)
	var started: Array[int] = []
	runner.turn_started.connect(func(seat: int) -> void: started.append(seat))
	runner.continue_game()
	assert_array(started).is_equal([0])
	assert_float(runner.time_left).is_equal(10.0)
	_advance(runner, 4.0)
	assert_float(runner.time_left).is_between(5.5, 6.5)
	assert_int(runner.waiting_seat).is_equal(0)


func test_running_out_of_time_passes_for_the_human() -> void:
	var runner := _runner([0], 0.0, 3.0)
	var timeouts: Array[int] = []
	var passes: Array[int] = []
	runner.timed_out.connect(func(seat: int) -> void: timeouts.append(seat))
	runner.move_made.connect(func(seat: int, play: Play, _r: MoveResult) -> void:
		if play == null:
			passes.append(seat)
	)
	runner.continue_game()
	_advance(runner, 3.5)
	assert_array(timeouts).is_equal([0])
	assert_array(passes).contains([0])


func test_running_out_of_time_while_leading_plays_the_lowest_set() -> void:
	var runner := GameRunner.new()
	runner.setup(3, Bot.Difficulty.MEDIUM, _rng(2), [0] as Array[int])
	runner.think_time = 0.0
	runner.turn_seconds = 2.0
	runner.game = Game.with_hands(TestUtil.hands(["3H 3S 9H", "6H 7H 8H", "5H AH 10H"]), 0)
	var plays: Array[Play] = []
	runner.move_made.connect(func(seat: int, play: Play, _r: MoveResult) -> void:
		if seat == 0:
			plays.append(play)
	)
	runner.continue_game()
	_advance(runner, 2.5)
	assert_int(plays[0].rank).is_equal(3)
	assert_int(plays[0].size).is_equal(2)


func test_only_the_waiting_seat_may_move() -> void:
	var runner := _runner([0], 0.0)
	runner.continue_game()
	assert_str(runner.submit_pass(1).reason).is_equal(MoveResult.REASON_NOT_YOUR_TURN)
	assert_str(runner.submit_play(1, TestUtil.cards("6H")).reason).is_equal(MoveResult.REASON_NOT_YOUR_TURN)
	assert_bool(runner.submit_pass(0).accepted).is_true()


func test_a_rejected_move_changes_nothing_and_keeps_the_timer() -> void:
	var runner := _runner([0], 0.0, 10.0)
	runner.continue_game()
	var before := runner.game.hand_of(0).size()
	var result := runner.submit_play(0, TestUtil.cards("3H"))  # 5 on the pile, 3 is too low
	assert_bool(result.accepted).is_false()
	assert_int(runner.game.hand_of(0).size()).is_equal(before)
	assert_int(runner.waiting_seat).is_equal(0)


func test_handing_a_waiting_seat_to_a_bot_lets_the_game_carry_on() -> void:
	var runner := _runner([0, 1], 0.0)
	runner.continue_game()
	assert_int(runner.waiting_seat).is_equal(0)
	runner.make_bot(0)
	assert_bool(runner.is_human(0)).is_false()
	assert_int(runner.waiting_seat).is_equal(1)  # the bot at seat 0 played; now human seat 1


func test_a_seat_can_be_taken_back_from_the_bot() -> void:
	var runner := _runner([0], 0.0)
	runner.make_bot(0)
	runner.make_human(0)
	assert_bool(runner.is_human(0)).is_true()


func test_event_pauses_delay_the_next_player() -> void:
	# After a SKIP the next actor waits an extra beat on top of thinking time.
	var runner := GameRunner.new()
	runner.setup(3, Bot.Difficulty.EASY, _rng(3), [] as Array[int])
	runner.think_time = 1.0
	runner.game = Game.with_hands(TestUtil.hands(["8H 3H 4H", "8S 5H 6H", "7H 9H 10H"]), 0)
	runner._extra = 0.0
	var result := runner.game.play(0, TestUtil.cards("8H"))
	runner._after_move(0, Play.from_codes(["8H"]), result)
	assert_float(runner._cooldown).is_equal(1.0)  # plain move: just thinking time
	var skip := runner.game.play(1, TestUtil.cards("8S"))
	assert_int(skip.effect).is_equal(PlayResult.Effect.SKIP)
	runner._after_move(1, Play.from_codes(["8S"]), skip)
	assert_float(runner._cooldown).is_equal_approx(1.6, 0.001)  # + 0.6 event pause


func test_hold_for_delays_the_first_move_of_a_game() -> void:
	var runner := GameRunner.new()
	runner.setup(3, Bot.Difficulty.MEDIUM, _rng(4), [] as Array[int])
	runner.think_time = 1.0
	runner.game_started.connect(func() -> void: runner.hold_for(5.0))
	runner.start_next_game()
	var first := runner.game.current_player
	var before := runner.game.hand_of(first).size()
	_advance(runner, 4.0)
	assert_int(runner.game.hand_of(first).size()).is_equal(before)  # still held (5s + 1s thinking)
	_advance(runner, 3.0)
	assert_int(runner.game.hand_of(first).size()).is_less(before)


func test_an_all_bot_match_plays_to_the_end_on_simulated_time(players: int, test_parameters := [[3], [5], [8]]) -> void:
	var runner := GameRunner.new()
	runner.setup(players, Bot.Difficulty.MEDIUM, _rng(10 + players), [] as Array[int])
	runner.think_time = 0.5
	var finished := [false]
	runner.game_finished.connect(func(_r: Array[int]) -> void: finished[0] = true)
	runner.start_next_game()
	var simulated := 0.0
	while not finished[0] and simulated < 2000.0:
		runner.tick(0.1)
		simulated += 0.1
	assert_bool(finished[0]).is_true()
	assert_int(runner.game.ranking().size()).is_equal(players)


func test_game_finished_is_reported_once_and_games_chain() -> void:
	var runner := GameRunner.new()
	runner.setup(4, Bot.Difficulty.MEDIUM, _rng(21), [] as Array[int])
	runner.think_time = 0.0
	var reports := [0]
	runner.game_finished.connect(func(_r: Array[int]) -> void: reports[0] += 1)
	runner.start_next_game()
	runner.tick(0.1)
	runner.tick(0.1)
	assert_int(reports[0]).is_equal(1)
	runner.start_next_game()
	assert_int(reports[0]).is_equal(2)
	assert_int(runner.games_played()).is_equal(2)


func test_a_whole_match_with_a_human_who_always_plays_something() -> void:
	var runner := GameRunner.new()
	runner.setup(4, Bot.Difficulty.MEDIUM, _rng(30), [0] as Array[int])
	runner.think_time = 0.0
	runner.turn_seconds = 5.0
	var finished := [false]
	runner.game_finished.connect(func(_r: Array[int]) -> void: finished[0] = true)
	runner.start_next_game()
	var guard := 0
	while not finished[0] and guard < 5000:
		guard += 1
		if runner.waiting_seat == 0:
			var view := runner.game.view_for(0)
			if view.legal_plays.is_empty():
				runner.submit_pass(0)
			else:
				runner.submit_play(0, view.legal_plays[0].cards)
		else:
			runner.tick(0.1)
	assert_bool(finished[0]).is_true()
