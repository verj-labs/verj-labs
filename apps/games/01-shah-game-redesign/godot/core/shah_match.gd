class_name ShahMatch
extends RefCounted
## A session of several games (GAME_RULES section 2.1). Decides who starts, which way play
## goes, and applies the card exchange between games.

var player_count: int
var games_played: int = 0
## Ranking of the last finished game, 1st place first. Empty before the first game ends.
var last_ranking: Array[int] = []
## Card transfers made before the current game: [{"from", "to", "cards"}]. Empty for game 1.
var last_transfers: Array[Dictionary] = []
## Hands as dealt, before the exchange (index = seat). Lets the screen show the exchange.
var dealt_hands: Array = []
## The game in progress (or the last one played).
var game: Game = null

var _rng: RandomNumberGenerator


func _init(p_player_count: int, rng: RandomNumberGenerator) -> void:
	assert(Dealer.is_supported_player_count(p_player_count), "player count must be 3..8")
	player_count = p_player_count
	_rng = rng


## Deals and returns the next game. The previous game must be over.
func start_next_game() -> Game:
	assert(game == null or game.is_over(), "previous game is still running")
	if game != null:
		last_ranking = game.ranking()
	var dealt := Dealer.deal(player_count, _rng)
	dealt_hands = []
	for hand: Array in dealt["hands"]:
		var copy: Array[Card] = []
		copy.assign(hand)
		dealt_hands.append(copy)
	var start_player: int
	var direction: int
	if last_ranking.is_empty():
		start_player = _rng.randi_range(0, player_count - 1)
		direction = Direction.CLOCKWISE
	else:
		start_player = last_ranking[0]
		direction = Direction.for_next_game(player_count, last_ranking[0], last_ranking[1])
		last_transfers = Exchange.apply(dealt["hands"], last_ranking)
	game = Game.with_hands(dealt["hands"], start_player, direction, dealt["discarded"])
	games_played += 1
	return game
