class_name WallDrawer
extends RefCounted
## Draws the built wall sections in the tilted view: each section is an arc of stone between
## two towers, with height (a lit outer face on the near side, the inner face on the far side),
## a walkway on top and a row of outlined battlements. Each section is cut into small pieces,
## and every piece is its own Stand so walls sort correctly with the raiders around them. A
## piece only redraws when its section's health band or the thorns change. Hurt sections turn
## brown; broken ones fall to rubble.

const THICKNESS := 4.0
const HEIGHT := 8.0  ## How tall the wall stands on screen; matches the tower pedestals' top.
const PIECE := deg_to_rad(5.0)
const MERLON_EVERY := 2.8
const GAP := 0.0  ## Angle trimmed at each end so sections meet under the towers.

const TOP_OUT := Color("#ffffff")
const TOP_IN := Color("#d9d2ee")
const FACE_LIT := Color("#cfc8e6")
const FACE_DARK := Color("#9d93c2")
const HURT := Color("#b0714f")
const INK := Color("#3a2218")


const HURT_STEPS := 12.0  ## how finely the hurt colour follows a section's health


## Which sections stand, ring by ring: the pieces are rebuilt when this changes.
static func layout_key(b: Battle) -> Array:
	var key: Array = [b.rings_unlocked]
	for ring in range(1, b.rings_unlocked + 1):
		key.append(b.walls[ring].sections.duplicate())
	return key


## Creates the Stand pieces for every built section under `parent`. Returns
## [[ring, segment, Stand], ...] for refresh().
static func build(b: Battle, parent: Node) -> Array:
	var out: Array = []
	for ring in range(1, b.rings_unlocked + 1):
		var wall: Entities.Wall = b.walls[ring]
		var radius := b.wall_radius(ring)
		var count: int = Defs.SLOT_COUNTS[ring]
		var step := TAU / count
		var pieces := maxi(int(ceil(step / PIECE)), 2)
		for seg in count:
			if not wall.sections[seg]:
				continue
			var start := Defs.ring_angle_offset(ring) + step * seg
			for i in pieces:
				var a0 := start + step * i / pieces
				var a1 := start + step * (i + 1) / pieces
				var mid := BattleView.proj(Vector2.from_angle((a0 + a1) / 2.0) * radius)
				var stand := Stand.new(mid.y + 0.3, Callable())
				stand.painter = _paint.bind(stand, b, ring, seg, radius, a0, a1, seg * 31 + i, i == 0, i == pieces - 1)
				parent.add_child(stand)
				out.append([ring, seg, stand])
	return out


## Redraws the pieces whose section changed health band (or when the ring gets Thorns).
static func refresh(b: Battle, pieces: Array) -> void:
	var thorns := b.stat("thorns") > 0.0
	for item in pieces:
		var wall: Entities.Wall = b.walls[item[0]]
		var spiked := 1 if thorns and wall.addons.has("thorns") else 0
		var share := wall.segments[item[1]] / wall.max_hp if wall.max_hp > 0.0 else 0.0
		(item[2] as Stand).refresh(_band(share) * 2 + spiked)


static func _band(share: float) -> int:
	if share <= 0.0:
		return -1
	return int(ceil(clampf(share, 0.0, 1.0) * HURT_STEPS))


static func _paint(ci: CanvasItem, stand: Stand, b: Battle, ring: int, seg: int, r: float, a0: float, a1: float, seed_value: int, first: bool, last: bool) -> void:
	var band := int(floor(float(stand.key) / 2.0))
	var share := -1.0 if band < 0 else band / HURT_STEPS
	_piece(ci, r, a0, a1, share, seed_value, first, last, int(stand.key) % 2 == 1)


static func _arc(r: float, a0: float, a1: float, lift: float, steps: int = 3) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in steps + 1:
		out.append(BattleView.proj(Vector2.from_angle(lerpf(a0, a1, float(k) / steps)) * r) + Vector2(0, -lift))
	return out


