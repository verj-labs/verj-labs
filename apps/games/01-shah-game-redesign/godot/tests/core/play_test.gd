extends GdUnitTestSuite
## Plays: a set of 1-4 cards of equal rank. (GAME_RULES section 7)


func test_valid_set_sizes_one_to_four(
	codes: String,
	expected_size: int,
	test_parameters := [["7H", 1], ["7H 7S", 2], ["7H 7S 7D", 3], ["7H 7S 7D 7C", 4]]
) -> void:
	var play := TestUtil.play(codes)
	assert_object(play).is_not_null()
	assert_int(play.size).is_equal(expected_size)
	assert_int(play.rank).is_equal(7)


func test_mixed_ranks_are_not_a_play() -> void:
	assert_object(TestUtil.play("7H 8S")).is_null()


func test_mixed_ranks_hidden_at_the_end_are_not_a_play() -> void:
	assert_object(TestUtil.play("7H 7S 7D 8C")).is_null()


func test_empty_set_is_not_a_play() -> void:
	assert_object(Play.from_cards([])).is_null()


func test_five_cards_is_not_a_play() -> void:
	# Impossible in a real deck (4 suits), but the engine should not rely on that.
	var cards: Array[Card] = []
	for i in 5:
		cards.append(Card.new(9, Card.Suit.HEARTS))
	assert_object(Play.from_cards(cards)).is_null()


func test_set_of_twos_is_a_play_and_is_flagged_as_two() -> void:
	var play := TestUtil.play("2H 2S")
	assert_int(play.size).is_equal(2)
	assert_bool(play.is_two()).is_true()
