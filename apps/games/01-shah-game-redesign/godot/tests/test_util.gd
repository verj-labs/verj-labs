class_name TestUtil
extends RefCounted
## Test helpers so tests read like the rulebook: TestUtil.play("9H 9S") is a double 9.


static func play(codes: String) -> Play:
	var cards: Array[Card] = []
	for code in codes.split(" ", false):
		var card := Card.from_code(code)
		assert(card != null, "bad card code in test: " + code)
		cards.append(card)
	return Play.from_cards(cards)
