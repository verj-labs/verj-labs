class_name TurnTimerBar
extends Control
## The turn timer: a row of arcade blocks that empties as time runs out, green then yellow then
## red, flashing in the last moments.

const HEIGHT := 28.0
const BLOCKS := 20
const GAP := 4.0
const YELLOW_BELOW := 0.5
const RED_BELOW := 0.25
const FLASH_BELOW := 0.15

var _ratio: float = 0.0
var _active: bool = false
var _time: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## `ratio` is the fraction of time left (1.0 = full). Inactive shows empty blocks.
func show_time(active: bool, ratio: float) -> void:
	_active = active
	_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta


func _draw() -> void:
	var block_w := (size.x - GAP * (BLOCKS - 1)) / BLOCKS
	var lit := ceili(_ratio * BLOCKS) if _active else 0
	var color := Palette.LIME
	if _ratio < RED_BELOW:
		color = Palette.RED
	elif _ratio < YELLOW_BELOW:
		color = Palette.YELLOW
	var flashing := _active and _ratio < FLASH_BELOW and int(_time * 8.0) % 2 == 0
	for i in BLOCKS:
		var rect := Rect2(i * (block_w + GAP), 0, block_w, size.y)
		if i < lit and not flashing:
			draw_rect(rect, color)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), color.lightened(0.4))
		else:
			draw_rect(rect, Palette.PANEL)
			draw_rect(rect, Palette.LINE.darkened(0.2), false, 2.0)
