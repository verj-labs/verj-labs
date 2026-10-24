extends GdUnitTestSuite
## The WebSocket server on real localhost sockets, with Godot's own WebSocketPeer as the client.

var _game: GameServer
var _wss: WsServer


func before_test() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	_game = GameServer.new(rng)
	_game.think_override = 0.0
	_game.turn_override = 20.0
	_wss = WsServer.new()
	assert_int(_wss.start(0, _game)).is_equal(OK)


func after_test() -> void:
	_wss.stop()


## Runs the server and the clients until `done` is true or `timeout_ms` passes.
func _pump_until(done: Callable, clients: Array, timeout_ms: int = 5000, tick_seconds: float = 0.02) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		_wss.poll(tick_seconds)
		_game.tick(tick_seconds)
		for client: WsTestClient in clients:
			client.poll()
		if done.call():
			return true
		OS.delay_usec(1000)
	return false


func _raw_http(request: String) -> String:
	var peer := StreamPeerTCP.new()
	peer.connect_to_host("127.0.0.1", _wss.port())
	var reply := ""
	var sent := false
	var deadline := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		_wss.poll(0.02)
		peer.poll()
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and not sent:
			peer.put_data(request.to_utf8_buffer())
			sent = true
		var available := peer.get_available_bytes()
		if available > 0:
			reply += peer.get_data(available)[1].get_string_from_utf8()
		if peer.get_status() == StreamPeerTCP.STATUS_NONE and sent:
			break
		OS.delay_usec(1000)
	return reply


# --- plain HTTP (health checks) ---------------------------------------------------------

func test_health_check_answers_200() -> void:
	var reply := _raw_http("GET /health HTTP/1.1\r\nHost: x\r\n\r\n")
	assert_str(reply).contains("200 OK")
	assert_str(reply).contains("shah-exchange ok")


func test_the_root_path_also_answers_for_platform_probes() -> void:
	assert_str(_raw_http("GET / HTTP/1.1\r\nHost: x\r\n\r\n")).contains("200 OK")


func test_unknown_paths_are_404() -> void:
	assert_str(_raw_http("GET /nope HTTP/1.1\r\nHost: x\r\n\r\n")).contains("404")


# --- websocket sessions --------------------------------------------------------------------

func test_a_real_websocket_client_can_say_hello() -> void:
	var client := WsTestClient.open(_wss.port())
	assert_bool(_pump_until(func() -> bool: return client.is_open(), [client])).is_true()
	client.hello("Waqas")
	assert_bool(_pump_until(func() -> bool: return not client.last("welcome").is_empty(), [client])).is_true()
	assert_str(client.last("welcome")["name"]).is_equal("WAQAS")
	assert_int(_wss.client_count()).is_equal(1)


func test_websocket_pings_get_pongs() -> void:
	var client := WsTestClient.open(_wss.port())
	_pump_until(func() -> bool: return client.is_open(), [client])
	# Godot answers pings itself; here we check the server stays up across a ping-pong cycle
	# by using the JSON-level ping instead.
	client.hello("A")
	client.say({"type": "ping"})
	assert_bool(_pump_until(func() -> bool: return client.count("pong") == 1, [client])).is_true()


func test_closing_the_socket_is_noticed_by_the_server() -> void:
	var client := WsTestClient.open(_wss.port())
	_pump_until(func() -> bool: return client.is_open(), [client])
	client.hello("A")
	_pump_until(func() -> bool: return not client.last("welcome").is_empty(), [client])
	client.say({"type": "create_room"})
	_pump_until(func() -> bool: return not client.last("room").is_empty(), [client])
	client.ws.close()
	assert_bool(_pump_until(func() -> bool: return _wss.client_count() == 0, [client])).is_true()
	# The room still exists (the player may reconnect) but the seat shows as disconnected.
	assert_int(_game.room_count()).is_equal(1)


func test_an_oversized_message_closes_the_connection() -> void:
	var client := WsTestClient.open(_wss.port())
	_pump_until(func() -> bool: return client.is_open(), [client])
	client.say({"type": "hello", "version": 1, "name": "A", "junk": "x".repeat(20000)})
	assert_bool(_pump_until(func() -> bool: return client.is_closed(), [client])).is_true()


func test_a_disallowed_origin_is_refused() -> void:
	_wss.allowed_origins = ["https://play.example.com"]
	var request := "GET / HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
	request += "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\nOrigin: https://evil.example\r\n\r\n"
	assert_str(_raw_http(request)).contains("403")


func test_an_allowed_origin_gets_through() -> void:
	_wss.allowed_origins = ["https://play.example.com"]
	var request := "GET / HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
	request += "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\nOrigin: https://play.example.com\r\n\r\n"
	var reply := _raw_http(request)
	assert_str(reply).contains("101 Switching Protocols")
	assert_str(reply).contains("s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")


