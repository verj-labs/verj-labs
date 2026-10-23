class_name TableFx
extends Node
## Directs the card animations: throwing a play onto the pile, and the card exchange between
## games (cards leave a hand and shrink into the other player's seat, or grow out of a seat
## into your hand). Pure presentation: it never touches the game state.

const HAND_CARD := CardView.CARD_SIZE
const PILE_CARD := PileView.SMALL_CARD
const SEAT_START_SCALE := 0.5
const THROW_SECONDS := 0.45
const THROW_STAGGER := 0.07
const SHRUNK_SCALE := 0.18
const MOVE_SECONDS := 0.75
const MOVE_STAGGER := 0.14
const INTRO_SECONDS := 1.2
const STEP_PAUSE := 0.45
const FINISH_PAUSE := 0.4

var human_seat: int = 0

var _layer: FxLayer
var _ring: TableRing
var _hand: HandView


func setup(layer: FxLayer, ring: TableRing, hand: HandView) -> void:
	_layer = layer
	_ring = ring
	_hand = hand


## How long run_exchange takes, so the game can wait for it.
static func exchange_seconds(transfers: Array[Dictionary], human_seat: int) -> float:
	var mine := 0
	for transfer in transfers:
		if transfer["from"] == human_seat or transfer["to"] == human_seat:
			mine += 1
	var one_step := MOVE_SECONDS + MOVE_STAGGER * 2 + STEP_PAUSE
	return INTRO_SECONDS + mine * one_step + FINISH_PAUSE


## Cards fly from where they were played (a seat, or the exact cards in your hand) to the pile.
## Returns when the last card has landed.
func throw_play(seat: int, play: Play, hand_origins: Array[Vector2]) -> void:
	var landings := _ring.pile_view.landing_centers(play.size)
	var last: Tween = null
	for i in play.size:
		var from := _ring.seat_center(seat)
		var start_scale := SEAT_START_SCALE
		if seat == human_seat and i < hand_origins.size():
			from = hand_origins[i]
			start_scale = HAND_CARD.x / PILE_CARD.x
		last = _layer.fly(play.cards[i], false, from, landings[i], PILE_CARD, start_scale, 1.0, THROW_SECONDS, i * THROW_STAGGER)
		AudioDirector.play_sfx_after(i * THROW_STAGGER, "throw", 0.06)
		AudioDirector.play_sfx_after(i * THROW_STAGGER + THROW_SECONDS - 0.04, "land", 0.08)
	await last.finished


## Plays the whole exchange. `dealt` is your hand before it, `final_hand` after it.
func run_exchange(transfers: Array[Dictionary], dealt: Array[Card], final_hand: Array[Card]) -> void:
	var working: Array[Card] = dealt.duplicate()
	_hand.set_cards(working)
	await _wait(INTRO_SECONDS)
	if not is_inside_tree():
		return
	var gives: Array[Dictionary] = []
	var receives: Array[Dictionary] = []
	for transfer in transfers:
		if transfer["from"] == human_seat:
			gives.append(transfer)
		elif transfer["to"] == human_seat:
			receives.append(transfer)
		else:
			_fly_between_seats(transfer)
	for transfer in gives:
		await _give_from_hand(transfer, working)
	for transfer in receives:
		await _receive_into_hand(transfer, working)
	await _wait(FINISH_PAUSE)
	_hand.set_cards(final_hand)


## Your cards shrink away into the other player's seat.
func _give_from_hand(transfer: Dictionary, working: Array[Card]) -> void:
	var cards: Array = transfer["cards"]
	var centers: Array[Vector2] = []
	for card: Card in cards:
		centers.append(_hand.card_center(card))
		_remove_card(working, card)
	_hand.set_cards(working)
	var last: Tween = null
	for i in cards.size():
		last = _layer.fly(cards[i], false, centers[i], _ring.seat_center(transfer["to"]), HAND_CARD, 1.0, SHRUNK_SCALE, MOVE_SECONDS, i * MOVE_STAGGER, true)
		AudioDirector.play_sfx_after(i * MOVE_STAGGER, "swoosh_out", 0.04)
	await last.finished
	await _wait(STEP_PAUSE)


## Cards grow out of the other player's seat and slide into place in your hand.
func _receive_into_hand(transfer: Dictionary, working: Array[Card]) -> void:
	var cards: Array = transfer["cards"]
	var arriving: Array[Card] = []
	for card: Card in cards:
		working.append(card)
		arriving.append(card)
	_hand.set_cards(working, arriving)
	var last: Tween = null
	for i in cards.size():
		var card: Card = cards[i]
		last = _layer.fly(card, false, _ring.seat_center(transfer["from"]), _hand.card_center(card), HAND_CARD, SHRUNK_SCALE, 1.0, MOVE_SECONDS, i * MOVE_STAGGER)
		last.finished.connect(func() -> void: _hand.reveal(card))
		AudioDirector.play_sfx_after(i * MOVE_STAGGER, "swoosh_in", 0.04)
	await last.finished
	await _wait(STEP_PAUSE)


## Exchange between two other players: face-down cards hop from seat to seat.
func _fly_between_seats(transfer: Dictionary) -> void:
	var cards: Array = transfer["cards"]
	for i in cards.size():
		_layer.fly(cards[i], true, _ring.seat_center(transfer["from"]), _ring.seat_center(transfer["to"]), PILE_CARD, SEAT_START_SCALE, SHRUNK_SCALE, MOVE_SECONDS, i * MOVE_STAGGER, true)
		AudioDirector.play_sfx_after(i * MOVE_STAGGER, "swoosh_out", 0.08, -9.0)


func _remove_card(list: Array[Card], target: Card) -> void:
	for i in list.size():
		if list[i].rank == target.rank and list[i].suit == target.suit:
			list.remove_at(i)
			return


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
