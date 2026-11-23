class_name FieldFx
extends Node2D
## Short-lived effects on the battlefield: musket tracers, cannon blasts, arcane lightning,
## pixel debris and floating "+$3" numbers. A child layer adds the glow (additive blending), so
## shots and magic light up the night.

const MAX_PARTICLES := 500
const GLOW_SIZE := 64

var shots: Array = []  ## {from, to, color, t, life, kind, seed}
var blasts: Array = []  ## {at, radius, t, life}
var particles: Array = []  ## {pos, vel, color, t, life, size}
var texts: Array = []  ## {pos, text, color, t, life}
var glows: Array = []  ## steady lights refreshed every frame by the view: [pos, radius, color]

var _glow_layer: Node2D
var _glow_tex: Texture2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_glow_tex = _make_glow_texture()
	_glow_layer = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_layer.material = mat
	_glow_layer.draw.connect(_draw_glow)
	add_child(_glow_layer)


func shot(from: Vector2, to: Vector2, kind: String) -> void:
	var life := 0.12
	match kind:
		"cannon": life = 0.22
		"sniper": life = 0.18
		"arcane", "chain": life = 0.16
	var color: Color = Pal.WEAPON_COLORS.get(kind, Pal.WEAPON_COLORS["arcane"])
	shots.append({"from": from, "to": to, "color": color, "t": 0.0, "life": life, "kind": kind, "seed": _rng.randi()})
	if kind in ["musket", "volley", "sniper"]:
		smoke(from, 2)


func blast(at: Vector2, radius: float) -> void:
	blasts.append({"at": at, "radius": radius, "t": 0.0, "life": 0.3})
	burst(at, Pal.ORANGE, 10, 40.0)
	smoke(at, 4)


func burst(at: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		if particles.size() >= MAX_PARTICLES:
			return
		var dir := Vector2.from_angle(_rng.randf() * TAU)
		particles.append({"pos": at, "vel": dir * _rng.randf_range(speed * 0.3, speed) + Vector2(0, -15),
			"color": color, "t": 0.0, "life": _rng.randf_range(0.25, 0.55), "size": 1.0, "gravity": 90.0})


func smoke(at: Vector2, count: int) -> void:
	for i in count:
		if particles.size() >= MAX_PARTICLES:
			return
		particles.append({"pos": at + Vector2(_rng.randf_range(-2, 2), _rng.randf_range(-2, 1)),
			"vel": Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-14, -6)), "color": Color(0.75, 0.75, 0.8, 0.7),
			"t": 0.0, "life": _rng.randf_range(0.4, 0.8), "size": 2.0, "gravity": 0.0})


func float_text(at: Vector2, text: String, color: Color, life: float = 0.8) -> void:
	texts.append({"pos": at, "text": text, "color": color, "t": 0.0, "life": life})


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
		c.a *= 1.0 - p["t"] / p["life"]
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"].floor(), Vector2(s, s)), c)
	for b in blasts:
		var k: float = b["t"] / b["life"]
		draw_arc(b["at"], b["radius"] * (0.4 + 0.6 * k), 0, TAU, 20, Color(1, 0.75, 0.35, 1.0 - k), 1.0)
	for s in shots:
		_draw_shot(s)
	var font := PixelFont.font()
	for t in texts:
		var k: float = t["t"] / t["life"]
		var pos: Vector2 = t["pos"] + Vector2(0, -10 * k)
		var c: Color = t["color"]
		c.a = 1.0 - maxf(k - 0.6, 0.0) / 0.4
		var w := PixelFont.text_width(t["text"], 1)
		var at := (pos - Vector2(w / 2.0, 0)).floor()
		draw_string(font, at + Vector2(1, 1), t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0, 0, 0, c.a))
		draw_string(font, at, t["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, c)


func _draw_shot(s: Dictionary) -> void:
	var k: float = s["t"] / s["life"]
	var from: Vector2 = s["from"]
	var to: Vector2 = s["to"]
	var c: Color = s["color"]
	match s["kind"]:
		"cannon":
			var p := from.lerp(to, k) + Vector2(0, -sin(k * PI) * 10.0)
			draw_rect(Rect2(p.floor() - Vector2(1, 1), Vector2(2, 2)), Color("#1a1a22"))
		"arcane", "chain":
			_draw_zigzag(from, to, c, s["seed"], 1.0 - k)
		"sniper":
			c.a = 1.0 - k
			draw_line(from, to, c, 1.0)
		_:
			# a short tracer flying from the muzzle to the target
			var head := from.lerp(to, minf(k * 1.6, 1.0))
			var tail := from.lerp(to, maxf(k * 1.6 - 0.35, 0.0))
			draw_line(tail, head, c, 1.0)


func _draw_zigzag(from: Vector2, to: Vector2, c: Color, seed_value: int, alpha: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var normal := (to - from).orthogonal().normalized()
	var prev := from
	var steps := 5
	c.a = alpha
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		if i < steps:
			p += normal * rng.randf_range(-3.0, 3.0)
		draw_line(prev, p, c, 1.0)
		prev = p


func _draw_glow() -> void:
	for g in glows:
		_glow(g[0], g[1], g[2])
	for s in shots:
		var k: float = s["t"] / s["life"]
		var c: Color = s["color"]
		c.a = 0.55 * (1.0 - k)
		if s["kind"] == "cannon":
			_glow(s["from"], 10.0, Color(1, 0.6, 0.2, 0.5 * (1.0 - k)))
		else:
			_glow(s["from"], 7.0, c)
			_glow(s["to"], 6.0, c)
		if s["kind"] in ["arcane", "chain", "sniper", "keep"]:
			_glow(s["from"].lerp(s["to"], 0.5), 9.0, Color(c.r, c.g, c.b, c.a * 0.5))
	for b in blasts:
		var k: float = b["t"] / b["life"]
		_glow(b["at"], b["radius"] * 1.6, Color(1.0, 0.55, 0.15, 0.8 * (1.0 - k)))


func _glow(at: Vector2, radius: float, color: Color) -> void:
	_glow_layer.draw_texture_rect(_glow_tex, Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


static func _make_glow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.35))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = GLOW_SIZE
	tex.height = GLOW_SIZE
	return tex
