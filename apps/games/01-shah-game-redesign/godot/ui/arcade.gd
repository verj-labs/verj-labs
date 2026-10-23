class_name Arcade
extends RefCounted
## The arcade look: panels and buttons with notched "big pixel" corners, built as tiny
## textures and cached. One big pixel (UNIT) is 4 screen pixels at the 720x1280 layout size.

const UNIT := 4

static var _cache: Dictionary = {}


## A notched-corner panel. `bevel` adds a light top edge and dark bottom edge; `shadow` adds a
## hard drop shadow one pixel to the right and below (it is drawn outside the control).
static func panel(fill: Color, border: Color, bevel: bool = true, shadow: bool = false) -> StyleBoxTexture:
	var key := "%s|%s|%s|%s" % [fill.to_html(), border.to_html(), bevel, shadow]
	if _cache.has(key):
		return _cache[key]
	var units := 9 if shadow else 8
	var image := Image.create(units * UNIT, units * UNIT, false, Image.FORMAT_RGBA8)
	var shade := Color(0, 0, 0, 0.45)
	if shadow:
		_rect(image, 1, 8, 8, 1, shade)
		_rect(image, 8, 1, 1, 8, shade)
	_rect(image, 1, 0, 6, 1, border)
	_rect(image, 1, 7, 6, 1, border)
	_rect(image, 0, 1, 1, 6, border)
	_rect(image, 7, 1, 1, 6, border)
	_rect(image, 1, 1, 6, 6, fill)
	for corner in [Vector2i(1, 1), Vector2i(6, 1), Vector2i(1, 6), Vector2i(6, 6)]:
		_rect(image, corner.x, corner.y, 1, 1, border)
	if bevel:
		_rect(image, 2, 1, 4, 1, fill.lightened(0.22))
		_rect(image, 2, 6, 4, 1, fill.darkened(0.3))

	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	var far := (3 if shadow else 2) * UNIT
	style.texture_margin_left = 2 * UNIT
	style.texture_margin_top = 2 * UNIT
	style.texture_margin_right = far
	style.texture_margin_bottom = far
	if shadow:
		style.expand_margin_right = UNIT
		style.expand_margin_bottom = UNIT
	style.content_margin_left = 4 * UNIT
	style.content_margin_right = 4 * UNIT
	style.content_margin_top = 4 * UNIT
	style.content_margin_bottom = 4 * UNIT
	_cache[key] = style
	return style


## Same panel with tighter padding (seat badges, small chips).
static func compact_panel(fill: Color, border: Color, shadow: bool = false) -> StyleBoxTexture:
	var style := panel(fill, border, true, shadow).duplicate() as StyleBoxTexture
	style.content_margin_left = 2 * UNIT
	style.content_margin_right = 2 * UNIT
	style.content_margin_top = 2 * UNIT
	style.content_margin_bottom = 2 * UNIT
	return style


static func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	image.fill_rect(Rect2i(x * UNIT, y * UNIT, w * UNIT, h * UNIT), color)
