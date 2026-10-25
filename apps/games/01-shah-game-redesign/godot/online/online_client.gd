class_name OnlineClient
extends Node
## The player's line to the game server (registered as the autoload "Online"). It connects,
## says hello, remembers the session token, pings to stay alive, and reconnects with backoff if
## the connection drops. Lobby screens listen to its signals; once a game starts the table's
## RemoteTableSource takes over the game messages (any that arrived early are kept for it).

signal status_changed(text: String)
signal welcomed(player_name: String)
signal room_changed(room: Dictionary)
## A game message (game_start / update / game_over) while a table is attached.
signal game_message(message: Dictionary)
## A game has just begun and no table is attached yet: open the table screen.
signal game_began
signal left_room(reason: String)
signal server_error(code: String, message: String)
signal connection_changed(connected: bool)

enum State { OFFLINE, CONNECTING, WAITING_WELCOME, ONLINE }

## The deployed game server (Railway). To play against a local server (./serve.sh) start the game
## with SHAH_SERVER=ws://127.0.0.1:8080 ./run.sh.
const DEFAULT_URL := "wss://verj-labs-production.up.railway.app"
## How long after stepping away a player is offered REJOIN (the server keeps the seat for a while
## and then lets a bot play it; the room closes a couple of minutes after everyone is gone).
const REJOIN_SECONDS := 600
const PING_SECONDS := 15.0
const CONNECT_TIMEOUT := 10.0
const RECONNECT_DELAYS := [1.0, 2.0, 4.0, 8.0]
const GAME_MESSAGE_TYPES := ["game_start", "update", "game_over"]

var url: String = DEFAULT_URL
var player_name: String = ""
var token: String = ""
var state: State = State.OFFLINE
## The latest room message, or {} when not in a room.
var room: Dictionary = {}
var table_attached: bool = false
## Remember name and token between runs. Tests switch this off.
var persist: bool = true
## Room the player stepped away from and may rejoin ("" = none). See park().
var rejoin_code: String = ""

var _ws: WebSocketPeer
var _pending_game: Array[Dictionary] = []
var _since_ping: float = 0.0
var _connecting_for: float = 0.0
var _reconnect_in: float = -1.0
var _attempt: int = 0
var _wanted_online: bool = false
var _was_connected: bool = false
var _rejoin_saved_at: int = 0


func _ready() -> void:
	if not persist:
		return
	# The address is never saved or shown to players. Developers can point the game at another
	# server with the SHAH_SERVER environment variable or `-- --server=ws://host:8080`.
	url = _developer_server_override()
	player_name = Settings.read("online", "name", "")
	token = Settings.read("online", "token", "")
	rejoin_code = Settings.read("online", "rejoin_code", "")
	_rejoin_saved_at = int(Settings.read("online", "rejoin_saved_at", 0))


func _developer_server_override() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--server="):
			return arg.get_slice("=", 1)
	if OS.get_environment("SHAH_SERVER") != "":
		return OS.get_environment("SHAH_SERVER")
	return DEFAULT_URL


## True when the player stepped away from a running game and can still get back in.
func can_rejoin() -> bool:
	if rejoin_code == "" or token == "" or player_name == "":
		return false
	return Time.get_unix_time_from_system() - _rejoin_saved_at < REJOIN_SECONDS


## Steps away from the game without giving up the seat: the connection closes (a bot plays the
## seat after a short grace period) and the main menu offers REJOIN until the game is over.
func park() -> void:
	if in_room():
		_remember_rejoin(str(room.get("code", "")))
	detach_table()
	disconnect_now()


## Reconnects with the saved session; the server puts the player back at their table.
func rejoin() -> void:
	connect_to_server(url, player_name)


func forget_rejoin() -> void:
	_remember_rejoin("")


func _remember_rejoin(code: String) -> void:
	rejoin_code = code
	_rejoin_saved_at = int(Time.get_unix_time_from_system()) if code != "" else 0
	if persist:
		Settings.write("online", "rejoin_code", rejoin_code)
		Settings.write("online", "rejoin_saved_at", _rejoin_saved_at)


func is_online() -> bool:
	return state == State.ONLINE


func in_room() -> bool:
	return not room.is_empty()


func is_host() -> bool:
	return in_room() and room["host_seat"] == room["you_seat"]


## Opens the connection (or reuses it) and says hello with `p_name`.
func connect_to_server(p_url: String, p_name: String) -> void:
	url = p_url
	player_name = p_name
	if persist:
		Settings.write("online", "name", player_name)
	_wanted_online = true
	_attempt = 0
	if state == State.OFFLINE:
		_open()
	elif state == State.ONLINE:
		welcomed.emit(player_name)


func disconnect_now() -> void:
	_wanted_online = false
	_reconnect_in = -1.0
	room = {}
	_pending_game.clear()
	if _ws != null:
		_ws.close()
	_set_state(State.OFFLINE, "DISCONNECTED")


