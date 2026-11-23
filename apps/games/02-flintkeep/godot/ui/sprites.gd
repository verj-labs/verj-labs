class_name Sprites
extends RefCounted
## Pixel-art sprites painted in code (no image files): rectangles and single pixels on a tiny
## Image, then a dark outline is traced around everything. Lit from the top left.
## Each sprite is built once and cached. Draw them at whole-number scales.

const OUTLINE := Color("#0c0e18")
const C := {
	"S": Color("#4b5068"), "s": Color("#7c829c"), "l": Color("#a9afc6"),
	"W": Color("#5a3620"), "w": Color("#8a5a34"), "h": Color("#b07a48"),
	"R": Color("#8c1e2c"), "r": Color("#d63a43"), "B": Color("#1c3470"), "b": Color("#3c6fd6"),
	"c": Color("#5ef2ff"), "y": Color("#ffc94a"), "Y": Color("#a87a2a"),
	"M": Color("#262a37"), "m": Color("#5d6478"), "n": Color("#9aa3b8"),
	"f": Color("#e8b48a"), "g": Color("#6fae4a"), "G": Color("#3a6b30"),
	"p": Color("#b06bff"), "P": Color("#5b2a9e"), "v": Color("#ecd6ff"),
	"x": Color("#f4efe0"), "o": Color("#ff9a3c"), "e": Color("#ff4d5e"), "t": Color("#e8cf8a"),
}

static var _cache: Dictionary = {}


static func get_tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = ImageTexture.create_from_image(_paint(name))
	return _cache[name]


static func _paint(name: String) -> Image:
	var p := Painter.new()
	match name:
		"keep": _keep(p)
		"musket": _musket(p)
		"cannon": _cannon(p)
		"volley": _volley(p)
		"sniper": _sniper(p)
		"arcane": _arcane(p)
		"footman": _footman(p)
		"runner": _runner(p)
		"brute": _brute(p)
		"balloon": _balloon(p)
		"wyvern": _wyvern(p, false)
		"wyvern_b": _wyvern(p, true)
		"juggernaut": _juggernaut(p)
		"coin": _coin(p)
		"cash": _cash(p)
		"slot": _slot(p)
		_: p.start(4, 4)
	return p.finish()


class Painter:
	var img: Image

	func start(w: int, h: int) -> void:
		img = Image.create(w + 2, h + 2, false, Image.FORMAT_RGBA8)  # 1 px border for the outline

	func rect(x: int, y: int, w: int, h: int, key: String) -> void:
		for yy in h:
			for xx in w:
				px(x + xx, y + yy, key)

	func px(x: int, y: int, key: String) -> void:
		var xx := x + 1
		var yy := y + 1
		if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
			img.set_pixel(xx, yy, Sprites.C[key])

	func filled(x: int, y: int) -> bool:
		var xx := x + 1
		var yy := y + 1
		return xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height() and img.get_pixel(xx, yy).a > 0.0

	func disc(cx: float, cy: float, r: float, key: String) -> void:
		for y in range(int(cy - r) - 1, int(cy + r) + 2):
			for x in range(int(cx - r) - 1, int(cx + r) + 2):
				if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy)) <= r:
					px(x, y, key)

	func finish() -> Image:
		var out := img.duplicate() as Image
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.0:
					continue
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(x, y) + d
					if n.x >= 0 and n.y >= 0 and n.x < img.get_width() and n.y < img.get_height() and img.get_pixel(n.x, n.y).a > 0.0:
						out.set_pixel(x, y, Sprites.OUTLINE)
						break
		return out


# --- Buildings --------------------------------------------------------------------------------

static func _stone_bricks(p: Painter, x: int, y: int, w: int, h: int) -> void:
	p.rect(x, y, w, h, "s")
	p.rect(x, y, 2, h, "l")
	p.rect(x + w - 2, y, 2, h, "S")
	for row in range(y + 3, y + h, 4):
		for col in range(x + 2, x + w - 2):
			if (col + row / 4) % 5 != 0:
				p.px(col, row, "S")


