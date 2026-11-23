class_name BattleView
extends Node2D
## Draws a Battle and runs it in real time. Works in field units (origin = the Keep) and is
## scaled to fit its area: close up while the fortress is small, zooming out as rings unlock.
## Layers, back to front: ground, the fortress and everything on it (sorted by depth), effects.

signal event(data: Dictionary)

const MAX_STEP := 1.0 / 30.0
const TAP_RADIUS := 13.0
const KEEP_FOOT := Vector2(0, 13)
const MARGIN := 30.0  ## Field units of open ground kept around the outermost wall.

var battle: Battle
var speed := 1.0
var paused := false
var selected_slot := -1
var zoom := 3.0
var field_size := Vector2(180, 200)  ## Visible area in field units.

var fx: FieldFx
var _ground: Node2D
var _things: Node2D
var _time := 0.0
var _soft: Texture2D
var _vignette: Texture2D
var _grass: NoiseTexture2D


func _ready() -> void:
	_soft = FieldFx.soft_disc()
	_vignette = _make_vignette()
	_grass = _make_grass()
	_ground = Node2D.new()
	_ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	_things = Node2D.new()
	_things.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_things.draw.connect(_draw_things)
	add_child(_things)
	fx = FieldFx.new()
	add_child(fx)


func setup(p_battle: Battle) -> void:
	battle = p_battle


## Fits the field into an area of `area` pixels (called by the screen every frame).
func layout(area: Vector2) -> void:
	if battle == null or area.x <= 0.0:
		return
	var outer := battle.wall_radius(battle.rings_unlocked) + MARGIN
	zoom = clampf(minf(area.x, area.y) / (2.0 * outer), 1.5, 4.0)
	scale = Vector2(zoom, zoom)
	position = area / 2.0 + Vector2(0, 4.0 * zoom)
	field_size = area / zoom


func to_field(local: Vector2) -> Vector2:
	return (local - position) / zoom


func _process(delta: float) -> void:
	_time += delta
	if battle != null:
		battle.spawn_extents = field_size / 2.0
		if not paused:
			var left := delta * speed
			while left > 0.0:
				var dt := minf(left, MAX_STEP)
				battle.step(dt)
				left -= dt
		for e in battle.drain_events():
			_on_event(e)
	fx.tick(0.0 if paused else delta)
	_update_lights()
	_ground.queue_redraw()
	_things.queue_redraw()


## The open build slot under a point in field coordinates, or -1.
func slot_at(field_pos: Vector2) -> int:
	var best := -1
	var best_d := TAP_RADIUS
	for slot in battle.slots:
		if not battle.slot_open(slot.index):
			continue
		var d := (slot.pos + Vector2(0, -4)).distance_to(field_pos)
		if d < best_d:
			best_d = d
			best = slot.index
	return best


func _on_event(e: Dictionary) -> void:
	match e["type"]:
		"shot":
			fx.shot(_muzzle(e), e["to"], e["weapon"])
		"chain":
			fx.shot(e["from"], e["to"], "chain")
		"blast":
			fx.blast(e["at"], e["radius"])
		"kill":
			fx.burst(e["pos"], Pal.RED if not e["boss"] else Pal.ORANGE, 14 if e["boss"] else 6, 30.0)
			fx.float_text(e["pos"] + Vector2(0, -8), "+" + Num.cash(e["cash"]), Pal.CASH)
			if e["boss"]:
				fx.float_text(e["pos"] + Vector2(0, -18), "+%s coins" % Num.fmt(e["coins"]), Pal.GOLD, 1.8, 9)
		"wall_broken":
			var angle: float = Defs.ring_angle_offset(e["ring"]) + TAU * e["segment"] / Defs.SLOT_COUNTS[e["ring"]]
			var at: Vector2 = Vector2.from_angle(angle) * battle.wall_radius(e["ring"])
			fx.burst(at, Color("#9c968a"), 12, 25.0)
			fx.smoke(at, 5)
		"built", "upgraded":
			var slot: Entities.Slot = battle.slots[e["slot"]]
			fx.burst(slot.pos + Vector2(0, -6), Pal.GOLD, 12, 28.0)
	event.emit(e)


