class_name BattleView
extends Node2D
## Draws a Battle and runs it in real time, seen by a camera tilted about 50 degrees: the
## ground (and every circle on it) is squashed vertically into ellipses, while towers, walls and
## enemies stand upright, so the flat battlefield reads as a 3D scene.
## Battle works in flat field units (origin = the Keep); proj() turns those into the tilted
## view. Layers, back to front: ground, selection marks, everything standing (y-sorted Stand
## and EnemySprite nodes), the tutorial arrow, effects.
##
## Drawing is the expensive part on phones, so nothing is redrawn every frame unless it moves:
## the ground redraws when the fortress or a selection changes, each wall piece and tower when it
## changes, and enemies are sprites that only move.

signal event(data: Dictionary)

const TILT := 0.6  ## How much the ground is squashed vertically (cos of the camera angle).
const MAX_STEP := 1.0 / 30.0
const TAP_RADIUS := 16.0
const SECTION_TAP := 11.0  ## How close (field units) to a wall line a tap must land.
const MARGIN := 26.0  ## Field units of open ground kept around the outermost wall.
const HEADROOM := 34.0  ## Room above the fortress for tall towers (screen field units).

var battle: Battle
var speed := 1.0
var paused := false
var selected_slot := -1
var selected_section := Vector2i(-1, -1)
var hint_slot := -1  ## The tutorial points a bouncing arrow at this slot.
var day_mode := "cycle"  ## time of day, see DayNight.MODES (the screen sets it from the profile)
var zoom := 3.0
var field_size := Vector2(180, 200)  ## Visible area in (screen) field units.

var fx: FieldFx
var _ground: Node2D
var _shadows: Node2D  ## sun shadows of the Keep and towers (flat, squashed like the ground)
var _haze: Node2D  ## a coloured haze at the field's edges at dawn, dusk and night
var _look: Dictionary = DayNight.look(0.3)
var _shadow_key: Array = []
var _visible_rect := Rect2()
var _haze_tex: Texture2D
var _fireflies: Array = []  ## [field position, speed, phase] for night sparkles
var _marks: Node2D  ## pulsing selection marks on the ground (drawn only while something is selected)
var _things: Node2D  ## y-sorted: Stands and EnemySprites
var _top: Node2D  ## the tutorial arrow
var _ground_key: Array = []
var _wall_key: Array = []
var _wall_pieces: Array = []  ## [ring, segment, Stand]
var _slot_stands: Dictionary = {}  ## slot index -> Stand
var _slot_rings := -1
var _keep_stand: Stand
var _decor_stands: Array[Stand] = []
var _enemy_sprites: Dictionary = {}  ## enemy id -> EnemySprite
var _spare_sprites: Array[EnemySprite] = []
var _seen_frame := 0
var _time := 0.0
var _soft: Texture2D
var _rim: Texture2D  ## clear centre, whitish towards the edge (range circles)
var _vignette: Texture2D
var _grass: Texture2D
var _decor: Array = []  ## [field position, sprite name], scattered once per layout
var _shake := 0.0  ## screen shake strength, decays quickly
var _base_position := Vector2.ZERO


static func proj(p: Vector2) -> Vector2:
	return Vector2(p.x, p.y * TILT)


