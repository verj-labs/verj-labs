class_name GameRunner
extends RefCounted
## Runs a match between any mix of human and bot seats: deals, lets bots move after a short
## "thinking" pause, waits for humans (with a turn timer), and reports what happens through
## signals. It has no nodes, sockets or real clock: whoever owns it calls tick(delta). That
## makes it usable by the single-player screen and the online server alike, and lets tests run
## whole matches on simulated time.
##
## Rules for a human who runs out of time: they pass, or if they must lead their lowest set is
## played for them. A seat can be handed to a bot (make_bot) and taken back (make_human).

signal game_started
signal state_changed
## `play` is null when the seat passed.
signal move_made(seat: int, play: Play, result: MoveResult)
## A human seat must now act (the turn timer is running).
signal turn_started(seat: int)
## The human ran out of time; the move that follows is made for them.
signal timed_out(seat: int)
signal game_finished(ranking: Array[int])

const DEFAULT_THINK_TIME := 1.2
const DEFAULT_TURN_SECONDS := 20.0
## Pauses are multiples of the bot think time, so one setting scales the whole game's pace.
const SPECTATOR_FACTOR := 0.25  ## Bots speed up when no human is still playing.
const EVENT_PAUSE_FACTOR := 0.6  ## After a SKIP or RESET.
const ROUND_END_PAUSE_FACTOR := 1.5  ## After a round is won: lets everyone see the winning play.

var match_session: ShahMatch
var game: Game
## Seconds a bot "thinks" before moving. 0 makes everything instant (tests).
var think_time: float = DEFAULT_THINK_TIME
## How long a human has to move.
var turn_seconds: float = DEFAULT_TURN_SECONDS
var time_left: float = 0.0
## The human seat the runner is currently waiting on, or -1.
var waiting_seat: int = -1

var _humans: Dictionary = {}  # seat -> true
var _bots: Array[Bot] = []
var _cooldown: float = 0.0
var _extra: float = 0.0
var _finish_reported: bool = false


func setup(
	player_count: int, difficulty: int, rng: RandomNumberGenerator, human_seats: Array[int],
	max_games: int = ShahMatch.DEFAULT_GAMES
) -> void:
	match_session = ShahMatch.new(player_count, rng, max_games)
	_humans.clear()
	for seat in human_seats:
		_humans[seat] = true
	_bots.clear()
	for seat in player_count:
		_bots.append(BotFactory.create(difficulty, rng))  # humans get one too, for takeovers


func is_human(seat: int) -> bool:
	return _humans.has(seat)


func games_played() -> int:
	return match_session.games_played


func total_games() -> int:
	return match_session.max_games


## True once the last game of the match is finished.
func match_over() -> bool:
	return match_session.is_over()


## Hands the seat to a bot (a player left or dropped). Safe at any time.
func make_bot(seat: int) -> void:
	_humans.erase(seat)
	if waiting_seat == seat:
		waiting_seat = -1
		_cooldown = _bot_delay()
		_pump()


## Gives the seat back to a human (they reconnected).
func make_human(seat: int) -> void:
	_humans[seat] = true


## Keeps the next player waiting for at least `seconds` (the screen uses this to play the card
## exchange animation before anyone moves).
func hold_for(seconds: float) -> void:
	_extra = maxf(_extra, seconds)


## How long the screen should keep the last play visible after a round ends.
func round_end_hold() -> float:
	return think_time * ROUND_END_PAUSE_FACTOR


func start_next_game() -> void:
	game = match_session.start_next_game()
	waiting_seat = -1
	time_left = 0.0
	_extra = 0.0
	_finish_reported = false
	game_started.emit()
	state_changed.emit()
	_cooldown = _delay_before(game.current_player)
	_pump()


## Carries on from the current `game` (used after swapping in a prepared game in tests).
func continue_game() -> void:
	_cooldown = _delay_before(game.current_player)
	_pump()


func tick(delta: float) -> void:
	if game == null or game.is_over():
		return
	if waiting_seat >= 0:
		time_left = maxf(time_left - delta, 0.0)
		if time_left <= 0.0:
			_time_is_up()
		return
	_cooldown -= delta
	_pump()


func submit_play(seat: int, cards: Array) -> MoveResult:
	if waiting_seat != seat:
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	var result := game.play(seat, cards)
	if result.accepted:
		waiting_seat = -1
		_after_move(seat, Play.from_cards(cards), result)
		_pump()
	return result


func submit_pass(seat: int) -> MoveResult:
	if waiting_seat != seat:
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	var result := game.pass_turn(seat)
	if result.accepted:
		waiting_seat = -1
		_after_move(seat, null, result)
		_pump()
	return result


## Lets bots move (and starts the human wait) until something needs time to pass.
func _pump() -> void:
	while game != null and not game.is_over() and waiting_seat < 0 and _cooldown <= 0.0:
		var seat := game.current_player
		if _humans.has(seat):
			_begin_wait(seat)
			return
		_bot_move(seat)


func _begin_wait(seat: int) -> void:
	waiting_seat = seat
	time_left = turn_seconds
	turn_started.emit(seat)
	state_changed.emit()


func _bot_move(seat: int) -> void:
	var choice := _bots[seat].choose(game.view_for(seat))
	var result := game.pass_turn(seat) if choice == null else game.play(seat, choice.cards)
	assert(result.accepted, "a move that should be legal was rejected: " + result.reason)
	_after_move(seat, choice, result)


func _after_move(seat: int, play: Play, result: MoveResult) -> void:
	_note_event_pause(result)
	move_made.emit(seat, play, result)
	state_changed.emit()
	if game.is_over():
		if not _finish_reported:
			_finish_reported = true
			match_session.record_game()
			game_finished.emit(game.ranking())
		return
	_cooldown = _delay_before(game.current_player)


func _time_is_up() -> void:
	var seat := waiting_seat
	timed_out.emit(seat)
	var view := game.view_for(seat)
	if view.can_pass:
		submit_pass(seat)
	else:
		submit_play(seat, MediumBot.new().choose(view).cards)


## After something worth noticing, wait a little before the next player acts.
func _note_event_pause(result: MoveResult) -> void:
	if result.round_won_by >= 0:
		_extra = think_time * ROUND_END_PAUSE_FACTOR
	elif result.effect != PlayResult.Effect.NONE:
		_extra = think_time * EVENT_PAUSE_FACTOR


## Seconds to wait before `next_seat` may act: any pending event pause, plus thinking time if
## it is a bot.
func _delay_before(next_seat: int) -> float:
	var delay := _extra
	_extra = 0.0
	if not _humans.has(next_seat):
		delay += _bot_delay()
	return delay


func _bot_delay() -> float:
	if _humans.is_empty():
		return think_time  # an all-bot demo runs at normal speed
	for seat: int in _humans:
		if not game.is_finished(seat):
			return think_time
	return think_time * SPECTATOR_FACTOR
