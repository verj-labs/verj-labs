extends Control
## Entry to online play: pick a name, then create a room or join one with a 4-letter code.

const LOBBY_SCENE := "res://scenes/lobby_screen.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

var _name_input: ArcadeInput
var _code_input: ArcadeInput
var _status: Label
var _pending: Callable = Callable()


func _ready() -> void:
	var column := UIKit.screen_column(self, 1.0, true)
	column.add_theme_constant_override("separation", 14)
	column.add_child(ShadowLabel.new("PLAY ONLINE", 6, Palette.CYAN, Palette.PINK))

	var who := _section("YOUR NAME", column)
	_name_input = ArcadeInput.make("TYPE A NAME", Protocol.MAX_NAME, true, true)
	_name_input.text = Online.player_name
	who.add_child(_name_input)

	var create := ArcadeButton.make("CREATE ROOM", ArcadeButton.Kind.PRIMARY, 3)
	create.pressed.connect(func() -> void: _go(func() -> void: Online.create_room()))
	column.add_child(create)

	var join := _section("JOIN WITH A CODE", column)
	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 14)
	_code_input = ArcadeInput.make("ABCD", Protocol.CODE_LENGTH, true, true)
	_code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_row.add_child(_code_input)
	var join_button := ArcadeButton.make("JOIN", ArcadeButton.Kind.SECONDARY, 3)
	join_button.custom_minimum_size.x = 170
	join_button.pressed.connect(func() -> void: _go(func() -> void: Online.join_room(_code_input.text)))
	join_row.add_child(join_button)
	join.add_child(join_row)

	_status = UIKit.make_label("", 22, Palette.DIM)
	_status.custom_minimum_size = Vector2(0, 52)
	column.add_child(_status)

	var back := ArcadeButton.make("BACK")
	back.pressed.connect(func() -> void:
		Online.disconnect_now()
		get_tree().change_scene_to_file(MENU_SCENE)
	)
	(column.get_meta("footer") as Control).add_child(back)
	add_child(CrtOverlay.new())

	Online.welcomed.connect(_on_welcomed)
	Online.room_changed.connect(_on_room_changed)
	Online.server_error.connect(_on_error)
	Online.status_changed.connect(_on_status)
	if Online.in_room():
		get_tree().call_deferred("change_scene_to_file", LOBBY_SCENE)
	elif Online.has_meta("notice"):
		_show(str(Online.get_meta("notice")), Palette.ORANGE)
		Online.remove_meta("notice")


func _exit_tree() -> void:
	for pair in [[Online.welcomed, _on_welcomed], [Online.room_changed, _on_room_changed],
			[Online.server_error, _on_error], [Online.status_changed, _on_status]]:
		if pair[0].is_connected(pair[1]):
			pair[0].disconnect(pair[1])


func _section(title: String, parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Arcade.panel(Palette.PANEL, Palette.LINE, true, true))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UIKit.pixel_label(title, 3, Palette.CYAN))
	return box


## Checks the inputs, connects if needed, then runs `action` once signed in.
func _go(action: Callable) -> void:
	var clean := Protocol.clean_name(_name_input.text)
	if clean.is_empty():
		_show("Name: 1-12 letters, numbers or spaces.", Palette.RED)
		return
	_pending = action
	if Online.is_online() and Online.player_name == clean:
		_run_pending()
	else:
		if Online.state != OnlineClient.State.OFFLINE:
			Online.disconnect_now()
		Online.connect_to_server(Online.url, clean)


func _on_welcomed(_name: String) -> void:
	_run_pending()


func _run_pending() -> void:
	if _pending.is_valid():
		var action := _pending
		_pending = Callable()
		action.call()


func _on_room_changed(_room: Dictionary) -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)


func _on_error(code: String, _message: String) -> void:
	_pending = Callable()
	_show(OnlineText.explain(code), Palette.RED)


func _on_status(text: String) -> void:
	if text in ["CONNECTING...", "SIGNING IN...", "RECONNECTING..."]:
		_show(text, Palette.CYAN)


func _show(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)
