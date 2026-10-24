class_name AudioToggle
extends Button
## A square icon button that switches either the music or the sound effects on and off.
## Lit up when on; dimmed with a red cross when off.

enum Kind { MUSIC, SFX }

var _kind: Kind
var _icon: PixelIcon
var _cross: PixelIcon


static func make(kind: Kind, button_size: float = 72.0) -> AudioToggle:
	var toggle := AudioToggle.new()
	toggle._kind = kind
	toggle.custom_minimum_size = Vector2.ONE * button_size
	return toggle


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)


func _ready() -> void:
	var unit := maxi(2, int(custom_minimum_size.x / 8 * 0.55))
	_icon = PixelIcon.new("music" if _kind == Kind.MUSIC else "speaker", unit)
	_cross = PixelIcon.new("cross", unit, Palette.RED)
	for icon in [_icon, _cross]:
		add_child(icon)
	resized.connect(_center_icons)
	_center_icons()
	if _kind == Kind.MUSIC:
		AudioDirector.music_enabled_changed.connect(_refresh)
	else:
		AudioDirector.sfx_enabled_changed.connect(_refresh)
	_refresh(_is_on())


func _center_icons() -> void:
	for icon in [_icon, _cross]:
		icon.position = (size - icon.custom_minimum_size) / 2.0


func _exit_tree() -> void:
	var changed := AudioDirector.music_enabled_changed if _kind == Kind.MUSIC else AudioDirector.sfx_enabled_changed
	if changed.is_connected(_refresh):
		changed.disconnect(_refresh)


func _is_on() -> bool:
	return AudioDirector.music_enabled if _kind == Kind.MUSIC else AudioDirector.sfx_enabled


func _on_pressed() -> void:
	if _kind == Kind.MUSIC:
		AudioDirector.set_music_enabled(not AudioDirector.music_enabled)
	else:
		AudioDirector.set_sfx_enabled(not AudioDirector.sfx_enabled)
	AudioDirector.play_sfx("click")


func _refresh(enabled: bool) -> void:
	var accent := Palette.CYAN if _kind == Kind.MUSIC else Palette.LIME
	var fill := Palette.PANEL_LIGHT if enabled else Palette.PANEL
	var border := accent if enabled else Palette.LINE
	add_theme_stylebox_override("normal", Arcade.compact_panel(fill, border, true))
	add_theme_stylebox_override("hover", Arcade.compact_panel(fill.lightened(0.12), border, true))
	add_theme_stylebox_override("pressed", Arcade.compact_panel(fill.darkened(0.2), border, false))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_icon.color = accent if enabled else Palette.DIM.darkened(0.35)
	_cross.visible = not enabled
	tooltip_text = ("Music " if _kind == Kind.MUSIC else "Sound effects ") + ("on" if enabled else "off")
