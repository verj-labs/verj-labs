class_name WallDrawer
extends RefCounted
## Draws each ring's wall as one continuous stone ring: a walkway on top (lighter on the outer
## edge, darker inside), a face below it and a row of battlements. The ring is cut into short
## pieces only so the pieces can be depth-sorted with the enemies and towers around them.
## Hurt sections darken, and broken sections become rubble.

const THICKNESS := 3.4
const FACE := 2.6  ## How far the wall's face drops below its top, for a little height.
const PIECE := deg_to_rad(5.0)
const MERLON_EVERY := 2.6  ## Field units between battlements.

const TOP_OUT := Color("#d3ccbd")
const TOP_IN := Color("#8e877a")
const FACE_COLOR := Color("#5e594f")
const FACE_DARK := Color("#3d3a34")
const HURT := Color("#5a3d2c")


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
			var center := Defs.ring_angle_offset(ring) + step * seg
			var share := wall.segments[seg] / wall.max_hp
			for i in pieces:
				var a0 := center - step / 2.0 + step * i / pieces
				var a1 := a0 + step / pieces
				var mid := Vector2.from_angle((a0 + a1) / 2.0) * radius
				items.append([mid.y + 0.4, _piece.bind(ci, radius, a0, a1, share, seg * 31 + i)])


static func _piece(ci: CanvasItem, r: float, a0: float, a1: float, share: float, seed_value: int) -> void:
	if share <= 0.0:
		_rubble(ci, r, a0, a1, seed_value)
		return
	var hurt := clampf(1.0 - share, 0.0, 1.0) * 0.75
	var top_out := TOP_OUT.lerp(HURT, hurt)
	var top_in := TOP_IN.lerp(HURT.darkened(0.3), hurt)
	var face := FACE_COLOR.lerp(HURT.darkened(0.2), hurt)
	var steps := 3
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for k in steps + 1:
		var a := lerpf(a0, a1, float(k) / steps)
		outer.append(Vector2.from_angle(a) * (r + THICKNESS / 2.0))
		inner.append(Vector2.from_angle(a) * (r - THICKNESS / 2.0))
	# face: the outer edge dropped down (reads as the wall's height on the near side)
	var drop := Vector2(0, FACE)
	var face_poly := PackedVector2Array()
	var face_cols := PackedColorArray()
	for p in outer:
		face_poly.append(p)
		face_cols.append(face)
	for k in range(steps, -1, -1):
		face_poly.append(outer[k] + drop)
		face_cols.append(FACE_DARK.lerp(HURT.darkened(0.4), hurt))
	ci.draw_polygon(face_poly, face_cols)
	# walkway: lighter on the outer edge, darker towards the courtyard
	var top := PackedVector2Array()
	var cols := PackedColorArray()
	for p in outer:
		top.append(p)
		cols.append(top_out)
	for k in range(steps, -1, -1):
		top.append(inner[k])
		cols.append(top_in)
	ci.draw_polygon(top, cols)
	ci.draw_polyline(outer, top_out.lightened(0.25), 0.35, true)
	_merlons(ci, r + THICKNESS / 2.0 - 0.7, a0, a1, top_out, face)
	if hurt > 0.3:
		var mid := Vector2.from_angle((a0 + a1) / 2.0) * r
		ci.draw_line(mid + Vector2(-0.8, -0.6), mid + Vector2(0.4, 0.5), Color(0.1, 0.07, 0.05, 0.7), 0.3, true)


static func _merlons(ci: CanvasItem, r: float, a0: float, a1: float, top: Color, face: Color) -> void:
	var arc := (a1 - a0) * r
	var count := maxi(int(arc / MERLON_EVERY), 1)
	for k in count:
		var a := lerpf(a0, a1, (k + 0.5) / count)
		var p := Vector2.from_angle(a) * r
		ci.draw_rect(Rect2(p + Vector2(-0.75, -0.9), Vector2(1.5, 1.6)), face)
		ci.draw_rect(Rect2(p + Vector2(-0.75, -1.5), Vector2(1.5, 0.8)), top.lightened(0.1))


static func _rubble(ci: CanvasItem, r: float, a0: float, a1: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in 3:
		var a := lerpf(a0, a1, rng.randf())
		var p := Vector2.from_angle(a) * (r + rng.randf_range(-1.5, 1.5))
		var s := rng.randf_range(0.6, 1.2)
		ci.draw_circle(p + Vector2(0, 0.6), s, Color("#3d3a34"), true, -1.0, true)
		ci.draw_circle(p, s, Color("#8e877a"), true, -1.0, true)
