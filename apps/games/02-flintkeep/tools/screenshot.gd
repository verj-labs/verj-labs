extends SceneTree
## Developer tool: opens a screen in a phone-shaped window and saves a screenshot, so layouts
## can be checked without a device. Needs a real window (not --headless):
##
##   godot --path godot --resolution 540x1170 -s ../tools/screenshot.gd -- battle out.png wait=20 research=mid auto=1 speed=3
##
## Screens: menu, battle, research, missions, settings. tutorial=1 shows the first-run tips. research=fresh|mid|late fakes a profile (nothing is saved).
## auto=1 lets the AutoPlayer spend cash during the battle. slot=N selects a build slot.

const PROFILES := {
	"fresh": {},
	"mid": {"keep_damage": 10, "keep_health": 10, "start_cash": 8, "cash_bonus": 6, "musket": 4, "cannon": 4, "volley": 3, "sniper": 2, "ring_2": 1, "masonry": 5},
	"late": {"keep_damage": 25, "keep_health": 25, "keep_regen": 15, "start_cash": 25, "cash_bonus": 15, "musket": 10, "cannon": 10, "volley": 8, "sniper": 6, "arcane": 4, "ring_2": 1, "ring_3": 1, "ring_4": 1, "masonry": 15},
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := args[0]
	var out_path := args[1]
	var opts := {"wait": "2", "research": "fresh", "auto": "0", "speed": "1", "slot": "-1", "tab": "", "tutorial": "0"}
	for arg in args.slice(2):
		if arg.contains("="):
			opts[arg.get_slice("=", 0)] = arg.get_slice("=", 1)
	await process_frame  # let the Profile autoload load first, then replace its data
	var profile: Node = root.get_node("Profile")
	profile.set_process(false)
	profile.save_path = "user://screenshot_save.json"
	profile.data = ProfileData.new()
	profile.data.research = PROFILES[opts["research"]].duplicate()
	profile.data.coins = 1234.0
	profile.data.best_wave = {"1": 23}
	profile.data.labs[0] = {"id": "keep_damage", "ends": Time.get_unix_time_from_system() + 95.0}
	profile.data.tutorial_done = opts["tutorial"] != "1"
	profile.data.refresh_missions(Missions.today())
	profile.data.missions[0]["progress"] = profile.data.missions[0]["target"]
	profile.data.missions[1]["progress"] = int(profile.data.missions[1]["target"]) / 2
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	match screen:
		"battle": main.show_battle(1)
		"research": main.show_research()
		"missions": main.get_child(main.get_child_count() - 1).call("_open_missions")
		"settings": main.get_child(main.get_child_count() - 1).call("_open_settings")
	await process_frame
	var screen_node: Node = main.get_child(main.get_child_count() - 1)
	if screen == "battle":
		var bs: Node = screen_node  # untyped: UI classes need the Profile autoload to compile
		bs.view.speed = float(opts["speed"])
		if opts["auto"] == "1":
			_autoplay(bs)
		if int(opts["slot"]) >= 0:
			await create_timer(float(opts["wait"]) - 0.3).timeout
			bs.call("_select_slot", int(opts["slot"]))
	await create_timer(float(opts["wait"])).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out_path)
	print("saved %s (%dx%d)" % [out_path, image.get_width(), image.get_height()])
	quit()


func _autoplay(bs: Node) -> void:
	while is_instance_valid(bs) and not bs.battle.over:
		AutoPlayer.think(bs.battle)
		await create_timer(0.5).timeout
