class_name FieldFx
extends Node2D
## Short-lived effects on the battlefield: tracers that fade from the muzzle to the target,
## cannon balls and blasts, arcane lightning, sparks, smoke and floating "+$3" numbers.
## A child layer adds soft glow with additive blending.

const MAX_PARTICLES := 500
const TEXT_SIZE := 7

var shots: Array = []  ## {from, to, color, t, life, kind, seed}
var blasts: Array = []  ## {at, radius, t, life}
var particles: Array = []  ## {pos, vel, color, t, life, size, gravity}
var texts: Array = []  ## {pos, text, color, t, life, size}
var glows: Array = []  ## steady lights set every frame by the view: [pos, radius, color]

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
	texts.append({"pos": at, "text": text, "color": color, "t": 0.0, "life": life, "size": size})


func tick(delta: float) -> void:
	for list in [shots, blasts, texts]:
		for item in list:
			item["t"] += delta
	shots = shots.filter(func(s: Dictionary) -> bool: return s["t"] < s["life"])
	blasts = blasts.filter(func(s: Dictionary) -> bool: return s["t"] < s["life"])
	texts = texts.filter(func(s: Dictionary) -> bool: return s["t"] < s["life"])
	for p in particles:
		p["t"] += delta
		p["vel"].y += p["gravity"] * delta
		p["pos"] += p["vel"] * delta
	particles = particles.filter(func(p: Dictionary) -> bool: return p["t"] < p["life"])
	queue_redraw()
	_glow_layer.queue_redraw()


func _draw() -> void:
	for p in particles:
		var c: Color = p["color"]
		var k: float = p["t"] / p["life"]
		c.a *= 1.0 - k
		var grow: float = 1.0 + (k * 1.5 if p["gravity"] == 0.0 else 0.0)
		draw_circle(p["pos"], p["size"] * grow, c, true, -1.0, true)
	for b in blasts:
		var k: float = b["t"] / b["life"]
		draw_circle(b["at"], b["radius"] * (0.3 + 0.7 * k), Color(1, 0.6, 0.25, 0.25 * (1.0 - k)), true, -1.0, true)
		draw_arc(b["at"], b["radius"] * (0.3 + 0.7 * k), 0, TAU, 32, Color(1, 0.8, 0.45, 1.0 - k), 0.8, true)
	for s in shots:
		_draw_shot(s)
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


## A line whose colour is strongest at the muzzle and fades out towards the target.
func _gradient_line(from: Vector2, to: Vector2, c: Color, width: float, strength: float = 1.0) -> void:
	var tail := Color(c.r, c.g, c.b, 0.0)
	var head := Color(c.r, c.g, c.b, c.a * strength)
	draw_polyline_colors(PackedVector2Array([from, to]), PackedColorArray([head, tail]), width, true)


func _draw_shot(s: Dictionary) -> void:
	var k: float = s["t"] / s["life"]
	var from: Vector2 = s["from"]
	var to: Vector2 = s["to"]
	var c: Color = s["color"]
	match s["kind"]:
		"cannon":
			var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 12.0)
			draw_circle(p, 1.4, Color("#1a1a22"), true, -1.0, true)
			draw_circle(p - Vector2(0.4, 0.4), 0.5, Color(1, 1, 1, 0.35), true, -1.0, true)
		"arcane", "chain":
			_draw_zigzag(from, to, c, s["seed"], 1.0 - k)
		"sniper":
			c.a = 1.0 - k
			_gradient_line(from, to, c, 1.0)
		"keep":
			# a firebolt: a hot white-yellow core with an orange trail
			var head := from.lerp(to, minf(k * 1.6, 1.0))
			var tail := from.lerp(to, maxf(k * 1.6 - 0.45, 0.0))
			draw_polyline_colors(PackedVector2Array([tail, head]), PackedColorArray([Color(1.0, 0.35, 0.05, 0.0), Color(1.0, 0.6, 0.1, 0.9)]), 1.6, true)
			draw_circle(head, 1.3, Color(1.0, 0.55, 0.1, 0.95), true, -1.0, true)
			draw_circle(head, 0.7, Color(1.0, 0.97, 0.75), true, -1.0, true)
		_:
			# a bright head flies to the target, trailing a fading line back to the muzzle
			var head := from.lerp(to, minf(k * 1.8, 1.0))
			c.a = 1.0 - maxf(k - 0.5, 0.0) * 2.0
			_gradient_line(head, from, c, 0.9)
			draw_circle(head, 0.8, Color(1, 1, 0.9, c.a), true, -1.0, true)


func _draw_zigzag(from: Vector2, to: Vector2, c: Color, seed_value: int, alpha: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var normal := (to - from).orthogonal().normalized()
	var points := PackedVector2Array([from])
	var colors := PackedColorArray([Color(c.r, c.g, c.b, alpha)])
	var steps := 6
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		if i < steps:
			p += normal * rng.randf_range(-3.0, 3.0)
		points.append(p)
		colors.append(Color(c.r, c.g, c.b, alpha * (1.0 - 0.6 * float(i) / steps)))
	draw_polyline_colors(points, colors, 1.0, true)
	draw_polyline_colors(points, PackedColorArray(Array(colors).map(func(x: Color) -> Color: return Color(1, 1, 1, x.a * 0.7))), 0.4, true)


func _draw_glow() -> void:
	for g in glows:
		_glow(g[0], g[1], g[2])
	for s in shots:
		var k: float = s["t"] / s["life"]
		var c: Color = s["color"]
		c.a = 0.6 * (1.0 - k)
		if s["kind"] == "cannon":
			_glow(s["from"], 12.0, Color(1, 0.6, 0.2, 0.55 * (1.0 - k)))
		else:
			_glow(s["from"], 7.0, c)
			_glow(s["to"], 5.0, c)
		if s["kind"] in ["arcane", "chain", "sniper", "keep"]:
			_glow(s["from"].lerp(s["to"], 0.35), 10.0, Color(c.r, c.g, c.b, c.a * 0.45))
	for b in blasts:
		var k: float = b["t"] / b["life"]
		_glow(b["at"], b["radius"] * 1.8, Color(1.0, 0.55, 0.15, 0.85 * (1.0 - k)))


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
