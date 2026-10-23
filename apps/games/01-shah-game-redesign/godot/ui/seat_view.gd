class_name SeatView
extends PanelContainer
## One player's badge: colour-coded, with their name, cards left and a short status. It blinks
## when it is their turn so the turn is hard to miss.

const BLINK_SECONDS := 0.3

var _accent: Color = Palette.CYAN
var _name_label: Label
var _count_label: Label
var _status_label: Label
var _blink: Tween
var _fill: Color = Palette.PANEL
var _border: Color = Palette.LINE


func _init() -> void:
	custom_minimum_size = Vector2(128, 104)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	_name_label = UIKit.pixel_label("", 2, Palette.CREAM)
	_count_label = UIKit.pixel_label("", 4, Palette.YELLOW)
	_status_label = UIKit.make_label("", 15, Palette.DIM, false)
	column.add_child(_name_label)
	column.add_child(_count_label)
	column.add_child(_status_label)


func set_seat(seat: int, display_name: String) -> void:
	_accent = Palette.seat_color(seat)
	_name_label.text = display_name
	_name_label.add_theme_color_override("font_color", _accent)


## `mode` is "turn", "last_chance", "skipped", "out" or "idle".
func refresh(cards_left: int, status: String, mode: String) -> void:
	_count_label.text = "-" if mode == "out" else str(cards_left)
	_status_label.text = status
	_fill = Palette.PANEL
	_border = _accent.darkened(0.35)
	var status_color := Palette.DIM
	match mode:
		"turn":
			_border = _accent
			status_color = Palette.LIME
		"last_chance":
			_border = Palette.ORANGE
			status_color = Palette.ORANGE
		"skipped":
			_border = Palette.PINK
			status_color = Palette.PINK
		"out":
			_fill = Palette.BG_DEEP
			_border = Palette.LINE
	_status_label.add_theme_color_override("font_color", status_color)
	modulate = Color(1, 1, 1, 0.55) if mode == "out" else Color.WHITE
	_apply_style(_border)
	_set_blinking(mode == "turn" or mode == "last_chance")


func _apply_style(border: Color) -> void:
	add_theme_stylebox_override("panel", Arcade.compact_panel(_fill, border, false))


func _set_blinking(on: bool) -> void:
	if _blink != null:
		_blink.kill()
		_blink = null
	if not on:
		return
	_blink = create_tween().set_loops()
	_blink.tween_callback(func() -> void: _apply_style(Palette.CREAM)).set_delay(BLINK_SECONDS)
	_blink.tween_callback(func() -> void: _apply_style(_border)).set_delay(BLINK_SECONDS)
