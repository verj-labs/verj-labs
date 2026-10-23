extends GdUnitTestSuite
## Dealing and direction. (GAME_RULES sections 4 and 6.3)


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_deal_table_matches_the_rules(
	players: int,
	each: int,
	discarded: int,
	test_parameters := [[3, 17, 1], [4, 13, 0], [5, 10, 2], [6, 8, 4], [7, 7, 3], [8, 6, 4]]
) -> void:
	var dealt := Dealer.deal(players, _rng())
	assert_int(dealt["hands"].size()).is_equal(players)
	for hand: Array in dealt["hands"]:
		assert_int(hand.size()).is_equal(each)
	assert_int(dealt["discarded"].size()).is_equal(discarded)


func test_every_card_is_dealt_exactly_once(players: int, test_parameters := [[3], [4], [5], [6], [7], [8]]) -> void:
	var dealt := Dealer.deal(players, _rng(7))
	var seen := {}
	for hand: Array in dealt["hands"]:
		for card: Card in hand:
			seen[card.to_code()] = true
	for card: Card in dealt["discarded"]:
		seen[card.to_code()] = true
	assert_int(seen.size()).is_equal(52)


func test_same_seed_gives_the_same_deal() -> void:
	var a := Dealer.deal(4, _rng(42))
	var b := Dealer.deal(4, _rng(42))
	assert_str(a["hands"][0][0].to_code()).is_equal(b["hands"][0][0].to_code())
	assert_str(a["hands"][3][12].to_code()).is_equal(b["hands"][3][12].to_code())


func test_different_seeds_shuffle_differently() -> void:
	var a := Dealer.deal(4, _rng(1))
	var b := Dealer.deal(4, _rng(2))
	var same := true
	for i in 13:
		if a["hands"][0][i].to_code() != b["hands"][0][i].to_code():
			same = false
	assert_bool(same).is_false()


func test_unsupported_player_counts() -> void:
	assert_bool(Dealer.is_supported_player_count(2)).is_false()
	assert_bool(Dealer.is_supported_player_count(9)).is_false()


# Direction: winner = seat 0, seats numbered clockwise.
func test_second_place_on_the_clockwise_side_means_clockwise(
	players: int, second: int, test_parameters := [[4, 1], [5, 1], [5, 2], [6, 2], [8, 3]]
) -> void:
	assert_int(Direction.for_next_game(players, 0, second)).is_equal(Direction.CLOCKWISE)


func test_second_place_on_the_other_side_means_counter_clockwise(
	players: int, second: int, test_parameters := [[4, 3], [5, 3], [5, 4], [6, 4], [8, 5], [8, 7]]
) -> void:
	assert_int(Direction.for_next_game(players, 0, second)).is_equal(Direction.COUNTER_CLOCKWISE)


func test_direction_is_relative_to_the_winner_not_seat_zero() -> void:
	# Winner in seat 3 of 5, 2nd place in seat 4: one step clockwise of the winner.
	assert_int(Direction.for_next_game(5, 3, 4)).is_equal(Direction.CLOCKWISE)
	# Winner in seat 1, 2nd place in seat 0: one step counter-clockwise.
	assert_int(Direction.for_next_game(5, 1, 0)).is_equal(Direction.COUNTER_CLOCKWISE)


func test_opposite_seat_defaults_to_clockwise() -> void:
	assert_int(Direction.for_next_game(4, 0, 2)).is_equal(Direction.CLOCKWISE)
