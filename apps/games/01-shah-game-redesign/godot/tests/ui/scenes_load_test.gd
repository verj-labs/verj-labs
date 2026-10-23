extends GdUnitTestSuite
## Smoke test: every screen loads, builds itself and runs a few frames without errors.
## (A typo in a UI script otherwise only shows up when someone opens that screen.)


func _load_and_run(path: String) -> Control:
	var scene: Control = load(path).instantiate()
	add_child(scene)
	auto_free(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func test_main_menu_loads() -> void:
	var scene := await _load_and_run("res://scenes/main_menu.tscn")
	assert_object(scene).is_not_null()


func test_setup_screen_loads() -> void:
	var scene := await _load_and_run("res://scenes/setup_screen.tscn")
	assert_object(scene).is_not_null()


func test_game_table_loads_and_shows_every_seat(players: int, test_parameters := [[3], [5], [8]]) -> void:
	SessionConfig.player_count = players
	var scene := await _load_and_run("res://scenes/game_table.tscn")
	assert_object(scene.controller.game).is_not_null()
	assert_int(scene.controller.game.player_count).is_equal(players)
	# Every seat, including yours, is drawn around the ring.
	assert_int(scene._ring._seat_views.size()).is_equal(players)
	SessionConfig.player_count = 4
