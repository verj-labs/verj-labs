extends GdUnitTestSuite
## The server brain, driven by in-memory fake players: handshake, rooms, privacy, moves,
## timeouts, drops and reconnects, abuse. No sockets and no real clock.


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _server(think: float = 0.0, turn: float = 20.0) -> GameServer:
	var server := GameServer.new(_rng())
	server.think_override = think
	server.turn_override = turn
	return server


func _step(server: GameServer, seconds: float, step: float = 0.1) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		server.tick(step)
		elapsed += step


## Like _step, but the given clients ping every 15 seconds the way real clients do, so the
## server does not consider them dead.
func _step_alive(server: GameServer, clients: Array, seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		server.tick(0.1)
		elapsed += 0.1
		if int(elapsed * 10.0) % 150 == 0:
			for client: FakeClient in clients:
				if not client.closed:
					client.say({"type": "ping"})


## Host + (count - 1) joiners in one lobby. Returns the clients, host first.
func _lobby(server: GameServer, count: int) -> Array[FakeClient]:
	var clients: Array[FakeClient] = []
	var host := FakeClient.connect_to(server, "HOST")
	host.say({"type": "create_room"})
	clients.append(host)
	var code := host.room_code()
	for i in count - 1:
		var guest := FakeClient.connect_to(server, "GUEST%d" % (i + 1))
		guest.say({"type": "join_room", "code": code})
		clients.append(guest)
	return clients


## A started 3-human game.
func _game(server: GameServer) -> Array[FakeClient]:
	var clients := _lobby(server, 3)
	clients[0].say({"type": "start_game"})
	return clients


# --- handshake ---------------------------------------------------------------------

func test_hello_gives_a_welcome_with_a_token() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "Waqas")
	var welcome := client.last("welcome")
	assert_str(welcome["name"]).is_equal("WAQAS")
	assert_int(welcome["token"].length()).is_equal(32)
	assert_int(welcome["version"]).is_equal(Protocol.VERSION)


func test_the_wrong_protocol_version_is_refused_and_hung_up() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server)
	client.say({"type": "hello", "version": 99, "name": "A"})
	assert_array(client.error_codes()).contains([Protocol.E_BAD_VERSION])
	assert_bool(client.closed).is_true()


func test_bad_names_are_refused(
	bad: Variant, test_parameters := [[""], ["   "], ["WAY TOO LONG NAME"], ["bad<script>"], [42], [null]]
) -> void:
	var server := _server()
	var client := FakeClient.connect_to(server)
	client.say({"type": "hello", "version": 1, "name": bad})
	assert_array(client.error_codes()).contains([Protocol.E_BAD_NAME])
	assert_array(client.of_type("welcome")).is_empty()


func test_anything_before_hello_is_refused() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server)
	client.say({"type": "create_room"})
	assert_array(client.error_codes()).contains([Protocol.E_BAD_MESSAGE])


func test_garbage_is_answered_not_crashed_on(
	garbage: String, test_parameters := [["not json"], ["[1,2,3]"], ["42"], ["{}"], ["{\"type\": 5}"], [""]]
) -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "A")
	client.clear()
	client.say_raw(garbage)
	assert_array(client.error_codes()).contains([Protocol.E_BAD_MESSAGE])
	assert_bool(client.closed).is_false()


func test_oversized_messages_hang_up() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "A")
	client.say_raw("x".repeat(GameServer.MAX_MESSAGE_CHARS + 1))
	assert_bool(client.closed).is_true()


func test_ping_gets_pong() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "A")
	client.say({"type": "ping"})
	assert_int(client.of_type("pong").size()).is_equal(1)


func test_silent_connections_are_dropped() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "A")
	_step(server, GameServer.SILENCE_TIMEOUT + 1.0, 1.0)
	assert_bool(client.closed).is_true()


func test_connections_that_never_say_hello_are_dropped() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server)
	_step(server, GameServer.HELLO_TIMEOUT + 1.0, 1.0)
	assert_bool(client.closed).is_true()


