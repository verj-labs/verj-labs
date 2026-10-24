class_name GameServer
extends RefCounted
## The server brain: tracks connections, sessions and rooms, and routes every message. It
## never touches a socket: a transport (WsServer, or a fake in tests) feeds it on_connect /
## on_text / on_close and calls tick(delta) regularly.

const MAX_ROOMS := 200
const MAX_CONNECTIONS := 800
const HELLO_TIMEOUT := 10.0
const SILENCE_TIMEOUT := 45.0
const MAX_MESSAGE_CHARS := 16384
const RATE_CAPACITY := 30.0
const RATE_REFILL_PER_SECOND := 20.0
const MAX_STRIKES := 3
const IDLE_SESSION_SECONDS := 600.0
const CODE_ATTEMPTS := 50

var reporter: ResultReporter = ResultReporter.new()
## Test knobs, applied to every new room (negative = use the room options).
var think_override: float = -1.0
var turn_override: float = -1.0

var _clock: float = 0.0
var _conns: Dictionary = {}  # Connection -> {"session", "age", "bucket", "strikes", "silence"}
var _sessions: Dictionary = {}  # token -> Session
var _rooms: Dictionary = {}  # code -> Room
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(rng: RandomNumberGenerator = null) -> void:
	if rng != null:
		_rng = rng
	else:
		_rng.randomize()


func room_count() -> int:
	return _rooms.size()


func connection_count() -> int:
	return _conns.size()


func room_for_code(code: String) -> Room:
	return _rooms.get(code)


# --- transport entry points ----------------------------------------------------------

## A new socket opened. Returns false (and closes it) if the server is full.
func on_connect(conn: Connection) -> bool:
	if _conns.size() >= MAX_CONNECTIONS:
		conn.send(Protocol.error(Protocol.E_SERVER_BUSY))
		conn.close()
		return false
	_conns[conn] = {"session": null, "age": 0.0, "bucket": RATE_CAPACITY, "strikes": 0, "silence": 0.0}
	return true


func on_close(conn: Connection) -> void:
	if not _conns.has(conn):
		return
	var info: Dictionary = _conns[conn]
	_conns.erase(conn)
	var session: Session = info["session"]
	if session != null and session.connection == conn:
		session.connection = null
		session.disconnected_for = 0.0
		if session.room != null:
			session.room.session_disconnected(session)


func on_text(conn: Connection, text: String) -> void:
	if not _conns.has(conn):
		return
	var info: Dictionary = _conns[conn]
	info["silence"] = 0.0
	if text.length() > MAX_MESSAGE_CHARS:
		_reject(conn, Protocol.error(Protocol.E_BAD_MESSAGE, "message too large"), true)
		return
	if not _take_token(conn, info):
		return
	var parser := JSON.new()
	if parser.parse(text) != OK or not parser.data is Dictionary:
		_reject(conn, Protocol.error(Protocol.E_BAD_MESSAGE, "not a JSON object"), false)
		return
	var message: Dictionary = parser.data
	if not message.get("type") is String:
		_reject(conn, Protocol.error(Protocol.E_BAD_MESSAGE, "missing type"), false)
		return
	_dispatch(conn, info, message)


func tick(delta: float) -> void:
	_clock += delta
	for conn: Connection in _conns.keys():
		var info: Dictionary = _conns[conn]
		info["age"] += delta
		info["silence"] += delta
		info["bucket"] = minf(RATE_CAPACITY, info["bucket"] + RATE_REFILL_PER_SECOND * delta)
		if info["session"] == null and info["age"] >= HELLO_TIMEOUT:
			_drop(conn)
		elif info["silence"] >= SILENCE_TIMEOUT:
			_drop(conn)
	for room: Room in _rooms.values():
		room.tick(delta)
	_reap_rooms()
	_purge_idle_sessions(delta)


# --- routing --------------------------------------------------------------------------

func _dispatch(conn: Connection, info: Dictionary, message: Dictionary) -> void:
	var type: String = message["type"]
	if info["session"] == null:
		if type != "hello":
			_reject(conn, Protocol.error(Protocol.E_BAD_MESSAGE, "say hello first"), false)
			return
		_hello(conn, info, message)
		return
	var session: Session = info["session"]
	match type:
		"hello":
			conn.send(Protocol.error(Protocol.E_BAD_MESSAGE, "already said hello"))
		"ping":
			conn.send({"type": "pong"})
		"create_room":
			_create_room(session)
		"join_room":
			_join_room(session, message)
		"leave_room":
			_leave_room(session)
		_:
			if session.room == null:
				session.send(Protocol.error(Protocol.E_NOT_IN_ROOM))
			else:
				session.room.handle(session, message)
	_reap_rooms()


