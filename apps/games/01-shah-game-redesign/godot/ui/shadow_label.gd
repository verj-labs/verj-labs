class_name ShadowLabel
extends Control
## Pixel-font text with a hard drop shadow, for logos, titles and big announcements.

var _front: Label
var _back: Label
var _offset: float
var _pixel_scale: int


func _init(text: String = "", pixel_scale: int = 4, color: Color = Palette.YELLOW, shadow: Color = Palette.PINK) -> void:
	_pixel_scale = pixel_scale
	_offset = float(maxi(1, pixel_scale / 2))
	_back = UIKit.pixel_label(text, pixel_scale, shadow)
	_front = UIKit.pixel_label(text, pixel_scale, color)
	_back.position = Vector2(_offset, _offset)
	add_child(_back)
	add_child(_front)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize()


func set_text(text: String) -> void:
	_front.text = text
	_back.text = text
	_resize()


## Changes the pixel scale (for text that must shrink to fit).
func set_pixel_scale(pixel_scale: int) -> void:
	if pixel_scale == _pixel_scale:
		return
	_pixel_scale = pixel_scale
	_offset = float(maxi(1, pixel_scale / 2))
	_back.position = Vector2(_offset, _offset)
	PixelFont.apply(_front, pixel_scale, _front.get_theme_color("font_color"))
	PixelFont.apply(_back, pixel_scale, _back.get_theme_color("font_color"))
	_resize()


func set_colors(color: Color, shadow: Color) -> void:
	_front.add_theme_color_override("font_color", color)
	_back.add_theme_color_override("font_color", shadow)


## Sized from the font metrics directly, so it is right even before the first layout pass.
func _resize() -> void:
	var text_size := Vector2(
		PixelFont.text_width(_front.text, _pixel_scale), PixelFont.size_for(_pixel_scale) + 2 * _pixel_scale
	)
	custom_minimum_size = text_size + Vector2(_offset, _offset)
	size = custom_minimum_size
	_front.size = text_size
	_back.size = text_size
