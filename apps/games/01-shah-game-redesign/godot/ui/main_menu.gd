extends Control
## Title screen: an arcade attract mode with a big logo, floating cards and a blinking prompt.

const SETUP_SCENE := "res://scenes/setup_screen.tscn"
const ONLINE_SCENE := "res://scenes/online_screen.tscn"
const RULES_TEXT := "Be first to empty your hand.

- Play a set of equal cards: single, double, triple or quad.
- Beat the pile with the same size and the same or a higher rank, or pass.
- Playing the same rank as the pile skips the next player.
- A 2 is a reset: it clears the pile and you play again.
- After each game the best and worst players swap cards."
const SHOWCASE := ["AS", "2D", "KH"]


func _ready() -> void:
	var column := UIKit.screen_column(self)

	column.add_child(_build_audio_row())
	column.add_child(UIKit.spacer(0.5))

	column.add_child(ShadowLabel.new("SHAH", 13, Palette.PINK, Palette.LINE))
	column.add_child(ShadowLabel.new("EXCHANGE", 9, Palette.YELLOW, Palette.PINK))
	column.add_child(UIKit.pixel_label("THE CARD GAME THAT ENDS\nFRIENDSHIPS", 3, Palette.CYAN))

	column.add_child(UIKit.spacer(0.4))
	column.add_child(_build_card_showcase())
	column.add_child(UIKit.spacer(0.6))

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

	add_child(CrtOverlay.new())


func _build_audio_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 14)
	row.add_child(AudioToggle.make(AudioToggle.Kind.MUSIC))
	row.add_child(AudioToggle.make(AudioToggle.Kind.SFX))
	return row


## Three cards fanned out, bobbing gently.
func _build_card_showcase() -> Control:
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 190)
	var size := Vector2(104, 148)
	var views: Array[CardView] = []
	var tilt := [-0.22, 0.0, 0.22]
	var lift := [14.0, 0.0, 14.0]
	for i in SHOWCASE.size():
		var view := CardView.new(Card.from_code(SHOWCASE[i]), size)
		view.tappable = false
		view.pivot_offset = size / 2.0
		view.rotation = tilt[i]
		view.position.y = lift[i] + 6.0
		views.append(view)
		stage.add_child(view)
		var bob := create_tween().set_loops()
		var rest := view.position.y
		bob.tween_property(view, "position:y", rest - 10.0, 0.9 + i * 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(view, "position:y", rest, 0.9 + i * 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	stage.resized.connect(func() -> void:
		for i in views.size():
			views[i].position.x = stage.size.x / 2.0 - size.x / 2.0 + (i - 1) * 124.0
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
