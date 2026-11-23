class_name Fonts
extends RefCounted
## Cinzel (carved, old-style capitals) for titles and headings; Barlow (clean, compact) for
## everything you read while playing. Both are SIL Open Font License, see assets/fonts/.

static var _cache: Dictionary = {}


## Titles and section headings.
static func heading() -> Font:
	return _variation("heading", "res://assets/fonts/Cinzel.ttf", 700, 1)


static func body() -> Font:
	return _font("body", "res://assets/fonts/Barlow-Medium.ttf")


static func semibold() -> Font:
	return _font("semibold", "res://assets/fonts/Barlow-SemiBold.ttf")


static func bold() -> Font:
	return _font("bold", "res://assets/fonts/Barlow-Bold.ttf")


## Bold text drawn on the zoomed battlefield: a signed-distance-field font stays sharp at any scale.
static func field() -> Font:
	if not _cache.has("field"):
		var f := (load("res://assets/fonts/Barlow-Bold.ttf") as FontFile).duplicate() as FontFile
		f.multichannel_signed_distance_field = true
		f.msdf_pixel_range = 14
		_cache["field"] = f
	return _cache["field"]


static func _font(key: String, path: String) -> Font:
	if not _cache.has(key):
		_cache[key] = load(path)
	return _cache[key]


static func _variation(key: String, path: String, weight: int, spacing: int) -> Font:
	if not _cache.has(key):
		var v := FontVariation.new()
		v.base_font = load(path)
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		v.spacing_glyph = spacing
		_cache[key] = v
	return _cache[key]