func _ready() -> void:
	_soft = FieldFx.soft_disc()
	_rim = _make_rim()
	_vignette = _make_vignette()
	_grass = _make_grass()
	_ground = Node2D.new()
	_ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ground.scale = Vector2(1.0, TILT)  # the ground is drawn flat and squashed by the camera tilt
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	_shadows = Node2D.new()
	_shadows.scale = Vector2(1.0, TILT)
	_shadows.draw.connect(_draw_shadows)
	add_child(_shadows)
	_haze_tex = _make_haze()
	_marks = Node2D.new()
	_marks.scale = Vector2(1.0, TILT)
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	_things = Node2D.new()
	_things.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_things.y_sort_enabled = true
	add_child(_things)
	_keep_stand = Stand.new(0.0, _draw_keep)
	_things.add_child(_keep_stand)
	_top = Node2D.new()
	_top.draw.connect(_draw_hint)
	add_child(_top)
	_haze = Node2D.new()
	_haze.draw.connect(_draw_haze)
	add_child(_haze)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 26:
		_fireflies.append([Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)), rng.randf_range(0.2, 0.6), rng.randf() * TAU])
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
	_base_position = area / 2.0 + Vector2(0, HEADROOM * 0.35 * zoom)
	position = _base_position + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * zoom
	var size := area / zoom
	var visible := Rect2(-_base_position / zoom, area / zoom)
	if visible != _visible_rect:
		_visible_rect = visible
		_haze.queue_redraw()
	if size != field_size or _decor.is_empty():
		field_size = size
		_scatter_decor()


## Local (screen) point to flat field coordinates.
func to_field(local: Vector2) -> Vector2:
	var p := (local - _base_position) / zoom
	return Vector2(p.x, p.y / TILT)


func _process(delta: float) -> void:
	_time += delta
	_shake = maxf(_shake - delta * 6.0, 0.0)
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
	_update_day()
	_update_lights()
	_refresh_field()


## Time of day: tints the ground and everything standing (effects stay untinted, so shots and
## lights glow brighter at night), tints the edge haze, and redraws shadows when the sun moves.
func _update_day() -> void:
	var now := Time.get_unix_time_from_system()
	var clock := Time.get_time_dict_from_system()
	var hour := float(clock["hour"]) + float(clock["minute"]) / 60.0
	_look = DayNight.look(DayNight.phase(day_mode, now, hour))
	var tint: Color = _look["tint"]
	_ground.modulate = tint
	_things.modulate = tint
	_shadows.modulate = Color(1, 1, 1, 1)
	var haze: Color = _look["haze"]
	_haze.modulate = haze
	_haze.visible = haze.a > 0.01
	if battle == null:
		return
	var sun: Dictionary = _look["sun"]
	var dir: Vector2 = sun["dir"]
	var towers: Array = []
	for slot in battle.slots:
		if slot.tower != null and battle.slot_open(slot.index):
			towers.append(slot.index)
	var key := [snappedf(dir.angle(), 0.02), snappedf(sun["height"], 0.03), sun["strength"], towers]
	if key != _shadow_key:
		_shadow_key = key
		_shadows.queue_redraw()


## Long soft shadows on the ground, pointing away from the sun (short at noon, long at dawn and
## dusk, faint under the moon).
func _draw_shadows() -> void:
	if battle == null:
		return
	var sun: Dictionary = _look["sun"]
	var away: Vector2 = -(sun["dir"] as Vector2)
	var reach := 0.6 + 2.4 * (1.0 - float(sun["height"]))
	var color := Color(0.02, 0.12, 0.05, 0.34 * float(sun["strength"]))
	_shadow(Vector2.ZERO, 15.0, reach, away, color)
	for slot in battle.slots:
		if slot.tower != null and battle.slot_open(slot.index):
			_shadow(slot.pos, 7.0, reach, away, color)


func _shadow(at: Vector2, size: float, reach: float, away: Vector2, color: Color) -> void:
	var length := size * (1.0 + reach)
	_shadows.draw_set_transform(at + away * (length * 0.5 - size * 0.4), away.angle(), Vector2.ONE)
	_shadows.draw_texture_rect(_soft, Rect2(Vector2(-length / 2.0, -size * 0.55), Vector2(length, size * 1.1)), false, color)
	_shadows.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_haze() -> void:
	_haze.draw_texture_rect(_haze_tex, _visible_rect, false)


func night_amount() -> float:
	return _look["night"]


## How warm the light is (dawn and dusk), 0-1, for the sun icon.
func warmth() -> float:
	var tint: Color = _look["tint"]
	return clampf((tint.r - tint.b) * 2.5, 0.0, 1.0) if float(_look["night"]) < 0.5 else 0.0


