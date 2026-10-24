class_name Room
extends RefCounted
## One table of up to 8 players. In the lobby seats are filled and options set; once started
## a GameRunner plays the match. Everything a player sees is built here from the runner's
## state, personalised so nobody receives another player's cards.

enum Phase { LOBBY, PLAYING, GAME_OVER }

const MAX_SEATS := 8
const MIN_PLAYERS := 3
const GRACE_SECONDS := 60.0
const LOBBY_IDLE_SECONDS := 600.0
const GAME_IDLE_SECONDS := 120.0
const BOT_NAMES := ["ACE", "DUKE", "MIMI", "ROCCO", "ZED", "LOLA", "KIKO", "NOVA"]
const PHASE_NAMES := {Phase.LOBBY: "lobby", Phase.PLAYING: "playing", Phase.GAME_OVER: "game_over"}

var code: String
var phase: Phase = Phase.LOBBY
var host_seat: int = 0
var options: Dictionary = {"difficulty": "medium", "speed": "normal", "games": ShahMatch.DEFAULT_GAMES}
## Test knobs: override the pacing derived from `options`.
var think_override: float = -1.0
var turn_override: float = -1.0
var reporter: ResultReporter = ResultReporter.new()
var runner: GameRunner

# Per seat: {"kind": "empty"|"human"|"bot", "session": Session|null, "name": String, "bot_playing": bool}
var _entries: Array[Dictionary] = []
var _clock: float = 0.0
var _unattended_since: float = -1.0
var _seq: int = 0
var _rng: RandomNumberGenerator


func _init(p_code: String, rng: RandomNumberGenerator) -> void:
	code = p_code
	_rng = rng
	for i in MAX_SEATS:
		_entries.append(_empty_entry())


# --- joining and leaving ------------------------------------------------------------

## Seats the creator as host. Returns "" or an error code.
func add_host(session: Session) -> String:
	return _seat_human(session)


## Seats a joining player. Returns "" or an error code.
func add_human(session: Session) -> String:
	if phase != Phase.LOBBY:
		return Protocol.E_ROOM_STARTED
	return _seat_human(session)


func session_left(session: Session) -> void:
	var seat := session.seat
	session.room = null
	session.seat = -1
	if seat < 0 or seat >= _entries.size() or _entries[seat]["session"] != session:
		return
	if phase == Phase.LOBBY:
		_entries[seat] = _empty_entry()
	else:
		_entries[seat] = {"kind": "bot", "session": null, "name": _entries[seat]["name"], "bot_playing": true}
		runner.make_bot(seat)
	_after_departure(seat)


func session_disconnected(session: Session) -> void:
	_broadcast_room()


## The player came back before the room closed. Gives them their seat and brings them up to date.
func session_reconnected(session: Session) -> void:
	var seat := session.seat
	if phase != Phase.LOBBY and seat >= 0 and _entries[seat]["session"] == session and _entries[seat]["bot_playing"]:
		_entries[seat]["bot_playing"] = false
		runner.make_human(seat)
	session.disconnected_for = -1.0
	_unattended_since = -1.0
	session.send(_room_message(session))
	match phase:
		Phase.PLAYING:
			session.send(_update_message(session, {"type": "sync"}))
		Phase.GAME_OVER:
			session.send(_update_message(session, {"type": "sync"}))
			session.send(_game_over_message())
	_broadcast_room()


## True when nobody is left to play: no human seats, or nobody connected for too long.
func is_dead() -> bool:
	if _human_seats().is_empty():
		return true
	if _unattended_since < 0.0:
		return false
	var limit := LOBBY_IDLE_SECONDS if phase == Phase.LOBBY else GAME_IDLE_SECONDS
	return _clock - _unattended_since >= limit


## Everyone still in the room is told they are out (called when the room is closed).
func close(reason: String) -> void:
	for entry in _entries:
		var session: Session = entry["session"]
		if session != null and session.room == self:
			session.send({"type": "left", "reason": reason})
			session.room = null
			session.seat = -1


func tick(delta: float) -> void:
	_clock += delta
	if runner != null and phase == Phase.PLAYING:
		runner.tick(delta)
	_apply_grace_periods(delta)
	_track_attendance()


# --- messages from players ------------------------------------------------------------

