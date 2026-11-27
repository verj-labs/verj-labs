class_name FieldFx
extends Node2D
## Short-lived effects on the battlefield: tracers that fade from the muzzle to the target,
## cannon balls and blasts, arcane lightning, sparks, smoke and floating "+$3" numbers.
## A child layer adds soft glow with additive blending.
##
## Late in a run there can be hundreds of shots a second, so effects are capped (the oldest go
## first) and all sparks, tracers and blasts are drawn as one mesh (see Geo), not one call each.

const MAX_PARTICLES := 300
const MAX_SHOTS := 90
const MAX_TEXTS := 24
const TEXT_SIZE := 7

var shots: Array = []  ## {from, to, color, t, life, kind, seed}
var blasts: Array = []  ## {at, radius, t, life}
var particles: Array = []  ## {pos, vel, color, t, life, size, gravity}
var texts: Array = []  ## {pos, text, color, t, life, size}
var glows: Array = []  ## steady lights set every frame by the view: [pos, radius, color]
var glow_boost := 1.0  ## brighter shot glows at dawn, dusk and night (set by the view)

var _glow_layer: Node2D
var _glow_tex: Texture2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_glow_tex = soft_disc()
	_glow_layer = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_layer.material = mat
	_glow_layer.draw.connect(_draw_glow)
	add_child(_glow_layer)


func shot(from: Vector2, to: Vector2, kind: String) -> void:
	var life := 0.14
	match kind:
		"cannon": life = 0.24
		"keep": life = 0.2
		"sniper": life = 0.2
		"arcane", "chain": life = 0.18
	var color: Color = Pal.WEAPON_COLORS.get(kind, Pal.WEAPON_COLORS["arcane"])
	if shots.size() >= MAX_SHOTS:
		shots.pop_front()
	shots.append({"from": from, "to": to, "color": color, "t": 0.0, "life": life, "kind": kind, "seed": _rng.randi()})
	if kind in ["musket", "volley", "sniper", "cannon"]:
		smoke(from, 2 if kind != "cannon" else 4)


func blast(at: Vector2, radius: float) -> void:
	blasts.append({"at": at, "radius": radius, "t": 0.0, "life": 0.35})
	burst(at, Pal.ORANGE, 12, 45.0)
	smoke(at, 5)


func burst(at: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		if particles.size() >= MAX_PARTICLES:
			return
		var dir := Vector2.from_angle(_rng.randf() * TAU)
		particles.append({"pos": at, "vel": dir * _rng.randf_range(speed * 0.3, speed) + Vector2(0, -15),
			"color": color, "t": 0.0, "life": _rng.randf_range(0.25, 0.55), "size": _rng.randf_range(0.5, 1.0), "gravity": 90.0})


func smoke(at: Vector2, count: int) -> void:
	for i in count:
		if particles.size() >= MAX_PARTICLES:
			return
		particles.append({"pos": at + Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-2, 1)),
			"vel": Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-14, -6)), "color": Color(0.82, 0.82, 0.86, 0.55),
			"t": 0.0, "life": _rng.randf_range(0.5, 0.9), "size": _rng.randf_range(1.2, 2.2), "gravity": 0.0})


func float_text(at: Vector2, text: String, color: Color, life: float = 0.9, size: int = TEXT_SIZE) -> void:
	if texts.size() >= MAX_TEXTS:
		texts.pop_front()
	texts.append({"pos": at, "text": text, "color": color, "t": 0.0, "life": life, "size": size})


func tick(delta: float) -> void:
	_age(shots, delta)
	_age(blasts, delta)
	_age(texts, delta)
	for p in particles:
		p["vel"].y += p["gravity"] * delta
		p["pos"] += p["vel"] * delta
	_age(particles, delta)
	queue_redraw()
	_glow_layer.queue_redraw()


## Advances every effect in `list` and drops the finished ones, in place (no new arrays).
static func _age(list: Array, delta: float) -> void:
	var keep := 0
	for item in list:
		item["t"] += delta
		if item["t"] < item["life"]:
			list[keep] = item
			keep += 1
	list.resize(keep)


