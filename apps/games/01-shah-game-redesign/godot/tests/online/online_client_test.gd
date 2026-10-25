extends GdUnitTestSuite
## The client side of online play (OnlineClient + RemoteTableSource) against the real WebSocket
## server on localhost: lobby flow, a full game through the table-source API, kicks, errors, and
## reconnecting after the socket drops.

var _game: GameServer
var _wss: WsServer


func before_test() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	_game = GameServer.new(rng)
	_game.think_override = 0.0
	_game.turn_override = 20.0
	_wss = WsServer.new()
	assert_int(_wss.start(0, _game)).is_equal(OK)


func after_test() -> void:
	_wss.stop()


func _url() -> String:
	return "ws://127.0.0.1:%d" % _wss.port()


func _client() -> OnlineClient:
	var client := OnlineClient.new()
	client.persist = false  # never touch the player's saved settings from a test
	add_child(client)
	auto_free(client)
	return client


## Runs the server and lets frames pass (so the clients' own _process runs) until `done`.
func _until(done: Callable, timeout_ms: int = 6000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() < deadline:
		_wss.poll(0.02)
		_game.tick(0.02)
		if done.call():
			return true
		await get_tree().process_frame
	return false


func _signed_in(name: String) -> OnlineClient:
	var client := _client()
	client.connect_to_server(_url(), name)
	assert_bool(await _until(func() -> bool: return client.is_online())).is_true()
	return client


func _make_room(host: OnlineClient, guests: Array[OnlineClient], bots: int) -> void:
	host.create_room()
	assert_bool(await _until(func() -> bool: return host.in_room())).is_true()
	for guest in guests:
		guest.join_room(host.room["code"])
	assert_bool(await _until(func() -> bool: return guests.all(func(g: OnlineClient) -> bool: return g.in_room()))).is_true()
	for i in bots:
		host.add_bot()
	await _until(func() -> bool: return host.room["seats"].filter(func(s: Dictionary) -> bool: return s["kind"] != "empty").size() == 1 + guests.size() + bots)


## One step of a sensible player on a RemoteTableSource. Returns true if it moved.
func _autoplay(source: RemoteTableSource, rng: RandomNumberGenerator) -> bool:
	if not source.is_human_turn():
		return false
	var options := source.state.legal_plays()
	if source.state.pile != null and (options.is_empty() or rng.randf() < 0.25):
		return source.submit_pass().accepted
	return source.submit_play(options[rng.randi_range(0, options.size() - 1)].cards).accepted


# --- connecting and the lobby ------------------------------------------------------------

func test_connecting_signs_in_and_gets_a_token() -> void:
	var client := await _signed_in("Waqas")
	assert_str(client.player_name).is_equal("WAQAS")
	assert_int(client.token.length()).is_equal(32)
	assert_bool(client.is_online()).is_true()


func test_create_and_join_a_room() -> void:
	var host := await _signed_in("HOST")
	var guest := await _signed_in("GUEST")
	await _make_room(host, [guest], 0)
	assert_bool(host.is_host()).is_true()
	assert_bool(guest.is_host()).is_false()
	assert_str(guest.room["code"]).is_equal(host.room["code"])
	assert_int(guest.room["you_seat"]).is_equal(1)


func test_server_errors_reach_the_client() -> void:
	var client := await _signed_in("A")
	var codes: Array[String] = []
	client.server_error.connect(func(code: String, _m: String) -> void: codes.append(code))
	client.join_room("ZZZZ")
	assert_bool(await _until(func() -> bool: return not codes.is_empty())).is_true()
	assert_array(codes).is_equal([Protocol.E_NO_SUCH_ROOM])


func test_being_kicked_is_reported() -> void:
	var host := await _signed_in("HOST")
	var guest := await _signed_in("GUEST")
	await _make_room(host, [guest], 0)
	var reasons: Array[String] = []
	guest.left_room.connect(func(reason: String) -> void: reasons.append(reason))
	host.remove_seat(1)
	assert_bool(await _until(func() -> bool: return not reasons.is_empty())).is_true()
	assert_array(reasons).is_equal(["kicked"])
	assert_bool(guest.in_room()).is_false()


func test_a_bad_name_is_refused_with_an_error() -> void:
	var client := _client()
	var codes: Array[String] = []
	client.server_error.connect(func(code: String, _m: String) -> void: codes.append(code))
	client.connect_to_server(_url(), "<<<>>>")
	assert_bool(await _until(func() -> bool: return not codes.is_empty())).is_true()
	assert_array(codes).is_equal([Protocol.E_BAD_NAME])


# --- playing through the table source -------------------------------------------------------

func test_two_humans_and_a_bot_play_a_full_game_through_the_table_source() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 1)
	a.start_game()
	assert_bool(await _until(func() -> bool: return a.table_attached or a._pending_game.size() > 0)).is_true()
	var source_a := RemoteTableSource.new(a)
	var source_b := RemoteTableSource.new(b)
	add_child(source_a)
	add_child(source_b)
	auto_free(source_a)
	auto_free(source_b)
	var finished := [0, 0]
	var rejected := [0]
	source_a.game_finished.connect(func(_r: Array[int]) -> void: finished[0] += 1)
	source_b.game_finished.connect(func(_r: Array[int]) -> void: finished[1] += 1)
	source_a.move_rejected.connect(func(_r: String) -> void: rejected[0] += 1)
	source_b.move_rejected.connect(func(_r: String) -> void: rejected[0] += 1)
	var started := [0]
	source_a.game_started.connect(func() -> void: started[0] += 1)
	source_a.start_next_game()
	source_b.start_next_game()
	assert_int(started[0]).is_equal(1)  # the early game_start was replayed on attach
	assert_int(source_a.state.player_count).is_equal(3)
	assert_int(source_a.state.my_hand.size()).is_equal(17)
	assert_int(source_a.human_seat).is_equal(0)
	assert_int(source_b.human_seat).is_equal(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var done := await _until(func() -> bool:
		_autoplay(source_a, rng)
		_autoplay(source_b, rng)
		return finished[0] == 1 and finished[1] == 1
	, 30000)
	assert_bool(done).is_true()
	assert_int(rejected[0]).is_equal(0)
	assert_bool(source_a.is_human_turn()).is_false()


func test_the_table_source_announces_my_turn_with_a_countdown() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 1)
	a.start_game()
	await _until(func() -> bool: return a._pending_game.size() > 0)
	var source := RemoteTableSource.new(a)
	add_child(source)
	auto_free(source)
	var turns := [0]
	source.human_turn_started.connect(func() -> void: turns[0] += 1)
	source.start_next_game()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	# Play until it is ours (seat 0 may not lead); then check the countdown is sane.
	assert_bool(await _until(func() -> bool: return source.is_human_turn() or turns[0] > 0, 15000)).is_true()
	assert_float(source.time_left).is_between(1.0, 20.0)
	assert_float(source.turn_seconds).is_equal(20.0)


