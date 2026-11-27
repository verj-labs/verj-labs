extends SceneTree
## Developer tool: opens a screen in a phone-shaped window and saves a screenshot, so layouts
## can be checked without a device. Needs a real window (not --headless):
##
##   godot --path godot --resolution 540x1170 -s ../tools/screenshot.gd -- battle out.png wait=20 research=mid auto=1 speed=3
##
## Screens: menu, battle, research, missions, settings, bestiary, heroes. hero=captain|engineer|archmage
## unlocks that hero and brings it into the battle. tutorial=1 shows the first-run tips,
## offline=1 the welcome-back coins, section=RING,SEG selects a wall section, tab=Attack|Defense|
## Walls|Economy|Powers opens a panel tab, perk=1 shows the perk choice. research=fresh|mid|late fakes a profile (nothing is saved).
## auto=1 lets the AutoPlayer spend cash during the battle. slot=N selects a build slot.

const PROFILES := {
	"fresh": {},
	"mid": {"musket": 4, "cannon": 4, "volley": 3, "sniper": 2, "ring_2": 1, "power_rain": 2, "power_freeze": 1, "game_speed": 2},
	"late": {"musket": 10, "cannon": 10, "volley": 8, "sniper": 6, "arcane": 4, "ring_2": 1, "ring_3": 1, "ring_4": 1, "power_rain": 5, "power_freeze": 4, "power_thunder": 3, "power_gold": 2, "game_speed": 4},
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := args[0]
	var out_path := args[1]
	var opts := {"wait": "2", "research": "fresh", "auto": "0", "speed": "1", "slot": "-1", "tab": "", "tutorial": "0", "offline": "0", "section": "", "perk": "0"}
	for arg in args.slice(2):
		if arg.contains("="):
			opts[arg.get_slice("=", 0)] = arg.get_slice("=", 1)
	await process_frame  # let the Profile autoload load first, then replace its data
	var profile: Node = root.get_node("Profile")
	profile.set_process(false)
	profile.save_path = "user://screenshot_save.json"
	profile.data = ProfileData.new()
	profile.data.research = PROFILES[opts["research"]].duplicate()
	if opts["research"] != "fresh":
		profile.data.workshop = {"damage": 12, "health": 12, "regen": 6, "towers": 8, "cash": 6} if opts["research"] == "mid" else {"damage": 40, "health": 40, "regen": 25, "towers": 30, "cash": 25, "masonry": 20}
	profile.data.coins = 1234.0
	profile.data.best_wave = {"1": 23}
	profile.data.labs[0] = {"id": "coin_bonus", "ends": Time.get_unix_time_from_system() + 95.0}
	profile.data.tutorial_done = opts["tutorial"] != "1"
	profile.data.refresh_missions(Missions.today())
	profile.data.missions[0]["progress"] = profile.data.missions[0]["target"]
	profile.data.missions[1]["progress"] = int(profile.data.missions[1]["target"]) / 2
	profile.data.gems = 60
	profile.data.day_mode = opts.get("day", "day")  # day=cycle|clock|sunrise|day|sunset|night
	if opts.has("hero"):  # hero=captain|engineer|archmage: unlock it and bring it along
		profile.data.best_wave["1"] = Heroes.unlock_wave(opts["hero"]) + 1
		profile.data.hero = opts["hero"]
	if opts["offline"] == "1":
		profile.offline_pending = 240.0
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	match screen:
		"battle": main.show_battle(1)
		"research": main.show_research()
		"missions": main.get_child(main.get_child_count() - 1).call("_open_missions")
		"settings": main.get_child(main.get_child_count() - 1).call("_open_settings")
		"bestiary": main.get_child(main.get_child_count() - 1).call("_open_bestiary")
		"heroes": main.get_child(main.get_child_count() - 1).call("_open_heroes")
	await process_frame
	var screen_node: Node = main.get_child(main.get_child_count() - 1)
	if screen == "battle":
		var bs: Node = screen_node  # untyped: UI classes need the Profile autoload to compile
		bs.view.speed = float(opts["speed"])
		if opts["auto"] == "1":
			_autoplay(bs)
		if opts.has("thorns"):
			bs.battle.levels["thorns"] = int(opts["thorns"])
		if opts["tab"] != "":
			bs.get("_panel").call("_set_tab", opts["tab"])
		if opts.get("picker", "0") == "1":
			await create_timer(float(opts["wait"]) - 0.3).timeout
			bs.call("_open_day_picker")
		if opts["perk"] == "1":
			await create_timer(float(opts["wait"]) - 0.3).timeout
			bs.battle.perk_offer = Perks.pick_three(bs.battle.rng)
			bs.battle.perk_time = Defs.PERK_SECONDS
			bs.call("_offer_perks")
		if opts["section"] != "":
			await create_timer(float(opts["wait"]) - 0.3).timeout
			bs.call("_select_section", Vector2i(int(opts["section"].get_slice(",", 0)), int(opts["section"].get_slice(",", 1))))
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
