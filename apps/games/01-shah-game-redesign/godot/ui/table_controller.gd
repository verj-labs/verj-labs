class_name TableController
extends Node
## Runs a match between a human and bots. Owns the ShahMatch, makes bots take their turns
## one at a time with pauses a person can follow, and tells the screen what changed through
## signals. With human_seat = -1 every seat is a bot (used by tests and demos).
##
## On the human's turn the game always waits for them, even with nothing to play (they press
## PASS). A turn timer runs; when it hits zero the human passes, or, if they must lead,
## their lowest set is played for them.

signal game_started
signal state_changed
## `play` is null when the seat passed.
signal move_made(seat: int, play: Play, result: MoveResult)
signal human_turn_started
## The human ran out of time and the controller moved for them.
signal timed_out
signal game_finished(ranking: Array[int])

const HUMAN_SEAT := 0
const DEFAULT_THINK_TIME := 1.2
const DEFAULT_TURN_SECONDS := 10.0
## Pauses are a multiple of the bot think time, so one setting scales the whole game's pace.
const SPECTATOR_FACTOR := 0.25
const EVENT_PAUSE_FACTOR := 0.6  ## After a SKIP or RESET.
const ROUND_END_PAUSE_FACTOR := 1.5  ## After a round is won: lets you see the winning play.

var match_session: ShahMatch
var game: Game
var human_seat: int = HUMAN_SEAT
## Seconds a bot "thinks" before moving. 0 makes everything instant (tests).
var think_time: float = DEFAULT_THINK_TIME
## How long the human has to move.
var turn_seconds: float = DEFAULT_TURN_SECONDS
var time_left: float = 0.0

var _bots: Array[Bot] = []
var _running: bool = false
var _awaiting_human: bool = false
var _extra_pause: float = 0.0


func setup(player_count: int, difficulty: int, rng: RandomNumberGenerator, p_human_seat: int = HUMAN_SEAT) -> void:
	human_seat = p_human_seat
	match_session = ShahMatch.new(player_count, rng)
	_bots.clear()
	for seat in player_count:
		_bots.append(null if seat == human_seat else BotFactory.create(difficulty, rng))


## Keeps the next player waiting for at least `seconds` (the screen uses this to play the
## card exchange animation before anyone moves).
func hold_for(seconds: float) -> void:
	_extra_pause = maxf(_extra_pause, seconds)


## How long the screen should keep the last play visible after a round ends.
func round_end_hold() -> float:
	return think_time * ROUND_END_PAUSE_FACTOR


func start_next_game() -> void:
	game = match_session.start_next_game()
	_awaiting_human = false
	_extra_pause = 0.0
	game_started.emit()
	state_changed.emit()
	continue_game()


## Lets bots move until it is the human's turn to decide, or the game ends.
## Call after changing `game` from outside (tests); the controller calls it itself otherwise.
func continue_game() -> void:
	if _running:
		return
	_running = true
	while not game.is_over():
		var seat := game.current_player
		var delay := _extra_pause
		_extra_pause = 0.0
		if seat != human_seat:
			delay += _bot_delay()
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if not is_inside_tree():
				return
		if seat == human_seat:
			_running = false  # before signals fire, so a listener may answer at once
			_begin_human_turn()
			return
		_bot_move(seat)
	_running = false
	if game.is_over():
		game_finished.emit(game.ranking())


func submit_play(cards: Array) -> MoveResult:
	if not is_human_turn():
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	var result := game.play(human_seat, cards)
	if result.accepted:
		_after_human_move(Play.from_cards(cards), result)
	return result


func submit_pass() -> MoveResult:
	if not is_human_turn():
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	var result := game.pass_turn(human_seat)
	if result.accepted:
		_after_human_move(null, result)
	return result


## True when the game is waiting for the human to decide.
func is_human_turn() -> bool:
	return _awaiting_human and game != null and not game.is_over()


func _process(delta: float) -> void:
	if not _awaiting_human:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_time_is_up()


func _begin_human_turn() -> void:
	_awaiting_human = true
	time_left = turn_seconds
	human_turn_started.emit()
	state_changed.emit()


func _time_is_up() -> void:
	timed_out.emit()
	var view := game.view_for(human_seat)
	if view.can_pass:
		submit_pass()
		return
	var lead := MediumBot.new().choose(view)
	submit_play(lead.cards)


func _after_human_move(play: Play, result: MoveResult) -> void:
	_awaiting_human = false
	_note_event_pause(result)
	move_made.emit(human_seat, play, result)
	state_changed.emit()
	continue_game()


func _bot_move(seat: int) -> void:
	var choice := _bots[seat].choose(game.view_for(seat))
	var result := game.pass_turn(seat) if choice == null else game.play(seat, choice.cards)
	assert(result.accepted, "a move that should be legal was rejected: " + result.reason)
	_note_event_pause(result)
	move_made.emit(seat, choice, result)
	state_changed.emit()


## After something worth noticing, wait a little before the next player acts.
func _note_event_pause(result: MoveResult) -> void:
	if result.round_won_by >= 0:
		_extra_pause = think_time * ROUND_END_PAUSE_FACTOR
	elif result.effect != PlayResult.Effect.NONE:
		_extra_pause = think_time * EVENT_PAUSE_FACTOR


func _bot_delay() -> float:
	if human_seat >= 0 and game.is_finished(human_seat):
		return think_time * SPECTATOR_FACTOR
	return think_time
