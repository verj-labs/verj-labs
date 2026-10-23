extends GdUnitTestSuite
## Chaining games into a match. (GAME_RULES sections 2.1, 6.1, 6.2, 6.3, 14)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_first_game_is_clockwise_with_a_valid_random_starter() -> void:
	var match_session := ShahMatch.new(5, _rng(3))
	var game := match_session.start_next_game()
	assert_int(game.direction).is_equal(Direction.CLOCKWISE)
	assert_bool(game.current_player >= 0 and game.current_player < 5).is_true()
	assert_int(match_session.games_played).is_equal(1)


func test_winner_starts_the_next_game_and_second_place_sets_direction() -> void:
	var rng := _rng(11)
	var match_session := ShahMatch.new(4, rng)
	var first := match_session.start_next_game()
	var errors: Array[String] = []
	TestUtil.play_random_game(first, rng, errors)
	assert_array(errors).is_empty()
	var ranking := first.ranking()
	var second := match_session.start_next_game()
	assert_int(second.current_player).is_equal(ranking[0])
	assert_int(second.direction).is_equal(Direction.for_next_game(4, ranking[0], ranking[1]))


func test_next_game_hands_are_exchanged_and_keep_their_size() -> void:
	var rng := _rng(21)
	var match_session := ShahMatch.new(6, rng)
	var first := match_session.start_next_game()
	var errors: Array[String] = []
	TestUtil.play_random_game(first, rng, errors)
	var second := match_session.start_next_game()
	for seat in 6:
		assert_int(second.hand_of(seat).size()).is_equal(8)
	assert_int(second.discarded.size()).is_equal(4)


func test_dealt_hands_are_kept_so_the_exchange_can_be_shown() -> void:
	var rng := _rng(31)
	var match_session := ShahMatch.new(4, rng)
	var first := match_session.start_next_game()
	var errors: Array[String] = []
	TestUtil.play_random_game(first, rng, errors)
	var second := match_session.start_next_game()
	assert_int(match_session.dealt_hands.size()).is_equal(4)
	var transfers := match_session.last_transfers
	assert_int(transfers.size()).is_equal(4)
	for transfer in transfers:
		for card: Card in transfer["cards"]:
			var code := card.to_code()
			assert_bool(_codes(match_session.dealt_hands[transfer["from"]]).has(code)).is_true()
			assert_bool(_codes(second.hand_of(transfer["to"])).has(code)).is_true()
			assert_bool(_codes(second.hand_of(transfer["from"])).has(code)).is_false()


func test_the_first_game_has_no_exchange() -> void:
	var match_session := ShahMatch.new(4, _rng(32))
	match_session.start_next_game()
	assert_array(match_session.last_transfers).is_empty()


func _codes(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card: Card in cards:
		result.append(card.to_code())
	return result
