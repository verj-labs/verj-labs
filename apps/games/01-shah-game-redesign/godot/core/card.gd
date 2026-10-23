class_name Card
extends RefCounted
## One playing card. Immutable by convention: never change rank or suit after creation.

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }

const TWO := 2
const LOWEST_NORMAL := 3
const JACK := 11
const QUEEN := 12
const KING := 13
const ACE := 14

## 2 is not part of the normal 3..A order, but it outranks everything (GAME_RULES 3.2, 14.3).
const TWO_STRENGTH := 15

const SUIT_LETTERS := {"C": Suit.CLUBS, "D": Suit.DIAMONDS, "H": Suit.HEARTS, "S": Suit.SPADES}
const FACE_LETTERS := {"J": JACK, "Q": QUEEN, "K": KING, "A": ACE}

var rank: int
var suit: int


func _init(p_rank: int, p_suit: int) -> void:
	rank = p_rank
	suit = p_suit


static func is_valid_rank(p_rank: int) -> bool:
	return p_rank >= TWO and p_rank <= ACE


func is_two() -> bool:
	return rank == TWO


## Ordering used both for beating the pile and for card exchange. 3 < ... < A < 2.
func strength() -> int:
	return TWO_STRENGTH if is_two() else rank


## Short text like "7H", "10S", "KD", "2C". Returns null if the text is not a card.
static func from_code(code: String) -> Card:
	if code.length() < 2 or code.length() > 3:
		return null
	var suit_letter := code.substr(code.length() - 1).to_upper()
	var rank_text := code.substr(0, code.length() - 1).to_upper()
	if not SUIT_LETTERS.has(suit_letter):
		return null
	var parsed_rank := 0
	if FACE_LETTERS.has(rank_text):
		parsed_rank = FACE_LETTERS[rank_text]
	elif rank_text.is_valid_int():
		parsed_rank = rank_text.to_int()
	if not is_valid_rank(parsed_rank):
		return null
	return Card.new(parsed_rank, SUIT_LETTERS[suit_letter])


## "10", "J", "A", "2" ... for display.
func rank_text() -> String:
	for letter: String in FACE_LETTERS:
		if FACE_LETTERS[letter] == rank:
			return letter
	return str(rank)


func to_code() -> String:
	var rank_text := str(rank)
	for letter: String in FACE_LETTERS:
		if FACE_LETTERS[letter] == rank:
			rank_text = letter
	var suit_letter := ""
	for letter: String in SUIT_LETTERS:
		if SUIT_LETTERS[letter] == suit:
			suit_letter = letter
	return rank_text + suit_letter


## A fresh, ordered 52-card deck (no jokers).
static func full_deck() -> Array[Card]:
	var deck: Array[Card] = []
	for suit_value: int in Suit.values():
		for rank_value in range(TWO, ACE + 1):
			deck.append(Card.new(rank_value, suit_value))
	return deck
