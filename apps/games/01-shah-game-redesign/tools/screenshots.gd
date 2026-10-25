extends SceneTree
## Makes the App Store / Google Play screenshots from the real game screens, so they can be redone
## whenever the UI changes. For every device size it writes two folders:
##   raw/<size>/NN_name.png     the game screen at exactly the store's pixel size
##   store/<size>/NN_name.png   the same screen in a phone frame under a big pixel-font caption
##
## Needs a real window (not --headless), because it renders. The window size does not matter.
##
##   godot --path godot --resolution 540x1170 -s ../tools/screenshots.gd -- --fake-notch out=/some/folder
##
## `out=` defaults to store_assets/ next to the godot/ folder. `only=table` makes just one shot.
## `--fake-notch` draws screens as on a phone with a Dynamic Island (see SafeMargin).

## Store sizes in pixels. Apple requires the 6.9" set (or 6.5"); Google Play takes 1080 x 1920 and up.
const SIZES := {
	"iphone_6.9": Vector2i(1320, 2868),
	"iphone_6.5": Vector2i(1284, 2778),
	"android_phone": Vector2i(1080, 1920),
}
## The screens, in store order. `caption` lines must be 13 characters or fewer.
const SHOTS := [
	{"name": "01_play", "kind": "table", "caption": "BEAT THE PILE"},
	{"name": "02_friends", "kind": "lobby", "caption": "PLAY ONLINE\nWITH FRIENDS"},
	{"name": "03_menu", "kind": "menu", "caption": "THE CARD GAME\nTHAT ENDS\nFRIENDSHIPS"},
	{"name": "04_match", "kind": "match", "caption": "10 OR 20 GAME\nMATCHES"},
	{"name": "05_setup", "kind": "setup", "caption": "3 TO 8 PLAYERS"},
]
const LAYOUT_WIDTH := 540.0
const FRAME_WIDTH := 660.0
const TABLE_SEED := 7
const MAX_TABLE_SECONDS := 40.0

var _out_dir: String = ""
var _only: String = ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out_dir = arg.get_slice("=", 1)
		elif arg.begins_with("only="):
			_only = arg.get_slice("=", 1)
	if _out_dir == "":
		_out_dir = ProjectSettings.globalize_path("res://").path_join("../store_assets").simplify_path()
	await _run()
	quit()


func _run() -> void:
	for size_name: String in SIZES:
		var size: Vector2i = SIZES[size_name]
		for shot: Dictionary in SHOTS:
			if _only != "" and _only != shot["name"] and _only != shot["kind"]:
				continue
			var raw := await _capture(shot, size)
			_save(raw, "raw", size_name, shot["name"])
			var framed := await _frame(raw, shot["caption"], size)
			_save(framed, "store", size_name, shot["name"])


func _save(image: Image, folder: String, size_name: String, shot_name: String) -> void:
	var dir := _out_dir.path_join(folder).path_join(size_name)
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(shot_name + ".png")
	image.save_png(path)
	print("wrote %s (%dx%d)" % [path, image.get_width(), image.get_height()])


# --- the game screens -------------------------------------------------------------------

## A viewport of `size` pixels that lays screens out as a 540-unit-wide phone would.
func _viewport(size: Vector2i, layout_width: float = LAYOUT_WIDTH) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.size_2d_override = Vector2i(int(layout_width), roundi(layout_width * size.y / size.x))
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport


func _capture(shot: Dictionary, size: Vector2i) -> Image:
	var viewport := _viewport(size)
	var scene_path := "res://scenes/main_menu.tscn"
	match shot["kind"]:
		"table", "match":
			scene_path = "res://scenes/game_table.tscn"
			SessionConfig.player_count = 5
			SessionConfig.rng_seed = TABLE_SEED
			SessionConfig.speed = SessionConfig.Speed.FAST
		"setup":
			scene_path = "res://scenes/setup_screen.tscn"
			SessionConfig.player_count = 5
		"lobby":
			scene_path = "res://scenes/lobby_screen.tscn"
			_fake_room()
	var scene: Control = (load(scene_path) as PackedScene).instantiate()
	viewport.add_child(scene)
	await create_timer(0.8).timeout
	if shot["kind"] == "table":
		await _play_to_a_good_moment(scene)
	elif shot["kind"] == "match":
		await _play_to_a_good_moment(scene)
		_show_standings(scene)
		await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image


