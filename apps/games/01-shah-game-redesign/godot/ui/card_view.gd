class_name CardView
extends Control
## One card on screen. The card itself stays clean and high-resolution (cream face, vector
## suits); only the rank uses the arcade pixel font and the border is chunky.

signal tapped(card_view: CardView)

const CARD_SIZE := Vector2(76, 108)
const FACE := Color("#FFF6DC")
const RED := Color("#E0194A")
const BLACK := Color("#120A2E")
const BACK_CELL := 8

var card: Card
var face_down: bool = false
var tappable: bool = true
var selected: bool = false:
	set(value):
		selected = value
		z_index = 1 if value else 0  # a lifted card is drawn above the row in front of it
		queue_redraw()


func _init(p_card: Card = null, p_size: Vector2 = CARD_SIZE) -> void:
	card = p_card
	custom_minimum_size = p_size
	size = p_size
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var k := size.x / CARD_SIZE.x
	if face_down or card == null:
		_draw_back(k)
		return
	var box := StyleBoxFlat.new()
	box.bg_color = FACE
	box.set_corner_radius_all(int(9 * k))
	box.border_color = Palette.YELLOW if selected else BLACK
	box.set_border_width_all(int((5 if selected else 3) * k))
	draw_style_box(box, Rect2(Vector2.ZERO, size))

	var ink := RED if SuitIcon.is_red(card.suit) else BLACK
	var px := maxi(1, roundi(3.0 * k))
	var font := PixelFont.font()
	var baseline := Vector2(9, 9) * k + Vector2(0, PixelFont.size_for(px))
	draw_string(font, baseline, card.rank_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.size_for(px), ink)
	SuitIcon.draw(self, card.suit, Vector2(17, 52) * k, 13 * k, ink)
	SuitIcon.draw(self, card.suit, Vector2(size.x * 0.6, size.y * 0.72), 36 * k, ink)


func _draw_back(k: float) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.set_corner_radius_all(int(9 * k))
	box.border_color = Palette.CYAN
	box.set_border_width_all(int(3 * k))
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var cell := BACK_CELL * k
	var inset := 8.0 * k
	var columns := int((size.x - inset * 2) / cell)
	var rows := int((size.y - inset * 2) / cell)
	for row in rows:
		for column in columns:
			if (row + column) % 2 == 0:
				draw_rect(Rect2(inset + column * cell, inset + row * cell, cell, cell), Palette.PANEL_LIGHT)


func _gui_input(event: InputEvent) -> void:
	if not tappable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
		accept_event()
