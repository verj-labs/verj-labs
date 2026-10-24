class_name Play
extends RefCounted
## A set of 1-4 cards of the same rank played together (GAME_RULES section 7).

const MIN_SIZE := 1
const MAX_SIZE := 4

var rank: int
var size: int
var cards: Array[Card] = []


## Builds a Play from cards, or returns null if they are not a legal set
## (empty, more than 4 cards, or mixed ranks).
static func from_cards(source: Array) -> Play:
	if source.size() < MIN_SIZE or source.size() > MAX_SIZE:
		return null
	var first: Card = source[0]
	for card: Card in source:
		if card.rank != first.rank:
			return null
	var play := Play.new()
	play.rank = first.rank
	play.size = source.size()
	for card: Card in source:
		play.cards.append(card)
	return play


## Builds a Play from card codes like ["7H", "7S"], or null if any code is bad or the set is illegal.
static func from_codes(codes: Array) -> Play:
	var cards: Array[Card] = []
	for code in codes:
		if not code is String:
			return null
		var card := Card.from_code(code)
		if card == null:
			return null
		cards.append(card)
	return Play.from_cards(cards)


func to_codes() -> Array[String]:
	var codes: Array[String] = []
	for card in cards:
		codes.append(card.to_code())
	return codes


func is_two() -> bool:
	return rank == Card.TWO


## Same ordering as Card.strength(): 3 < ... < A < 2.
func strength() -> int:
	return Card.TWO_STRENGTH if is_two() else rank


func to_text() -> String:
	var codes: PackedStringArray = []
	for card in cards:
		codes.append(card.to_code())
	return " ".join(codes)