func _hello(conn: Connection, info: Dictionary, message: Dictionary) -> void:
	if message.get("version") != Protocol.VERSION:
		_reject(conn, Protocol.error(Protocol.E_BAD_VERSION, "this server speaks protocol %d" % Protocol.VERSION), true)
		return
	var clean := Protocol.clean_name(message.get("name"))
	var token = message.get("token")
	var session: Session = _sessions.get(token) if token is String else null
	if session == null:
		if clean.is_empty():
			_reject(conn, Protocol.error(Protocol.E_BAD_NAME, "name must be 1-%d letters, numbers or spaces" % Protocol.MAX_NAME), false)
			return
		session = Session.new()
		session.token = _new_token()
		session.name = clean
		_sessions[session.token] = session
	elif session.connection != null and session.connection != conn:
		var old := session.connection
		old.send(Protocol.error(Protocol.E_REPLACED, "signed in from another place"))
		_conns.erase(old)
		old.close()
	session.connection = conn
	session.disconnected_for = -1.0
	info["session"] = session
	conn.send({"type": "welcome", "version": Protocol.VERSION, "token": session.token, "name": session.name})
	if session.room != null:
		session.room.session_reconnected(session)


func _create_room(session: Session) -> void:
	if session.room != null:
		session.send(Protocol.error(Protocol.E_ALREADY_IN_ROOM))
		return
	if _rooms.size() >= MAX_ROOMS:
		session.send(Protocol.error(Protocol.E_SERVER_BUSY))
		return
	var code := _new_code()
	if code.is_empty():
		session.send(Protocol.error(Protocol.E_SERVER_BUSY))
		return
	var room := Room.new(code, _rng)
	room.think_override = think_override
	room.turn_override = turn_override
	room.reporter = reporter
	_rooms[code] = room
	room.add_host(session)


func _join_room(session: Session, message: Dictionary) -> void:
	if session.room != null:
		session.send(Protocol.error(Protocol.E_ALREADY_IN_ROOM))
		return
	var wanted: Variant = message.get("code")
	if wanted is String:
		wanted = (wanted as String).to_upper()
	if not Protocol.is_valid_code(wanted) or not _rooms.has(wanted):
		session.send(Protocol.error(Protocol.E_NO_SUCH_ROOM))
		return
	var error: String = _rooms[wanted].add_human(session)
	if error != "":
		session.send(Protocol.error(error))


func _leave_room(session: Session) -> void:
	if session.room == null:
		session.send(Protocol.error(Protocol.E_NOT_IN_ROOM))
		return
	session.room.session_left(session)
	session.send({"type": "left", "reason": "left"})


func _reap_rooms() -> void:
	for code: String in _rooms.keys():
		var room: Room = _rooms[code]
		if room.is_dead():
			room.close("room_closed")
			_rooms.erase(code)


func _purge_idle_sessions(delta: float) -> void:
	for token: String in _sessions.keys():
		var session: Session = _sessions[token]
		if session.has_connection() or session.room != null:
			continue
		session.disconnected_for = maxf(session.disconnected_for, 0.0) + delta
		if session.disconnected_for >= IDLE_SESSION_SECONDS:
			_sessions.erase(token)


# --- small helpers ----------------------------------------------------------------------

## Token bucket per connection: bursts are fine, sustained spam is not.
func _take_token(conn: Connection, info: Dictionary) -> bool:
	if info["bucket"] >= 1.0:
		info["bucket"] -= 1.0
		return true
	info["strikes"] += 1
	if info["strikes"] >= MAX_STRIKES:
		_reject(conn, Protocol.error(Protocol.E_RATE_LIMITED, "too many messages"), true)
	else:
		conn.send(Protocol.error(Protocol.E_RATE_LIMITED, "slow down"))
	return false


## Answers with an error; optionally hangs up.
func _reject(conn: Connection, error: Dictionary, hang_up: bool) -> void:
	conn.send(error)
	if hang_up:
		_drop(conn)


func _drop(conn: Connection) -> void:
	on_close(conn)
	conn.close()


func _new_token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


func _new_code() -> String:
	for attempt in CODE_ATTEMPTS:
		var code := ""
		for i in Protocol.CODE_LENGTH:
			code += Protocol.CODE_LETTERS[_rng.randi_range(0, Protocol.CODE_LETTERS.length() - 1)]
		if not _rooms.has(code):
			return code
	return ""
