class_name BattleView
extends Node2D
## Draws a Battle and runs it in real time. Lives inside a half-resolution SubViewport, so
## every line, circle and sprite lands on a chunky pixel grid. The origin is the Keep.

signal event(data: Dictionary)

const MAX_STEP := 1.0 / 30.0
const TAP_RADIUS := 14.0

var battle: Battle
var speed := 1.0
var paused := false
var selected_slot := -1
var field_size := Vector2(270, 300)

var fx: FieldFx
var _ground: ImageTexture
var _ground_key := ""
var _time := 0.0


func _ready() -> void:
	fx = FieldFx.new()
	add_child(fx)


func setup(p_battle: Battle) -> void:
	battle = p_battle
	_ground_key = ""


func _process(delta: float) -> void:
	_time += delta
	var size := get_viewport_rect().size
	if size != field_size:
		field_size = size
	position = (field_size / 2.0).floor() + Vector2(0, 4)
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
	queue_redraw()


## The slot under a point in field coordinates (origin = the Keep), or -1.
func slot_at(field_pos: Vector2) -> int:
	var best := -1
	var best_d := TAP_RADIUS
	for slot in battle.slots:
		if not battle.slot_open(slot.index):
			continue
		var d := slot.pos.distance_to(field_pos)
		if d < best_d:
			best_d = d
			best = slot.index
	return best


func _on_event(e: Dictionary) -> void:
	match e["type"]:
		"shot":
			fx.shot(e["from"] + Vector2(0, -6) if e["weapon"] != "keep" else e["from"], e["to"], e["weapon"])
		"chain":
			fx.shot(e["from"], e["to"], "chain")
		"blast":
			fx.blast(e["at"], e["radius"])
		"kill":
			var color := Pal.RED if not e["boss"] else Pal.ORANGE
			fx.burst(e["pos"], color, 14 if e["boss"] else 6, 30.0)
			fx.float_text(e["pos"] + Vector2(0, -6), "+" + Num.cash(e["cash"]), Pal.CASH)
			if e["boss"]:
				fx.float_text(e["pos"] + Vector2(0, -16), "+%s COINS" % Num.fmt(e["coins"]), Pal.GOLD, 1.6)
		"wall_broken":
			var angle: float = Defs.ring_angle_offset(e["ring"]) + TAU * e["segment"] / Defs.SLOT_COUNTS[e["ring"]]
			var at: Vector2 = Vector2.from_angle(angle) * battle.wall_radius(e["ring"])
			fx.burst(at, Color("#7c829c"), 10, 25.0)
			fx.smoke(at, 4)
		"built", "upgraded":
			var slot: Entities.Slot = battle.slots[e["slot"]]
			fx.burst(slot.pos, Pal.GOLD, 10, 25.0)
	event.emit(e)


func _update_lights() -> void:
	fx.glows.clear()
	if battle == null:
		return
	var pulse := 0.75 + 0.25 * sin(_time * 3.0)
	fx.glows.append([Vector2(0, -24), 16.0 * pulse, Color(0.37, 0.95, 1.0, 0.45)])
	for slot in battle.slots:
		if slot.tower != null and slot.tower.weapon == "arcane":
			fx.glows.append([slot.pos + Vector2(0, -16), 10.0 * pulse, Color(0.7, 0.42, 1.0, 0.5)])


# --- Drawing ----------------------------------------------------------------------------------

func _draw() -> void:
	if battle == null:
		return
	_draw_ground()
	_draw_rings()
	_draw_range()
	var sprites: Array = []  # [y, Callable] drawn back to front
	sprites.append([12.0, _draw_keep])
	for slot in battle.slots:
		if battle.slot_open(slot.index):
			sprites.append([slot.pos.y + 3.0, _draw_slot.bind(slot)])
	_add_wall_blocks(sprites)
	for e in battle.enemies:
		sprites.append([e.pos().y + (40.0 if e.air else 0.0), _draw_enemy.bind(e)])
	sprites.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for s in sprites:
		(s[1] as Callable).call()


func _draw_ground() -> void:
	var key := "%dx%d-%d" % [int(field_size.x), int(field_size.y), battle.rings_unlocked]
	if key != _ground_key:
		_ground_key = key
		_ground = FieldGround.make(field_size, battle.rings_unlocked, battle)
	draw_texture(_ground, -position)


func _draw_rings() -> void:
	for ring in range(1, Defs.MAX_RING + 1):
		var open := ring <= battle.rings_unlocked
		var r: float = Defs.RING_RADII[ring]
		var c := Color(0.95, 0.85, 0.6, 0.10) if open else Color(1, 1, 1, 0.03)
		var segments := int(r * 0.8)
		for i in segments:
			if i % 2 == 0:
				var a := TAU * i / segments
				draw_rect(Rect2((Vector2.from_angle(a) * r).floor(), Vector2.ONE), c)