func test_the_last_game_ends_the_match_and_the_host_returns_everyone_to_the_lobby() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 1)
	a.start_game()
	assert_bool(await _until(func() -> bool: return a._pending_game.size() > 0 and b._pending_game.size() > 0)).is_true()
	_game.room_for_code(a.room["code"]).runner.match_session.max_games = 1
	var source_a := RemoteTableSource.new(a)
	var source_b := RemoteTableSource.new(b)
	for source in [source_a, source_b]:
		add_child(source)
		auto_free(source)
		source.start_next_game()
	var back := [0, 0]
	source_a.returned_to_lobby.connect(func() -> void: back[0] += 1)
	source_b.returned_to_lobby.connect(func() -> void: back[1] += 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var done := await _until(func() -> bool:
		_autoplay(source_a, rng)
		_autoplay(source_b, rng)
		return source_a.match_over and source_b.match_over
	, 30000)
	assert_bool(done).is_true()
	assert_int(source_a.scores.size()).is_equal(3)
	assert_int(source_a.standings.size()).is_equal(3)
	assert_int(source_a.total_games).is_equal(1)
	assert_bool(source_b.can_start_next_game()).is_false()
	source_a.return_to_lobby()
	assert_bool(await _until(func() -> bool: return back[0] == 1 and back[1] == 1)).is_true()


func test_non_hosts_cannot_start_the_next_game() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 1)
	a.start_game()
	await _until(func() -> bool: return a._pending_game.size() > 0 and b._pending_game.size() > 0)
	var host_source := RemoteTableSource.new(a)
	var guest_source := RemoteTableSource.new(b)
	add_child(host_source)
	add_child(guest_source)
	auto_free(host_source)
	auto_free(guest_source)
	host_source.start_next_game()
	guest_source.start_next_game()
	assert_bool(host_source.can_start_next_game()).is_true()
	assert_bool(guest_source.can_start_next_game()).is_false()


