extends GdUnitTestSuite
## TableState: what one player may see, and its trip through JSON.


func _state_for(seat: int) -> TableState:
	var game := Game.with_hands(TestUtil.hands(["3H 4H 5H", "6H 7H 8H 9H", "10H JH"]), 0)
	game.play(0, TestUtil.cards("3H"))
	var names: Array[String] = ["A", "B", "C"]
	var kinds: Array[String] = ["human", "bot", "bot"]
	return TableState.from_game(game, seat, names, kinds, 2)


func test_shows_only_your_own_hand_and_the_others_sizes() -> void:
	var state := _state_for(1)
	assert_int(state.my_hand.size()).is_equal(4)
	assert_array(state.hand_sizes).is_equal([2, 4, 2])
	assert_int(state.hand_size(2)).is_equal(2)


func test_reflects_the_table() -> void:
	var state := _state_for(0)
	assert_int(state.pile.rank).is_equal(3)
	assert_int(state.pile_owner).is_equal(0)
	assert_int(state.current_player).is_equal(1)
	assert_int(state.game_number).is_equal(2)
	assert_bool(state.is_over()).is_false()


func test_round_trips_through_json_text() -> void:
	var original := _state_for(1)
	var text := JSON.stringify(original.to_dict())
	var copy := TableState.from_dict(JSON.parse_string(text))
	assert_object(copy).is_not_null()
	assert_int(copy.my_seat).is_equal(1)
	assert_array(copy.hand_sizes).is_equal([2, 4, 2])
	assert_int(copy.my_hand.size()).is_equal(4)
	assert_str(copy.my_hand[0].to_code()).is_equal(original.my_hand[0].to_code())
	assert_array(copy.pile.to_codes()).is_equal(original.pile.to_codes())
	assert_int(copy.current_player).is_equal(1)
	assert_array(copy.names).is_equal(["A", "B", "C"])


func test_an_empty_pile_survives_the_trip() -> void:
	var game := Game.with_hands(TestUtil.hands(["3H 4H", "6H 7H", "10H JH"]), 0)
	var names: Array[String] = ["A", "B", "C"]
	var kinds: Array[String] = ["human", "bot", "bot"]
	var state := TableState.from_game(game, 0, names, kinds, 1)
	var copy := TableState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_object(copy.pile).is_null()


func test_malformed_data_is_rejected_not_crashed_on(
	bad: Variant, test_parameters := [[null], ["text"], [42], [{}], [{"game_number": 1}]]
) -> void:
	assert_object(TableState.from_dict(bad)).is_null()


func test_a_bad_card_code_is_rejected() -> void:
	var data := _state_for(0).to_dict()
	data["my_hand"] = ["3H", "ZZ"]
	assert_object(TableState.from_dict(data)).is_null()


func test_wrong_player_count_or_array_sizes_are_rejected() -> void:
	var data := _state_for(0).to_dict()
	data["names"] = ["A", "B"]
	assert_object(TableState.from_dict(data)).is_null()
	var data2 := _state_for(0).to_dict()
	data2["player_count"] = 12
	assert_object(TableState.from_dict(data2)).is_null()


func test_legal_plays_and_evaluate_use_my_hand_and_the_pile() -> void:
	var state := _state_for(1)  # pile is a single 3; hand 6H 7H 8H 9H
	assert_int(state.legal_plays().size()).is_equal(4)
	assert_bool(state.evaluate(TestUtil.play("6H")).legal).is_true()
	assert_bool(state.evaluate(TestUtil.play("6H 6S")).legal).is_false()  # size must match the pile


func test_skipped_and_declined_come_through() -> void:
	var game := Game.with_hands(TestUtil.hands(["8H 3H 4H", "8S 5H 6H", "7H 9H 10H"]), 0)
	game.play(0, TestUtil.cards("8H"))
	game.play(1, TestUtil.cards("8S"))
	game.pass_turn(0)
	var names: Array[String] = ["A", "B", "C"]
	var kinds: Array[String] = ["human", "bot", "bot"]
	var state := TableState.from_game(game, 0, names, kinds, 1)
	assert_bool(state.is_skipped(2)).is_true()
	assert_bool(state.has_declined(0)).is_true()


func test_remembers_how_long_the_match_is() -> void:
	var game := Game.with_hands(TestUtil.hands(["3H 4H 5H", "6H 7H 8H 9H", "10H JH"]), 0)
	var names: Array[String] = ["A", "B", "C"]
	var kinds: Array[String] = ["human", "bot", "bot"]
	var state := TableState.from_game(game, 0, names, kinds, 3, 20)
	var copy := TableState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_int(copy.total_games).is_equal(20)
	assert_int(copy.game_number).is_equal(3)
