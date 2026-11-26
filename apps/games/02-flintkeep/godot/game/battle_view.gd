class_name BattleView
extends Node2D
## Draws a Battle and runs it in real time, seen by a camera tilted about 50 degrees: the
## ground (and every circle on it) is squashed vertically into ellipses, while towers, walls and
## enemies stand upright, so the flat battlefield reads as a 3D scene.
## Battle works in flat field units (origin = the Keep); proj() turns those into the tilted
## view. Layers, back to front: ground, everything standing (sorted by depth), effects.

signal event(data: Dictionary)

const TILT := 0.6  ## How much the ground is squashed vertically (cos of the camera angle).
const MAX_STEP := 1.0 / 30.0
const TAP_RADIUS := 12.0
const SECTION_TAP := 8.0  ## How close (field units) to a wall line a tap must land.
const MARGIN := 26.0  ## Field units of open ground kept around the outermost wall.
const HEADROOM := 34.0  ## Room above the fortress for tall towers (screen field units).

var battle: Battle
var speed := 1.0
var paused := false
var selected_slot := -1
var selected_section := Vector2i(-1, -1)
var hint_slot := -1  ## The tutorial points a bouncing arrow at this slot.
var zoom := 3.0
var field_size := Vector2(180, 200)  ## Visible area in (screen) field units.

var fx: FieldFx
var _ground: Node2D
var _things: Node2D
var _time := 0.0
var _soft: Texture2D
var _vignette: Texture2D
var _grass: Texture2D
var _decor: Array = []  ## [field position, sprite name], scattered once per layout


static func proj(p: Vector2) -> Vector2:
	return Vector2(p.x, p.y * TILT)


func _ready() -> void:
	_soft = FieldFx.soft_disc()
	_vignette = _make_vignette()
	_grass = _make_grass()
	_ground = Node2D.new()
	_ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ground.scale = Vector2(1.0, TILT)  # the ground is drawn flat and squashed by the camera tilt
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
	zoom = clampf(minf(area.x / (2.0 * outer), area.y / (2.0 * outer * TILT + HEADROOM)), 1.4, 4.5)
	scale = Vector2(zoom, zoom)
	position = area / 2.0 + Vector2(0, HEADROOM * 0.35 * zoom)
	var size := area / zoom
	if size != field_size or _decor.is_empty():
		field_size = size
		_scatter_decor()


## Local (screen) point to flat field coordinates.
func to_field(local: Vector2) -> Vector2:
	var p := (local - position) / zoom
	return Vector2(p.x, p.y / TILT)


func _process(delta: float) -> void:
	_time += delta
	if battle != null:
		battle.spawn_extents = Vector2(field_size.x / 2.0, field_size.y / 2.0 / TILT)
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


## The open build slot under a local point, or -1. Compares on screen, where towers stand.
func slot_at(local: Vector2) -> int:
	var screen := (local - position) / zoom
	var best := -1
	var best_d := TAP_RADIUS
	for slot in battle.slots:
		if not battle.slot_open(slot.index):
			continue
		var d := (proj(slot.pos) + Vector2(0, -WallDrawer.HEIGHT - 3.0)).distance_to(screen)
		if d < best_d:
			best_d = d
			best = slot.index
	return best


## The wall section (ring, segment) under a local point, or (-1, -1).
func section_at(local: Vector2) -> Vector2i:
	var p := to_field(local)
	var r := p.length()
	for ring in range(1, battle.rings_unlocked + 1):
		if absf(r - battle.wall_radius(ring)) <= SECTION_TAP:
			return Vector2i(ring, Battle.wall_segment(ring, p.angle()))
	return Vector2i(-1, -1)