func test_a_message_split_across_frames_is_reassembled() -> void:
	var peer := StreamPeerTCP.new()
	peer.connect_to_host("127.0.0.1", _wss.port())
	var request := "GET / HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
	request += "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
	var mask := PackedByteArray([1, 2, 3, 4])
	var text := JSON.stringify({"type": "hello", "version": 1, "name": "SPLIT"})
	var half := text.length() / 2
	var frames := PackedByteArray()
	for part in [[false, WsFrames.OP_TEXT, text.substr(0, half)], [true, WsFrames.OP_CONTINUATION, text.substr(half)]]:
		var payload: PackedByteArray = (part[2] as String).to_utf8_buffer()
		frames.append((0x80 if part[0] else 0x00) | part[1])
		frames.append(0x80 | payload.size())
		frames.append_array(mask)
		for i in payload.size():
			frames.append(payload[i] ^ mask[i % 4])
	var received := PackedByteArray()
	var sent_upgrade := false
	var sent_frames := false
	var deadline := Time.get_ticks_msec() + 4000
	while Time.get_ticks_msec() < deadline:
		_wss.poll(0.02)
		_game.tick(0.02)
		peer.poll()
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and not sent_upgrade:
			peer.put_data(request.to_utf8_buffer())
			sent_upgrade = true
		var available := peer.get_available_bytes()
		if available > 0:
			received.append_array(peer.get_data(available)[1])
		var so_far := received.get_string_from_utf8()
		if so_far.contains("\r\n\r\n") and not sent_frames:
			peer.put_data(frames)
			sent_frames = true
		if so_far.contains("welcome"):
			break
		OS.delay_usec(1000)
	assert_str(received.get_string_from_utf8()).contains("\"name\":\"SPLIT\"")


# --- whole games over real sockets ---------------------------------------------------------

func test_three_players_play_a_full_game_over_real_websockets() -> void:
	var clients: Array[WsTestClient] = []
	for i in 3:
		clients.append(WsTestClient.open(_wss.port()))
	assert_bool(_pump_until(func() -> bool: return clients.all(func(c: WsTestClient) -> bool: return c.is_open()), clients)).is_true()
	for i in 3:
		clients[i].hello("P%d" % i)
	_pump_until(func() -> bool: return clients.all(func(c: WsTestClient) -> bool: return not c.last("welcome").is_empty()), clients)
	clients[0].say({"type": "create_room"})
	_pump_until(func() -> bool: return not clients[0].last("room").is_empty(), clients)
	var code: String = clients[0].last("room")["code"]
	clients[1].say({"type": "join_room", "code": code})
	clients[2].say({"type": "join_room", "code": code})
	_pump_until(func() -> bool: return clients[0].last("room")["seats"][2]["kind"] == "human", clients)
	clients[0].say({"type": "start_game"})
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var finished := _pump_until(func() -> bool:
		for client in clients:
			client.act_randomly(rng)
		return clients.all(func(c: WsTestClient) -> bool: return c.count("game_over") == 1)
	, clients, 20000)
	assert_bool(finished).is_true()
	for client in clients:
		assert_int(client.count("error")).is_equal(0)
		assert_int(client.last("game_over")["ranking"].size()).is_equal(3)


func test_a_player_can_reconnect_over_a_new_socket_with_their_token() -> void:
	var first := WsTestClient.open(_wss.port())
	_pump_until(func() -> bool: return first.is_open(), [first])
	first.hello("RETURNING")
	_pump_until(func() -> bool: return not first.last("welcome").is_empty(), [first])
	var token: String = first.last("welcome")["token"]
	first.say({"type": "create_room"})
	_pump_until(func() -> bool: return not first.last("room").is_empty(), [first])
	var code: String = first.last("room")["code"]
	first.ws.close()
	_pump_until(func() -> bool: return _wss.client_count() == 0, [first])
	var second := WsTestClient.open(_wss.port())
	_pump_until(func() -> bool: return second.is_open(), [second])
	second.hello("RETURNING", token)
	_pump_until(func() -> bool: return not second.last("room").is_empty(), [second])
	assert_str(second.last("welcome")["token"]).is_equal(token)
	assert_str(second.last("room")["code"]).is_equal(code)
	assert_int(second.last("room")["you_seat"]).is_equal(0)


func test_many_simultaneous_connections() -> void:
	# 100 players arriving in waves of 20 (a thundering herd in one instant overflows the
	# operating system's accept queue; in production the host's proxy absorbs that).
	var clients: Array[WsTestClient] = []
	for wave in 5:
		var batch: Array[WsTestClient] = []
		for i in 20:
			var client := WsTestClient.open(_wss.port())
			batch.append(client)
			clients.append(client)
		assert_bool(_pump_until(func() -> bool: return batch.all(func(c: WsTestClient) -> bool: return c.is_open()), clients, 5000)).is_true()
	for i in clients.size():
		clients[i].hello("C%d" % i)
	assert_bool(_pump_until(func() -> bool: return clients.all(func(c: WsTestClient) -> bool: return not c.last("welcome").is_empty()), clients, 8000)).is_true()
	assert_int(_game.connection_count()).is_equal(100)
	for client in clients:
		client.ws.close()
	assert_bool(_pump_until(func() -> bool: return _wss.client_count() == 0, clients, 8000)).is_true()
