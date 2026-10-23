class_name PixelIcon
extends Control
## Tiny 8x8 icons drawn as big square pixels, so they match the pixel font.

const ICONS := {
	"music": ["...##...", "...#.#..", "...#..#.", "...#....", "...#....", ".###....", "####....", ".##....."],
	"speaker": ["...#....", "..##..#.", "####...#", "####.#.#", "####.#.#", "####...#", "..##..#.", "...#...."],
	"cross": ["#......#", ".#....#.", "..#..#..", "...##...", "...##...", "..#..#..", ".#....#.", "#......#"],
	"arrow_down": ["########", ".######.", "..####..", "...##...", "........", "........", "........", "........"],
	"heart": [".##..##.", "########", "########", "########", ".######.", "..####..", "...##...", "........"],
	"star": ["...##...", "...##...", "########", ".######.", "..####..", ".##..##.", ".#....#.", "........"],
}

var icon: String = "music":
	set(value):
		icon = value
		queue_redraw()
var color: Color = Palette.CREAM:
	set(value):
		color = value
		queue_redraw()
var unit: int = 4:
	set(value):
		unit = value
		custom_minimum_size = Vector2.ONE * 8 * unit
		queue_redraw()


func _init(p_icon: String = "music", p_unit: int = 4, p_color: Color = Palette.CREAM) -> void:
	icon = p_icon
	color = p_color
	unit = p_unit
	custom_minimum_size = Vector2.ONE * 8 * unit
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	PixelIcon.paint(self, icon, Vector2.ZERO, unit, color)


## Draws an icon onto any canvas item (used by custom-drawn controls).
static func paint(canvas: CanvasItem, icon_name: String, origin: Vector2, pixel: float, tint: Color) -> void:
	var rows: Array = ICONS[icon_name]
	for y in 8:
		for x in 8:
			if (rows[y] as String)[x] == "#":
				canvas.draw_rect(Rect2(origin + Vector2(x, y) * pixel, Vector2(pixel, pixel)), tint)
