class_name RemoteTableSource
extends TableSource
## The online table: turns the server's messages into the same signals and state the single-
## player controller provides, so the table screen cannot tell the difference. The server is
## the referee; this class only reflects what it says and forwards the player's intents.

var client: OnlineClient

var _attached: bool = false
var _my_turn: bool = false
var _game_over: bool = false
var _last_seq: int = -1


func _init(p_client: OnlineClient) -> void:
	client = p_client


## First call: takes over the game messages (replaying any that arrived early). Later calls:
## asks the server for the next game (the host's NEXT GAME button).
func start_next_game() -> void:
	if _attached:
		client.next_game()
		return
	_attached = true
	var backlog := client.attach_table()
	client.game_message.connect(_handle)
	client.room_changed.connect(_on_room)
	client.server_error.connect(_on_server_error)
	client.connection_changed.connect(func(connected: bool) -> void: connection_changed.emit(connected))
	_on_room(client.room)
	for message in backlog:
		_handle(message)


func submit_play(cards: Array) -> MoveResult:
	if not is_human_turn():
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	var codes: Array[String] = []
	for card: Card in cards:
		codes.append(card.to_code())
	_my_turn = false  # the server will say if it was refused
	client.send_play(codes)
	return MoveResult.ok()


func submit_pass() -> MoveResult:
	if not is_human_turn():
		return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)
	_my_turn = false
	client.send_pass()
	return MoveResult.ok()


func is_human_turn() -> bool:
	return _my_turn and not _game_over


func can_start_next_game() -> bool:
	return client.is_host()


func leave() -> void:
	client.detach_table()
	client.leave_room()


func _process(delta: float) -> void:
	if _my_turn:
		time_left = maxf(time_left - delta, 0.0)


func _exit_tree() -> void:
	# The client may already be gone (both are freed together when a screen closes).
	if _attached and is_instance_valid(client):
		client.detach_table()


# --- server messages -------------------------------------------------------------------

func _handle(message: Dictionary) -> void:
	match message.get("type"):
		"game_start":
			_on_game_start(message)
		"update":
			_on_update(message)
		"game_over":
			_on_game_over(message)


func _on_room(room: Dictionary) -> void:
	var options: Dictionary = room.get("options", {})
	var speed: String = options.get("speed", "normal")
	if Protocol.is_speed(speed):
		think_time = Protocol.THINK_SECONDS[speed]
		turn_seconds = Protocol.TURN_SECONDS[speed]


func _on_game_start(message: Dictionary) -> void:
	var fresh := TableState.from_dict(message.get("state"))
	if fresh == null:
		return
	state = fresh
	human_seat = fresh.my_seat
	_game_over = false
	_my_turn = false
	_last_seq = -1
	time_left = 0.0
	dealt_hand = _cards_from(message.get("dealt_hand", []))
	exchange_transfers = _transfers_from(message.get("transfers", []))
	game_started.emit()
	state_changed.emit()


func _on_update(message: Dictionary) -> void:
	var fresh := TableState.from_dict(message.get("state"))
	var event: Variant = message.get("event")
	if fresh == null or not event is Dictionary:
		return
	state = fresh
	_last_seq = int(message.get("seq", _last_seq))
	var turn: Variant = message.get("turn")
	_my_turn = turn is Dictionary and int(turn["seat"]) == fresh.my_seat
	if _my_turn:
		time_left = float(turn["ms_left"]) / 1000.0
	match event.get("type"):
		"move":
			_emit_move(event)
			state_changed.emit()
		"timeout":
			if int(event["seat"]) == fresh.my_seat:
				timed_out.emit()
		"turn":
			state_changed.emit()
			if _my_turn:
				human_turn_started.emit()
		_:
			state_changed.emit()


func _emit_move(event: Dictionary) -> void:
	var result := MoveResult.ok()
	result.effect = Protocol.effect_value(str(event.get("effect", "none")))
	result.skipped_player = int(event.get("skipped_player", -1))
	result.round_won_by = int(event.get("round_won_by", -1))
	result.player_finished = bool(event.get("player_finished", false))
	result.game_over = bool(event.get("game_over", false))
	var play: Play = null
	if event.get("cards") != null:
		play = Play.from_codes(event["cards"])
	move_made.emit(int(event["seat"]), play, result)


func _on_game_over(message: Dictionary) -> void:
	_game_over = true
	_my_turn = false
	var ranking: Array[int] = []
	for seat in message.get("ranking", []):
		ranking.append(int(seat))
	game_finished.emit(ranking)


func _on_server_error(code: String, text: String) -> void:
	if code == Protocol.E_ILLEGAL_MOVE:
		_my_turn = true  # still your turn: try again
		move_rejected.emit(text)
	elif code == Protocol.E_NOT_YOUR_TURN:
		move_rejected.emit(code)


func _cards_from(codes: Array) -> Array[Card]:
	var cards: Array[Card] = []
	for code in codes:
		var card := Card.from_code(str(code))
		if card != null:
			cards.append(card)
	return cards


func _transfers_from(raw: Array) -> Array[Dictionary]:
	var transfers: Array[Dictionary] = []
	for item in raw:
		var transfer := {"from": int(item["from"]), "to": int(item["to"])}
		if item.has("cards"):
			transfer["cards"] = _cards_from(item["cards"])
		else:
			transfer["count"] = int(item.get("count", 0))
		transfers.append(transfer)
	return transfers
