extends Control
## Pick how many players (you + bots), how clever the bots are, and how fast the game runs.

const TABLE_SCENE := "res://scenes/game_table.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

var _count_label: ShadowLabel
var _count_note: Label
var _difficulty_buttons: Dictionary = {}
var _speed_buttons: Dictionary = {}
var _speed_note: Label


func _ready() -> void:
	var column := UIKit.screen_column(self)
	column.add_theme_constant_override("separation", 22)
	column.add_child(ShadowLabel.new("NEW GAME", 7, Palette.YELLOW, Palette.PINK))

	var players := _section("PLAYERS", column)
	players.add_child(_build_player_stepper())
	_count_note = UIKit.make_label("", 20, Palette.DIM)
	players.add_child(_count_note)

	var skill := _section("BOT SKILL", column)
	skill.add_child(_build_chip_row(_difficulty_buttons, [Bot.Difficulty.EASY, Bot.Difficulty.MEDIUM],
		func(value: int) -> String: return BotFactory.difficulty_name(value),
		func(value: int) -> void: SessionConfig.difficulty = value))

	var speed := _section("GAME SPEED", column)
	speed.add_child(_build_chip_row(_speed_buttons,
		[SessionConfig.Speed.SLOW, SessionConfig.Speed.NORMAL, SessionConfig.Speed.FAST],
		func(value: int) -> String: return SessionConfig.speed_name(value),
		func(value: int) -> void: SessionConfig.speed = value))
	_speed_note = UIKit.make_label("", 20, Palette.DIM)
	speed.add_child(_speed_note)

	column.add_child(UIKit.spacer())
	var start := ArcadeButton.make("START", ArcadeButton.Kind.PRIMARY, 4)
	start.pressed.connect(func() -> void: get_tree().change_scene_to_file(TABLE_SCENE))
	column.add_child(start)
	var back := ArcadeButton.make("BACK")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	column.add_child(back)

	add_child(CrtOverlay.new())
	_refresh()


## A titled panel; returns the box to put the section's controls in.
func _section(title: String, parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Arcade.panel(Palette.PANEL, Palette.LINE, true, true))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(UIKit.pixel_label(title, 2, Palette.CYAN))
	return box


func _build_player_stepper() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var minus := ArcadeButton.make("<", ArcadeButton.Kind.SECONDARY, 5)
	minus.custom_minimum_size.x = 120
	minus.pressed.connect(func() -> void: _change_players(-1))
	_count_label = ShadowLabel.new("4", 9, Palette.CYAN, Palette.BG_DEEP)
	var middle := CenterContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(_count_label)
	var plus := ArcadeButton.make(">", ArcadeButton.Kind.SECONDARY, 5)
	plus.custom_minimum_size.x = 120
	plus.pressed.connect(func() -> void: _change_players(1))
	row.add_child(minus)
	row.add_child(middle)
	row.add_child(plus)
	return row


## A row of chips where exactly one is selected. `store` collects value -> button.
func _build_chip_row(store: Dictionary, values: Array, label_for: Callable, on_pick: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for value: int in values:
		var chip := ArcadeButton.make(label_for.call(value).to_upper(), ArcadeButton.Kind.SECONDARY, 2)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.pressed.connect(func() -> void:
			on_pick.call(value)
			_refresh()
		)
		store[value] = chip
		row.add_child(chip)
	return row


func _change_players(delta: int) -> void:
	SessionConfig.player_count = clampi(
		SessionConfig.player_count + delta, SessionConfig.MIN_PLAYERS, SessionConfig.MAX_PLAYERS
	)
	_refresh()


func _refresh() -> void:
	_count_label.set_text(str(SessionConfig.player_count))
	_count_note.text = "You + %d bots" % (SessionConfig.player_count - 1)
	_speed_note.text = "Bots pause %.1fs per move. You get %d seconds per turn." % [
		SessionConfig.think_seconds(), int(SessionConfig.turn_seconds())
	]
	for value: int in _difficulty_buttons:
		(_difficulty_buttons[value] as ArcadeButton).set_selected(value == SessionConfig.difficulty)
	for value: int in _speed_buttons:
		(_speed_buttons[value] as ArcadeButton).set_selected(value == SessionConfig.speed)
