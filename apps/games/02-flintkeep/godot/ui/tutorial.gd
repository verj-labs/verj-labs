class_name Tutorial
extends PanelContainer
## First-run tips shown over the battlefield, one at a time. Each step waits for the player to
## do the thing it asks (or for a few seconds), then the next appears. Runs once per profile.

const STEPS := [
	{"text": "Tap the glowing foundation to build your first tower!", "until": "tower"},
	{"text": "Nice! Enemies come in waves. Each kill pays cash.", "seconds": 5.0},
	{"text": "Tap the gap between two towers to build a wall section. Walls stop ground enemies.", "until": "wall"},
	{"text": "Tap a tower to upgrade it. The Keep tab makes your Keep stronger.", "seconds": 7.0},
	{"text": "Coins you earn are kept forever. Spend them in Research after the run!", "seconds": 7.0},
]

var battle: Battle
var view: BattleView
var _step := -1
var _timer := 0.0
var _label: Label


func _init(p_battle: Battle, p_view: BattleView) -> void:
	battle = p_battle
	view = p_view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := Kit.card(18)
	style.content_margin_left = 14
	style.content_margin_right = 16
	style.border_color = Pal.INK
	style.set_border_width_all(3)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", style)
	var h := Kit.hbox(12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	h.add_child(Kit.icon("keep", 48))
	_label = Kit.label("", 21, Pal.TEXT, Fonts.bold())
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_label)
	_next()


func _process(delta: float) -> void:
	if _step < 0 or _step >= STEPS.size():
		return
	var step: Dictionary = STEPS[_step]
	_timer += delta
	var done := false
	match step.get("until", ""):
		"tower": done = _towers() > 0
		"wall": done = battle.walls[1].built
		_: done = _timer >= float(step.get("seconds", 5.0))
	view.hint_slot = _first_open_slot() if step.get("until", "") == "tower" else -1
	modulate.a = clampf(_timer / 0.3, 0.0, 1.0)
	if done:
		_next()


func _next() -> void:
	_step += 1
	_timer = 0.0
	if _step >= STEPS.size():
		view.hint_slot = -1
		Profile.data.tutorial_done = true
		Profile.save_game()
		queue_free()
		return
	_label.text = STEPS[_step]["text"]


func _towers() -> int:
	var n := 0
	for slot in battle.slots:
		if slot.tower != null:
			n += 1
	return n


func _first_open_slot() -> int:
	for slot in battle.slots:
		if battle.slot_open(slot.index) and slot.tower == null:
			return slot.index
	return -1