func test_spamming_is_rate_limited_then_cut_off() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "A")
	for i in 200:
		client.say({"type": "ping"})
	assert_bool(client.error_codes().has(Protocol.E_RATE_LIMITED)).is_true()
	assert_bool(client.closed).is_true()


# --- rooms ---------------------------------------------------------------------------

func test_create_room_returns_a_code_and_makes_you_host() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "HOST")
	host.say({"type": "create_room"})
	var room := host.last("room")
	assert_int(room["code"].length()).is_equal(4)
	assert_str(room["phase"]).is_equal("lobby")
	assert_int(room["you_seat"]).is_equal(0)
	assert_int(room["host_seat"]).is_equal(0)
	assert_int(room["seats"].size()).is_equal(8)
	assert_str(room["seats"][0]["kind"]).is_equal("human")
	assert_int(server.room_count()).is_equal(1)


func test_room_codes_only_use_the_allowed_letters() -> void:
	var server := _server()
	for i in 20:
		var host := FakeClient.connect_to(server, "H%d" % i)
		host.say({"type": "create_room"})
		for letter in host.room_code():
			assert_bool(Protocol.CODE_LETTERS.contains(letter)).is_true()


func test_joining_by_code_seats_you_and_tells_everyone() -> void:
	var server := _server()
	var clients := _lobby(server, 2)
	assert_int(clients[1].last("room")["you_seat"]).is_equal(1)
	assert_str(clients[0].last("room")["seats"][1]["name"]).is_equal("GUEST1")


func test_codes_are_case_insensitive() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "HOST")
	host.say({"type": "create_room"})
	var guest := FakeClient.connect_to(server, "G")
	guest.say({"type": "join_room", "code": host.room_code().to_lower()})
	assert_int(guest.last("room")["you_seat"]).is_equal(1)


func test_duplicate_names_get_a_number() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "SAM")
	host.say({"type": "create_room"})
	var twin := FakeClient.connect_to(server, "SAM")
	twin.say({"type": "join_room", "code": host.room_code()})
	assert_str(twin.last("room")["seats"][1]["name"]).is_equal("SAM2")


func test_joining_a_missing_or_malformed_room_fails() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server, "A")
	client.say({"type": "join_room", "code": "ABCD"})
	client.say({"type": "join_room", "code": "x"})
	client.say({"type": "join_room"})
	assert_array(client.error_codes()).is_equal([Protocol.E_NO_SUCH_ROOM, Protocol.E_NO_SUCH_ROOM, Protocol.E_NO_SUCH_ROOM])


func test_a_ninth_player_is_told_the_room_is_full() -> void:
	var server := _server()
	var clients := _lobby(server, 8)
	var late := FakeClient.connect_to(server, "LATE")
	late.say({"type": "join_room", "code": clients[0].room_code()})
	assert_array(late.error_codes()).is_equal([Protocol.E_ROOM_FULL])


func test_you_cannot_be_in_two_rooms() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "H")
	host.say({"type": "create_room"})
	host.say({"type": "create_room"})
	assert_array(host.error_codes()).is_equal([Protocol.E_ALREADY_IN_ROOM])


func test_only_the_host_controls_the_lobby() -> void:
	var server := _server()
	var clients := _lobby(server, 3)
	var guest := clients[1]
	for message in [{"type": "add_bot"}, {"type": "start_game"}, {"type": "set_options", "speed": "fast"}, {"type": "remove_seat", "seat": 2}]:
		guest.say(message)
	assert_array(guest.error_codes()).is_equal([Protocol.E_NOT_HOST, Protocol.E_NOT_HOST, Protocol.E_NOT_HOST, Protocol.E_NOT_HOST])


func test_the_host_can_add_bots_and_set_options() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "H")
	host.say({"type": "create_room"})
	host.say({"type": "add_bot"})
	host.say({"type": "set_options", "difficulty": "easy", "speed": "fast"})
	var room := host.last("room")
	assert_str(room["seats"][1]["kind"]).is_equal("bot")
	assert_str(room["options"]["difficulty"]).is_equal("easy")
	assert_str(room["options"]["speed"]).is_equal("fast")


