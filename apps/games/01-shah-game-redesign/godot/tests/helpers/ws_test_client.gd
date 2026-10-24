class_name WsTestClient
extends RefCounted
## A real WebSocket client (Godot's own WebSocketPeer) for integration tests. It is an
## independent implementation of the protocol, which is the point: it checks our server.

var ws: WebSocketPeer = WebSocketPeer.new()
var inbox: Array[Dictionary] = []
var token: String = ""
var _last_acted_seq: int = -1


static func open(port: int) -> WsTestClient:
	var client := WsTestClient.new()
	client.ws.connect_to_url("ws://127.0.0.1:%d" % port)
	return client


func poll() -> void:
	ws.poll()
	while ws.get_available_packet_count() > 0:
		var text := ws.get_packet().get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			inbox.append(Protocol.whole_numbers(parsed))


func is_open() -> bool:
	return ws.get_ready_state() == WebSocketPeer.STATE_OPEN


func is_closed() -> bool:
	return ws.get_ready_state() == WebSocketPeer.STATE_CLOSED


func say(message: Dictionary) -> void:
	ws.send_text(JSON.stringify(message))


func hello(display_name: String, p_token: String = "") -> void:
	var message := {"type": "hello", "version": Protocol.VERSION, "name": display_name}
	if p_token != "":
		message["token"] = p_token
	say(message)


func last(type: String) -> Dictionary:
	for i in range(inbox.size() - 1, -1, -1):
		if inbox[i].get("type") == type:
			return inbox[i]
	return {}


func count(type: String) -> int:
	var total := 0
	for message in inbox:
		if message.get("type") == type:
			total += 1
	return total


func act_randomly(rng: RandomNumberGenerator, pass_chance: float = 0.25) -> bool:
	var update := last("update")
	if update.is_empty() or update["turn"] == null:
		return false
	var state := TableState.from_dict(update["state"])
	if state == null or update["turn"]["seat"] != state.my_seat or update["seq"] == _last_acted_seq:
		return false
	_last_acted_seq = update["seq"]
	var options := state.legal_plays()
	if state.pile != null and (options.is_empty() or rng.randf() < pass_chance):
		say({"type": "pass"})
	else:
		var choice: Play = options[rng.randi_range(0, options.size() - 1)]
		say({"type": "play", "cards": choice.to_codes()})
	return true
