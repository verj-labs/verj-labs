extends SceneTree
## Developer tool: opens a scene in a phone-shaped window and saves a screenshot, so layouts can
## be checked without a device. Run it with a real window (not --headless):
##
##   godot --path godot --resolution 540x1170 -s ../tools/screenshot.gd -- \
##       res://scenes/game_table.tscn /tmp/table.png players=8 wait=5 --fake-notch
##
## Options after the output path: players=N (3-8), wait=SECONDS before the shot (default 1).

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
	root.add_child((load(scene_path) as PackedScene).instantiate())
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out_path)
	print("saved %s (%dx%d)" % [out_path, image.get_width(), image.get_height()])
	quit()
