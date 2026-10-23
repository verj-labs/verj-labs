class_name ArcadeButton
extends Button
## A chunky arcade button with pixel text, a hard shadow, and a click sound.

enum Kind { PRIMARY, SECONDARY, DANGER }

const KIND_COLORS := {
	Kind.PRIMARY: [Palette.YELLOW, Palette.ORANGE, Palette.INK],
	Kind.SECONDARY: [Palette.PANEL_LIGHT, Palette.CYAN, Palette.CREAM],
	Kind.DANGER: [Palette.RED, Palette.PINK, Palette.CREAM],
}

var _kind: Kind = Kind.SECONDARY
var _pixel_scale: int = 3


static func make(label: String, kind: Kind = Kind.SECONDARY, pixel_scale: int = 3) -> ArcadeButton:
	var button := ArcadeButton.new()
	button.text = label
	button.set_kind(kind, pixel_scale)
	return button


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(func() -> void: AudioDirector.play_sfx("click"))


func set_kind(kind: Kind, pixel_scale: int = 3) -> void:
	_kind = kind
	_pixel_scale = pixel_scale
	var colors: Array = KIND_COLORS[kind]
	var fill: Color = colors[0]
	var border: Color = colors[1]
	var ink: Color = colors[2]
	add_theme_stylebox_override("normal", Arcade.panel(fill, border, true, true))
	add_theme_stylebox_override("hover", Arcade.panel(fill.lightened(0.18), border, true, true))
	add_theme_stylebox_override("pressed", Arcade.panel(fill.darkened(0.2), border, true, false))
	add_theme_stylebox_override("disabled", Arcade.panel(Palette.PANEL, Palette.LINE.darkened(0.3), false, false))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	PixelFont.apply(self, pixel_scale, ink)
	for color_name in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(color_name, ink)
	add_theme_color_override("font_disabled_color", Palette.DIM.darkened(0.3))
	custom_minimum_size = Vector2(custom_minimum_size.x, 20 + PixelFont.size_for(pixel_scale) + 20)


## Restyles in place (used for selected/unselected chips).
func set_selected(selected: bool) -> void:
	set_kind(Kind.PRIMARY if selected else Kind.SECONDARY, _pixel_scale)
