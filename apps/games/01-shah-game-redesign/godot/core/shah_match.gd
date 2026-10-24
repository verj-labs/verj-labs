class_name ShahMatch
extends RefCounted
## A session of several games (GAME_RULES section 2.1). Decides who starts, which way play
## goes, and applies the card exchange between games. A match has a fixed length (10 or 20
## games in the UI) and keeps score: each game gives every player points for their place
## (1st gets player_count - 1, last gets 0); the most points after the last game wins.

const DEFAULT_GAMES := 10
## The match lengths offered to players.
const GAME_OPTIONS: Array[int] = [10, 20]

var player_count: int
## How many games the match lasts.
var max_games: int = DEFAULT_GAMES
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
## Finished games' rankings, 1st place first (one per recorded game).
var _history: Array[Array] = []


func _init(p_player_count: int, rng: RandomNumberGenerator, p_max_games: int = DEFAULT_GAMES) -> void:
	assert(Dealer.is_supported_player_count(p_player_count), "player count must be 3..8")
	assert(p_max_games > 0, "a match has at least one game")
	player_count = p_player_count
	max_games = p_max_games
	_rng = rng


## Points a player earns for finishing in `place` (0 = 1st) among `players`.
static func points_for_place(place: int, players: int) -> int:
	return players - 1 - place


## True once the last game of the match has been played to the end.
func is_over() -> bool:
	return games_played >= max_games and game != null and game.is_over()


## Adds the finished game to the scores. Safe to call more than once for the same game (the
## score getters call it too, so a game that just ended always counts).
func record_game() -> void:
	if game == null or not game.is_over() or _history.size() >= games_played:
		return
	_history.append(game.ranking())


## Match points per seat so far.
func scores() -> Array[int]:
	record_game()
	var totals: Array[int] = []
	totals.resize(player_count)
	totals.fill(0)
	for ranking in _history:
		for place in ranking.size():
			totals[ranking[place]] += points_for_place(place, player_count)
	return totals


## How many games each seat has won (finished 1st).
func wins() -> Array[int]:
	record_game()
	var totals: Array[int] = []
	totals.resize(player_count)
	totals.fill(0)
	for ranking in _history:
		totals[ranking[0]] += 1
	return totals


## Seats ordered best first: most points, then most wins, then lowest seat number.
func standings() -> Array[int]:
	var points := scores()
	var game_wins := wins()
	var seats: Array[int] = []
	for seat in player_count:
		seats.append(seat)
	seats.sort_custom(func(a: int, b: int) -> bool:
		if points[a] != points[b]:
			return points[a] > points[b]
		if game_wins[a] != game_wins[b]:
			return game_wins[a] > game_wins[b]
		return a < b
	)
	return seats


## Deals and returns the next game. The previous game must be over.
func start_next_game() -> Game:
	assert(game == null or game.is_over(), "previous game is still running")
	assert(games_played < max_games, "the match is over")
	record_game()
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