func _draw() -> void:
	var g := Geo.new()
	for p in particles:
		var c: Color = p["color"]
		var k: float = p["t"] / p["life"]
		c.a *= 1.0 - k
		var grow: float = 1.0 + (k * 1.5 if p["gravity"] == 0.0 else 0.0)
		g.disc(p["pos"], p["size"] * grow, c, 6)
	for b in blasts:
		var k: float = b["t"] / b["life"]
		var radius: float = b["radius"] * (0.3 + 0.7 * k)
		g.disc(b["at"], radius, Color(1, 0.6, 0.25, 0.25 * (1.0 - k)), 20)
		_ring(g, b["at"], radius, 0.8, Color(1, 0.8, 0.45, 1.0 - k))
	for s in shots:
		_draw_shot(g, s)
	g.submit(self)
	var font := Fonts.field()
	for t in texts:
		var k: float = t["t"] / t["life"]
		var pos: Vector2 = t["pos"] + Vector2(0, -12 * k)
		var c: Color = t["color"]
		c.a = 1.0 - maxf(k - 0.6, 0.0) / 0.4
		var fs: int = t["size"]
		var w := font.get_string_size(t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var at := pos - Vector2(w / 2.0, 0)
		draw_string_outline(font, at, t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 2, Color(0, 0, 0, 0.7 * c.a))
		draw_string(font, at, t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


static func _ring(g: Geo, at: Vector2, radius: float, width: float, c: Color) -> void:
	var steps := 24
	for k in steps:
		var a0 := TAU * k / steps
		var a1 := TAU * (k + 1) / steps
		g.line(at + Vector2.from_angle(a0) * radius, at + Vector2.from_angle(a1) * radius, width, c)


## A stroke whose colour is strongest at `from` and fades out towards `to`.
static func _fade_line(g: Geo, from: Vector2, to: Vector2, head: Color, tail: Color, width: float) -> void:
	var dir := (to - from).normalized()
	if dir == Vector2.ZERO:
		return
	var side := Vector2(-dir.y, dir.x) * width * 0.5
	g.quad(from + side, to + side, to - side, from - side, head, tail, tail, head)


func _draw_shot(g: Geo, s: Dictionary) -> void:
	var k: float = s["t"] / s["life"]
	var from: Vector2 = s["from"]
	var to: Vector2 = s["to"]
	var c: Color = s["color"]
	match s["kind"]:
		"cannon":
			var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 12.0)
			g.disc(p, 1.4, Color("#1a1a22"), 8)
			g.disc(p - Vector2(0.4, 0.4), 0.5, Color(1, 1, 1, 0.35), 6)
		"arcane", "chain":
			_draw_zigzag(g, from, to, c, s["seed"], 1.0 - k)
		"sniper":
			c.a = 1.0 - k
			_fade_line(g, from, to, c, Color(c.r, c.g, c.b, 0.0), 1.0)
		"keep":
			# a firebolt: a hot white-yellow core with an orange trail
			var head := from.lerp(to, minf(k * 1.6, 1.0))
			var tail := from.lerp(to, maxf(k * 1.6 - 0.45, 0.0))
			_fade_line(g, head, tail, Color(1.0, 0.6, 0.1, 0.9), Color(1.0, 0.35, 0.05, 0.0), 1.6)
			g.disc(head, 1.3, Color(1.0, 0.55, 0.1, 0.95), 8)
			g.disc(head, 0.7, Color(1.0, 0.97, 0.75), 6)
		_:
			# a bright head flies to the target, trailing a fading line back to the muzzle
			var head := from.lerp(to, minf(k * 1.8, 1.0))
			c.a = 1.0 - maxf(k - 0.5, 0.0) * 2.0
			_fade_line(g, head, from, c, Color(c.r, c.g, c.b, 0.0), 0.9)
			g.disc(head, 0.8, Color(1, 1, 0.9, c.a), 6)


static func _draw_zigzag(g: Geo, from: Vector2, to: Vector2, c: Color, seed_value: int, alpha: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var normal := (to - from).orthogonal().normalized()
	var prev := from
	var steps := 6
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		if i < steps:
			p += normal * rng.randf_range(-3.0, 3.0)
		var a := alpha * (1.0 - 0.6 * float(i) / steps)
		g.line(prev, p, 1.0, Color(c.r, c.g, c.b, a))
		g.line(prev, p, 0.4, Color(1, 1, 1, a * 0.7))
		prev = p


func _draw_glow() -> void:
	for g in glows:
		_glow(g[0], g[1], g[2])
	var boost := sqrt(glow_boost)  # shots light up the field more after dark
	for s in shots:
		var k: float = s["t"] / s["life"]
		var c: Color = s["color"]
		c.a = minf(0.6 * (1.0 - k) * glow_boost, 1.0)
		if s["kind"] == "cannon":
			_glow(s["from"], 12.0 * boost, Color(1, 0.6, 0.2, minf(0.55 * (1.0 - k) * glow_boost, 1.0)))
		else:
			_glow(s["from"], 7.0 * boost, c)
			_glow(s["to"], 5.0 * boost, c)
		if s["kind"] in ["arcane", "chain", "sniper", "keep"]:
			_glow(s["from"].lerp(s["to"], 0.35), 10.0 * boost, Color(c.r, c.g, c.b, c.a * 0.45))
	for b in blasts:
		var k: float = b["t"] / b["life"]
		_glow(b["at"], b["radius"] * 1.8 * boost, Color(1.0, 0.55, 0.15, minf(0.85 * (1.0 - k) * glow_boost, 1.0)))


func _glow(at: Vector2, radius: float, color: Color) -> void:
	_glow_layer.draw_texture_rect(_glow_tex, Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


## A soft white disc that fades to nothing at its edge (glows, range fill, courtyard).
static func soft_disc(inner: float = 0.0, mid_alpha: float = 0.35) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(clampf(inner + 0.35, 0.05, 0.95), Color(1, 1, 1, mid_alpha))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex
