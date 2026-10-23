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


## "7H 8S" -> Array[Card]
static func cards(codes: String) -> Array[Card]:
	var result: Array[Card] = []
	for code in codes.split(" ", false):
		var card := Card.from_code(code)
		assert(card != null, "bad card code in test: " + code)
		result.append(card)
	return result


## ["7H 8S", "9D", "KC"] -> hands for seats 0, 1, 2
static func hands(codes_per_seat: Array) -> Array:
	var result: Array = []
	for codes: String in codes_per_seat:
		result.append(cards(codes))
	return result


## Plays a whole game with random (but legal) moves. Checks invariants as it goes and returns
## the number of moves taken, or -1 if something went wrong (message in `errors`).
## Players pass about `pass_chance` of the time when they are allowed to.
static func play_random_game(game: Game, rng: RandomNumberGenerator, errors: Array[String], pass_chance: float = 0.3) -> int:
	const MOVE_LIMIT := 5000
	var total_cards := 52
	var played := 0
	var moves := 0
	while not game.is_over():
		moves += 1
		if moves > MOVE_LIMIT:
			errors.append("game did not finish within %d moves" % MOVE_LIMIT)
			return -1
		var seat := game.current_player
		var options := game.legal_plays(seat)
		var can_pass := game.pile != null
		if options.is_empty() and not can_pass:
			errors.append("seat %d has no move on an empty table" % seat)
			return -1
		var result: MoveResult
		if can_pass and (options.is_empty() or rng.randf() < pass_chance):
			result = game.pass_turn(seat)
		else:
			var chosen: Play = options[rng.randi_range(0, options.size() - 1)]
			result = game.play(seat, chosen.cards)
			played += chosen.size
		if not result.accepted:
			errors.append("a legal move was rejected: " + result.reason)
			return -1
		var in_hands := 0
		for hand: Array in game.hands:
			in_hands += hand.size()
		if in_hands + played + game.discarded.size() != total_cards:
			errors.append("cards were created or lost")
			return -1
	return moves


## Plays a whole game where every seat is a bot. Returns the ranking, or an empty array if
## something went wrong (details in `errors`).
static func play_bot_game(game: Game, bots: Array[Bot], errors: Array[String]) -> Array[int]:
	const MOVE_LIMIT := 5000
	var moves := 0
	while not game.is_over():
		moves += 1
		if moves > MOVE_LIMIT:
			errors.append("bot game did not finish")
			return []
		var seat := game.current_player
		var view := game.view_for(seat)
		var choice := bots[seat].choose(view)
		if choice == null and not view.can_pass:
			errors.append("bot %d passed on an empty table" % seat)
			return []
		if choice != null and not _is_offered(view.legal_plays, choice):
			errors.append("bot %d chose a play that was not legal: %s" % [seat, choice.to_text()])
			return []
		var result := game.pass_turn(seat) if choice == null else game.play(seat, choice.cards)
		if not result.accepted:
			errors.append("move rejected: " + result.reason)
			return []
	return game.ranking()


static func _is_offered(plays: Array[Play], choice: Play) -> bool:
	for offered in plays:
		if offered == choice:
			return true
	return false
