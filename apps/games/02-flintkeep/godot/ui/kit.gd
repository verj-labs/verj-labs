class_name Kit
extends RefCounted
## Builds labels, panels and buttons the same way everywhere. The layout is 540 units wide;
## pixel text is used at scale 2 (14 px) for small print and 3+ for anything important.

enum Btn { PRIMARY, SECONDARY, BUY, DANGER, GHOST }

const BTN_COLORS := {
	Btn.PRIMARY: [Pal.GOLD, Color("#ffe9a8"), Pal.INK],
	Btn.SECONDARY: [Pal.PANEL_LIGHT, Pal.LINE, Pal.PARCHMENT],
	Btn.BUY: [Color("#2c6b3a"), Pal.CASH, Pal.PARCHMENT],
	Btn.DANGER: [Color("#6b2230"), Pal.RED, Pal.PARCHMENT],
	Btn.GHOST: [Color(0, 0, 0, 0), Pal.LINE, Pal.DIM],
}


## A flat panel with a 3 px border and a hard drop shadow: chunky and pixel-like.
static func panel(fill: Color, border: Color, shadow: bool = true, border_px: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_px)
	box.set_corner_radius_all(0)
	box.anti_aliasing = false
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	if shadow:  # a thicker bottom edge reads as a raised, pressable block
		box.border_width_bottom = border_px + 3
	return box


static func label(text: String, scale: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	PixelFont.apply(l, scale, color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func button(text: String, kind: Btn = Btn.SECONDARY, scale: int = 3, min_height: float = 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	style_button(b, kind, scale)
	b.custom_minimum_size.y = min_height
	return b


static func style_button(b: Button, kind: Btn, scale: int = 3) -> void:
	var colors: Array = BTN_COLORS[kind]
	var fill: Color = colors[0]
	var border: Color = colors[1]
	var ink: Color = colors[2]
	b.add_theme_stylebox_override("normal", panel(fill, border))
	b.add_theme_stylebox_override("hover", panel(fill.lightened(0.12), border))
	b.add_theme_stylebox_override("pressed", panel(fill.darkened(0.25), border, false))
	b.add_theme_stylebox_override("disabled", panel(Pal.PANEL, Pal.LINE.darkened(0.35), false))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	PixelFont.apply(b, scale, ink)
	for state in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, ink)
	b.add_theme_color_override("font_disabled_color", Pal.MUTED)


static func hbox(separation: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func vbox(separation: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func spacer(horizontal: bool = false) -> Control:
	var c := Control.new()
	if horizontal:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func panel_container(fill: Color = Pal.PANEL, border: Color = Pal.LINE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel(fill, border))
	return p


static func color_rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A small icon (coin, cash ...) drawn at a whole-number scale.
static func icon(texture: Texture2D, scale: int = 3) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = texture.get_size() * scale
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