func test_bad_options_are_refused() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "H")
	host.say({"type": "create_room"})
	host.say({"type": "set_options", "speed": "ludicrous"})
	host.say({"type": "set_options", "difficulty": "impossible"})
	assert_array(host.error_codes()).is_equal([Protocol.E_BAD_MESSAGE, Protocol.E_BAD_MESSAGE])


func test_the_host_can_kick_a_player() -> void:
	var server := _server()
	var clients := _lobby(server, 3)
	clients[0].say({"type": "remove_seat", "seat": 2})
	assert_str(clients[2].last("left")["reason"]).is_equal("kicked")
	assert_str(clients[0].last("room")["seats"][2]["kind"]).is_equal("empty")
	clients[2].say({"type": "play", "cards": ["3H"]})
	assert_array(clients[2].error_codes()).contains([Protocol.E_NOT_IN_ROOM])


func test_starting_needs_three_seats() -> void:
	var server := _server()
	var clients := _lobby(server, 2)
	clients[0].say({"type": "start_game"})
	assert_array(clients[0].error_codes()).is_equal([Protocol.E_NOT_ENOUGH_PLAYERS])


func test_cannot_join_once_the_game_has_started() -> void:
	var server := _server()
	var clients := _game(server)
	var late := FakeClient.connect_to(server, "LATE")
	late.say({"type": "join_room", "code": clients[0].room_code()})
	assert_array(late.error_codes()).is_equal([Protocol.E_ROOM_STARTED])


func test_leaving_the_lobby_frees_the_seat_and_moves_the_host() -> void:
	var server := _server()
	var clients := _lobby(server, 3)
	clients[0].say({"type": "leave_room"})
	assert_str(clients[0].last("left")["reason"]).is_equal("left")
	var room := clients[1].last("room")
	assert_str(room["seats"][0]["kind"]).is_equal("empty")
	assert_int(room["host_seat"]).is_equal(1)


func test_an_empty_room_is_closed() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "H")
	host.say({"type": "create_room"})
	host.say({"type": "leave_room"})
	assert_int(server.room_count()).is_equal(0)


func test_an_idle_lobby_is_eventually_closed() -> void:
	var server := _server()
	var host := FakeClient.connect_to(server, "H")
	host.say({"type": "create_room"})
	host.hang_up()
	_step(server, Room.LOBBY_IDLE_SECONDS + 5.0, 5.0)
	assert_int(server.room_count()).is_equal(0)


# --- starting a game and privacy --------------------------------------------------------

func test_starting_sends_each_player_their_own_view() -> void:
	var server := _server()
	var clients := _game(server)
	for i in 3:
		var start := clients[i].last("game_start")
		assert_int(start["state"]["my_seat"]).is_equal(i)
		assert_int(start["state"]["my_hand"].size()).is_equal(17)
		assert_array(start["state"]["hand_sizes"]).is_equal([17, 17, 17])
		assert_int(start["game_number"]).is_equal(1)
		assert_str(clients[i].last("room")["phase"]).is_equal("playing")


func test_nobody_ever_receives_another_players_cards() -> void:
	var server := _server()
	var clients := _game(server)
	var rng := _rng(5)
	for step in 600:
		server.tick(0.1)
		for client in clients:
			client.act_randomly(rng)
	# Collect each player's own cards across the whole game, then make sure those codes never
	# appeared in anyone else's inbox except as public pile plays (event cards) or exchange.
	for owner in 3:
		var secret := {}
		for code in clients[owner].last("game_start")["state"]["my_hand"]:
			secret[code] = true
		for other in 3:
			if other == owner:
				continue
			for message in clients[other].inbox:
				if message["type"] == "game_start" or message["type"] == "update":
					var hand: Array = message["state"]["my_hand"]
					for code in hand:
						if clients[owner].last("game_start")["state"]["my_hand"].has(code):
							assert_bool(false).override_failure_message("player %d was sent player %d's card %s in their hand" % [other, owner, code]).is_true()


