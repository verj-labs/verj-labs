class_name ArcadeBackground
extends Control
## The night-sky backdrop: indigo gradient, twinkling pixel stars, and a neon grid floor that
## slowly scrolls towards you. `intensity` dims it for screens that need calm (the table).

const STAR_COUNT := 70
const HORIZON := 0.58
const GRID_LINES_ACROSS := 14
const GRID_LINES_DEEP := 9
const SCROLL_SPEED := 0.12

var intensity: float = 1.0

var _time: float = 0.0
var _stars: Array[Vector3] = []  # x, y (0..1) and twinkle phase


func _init(p_intensity: float = 1.0) -> void:
	intensity = p_intensity
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in STAR_COUNT:
		_stars.append(Vector3(rng.randf(), rng.randf() * HORIZON, rng.randf() * TAU))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Palette.BG_DEEP
	var bottom := Palette.BG_MID
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bottom, bottom])
	)
	for star in _stars:
		var twinkle := 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 2.0 + star.z))
		var shade := Color(1, 1, 1, twinkle * 0.7 * intensity)
		var pixel := 4.0 if star.z > 4.2 else 2.0
		draw_rect(Rect2(star.x * w, star.y * h, pixel, pixel), shade)
	_draw_grid(w, h)


func _draw_grid(w: float, h: float) -> void:
	var horizon_y := h * HORIZON
	var floor_color := Palette.PURPLE
	floor_color.a = 0.32 * intensity
	var vanish := Vector2(w / 2.0, horizon_y)
	for i in range(-GRID_LINES_ACROSS, GRID_LINES_ACROSS + 1):
		var bottom_x := w / 2.0 + i * (w / GRID_LINES_ACROSS) * 1.3
		draw_line(vanish, Vector2(bottom_x, h), floor_color, 2.0)
	var scroll := fposmod(_time * SCROLL_SPEED, 1.0)
	for i in GRID_LINES_DEEP:
		var t := (i + scroll) / GRID_LINES_DEEP
		var y := horizon_y + (h - horizon_y) * t * t
		var fade := floor_color
		fade.a *= 0.4 + 0.6 * t
		draw_line(Vector2(0, y), Vector2(w, y), fade, 2.0)
	var glow := Palette.PINK
	glow.a = 0.55 * intensity
	draw_line(Vector2(0, horizon_y), Vector2(w, horizon_y), glow, 3.0)