## Where a tower's shot leaves: near the top of its sprite.
func _muzzle(e: Dictionary) -> Vector2:
	if e["weapon"] == "keep":
		var r := Art.rect("keep", KEEP_FOOT)
		return r.position + r.size * Vector2(0.5, 0.12)
	return e["from"] + Vector2(0, -Art.height(e["weapon"]) * 0.62)


func _update_lights() -> void:
	fx.glows.clear()
	if battle == null:
		return
	var pulse := 0.8 + 0.2 * sin(_time * 3.0)
	var keep := Art.rect("keep", KEEP_FOOT)
	fx.glows.append([keep.position + keep.size * Vector2(0.5, 0.12), 14.0 * pulse, Color(0.44, 0.89, 1.0, 0.5)])
	for slot in battle.slots:
		if slot.tower != null and slot.tower.weapon == "arcane":
			var r := Art.rect("arcane", slot.pos + Vector2(0, 2))
			fx.glows.append([r.position + r.size * Vector2(0.5, 0.19), 9.0 * pulse, Color(0.78, 0.6, 1.0, 0.55)])


# --- Ground ------------------------------------------------------------------------------------

func _draw_ground() -> void:
	if battle == null:
		return
	var half := field_size / 2.0 + Vector2(4, 12)
	var area := Rect2(-half, half * 2.0)
	_ground.draw_rect(area, Pal.GRASS_DARK)
	if _grass.get_image() != null:
		var tile := 0.25  # one noise texel = a quarter field unit
		_ground.draw_set_transform(Vector2.ZERO, 0.0, Vector2(tile, tile))
		_ground.draw_texture_rect(_grass, Rect2(area.position / tile, area.size / tile), true)
		_ground.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the courtyard: packed earth, strongest at the Keep and fading out past the outer wall
	var yard := battle.wall_radius(battle.rings_unlocked) + 16.0
	_ground.draw_texture_rect(_soft, Rect2(Vector2(-yard, -yard), Vector2(yard, yard) * 2.0), false, Color(Pal.EARTH, 0.95))
	# worn paths along each ring, and faint guides for rings still to come
	for ring in range(1, Defs.MAX_RING + 1):
		var r: float = Defs.RING_RADII[ring]
		var open := ring <= battle.rings_unlocked
		var c := Color(0.08, 0.05, 0.02, 0.22) if open else Color(1, 1, 1, 0.05)
		_ground.draw_arc(Vector2.ZERO, r, 0, TAU, 96, c, 5.0 if open else 0.6, true)
	_draw_range()
	_ground.draw_texture_rect(_vignette, area, false)