## Redraws only what changed since the last frame (see the class comment).
func _refresh_field() -> void:
	if battle == null:
		return
	var wall_key := WallDrawer.layout_key(battle)
	if wall_key != _wall_key:
		_wall_key = wall_key
		for item in _wall_pieces:
			(item[2] as Stand).queue_free()
		_wall_pieces = WallDrawer.build(battle, _things)
	var ground_key := _make_ground_key()
	if ground_key != _ground_key:
		_ground_key = ground_key
		_ground.queue_redraw()
	if selected_slot >= 0 or selected_section.x >= 0:
		_marks.queue_redraw()
	elif _marks.visible:
		_marks.queue_redraw()  # once more, to clear the last mark
	_marks.visible = selected_slot >= 0 or selected_section.x >= 0
	_top.visible = hint_slot >= 0 and hint_slot != selected_slot
	if _top.visible:
		_top.queue_redraw()
	WallDrawer.refresh(battle, _wall_pieces)
	_refresh_slots()
	_keep_stand.refresh([battle.stat("thorns") > 0.0, battle.keep_fired < 0.08])
	_refresh_enemies()


func _make_ground_key() -> Array:
	var affordable: Array = []
	for ring in range(1, battle.rings_unlocked + 1):
		affordable.append(battle.cash >= battle.section_cost(ring))
	var reach := battle.tower_range(battle.slots[selected_slot].tower) if selected_slot >= 0 and battle.slots[selected_slot].tower != null else 0.0
	return [battle.rings_unlocked, _wall_key, affordable, battle.keep_range(), selected_slot, reach, field_size]


func _refresh_slots() -> void:
	if _slot_rings != battle.rings_unlocked:
		_slot_rings = battle.rings_unlocked
		for stand in _slot_stands.values():
			(stand as Stand).queue_free()
		_slot_stands.clear()
		for slot in battle.slots:
			if battle.slot_open(slot.index):
				var stand := Stand.new(slot.pos.y * TILT + 2.5, Callable())
				stand.painter = _draw_slot.bind(slot)
				_things.add_child(stand)
				_slot_stands[slot.index] = stand
	var cheapest := _cheapest_build()
	for index in _slot_stands:
		var slot: Entities.Slot = battle.slots[index]
		var lit := slot.index == selected_slot or (slot.tower == null and battle.cash >= cheapest)
		var key: Array
		if slot.tower == null:
			key = [lit]
		else:
			key = [lit, slot.tower.weapon, slot.tower.level, slot.tower.fired < 0.08]
		(_slot_stands[index] as Stand).refresh(key)


func _refresh_enemies() -> void:
	_seen_frame += 1
	var frozen := battle.freeze_left > 0.0
	var seen := {}
	for e in battle.enemies:
		var sprite: EnemySprite = _enemy_sprites.get(e.id)
		if sprite == null:
			sprite = _spare_sprites.pop_back() if not _spare_sprites.is_empty() else null
			if sprite == null:
				sprite = EnemySprite.new(_soft)
				_things.add_child(sprite)
			sprite.visible = true
			_enemy_sprites[e.id] = sprite
		sprite.show_enemy(e, frozen)
		seen[e.id] = true
	if _enemy_sprites.size() != seen.size():
		for id in _enemy_sprites.keys():
			if not seen.has(id):
				var gone: EnemySprite = _enemy_sprites[id]
				gone.visible = false
				_spare_sprites.append(gone)
				_enemy_sprites.erase(id)


