class_name Meter
extends Control
## A chunky bar with pixel text on it (Keep health, wave timer, research progress).

var value := 1.0  ## 0..1
var text := ""
var fill := Pal.CASH
var back := Pal.SHADOW
var text_scale := 2


func _init(p_fill: Color = Pal.CASH, height: float = 28.0, p_text_scale: int = 2) -> void:
	fill = p_fill
	text_scale = p_text_scale
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
	draw_rect(r, Pal.LINE)
	draw_rect(r.grow(-3), back)
	var inner := r.grow(-3)
	var w := floorf(inner.size.x * value)
	if w > 0.0:
		draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), fill)
		draw_rect(Rect2(inner.position, Vector2(w, 3)), fill.lightened(0.3))
	if text != "":
		var font := PixelFont.font()
		var fs := PixelFont.size_for(text_scale)
		var tw := PixelFont.text_width(text, text_scale)
		var at := Vector2(floorf((size.x - tw) / 2.0), floorf((size.y + fs) / 2.0) - text_scale)
		draw_string(font, at + Vector2(text_scale, text_scale), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.PARCHMENT)
