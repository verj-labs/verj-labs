class_name BattleScreen
extends Control
## A run: the HUD on top, the battlefield in the middle (tap an empty foundation to build there,
## or a tower to upgrade it) and the upgrade panel at the bottom. Coins are banked into the
## profile every wave, so closing the app mid-run never loses them.

signal finished(goto: String)  ## "menu", "research" or "again"

const PANEL_HEIGHT := 340.0
const SPEEDS := [1.0, 2.0, 3.0]

var tier := 1
var battle: Battle
var view: BattleView

var _speed_index := 0
var _banked := 0.0
var _cash_label: Label
var _coin_label: Label
var _speed_button: Button
var _hp_meter: Meter
var _wave_meter: Meter
var _panel: BattlePanel
var _banner: Label
var _banner_time := 0.0
var _field: Control
var _overlay: Control


func _init(p_tier: int) -> void:
	tier = p_tier
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	battle = Battle.new(Profile.data.research.duplicate(), tier)
	add_child(Kit.backdrop())
	var margin := SafeMargin.new(0)
	add_child(margin)
	var column := Kit.vbox(0)
	margin.add_child(column)
	column.add_child(_build_hud())
	column.add_child(_build_field())
	column.add_child(_build_panel())
	_banner = Kit.heading("", 44, Pal.PARCHMENT)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	_show_banner("Wave 1", Pal.PARCHMENT)
	_update_hud()


func _build_hud() -> Control:
	var hud := PanelContainer.new()
	var box := Kit.panel(Pal.PANEL, Pal.LINE, 0, 0)
	box.border_width_bottom = 2
	box.border_color = Pal.BRASS_DIM
	box.content_margin_left = 16
	box.content_margin_right = 16
	hud.add_theme_stylebox_override("panel", box)
	var v := Kit.vbox(8)
	hud.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	top.add_child(Kit.icon("cash", 34))
	_cash_label = Kit.label("", 30, Pal.CASH, Fonts.bold())
	_cash_label.custom_minimum_size.x = 140
	top.add_child(_cash_label)
	top.add_child(Kit.icon("coin", 26))
	_coin_label = Kit.label("", 22, Pal.GOLD, Fonts.bold())
	_coin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_coin_label)
	_speed_button = Kit.button("1x", Kit.Btn.SECONDARY, 20, 48)
	_speed_button.custom_minimum_size.x = 64
	_speed_button.pressed.connect(_cycle_speed)
	top.add_child(_speed_button)
	var pause := Kit.button("II", Kit.Btn.SECONDARY, 18, 48)
	pause.custom_minimum_size.x = 56
	pause.pressed.connect(_pause)
	top.add_child(pause)
	var bars := Kit.hbox(10)
	v.add_child(bars)
	bars.add_child(Kit.icon("heart", 26))
	_hp_meter = Meter.new(Color("#d8453d"), 28, 16)
	_hp_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_meter.size_flags_stretch_ratio = 1.5
	bars.add_child(_hp_meter)
	_wave_meter = Meter.new(Color("#3f8fa6"), 28, 16)
	_wave_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(_wave_meter)
	return hud


func _build_field() -> Control:
	_field = Control.new()
	_field.clip_contents = true
	_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view = BattleView.new()
	_field.add_child(view)
	view.setup(battle)
	view.event.connect(_on_battle_event)
	_field.gui_input.connect(_on_field_input)
	return _field


func _build_panel() -> Control:
	var box := PanelContainer.new()
	var style := Kit.panel(Pal.PANEL, Pal.BRASS_DIM, 18, 0)
	style.border_width_top = 2
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_top = 12
	box.add_theme_stylebox_override("panel", style)
	box.custom_minimum_size.y = PANEL_HEIGHT
	_panel = BattlePanel.new(battle)
	_panel.close_slot.connect(_select_slot.bind(-1))
	box.add_child(_panel)
	return box


func _process(delta: float) -> void:
	view.layout(_field.size)
	_update_hud()
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clampf(_banner_time / 0.4, 0.0, 1.0)
	_banner.size.x = size.x
	_banner.position = Vector2(0, _field.global_position.y + 24.0)


func _update_hud() -> void:
	_cash_label.text = Num.cash(battle.cash)
	_coin_label.text = Num.fmt(Profile.data.coins + battle.coins_earned - _banked)
	_hp_meter.set_state(battle.keep_hp / battle.keep_max_hp(), "%s / %s" % [Num.fmt(battle.keep_hp), Num.fmt(battle.keep_max_hp())])
	_wave_meter.set_state(battle.wave_elapsed() / Defs.WAVE_SECONDS, "Wave %d" % battle.wave)


func _on_field_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_slot(view.slot_at(view.to_field(event.position)))


func _select_slot(index: int) -> void:
	view.selected_slot = index
	_panel.show_slot(index)


func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	view.speed = SPEEDS[_speed_index]
	_speed_button.text = "%dx" % int(SPEEDS[_speed_index])


func _show_banner(text: String, color: Color, seconds: float = 1.6) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_time = seconds


func _on_battle_event(e: Dictionary) -> void:
	match e["type"]:
		"wave":
			_bank_coins()
			if e["boss"]:
				_show_banner("Wave %d\nThe Juggernaut comes" % e["wave"], Pal.ORANGE, 2.6)
			else:
				_show_banner("Wave %d" % e["wave"], Pal.PARCHMENT)
		"interest":
			if e["cash"] >= 1.0:
				view.fx.float_text(Vector2(0, -40), "Interest +" + Num.cash(e["cash"]), Pal.CASH, 1.4, 7)
		"game_over":
			_end_run()


func _bank_coins() -> void:
	Profile.add_coins(battle.coins_earned - _banked)
	_banked = battle.coins_earned
	Profile.save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and battle != null:
		_bank_coins()


# --- Pause and game over ------------------------------------------------------------------------

func _pause() -> void:
	if _overlay != null:
		return
	view.paused = true
	var body := Kit.vbox(16)
	body.add_child(Kit.heading("Paused", 40))
	body.add_child(Kit.label("Tier %d  ·  Wave %d" % [tier, battle.wave], 20, Pal.DIM, null, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := Kit.button("Resume", Kit.Btn.PRIMARY, 26, 72)
	resume.pressed.connect(_resume)
	body.add_child(resume)
	var retreat := Kit.button("Retreat and end the run", Kit.Btn.DANGER, 20, 60)
	retreat.pressed.connect(_end_run)
	body.add_child(retreat)
	_open_overlay(body)


func _resume() -> void:
	_close_overlay()
	view.paused = false


func _end_run() -> void:
	_close_overlay()
	view.paused = true
	battle.over = true
	_bank_coins()
	var record := Profile.data.record_run(tier, battle.wave, battle.kills)
	Profile.save_game()
	_open_overlay(RunSummary.build(battle, tier, record, _banked, finished.emit))


func _open_overlay(body: Control) -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := Kit.color_rect(Color(0.02, 0.03, 0.05, 0.78))
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var card := Kit.panel_container(Pal.PANEL, Pal.BRASS, 20)
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = 24
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_right = 24
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 22
	(card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_bottom = 22
	card.custom_minimum_size.x = 460
	center.add_child(card)
	card.add_child(body)
	add_child(_overlay)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
