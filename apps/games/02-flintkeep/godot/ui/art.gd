class_name Art
extends RefCounted
## The game's sprites: SVG files in res://assets/art (made by tools/make_art.py, or by hand).
## Each is rasterised once at high resolution with mipmaps, so it stays crisp at any zoom.
##
## WIDTH is how wide the sprite is on the battlefield (field units) and FOOT is the point it
## stands on, as a fraction of the canvas (0.5, 1.0 = bottom centre).

const DIR := "res://assets/art/"
const RASTER_SCALE := 3.0

const WIDTH := {
	"keep": 36.0, "musket": 19.0, "cannon": 20.0, "volley": 19.0, "sniper": 19.0, "arcane": 19.0,
	"slot": 17.0, "footman": 9.0, "runner": 8.0, "brute": 13.0, "balloon": 11.0, "wyvern": 15.0,
	"wyvern_b": 15.0, "juggernaut": 18.0, "sapper": 9.0, "shaman": 9.5,
	"decor_bush": 9.0, "decor_tuft": 4.5, "decor_flowers": 5.5, "decor_rock": 6.0, "decor_mushroom": 4.0,
}
## Enemies with a second walking frame (name + "_b").
const WALKERS := ["footman", "runner", "brute", "sapper", "shaman"]
const FOOT := {
	"keep": Vector2(0.5, 0.97), "musket": Vector2(0.5, 0.92), "cannon": Vector2(0.5, 0.92),
	"volley": Vector2(0.5, 0.92), "sniper": Vector2(0.5, 0.93), "arcane": Vector2(0.5, 0.93),
	"slot": Vector2(0.5, 0.9), "footman": Vector2(0.5, 0.94), "runner": Vector2(0.5, 0.94),
	"brute": Vector2(0.5, 0.95), "balloon": Vector2(0.5, 0.92), "wyvern": Vector2(0.5, 0.55),
	"wyvern_b": Vector2(0.5, 0.55), "juggernaut": Vector2(0.5, 0.96), "sapper": Vector2(0.5, 0.94),
	"shaman": Vector2(0.5, 0.94), "decor_bush": Vector2(0.5, 0.85), "decor_tuft": Vector2(0.5, 0.9),
	"decor_flowers": Vector2(0.5, 0.9), "decor_rock": Vector2(0.5, 0.85), "decor_mushroom": Vector2(0.5, 0.92),
}

static var _cache: Dictionary = {}


static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = _load(name)
	return _cache[name]


static func _load(name: String) -> Texture2D:
	var img := Image.new()
	var svg := FileAccess.get_file_as_string(DIR + name + ".svg")
	if svg == "" or img.load_svg_from_string(svg, RASTER_SCALE) != OK:
		push_warning("Missing art: " + name)
		img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.MAGENTA)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Where to draw `name` so its foot lands on `at`, `width` field units wide.
static func rect(name: String, at: Vector2, width: float = -1.0) -> Rect2:
	var t := tex(name)
	var key := base(name)
	var w: float = WIDTH.get(key, 10.0) if width < 0.0 else width
	var size := Vector2(w, w * t.get_height() / t.get_width())
	var foot: Vector2 = FOOT.get(key, Vector2(0.5, 1.0))
	return Rect2(at - size * foot, size)


## Height in field units when drawn at its normal width (for health bars and labels).
static func height(name: String) -> float:
	var t := tex(name)
	return WIDTH.get(base(name), 10.0) * t.get_height() / t.get_width()


## A variant ("musket_3", "footman_b") sizes and stands like its base sprite.
static func base(name: String) -> String:
	for suffix in ["_2", "_3", "_b"]:
		if name.ends_with(suffix) and WIDTH.has(name.trim_suffix(suffix)):
			return name.trim_suffix(suffix)
	return name