static func _piece(ci: CanvasItem, r: float, a0: float, a1: float, share: float, seed_value: int, first: bool, last: bool, spiked: bool = false) -> void:
	var g := Geo.new()
	if share <= 0.0:
		_rubble(g, r, a0, a1, seed_value)
		g.submit(ci)
		return
	var hurt := clampf(1.0 - share, 0.0, 1.0) * 0.8
	var height := HEIGHT * (1.0 if share > 0.3 else 0.65)
	var mid := (a0 + a1) / 2.0
	var near_side := sin(mid) > 0.0  # the half of the ring facing the camera shows its outer face
	var face_r := r + THICKNESS / 2.0 if near_side else r - THICKNESS / 2.0
	var lit := clampf(0.5 + 0.5 * cos(mid - PI * 0.75), 0.0, 1.0)  # light from the top left
	var face_color := FACE_DARK.lerp(FACE_LIT, lit).lerp(HURT, hurt)
	var base := _arc(face_r, a0, a1, 0.0)
	var top := _arc(face_r, a0, a1, height)
	# the face as quads (one outline polygon would fold over itself where the ring runs up the screen)
	for k in base.size() - 1:
		g.quad(base[k], base[k + 1], top[k + 1], top[k], face_color, face_color, face_color, face_color)
	g.polyline(base, 0.5, INK)
	# walkway on top: lighter on the outside edge
	var out_top := _arc(r + THICKNESS / 2.0, a0, a1, height)
	var in_top := _arc(r - THICKNESS / 2.0, a0, a1, height)
	var outer_c := TOP_OUT.lerp(HURT.lightened(0.3), hurt)
	var inner_c := TOP_IN.lerp(HURT, hurt)
	for k in out_top.size() - 1:
		g.quad(out_top[k], out_top[k + 1], in_top[k + 1], in_top[k], outer_c, outer_c, inner_c, inner_c)
	g.polyline(out_top, 0.45, INK)
	g.polyline(in_top, 0.35, INK)
	if first:
		g.line(base[0], top[0], 0.45, INK)
	if last:
		g.line(base[base.size() - 1], top[top.size() - 1], 0.45, INK)
	_merlons(g, r + THICKNESS / 2.0 - 0.6, a0, a1, height, face_color)
	if spiked:
		_spikes(g, r + THICKNESS / 2.0, a0, a1, near_side)
	if hurt > 0.3:
		var c := BattleView.proj(Vector2.from_angle(mid) * face_r) + Vector2(0, -height * 0.5)
		g.polyline(PackedVector2Array([c + Vector2(-1, -1.5), c + Vector2(0, -0.3), c + Vector2(-0.4, 0.6), c + Vector2(0.8, 1.6)]), 0.35, INK)
	g.submit(ci)


## Iron spikes jutting out of the wall's foot (bought with the Thorns upgrade).
static func spike(g: Geo, base: Vector2, dir: Vector2, length: float) -> void:
	var side := Vector2(-dir.y, dir.x) * 0.6
	var tip := base + dir * length
	g.tri(base + side, tip, base - side, Color("#5b6582"))
	g.line(base + side, tip, 0.35, INK)
	g.line(tip, base - side, 0.35, INK)
	g.line(base + side * 0.4, tip, 0.25, Color("#c3c8d8"))


static func _spikes(g: Geo, r: float, a0: float, a1: float, near_side: bool) -> void:
	var count := maxi(int((a1 - a0) * r / 2.4), 1)
	for k in count:
		var a := lerpf(a0, a1, (k + 0.5) / count)
		var out := Vector2.from_angle(a)
		var base := BattleView.proj(out * (r - 0.2)) + Vector2(0, -2.2 if near_side else -4.5)
		var dir := (BattleView.proj(out) + Vector2(0, -0.35)).normalized()
		spike(g, base, dir, 2.4)


static func _merlons(g: Geo, r: float, a0: float, a1: float, height: float, face: Color) -> void:
	var count := maxi(int((a1 - a0) * r / MERLON_EVERY), 1)
	for k in count:
		var p := BattleView.proj(Vector2.from_angle(lerpf(a0, a1, (k + 0.5) / count)) * r) + Vector2(0, -height)
		g.rect(Rect2(p + Vector2(-1.0, -2.0), Vector2(2.0, 2.3)), INK)
		g.rect(Rect2(p + Vector2(-0.75, -1.2), Vector2(1.5, 1.3)), face)
		g.rect(Rect2(p + Vector2(-0.75, -1.75), Vector2(1.5, 0.6)), TOP_OUT)


static func _rubble(g: Geo, r: float, a0: float, a1: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in 3:
		var a := lerpf(a0, a1, rng.randf())
		var p := BattleView.proj(Vector2.from_angle(a) * (r + rng.randf_range(-1.5, 1.5)))
		var s := rng.randf_range(0.7, 1.3)
		g.disc(p + Vector2(0, 0.4), s + 0.3, INK)
		g.disc(p, s, Color("#cfc8e6"))
