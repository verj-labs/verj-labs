extends SceneTree
## Developer tool: opens a scene in a phone-shaped window and saves a screenshot, so layouts can
## be checked without a device. Run it with a real window (not --headless):
##
##   godot --path godot --resolution 540x1170 -s ../tools/screenshot.gd -- \
##       res://scenes/game_table.tscn /tmp/table.png players=8 wait=5 --fake-notch
##
## Options after the output path: players=N (3-8), wait=SECONDS before the shot (default 1),
## room=1 (pretend you are in a 5-seat online lobby, for lobby_screen.tscn).

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0]
	var out_path := args[1]
	var wait := 1.0
	for arg in args.slice(2):
		if arg.begins_with("players="):
			SessionConfig.player_count = int(arg.get_slice("=", 1))
		elif arg.begins_with("wait="):
			wait = float(arg.get_slice("=", 1))
		elif arg == "room=1":
			_fake_room()
	root.add_child((load(scene_path) as PackedScene).instantiate())
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out_path)
	print("saved %s (%dx%d)" % [out_path, image.get_width(), image.get_height()])
	quit()


func _fake_room() -> void:
	var names := ["WAQAS", "SARA", "OMAR", "ACE", "NOVA", "", "", ""]
	var seats: Array = []
	for index in names.size():
		var kind := "empty" if names[index] == "" else ("bot" if index >= 3 else "human")
		seats.append({"seat": index, "kind": kind, "name": names[index], "connected": kind == "human", "bot_playing": kind == "bot"})
	root.get_node("Online").room = {"type": "room", "code": "KQXM", "phase": "lobby", "host_seat": 0, "you_seat": 0,
		"options": {"difficulty": "medium", "speed": "normal", "games": 10}, "seats": seats}
