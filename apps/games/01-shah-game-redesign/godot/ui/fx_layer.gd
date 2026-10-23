class_name FxLayer
extends Control
## A transparent layer over the whole table where cards fly between places (throws, the
## exchange). Cards here are temporary pictures; they free themselves when they land.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Flies a card from one screen point to another. Returns the tween (await its `finished`).
## `vanish` fades the card out at the end (used when cards are handed away).
func fly(
	card: Card,
	face_down: bool,
	from_center: Vector2,
	to_center: Vector2,
	card_size: Vector2,
	start_scale: float,
	end_scale: float,
	duration: float,
	delay: float = 0.0,
	vanish: bool = false
) -> Tween:
	var view := CardView.new(card, card_size)
	view.tappable = false
	view.face_down = face_down
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.pivot_offset = card_size / 2.0
	view.scale = Vector2.ONE * start_scale
	view.modulate.a = 0.0
	add_child(view)
	view.global_position = from_center - card_size / 2.0

	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: view.modulate.a = 1.0)
	tween.tween_property(view, "global_position", to_center - card_size / 2.0, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(view, "scale", Vector2.ONE * end_scale, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if vanish:
		tween.parallel().tween_property(view, "modulate:a", 0.0, duration * 0.35).set_delay(duration * 0.65)
	tween.tween_callback(view.queue_free)
	return tween
