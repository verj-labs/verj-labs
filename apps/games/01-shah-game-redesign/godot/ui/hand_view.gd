class_name HandView
extends Control
## Your hand: cards sorted low to high, up to two overlapping rows, tap to select.
## Selection rule: tapping adds to the selection if it is the same rank, otherwise it
## starts a new selection (only equal-rank sets can be played).

signal selection_changed

const ROW_MAX := 9
const ROW_OVERLAP := 0.72  ## Fraction of card height between row tops.
const LIFT := 18.0  ## How far a selected card pops up.
const MAX_ROWS := 2

var interactive: bool = true:
	set(value):
		interactive = value
		for view in _views:
			view.tappable = value

var _views: Array[CardView] = []


func _init() -> void:
	custom_minimum_size = Vector2(0, LIFT + CardView.CARD_SIZE.y * (1.0 + ROW_OVERLAP) + 6)
	clip_contents = false


## `hidden` cards are laid out but invisible (until reveal()): used while a card is flying in.
func set_cards(cards: Array[Card], hidden: Array[Card] = []) -> void:
	var keep := {}
	for view in _views:
		if view.selected:
			keep[view.card.to_code()] = true
		remove_child(view)
		view.queue_free()
	_views.clear()

	var sorted: Array[Card] = cards.duplicate()
	sorted.sort_custom(func(a: Card, b: Card) -> bool:
		return a.strength() < b.strength() if a.strength() != b.strength() else a.suit < b.suit
	)
	for card in sorted:
		var view := CardView.new(card)
		view.selected = keep.has(card.to_code())
		view.tappable = interactive
		if _contains(hidden, card):
			view.modulate.a = 0.0
		view.tapped.connect(_on_card_tapped)
		add_child(view)
		_views.append(view)
	_layout()
	selection_changed.emit()


## Screen position of the middle of a card in the hand (valid after set_cards).
func card_center(card: Card) -> Vector2:
	var view := _view_of(card)
	return view.global_position + view.size / 2.0 if view != null else global_position + size / 2.0


func reveal(card: Card) -> void:
	var view := _view_of(card)
	if view != null:
		view.modulate.a = 1.0


## Screen positions of the selected cards, in the same order as selected_cards().
func selected_global_centers() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for view in _views:
		if view.selected:
			result.append(view.global_position + view.size / 2.0)
	return result


func selected_cards() -> Array[Card]:
	var result: Array[Card] = []
	for view in _views:
		if view.selected:
			result.append(view.card)
	return result


func clear_selection() -> void:
	for view in _views:
		view.selected = false
	_layout()
	selection_changed.emit()


func _view_of(card: Card) -> CardView:
	for view in _views:
		if view.card.rank == card.rank and view.card.suit == card.suit:
			return view
	return null


func _contains(list: Array[Card], card: Card) -> bool:
	for other in list:
		if other.rank == card.rank and other.suit == card.suit:
			return true
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _on_card_tapped(tapped_view: CardView) -> void:
	AudioDirector.play_sfx("select", 0.05)
	if tapped_view.selected:
		tapped_view.selected = false
	else:
		var other_rank_selected := false
		for view in _views:
			if view.selected and view.card.rank != tapped_view.card.rank:
				other_rank_selected = true
		if other_rank_selected:
			for view in _views:
				view.selected = false
		tapped_view.selected = true
	_layout()
	selection_changed.emit()


func _layout() -> void:
	var total := _views.size()
	if total == 0 or size.x <= 0.0:
		return
	var rows := clampi(ceili(float(total) / ROW_MAX), 1, MAX_ROWS)
	var per_row := ceili(float(total) / rows)
	var card_size := CardView.CARD_SIZE
	var row_step := card_size.y * ROW_OVERLAP
	for row in rows:
		var first := row * per_row
		var count := mini(per_row, total - first)
		var spacing := 0.0
		if count > 1:
			spacing = minf(card_size.x + 4.0, (size.x - card_size.x) / (count - 1))
		var row_width := card_size.x + spacing * (count - 1)
		var x := (size.x - row_width) / 2.0
		for i in count:
			var view := _views[first + i]
			var y := LIFT + row * row_step - (LIFT if view.selected else 0.0)
			view.position = Vector2(x + spacing * i, y)