func test_the_first_game_has_no_transfers() -> void:
	var server := _server()
	var clients := _game(server)
	assert_array(clients[0].last("game_start")["transfers"]).is_empty()


# --- playing ---------------------------------------------------------------------------

func test_a_human_turn_is_announced_with_a_deadline() -> void:
	var server := _server(0.0, 15.0)
	var clients := _game(server)
	var mover := -1
	for update in clients[0].of_type("update"):
		if update["turn"] != null:
			mover = update["turn"]["seat"]
			assert_int(update["turn"]["ms_left"]).is_between(14000, 15000)
			assert_str(update["event"]["type"]).is_equal("turn")
	assert_int(mover).is_greater_equal(0)


func test_moving_out_of_turn_is_refused() -> void:
	var server := _server()
	var clients := _game(server)
	var current: int = clients[0].last("update")["turn"]["seat"]
	var wrong := clients[(current + 1) % 3]
	wrong.say({"type": "pass"})
	wrong.say({"type": "play", "cards": ["3H"]})
	assert_array(wrong.error_codes()).is_equal([Protocol.E_NOT_YOUR_TURN, Protocol.E_NOT_YOUR_TURN])


func test_illegal_moves_are_refused_and_change_nothing() -> void:
	var server := _server()
	var clients := _game(server)
	var current: int = clients[0].last("update")["turn"]["seat"]
	var mover := clients[current]
	var before: int = mover.last("update")["seq"]
	mover.say({"type": "play", "cards": ["AS", "AS", "AS", "AS", "AS"]})  # too many
	mover.say({"type": "play", "cards": ["ZZ"]})  # not a card
	mover.say({"type": "play", "cards": "7H"})  # wrong shape
	mover.say({"type": "pass"})  # cannot pass on an empty table
	assert_int(mover.error_codes().size()).is_equal(4)
	assert_int(mover.last("update")["seq"]).is_equal(before)


func test_cards_you_do_not_hold_are_refused() -> void:
	var server := _server()
	var clients := _game(server)
	var current: int = clients[0].last("update")["turn"]["seat"]
	var mover := clients[current]
	var mine: Array = mover.last("game_start")["state"]["my_hand"]
	var foreign := ""
	for rank in ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]:
		for suit in ["C", "D", "H", "S"]:
			if not mine.has(rank + suit):
				foreign = rank + suit
	mover.say({"type": "play", "cards": [foreign]})
	assert_array(mover.error_codes()).is_equal([Protocol.E_ILLEGAL_MOVE])


func test_a_legal_move_reaches_everyone_as_an_update() -> void:
	var server := _server()
	var clients := _game(server)
	var current: int = clients[0].last("update")["turn"]["seat"]
	var mover := clients[current]
	var code: String = mover.last("game_start")["state"]["my_hand"][0]
	mover.say({"type": "play", "cards": [code]})
	for client in clients:
		var moves: Array = client.of_type("update").filter(func(m: Dictionary) -> bool: return m["event"]["type"] == "move")
		assert_int(moves.size()).is_equal(1)
		assert_array(moves[0]["event"]["cards"]).is_equal([code])
		assert_int(moves[0]["event"]["seat"]).is_equal(current)
	var seqs: Array = clients[0].of_type("update").map(func(m: Dictionary) -> int: return m["seq"])
	for i in range(1, seqs.size()):
		assert_int(seqs[i]).is_equal(seqs[i - 1] + 1)


func test_a_full_three_human_game_plays_to_the_end_over_the_protocol() -> void:
	var server := _server()
	var clients := _game(server)
	var rng := _rng(9)
	var steps := 0
	while clients[0].of_type("game_over").is_empty() and steps < 20000:
		steps += 1
		server.tick(0.1)
		for client in clients:
			client.act_randomly(rng)
	for client in clients:
		var over := client.last("game_over")
		assert_bool(over.is_empty()).is_false()
		assert_int(over["ranking"].size()).is_equal(3)
		assert_str(client.last("room")["phase"]).is_equal("game_over")
		assert_array(client.error_codes()).is_empty()


