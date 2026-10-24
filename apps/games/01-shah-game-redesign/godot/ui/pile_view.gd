class_name PileView
extends VBoxContainer
## The middle of the table: what is on the pile in big pixel letters, plus the cards.

const SIZE_NAMES := ["", "SINGLE", "DOUBLE", "TRIPLE", "QUAD"]
const SMALL_CARD := Vector2(80, 114)
const TITLE_SCALE := 4
## Longer titles drop one pixel scale so they stay between the seats on a narrow table.
const LONG_TITLE := 7
const CARD_OVERLAP := 28.0
const CARD_STEP := SMALL_CARD.x - CARD_OVERLAP  ## Card width minus the row's overlap.

var _title: ShadowLabel
var _subtitle: Label
var _cards_row: HBoxContainer


func _init() -> void:
	custom_minimum_size = Vector2(290, 200)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	_title = ShadowLabel.new("", 4, Palette.YELLOW, Palette.BG_DEEP)
	_subtitle = UIKit.pixel_label("", 3, Palette.DIM)
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", -int(CARD_OVERLAP))
	_cards_row.custom_minimum_size = Vector2(0, SMALL_CARD.y)
	add_child(_title)
	add_child(_cards_row)
	add_child(_subtitle)


## `note` replaces the "<owner> played" line (used for "<name> took the round").
func show_pile(pile: Play, owner_name: String, note: String = "") -> void:
	for child in _cards_row.get_children():
		_cards_row.remove_child(child)
		child.queue_free()
	if pile == null:
		_title.set_text("EMPTY")
		_title.set_colors(Palette.DIM, Palette.BG_DEEP)
		_subtitle.text = "LEAD ANYTHING"
		_subtitle.add_theme_color_override("font_color", Palette.DIM)
		return
	var title := "%s %s" % [SIZE_NAMES[pile.size], pile.cards[0].rank_text()]
	_title.set_pixel_scale(TITLE_SCALE if title.length() <= LONG_TITLE else TITLE_SCALE - 1)
	_title.set_text(title)
	_title.set_colors(Palette.YELLOW, Palette.BG_DEEP)
	_subtitle.text = note if note != "" else "%s PLAYED" % owner_name
	_subtitle.add_theme_color_override("font_color", Palette.PINK if note != "" else Palette.DIM)
	for card in pile.cards:
		var view := CardView.new(card, SMALL_CARD)
		view.tappable = false
		_cards_row.add_child(view)


## Screen positions where `count` cards of the pile will sit (for cards flying in).
func landing_centers(count: int) -> Array[Vector2]:
	var middle := _cards_row.global_position + _cards_row.size / 2.0
	var result: Array[Vector2] = []
	for i in count:
		result.append(middle + Vector2((i - (count - 1) / 2.0) * CARD_STEP, 0.0))
	return result