## The open build slot under a local point, or -1. Compares on screen, where towers stand.
func slot_at(local: Vector2) -> int:
	var screen := (local - _base_position) / zoom
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
			_shake = maxf(_shake, 0.8)
		"thorns":
			fx.burst(proj(e["pos"]) + Vector2(0, -3), Color("#ff6a4a"), 4, 18.0)
		"breath":
			var keep := Art.rect("keep", Vector2.ZERO)
			fx.shot(proj(e["from"]) + Vector2(0, -16), keep.position + keep.size * Vector2(0.5, 0.45), "breath")
			fx.burst(keep.position + keep.size * Vector2(0.5, 0.45), Color("#ff8a2a"), 4, 20.0)
		"crit":
			if randf() < 0.35:  # not every crit, or the field fills with numbers
				fx.float_text(proj(e["pos"]) + Vector2(randf_range(-3, 3), -12), Num.fmt(e["amount"]) + "!", Pal.ORANGE, 0.7, 6)
		"power":
			_power_fx(e["id"])
		"kill":
			Sfx.play("coin" if e["boss"] else "kill", 0.1)
			var at := proj(e["pos"])
			fx.burst(at + Vector2(0, -3), Pal.RED if not e["boss"] else Pal.ORANGE, 14 if e["boss"] else 6, 30.0)
			fx.float_text(at + Vector2(0, -10), "+" + Num.cash(e["cash"]), Pal.CASH)
			if e["boss"]:
				fx.float_text(at + Vector2(0, -20), "+%s coins" % Num.fmt(e["coins"]), Pal.GOLD, 1.8, 9)
				_shake = 2.0
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


func _power_fx(id: String) -> void:
	_shake = 1.5
	match id:
		"rain":
			for e in battle.enemies:
				fx.shot(proj(e.pos()) + Vector2(randf_range(-6, 6), -40), proj(e.pos()), "musket")
		"freeze":
			for e in battle.enemies:
				fx.burst(proj(e.pos()) + Vector2(0, -3), Pal.CYAN, 4, 15.0)
		"gold":
			fx.burst(Vector2(0, -30), Pal.GOLD, 30, 50.0)


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
	var glow: float = _look["glow"]
	var night: float = _look["night"]
	fx.glow_boost = glow
	var keep := Art.rect("keep", Vector2.ZERO)
	fx.glows.append([keep.position + keep.size * Vector2(0.5, 0.12), 14.0 * pulse * sqrt(glow), Color(1.0, 0.75, 0.3, minf(0.45 * glow, 0.9))])
	if night > 0.05:
		# lamplight: a warm pool around the Keep, lit windows and door, a lantern on every tower
		fx.glows.append([Vector2(0, -6), 38.0, Color(1.0, 0.7, 0.35, 0.22 * night)])
		for spot in [Vector2(0.33, 0.55), Vector2(0.67, 0.55), Vector2(0.5, 0.84)]:
			fx.glows.append([keep.position + keep.size * spot, 5.0, Color(1.0, 0.78, 0.35, 0.8 * night)])
	for slot in battle.slots:
		if slot.tower == null or not battle.slot_open(slot.index):
			continue
		var name := tower_sprite(slot.tower)
		var r := Art.rect(name, proj(slot.pos) + Vector2(0, 1.5 - WallDrawer.HEIGHT))
		if slot.tower.weapon == "arcane":
			fx.glows.append([r.position + r.size * Vector2(0.5, 0.19), 9.0 * pulse * sqrt(glow), Color(0.78, 0.6, 1.0, minf(0.55 * glow, 0.9))])
		if night > 0.05:
			fx.glows.append([r.position + r.size * Vector2(0.5, 0.55), 6.0, Color(1.0, 0.75, 0.35, 0.65 * night)])
			fx.glows.append([proj(slot.pos), 14.0, Color(1.0, 0.7, 0.35, 0.14 * night)])
	var tint: Color = _look["tint"]
	var golden := clampf((tint.r - tint.b) * 3.0, 0.0, 1.0) * (1.0 - night)
	if golden > 0.02:  # golden hour: warm light washing in from the sun's side
		var towards: Vector2 = proj(_look["sun"]["dir"])
		var w := _visible_rect.size.x
		fx.glows.append([_visible_rect.get_center() + towards * w * 0.4, w * 0.85, Color(1.0, 0.5, 0.22, 0.7 * golden)])
	if night > 0.3:  # fireflies drifting over the meadow
		var half := _visible_rect.size / 2.0
		var centre := _visible_rect.get_center()
		for f in _fireflies:
			var base: Vector2 = f[0]
			var t: float = _time * f[1] + f[2]
			var p := centre + Vector2(base.x * half.x + sin(t * 1.3) * 10.0, base.y * half.y + cos(t) * 8.0)
			var blink := maxf(sin(t * 4.0), 0.0)
			fx.glows.append([p, 2.2, Color(0.85, 1.0, 0.45, 0.9 * blink * (night - 0.3) / 0.7)])


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
	_draw_keep_range()
	_draw_range()
	_ground.draw_texture_rect(_vignette, area, false)