func _draw_range() -> void:
	if selected_slot < 0:
		return
	var slot: Entities.Slot = battle.slots[selected_slot]
	var reach := 0.0
	if slot.tower != null:
		reach = battle.tower_range(slot.tower)
	var pulse := 0.6 + 0.4 * sin(_time * 6.0)
	if reach > 0.0:
		draw_circle(slot.pos, reach, Color(0.37, 0.95, 1.0, 0.07))
		draw_arc(slot.pos, reach, 0, TAU, 48, Color(0.37, 0.95, 1.0, 0.5), 1.0)
	draw_arc(slot.pos, 8.0, 0, TAU, 16, Color(0.37, 0.95, 1.0, pulse), 1.0)


func _draw_keep() -> void:
	var tex := Sprites.get_tex("keep")
	var recoil := 1.0 if battle.keep_fired < 0.08 else 0.0
	draw_texture(tex, Vector2(-tex.get_width() / 2.0, 14.0 - tex.get_height() + recoil).floor())


func _draw_slot(slot: Entities.Slot) -> void:
	if slot.tower == null:
		var plate := Sprites.get_tex("slot")
		draw_texture(plate, (slot.pos - plate.get_size() / 2.0).floor())
		var blink := 0.35 + 0.25 * sin(_time * 2.5 + slot.index)
		draw_rect(Rect2(slot.pos.floor() + Vector2(-1, -3), Vector2(2, 1)), Color(1, 0.85, 0.4, blink))
		draw_rect(Rect2(slot.pos.floor() + Vector2(-0.5, -4.5), Vector2(1, 3)), Color(1, 0.85, 0.4, blink))
		return
	var tex := Sprites.get_tex(slot.tower.weapon)
	var recoil := 1.0 if slot.tower.fired < 0.08 else 0.0
	var at := Vector2(slot.pos.x - tex.get_width() / 2.0, slot.pos.y + 4.0 - tex.get_height() + recoil).floor()
	draw_texture(tex, at)
	_draw_level_pips(slot.pos + Vector2(7, -1), slot.tower.level)


func _draw_level_pips(at: Vector2, level: int) -> void:
	var text := str(level)
	var w := PixelFont.text_width(text, 1)
	var origin := (at - Vector2(w / 2.0 + 1, 0)).floor()
	draw_rect(Rect2(origin - Vector2(1, 0), Vector2(w + 3, 9)), Color(0.04, 0.05, 0.09, 0.8))
	draw_string(PixelFont.font(), origin + Vector2(0, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Pal.GOLD)


func _add_wall_blocks(sprites: Array) -> void:
	for ring in range(1, battle.rings_unlocked + 1):
		var wall: Entities.Wall = battle.walls[ring]
		if not wall.built:
			continue
		var radius := battle.wall_radius(ring)
		var count: int = Defs.SLOT_COUNTS[ring]
		var step := TAU / count
		var blocks := int(radius * step / 4.0)
		for seg in count:
			var center := Defs.ring_angle_offset(ring) + step * seg
			var share := wall.segments[seg] / wall.max_hp
			for i in blocks:
				var a := center - step / 2.0 + step * (i + 0.5) / blocks
				var p := (Vector2.from_angle(a) * radius).floor()
				sprites.append([p.y, _draw_wall_block.bind(p, share, i)])


func _draw_wall_block(p: Vector2, share: float, i: int) -> void:
	if share <= 0.0:
		if i % 3 == 0:
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2(2, 1)), Color("#4b5068"))
		return
	var top := Color("#a9afc6") if share > 0.5 else Color("#7c829c")
	var body := Color("#7c829c") if share > 0.5 else Color("#5d6478")
	if share < 0.25:
		body = Color("#6b4a3a")
	var h := 4.0 if share > 0.25 else 2.0
	draw_rect(Rect2(p + Vector2(-2, -h), Vector2(4, h + 1)), Color("#0c0e18"))
	draw_rect(Rect2(p + Vector2(-2, -h), Vector2(3, h)), body)
	draw_rect(Rect2(p + Vector2(-2, -h), Vector2(3, 1)), top)


func _draw_enemy(e: Entities.Enemy) -> void:
	var name := e.kind
	if e.kind == "wyvern" and int(e.age * 6.0) % 2 == 1:
		name = "wyvern_b"
	var tex := Sprites.get_tex(name)
	var p := e.pos()
	var lift := 0.0
	if e.air:
		lift = 12.0 + sin(e.age * 3.0) * 1.5
		draw_rect(Rect2((p + Vector2(-3, 2)).floor(), Vector2(6, 2)), Color(0, 0, 0, 0.35))
	elif e.attacking == -1:
		lift = absf(sin(e.age * 9.0)) * 1.0
	var at := Vector2(p.x - tex.get_width() / 2.0, p.y + 2.0 - tex.get_height() - lift).floor()
	if e.attacking >= 0 and int(e.age * 8.0) % 2 == 0:
		at.x += 1.0  # lunging at the wall
	var tint := Color(2.5, 2.5, 2.5) if e.hit_flash > 0.0 else Color.WHITE
	draw_texture(tex, at, tint)
	if e.hp < e.max_hp:
		var w := maxf(tex.get_width() - 2.0, 6.0)
		var bar := Rect2(Vector2(p.x - w / 2.0, at.y - 3.0).floor(), Vector2(w, 1))
		draw_rect(bar.grow(1), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(bar.position, Vector2(w * e.hp / e.max_hp, 1)), Pal.RED if not e.boss else Pal.ORANGE)
