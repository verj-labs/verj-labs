class_name SkyButton
extends Button
## The round button in the battlefield's corner: shows a sun (warm at dawn and dusk) or a moon,
## and opens the time-of-day picker.

var night := 0.0:
	set(value):
		if absf(value - night) > 0.02:
			night = value
			_icon.queue_redraw()
var warmth := 0.0:
	set(value):
		if absf(value - warmth) > 0.02:
			warmth = value
			_icon.queue_redraw()
var _icon := Control.new()


func _init() -> void:
	Kit.style_button(self, Kit.Btn.SECONDARY, 18)
	Kit.tighten(self, 0.0)
	custom_minimum_size = Vector2(52, 52)
	tooltip_text = "Time of day"
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.draw.connect(_draw_icon)
	add_child(_icon)


func _draw_icon() -> void:
	var c := _icon.size / 2.0 + Vector2(0, -2)
	if night > 0.5:
		_icon.draw_circle(c, 12.0, Color("#f4f1ff"), true, -1.0, true)
		_icon.draw_circle(c + Vector2(5.5, -4.0), 10.5, Color("#4aa3ff"), true, -1.0, true)  # carve a crescent (button blue)
		return
	var sun := Color("#ffd23f").lerp(Color("#ff8a3d"), warmth)
	for k in 8:
		var dir := Vector2.from_angle(TAU * k / 8.0)
		_icon.draw_line(c + dir * 12.0, c + dir * 17.0, sun, 3.0, true)
	_icon.draw_circle(c, 9.0, sun, true, -1.0, true)