# --- stepping away and rejoining -----------------------------------------------------------

func test_a_player_who_steps_away_from_a_running_game_can_rejoin_it() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 1)
	a.start_game()
	assert_bool(await _until(func() -> bool: return a._pending_game.size() > 0 and b._pending_game.size() > 0)).is_true()
	var first := RemoteTableSource.new(b)
	add_child(first)
	auto_free(first)
	first.start_next_game()
	assert_bool(b.can_rejoin()).is_false()
	first.step_away()
	assert_bool(b.is_online()).is_false()
	assert_bool(b.in_room()).is_false()
	assert_bool(b.can_rejoin()).is_true()
	b.rejoin()
	assert_bool(await _until(func() -> bool: return b.in_room() and b._pending_game.size() > 0)).is_true()
	assert_str(b.room["phase"]).is_equal("playing")
	var second := RemoteTableSource.new(b)
	add_child(second)
	auto_free(second)
	second.start_next_game()
	assert_object(second.state).is_not_null()
	assert_int(second.state.my_hand.size()).is_greater(0)
	assert_int(second.state.my_seat).is_equal(1)


func test_leaving_for_good_or_being_kicked_clears_the_rejoin_offer() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 0)
	b._remember_rejoin(str(b.room["code"]))
	assert_bool(b.can_rejoin()).is_true()
	a.remove_seat(1)
	assert_bool(await _until(func() -> bool: return not b.in_room())).is_true()
	assert_bool(b.can_rejoin()).is_false()


func test_the_rejoin_offer_expires() -> void:
	var client := _client()
	client.token = "abc"
	client.player_name = "ANN"
	client.rejoin_code = "ABCD"
	client._rejoin_saved_at = int(Time.get_unix_time_from_system())
	assert_bool(client.can_rejoin()).is_true()
	client._rejoin_saved_at = int(Time.get_unix_time_from_system()) - OnlineClient.REJOIN_SECONDS - 1
	assert_bool(client.can_rejoin()).is_false()


# --- dropped connections ------------------------------------------------------------------

func test_the_client_reconnects_by_itself_and_keeps_its_room() -> void:
	var host := await _signed_in("HOST")
	await _make_room(host, [], 2)
	var token := host.token
	var code: String = host.room["code"]
	var changes: Array[bool] = []
	host.connection_changed.connect(func(connected: bool) -> void: changes.append(connected))
	host._ws.close()  # the network dies
	assert_bool(await _until(func() -> bool: return changes.has(false), 3000)).is_true()
	assert_bool(await _until(func() -> bool: return host.is_online() and changes.has(true), 8000)).is_true()
	assert_str(host.token).is_equal(token)
	assert_str(host.room["code"]).is_equal(code)
	assert_int(host.room["you_seat"]).is_equal(0)


func test_a_player_who_drops_mid_game_comes_back_into_it() -> void:
	var a := await _signed_in("ANN")
	var b := await _signed_in("BEN")
	await _make_room(a, [b], 1)
	a.start_game()
	await _until(func() -> bool: return a._pending_game.size() > 0 and b._pending_game.size() > 0)
	var source_a := RemoteTableSource.new(a)
	var source_b := RemoteTableSource.new(b)
	add_child(source_a)
	add_child(source_b)
	auto_free(source_a)
	auto_free(source_b)
	source_a.start_next_game()
	source_b.start_next_game()
	var finished := [0, 0]
	source_a.game_finished.connect(func(_r: Array[int]) -> void: finished[0] += 1)
	source_b.game_finished.connect(func(_r: Array[int]) -> void: finished[1] += 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var dropped := [false]
	var steps := [0]
	var done := await _until(func() -> bool:
		steps[0] += 1
		if steps[0] == 30 and not dropped[0]:
			dropped[0] = true
			a._ws.close()  # ANN loses her connection mid-game
		_autoplay(source_a, rng)
		_autoplay(source_b, rng)
		return finished[0] == 1 and finished[1] == 1
	, 40000)
	assert_bool(dropped[0]).is_true()
	assert_bool(done).is_true()
