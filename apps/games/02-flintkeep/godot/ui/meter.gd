class_name Meter
extends Control
## A rounded bar with centred text (Keep health, wave timer, research progress). The fill has
## a soft top highlight so it reads as a glass tube.

var value := 1.0  ## 0..1
var text := ""
var fill := Pal.CASH
var font_size := 17


func _init(p_fill: Color = Pal.CASH, height: float = 30.0, p_font_size: int = 17) -> void:
	fill = p_fill
	font_size = p_font_size
	custom_minimum_size.y = height
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(p_value: float, p_text: String = "") -> void:
	var v := clampf(p_value, 0.0, 1.0)
	if is_equal_approx(v, value) and p_text == text:
		return
	value = v
	text = p_text
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var radius := int(size.y / 2.0)
	draw_style_box(Kit.box(Color("#4a2a16"), Pal.INK, radius, 3), r)
	var inner := r.grow(-4)
	var w := inner.size.x * value
	if w >= 2.0:
		var bar := Kit.box(fill, fill.darkened(0.3), int(inner.size.y / 2.0), 0)
		draw_style_box(bar, Rect2(inner.position, Vector2(maxf(w, inner.size.y), inner.size.y)))
		var shine := Kit.box(Color(1, 1, 1, 0.35), Color.TRANSPARENT, int(inner.size.y / 4.0), 0)
		draw_style_box(shine, Rect2(inner.position + Vector2(5, 2), Vector2(maxf(w - 10, 2), inner.size.y * 0.32)))
	if text != "":
		var font := Fonts.heading()
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2((size.x - tw) / 2.0, (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Pal.INK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Pal.WHITE)