func handle(session: Session, message: Dictionary) -> void:
	match message["type"]:
		"set_options":
			_set_options(session, message)
		"add_bot":
			_add_bot(session)
		"remove_seat":
			_remove_seat(session, message)
		"start_game":
			_start_game(session)
		"next_game":
			_next_game(session)
		"back_to_lobby":
			_back_to_lobby(session)
		"play":
			_play(session, message)
		"pass":
			_pass(session)
		_:
			session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "unknown message type"))


func _set_options(session: Session, message: Dictionary) -> void:
	if not _require_host(session) or not _require_phase(session, Phase.LOBBY):
		return
	var difficulty = message.get("difficulty", options["difficulty"])
	var speed = message.get("speed", options["speed"])
	var games = message.get("games", options["games"])
	if Protocol.difficulty_value(difficulty) < 0 or not Protocol.is_speed(speed) or not Protocol.is_games(games):
		session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "bad options"))
		return
	options = {"difficulty": difficulty, "speed": speed, "games": int(games)}
	_broadcast_room()


func _add_bot(session: Session) -> void:
	if not _require_host(session) or not _require_phase(session, Phase.LOBBY):
		return
	var seat := _first_empty_seat()
	if seat < 0:
		session.send(Protocol.error(Protocol.E_ROOM_FULL))
		return
	_entries[seat] = {"kind": "bot", "session": null, "name": _next_bot_name(), "bot_playing": true}
	_broadcast_room()


func _remove_seat(session: Session, message: Dictionary) -> void:
	if not _require_host(session) or not _require_phase(session, Phase.LOBBY):
		return
	var seat = message.get("seat", -1)
	if not seat is int and not seat is float:
		session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "seat must be a number"))
		return
	var index := int(seat)
	if index < 0 or index >= MAX_SEATS or index == host_seat or _entries[index]["kind"] == "empty":
		session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "cannot remove that seat"))
		return
	var kicked: Session = _entries[index]["session"]
	_entries[index] = _empty_entry()
	if kicked != null:
		kicked.send({"type": "left", "reason": "kicked"})
		kicked.room = null
		kicked.seat = -1
	_broadcast_room()


func _start_game(session: Session) -> void:
	if not _require_host(session) or not _require_phase(session, Phase.LOBBY):
		return
	var filled: Array[Dictionary] = []
	for entry in _entries:
		if entry["kind"] != "empty":
			filled.append(entry)
	if filled.size() < MIN_PLAYERS:
		session.send(Protocol.error(Protocol.E_NOT_ENOUGH_PLAYERS, "need at least %d players" % MIN_PLAYERS))
		return
	_entries = filled
	var humans: Array[int] = []
	for seat in _entries.size():
		var human: Session = _entries[seat]["session"]
		if human != null:
			human.seat = seat
			humans.append(seat)
	host_seat = session.seat
	runner = GameRunner.new()
	runner.setup(_entries.size(), Protocol.difficulty_value(options["difficulty"]), _rng, humans, options["games"])
	runner.think_time = think_override if think_override >= 0.0 else Protocol.THINK_SECONDS[options["speed"]]
	runner.turn_seconds = turn_override if turn_override >= 0.0 else Protocol.TURN_SECONDS[options["speed"]]
	runner.game_started.connect(_on_game_started)
	runner.move_made.connect(_on_move_made)
	runner.turn_started.connect(_on_turn_started)
	runner.timed_out.connect(_on_timed_out)
	runner.game_finished.connect(_on_game_finished)
	phase = Phase.PLAYING
	_broadcast_room()
	runner.start_next_game()


func _next_game(session: Session) -> void:
	if not _require_host(session) or not _require_phase(session, Phase.GAME_OVER):
		return
	if runner.match_over():
		session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "the match is over"))
		return
	phase = Phase.PLAYING
	_broadcast_room()
	runner.start_next_game()


func _back_to_lobby(session: Session) -> void:
	if not _require_host(session) or not _require_phase(session, Phase.GAME_OVER):
		return
	phase = Phase.LOBBY
	runner = null
	while _entries.size() < MAX_SEATS:
		_entries.append(_empty_entry())
	for seat in _entries.size():
		_entries[seat]["bot_playing"] = _entries[seat]["kind"] == "bot"
	_broadcast_room()


