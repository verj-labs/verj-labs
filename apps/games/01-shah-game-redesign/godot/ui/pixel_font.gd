class_name PixelFont
extends RefCounted
## A 5x7 arcade bitmap font built at runtime (no font files). Draw it at whole-number
## multiples of 7 px (7, 14, 21, 28 ...) so every font pixel stays a crisp square.
## Lower-case letters share the capital shapes, so any text works.

const GLYPH_W := 5
const GLYPH_H := 7
const ADVANCE := 6  ## 5 pixels of glyph + 1 of space.
const PAD := 1
const COLUMNS := 16

const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
	" ": [".....", ".....", ".....", ".....", ".....", ".....", "....."],
	".": [".....", ".....", ".....", ".....", ".....", ".##..", ".##.."],
	",": [".....", ".....", ".....", ".....", ".##..", "..#..", ".#..."],
	"!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	":": [".....", ".##..", ".##..", ".....", ".##..", ".##..", "....."],
	"-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
	"'": ["..#..", "..#..", ".#...", ".....", ".....", ".....", "....."],
	"#": [".#.#.", ".#.#.", "#####", ".#.#.", "#####", ".#.#.", ".#.#."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
	"(": ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#."],
	")": [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#..."],
	">": ["#....", ".#...", "..#..", "...#.", "..#..", ".#...", "#...."],
	"<": ["....#", "...#.", "..#..", ".#...", "..#..", "...#.", "....#"],
	"=": [".....", ".....", "#####", ".....", "#####", ".....", "....."],
	"*": [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."],
	"_": [".....", ".....", ".....", ".....", ".....", ".....", "#####"],
}

static var _font: FontFile


## The shared font. Use it at font sizes that are multiples of 7 (see size_for).
static func font() -> FontFile:
	if _font == null:
		_font = _build()
	return _font


## Font size (in px) for a whole-number pixel scale: scale 2 = every font pixel is 2x2 px.
static func size_for(pixel_scale: int) -> int:
	return GLYPH_H * pixel_scale


## Width in px of `text` at a pixel scale (no wrapping).
static func text_width(text: String, pixel_scale: int) -> int:
	return maxi(0, text.length() * ADVANCE - 1) * pixel_scale


static func apply(label: Control, pixel_scale: int, color: Color) -> void:
	label.add_theme_font_override("font", font())
	label.add_theme_font_size_override("font_size", size_for(pixel_scale))
	label.add_theme_color_override("font_color", color)


static func _build() -> FontFile:
	var keys: Array = GLYPHS.keys()
	var cell := Vector2i(GLYPH_W + PAD * 2, GLYPH_H + PAD * 2)
	var rows := ceili(float(keys.size()) / COLUMNS)
	var image := Image.create(COLUMNS * cell.x, rows * cell.y, false, Image.FORMAT_RGBA8)

	var font := FontFile.new()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.generate_mipmaps = false
	font.multichannel_signed_distance_field = false
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.fixed_size = GLYPH_H
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	font.set_cache_ascent(0, GLYPH_H, GLYPH_H)
	font.set_cache_descent(0, GLYPH_H, 2)

	var size := Vector2i(GLYPH_H, 0)
	for i in keys.size():
		var key: String = keys[i]
		var origin := Vector2i((i % COLUMNS) * cell.x + PAD, (i / COLUMNS) * cell.y + PAD)
		var rows_of_pixels: Array = GLYPHS[key]
		for y in GLYPH_H:
			for x in GLYPH_W:
				if (rows_of_pixels[y] as String)[x] == "#":
					image.set_pixel(origin.x + x, origin.y + y, Color.WHITE)
		for code in _codes_for(key):
			font.set_glyph_advance(0, GLYPH_H, code, Vector2(ADVANCE, 0))
			font.set_glyph_offset(0, size, code, Vector2(0, -GLYPH_H))
			font.set_glyph_size(0, size, code, Vector2(GLYPH_W, GLYPH_H))
			font.set_glyph_uv_rect(0, size, code, Rect2(origin, Vector2(GLYPH_W, GLYPH_H)))
			font.set_glyph_texture_idx(0, size, code, 0)
	font.set_texture_image(0, size, 0, image)
	return font


## A letter answers to both its capital and lower-case code.
static func _codes_for(key: String) -> Array[int]:
	var codes: Array[int] = [key.unicode_at(0)]
	if key >= "A" and key <= "Z":
		codes.append(key.to_lower().unicode_at(0))
	return codes
