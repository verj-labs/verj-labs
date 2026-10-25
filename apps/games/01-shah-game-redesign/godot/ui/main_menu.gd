extends Control
## Title screen: an arcade attract mode with a big logo, floating cards and a blinking prompt.
## If the player stepped away from an online game it also offers REJOIN GAME.

const SETUP_SCENE := "res://scenes/setup_screen.tscn"
const ONLINE_SCENE := "res://scenes/online_screen.tscn"
const LOBBY_SCENE := "res://scenes/lobby_screen.tscn"
const TABLE_SCENE := "res://scenes/game_table.tscn"
const REJOIN_TIMEOUT := 8.0
const RULES_TEXT := "Be first to empty your hand.

- Play a set of equal cards: single, double, triple or quad.
- Beat the pile with the same size and the same or a higher rank, or pass.
- Playing the same rank as the pile skips the next player.
- A 2 is a reset: it clears the pile and you play again.
- After each game the best and worst players swap cards."
const SHOWCASE := ["AS", "2D", "KH"]

var _rejoin_button: ArcadeButton
var _rejoin_token: int = 0


func _ready() -> void:
	var column := UIKit.screen_column(self)

	column.add_child(UIKit.spacer(0.3))
	column.add_child(ShadowLabel.new("SHAH", 10, Palette.PINK, Palette.LINE))
	column.add_child(ShadowLabel.new("EXCHANGE", 8, Palette.YELLOW, Palette.PINK))
	column.add_child(UIKit.pixel_label("THE CARD GAME THAT ENDS\nFRIENDSHIPS", 3, Palette.CYAN))

	var showcase := _build_card_showcase()
	showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(showcase)

	if Online.can_rejoin():
		_rejoin_button = ArcadeButton.make("REJOIN GAME", ArcadeButton.Kind.SUCCESS, 4)
		_rejoin_button.pressed.connect(_rejoin)
		column.add_child(_rejoin_button)
	else:
		var prompt := UIKit.pixel_label("PRESS START", 3, Palette.LIME)
		column.add_child(prompt)
		_blink(prompt)

	var start := ArcadeButton.make("START GAME", ArcadeButton.Kind.PRIMARY, 4)
	start.pressed.connect(func() -> void: get_tree().change_scene_to_file(SETUP_SCENE))
	column.add_child(start)
	var online := ArcadeButton.make("PLAY ONLINE", ArcadeButton.Kind.SECONDARY, 4)
	online.pressed.connect(func() -> void: get_tree().change_scene_to_file(ONLINE_SCENE))
	column.add_child(online)
	var how_to := ArcadeButton.make("HOW TO PLAY", ArcadeButton.Kind.SECONDARY, 3)
	how_to.pressed.connect(_show_rules)
	column.add_child(how_to)
	if not OS.has_feature("mobile"):
		var quit := ArcadeButton.make("QUIT")
		quit.pressed.connect(func() -> void: get_tree().quit())
		column.add_child(quit)
	column.add_child(UIKit.pixel_label("V0.2  ARCADE EDITION", 2, Palette.DIM))

	add_child(_build_audio_corner())
	add_child(CrtOverlay.new())


## The music and sound buttons float in the top corner, under the notch, so they cost no height.
func _build_audio_corner() -> Control:
	var margin := SafeMargin.new(UIKit.SCREEN_PADDING)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	row.add_child(AudioToggle.make(AudioToggle.Kind.MUSIC, 60.0))
	row.add_child(AudioToggle.make(AudioToggle.Kind.SFX, 60.0))
	margin.add_child(row)
	return margin


## Three cards fanned out, bobbing gently. They scale down on a short screen.
func _build_card_showcase() -> Control:
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 120)
	stage.clip_contents = false
	var size := Vector2(104, 148)
	var views: Array[Control] = []  # holders: they place and scale the cards, the cards bob inside
	var tilt := [-0.22, 0.0, 0.22]
	var lift := [14.0, 0.0, 14.0]
	for i in SHOWCASE.size():
		var holder := Control.new()
		holder.pivot_offset = size / 2.0
		holder.rotation = tilt[i]
		var view := CardView.new(Card.from_code(SHOWCASE[i]), size)
		view.tappable = false
		holder.add_child(view)
		views.append(holder)
		stage.add_child(holder)
		var bob := create_tween().set_loops()
		var seconds := 0.9 + i * 0.15
		bob.tween_property(view, "position:y", -10.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(view, "position:y", 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	stage.resized.connect(func() -> void:
		var fit := clampf(stage.size.y / (size.y + 28.0), 0.55, 1.0)
		for i in views.size():
			views[i].scale = Vector2.ONE * fit
			views[i].position = Vector2(
				stage.size.x / 2.0 - size.x / 2.0 + (i - 1) * 124.0 * fit,
				(stage.size.y - size.y) / 2.0 + lift[i] * fit
			)
	)
	return stage


func _blink(node: CanvasItem) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(node, "modulate:a", 0.15, 0.55)
	tween.tween_property(node, "modulate:a", 1.0, 0.55)


func _show_rules() -> void:
	var modal := ArcadeModal.new("HOW TO PLAY", RULES_TEXT, Palette.CYAN, "GOT IT")
	add_child(modal)
	move_child(modal, get_child_count() - 2)  # keep the CRT overlay on top


# --- rejoining an online game -------------------------------------------------------------

func _rejoin() -> void:
	_rejoin_button.disabled = true
	_rejoin_button.text = "REJOINING..."
	_rejoin_token += 1
	var token := _rejoin_token
	Online.room_changed.connect(_on_rejoined, CONNECT_ONE_SHOT)
	Online.rejoin()
	await get_tree().create_timer(REJOIN_TIMEOUT).timeout
	if not is_inside_tree() or token != _rejoin_token:
		return
	_rejoin_failed()


func _on_rejoined(room: Dictionary) -> void:
	_rejoin_token += 1  # cancels the timeout
	if room.get("phase") == "lobby":
		get_tree().change_scene_to_file(LOBBY_SCENE)
		return
	SessionConfig.online_source = RemoteTableSource.new(Online)
	get_tree().change_scene_to_file(TABLE_SCENE)


func _rejoin_failed() -> void:
	if Online.room_changed.is_connected(_on_rejoined):
		Online.room_changed.disconnect(_on_rejoined)
	Online.forget_rejoin()
	Online.disconnect_now()
	_rejoin_button.text = "GAME ENDED"
	var modal := ArcadeModal.new("CAN'T REJOIN", "That game has ended or the room closed. You can start or join a new one.", Palette.ORANGE, "OK")
	add_child(modal)
	move_child(modal, get_child_count() - 2)