func _play(session: Session, message: Dictionary) -> void:
	if phase != Phase.PLAYING:
		session.send(Protocol.error(Protocol.E_NOT_YOUR_TURN, "no game in progress"))
		return
	var cards := Protocol.parse_cards(message.get("cards"))
	if cards.is_empty():
		session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "cards must be 1-4 card codes"))
		return
	_report_result(session, runner.submit_play(session.seat, cards))


func _pass(session: Session) -> void:
	if phase != Phase.PLAYING:
		session.send(Protocol.error(Protocol.E_NOT_YOUR_TURN, "no game in progress"))
		return
	_report_result(session, runner.submit_pass(session.seat))


func _report_result(session: Session, result: MoveResult) -> void:
	if result.accepted:
		return
	if result.reason == MoveResult.REASON_NOT_YOUR_TURN:
		session.send(Protocol.error(Protocol.E_NOT_YOUR_TURN))
	else:
		session.send(Protocol.error(Protocol.E_ILLEGAL_MOVE, result.reason))


# --- runner events -> messages --------------------------------------------------------

func _on_game_started() -> void:
	if not runner.match_session.last_transfers.is_empty():
		runner.hold_for(ExchangeTiming.seconds(2))  # players are watching the card swap
	for seat in _entries.size():
		var session: Session = _entries[seat]["session"]
		if session == null:
			continue
		session.send({
			"type": "game_start",
			"game_number": runner.games_played(),
			"state": _state_dict(seat),
			"dealt_hand": _codes(runner.match_session.dealt_hands[seat]),
			"transfers": _transfers_for(seat),
		})


func _on_move_made(seat: int, play: Play, result: MoveResult) -> void:
	_send_update({
		"type": "move",
		"seat": seat,
		"cards": null if play == null else play.to_codes(),
		"effect": Protocol.effect_name(result.effect),
		"skipped_player": result.skipped_player,
		"round_won_by": result.round_won_by,
		"player_finished": result.player_finished,
		"game_over": result.game_over,
	})


func _on_turn_started(seat: int) -> void:
	_send_update({"type": "turn", "seat": seat})


func _on_timed_out(seat: int) -> void:
	_send_update({"type": "timeout", "seat": seat})


func _on_game_finished(ranking: Array[int]) -> void:
	phase = Phase.GAME_OVER
	var report: Array[Dictionary] = []
	for seat in ranking:
		var entry := _entries[seat]
		report.append({"name": entry["name"], "kind": entry["kind"], "user_id": ""})
	reporter.report_game(code, runner.games_played(), report)
	for entry in _entries:
		var session: Session = entry["session"]
		if session != null:
			session.send(_game_over_message())
	_broadcast_room()


func _game_over_message() -> Dictionary:
	return {
		"type": "game_over",
		"ranking": runner.game.ranking(),
		"scores": runner.match_session.scores(),
		"standings": runner.match_session.standings(),
		"match_over": runner.match_over(),
		"game_number": runner.games_played(),
		"total_games": runner.total_games(),
	}


func _send_update(event: Dictionary) -> void:
	_seq += 1
	for entry in _entries:
		var session: Session = entry["session"]
		if session != null and session.has_connection():
			session.send(_update_message(session, event))


func _update_message(session: Session, event: Dictionary) -> Dictionary:
	var turn: Variant = null
	if runner.waiting_seat >= 0:
		turn = {"seat": runner.waiting_seat, "ms_left": int(runner.time_left * 1000.0)}
	return {"type": "update", "seq": _seq, "event": event, "state": _state_dict(session.seat), "turn": turn}


func _state_dict(seat: int) -> Dictionary:
	var names: Array[String] = []
	var kinds: Array[String] = []
	for index in _entries.size():
		names.append(_entries[index]["name"])
		kinds.append("human" if runner.is_human(index) else "bot")
	return TableState.from_game(runner.game, seat, names, kinds, runner.games_played(), runner.total_games()).to_dict()


## The exchange as `seat` may see it: card identities only if they gave or received them.
func _transfers_for(seat: int) -> Array:
	var result: Array = []
	for transfer in runner.match_session.last_transfers:
		var cards: Array = transfer["cards"]
		if transfer["from"] == seat or transfer["to"] == seat:
			result.append({"from": transfer["from"], "to": transfer["to"], "cards": _codes(cards)})
		else:
			result.append({"from": transfer["from"], "to": transfer["to"], "count": cards.size()})
	return result