## Lets the bots play until it is your turn with a pile to beat, then picks a set to play.
func _play_to_a_good_moment(table: Control) -> void:
	var waited := 0.0
	while waited < MAX_TABLE_SECONDS:
		await create_timer(0.25).timeout
		waited += 0.25
		var source: TableSource = table.controller
		if source.state == null or not source.is_human_turn() or source.state.pile == null:
			continue
		var plays := source.state.legal_plays()
		if plays.is_empty():
			continue
		await create_timer(1.8).timeout  # let the SKIP / RESET banner fade
		if not source.is_human_turn():
			continue
		var best: Play = plays[0]
		for play in plays:
			if play.size > best.size:
				best = play
		for card in best.cards:
			for view: CardView in table._hand._views:
				if view.card.to_code() == card.to_code():
					table._hand._on_card_tapped(view)
		await create_timer(0.4).timeout
		return


## The match-over panel with a believable scoreboard (the seats are the table's real bots).
func _show_standings(table: Control) -> void:
	var source: TableSource = table.controller
	source.scores = [14, 21, 33, 9, 17] as Array[int]
	source.standings = [2, 1, 4, 0, 3] as Array[int]
	source.match_over = true
	source.total_games = 10
	table._hand.clear_selection()  # a lifted card would draw above the panel
	table._on_game_finished(source.standings)


## A room with five seats, as the lobby screen would show it online.
func _fake_room() -> void:
	var seats: Array = []
	var names := ["WAQAS", "SARA", "OMAR", "ACE", "NOVA"]
	var kinds := ["human", "human", "human", "bot", "bot"]
	for index in names.size():
		seats.append({"seat": index, "kind": kinds[index], "name": names[index], "connected": true, "bot_playing": kinds[index] == "bot"})
	seats.append({"seat": names.size(), "kind": "empty", "name": "", "connected": false, "bot_playing": false})
	root.get_node("Online").room = {
		"type": "room", "code": "KQXM", "phase": "lobby", "host_seat": 0, "you_seat": 0,
		"options": {"difficulty": "medium", "speed": "normal", "games": 10}, "seats": seats,
	}


# --- the framed marketing version ---------------------------------------------------------

func _frame(raw: Image, caption: String, size: Vector2i) -> Image:
	var viewport := _viewport(size, FRAME_WIDTH)
	var layout := Vector2(viewport.size_2d_override)
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(page)
	page.add_child(ArcadeBackground.new(1.0))

	var top := 70.0
	# Loaded by path: naming ShadowLabel here would make this script depend on the AudioDirector
	# autoload at compile time, which does not exist yet when a -s script is compiled.
	var shadow_label: GDScript = load("res://ui/shadow_label.gd")
	for line in caption.split("\n"):
		var label: Control = shadow_label.new(line, 7, Palette.YELLOW, Palette.PINK)
		label.position = Vector2((layout.x - label.size.x) / 2.0, top)
		page.add_child(label)
		top += label.size.y + 18.0

	var shot_top := top + 40.0
	var shot_width := minf(520.0, (layout.y - shot_top - 50.0) * raw.get_width() / raw.get_height())
	var shot_size := Vector2(shot_width, shot_width * raw.get_height() / raw.get_width())
	var frame := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.INK
	style.border_color = Palette.CYAN
	style.set_border_width_all(8)
	style.set_corner_radius_all(42)
	frame.add_theme_stylebox_override("panel", style)
	frame.position = Vector2((layout.x - shot_size.x) / 2.0 - 8.0, shot_top - 8.0)
	frame.size = shot_size + Vector2(16.0, 16.0)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	page.add_child(frame)
	var picture := TextureRect.new()
	picture.texture = ImageTexture.create_from_image(raw)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.position = Vector2(8.0, 8.0)
	picture.size = shot_size
	frame.add_child(picture)
	var island := Panel.new()
	var island_style := StyleBoxFlat.new()
	island_style.bg_color = Color.BLACK
	island_style.set_corner_radius_all(20)
	island.add_theme_stylebox_override("panel", island_style)
	island.size = Vector2(shot_size.x * 0.28, 22.0)
	island.position = Vector2((shot_size.x - island.size.x) / 2.0 + 8.0, 22.0)
	frame.add_child(island)

	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image
