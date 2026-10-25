extends GdUnitTestSuite
## Phone behaviour of the UI: scrolling by dragging anywhere, the leave-game confirmation, and the
## single-player match length reaching the table.


func after_test() -> void:
	SessionConfig.match_games = ShahMatch.DEFAULT_GAMES
	SessionConfig.rng_seed = 0


func _touch(scroll: TouchScroll, pressed: bool, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = position
	scroll._input(event)


func _drag(scroll: TouchScroll, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	event.relative = relative
	scroll._input(event)


func _tall_scroll() -> TouchScroll:
	var scroll := TouchScroll.new()
	scroll.position = Vector2(0, 0)
	scroll.size = Vector2(300, 300)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var content := Control.new()
	content.custom_minimum_size = Vector2(200, 900)
	column.add_child(content)
	scroll.add_child(column)
	add_child(scroll)
	auto_free(scroll)
	return scroll


func test_dragging_up_scrolls_the_content_down() -> void:
	var scroll := _tall_scroll()
	await get_tree().process_frame
	await get_tree().process_frame
	_touch(scroll, true, Vector2(150, 250))
	for step in 10:
		_drag(scroll, Vector2(150, 250 - 20 * (step + 1)), Vector2(0, -20))
	_touch(scroll, false, Vector2(150, 50))
	assert_int(scroll.scroll_vertical).is_greater(100)


func test_a_small_wobble_does_not_scroll() -> void:
	var scroll := _tall_scroll()
	await get_tree().process_frame
	await get_tree().process_frame
	_touch(scroll, true, Vector2(150, 250))
	_drag(scroll, Vector2(150, 245), Vector2(0, -5))
	_touch(scroll, false, Vector2(150, 245))
	assert_int(scroll.scroll_vertical).is_equal(0)


func test_a_touch_outside_the_scroll_area_is_ignored() -> void:
	var scroll := _tall_scroll()
	await get_tree().process_frame
	await get_tree().process_frame
	_touch(scroll, true, Vector2(150, 700))  # below the 300-high area
	for step in 10:
		_drag(scroll, Vector2(150, 700 - 20 * (step + 1)), Vector2(0, -20))
	assert_int(scroll.scroll_vertical).is_equal(0)


func test_a_scrolling_drag_cancels_the_press_on_a_button() -> void:
	var scroll := TouchScroll.new()
	scroll.size = Vector2(300, 300)
	var column := VBoxContainer.new()
	var button := Button.new()
	button.custom_minimum_size = Vector2(200, 100)
	var content := Control.new()
	content.custom_minimum_size = Vector2(200, 900)
	column.add_child(button)
	column.add_child(content)
	scroll.add_child(column)
	add_child(scroll)
	auto_free(scroll)
	var clicks := [0]
	button.pressed.connect(func() -> void: clicks[0] += 1)
	await get_tree().process_frame
	await get_tree().process_frame
	_touch(scroll, true, Vector2(100, 50))
	for step in 6:
		_drag(scroll, Vector2(100, 50 - 8 * (step + 1)), Vector2(0, -8))
	_touch(scroll, false, Vector2(100, 2))
	assert_int(clicks[0]).is_equal(0)


func test_leaving_a_running_game_asks_first() -> void:
	SessionConfig.rng_seed = 4
	var table: Control = (load("res://scenes/game_table.tscn") as PackedScene).instantiate()
	add_child(table)
	auto_free(table)
	await get_tree().process_frame
	table._leave_to_menu()
	var dialogs: Array = table._top.get_children().filter(func(node: Node) -> bool: return node is ArcadeConfirm)
	assert_int(dialogs.size()).is_equal(1)
	(dialogs[0] as ArcadeConfirm).cancelled.emit()  # STAY keeps the game; the dialog just closes


func test_single_player_uses_the_chosen_match_length() -> void:
	SessionConfig.match_games = 20
	SessionConfig.rng_seed = 3
	var table: Control = (load("res://scenes/game_table.tscn") as PackedScene).instantiate()
	add_child(table)
	auto_free(table)
	await get_tree().process_frame
	assert_int(table.controller.total_games).is_equal(20)
	assert_int(table.controller.state.total_games).is_equal(20)


func test_the_table_header_shows_progress_through_the_match() -> void:
	SessionConfig.rng_seed = 5
	var table: Control = (load("res://scenes/game_table.tscn") as PackedScene).instantiate()
	add_child(table)
	auto_free(table)
	await get_tree().process_frame
	assert_str(table._game_label.text).is_equal("GAME 1/10")