static func _keep(p: Painter) -> void:
	p.start(26, 32)
	_stone_bricks(p, 4, 12, 18, 20)
	p.rect(2, 8, 22, 5, "s")
	p.rect(2, 8, 22, 1, "l")
	p.rect(2, 12, 22, 1, "S")
	for x in range(2, 24, 4):
		p.rect(x, 5, 2, 3, "s")
		p.px(x, 5, "l")
	# arcane crystal the Keep shoots from
	p.rect(12, 3, 2, 5, "c")
	p.px(11, 5, "c")
	p.px(14, 5, "c")
	p.px(12, 3, "x")
	# flag
	p.rect(16, 0, 1, 8, "m")
	p.rect(17, 0, 6, 3, "b")
	p.rect(17, 3, 4, 1, "b")
	p.px(19, 1, "y")
	# door and windows
	p.rect(10, 24, 6, 8, "M")
	p.rect(11, 25, 4, 7, "W")
	p.rect(11, 23, 4, 1, "M")
	p.px(13, 28, "y")
	for wx in [7, 17]:
		p.rect(wx, 16, 2, 3, "M")
		p.px(wx, 17, "o")
	p.rect(4, 12, 18, 1, "Y")  # brass band


static func _wood_tower(p: Painter, x: int, y: int, w: int, h: int) -> void:
	p.rect(x, y, w, h, "w")
	p.rect(x, y, 1, h, "h")
	p.rect(x + w - 1, y, 1, h, "W")
	for col in range(x + 3, x + w - 1, 3):
		p.rect(col, y, 1, h, "W")
	p.rect(x - 1, y, w + 2, 2, "h")
	p.rect(x - 1, y + 1, w + 2, 1, "W")


static func _musket(p: Painter) -> void:
	p.start(16, 20)
	_wood_tower(p, 3, 9, 10, 11)
	p.rect(6, 1, 4, 2, "M")  # shako
	p.px(8, 0, "r")
	p.rect(6, 3, 4, 2, "f")
	p.rect(5, 5, 6, 3, "b")  # blue coat: the defenders
	p.px(7, 5, "x")
	p.px(8, 6, "x")
	p.rect(9, 4, 6, 1, "m")  # musket
	p.px(15, 4, "n")
	p.rect(10, 5, 2, 1, "W")


static func _cannon(p: Painter) -> void:
	p.start(16, 20)
	_stone_bricks(p, 2, 10, 12, 10)
	for x in range(2, 14, 3):
		p.rect(x, 8, 2, 2, "s")
	p.rect(3, 4, 9, 4, "M")
	p.rect(4, 4, 7, 1, "m")
	p.rect(12, 3, 3, 6, "M")
	p.px(13, 4, "m")
	p.disc(5.5, 8.5, 2.2, "W")
	p.px(5, 8, "Y")


static func _volley(p: Painter) -> void:
	p.start(16, 20)
	_wood_tower(p, 3, 10, 10, 10)
	for i in 4:
		p.rect(4 + i * 2, 1 + (i % 2), 1, 8 - (i % 2), "M")
		p.px(4 + i * 2, 1 + (i % 2), "m")
	p.rect(3, 6, 10, 2, "Y")
	p.rect(3, 6, 10, 1, "y")
	p.rect(6, 8, 4, 2, "W")


static func _sniper(p: Painter) -> void:
	p.start(16, 22)
	_stone_bricks(p, 5, 8, 6, 14)
	p.rect(4, 7, 8, 2, "l")
	p.rect(4, 8, 8, 1, "S")
	p.rect(6, 1, 3, 2, "G")  # tricorn
	p.rect(6, 3, 3, 2, "f")
	p.rect(5, 5, 5, 2, "G")
	p.rect(8, 3, 8, 1, "m")  # long rifle
	p.px(15, 3, "n")
	p.px(10, 4, "W")


static func _arcane(p: Painter) -> void:
	p.start(16, 22)
	p.rect(4, 10, 8, 12, "S")
	p.rect(4, 10, 2, 12, "s")
	p.rect(10, 10, 2, 12, "M")
	for ry in [13, 17]:
		p.px(7, ry, "p")
		p.px(8, ry + 1, "p")
	p.rect(3, 9, 10, 2, "P")
	p.rect(3, 9, 10, 1, "p")
	# floating crystal
	p.px(8, 0, "v")
	p.rect(7, 1, 3, 1, "p")
	p.rect(6, 2, 5, 3, "p")
	p.rect(7, 2, 1, 3, "v")
	p.rect(7, 5, 3, 1, "P")
	p.px(8, 6, "P")


# --- Enemies (goblin raiders) ------------------------------------------------------------------