func _on_event(e: Dictionary) -> void:
	match e["type"]:
		"shot":
			fx.shot(_muzzle(e), proj(e["to"]) + Vector2(0, -3), e["weapon"])
			Sfx.play(e["weapon"], 0.08)
		"chain":
			fx.shot(proj(e["from"]) + Vector2(0, -3), proj(e["to"]) + Vector2(0, -3), "chain")
		"blast":
			fx.blast(proj(e["at"]), e["radius"])
		"kill":
			Sfx.play("coin" if e["boss"] else "kill", 0.1)
			var at := proj(e["pos"])
			fx.burst(at + Vector2(0, -3), Pal.RED if not e["boss"] else Pal.ORANGE, 14 if e["boss"] else 6, 30.0)
			fx.float_text(at + Vector2(0, -10), "+" + Num.cash(e["cash"]), Pal.CASH)
			if e["boss"]:
				fx.float_text(at + Vector2(0, -20), "+%s coins" % Num.fmt(e["coins"]), Pal.GOLD, 1.8, 9)
		"wall_broken":
			Sfx.play("wall_break")
			var at := proj(Vector2.from_angle(Battle.section_angle(e["ring"], e["segment"])) * battle.wall_radius(e["ring"]))
			fx.burst(at + Vector2(0, -3), Color("#cfc8e6"), 12, 25.0)
			fx.smoke(at, 5)
		"wall_built":
			if e.has("segment"):
				var at := proj(Vector2.from_angle(Battle.section_angle(e["ring"], e["segment"])) * battle.wall_radius(e["ring"]))
				fx.burst(at + Vector2(0, -4), Color("#ffffff"), 10, 22.0)
				Sfx.play("build", 0.0)
		"fortified":
			Sfx.play("upgrade", 0.0)
			fx.float_text(proj(Vector2(0, -battle.wall_radius(e["ring"]))) + Vector2(0, -12), "Ring %d fortified!" % e["ring"], Pal.GOLD, 2.2, 8)
		"built", "upgraded":
			Sfx.play("build" if e["type"] == "built" else "upgrade", 0.0)
			var slot: Entities.Slot = battle.slots[e["slot"]]
			fx.burst(proj(slot.pos) + Vector2(0, -WallDrawer.HEIGHT - 8.0), Pal.GOLD, 12, 28.0)
	event.emit(e)


## Where a shot leaves: near the top of the tower (or the Keep's crystal).
func _muzzle(e: Dictionary) -> Vector2:
	if e["weapon"] == "keep":
		var r := Art.rect("keep", Vector2.ZERO)
		return r.position + r.size * Vector2(0.5, 0.12)
	return proj(e["from"]) + Vector2(0, -WallDrawer.HEIGHT - Art.height(e["weapon"]) * 0.62)


func _update_lights() -> void:
	fx.glows.clear()
	if battle == null:
		return
	var pulse := 0.8 + 0.2 * sin(_time * 3.0)
	var keep := Art.rect("keep", Vector2.ZERO)
	fx.glows.append([keep.position + keep.size * Vector2(0.5, 0.12), 14.0 * pulse, Color(0.44, 0.89, 1.0, 0.5)])
	for slot in battle.slots:
		if slot.tower != null and slot.tower.weapon == "arcane":
			var r := Art.rect("arcane", proj(slot.pos) + Vector2(0, 1.5 - WallDrawer.HEIGHT))
			fx.glows.append([r.position + r.size * Vector2(0.5, 0.19), 9.0 * pulse, Color(0.78, 0.6, 1.0, 0.55)])


# --- Ground (drawn flat; the layer is squashed by TILT) ----------------------------------------------

func _draw_ground() -> void:
	if battle == null:
		return
	var half := Vector2(field_size.x / 2.0 + 4.0, field_size.y / 2.0 / TILT + 20.0)
	var area := Rect2(-half, half * 2.0)
	var tile := 26.0 / GRASS_TILE
	_ground.draw_set_transform(Vector2.ZERO, 0.0, Vector2(tile, tile))
	_ground.draw_texture_rect(_grass, Rect2(area.position / tile, area.size / tile), true)
	_ground.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the courtyard: warm sand, strongest at the Keep and fading out past the outer wall
	var yard := battle.wall_radius(battle.rings_unlocked) + 20.0
	_ground.draw_texture_rect(_soft, Rect2(Vector2(-yard, -yard), Vector2(yard, yard) * 2.0), false, Color(Pal.SAND, 1.0))
	_ground.draw_texture_rect(_soft, Rect2(Vector2(-yard, -yard) * 0.7, Vector2(yard, yard) * 1.4), false, Color(Pal.SAND, 0.85))
	for ring in range(1, Defs.MAX_RING + 1):
		var r: float = Defs.RING_RADII[ring]
		if ring <= battle.rings_unlocked:
			_ground.draw_arc(Vector2.ZERO, r, 0, TAU, 128, Color(Pal.PATH, 0.9), 9.0, true)
			_draw_wall_plan(ring)
		else:
			_ground.draw_arc(Vector2.ZERO, r, 0, TAU, 128, Color(1, 1, 1, 0.12), 0.8, true)
	_draw_range()
	_ground.draw_texture_rect(_vignette, area, false)