func test_the_host_can_start_the_next_game_with_an_exchange() -> void:
	var server := _server()
	var clients := _game(server)
	var rng := _rng(11)
	var steps := 0
	while clients[0].of_type("game_over").is_empty() and steps < 20000:
		steps += 1
		server.tick(0.1)
		for client in clients:
			client.act_randomly(rng)
	clients[0].say({"type": "next_game"})
	var start := clients[0].last("game_start")
	assert_int(start["game_number"]).is_equal(2)
	assert_int(start["transfers"].size()).is_equal(2)  # 3 players: only first <-> last swap
	# A player outside the swap sees only a count; the two involved see cards.
	var seen_cards := 0
	var seen_counts := 0
	for client in clients:
		for transfer in client.last("game_start")["transfers"]:
			if transfer.has("cards"):
				seen_cards += 1
			else:
				seen_counts += 1
	assert_int(seen_cards).is_equal(4)  # each of 2 swappers sees both transfers
	assert_int(seen_counts).is_equal(2)  # the third player sees counts only


func test_only_the_host_can_start_the_next_game() -> void:
	var server := _server()
	var clients := _game(server)
	var rng := _rng(12)
	var steps := 0
	while clients[0].of_type("game_over").is_empty() and steps < 20000:
		steps += 1
		server.tick(0.1)
		for client in clients:
			client.act_randomly(rng)
	clients[1].say({"type": "next_game"})
	assert_array(clients[1].error_codes()).contains([Protocol.E_NOT_HOST])


func test_back_to_lobby_returns_everyone_to_the_lobby() -> void:
	var server := _server()
	var clients := _game(server)
	var rng := _rng(13)
	var steps := 0
	while clients[0].of_type("game_over").is_empty() and steps < 20000:
		steps += 1
		server.tick(0.1)
		for client in clients:
			client.act_randomly(rng)
	clients[0].say({"type": "back_to_lobby"})
	assert_str(clients[1].last("room")["phase"]).is_equal("lobby")


# --- time, drops and reconnects ------------------------------------------------------

func test_running_out_of_time_makes_a_move_for_you() -> void:
	var server := _server(0.0, 5.0)
	var clients := _game(server)
	_step(server, 6.0)
	var types: Array = clients[0].of_type("update").map(func(m: Dictionary) -> String: return m["event"]["type"])
	assert_bool(types.has("timeout")).is_true()
	var moved := clients[0].of_type("update").filter(func(m: Dictionary) -> bool: return m["event"]["type"] == "move")
	assert_bool(moved.is_empty()).is_false()


func test_a_dropped_player_gets_a_bot_after_the_grace_period() -> void:
	var server := _server(0.2, 10.0)
	var clients := _game(server)
	clients[2].hang_up()
	assert_bool(clients[0].last("room")["seats"][2]["connected"]).is_false()
	assert_bool(clients[0].last("room")["seats"][2]["bot_playing"]).is_false()
	_step_alive(server, [clients[0], clients[1]], Room.GRACE_SECONDS + 2.0)
	assert_bool(clients[0].last("room")["seats"][2]["bot_playing"]).is_true()
	# The game carries on without them: the bot makes moves for seat 2.
	var rng := _rng(14)
	var seat_two_moves := 0
	for step in 400:
		server.tick(0.1)
		for client in [clients[0], clients[1]]:
			client.act_randomly(rng)
	for update in clients[0].of_type("update"):
		if update["event"]["type"] == "move" and update["event"]["seat"] == 2:
			seat_two_moves += 1
	assert_int(seat_two_moves).is_greater(0)


