class_name Dealer
extends RefCounted
## Shuffling and dealing (GAME_RULES section 4). Randomness is injected so tests can be repeatable.

## player count -> [cards each, discarded]
const DEAL_TABLE := {3: [17, 1], 4: [13, 0], 5: [10, 2], 6: [8, 4], 7: [7, 3], 8: [6, 4]}


static func is_supported_player_count(player_count: int) -> bool:
	return DEAL_TABLE.has(player_count)


## Returns {"hands": Array of Array[Card], "discarded": Array[Card]}.
static func deal(player_count: int, rng: RandomNumberGenerator) -> Dictionary:
	assert(is_supported_player_count(player_count), "player count must be 3..8")
	var deck := shuffled(Card.full_deck(), rng)
	var per_player: int = DEAL_TABLE[player_count][0]
	var hands: Array = []
	for player in player_count:
		var hand: Array[Card] = []
		for i in per_player:
			hand.append(deck.pop_back())
		hands.append(hand)
	return {"hands": hands, "discarded": deck}


## Fisher-Yates shuffle using our own RNG (Array.shuffle() uses the global one).
static func shuffled(cards: Array[Card], rng: RandomNumberGenerator) -> Array[Card]:
	var result: Array[Card] = cards.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
