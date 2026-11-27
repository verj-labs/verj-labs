class_name Geo
extends RefCounted
## Collects coloured triangles (fills, outlines as thin quads, little discs) and submits them as
## ONE draw command. Drawing a wall piece as dozens of separate polygons, lines and rects cost
## thousands of commands a frame with three rings built; one mesh per piece costs one.
## Shapes are painted in the order they are added.

var points := PackedVector2Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()


func tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var i := points.size()
	points.append_array([a, b, c])
	colors.append_array([col, col, col])
	indices.append_array([i, i + 1, i + 2])


## A quad a-b-c-d (in order around it), one colour per corner.
func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var i := points.size()
	points.append_array([a, b, c, d])
	colors.append_array([ca, cb, cc, cd])
	indices.append_array([i, i + 1, i + 2, i, i + 2, i + 3])


func rect(r: Rect2, col: Color) -> void:
	quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col, col, col, col)


## A straight stroke, stretched by half its width at both ends so strokes join without gaps.
func line(a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var along := dir * width * 0.5
	var side := Vector2(-dir.y, dir.x) * width * 0.5
	var s := a - along
	var e := b + along
	quad(s + side, e + side, e - side, s - side, col, col, col, col)


func polyline(pts: PackedVector2Array, width: float, col: Color) -> void:
	for k in pts.size() - 1:
		line(pts[k], pts[k + 1], width, col)


func disc(center: Vector2, radius: float, col: Color, segments: int = 10) -> void:
	for k in segments:
		var a0 := TAU * k / segments
		var a1 := TAU * (k + 1) / segments
		tri(center, center + Vector2.from_angle(a0) * radius, center + Vector2.from_angle(a1) * radius, col)


## Draws everything collected on `ci` (after any draw_set_transform it has).
func submit(ci: CanvasItem) -> void:
	if indices.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, colors)
