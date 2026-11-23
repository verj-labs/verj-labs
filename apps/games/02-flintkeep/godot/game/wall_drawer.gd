class_name WallDrawer
extends RefCounted
## Draws the built wall sections in the tilted view: each section is an arc of stone between
## two towers, with height (a lit outer face on the near side, the inner face on the far side),
## a walkway on top and a row of outlined battlements. Pieces are depth-sorted with everything
## else. Hurt sections turn brown; broken ones fall to rubble.

const THICKNESS := 4.0
const HEIGHT := 5.5  ## How tall the wall stands on screen (field units).
const PIECE := deg_to_rad(5.0)
const MERLON_EVERY := 2.8
const GAP := 0.0  ## Angle trimmed at each end so sections meet under the towers.

const TOP_OUT := Color("#ffffff")
const TOP_IN := Color("#d9d2ee")
const FACE_LIT := Color("#cfc8e6")
const FACE_DARK := Color("#9d93c2")
const HURT := Color("#b0714f")
const INK := Color("#3a2218")


static func add(items: Array, b: Battle, ci: CanvasItem) -> void:
	for ring in range(1, b.rings_unlocked + 1):
		var wall: Entities.Wall = b.walls[ring]
		if not wall.built:
			continue
		var radius := b.wall_radius(ring)
		var count: int = Defs.SLOT_COUNTS[ring]
		var step := TAU / count
		var pieces := maxi(int(ceil(step / PIECE)), 2)
		for seg in count:
			if not wall.sections[seg]:
				continue
			var start := Defs.ring_angle_offset(ring) + step * seg
			var share := wall.segments[seg] / wall.max_hp
			for i in pieces:
				var a0 := start + step * i / pieces
				var a1 := start + step * (i + 1) / pieces
				var mid := BattleView.proj(Vector2.from_angle((a0 + a1) / 2.0) * radius)
				items.append([mid.y + 0.3, _piece.bind(ci, radius, a0, a1, share, seg * 31 + i, i == 0, i == pieces - 1)])


static func _arc(r: float, a0: float, a1: float, lift: float, steps: int = 3) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in steps + 1:
		out.append(BattleView.proj(Vector2.from_angle(lerpf(a0, a1, float(k) / steps)) * r) + Vector2(0, -lift))
	return out


static func _piece(ci: CanvasItem, r: float, a0: float, a1: float, share: float, seed_value: int, first: bool, last: bool) -> void:
	if share <= 0.0:
		_rubble(ci, r, a0, a1, seed_value)
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
	var face := PackedVector2Array(base)
	for k in range(top.size() - 1, -1, -1):
		face.append(top[k])
	ci.draw_colored_polygon(face, face_color)
	ci.draw_polyline(base, INK, 0.5, true)
	# walkway on top: lighter on the outside edge
	var out_top := _arc(r + THICKNESS / 2.0, a0, a1, height)
	var in_top := _arc(r - THICKNESS / 2.0, a0, a1, height)
	var walk := PackedVector2Array(out_top)
	var cols := PackedColorArray()
	for p in out_top:
		cols.append(TOP_OUT.lerp(HURT.lightened(0.3), hurt))
	for k in range(in_top.size() - 1, -1, -1):
		walk.append(in_top[k])
		cols.append(TOP_IN.lerp(HURT, hurt))
	ci.draw_polygon(walk, cols)
	ci.draw_polyline(out_top, INK, 0.45, true)
	ci.draw_polyline(in_top, INK, 0.35, true)
	if first:
		ci.draw_line(base[0], top[0], INK, 0.45, true)
	if last:
		ci.draw_line(base[base.size() - 1], top[top.size() - 1], INK, 0.45, true)
	_merlons(ci, r + THICKNESS / 2.0 - 0.6, a0, a1, height, face_color)
	if hurt > 0.3:
		var c := BattleView.proj(Vector2.from_angle(mid) * face_r) + Vector2(0, -height * 0.5)
		ci.draw_polyline(PackedVector2Array([c + Vector2(-1, -1.5), c + Vector2(0, -0.3), c + Vector2(-0.4, 0.6), c + Vector2(0.8, 1.6)]), INK, 0.35, true)


static func _merlons(ci: CanvasItem, r: float, a0: float, a1: float, height: float, face: Color) -> void:
	var count := maxi(int((a1 - a0) * r / MERLON_EVERY), 1)
	for k in count:
		var p := BattleView.proj(Vector2.from_angle(lerpf(a0, a1, (k + 0.5) / count)) * r) + Vector2(0, -height)
		ci.draw_rect(Rect2(p + Vector2(-1.0, -2.0), Vector2(2.0, 2.3)), INK)
		ci.draw_rect(Rect2(p + Vector2(-0.75, -1.2), Vector2(1.5, 1.3)), face)
		ci.draw_rect(Rect2(p + Vector2(-0.75, -1.75), Vector2(1.5, 0.6)), TOP_OUT)


static func _rubble(ci: CanvasItem, r: float, a0: float, a1: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in 3:
		var a := lerpf(a0, a1, rng.randf())
		var p := BattleView.proj(Vector2.from_angle(a) * (r + rng.randf_range(-1.5, 1.5)))
		var s := rng.randf_range(0.7, 1.3)
		ci.draw_circle(p + Vector2(0, 0.4), s + 0.3, INK, true, -1.0, true)
		ci.draw_circle(p, s, Color("#cfc8e6"), true, -1.0, true)
