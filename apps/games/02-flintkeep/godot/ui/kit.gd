class_name Kit
extends RefCounted
## Builds labels, panels and buttons the same way everywhere, in the casual cartoon style:
## dark brown outlines, chunky rounded shapes, a darker "lip" under every button and a glossy
## highlight on top. Wood panels hold cream cards. The layout is 540 units wide.

enum Btn { PRIMARY, SECONDARY, BUY, DANGER, GHOST, TAB, TAB_ON }

## fill, lip (darker bottom edge)
const BTN_COLORS := {
	Btn.PRIMARY: [Color("#ffc22e"), Color("#d47a12")],
	Btn.SECONDARY: [Color("#4aa3ff"), Color("#2466c9")],
	Btn.BUY: [Color("#5fd13f"), Color("#2f8f26")],
	Btn.DANGER: [Color("#ff5a4a"), Color("#b8261f")],
	Btn.GHOST: [Color("#d48a48"), Color("#8a4a1f")],
	Btn.TAB: [Color("#8f5226"), Color("#5e3214")],
	Btn.TAB_ON: [Color("#ffc22e"), Color("#d47a12")],
}
const RADIUS := 16
const OUTLINE := 3
const LIP := 5


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = Fonts.body()
	t.default_font_size = 20
	t.set_color("font_color", "Label", Pal.TEXT)
	return t


## A rounded box with a dark outline; `lip` thickens the bottom edge in a darker shade.
static func box(fill: Color, edge: Color = Pal.INK, radius: int = RADIUS, outline: int = OUTLINE, lip: int = 0, lip_color: Color = Pal.INK) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = edge
	b.set_border_width_all(outline)
	b.set_corner_radius_all(radius)
	b.corner_detail = 8
	b.anti_aliasing = true
	b.content_margin_left = 14
	b.content_margin_right = 14
	b.content_margin_top = 10
	b.content_margin_bottom = 10
	if lip > 0:
		b.border_width_bottom = outline + lip
		b.border_color = lip_color if lip_color != Pal.INK else edge
	return b


## The wooden frame used for big panels and cards.
static func wood(radius: int = RADIUS) -> StyleBoxFlat:
	var b := box(Pal.WOOD, Pal.INK, radius, OUTLINE, 0)
	b.shadow_color = Color(0, 0, 0, 0.25)
	b.shadow_size = 6
	b.shadow_offset = Vector2(0, 4)
	return b


## A cream card that sits inside a wood panel.
static func card(radius: int = 12) -> StyleBoxFlat:
	var b := box(Pal.CARD, Pal.CARD_EDGE, radius, 2, 3, Pal.CARD_EDGE.darkened(0.15))
	b.content_margin_left = 12
	b.content_margin_right = 8
	b.content_margin_top = 6
	b.content_margin_bottom = 8
	return b


## Text. `outline` gives it the dark cartoon edge used on wood, sky and buttons.
static func label(text: String, size: int, color: Color = Pal.TEXT, font: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT, outline: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font != null else Fonts.semibold())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Pal.INK)
		l.add_theme_constant_override("outline_size", maxi(4, size / 4))
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## A big Lilita One title with a dark outline and a drop shadow.
static func heading(text: String, size: int, color: Color = Pal.GOLD, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, Fonts.heading(), align, true)
	l.add_theme_constant_override("outline_size", maxi(6, size / 5))
	l.add_theme_color_override("font_shadow_color", Color(0.1, 0.05, 0.02, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(3, size / 12))
	l.add_theme_constant_override("shadow_outline_size", maxi(6, size / 5))
	return l


static func button(text: String, kind: Btn = Btn.SECONDARY, size: int = 24, min_height: float = 60.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size.y = min_height
	style_button(b, kind, size)
	b.pressed.connect(func() -> void: Sfx.play("click"))
	var shine := Panel.new()  # the glossy highlight across the top of the button
	shine.name = "Shine"
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.anchor_right = 1.0
	shine.anchor_bottom = 0.42
	shine.offset_left = 7
	shine.offset_top = 5
	shine.offset_right = -7
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.28)
	gloss.set_corner_radius_all(RADIUS - 6)
	gloss.corner_detail = 8
	gloss.anti_aliasing = true
	shine.add_theme_stylebox_override("panel", gloss)
	b.add_child(shine)
	return b


static func style_button(b: Button, kind: Btn, size: int = 24) -> void:
	var colors: Array = BTN_COLORS[kind]
	var fill: Color = colors[0]
	var lip: Color = colors[1]
	var normal := _button_box(fill, lip, LIP)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.08), lip, LIP))
	var pressed := _button_box(fill.darkened(0.08), lip, 2)
	pressed.content_margin_top += LIP - 2
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", _button_box(Color("#b9ab98"), Color("#857560"), LIP))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", Fonts.heading())
	b.add_theme_font_size_override("font_size", size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, Pal.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("#f2ebe0"))
	b.add_theme_color_override("font_outline_color", Pal.INK)
	b.add_theme_constant_override("outline_size", maxi(5, size / 4))


## Narrow side padding, for rows of many small buttons (the battle panel's six tabs).
static func tighten(b: Button, side: float = 4.0) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := b.get_theme_stylebox(state) as StyleBoxFlat
		if box != null:
			box.content_margin_left = side
			box.content_margin_right = side


static func _button_box(fill: Color, lip: Color, lip_px: int) -> StyleBoxFlat:
	## Ink outline around the face; a darker extrusion (the "lip") below it, drawn as a hard
	## shadow, so the button looks thick and pressable.
	var b := box(fill, Pal.INK, RADIUS, OUTLINE)
	b.content_margin_bottom = 10
	if lip_px > 0:
		b.shadow_color = lip
		b.shadow_size = 1
		b.shadow_offset = Vector2(0, lip_px)
	return b


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


static func panel_container(style: StyleBox = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style if style != null else wood())
	return p


## A rounded "pill" showing an icon and a value (coins, cash).
static func pill(icon_name: String, color: Color) -> Array:
	var p := panel_container(box(Color(0.16, 0.09, 0.05, 0.55), Pal.INK, 22, 2))
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 4
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 4
	var h := hbox(8)
	h.add_child(icon(icon_name, 30))
	var l := label("", 24, color, Fonts.heading(), HORIZONTAL_ALIGNMENT_LEFT, true)
	h.add_child(l)
	p.add_child(h)
	return [p, l]


static func color_rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A full-screen sunny sky backdrop.
static func backdrop() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Pal.SKY_TOP)
	g.set_color(1, Pal.SKY_BOTTOM)
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


## Dims the screen and shows `body` in a wood card. Returns the overlay; free it to close.
static func modal(parent: Control, body: Control, width: float = 460.0) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := color_rect(Color(0.05, 0.08, 0.15, 0.6))
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var style := wood(24)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 24
	var card := panel_container(style)
	card.custom_minimum_size.x = width
	center.add_child(card)
	card.add_child(body)
	parent.add_child(overlay)
	return overlay
