class_name Kit
extends RefCounted
## Builds labels, panels and buttons the same way everywhere: rounded corners, soft shadows,
## walnut and brass. The layout is 540 units wide; body text is 18-24 px.

enum Btn { PRIMARY, SECONDARY, BUY, DANGER, GHOST, TAB, TAB_ON }

## fill, border, text
const BTN_COLORS := {
	Btn.PRIMARY: [Color("#e2b04e"), Color("#ffe1a0"), Pal.INK],
	Btn.SECONDARY: [Pal.PANEL_LIGHT, Pal.BRASS_DIM, Pal.PARCHMENT],
	Btn.BUY: [Color("#3e7f37"), Color("#8fdc6a"), Color("#f4ffe9")],
	Btn.DANGER: [Color("#7a2a26"), Color("#e5534b"), Pal.PARCHMENT],
	Btn.GHOST: [Color(1, 1, 1, 0.04), Pal.LINE, Pal.DIM],
	Btn.TAB: [Pal.PANEL_DEEP, Pal.LINE, Pal.DIM],
	Btn.TAB_ON: [Pal.PANEL_LIGHT, Pal.BRASS, Pal.GOLD],
}
const RADIUS := 12


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = Fonts.body()
	t.default_font_size = 20
	t.set_color("font_color", "Label", Pal.PARCHMENT)
	return t


## A rounded panel with a thin border and a soft drop shadow.
static func panel(fill: Color, border: Color, radius: int = RADIUS, border_px: int = 2, shadow: bool = true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_px)
	box.set_corner_radius_all(radius)
	box.corner_detail = 8
	box.anti_aliasing = true
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	if shadow:
		box.shadow_color = Pal.SHADOW
		box.shadow_size = 6
		box.shadow_offset = Vector2(0, 3)
	return box


static func label(text: String, size: int, color: Color = Pal.PARCHMENT, font: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font != null else Fonts.semibold())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## A Cinzel heading with a soft shadow.
static func heading(text: String, size: int, color: Color = Pal.GOLD, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, Fonts.heading(), align)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l


static func button(text: String, kind: Btn = Btn.SECONDARY, size: int = 22, min_height: float = 60.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = min_height
	style_button(b, kind, size)
	return b


static func style_button(b: Button, kind: Btn, size: int = 22) -> void:
	var colors: Array = BTN_COLORS[kind]
	var fill: Color = colors[0]
	var border: Color = colors[1]
	var ink: Color = colors[2]
	var shadow := kind not in [Btn.GHOST, Btn.TAB, Btn.TAB_ON]
	b.add_theme_stylebox_override("normal", panel(fill, border, RADIUS, 2, shadow))
	b.add_theme_stylebox_override("hover", panel(fill.lightened(0.08), border, RADIUS, 2, shadow))
	b.add_theme_stylebox_override("pressed", panel(fill.darkened(0.18), border, RADIUS, 2, false))
	b.add_theme_stylebox_override("disabled", panel(Color(fill.darkened(0.55), 0.7), Pal.LINE.darkened(0.3), RADIUS, 2, false))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", Fonts.bold())
	b.add_theme_font_size_override("font_size", size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
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
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if horizontal:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func panel_container(fill: Color = Pal.PANEL, border: Color = Pal.LINE, radius: int = RADIUS) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel(fill, border, radius))
	return p


static func color_rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A full-screen backdrop: a vertical gradient from deep night to near black.
static func backdrop() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color("#1a2130"))
	g.set_color(1, Color("#0b0d12"))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 16
	tex.height = 256
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## An art sprite as a UI icon, `size` px wide.
static func icon(name: String, size: float = 28.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.tex(name)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = Vector2(size, size)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
