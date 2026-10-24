class_name TableController
extends TableSource
## The single-player table: a GameRunner (you in seat 0, bots elsewhere) driven by the frame
## clock. RemoteTableSource offers the same surface for online games.

const HUMAN_SEAT := 0

var runner: GameRunner = GameRunner.new()
## Display names by seat (the screen sets these before the first game).
var names: Array[String] = []

var match_session: ShahMatch:
	get:
		return runner.match_session
var game: Game:
	get:
		return runner.game
	set(value):
		runner.game = value


func setup(player_count: int, difficulty: int, rng: RandomNumberGenerator, p_human_seat: int = HUMAN_SEAT) -> void:
	human_seat = p_human_seat
	var humans: Array[int] = []
	if human_seat >= 0:
		humans.append(human_seat)
	runner.setup(player_count, difficulty, rng, humans)
	runner.game_started.connect(_on_runner_game_started)
	runner.state_changed.connect(func() -> void:
		_sync_from_runner()
		state_changed.emit()
	)
	runner.move_made.connect(func(seat: int, play: Play, result: MoveResult) -> void:
		_sync_from_runner()
		move_made.emit(seat, play, result)
	)
	runner.turn_started.connect(func(_seat: int) -> void: human_turn_started.emit())
	runner.timed_out.connect(func(_seat: int) -> void: timed_out.emit())
	runner.game_finished.connect(func(ranking: Array[int]) -> void: game_finished.emit(ranking))


func start_next_game() -> void:
	_push_settings()
	runner.start_next_game()


func continue_game() -> void:
	_push_settings()
	_sync_from_runner()
	runner.continue_game()


func hold_for(seconds: float) -> void:
	runner.hold_for(seconds)


func round_end_hold() -> float:
	return runner.round_end_hold()


func submit_play(cards: Array) -> MoveResult:
	return runner.submit_play(human_seat, cards)


func submit_pass() -> MoveResult:
	return runner.submit_pass(human_seat)


func is_human_turn() -> bool:
	return human_seat >= 0 and runner.waiting_seat == human_seat and not runner.game.is_over()


func _process(delta: float) -> void:
	runner.tick(delta)
	time_left = runner.time_left


## The screen sets think_time/turn_seconds on this object; the runner needs the same values.
func _push_settings() -> void:
	runner.think_time = think_time
	runner.turn_seconds = turn_seconds


func _on_runner_game_started() -> void:
	exchange_transfers = runner.match_session.last_transfers
	dealt_hand = []
	if human_seat >= 0:
		dealt_hand.assign(runner.match_session.dealt_hands[human_seat])
	_sync_from_runner()
	game_started.emit()


func _sync_from_runner() -> void:
	time_left = runner.time_left
	if runner.game == null:
		return
	var seat_names: Array[String] = []
	var kinds: Array[String] = []
	for seat in runner.game.player_count:
		seat_names.append(names[seat] if seat < names.size() else "P%d" % (seat + 1))
		kinds.append("human" if runner.is_human(seat) else "bot")
	state = TableState.from_game(runner.game, human_seat, seat_names, kinds, runner.games_played())