static func _footman(p: Painter) -> void:
	p.start(10, 11)
	p.px(0, 2, "g")
	p.px(8, 2, "g")
	p.rect(2, 1, 5, 4, "g")
	p.rect(2, 0, 5, 1, "m")
	p.px(3, 2, "e")
	p.px(5, 2, "e")
	p.rect(2, 5, 5, 3, "r")
	p.rect(2, 7, 5, 1, "W")
	p.rect(2, 8, 2, 2, "G")
	p.rect(5, 8, 2, 2, "G")
	p.rect(8, 3, 1, 6, "W")
	p.rect(8, 3, 2, 2, "n")


static func _runner(p: Painter) -> void:
	p.start(8, 9)
	p.px(0, 1, "g")
	p.px(7, 1, "g")
	p.rect(2, 0, 4, 3, "g")
	p.px(3, 1, "e")
	p.px(4, 1, "e")
	p.rect(2, 3, 4, 3, "o")
	p.rect(1, 6, 2, 2, "G")
	p.rect(5, 6, 2, 2, "G")
	p.rect(7, 3, 1, 3, "n")


static func _brute(p: Painter) -> void:
	p.start(14, 14)
	p.rect(5, 0, 5, 4, "G")
	p.rect(5, 0, 5, 1, "m")
	p.px(6, 2, "e")
	p.px(8, 2, "e")
	p.rect(1, 4, 12, 6, "m")
	p.rect(1, 4, 12, 1, "n")
	p.rect(6, 5, 2, 4, "n")
	p.rect(0, 5, 1, 4, "G")
	p.rect(13, 5, 1, 4, "G")
	p.rect(3, 10, 3, 3, "M")
	p.rect(8, 10, 3, 3, "M")
	for rx in [3, 10]:
		p.px(rx, 6, "n")


static func _balloon(p: Painter) -> void:
	p.start(12, 17)
	p.disc(6.0, 5.5, 5.5, "r")
	for y in 12:
		for sx in [1, 5, 9]:
			for x in [sx, sx + 1]:
				if p.filled(x, y):
					p.px(x, y, "t")
	p.px(4, 2, "x")
	p.rect(3, 11, 1, 2, "W")
	p.rect(8, 11, 1, 2, "W")
	p.rect(3, 13, 6, 3, "w")
	p.rect(3, 13, 6, 1, "h")
	p.px(5, 12, "g")
	p.px(6, 12, "g")


static func _wyvern(p: Painter, flap: bool) -> void:
	p.start(17, 11)
	p.rect(6, 3, 5, 5, "P")
	p.rect(7, 1, 3, 3, "P")
	p.px(7, 2, "e")
	p.px(9, 2, "e")
	p.rect(8, 8, 1, 3, "P")
	var wy := 5 if flap else 1
	for i in 6:
		var h := 4 - i / 2
		p.rect(5 - i, wy + (i if not flap else -i / 2), 1, maxi(h, 1), "p")
		p.rect(11 + i, wy + (i if not flap else -i / 2), 1, maxi(h, 1), "p")
	p.px(8, 4, "v")


static func _juggernaut(p: Painter) -> void:
	p.start(18, 19)
	p.rect(6, 0, 6, 5, "M")
	p.rect(6, 0, 6, 1, "m")
	p.px(7, 2, "e")
	p.px(10, 2, "e")
	p.rect(1, 5, 16, 4, "m")
	p.rect(1, 5, 16, 1, "n")
	p.rect(3, 9, 12, 6, "M")
	p.disc(9.0, 11.5, 2.0, "o")
	p.px(9, 11, "y")
	for rx in [2, 15]:
		p.px(rx, 7, "n")
	p.rect(4, 15, 4, 4, "M")
	p.rect(10, 15, 4, 4, "M")
	p.rect(0, 6, 1, 6, "m")
	p.rect(17, 6, 1, 6, "m")


# --- Icons -------------------------------------------------------------------------------------

static func _coin(p: Painter) -> void:
	p.start(7, 7)
	p.disc(3.5, 3.5, 3.5, "Y")
	p.disc(3.5, 3.5, 2.6, "y")
	p.rect(3, 2, 1, 3, "Y")
	p.px(2, 1, "x")


static func _cash(p: Painter) -> void:
	p.start(9, 6)
	p.rect(0, 0, 9, 6, "G")
	p.rect(1, 1, 7, 4, "g")
	p.rect(4, 1, 1, 4, "G")
	p.px(3, 2, "G")
	p.px(5, 3, "G")


static func _slot(p: Painter) -> void:
	p.start(14, 8)
	p.disc(7.0, 4.0, 4.0, "S")
	p.rect(1, 2, 12, 4, "S")
	p.rect(2, 3, 10, 2, "s")
	p.px(7, 4, "l")