## Takes over the game messages. Returns everything that arrived before a table was attached.
func attach_table() -> Array[Dictionary]:
	table_attached = true
	var backlog := _pending_game.duplicate()
	_pending_game.clear()
	return backlog


func detach_table() -> void:
	table_attached = false
	_pending_game.clear()


# --- things to say ---------------------------------------------------------------------

func create_room() -> void:
	_send({"type": "create_room"})


func join_room(code: String) -> void:
	_send({"type": "join_room", "code": code.strip_edges().to_upper()})


func leave_room() -> void:
	forget_rejoin()
	_send({"type": "leave_room"})


func set_options(difficulty: String, speed: String, games: int = ShahMatch.DEFAULT_GAMES) -> void:
	_send({"type": "set_options", "difficulty": difficulty, "speed": speed, "games": games})


func add_bot() -> void:
	_send({"type": "add_bot"})


func remove_seat(seat: int) -> void:
	_send({"type": "remove_seat", "seat": seat})


func start_game() -> void:
	_send({"type": "start_game"})


func next_game() -> void:
	_send({"type": "next_game"})


func back_to_lobby() -> void:
	_send({"type": "back_to_lobby"})


func send_play(codes: Array[String]) -> void:
	_send({"type": "play", "cards": codes})


func send_pass() -> void:
	_send({"type": "pass"})


# --- the connection loop -------------------------------------------------------------------

func _process(delta: float) -> void:
	if _reconnect_in >= 0.0:
		_reconnect_in -= delta
		if _reconnect_in < 0.0:
			_open()
		return
	if _ws == null:
		return
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			_connecting_for += delta
			if _connecting_for > CONNECT_TIMEOUT:
				_ws.close()
		WebSocketPeer.STATE_OPEN:
			if state == State.CONNECTING:
				_send_hello()
			_read_packets()
			_since_ping += delta
			if _since_ping >= PING_SECONDS:
				_since_ping = 0.0
				_send({"type": "ping"})
		WebSocketPeer.STATE_CLOSED:
			_on_closed()


func _open() -> void:
	_ws = WebSocketPeer.new()
	_connecting_for = 0.0
	_since_ping = 0.0
	var error := _ws.connect_to_url(url)
	if error != OK:
		_ws = null
		_schedule_reconnect()
		return
	_set_state(State.CONNECTING, "CONNECTING...")


func _send_hello() -> void:
	var message := {"type": "hello", "version": Protocol.VERSION, "name": player_name}
	if token != "":
		message["token"] = token
	_ws.send_text(JSON.stringify(message))
	_set_state(State.WAITING_WELCOME, "SIGNING IN...")


func _read_packets() -> void:
	while _ws != null and _ws.get_available_packet_count() > 0:
		var parsed: Variant = JSON.parse_string(_ws.get_packet().get_string_from_utf8())
		if parsed is Dictionary:
			_handle(Protocol.whole_numbers(parsed))


func _on_closed() -> void:
	_ws = null
	var had_connection := _was_connected
	_was_connected = false
	if had_connection:
		connection_changed.emit(false)
	if _wanted_online:
		_schedule_reconnect()
	else:
		_set_state(State.OFFLINE, "DISCONNECTED")


func _schedule_reconnect() -> void:
	_set_state(State.OFFLINE, "RECONNECTING...")
	var delay: float = RECONNECT_DELAYS[mini(_attempt, RECONNECT_DELAYS.size() - 1)]
	_attempt += 1
	_reconnect_in = delay


func _send(message: Dictionary) -> void:
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(message))


func _set_state(new_state: State, text: String) -> void:
	state = new_state
	status_changed.emit(text)


# --- messages from the server ------------------------------------------------------------

func _handle(message: Dictionary) -> void:
	var type: String = message.get("type", "")
	if type in GAME_MESSAGE_TYPES:
		_handle_game_message(message)
		return
	match type:
		"welcome":
			token = message["token"]
			player_name = message["name"]
			if persist:
				Settings.write("online", "token", token)
			_attempt = 0
			var reconnected := _was_connected == false and in_room()
			_was_connected = true
			_set_state(State.ONLINE, "ONLINE")
			welcomed.emit(player_name)
			connection_changed.emit(true)
			if reconnected:
				status_changed.emit("BACK ONLINE")
		"room":
			room = message
			room_changed.emit(room)
		"left":
			forget_rejoin()
			room = {}
			_pending_game.clear()
			left_room.emit(str(message.get("reason", "left")))
		"error":
			var code := str(message.get("code", ""))
			if code == Protocol.E_REPLACED:
				_wanted_online = false
			server_error.emit(code, str(message.get("message", code)))
		_:
			pass


func _handle_game_message(message: Dictionary) -> void:
	if table_attached:
		game_message.emit(message)
		return
	if message["type"] == "game_start":
		_pending_game.clear()
		game_began.emit()
	_pending_game.append(message)