## The Keep's reach is always shown: a solid whitish edge with a subtle gradient that is clear
## in the middle and brightens towards the edge.
func _draw_keep_range() -> void:
	_draw_reach(Vector2.ZERO, battle.keep_range(), 0.8)


func _draw_reach(at: Vector2, reach: float, strength: float) -> void:
	_ground.draw_texture_rect(_rim, Rect2(at - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, Color(1, 1, 1, strength))
	_ground.draw_arc(at, reach, 0, TAU, 128, Color(1, 1, 1, 0.7 * strength + 0.25), 1.5, true)


## Unbuilt wall sections show as dashed foundations; the selected one glows.
func _draw_wall_plan(ring: int) -> void:
	var wall: Entities.Wall = battle.walls[ring]
	var r := battle.wall_radius(ring)
	var count: int = Defs.SLOT_COUNTS[ring]
	var step := TAU / count
	var affordable := battle.cash >= battle.section_cost(ring)
	for seg in count:
		var a0 := Defs.ring_angle_offset(ring) + step * seg
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
	if slot.tower != null:
		_draw_reach(slot.pos, battle.tower_range(slot.tower), 0.9)


## The pulsing marks under a selected slot or wall section (flat, squashed like the ground).
func _draw_marks() -> void:
	if battle == null:
		return
	if selected_slot >= 0:
		var slot: Entities.Slot = battle.slots[selected_slot]
		var pulse := 0.7 + 0.3 * sin(_time * 5.0)
		_marks.draw_texture_rect(_soft, Rect2(slot.pos - Vector2(14, 14), Vector2(28, 28)), false, Color(1.0, 0.95, 0.5, 0.8 * pulse))
	if selected_section.x >= 1 and selected_section.x <= battle.rings_unlocked:
		var ring := selected_section.x
		var step: float = TAU / Defs.SLOT_COUNTS[ring]
		var a0: float = Defs.ring_angle_offset(ring) + step * selected_section.y
		var pulse := 0.6 + 0.4 * sin(_time * 6.0)
		_marks.draw_arc(Vector2.ZERO, battle.wall_radius(ring), a0 + 0.06, a0 + step - 0.06, 32, Color(1.0, 0.95, 0.5, 0.75 * pulse), 9.0, true)


# --- Everything standing (Stands under the y-sorted layer) -----------------------------------------

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
	for stand in _decor_stands:
		stand.queue_free()
	_decor_stands.clear()
	for d in _decor:
		var stand := Stand.new((d[0] as Vector2).y * TILT, _draw_decor.bind(d[0], d[1]))
		_things.add_child(stand)
		_decor_stands.append(stand)


func _draw_decor(ci: CanvasItem, p: Vector2, name: String) -> void:
	ci.draw_texture_rect(Art.tex(name), Art.rect(name, proj(p)), false)


func _draw_hint() -> void:
	if battle == null or hint_slot < 0 or hint_slot == selected_slot:
		return
	var tip: Vector2 = proj(battle.slots[hint_slot].pos) + Vector2(0, -WallDrawer.HEIGHT - 6.0 - absf(sin(_time * 4.0)) * 4.0)
	var arrow := PackedVector2Array([tip, tip + Vector2(-4, -5), tip + Vector2(-1.6, -5), tip + Vector2(-1.6, -10),
		tip + Vector2(1.6, -10), tip + Vector2(1.6, -5), tip + Vector2(4, -5)])
	var outline := arrow.duplicate()
	outline.append(tip)
	_top.draw_colored_polygon(arrow, Pal.GOLD)
	_top.draw_polyline(outline, Pal.INK, 0.7, true)


func _cheapest_build() -> float:
	var best := INF
	for weapon in Defs.WEAPON_ORDER:
		if battle.weapon_unlocked(weapon):
			best = minf(best, battle.build_cost(weapon))
	return best


func _draw_keep(ci: CanvasItem) -> void:
	if battle == null:
		return
	if battle.stat("thorns") > 0.0:  # a ring of iron spikes around the Keep's foot
		var g := Geo.new()
		for k in 14:
			var a := PI * (k + 0.5) / 14.0
			var out := Vector2.from_angle(a)
			WallDrawer.spike(g, proj(out * 13.0) + Vector2(0, -1.0), (proj(out) + Vector2(0, -0.3)).normalized(), 3.0)
		g.submit(ci)
	var r := Art.rect("keep", Vector2.ZERO)
	if battle.keep_fired < 0.08:
		r.position.y += 0.5
	ci.draw_texture_rect(Art.tex("keep"), r, false)


## Every slot is a stone pedestal as tall as the walls; its tower stands on top.
func _draw_slot(ci: CanvasItem, slot: Entities.Slot) -> void:
	var at := proj(slot.pos)
	var plate := Art.rect("slot", at)
	var top := at + Vector2(0, -WallDrawer.HEIGHT)
	var lit: bool = (ci as Stand).key[0]
	ci.draw_texture_rect(Art.tex("slot"), plate, false, Color(1.12, 1.07, 0.92) if lit else Color.WHITE)
	if slot.tower == null:
		if lit and slot.index != selected_slot:  # an empty plate you can afford to build on
			ci.draw_set_transform(top - Vector2(0, ci.position.y), 0.0, Vector2(1.0, TILT))
			ci.draw_arc(Vector2.ZERO, 9.0, 0, TAU, 40, Color(1.0, 1.0, 0.7, 0.55), 1.0, true)
			ci.draw_set_transform(Vector2(0, -ci.position.y))
		return
	var name := tower_sprite(slot.tower)
	var r := Art.rect(name, top + Vector2(0, 1.5))
	if slot.tower.fired < 0.08:
		r.position.y += 0.6
	ci.draw_texture_rect(Art.tex(name), r, false)
	_draw_badge(ci, top + Vector2(8, 1), str(slot.tower.level))


## Towers look grander as they level: a new detail at level 5 and again at level 10.
static func tower_sprite(tower: Entities.Tower) -> String:
	if tower.level >= 10:
		return tower.weapon + "_3"
	if tower.level >= 5:
		return tower.weapon + "_2"
	return tower.weapon


func _draw_badge(ci: CanvasItem, at: Vector2, text: String) -> void:
	var font := Fonts.field()
	var fs := 5
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var box := Rect2(at - Vector2(w / 2.0 + 1.6, 3.2), Vector2(w + 3.2, 5.0))
	ci.draw_style_box(_badge_box(), box)
	ci.draw_string(font, Vector2(at.x - w / 2.0, at.y + 0.9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.INK)


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


## The edge haze: clear in the middle, white towards the corners (tinted by the time of day).
static func _make_haze() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 1))
	g.add_point(0.45, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.1, 0.5)
	tex.width = 128
	tex.height = 128
	return tex


## A range circle's fill: transparent in the middle, a faint white haze growing to the edge.
static func _make_rim() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.55, Color(1, 1, 1, 0.0))
	g.add_point(0.985, Color(1, 1, 1, 0.32))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
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