func _codes(cards: Array) -> Array[String]:
	var codes: Array[String] = []
	for card: Card in cards:
		codes.append(card.to_code())
	return codes


# --- room messages ---------------------------------------------------------------------

func _room_message(session: Session) -> Dictionary:
	var seats: Array = []
	for seat in _entries.size():
		var entry := _entries[seat]
		var owner: Session = entry["session"]
		seats.append({
			"seat": seat,
			"kind": entry["kind"],
			"name": entry["name"],
			"connected": owner != null and owner.has_connection(),
			"bot_playing": entry["bot_playing"],
		})
	return {
		"type": "room",
		"code": code,
		"phase": PHASE_NAMES[phase],
		"host_seat": host_seat,
		"you_seat": session.seat,
		"options": options,
		"seats": seats,
	}


func _broadcast_room() -> void:
	for entry in _entries:
		var session: Session = entry["session"]
		if session != null and session.has_connection():
			session.send(_room_message(session))


# --- helpers -------------------------------------------------------------------------

func _seat_human(session: Session) -> String:
	var seat := _first_empty_seat()
	if seat < 0:
		return Protocol.E_ROOM_FULL
	session.room = self
	session.seat = seat
	_entries[seat] = {"kind": "human", "session": session, "name": _unique_name(session.name), "bot_playing": false}
	if _human_seats().size() == 1:
		host_seat = seat
	_broadcast_room()
	return ""


func _empty_entry() -> Dictionary:
	return {"kind": "empty", "session": null, "name": "", "bot_playing": false}


func _first_empty_seat() -> int:
	for seat in _entries.size():
		if _entries[seat]["kind"] == "empty":
			return seat
	return -1


func _human_seats() -> Array[int]:
	var seats: Array[int] = []
	for seat in _entries.size():
		if _entries[seat]["session"] != null:
			seats.append(seat)
	return seats


func _unique_name(wanted: String) -> String:
	var taken: Array[String] = []
	for entry in _entries:
		taken.append(entry["name"])
	var candidate := wanted
	var suffix := 2
	while taken.has(candidate):
		candidate = "%s%d" % [wanted.substr(0, Protocol.MAX_NAME - 2), suffix]
		suffix += 1
	return candidate


func _next_bot_name() -> String:
	var taken: Array[String] = []
	for entry in _entries:
		taken.append(entry["name"])
	for bot_name: String in BOT_NAMES:
		if not taken.has(bot_name):
			return bot_name
	return "BOT"


func _after_departure(seat: int) -> void:
	if seat == host_seat:
		_migrate_host()
	_broadcast_room()


func _migrate_host() -> void:
	for seat in _entries.size():
		var session: Session = _entries[seat]["session"]
		if session != null and session.has_connection():
			host_seat = seat
			return
	for seat in _entries.size():
		if _entries[seat]["session"] != null:
			host_seat = seat
			return


func _require_host(session: Session) -> bool:
	if session.seat != host_seat:
		session.send(Protocol.error(Protocol.E_NOT_HOST))
		return false
	return true


func _require_phase(session: Session, wanted: Phase) -> bool:
	if phase != wanted:
		session.send(Protocol.error(Protocol.E_BAD_MESSAGE, "not allowed right now"))
		return false
	return true


## A disconnected human keeps their seat for GRACE_SECONDS, then a bot plays it (or, in the
## lobby, the seat is freed).
func _apply_grace_periods(delta: float) -> void:
	var changed := false
	for seat in _entries.size():
		var session: Session = _entries[seat]["session"]
		if session == null or session.has_connection():
			continue
		session.disconnected_for = maxf(session.disconnected_for, 0.0) + delta
		if session.disconnected_for < GRACE_SECONDS:
			continue
		if phase == Phase.LOBBY:
			_entries[seat] = _empty_entry()
			session.room = null
			session.seat = -1
			if seat == host_seat:
				_migrate_host()
			changed = true
		elif not _entries[seat]["bot_playing"]:
			_entries[seat]["bot_playing"] = true
			runner.make_bot(seat)
			changed = true
	if changed:
		_broadcast_room()


func _track_attendance() -> void:
	var attended := false
	for entry in _entries:
		var session: Session = entry["session"]
		if session != null and session.has_connection():
			attended = true
	if attended:
		_unattended_since = -1.0
	elif _unattended_since < 0.0:
		_unattended_since = _clock
