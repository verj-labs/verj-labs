class_name Game
extends RefCounted
## One full game: from the deal until every player has finished. Pure logic: no nodes,
## no timers. The caller (UI, bot driver, server) asks "whose turn", then calls play() or
## pass_turn(). Rejected moves change nothing.
##
## Defaults where GAME_RULES is silent (see docs/OPEN_QUESTIONS.md):
## - After a 2-reset the player must lead again (an empty table cannot be passed on).
## - If a reset empties the player's hand they finish, and the next active player leads.
## - If the player who won a round has already finished, the next active player in the
##   direction of play leads the new round.

var player_count: int = 0
## Array of Array[Card], index = seat.
var hands: Array = []
var discarded: Array[Card] = []
var direction: int = Direction.CLOCKWISE
## Seat whose turn it is, or -1 when the game is over.
var current_player: int = -1
## Top play on the table, or null when the next player must lead a new round.
var pile: Play = null
## Who made the play on top of the pile, or -1 when the table is empty.
var pile_owner: int = -1
## Seats in the order they emptied their hand: index 0 = 1st place.
var finished: Array[int] = []

## Players who have passed since the last play.
var _declined := {}
## The player who was skipped most recently and has not had a turn since (at most one: a new
## skip replaces the mark). Before a round can be won they are offered a turn.
var _skipped := {}


static func with_hands(
	p_hands: Array,
	start_player: int,
	p_direction: int = Direction.CLOCKWISE,
	p_discarded: Array[Card] = []
) -> Game:
	assert(p_hands.size() >= 3, "a game needs at least 3 players")
	assert(start_player >= 0 and start_player < p_hands.size(), "start player out of range")
	var game := Game.new()
	game.player_count = p_hands.size()
	for hand: Array in p_hands:
		var copy: Array[Card] = []
		copy.assign(hand)
		game.hands.append(copy)
	game.discarded = p_discarded.duplicate()
	game.direction = p_direction
	game.current_player = start_player
	return game


func is_over() -> bool:
	return current_player == -1


func hand_of(player: int) -> Array[Card]:
	var hand: Array[Card] = hands[player]
	return hand


## True if the player has passed since the last play on the table.
func has_declined(player: int) -> bool:
	return _declined.has(player)


## True if the player was skipped and has not had a turn since.
func is_skipped(player: int) -> bool:
	return _skipped.has(player)


## What would happen if the current player made `candidate` now.
func evaluate(candidate: Play) -> PlayResult:
	return PlayRules.evaluate(pile, candidate)


func is_finished(player: int) -> bool:
	return finished.has(player)


## Seats that still hold cards, in seat order.
func active_players() -> Array[int]:
	var result: Array[int] = []
	for seat in player_count:
		if not is_finished(seat):
			result.append(seat)
	return result


## Final order, 1st place first. Only complete once the game is over.
func ranking() -> Array[int]:
	return finished.duplicate()


func play(player: int, cards: Array) -> MoveResult:
	var guard := _check_turn(player)
	if guard != null:
		return guard
	var chosen := Play.from_cards(cards)
	if chosen == null:
		return MoveResult.rejected(MoveResult.REASON_NOT_A_SET)
	if not _holds_all(player, cards):
		return MoveResult.rejected(MoveResult.REASON_CARDS_NOT_IN_HAND)
	var verdict := evaluate(chosen)
	if not verdict.legal:
		return MoveResult.rejected(verdict.reason)

	_skipped.erase(player)
	_remove_from_hand(player, cards)
	var result := MoveResult.ok()
	result.effect = verdict.effect
	if hand_of(player).is_empty():
		finished.append(player)
		result.player_finished = true
	if _finish_game_if_one_left(result):
		return result

	if verdict.effect == PlayResult.Effect.RESET:
		_clear_table()
		current_player = _next_active(player, true)
		return result

	pile = chosen
	pile_owner = player
	_declined.clear()
	var next := _next_active(player, false)
	if verdict.effect == PlayResult.Effect.SKIP:
		_skipped.clear()
		_skipped[next] = true
		result.skipped_player = next
		next = _next_active(next, false)
	current_player = next
	_settle_round(result)
	return result


