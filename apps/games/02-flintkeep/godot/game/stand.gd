class_name Stand
extends Node2D
## One upright thing on the battlefield: a wall piece, a tower on its pedestal, the Keep, a bush.
## The view keeps them under a y-sorted parent, so the engine orders them back to front, and each
## one redraws only when what it shows changes (not every frame), which is what keeps late runs
## with three or four full rings smooth.
##
## `position.y` is only the depth; the painter draws in the view's field coordinates.

var painter: Callable  ## func(ci: CanvasItem) -> void
var key: Variant = null  ## what was drawn last; refresh() redraws when it changes


func _init(depth: float, p_painter: Callable) -> void:
	position = Vector2(0.0, depth)
	painter = p_painter


## Redraws only when `new_key` differs from the last one drawn.
func refresh(new_key: Variant) -> void:
	if new_key != key:
		key = new_key
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -position.y))
	painter.call(self)
