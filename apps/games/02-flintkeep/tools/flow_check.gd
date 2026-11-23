extends SceneTree
## Smoke test of the whole loop through the real screens: menu -> battle -> retreat ->
## summary -> research -> start research -> menu. Fails loudly on script errors.
##   godot --path godot -s ../tools/flow_check.gd -- [screenshot dir]

func _initialize() -> void:
	var out_dir := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else ""
	await process_frame
	var profile: Node = root.get_node("Profile")
	profile.save_path = "user://flow_check_save.json"
	profile.data = ProfileData.new()
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.show_battle(1)
	await create_timer(0.5).timeout
	var battle_screen: Node = _screen(main)
	var b: Battle = battle_screen.battle
	_expect(b.cash >= 60.0, "start cash")
	# tap the north slot through the real input path
	var view: Node2D = battle_screen.view
	var slot_pos: Vector2 = view.position + (b.slots[0].pos + Vector2(0, -4)) * view.zoom
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = slot_pos
	battle_screen._on_field_input(click)
	_expect(battle_screen.view.selected_slot == 0, "tapping a slot selects it (got %d)" % battle_screen.view.selected_slot)
	await create_timer(0.3).timeout
	await _shot(out_dir, "flow_slot")
	_expect(b.build(0, "musket"), "build musket")
	b.build_wall(1)
	battle_screen.view.speed = 3.0
	await create_timer(6.0).timeout
	_expect(b.wave >= 1 and not b.over, "battle runs")
	battle_screen._pause()
	await create_timer(0.3).timeout
	await _shot(out_dir, "flow_pause")
	battle_screen._end_run()
	await create_timer(0.3).timeout
	await _shot(out_dir, "flow_summary")
	_expect(profile.data.runs == 1, "run recorded")
	_expect(profile.data.coins > 0.0, "coins banked (%.1f)" % profile.data.coins)
	battle_screen.finished.emit("research")
	await create_timer(0.3).timeout
	profile.data.coins += 100.0
	_expect(profile.start_research("keep_damage"), "start research")
	await create_timer(1.2).timeout
	await _shot(out_dir, "flow_research")
	_screen(main).back.emit()
	await create_timer(0.3).timeout
	await _shot(out_dir, "flow_menu")
	print("FLOW OK")
	quit(0)


func _screen(main: Control) -> Node:
	return main.get_child(main.get_child_count() - 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		print("FLOW FAILED: " + what)
		quit(1)


func _shot(dir: String, name: String) -> void:
	if dir == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir.path_join(name + ".png"))
