class_name SuitIcon
extends RefCounted
## Draws the four suits from simple shapes, so cards look right without any font or image.
## Placeholder art: swap for real artwork later without touching game logic.


static func is_red(suit: int) -> bool:
	return suit == Card.Suit.HEARTS or suit == Card.Suit.DIAMONDS


## `size` is roughly the icon's width in pixels.
static func draw(canvas: CanvasItem, suit: int, center: Vector2, size: float, color: Color) -> void:
	match suit:
		Card.Suit.DIAMONDS:
			_diamond(canvas, center, size, color)
		Card.Suit.HEARTS:
			_heart(canvas, center, size, color, 1.0)
		Card.Suit.SPADES:
			_spade(canvas, center, size, color)
		_:
			_club(canvas, center, size, color)


static func _pt(center: Vector2, size: float, x: float, y: float) -> Vector2:
	return center + Vector2(x, y) * size


static func _diamond(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_colored_polygon(
		PackedVector2Array([_pt(c, s, 0, -0.55), _pt(c, s, 0.4, 0), _pt(c, s, 0, 0.55), _pt(c, s, -0.4, 0)]),
		color
	)


## flip = 1 for a heart; -1 mirrors it vertically (the head of a spade).
static func _heart(canvas: CanvasItem, c: Vector2, s: float, color: Color, flip: float) -> void:
	canvas.draw_circle(_pt(c, s, -0.23, -0.2 * flip), 0.28 * s, color)
	canvas.draw_circle(_pt(c, s, 0.23, -0.2 * flip), 0.28 * s, color)
	canvas.draw_colored_polygon(
		PackedVector2Array([_pt(c, s, -0.49, -0.05 * flip), _pt(c, s, 0.49, -0.05 * flip), _pt(c, s, 0, 0.55 * flip)]),
		color
	)


static func _spade(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	_heart(canvas, c + Vector2(0, 0.0), s, color, -1.0)
	canvas.draw_colored_polygon(
		PackedVector2Array([_pt(c, s, 0, 0.1), _pt(c, s, -0.17, 0.58), _pt(c, s, 0.17, 0.58)]), color
	)


static func _club(canvas: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	canvas.draw_circle(_pt(c, s, 0, -0.27), 0.26 * s, color)
	canvas.draw_circle(_pt(c, s, -0.27, 0.1), 0.26 * s, color)
	canvas.draw_circle(_pt(c, s, 0.27, 0.1), 0.26 * s, color)
	canvas.draw_colored_polygon(
		PackedVector2Array([_pt(c, s, 0, 0.0), _pt(c, s, -0.17, 0.58), _pt(c, s, 0.17, 0.58)]), color
	)
