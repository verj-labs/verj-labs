extends GdUnitTestSuite
## Card exchange between games. (GAME_RULES section 14)


func _codes(cards: Array) -> Array[String]:
	var result: Array[String] = []
	for card: Card in cards:
		result.append(card.to_code())
	result.sort()
	return result


func test_first_and_last_swap_two_cards_four_players() -> void:
	# Ranking: seat 2 won, seat 0 second, seat 3 second-last, seat 1 last.
	var hands := TestUtil.hands([
		"4H 9H JH",  # seat 0 (2nd)
		"3H 5H AH 2S",  # seat 1 (last): best two are 2S and AH
		"3S 4S 10H KH",  # seat 2 (1st): worst two are 3S and 4S
		"5S 6S QH",  # seat 3 (second-last)
	])
	Exchange.apply(hands, [2, 0, 3, 1] as Array[int])
	assert_array(_codes(hands[2])).contains_exactly(["10H", "2S", "AH", "KH"])
	assert_array(_codes(hands[1])).contains_exactly(["3H", "3S", "4S", "5H"])


func test_second_and_second_last_swap_one_card() -> void:
	var hands := TestUtil.hands([
		"4H 9H JH",  # seat 0 (2nd): gives worst (4H)
		"3H 5H AH 2S",
		"3S 4S 10H KH",
		"5S 6S QH",  # seat 3 (second-last): gives best (QH)
	])
	Exchange.apply(hands, [2, 0, 3, 1] as Array[int])
	assert_array(_codes(hands[0])).contains_exactly(["9H", "JH", "QH"])
	assert_array(_codes(hands[3])).contains_exactly(["4H", "5S", "6S"])


func test_three_players_only_swap_first_and_last() -> void:
	var hands := TestUtil.hands(["5H 6H 7H", "3H 4H KH AH", "8H 9H 10H"])
	# seat 2 is 1st, seat 0 is 2nd, seat 1 is last.
	var transfers := Exchange.apply(hands, [2, 0, 1] as Array[int])
	assert_int(transfers.size()).is_equal(2)
	assert_array(_codes(hands[0])).contains_exactly(["5H", "6H", "7H"])
	assert_array(_codes(hands[2])).contains_exactly(["10H", "AH", "KH"])
	assert_array(_codes(hands[1])).contains_exactly(["3H", "4H", "8H", "9H"])


func test_two_is_the_best_card_for_exchange() -> void:
	var hands := TestUtil.hands(["3H 4H 5H", "6H 2D 7H AS", "8H 9H 10H", "JH QH KH"])
	Exchange.apply(hands, [0, 2, 3, 1] as Array[int])
	# seat 1 (last) gave 2D and AS to seat 0 (first).
	assert_bool(_codes(hands[0]).has("2D")).is_true()
	assert_bool(_codes(hands[0]).has("AS")).is_true()


func test_suit_breaks_ties_so_the_result_is_stable() -> void:
	var hands := TestUtil.hands(["3H 3S 9H", "5H 6H", "7H 8H", "4H 4S"])
	# seat 0 is 1st and gives its 2 worst: the 3s. Both 3s go regardless of suit.
	Exchange.apply(hands, [0, 1, 2, 3] as Array[int])
	assert_bool(_codes(hands[3]).has("3H")).is_true()
	assert_bool(_codes(hands[3]).has("3S")).is_true()


func test_exchange_keeps_every_hand_size_the_same() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for players in [3, 4, 5, 6, 7, 8]:
		var dealt := Dealer.deal(players, rng)
		var sizes: Array[int] = []
		for hand: Array in dealt["hands"]:
			sizes.append(hand.size())
		var ranking: Array[int] = []
		for seat in players:
			ranking.append(seat)
		Exchange.apply(dealt["hands"], ranking)
		for seat in players:
			assert_int(dealt["hands"][seat].size()).is_equal(sizes[seat])
