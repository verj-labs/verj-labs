class_name WsServer
extends RefCounted
## Accepts TCP connections, upgrades them to WebSockets, and hands text messages to a GameServer.
## Any ordinary HTTP request (not an upgrade) gets a small reply, so platform health checks on
## the same port work. TLS is expected to be terminated in front of this (Railway does that).

const MAX_FRAME_BYTES := 16384
const MAX_PENDING := 100
const HANDSHAKE_TIMEOUT := 5.0
const MAX_REQUEST_BYTES := 8192

var allowed_origins: Array[String] = []

var _tcp: TCPServer = TCPServer.new()
var _game: GameServer
var _pending: Array[Dictionary] = []  # {"peer", "buffer", "age"}
var _clients: Array[WsConnection] = []
var _next_id: int = 1


func start(port: int, game: GameServer) -> Error:
	_game = game
	return _tcp.listen(port)


func port() -> int:
	return _tcp.get_local_port()


func client_count() -> int:
	return _clients.size()


func stop() -> void:
	for conn in _clients:
		conn.peer.disconnect_from_host()
	_clients.clear()
	for entry in _pending:
		(entry["peer"] as StreamPeerTCP).disconnect_from_host()
	_pending.clear()
	_tcp.stop()


## Call every frame.
func poll(delta: float) -> void:
	_accept()
	_poll_handshakes(delta)
	_poll_clients()


# --- accepting and handshakes -------------------------------------------------------

func _accept() -> void:
	while _tcp.is_connection_available():
		var peer := _tcp.take_connection()
		if _pending.size() >= MAX_PENDING:
			peer.disconnect_from_host()
			continue
		peer.set_no_delay(true)
		_pending.append({"peer": peer, "buffer": PackedByteArray(), "age": 0.0})


func _poll_handshakes(delta: float) -> void:
	var still_pending: Array[Dictionary] = []
	for entry in _pending:
		var peer: StreamPeerTCP = entry["peer"]
		peer.poll()
		entry["age"] += delta
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or entry["age"] > HANDSHAKE_TIMEOUT:
			peer.disconnect_from_host()
			continue
		_read_into(peer, entry["buffer"])
		var buffer: PackedByteArray = entry["buffer"]
		var end := _find_header_end(buffer)
		if end < 0:
			if buffer.size() > MAX_REQUEST_BYTES:
				peer.disconnect_from_host()
			else:
				still_pending.append(entry)
			continue
		_handle_request(peer, buffer, end)
	_pending = still_pending


func _handle_request(peer: StreamPeerTCP, buffer: PackedByteArray, header_end: int) -> void:
	var head := buffer.slice(0, header_end).get_string_from_utf8()
	var lines := head.split("\r\n")
	var request_line := lines[0].split(" ")
	var headers := {}
	for i in range(1, lines.size()):
		var colon := lines[i].find(":")
		if colon > 0:
			headers[lines[i].substr(0, colon).strip_edges().to_lower()] = lines[i].substr(colon + 1).strip_edges()
	var is_upgrade := str(headers.get("upgrade", "")).to_lower() == "websocket" and headers.has("sec-websocket-key")
	if is_upgrade:
		_upgrade(peer, headers, buffer.slice(header_end + 4))
		return
	var path: String = request_line[1] if request_line.size() > 1 else "/"
	if path == "/" or path == "/health":
		_http_reply(peer, 200, "OK", "shah-exchange ok\n")
	else:
		_http_reply(peer, 404, "Not Found", "not found\n")


func _upgrade(peer: StreamPeerTCP, headers: Dictionary, leftover: PackedByteArray) -> void:
	if str(headers.get("sec-websocket-version", "")) != "13":
		_http_reply(peer, 400, "Bad Request", "unsupported websocket version\n")
		return
	var origin := str(headers.get("origin", ""))
	if not allowed_origins.is_empty() and origin != "" and not allowed_origins.has(origin):
		_http_reply(peer, 403, "Forbidden", "origin not allowed\n")
		return
	var response := "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
	response += "Sec-WebSocket-Accept: %s\r\n\r\n" % WsFrames.accept_key(str(headers["sec-websocket-key"]))
	peer.put_data(response.to_utf8_buffer())
	var conn := WsConnection.new()
	conn.id = _next_id
	_next_id += 1
	conn.peer = peer
	conn.inbound = leftover
	_clients.append(conn)
	_game.on_connect(conn)


