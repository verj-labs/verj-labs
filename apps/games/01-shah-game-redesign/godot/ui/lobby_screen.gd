extends Control
## The room before the game: the code to share, who is seated, options, and the host's controls.

const TABLE_SCENE := "res://scenes/game_table.tscn"
const ONLINE_SCENE := "res://scenes/online_screen.tscn"
const KIND_TAGS := {"human": "PLAYER", "bot": "BOT", "empty": "OPEN"}

var _code_label: ShadowLabel
var _rows: VBoxContainer
var _difficulty_buttons: Dictionary = {}
var _speed_buttons: Dictionary = {}
var _add_bot: ArcadeButton
var _start: ArcadeButton
var _note: Label
var _banner: Label


func _ready() -> void:
	var column := UIKit.screen_column(self)
	column.add_theme_constant_override("separation", 14)
	column.add_child(UIKit.pixel_label("ROOM CODE", 2, Palette.CYAN))
	_code_label = ShadowLabel.new("----", 11, Palette.YELLOW, Palette.PINK)
	column.add_child(_code_label)
	column.add_child(UIKit.make_label("Friends join with this code", 20, Palette.DIM))

	var seats_panel := PanelContainer.new()
	seats_panel.add_theme_stylebox_override("panel", Arcade.panel(Palette.PANEL, Palette.LINE, true, true))
	column.add_child(seats_panel)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	seats_panel.add_child(_rows)

	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 10)
	for difficulty in ["easy", "medium"]:
		options.add_child(_option_chip(_difficulty_buttons, difficulty, func() -> void: _send_options(difficulty, Online.room["options"]["speed"])))
	for speed in ["slow", "normal", "fast"]:
		options.add_child(_option_chip(_speed_buttons, speed, func() -> void: _send_options(Online.room["options"]["difficulty"], speed)))
	column.add_child(options)

	_note = UIKit.make_label("", 20, Palette.DIM)
	column.add_child(_note)
	column.add_child(UIKit.spacer())

	_add_bot = ArcadeButton.make("ADD BOT", ArcadeButton.Kind.SECONDARY, 3)
	_add_bot.pressed.connect(func() -> void: Online.add_bot())
	column.add_child(_add_bot)
	_start = ArcadeButton.make("START GAME", ArcadeButton.Kind.PRIMARY, 4)
	_start.pressed.connect(func() -> void: Online.start_game())
	column.add_child(_start)
	var leave := ArcadeButton.make("LEAVE ROOM")
	leave.pressed.connect(func() -> void: Online.leave_room())
	column.add_child(leave)

	_banner = UIKit.pixel_label("RECONNECTING...", 2, Palette.ORANGE)
	_banner.visible = false
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position = Vector2(180, 8)
	add_child(_banner)
	add_child(CrtOverlay.new())

	Online.room_changed.connect(_refresh)
	Online.game_began.connect(_open_table)
	Online.left_room.connect(_on_left)
	Online.server_error.connect(_on_error)
	Online.connection_changed.connect(func(connected: bool) -> void: _banner.visible = not connected)
	if Online.in_room():
		_refresh(Online.room)
	if not Online._pending_game.is_empty():
		_open_table()


func _exit_tree() -> void:
	for pair in [[Online.room_changed, _refresh], [Online.game_began, _open_table],
			[Online.left_room, _on_left], [Online.server_error, _on_error]]:
		if pair[0].is_connected(pair[1]):
			pair[0].disconnect(pair[1])


func _option_chip(store: Dictionary, value: String, on_press: Callable) -> ArcadeButton:
	var chip := ArcadeButton.make(value.to_upper(), ArcadeButton.Kind.SECONDARY, 2)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.pressed.connect(on_press)
	store[value] = chip
	return chip


func _send_options(difficulty: String, speed: String) -> void:
	Online.set_options(difficulty, speed)


func _refresh(room: Dictionary) -> void:
	_code_label.set_text(room["code"])
	var host: bool = room["host_seat"] == room["you_seat"]
	var filled := 0
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	for seat: Dictionary in room["seats"]:
		if seat["kind"] != "empty":
			filled += 1
		_rows.add_child(_seat_row(seat, room, host))
	for value: String in _difficulty_buttons:
		_style_chip(_difficulty_buttons[value], value == room["options"]["difficulty"], host)
	for value: String in _speed_buttons:
		_style_chip(_speed_buttons[value], value == room["options"]["speed"], host)
	_note.add_theme_color_override("font_color", Palette.DIM)
	_add_bot.disabled = not host or filled >= Room.MAX_SEATS
	_start.disabled = not host or filled < Room.MIN_PLAYERS
	if host:
		_note.text = "Need %d or more players to start." % Room.MIN_PLAYERS if filled < Room.MIN_PLAYERS else "Ready when you are!"
	else:
		_note.text = "Waiting for the host to start..."


func _style_chip(chip: ArcadeButton, selected: bool, host: bool) -> void:
	chip.set_selected(selected)
	chip.disabled = not host


func _seat_row(seat: Dictionary, room: Dictionary, host: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 44)
	var chip := ColorRect.new()
	chip.color = Palette.seat_color(seat["seat"]) if seat["kind"] != "empty" else Palette.LINE.darkened(0.3)
	chip.custom_minimum_size = Vector2(20, 20)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chip)
	var label_text: String = seat["name"] if seat["kind"] != "empty" else "---"
	var name_label := UIKit.pixel_label(label_text, 3, Palette.CREAM if seat["kind"] != "empty" else Palette.DIM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var tag: String = KIND_TAGS[seat["kind"]]
	if seat["seat"] == room["host_seat"]:
		tag = "HOST"
	if seat["seat"] == room["you_seat"]:
		tag += " (YOU)"
	var tag_color := Palette.LIME if seat["kind"] == "human" and seat["connected"] else Palette.DIM
	if seat["kind"] == "human" and not seat["connected"]:
		tag = "AWAY"
		tag_color = Palette.ORANGE
	row.add_child(UIKit.pixel_label(tag, 2, tag_color))
	if host and seat["kind"] != "empty" and seat["seat"] != room["you_seat"]:
		var kick := ArcadeButton.make("X", ArcadeButton.Kind.DANGER, 2)
		kick.custom_minimum_size = Vector2(56, 44)
		kick.pressed.connect(func() -> void: Online.remove_seat(seat["seat"]))
		row.add_child(kick)
	return row


func _open_table() -> void:
	SessionConfig.online_source = RemoteTableSource.new(Online)
	get_tree().change_scene_to_file(TABLE_SCENE)


func _on_left(reason: String) -> void:
	var message := OnlineText.why_left(reason)
	if message != "":
		Online.set_meta("notice", message)
	get_tree().change_scene_to_file(ONLINE_SCENE)


func _on_error(code: String, _message: String) -> void:
	_note.text = OnlineText.explain(code)
	_note.add_theme_color_override("font_color", Palette.RED)
