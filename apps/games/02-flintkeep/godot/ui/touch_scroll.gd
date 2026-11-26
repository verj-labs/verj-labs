class_name TouchScroll
extends ScrollContainer
## A ScrollContainer that scrolls with a finger drag wherever the drag starts, including on
## buttons and panels (the built-in drag scrolling only works from empty gaps, so a phone screen
## full of buttons felt stuck). When a drag starts, buttons under the finger cancel their press, so
## scrolling never clicks anything. Mouse wheel and the scroll bar keep working as normal.

const DEADZONE := 14.0  ## Layout units the finger must move before it counts as a scroll.
const FRICTION := 4.0  ## How quickly a fling slows down (per second).
const MIN_FLING := 40.0  ## Slower than this (units per second) and the fling stops.

var _touch: int = -1
var _origin: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _fling: float = 0.0  ## Scroll speed in units per second, positive = content moves up.


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_deadzone = 1000000  # switch off the built-in touch scrolling; this class replaces it


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag and event.index == _touch:
		_on_drag(event)


func _process(delta: float) -> void:
	if _touch != -1 or absf(_fling) < MIN_FLING:
		_fling = 0.0
		return
	var bar := get_v_scroll_bar()
	var before := bar.value
	bar.value += _fling * delta
	if is_equal_approx(bar.value, before):
		_fling = 0.0
	_fling = move_toward(_fling, 0.0, absf(_fling) * FRICTION * delta)


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch == -1 and is_visible_in_tree() and get_global_rect().has_point(event.position):
			_touch = event.index
			_origin = event.position
			_dragging = false
			_fling = 0.0
	elif event.index == _touch:
		_touch = -1


func _on_drag(event: InputEventScreenDrag) -> void:
	if not _dragging:
		if absf(event.position.y - _origin.y) < DEADZONE:
			return
		_dragging = true
		propagate_notification(NOTIFICATION_SCROLL_BEGIN)  # buttons under the finger drop their press
	get_v_scroll_bar().value -= event.relative.y
	_fling = -event.velocity.y
