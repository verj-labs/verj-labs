class_name Fonts
extends RefCounted
## Lilita One (chunky, friendly) for titles, buttons and big numbers; Fredoka (rounded) for
## everything else. Both are SIL Open Font License, see assets/fonts/.

static var _cache: Dictionary = {}


## Titles, buttons and numbers.
static func heading() -> Font:
	return _font("heading", "res://assets/fonts/LilitaOne.ttf")


static func body() -> Font:
	return _weight("body", 500)


static func semibold() -> Font:
	return _weight("semibold", 600)


static func bold() -> Font:
	return _weight("bold", 700)


## Text drawn on the zoomed battlefield: a signed-distance-field font stays sharp at any scale.
static func field() -> Font:
	if not _cache.has("field"):
		var f := (load("res://assets/fonts/LilitaOne.ttf") as FontFile).duplicate() as FontFile
		f.multichannel_signed_distance_field = true
		f.msdf_pixel_range = 14
		_cache["field"] = f
	return _cache["field"]


static func _font(key: String, path: String) -> Font:
	if not _cache.has(key):
		_cache[key] = load(path)
	return _cache[key]


static func _weight(key: String, weight: int) -> Font:
	if not _cache.has(key):
		var v := FontVariation.new()
		v.base_font = load("res://assets/fonts/Fredoka.ttf")
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_cache[key] = v
	return _cache[key]
