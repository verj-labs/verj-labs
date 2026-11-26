extends SceneTree
## Developer tool: a late-run battle (wave 60, three rings full of upgraded towers, a crowded
## field) to measure where frame time goes. Needs a window (not --headless):
##
##   godot --path godot --resolution 540x1170 -s ../tools/bench.gd [-- enemies=70 seconds=5]
##
## Prints the average frame time with everything on, with the battlefield hidden (so the
## difference is drawing), and the battle simulation alone.

var _opts := {"enemies": "70", "seconds": "5"}
var _bs: Node
var _b: Battle


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.contains("="):
			_opts[arg.get_slice("=", 0)] = arg.get_slice("=", 1)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await process_frame
	var profile: Node = root.get_node("Profile")
	profile.set_process(false)
	profile.save_path = "user://bench_save.json"
	profile.data = ProfileData.new()
	profile.data.research = {"musket": 10, "cannon": 10, "volley": 8, "sniper": 6, "arcane": 4, "ring_2": 1, "ring_3": 1}
	profile.data.workshop = {"damage": 10, "health": 10, "towers": 10}
	profile.data.tutorial_done = true
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.show_battle(1)
	await process_frame
	_bs = main.get_child(main.get_child_count() - 1)
	_b = _bs.battle
	_setup()
	await _measure("warm-up", 1.0)
	var full := await _measure("everything", float(_opts["seconds"]))
	var view: Node2D = _bs.view
	var parts := {"effects": [view.fx], "ground": [view.get("_ground")]}
	parts["walls"] = view.get("_wall_pieces").map(func(item: Array) -> Node: return item[2])
	parts["enemies"] = view.get("_enemy_sprites").values()
	parts["towers"] = view.get("_slot_stands").values()
	parts["decor"] = view.get("_decor_stands")
	for part in parts:
		for node in parts[part]:
			node.visible = false
		var ms := await _measure("no " + part, float(_opts["seconds"]) / 2.0)
		print("    -> %s cost ~%.2f ms" % [part, full - ms])
		for node in parts[part]:
			node.visible = true
	view.visible = false
	var hidden := await _measure("field hidden", float(_opts["seconds"]))
	view.visible = true
	var sim := _measure_sim(300)
	print("BENCH frame %.2f ms (%.0f fps) | drawing+fx ~%.2f ms | simulation %.2f ms per frame at 1x"
		% [full, 1000.0 / full, full - hidden, sim])
	quit()


func _setup() -> void:
	var b := _b
	b.cash = 1e18
	b.wave = 59
	for id in ["damage", "rate", "crit_chance", "crit_factor", "multishot", "bounce", "push_chance", "health", "regen", "armor", "thorns"]:
		b.levels[id] = mini(30, Upgrades.LIST[id]["max"]) if Upgrades.LIST[id]["max"] > 0 else 30
	var weapons := ["musket", "cannon", "volley", "sniper", "arcane"]
	for i in b.slots.size():
		if b.slot_open(i):
			b.build(i, weapons[i % weapons.size()])
			for k in 15:
				b.upgrade_tower(i)
	for ring in range(1, b.rings_unlocked + 1):
		b.build_wall(ring)
	b.wave_timer = 0.01


## Keeps the field crowded (so every frame has the same load) and the Keep alive.
func _top_up() -> void:
	var kinds := ["footman", "runner", "brute", "balloon", "wyvern", "sapper", "shaman"]
	while _b.enemies.size() < int(_opts["enemies"]):
		_b.spawn(kinds[_b.rng.randi() % kinds.size()], _b.rng.randf() * TAU)
	_b.keep_hp = _b.keep_max_hp()
	_b.over = false


func _measure(label: String, seconds: float) -> float:
	var frames := 0
	var script_ms := 0.0
	var render_cpu := 0.0
	var render_gpu := 0.0
	var vp := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < seconds * 1e6:
		_top_up()
		await process_frame
		frames += 1
		script_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		render_cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu()
		render_gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var n := maxf(frames, 1)
	var ms := (Time.get_ticks_usec() - start) / 1000.0 / n
	print("  %-13s %.2f ms a frame over %d frames | scripts %.2f  render cpu %.2f  gpu %.2f | enemies %d shots %d texts %d particles %d"
		% [label, ms, frames, script_ms / n, render_cpu / n, render_gpu / n, _b.enemies.size(), _bs.view.fx.shots.size(), _bs.view.fx.texts.size(), _bs.view.fx.particles.size()])
	return ms


## The simulation alone: one 1/60 s step (what a 60 fps frame runs at 1x), in ms.
func _measure_sim(steps: int) -> float:
	_bs.view.paused = true
	var spent := 0
	for i in steps:
		_top_up()
		var t := Time.get_ticks_usec()
		_b.step(1.0 / 60.0)
		spent += Time.get_ticks_usec() - t
	_b.drain_events()
	return spent / 1000.0 / steps
