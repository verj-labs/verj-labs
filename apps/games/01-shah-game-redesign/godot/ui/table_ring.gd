class_name TableRing
extends Control
## Players seated around an oval, you at the bottom, seats numbered clockwise (seat 1 is to
## your left). The pile sits on a felt in the middle. Pixel arrows between seats show the
## direction of play, the arrow leaving the current player lights up, and a bobbing pointer
## marks whose turn it is.

## The oval is never taller than this multiple of its width, so a tall phone does not stretch it.
const MAX_ASPECT := 1.2
const ARROW_SIZE := 12.0
const RING_SEGMENTS := 72
const FELT_SCALE := 0.8
const POINTER_SIZE := 16.0
const BOB := 5.0

var seat_size: Vector2 = SeatView.NORMAL_SIZE
var pile_view: PileView
var _seat_views: Array[SeatView] = []
var _player_count: int = 0
var _my_seat: int = 0
var _current: int = -1
var _direction: int = Direction.CLOCKWISE
var _time: float = 0.0


func is_built() -> bool:
	return _player_count > 0


## `my_seat` is drawn at the bottom; everyone else is placed around you in seat order.
func setup(player_count: int, names: Array, my_seat: int = 0) -> void:
	_player_count = player_count
	_my_seat = maxi(my_seat, 0)
	seat_size = SeatView.size_for(player_count)
	for seat in player_count:
		var view := SeatView.new(player_count > 6)
		view.size = seat_size
		view.set_seat(seat, names[seat])
		add_child(view)
		_seat_views.append(view)
	pile_view = PileView.new()
	pile_view.size = pile_view.custom_minimum_size
	add_child(pile_view)
	_layout()


func seat_view(seat: int) -> SeatView:
	return _seat_views[seat]


## Screen position of the middle of a seat.
func seat_center(seat: int) -> Vector2:
	var view := _seat_views[seat]
	return view.global_position + view.size / 2.0


func set_turn(current: int, direction: int) -> void:
	_current = current
	_direction = direction
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _current >= 0:
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _radii() -> Vector2:
	var radius_x := maxf((size.x - seat_size.x) / 2.0, 1.0)
	var radius_y := maxf((size.y - seat_size.y) / 2.0, 1.0)
	return Vector2(radius_x, minf(radius_y, radius_x * MAX_ASPECT))


## Point on an oval for angle `t` (0 = bottom, growing clockwise on screen).
func _oval_point(t: float, scale_factor: float = 1.0) -> Vector2:
	var radii := _radii() * scale_factor
	return size / 2.0 + Vector2(-radii.x * sin(t), radii.y * cos(t))


## How many places clockwise from the bottom seat (you) this seat sits.
func _slot(seat: int) -> int:
	return posmod(seat - _my_seat, _player_count)


func _layout() -> void:
	if _player_count == 0:
		return
	for seat in _player_count:
		_seat_views[seat].position = _oval_point(TAU * _slot(seat) / _player_count) - seat_size / 2.0
	pile_view.position = size / 2.0 - pile_view.size / 2.0
	queue_redraw()


func _draw() -> void:
	if _player_count == 0:
		return
	_draw_felt()
	var outline := PackedVector2Array()
	for i in range(RING_SEGMENTS + 1):
		outline.append(_oval_point(TAU * i / RING_SEGMENTS))
	var glow := Palette.CYAN
	glow.a = 0.14
	draw_polyline(outline, glow, 12.0, true)
	var line := Palette.LINE.lightened(0.25)
	draw_polyline(outline, line, 3.0, true)
	for seat in _player_count:
		_draw_arrow(seat)
	if _current >= 0:
		_draw_pointer()


func _draw_felt() -> void:
	var points := PackedVector2Array()
	for i in RING_SEGMENTS:
		points.append(_oval_point(TAU * i / RING_SEGMENTS, FELT_SCALE))
	var felt := Palette.FELT
	felt.a = 0.9
	draw_colored_polygon(points, felt)
	points.append(points[0])
	var edge := Palette.CYAN
	edge.a = 0.35
	draw_polyline(points, edge, 4.0, true)


## Arrow on the stretch of oval between `seat` and the next seat clockwise.
func _draw_arrow(seat: int) -> void:
	var t := TAU * (_slot(seat) + 0.5) / _player_count
	var radii := _radii()
	var tangent := Vector2(-radii.x * cos(t), -radii.y * sin(t)).normalized()
	if _direction == Direction.COUNTER_CLOCKWISE:
		tangent = -tangent
	var normal := Vector2(-tangent.y, tangent.x)
	var middle := _oval_point(t)
	var tip := middle + tangent * ARROW_SIZE
	var base := middle - tangent * ARROW_SIZE
	var active := _arrow_is_active(seat)
	var color := Palette.LIME if active else Palette.DIM.darkened(0.3)
	var wing := ARROW_SIZE * (1.0 if active else 0.8)
	draw_colored_polygon(PackedVector2Array([tip, base + normal * wing, base - normal * wing]), color)


## The arrow leaving the current player, in the direction of play, is the lit one.
func _arrow_is_active(segment_after_seat: int) -> bool:
	if _current < 0:
		return false
	if _direction == Direction.CLOCKWISE:
		return segment_after_seat == _current
	return posmod(segment_after_seat + 1, _player_count) == _current


## A bobbing triangle just inside the ring, pointing at the player whose turn it is.
func _draw_pointer() -> void:
	var seat_middle := _oval_point(TAU * _slot(_current) / _player_count)
	var toward_centre := (size / 2.0 - seat_middle).normalized()
	var half := seat_size / 2.0
	var reach := minf(half.x / maxf(absf(toward_centre.x), 0.001), half.y / maxf(absf(toward_centre.y), 0.001))
	var base := seat_middle + toward_centre * (reach + 20.0 + sin(_time * 7.0) * BOB)
	var tip := base - toward_centre * POINTER_SIZE
	var side := Vector2(-toward_centre.y, toward_centre.x) * POINTER_SIZE * 0.8
	var back := base + toward_centre * POINTER_SIZE * 0.4
	draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Palette.LIME)