func test_reconnecting_with_the_token_returns_you_to_your_seat() -> void:
	var server := _server(0.2, 20.0)
	var clients := _game(server)
	var token: String = clients[1].token
	clients[1].hang_up()
	_step_alive(server, [clients[0], clients[2]], Room.GRACE_SECONDS + 2.0)  # a bot has taken over
	var back := FakeClient.connect_to(server)
	back.say({"type": "hello", "version": 1, "name": "GUEST1", "token": token})
	assert_str(back.last("welcome")["token"]).is_equal(token)
	var room := back.last("room")
	assert_int(room["you_seat"]).is_equal(1)
	assert_bool(room["seats"][1]["bot_playing"]).is_false()
	var sync := back.last("update")
	assert_str(sync["event"]["type"]).is_equal("sync")
	assert_int(sync["state"]["my_seat"]).is_equal(1)
	assert_int(sync["state"]["my_hand"].size()).is_greater(0)


func test_reconnecting_within_the_grace_period_keeps_playing_as_a_human() -> void:
	var server := _server(0.2, 20.0)
	var clients := _game(server)
	var token: String = clients[1].token
	clients[1].hang_up()
	_step_alive(server, [clients[0], clients[2]], 10.0)
	var back := FakeClient.connect_to(server)
	back.say({"type": "hello", "version": 1, "name": "GUEST1", "token": token})
	assert_bool(clients[0].last("room")["seats"][1]["connected"]).is_true()
	assert_bool(clients[0].last("room")["seats"][1]["bot_playing"]).is_false()


func test_signing_in_from_a_second_place_replaces_the_first() -> void:
	var server := _server()
	var first := FakeClient.connect_to(server, "ME")
	var second := FakeClient.connect_to(server)
	second.say({"type": "hello", "version": 1, "name": "ME", "token": first.token})
	assert_array(first.error_codes()).contains([Protocol.E_REPLACED])
	assert_bool(first.closed).is_true()
	assert_str(second.last("welcome")["token"]).is_equal(first.token)


func test_a_wrong_token_just_starts_a_new_session() -> void:
	var server := _server()
	var client := FakeClient.connect_to(server)
	client.say({"type": "hello", "version": 1, "name": "NEW", "token": "deadbeef"})
	assert_str(client.last("welcome")["token"]).is_not_equal("deadbeef")


func test_leaving_mid_game_hands_the_seat_to_a_bot_permanently() -> void:
	var server := _server(0.2, 20.0)
	var clients := _game(server)
	clients[2].say({"type": "leave_room"})
	var seat: Dictionary = clients[0].last("room")["seats"][2]
	assert_str(seat["kind"]).is_equal("bot")
	assert_bool(seat["bot_playing"]).is_true()


func test_when_the_last_human_leaves_mid_game_the_room_closes() -> void:
	var server := _server(0.2, 20.0)
	var clients := _game(server)
	for client in clients:
		client.say({"type": "leave_room"})
	assert_int(server.room_count()).is_equal(0)


func test_the_host_leaving_mid_game_passes_hosting_on() -> void:
	var server := _server(0.2, 20.0)
	var clients := _game(server)
	clients[0].say({"type": "leave_room"})
	assert_int(clients[1].last("room")["host_seat"]).is_equal(1)


# --- load -----------------------------------------------------------------------------

func test_many_rooms_play_at_once_without_errors() -> void:
	var server := _server(0.0, 20.0)
	var rng := _rng(77)
	var humans: Array[FakeClient] = []
	for room_number in 25:
		var host := FakeClient.connect_to(server, "H%d" % room_number)
		host.say({"type": "create_room"})
		host.say({"type": "add_bot"})
		host.say({"type": "add_bot"})
		host.say({"type": "add_bot"})
		host.say({"type": "start_game"})
		humans.append(host)
	assert_int(server.room_count()).is_equal(25)
	var steps := 0
	var finished := 0
	while finished < humans.size() and steps < 40000:
		steps += 1
		server.tick(0.1)
		finished = 0
		for host in humans:
			host.act_randomly(rng)
			if not host.of_type("game_over").is_empty():
				finished += 1
	assert_int(finished).is_equal(25)
	for host in humans:
		assert_array(host.error_codes()).is_empty()