## Unbuilt wall sections show as dashed foundations; the selected one glows.
func _draw_wall_plan(ring: int) -> void:
	var wall: Entities.Wall = battle.walls[ring]
	var r := battle.wall_radius(ring)
	var count: int = Defs.SLOT_COUNTS[ring]
	var step := TAU / count
	var affordable := battle.cash >= battle.section_cost(ring)
	for seg in count:
		var a0 := Defs.ring_angle_offset(ring) + step * seg
		var selected := selected_section == Vector2i(ring, seg)
		if selected:
			var pulse := 0.6 + 0.4 * sin(_time * 6.0)
			_ground.draw_arc(Vector2.ZERO, r, a0 + 0.06, a0 + step - 0.06, 32, Color(1.0, 0.95, 0.5, 0.75 * pulse), 9.0, true)
		if wall.sections[seg]:
			continue
		var dashes := maxi(int(step * r / 4.0), 3)
		var c := Color(1, 1, 1, 0.75 if affordable else 0.4)
		for k in dashes:
			if k % 2 == 1:
				continue
			var d0 := a0 + 0.08 + (step - 0.16) * k / dashes
			var d1 := a0 + 0.08 + (step - 0.16) * (k + 1) / dashes
			_ground.draw_arc(Vector2.ZERO, r, d0, d1, 4, c, 1.6, true)


