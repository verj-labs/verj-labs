class_name FakeClient
extends Connection
## A pretend player for server tests. Messages the server sends are round-tripped through JSON
## text, exactly as on a real socket, so anything that cannot be serialised fails here.

var server: GameServer
var inbox: Array[Dictionary] = []
var closed: bool = false
var token: String = ""
var _last_acted_seq: int = -1


static func connect_to(p_server: GameServer, display_name: String = "") -> FakeClient:
	var client := FakeClient.new()
	client.server = p_server
	p_server.on_connect(client)
	if display_name != "":
		client.say({"type": "hello", "version": Protocol.VERSION, "name": display_name})
		client.token = client.last("welcome").get("token", "")
	return client


func send(message: Dictionary) -> void:
	inbox.append(Protocol.whole_numbers(JSON.parse_string(JSON.stringify(message))))


func close() -> void:
	closed = true


func say(message: Dictionary) -> void:
	server.on_text(self, JSON.stringify(message))


func say_raw(text: String) -> void:
	server.on_text(self, text)


func hang_up() -> void:
	server.on_close(self)


func of_type(type: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for message in inbox:
		if message.get("type") == type:
			found.append(message)
	return found


func last(type: String) -> Dictionary:
	var found := of_type(type)
	return found[found.size() - 1] if not found.is_empty() else {}


func error_codes() -> Array[String]:
	var codes: Array[String] = []
	for message in of_type("error"):
		codes.append(message["code"])
	return codes


func clear() -> void:
	inbox.clear()


## The room code from the latest `room` message.
func room_code() -> String:
	return last("room").get("code", "")


## If it is this client's turn (per the newest update), makes a random legal move. Returns
## true if it acted.
func act_randomly(rng: RandomNumberGenerator, pass_chance: float = 0.25) -> bool:
	var update := last("update")
	if update.is_empty() or update["turn"] == null:
		return false
	var state := TableState.from_dict(update["state"])
	if state == null or update["turn"]["seat"] != state.my_seat or update["seq"] == _last_acted_seq:
		return false
	_last_acted_seq = update["seq"]
	var options := state.legal_plays()
	var can_pass := state.pile != null
	if can_pass and (options.is_empty() or rng.randf() < pass_chance):
		say({"type": "pass"})
	else:
		var choice: Play = options[rng.randi_range(0, options.size() - 1)]
		say({"type": "play", "cards": choice.to_codes()})
	return true
