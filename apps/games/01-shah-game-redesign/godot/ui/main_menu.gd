extends Control
## Entry screen. Everything is built in code so the layout is easy to review in a diff.

const GAME_TABLE_SCENE := "res://scenes/game_table.tscn"

var _rules_dialog: AcceptDialog


func _ready() -> void:
	var column := UIKit.screen_column(self)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = 1.2
	column.add_child(top_spacer)

	column.add_child(UIKit.make_label("SHAH\nEXCHANGE", 84, Palette.ELECTRIC_YELLOW))
	column.add_child(UIKit.make_label("The card game that ends friendships.", 24, Palette.TEXT_MUTED))

	var mid_spacer := Control.new()
	mid_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(mid_spacer)

	var play := UIKit.primary_button("PLAY VS BOTS")
	play.pressed.connect(_on_play_pressed)
	column.add_child(play)

	var how_to := UIKit.secondary_button("HOW TO PLAY")
	how_to.pressed.connect(_on_how_to_pressed)
	column.add_child(how_to)

	var quit := UIKit.secondary_button("QUIT")
	quit.pressed.connect(func() -> void: get_tree().quit())
	# Mobile apps don't have a quit button; keep it for desktop builds only.
	quit.visible = not OS.has_feature("mobile")
	column.add_child(quit)

	var version := UIKit.make_label("v0.0.1 - redesign", 16, Palette.TEXT_MUTED)
	column.add_child(version)

	_rules_dialog = AcceptDialog.new()
	_rules_dialog.title = "How to play"
	_rules_dialog.dialog_text = "Be the first to empty your hand.\n\nSingles, doubles, triples and quads. Beat the pile or pass. A 2 resets the pile.\n\n(Full rules coming with the game engine.)"
	_rules_dialog.dialog_autowrap = true
	_rules_dialog.min_size = Vector2i(560, 0)
	add_child(_rules_dialog)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_TABLE_SCENE)


func _on_how_to_pressed() -> void:
	_rules_dialog.popup_centered()