func _http_reply(peer: StreamPeerTCP, status: int, reason: String, body: String) -> void:
	var text := "HTTP/1.1 %d %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [
		status, reason, body.to_utf8_buffer().size(), body
	]
	peer.put_data(text.to_utf8_buffer())
	peer.disconnect_from_host()


func _find_header_end(buffer: PackedByteArray) -> int:
	for i in range(buffer.size() - 3):
		if buffer[i] == 13 and buffer[i + 1] == 10 and buffer[i + 2] == 13 and buffer[i + 3] == 10:
			return i
	return -1


# --- established connections ------------------------------------------------------------

func _poll_clients() -> void:
	for conn in _clients.duplicate():
		conn.peer.poll()
		if conn.peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_finish(conn)
			continue
		_read_into(conn.peer, conn.inbound)
		_process_frames(conn)
		_flush(conn)


func _process_frames(conn: WsConnection) -> void:
	while not conn.closing and not conn.finished:
		var frame := WsFrames.decode_client_frame(conn.inbound, MAX_FRAME_BYTES)
		if frame.is_empty():
			return
		if frame.has("error"):
			_fail(conn, frame["error"])
			return
		conn.inbound = conn.inbound.slice(frame["consumed"])
		_handle_frame(conn, frame)


func _handle_frame(conn: WsConnection, frame: Dictionary) -> void:
	var payload: PackedByteArray = frame["payload"]
	match frame["opcode"]:
		WsFrames.OP_PING:
			conn.queue_raw(WsFrames.encode(WsFrames.OP_PONG, payload))
		WsFrames.OP_PONG:
			pass
		WsFrames.OP_CLOSE:
			conn.closing = true
			conn.queue_raw(WsFrames.encode(WsFrames.OP_CLOSE, payload.slice(0, 2)))
		WsFrames.OP_TEXT, WsFrames.OP_CONTINUATION:
			_handle_data_frame(conn, frame)
		_:
			_fail(conn, WsFrames.CLOSE_UNSUPPORTED)


func _handle_data_frame(conn: WsConnection, frame: Dictionary) -> void:
	var is_start: bool = frame["opcode"] == WsFrames.OP_TEXT
	if is_start and not conn.fragments.is_empty():
		_fail(conn, WsFrames.CLOSE_PROTOCOL_ERROR)
		return
	if not is_start and conn.fragments.is_empty():
		_fail(conn, WsFrames.CLOSE_PROTOCOL_ERROR)
		return
	conn.fragments.append_array(frame["payload"])
	if conn.fragments.size() > MAX_FRAME_BYTES:
		_fail(conn, WsFrames.CLOSE_TOO_BIG)
		return
	if frame["fin"]:
		var text := conn.fragments.get_string_from_utf8()
		conn.fragments = PackedByteArray()
		_game.on_text(conn, text)


func _fail(conn: WsConnection, code: int) -> void:
	conn.closing = true
	conn.outbound.append_array(WsFrames.encode_close(code))


## Writes as much queued output as the socket will take; finishes a closing connection once
## everything has been sent.
func _flush(conn: WsConnection) -> void:
	if not conn.outbound.is_empty():
		var result := conn.peer.put_partial_data(conn.outbound)
		if result[0] != OK:
			_finish(conn)
			return
		conn.outbound = conn.outbound.slice(result[1])
	if conn.closing and conn.outbound.is_empty():
		_finish(conn)


func _finish(conn: WsConnection) -> void:
	if conn.finished:
		return
	conn.finished = true
	_game.on_close(conn)
	conn.peer.disconnect_from_host()
	_clients.erase(conn)


func _read_into(peer: StreamPeerTCP, buffer: PackedByteArray) -> void:
	var available := peer.get_available_bytes()
	if available > 0:
		var result := peer.get_data(available)
		if result[0] == OK:
			buffer.append_array(result[1])