func pass_turn(player: int) -> MoveResult:
	var guard := _check_turn(player)
	if guard != null:
		return guard
	if pile == null:
		return MoveResult.rejected(MoveResult.REASON_MUST_LEAD)
	var result := MoveResult.ok()
	_skipped.erase(player)
	_declined[player] = true
	current_player = _next_active(player, false)
	_settle_round(result)
	return result


## One representative play for every rank and set size the player can legally make now.
## (Which suits are used does not matter to the rules.)
func legal_plays(player: int) -> Array[Play]:
	var by_rank := {}
	for card in hand_of(player):
		if not by_rank.has(card.rank):
			by_rank[card.rank] = [] as Array[Card]
		by_rank[card.rank].append(card)
	var ranks := by_rank.keys()
	ranks.sort()
	var result: Array[Play] = []
	for rank: int in ranks:
		var group: Array = by_rank[rank]
		for size in range(Play.MIN_SIZE, mini(group.size(), Play.MAX_SIZE) + 1):
			var candidate := Play.from_cards(group.slice(0, size))
			if evaluate(candidate).legal:
				result.append(candidate)
	return result


## What `player` can see right now. Hand cards are shared objects, never edit them.
func view_for(player: int) -> PlayerView:
	var view := PlayerView.new()
	view.seat = player
	view.player_count = player_count
	view.hand = hand_of(player).duplicate()
	view.pile = pile
	view.pile_owner = pile_owner
	view.current_player = current_player
	view.direction = direction
	for seat in player_count:
		view.hand_sizes.append(hand_of(seat).size())
	view.finished = finished.duplicate()
	view.legal_plays = legal_plays(player)
	view.can_pass = pile != null
	return view


func _check_turn(player: int) -> MoveResult:
	if is_over():
		return MoveResult.rejected(MoveResult.REASON_GAME_OVER)
	if player != current_player:
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	return null


## True if the player holds every card in `cards` (each physical card counts once).
func _holds_all(player: int, cards: Array) -> bool:
	var spare: Array[Card] = hand_of(player).duplicate()
	for card: Card in cards:
		var index := _index_of(spare, card)
		if index == -1:
			return false
		spare.remove_at(index)
	return true


func _remove_from_hand(player: int, cards: Array) -> void:
	var hand := hand_of(player)
	for card: Card in cards:
		hand.remove_at(_index_of(hand, card))


func _index_of(list: Array[Card], target: Card) -> int:
	for i in list.size():
		if list[i].rank == target.rank and list[i].suit == target.suit:
			return i
	return -1


## Next seat in the direction of play that has not finished. With include_self the player
## themselves is a candidate (used after a reset: they lead again unless they just finished).
func _next_active(from: int, include_self: bool) -> int:
	var steps := player_count if include_self else player_count - 1
	for i in range(0 if include_self else 1, steps + 1):
		var seat := posmod(from + i * direction, player_count)
		if not is_finished(seat):
			return seat
	return -1


func _clear_table() -> void:
	pile = null
	pile_owner = -1
	_declined.clear()
	_skipped.clear()


## When only one player still holds cards, they are last place and the game ends.
func _finish_game_if_one_left(result: MoveResult) -> bool:
	var active := active_players()
	if active.size() > 1:
		return false
	if active.size() == 1:
		finished.append(active[0])
	_clear_table()
	current_player = -1
	result.game_over = true
	return true


## The round ends when every active player except the pile owner has passed or been skipped,
## but a skipped player who never got a turn is first offered one (they may play or pass).
func _settle_round(result: MoveResult) -> void:
	for seat in active_players():
		if seat != pile_owner and not _declined.has(seat) and not _skipped.has(seat):
			return
	var owed := _first_skipped_after_owner()
	if owed != -1:
		current_player = owed
		return
	var winner := pile_owner
	result.round_won_by = winner
	_clear_table()
	current_player = _next_active(winner, true)


## The skipped player nearest after the pile owner in the direction of play, or -1.
func _first_skipped_after_owner() -> int:
	for i in range(1, player_count):
		var seat := posmod(pile_owner + i * direction, player_count)
		if _skipped.has(seat) and not is_finished(seat):
			return seat
	return -1