func _draw_range() -> void:
	if selected_slot < 0:
		return
	var slot: Entities.Slot = battle.slots[selected_slot]
	var pulse := 0.7 + 0.3 * sin(_time * 5.0)
	if slot.tower != null:
		var reach := battle.tower_range(slot.tower)
		# strongest at the tower, fading towards the edge of its reach
		_ground.draw_texture_rect(_soft, Rect2(slot.pos - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, Color(1.0, 1.0, 1.0, 0.45))
		_ground.draw_arc(slot.pos, reach, 0, TAU, 96, Color(1, 1, 1, 0.9), 1.0, true)
	_ground.draw_texture_rect(_soft, Rect2(slot.pos - Vector2(14, 14), Vector2(28, 28)), false, Color(1.0, 0.95, 0.5, 0.8 * pulse))


# --- Everything standing, sorted back to front -------------------------------------------------------

func _draw_things() -> void:
	if battle == null:
		return
	var items: Array = []  # [depth, Callable]
	items.append([0.0, _draw_keep])
	var cheapest := _cheapest_build()
	for slot in battle.slots:
		if battle.slot_open(slot.index):
			items.append([slot.pos.y * TILT + 2.5, _draw_slot.bind(slot, cheapest)])
	WallDrawer.add(items, battle, _things)
	for d in _decor:
		var p: Vector2 = d[0]
		items.append([p.y * TILT, _draw_decor.bind(p, d[1])])
	for e in battle.enemies:
		items.append([e.pos().y * TILT + (60.0 if e.air else 0.5), _draw_enemy.bind(e)])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for item in items:
		(item[1] as Callable).call()
	_draw_hint()


func _scatter_decor() -> void:
	_decor.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var keep_clear := battle.wall_radius(battle.rings_unlocked) + 12.0
	var hx := field_size.x / 2.0
	var hy := field_size.y / 2.0 / TILT
	var names := ["decor_bush", "decor_bush", "decor_tuft", "decor_tuft", "decor_tuft", "decor_flowers", "decor_rock", "decor_mushroom"]
	for i in 70:
		var p := Vector2(rng.randf_range(-hx, hx), rng.randf_range(-hy, hy))
		if p.length() < keep_clear:
			continue
		_decor.append([p, names[rng.randi() % names.size()]])


func _draw_decor(p: Vector2, name: String) -> void:
	_things.draw_texture_rect(Art.tex(name), Art.rect(name, proj(p)), false)


func _draw_hint() -> void:
	if hint_slot < 0 or hint_slot == selected_slot:
		return
	var tip: Vector2 = proj(battle.slots[hint_slot].pos) + Vector2(0, -WallDrawer.HEIGHT - 6.0 - absf(sin(_time * 4.0)) * 4.0)
	var arrow := PackedVector2Array([tip, tip + Vector2(-4, -5), tip + Vector2(-1.6, -5), tip + Vector2(-1.6, -10),
		tip + Vector2(1.6, -10), tip + Vector2(1.6, -5), tip + Vector2(4, -5)])
	var outline := arrow.duplicate()
	outline.append(tip)
	_things.draw_colored_polygon(arrow, Pal.GOLD)
	_things.draw_polyline(outline, Pal.INK, 0.7, true)


func _cheapest_build() -> float:
	var best := INF
	for weapon in Defs.WEAPON_ORDER:
		if battle.weapon_unlocked(weapon):
			best = minf(best, battle.build_cost(weapon))
	return best


func _draw_keep() -> void:
	var r := Art.rect("keep", Vector2.ZERO)
	if battle.keep_fired < 0.08:
		r.position.y += 0.5
	_things.draw_texture_rect(Art.tex("keep"), r, false)


## Every slot is a stone pedestal as tall as the walls; its tower stands on top.
func _draw_slot(slot: Entities.Slot, cheapest: float) -> void:
	var at := proj(slot.pos)
	var plate := Art.rect("slot", at)
	var top := at + Vector2(0, -WallDrawer.HEIGHT)
	var lit := slot.index == selected_slot or (slot.tower == null and battle.cash >= cheapest)
	_things.draw_texture_rect(Art.tex("slot"), plate, false, Color(1.12, 1.07, 0.92) if lit else Color.WHITE)
	if slot.tower == null:
		if battle.cash >= cheapest and slot.index != selected_slot:
			var a := 0.4 + 0.3 * sin(_time * 3.0 + slot.index)
			_things.draw_set_transform(top, 0.0, Vector2(1.0, TILT))
			_things.draw_arc(Vector2.ZERO, 9.0, 0, TAU, 40, Color(1.0, 1.0, 0.7, a), 1.0, true)
			_things.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var name := tower_sprite(slot.tower)
	var r := Art.rect(name, top + Vector2(0, 1.5))
	if slot.tower.fired < 0.08:
		r.position.y += 0.6
	_things.draw_texture_rect(Art.tex(name), r, false)
	_draw_badge(top + Vector2(8, 1), str(slot.tower.level))


## Towers look grander as they level: a new detail at level 5 and again at level 10.
static func tower_sprite(tower: Entities.Tower) -> String:
	if tower.level >= 10:
		return tower.weapon + "_3"
	if tower.level >= 5:
		return tower.weapon + "_2"
	return tower.weapon


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
		_badge.border_color = Pal.INK
		_badge.set_border_width_all(0)
		_badge.set_corner_radius_all(3)
		_badge.anti_aliasing = true
	return _badge


func _draw_enemy(e: Entities.Enemy) -> void:
	var name := e.kind
	if e.kind == "wyvern":
		name = "wyvern_b" if int(e.age * 6.0) % 2 == 1 else "wyvern"
	elif not e.air and e.attacking == -1 and Art.WALKERS.has(e.kind) and int(e.age * 6.0) % 2 == 1:
		name = e.kind + "_b"  # second walking frame
	var p := proj(e.pos())
	var lift := 0.0
	if e.air:
		lift = 16.0 + sin(e.age * 3.0) * 1.5
		_things.draw_texture_rect(_soft, Rect2(p + Vector2(-4, -1.2), Vector2(8, 2.6)), false, Color(0.05, 0.25, 0.1, 0.45))
	else:
		_things.draw_texture_rect(_soft, Rect2(p + Vector2(-3.5, -1.0), Vector2(7, 2.2)), false, Color(0.05, 0.25, 0.1, 0.35))
		if e.attacking == -1:
			lift = absf(sin(e.age * 9.0)) * 0.7
	var r := Art.rect(name, p + Vector2(0, 0.5 - lift))
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
		_things.draw_rect(bar.grow(0.4), Pal.INK)
		_things.draw_rect(Rect2(bar.position, Vector2(w * e.hp / e.max_hp, 1.1)), Pal.RED if not e.boss else Pal.ORANGE)


# --- Textures ---------------------------------------------------------------------------------

static func _make_vignette() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.05, 0.2, 0.1, 0.4))
	g.add_point(0.6, Color(0, 0, 0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


const GRASS_TILE := 64


## A meadow tile: soft checker diamonds (which the tilt turns into isometric tiles) with a
## little speckle so the grass is not flat.
static func _make_grass() -> Texture2D:
	var img := Image.create(GRASS_TILE, GRASS_TILE, false, Image.FORMAT_RGBA8)
	var half := GRASS_TILE / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in GRASS_TILE:
		for x in GRASS_TILE:
			var d := absf(x + 0.5 - half) + absf(y + 0.5 - half)
			var c := Pal.GRASS_LIGHT if d < half * 0.92 else Pal.GRASS
			if absf(d - half * 0.92) < 1.2:
				c = c.lerp(Pal.GRASS_DARK, 0.2)
			var n := rng.randf()
			if n < 0.06:
				c = c.lightened(0.07)
			elif n < 0.12:
				c = c.darkened(0.05)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
