class_name Exchange
extends RefCounted
## Card exchange between games (GAME_RULES section 14), applied to freshly dealt hands.
##
## - 1st place gives their 2 worst cards to last place; last place gives their 2 best to 1st.
## - With 4+ players, 2nd gives 1 worst to second-last; second-last gives 1 best to 2nd.
## "Best" = highest rank (3 < ... < A). A 2 is never exchanged: it is the only way a loser can
## win a game back, so the best card anyone can be asked to give is an Ace. Ties between equal
## ranks are broken by suit so the result is always the same.

const TOP_PAIR_CARDS := 2
const SECOND_PAIR_CARDS := 1
const MIN_PLAYERS_FOR_SECOND_PAIR := 4


## `ranking` lists seats, 1st place first. Changes `hands` in place.
## Returns one entry per transfer: {"from": seat, "to": seat, "cards": Array[Card]}.
static func apply(hands: Array, ranking: Array[int]) -> Array[Dictionary]:
	var transfers: Array[Dictionary] = []
	var count := ranking.size()
	_swap(hands, ranking[0], ranking[count - 1], TOP_PAIR_CARDS, transfers)
	if count >= MIN_PLAYERS_FOR_SECOND_PAIR:
		_swap(hands, ranking[1], ranking[count - 2], SECOND_PAIR_CARDS, transfers)
	return transfers


## `high` gives away their `amount` worst cards, `low` gives away their `amount` best.
static func _swap(
	hands: Array, high: int, low: int, amount: int, transfers: Array[Dictionary]
) -> void:
	var from_high := _take(hands[high], amount, false)
	var from_low := _take(hands[low], amount, true)
	hands[high].append_array(from_low)
	hands[low].append_array(from_high)
	transfers.append({"from": high, "to": low, "cards": from_high})
	transfers.append({"from": low, "to": high, "cards": from_low})


## Removes and returns the `amount` best (or worst) cards from `hand`, never a 2.
static func _take(hand: Array, amount: int, best: bool) -> Array[Card]:
	var sorted: Array[Card] = []
	var twos: Array[Card] = []
	for card: Card in hand:
		if card.is_two():
			twos.append(card)
		else:
			sorted.append(card)
	assert(sorted.size() >= amount, "a hand always has more non-2 cards than an exchange takes")
	sorted.sort_custom(_weaker_first)
	var taken: Array[Card] = []
	for i in amount:
		taken.append(sorted.pop_back() if best else sorted.pop_front())
	hand.clear()
	hand.append_array(sorted)
	hand.append_array(twos)
	return taken


static func _weaker_first(a: Card, b: Card) -> bool:
	if a.rank != b.rank:
		return a.rank < b.rank
	return a.suit < b.suit