func _draw_range() -> void:
	if selected_slot < 0:
		return
	var slot: Entities.Slot = battle.slots[selected_slot]
	var pulse := 0.7 + 0.3 * sin(_time * 5.0)
	if slot.tower != null:
		var reach := battle.tower_range(slot.tower)
		# strongest at the tower, fading towards the edge of its reach
		_ground.draw_texture_rect(_soft, Rect2(slot.pos - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, Color(0.44, 0.89, 1.0, 0.32))
		_ground.draw_arc(slot.pos, reach, 0, TAU, 96, Color(0.44, 0.89, 1.0, 0.7), 0.6, true)
	_ground.draw_texture_rect(_soft, Rect2(slot.pos - Vector2(14, 9), Vector2(28, 18)), false, Color(1.0, 0.85, 0.4, 0.55 * pulse))


# --- Fortress, towers and enemies ----------------------------------------------------------------

func _draw_things() -> void:
	if battle == null:
		return
	var items: Array = []  # [depth, Callable], drawn back to front
	items.append([KEEP_FOOT.y, _draw_keep])
	var cheapest := _cheapest_build()
	for slot in battle.slots:
		if battle.slot_open(slot.index):
			items.append([slot.pos.y + 2.0, _draw_slot.bind(slot, cheapest)])
	WallDrawer.add(items, battle, _things)
	for e in battle.enemies:
		items.append([e.pos().y + (60.0 if e.air else 0.5), _draw_enemy.bind(e)])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for item in items:
		(item[1] as Callable).call()


func _cheapest_build() -> float:
	var best := INF
	for weapon in Defs.WEAPON_ORDER:
		if battle.weapon_unlocked(weapon):
			best = minf(best, battle.build_cost(weapon))
	return best


func _draw_keep() -> void:
	var r := Art.rect("keep", KEEP_FOOT)
	if battle.keep_fired < 0.08:
		r.position.y += 0.5
	_things.draw_texture_rect(Art.tex("keep"), r, false)


func _draw_slot(slot: Entities.Slot, cheapest: float) -> void:
	if slot.tower == null:
		var plate := Art.rect("slot", slot.pos)
		var glow := slot.index == selected_slot or battle.cash >= cheapest
		var tint := Color(1.15, 1.08, 0.9) if glow else Color(0.8, 0.8, 0.8)
		_things.draw_texture_rect(Art.tex("slot"), plate, false, tint)
		if battle.cash >= cheapest and slot.index != selected_slot:
			var a := 0.25 + 0.2 * sin(_time * 3.0 + slot.index)
			_things.draw_arc(slot.pos, 9.0, 0, TAU, 40, Color(1.0, 0.85, 0.4, a), 0.6, true)
		return
	var name := slot.tower.weapon
	var r := Art.rect(name, slot.pos + Vector2(0, 2))
	if slot.tower.fired < 0.08:
		r.position.y += 0.6
	_things.draw_texture_rect(Art.tex(name), r, false)
	_draw_badge(slot.pos + Vector2(8, -1), str(slot.tower.level))


func _draw_badge(at: Vector2, text: String) -> void:
	var font := Fonts.field()
	var fs := 5
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var box := Rect2(at - Vector2(w / 2.0 + 1.6, 3.2), Vector2(w + 3.2, 5.0))
	_things.draw_style_box(_badge_box(), box)
	_things.draw_string(font, Vector2(at.x - w / 2.0, at.y + 0.9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.INK)


var _badge: StyleBoxFlat


func _badge_box() -> StyleBoxFlat:
	if _badge == null:
		_badge = StyleBoxFlat.new()
		_badge.bg_color = Pal.GOLD
		_badge.border_color = Color("#7a5512")
		_badge.set_border_width_all(0)
		_badge.set_corner_radius_all(3)
		_badge.anti_aliasing = true
	return _badge


func _draw_enemy(e: Entities.Enemy) -> void:
	var name := e.kind
	if e.kind == "wyvern" and int(e.age * 6.0) % 2 == 1:
		name = "wyvern_b"
	var p := e.pos()
	var lift := 0.0
	if e.air:
		lift = 14.0 + sin(e.age * 3.0) * 1.5
		_things.draw_texture_rect(_soft, Rect2(p + Vector2(-4, -1.2), Vector2(8, 2.6)), false, Color(0, 0, 0, 0.45))
	elif e.attacking == -1:
		lift = absf(sin(e.age * 9.0)) * 0.8
	var r := Art.rect(name, p + Vector2(0, 1.5 - lift))
	if e.attacking >= 0:
		r.position += Vector2.from_angle(e.angle + PI) * (0.6 if int(e.age * 8.0) % 2 == 0 else 0.0)
	var tint := Color(2.2, 2.2, 2.2) if e.hit_flash > 0.0 else Color.WHITE
	if p.x > 0.0:  # face the Keep
		r.position.x += r.size.x
		r.size.x = -r.size.x
	_things.draw_texture_rect(Art.tex(name), r, false, tint)
	if e.hp < e.max_hp:
		var w := maxf(absf(r.size.x) * 0.8, 6.0)
		var top := minf(r.position.y, r.end.y) - 2.0
		var bar := Rect2(Vector2(p.x - w / 2.0, top), Vector2(w, 1.1))
		_things.draw_rect(bar.grow(0.35), Color(0, 0, 0, 0.75))
		_things.draw_rect(Rect2(bar.position, Vector2(w * e.hp / e.max_hp, 1.1)), Pal.RED if not e.boss else Pal.ORANGE)


# --- Textures ---------------------------------------------------------------------------------

static func _make_vignette() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.02, 0.03, 0.05, 0.75))
	g.add_point(0.55, Color(0, 0, 0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


static func _make_grass() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	var ramp := Gradient.new()
	ramp.set_color(0, Pal.GRASS_DARK)
	ramp.set_color(1, Pal.GRASS_LIGHT)
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = ramp
	return tex
