extends GdUnitTestSuite
## "Can a game ever get stuck?" Plays lots of random games and checks the invariants:
## it always finishes, nobody is ever without a move, no card appears or vanishes,
## and the final ranking contains every player exactly once.

const GAMES_PER_PLAYER_COUNT := 150


func test_random_games_always_finish_cleanly(players: int, test_parameters := [[3], [4], [5], [6], [7], [8]]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + players
	for game_number in GAMES_PER_PLAYER_COUNT:
		var dealt := Dealer.deal(players, rng)
		var game := Game.with_hands(
			dealt["hands"],
			rng.randi_range(0, players - 1),
			Direction.CLOCKWISE if rng.randf() < 0.5 else Direction.COUNTER_CLOCKWISE,
			dealt["discarded"]
		)
		var errors: Array[String] = []
		var moves := TestUtil.play_random_game(game, rng, errors, rng.randf() * 0.6)
		assert_array(errors).is_empty()
		assert_bool(moves > 0).is_true()
		var ranking := game.ranking()
		assert_int(ranking.size()).is_equal(players)
		var seen := {}
		for seat in ranking:
			seen[seat] = true
		assert_int(seen.size()).is_equal(players)


func test_matches_of_ten_games_keep_working(players: int, test_parameters := [[3], [4], [8]]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + players
	var match_session := ShahMatch.new(players, rng)
	for game_number in 10:
		var game := match_session.start_next_game()
		var errors: Array[String] = []
		TestUtil.play_random_game(game, rng, errors)
		assert_array(errors).is_empty()
		assert_bool(game.is_over()).is_true()
	assert_int(match_session.games_played).is_equal(10)
