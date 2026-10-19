extends GdUnitTestSuite
## Cards: parsing, ordering, deck. (GAME_RULES sections 3 and 4)


func test_full_deck_has_52_unique_cards() -> void:
	var deck := Card.full_deck()
	var codes := {}
	for card in deck:
		codes[card.to_code()] = true
	assert_int(deck.size()).is_equal(52)
	assert_int(codes.size()).is_equal(52)


func test_ordering_is_3_to_ace_then_2_highest() -> void:
	var order := "3H 4H 5H 6H 7H 8H 9H 10H JH QH KH AH 2H".split(" ")
	for i in range(order.size() - 1):
		var lower := Card.from_code(order[i])
		var higher := Card.from_code(order[i + 1])
		assert_bool(lower.strength() < higher.strength()).is_true()


func test_two_is_a_power_card() -> void:
	assert_bool(Card.from_code("2S").is_two()).is_true()
	assert_bool(Card.from_code("AS").is_two()).is_false()


func test_from_code_parses_faces_tens_and_suits() -> void:
	var ten := Card.from_code("10S")
	assert_int(ten.rank).is_equal(10)
	assert_int(ten.suit).is_equal(Card.Suit.SPADES)
	assert_int(Card.from_code("kd").rank).is_equal(Card.KING)
	assert_int(Card.from_code("AC").rank).is_equal(Card.ACE)


func test_to_code_round_trips_for_every_card_in_the_deck() -> void:
	for card in Card.full_deck():
		var parsed := Card.from_code(card.to_code())
		assert_int(parsed.rank).is_equal(card.rank)
		assert_int(parsed.suit).is_equal(card.suit)


func test_from_code_rejects_garbage(code: String, test_parameters := [[""], ["7"], ["1H"], ["15H"], ["7X"], ["HH"], ["77H"]]) -> void:
	assert_object(Card.from_code(code)).is_null()
