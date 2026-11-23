class_name BattleScreen
extends Control
## A run: the HUD on top, the battlefield in the middle (tap a slot to build there) and the
## upgrade panel at the bottom. Coins are banked into the profile every wave, so closing the
## app mid-run never loses them.

signal finished(goto: String)  ## "menu", "research" or "again"

## The field is drawn at 1/3 or 1/2 resolution for the pixel look. A small fortress is drawn
## bigger (1/3) so it fills the screen; with 3+ rings it zooms out to 1/2.
const ZOOM_CLOSE := 3
const ZOOM_FAR := 2
const PANEL_HEIGHT := 330.0
const SPEEDS := [1.0, 2.0, 3.0]

var tier := 1
var battle: Battle
var view: BattleView

var _speed_index := 0
var _banked := 0.0
var _cash_label: Label
var _coin_label: Label
var _wave_label: Label
var _speed_button: Button
var _hp_meter: Meter
var _wave_meter: Meter
var _panel: BattlePanel
var _banner: Label
var _banner_time := 0.0
var _field: SubViewportContainer
var _overlay: Control


func _init(p_tier: int) -> void:
	tier = p_tier
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	battle = Battle.new(Profile.data.research.duplicate(), tier)
	add_child(Kit.color_rect(Pal.BG))
	get_child(0).set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := SafeMargin.new(0)
	add_child(margin)
	var column := Kit.vbox(0)
	margin.add_child(column)
	column.add_child(_build_hud())
	column.add_child(_build_field())
	column.add_child(_build_panel())
	_banner = Kit.label("", 5, Pal.PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.add_theme_constant_override("outline_size", 0)
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_banner.add_theme_constant_override("shadow_offset_x", 4)
	_banner.add_theme_constant_override("shadow_offset_y", 4)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	_show_banner("WAVE 1", Pal.PARCHMENT)
	_update_hud()


func _build_hud() -> Control:
	var hud := Kit.panel_container(Pal.PANEL, Pal.LINE)
	var v := Kit.vbox(6)
	hud.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	top.add_child(Kit.icon(Sprites.get_tex("cash"), 3))
	_cash_label = Kit.label("", 4, Pal.CASH)
	_cash_label.custom_minimum_size.x = 150
	top.add_child(_cash_label)
	top.add_child(Kit.icon(Sprites.get_tex("coin"), 3))
	_coin_label = Kit.label("", 3, Pal.GOLD)
	_coin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_coin_label)
	_speed_button = Kit.button("1X", Kit.Btn.SECONDARY, 3, 52)
	_speed_button.custom_minimum_size.x = 72
	_speed_button.pressed.connect(_cycle_speed)
	top.add_child(_speed_button)
	var pause := Kit.button("II", Kit.Btn.SECONDARY, 3, 52)
	pause.custom_minimum_size.x = 60
	pause.pressed.connect(_pause)
	top.add_child(pause)
	var bars := Kit.hbox(8)
	v.add_child(bars)
	_hp_meter = Meter.new(Pal.RED, 30, 2)
	_hp_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_meter.size_flags_stretch_ratio = 1.6
	bars.add_child(_hp_meter)
	var wave_box := Kit.vbox(2)
	wave_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(wave_box)
	_wave_meter = Meter.new(Color("#2a7f95"), 30, 2)
	wave_box.add_child(_wave_meter)
	return hud


func _build_field() -> Control:
	_field = SubViewportContainer.new()
	_field.stretch = true
	_field.stretch_shrink = ZOOM_CLOSE if battle.rings_unlocked <= 2 else ZOOM_FAR
	_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.snap_2d_transforms_to_pixel = true
	_field.add_child(vp)
	view = BattleView.new()
	vp.add_child(view)
	view.setup(battle)
	view.event.connect(_on_battle_event)
	_field.gui_input.connect(_on_field_input)
	return _field


func _build_panel() -> Control:
	var box := Kit.panel_container(Pal.PANEL, Pal.LINE)
	box.custom_minimum_size.y = PANEL_HEIGHT
	_panel = BattlePanel.new(battle)
	_panel.close_slot.connect(_select_slot.bind(-1))
	box.add_child(_panel)
	return box


func _process(delta: float) -> void:
	_update_hud()
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.modulate.a = clampf(_banner_time / 0.4, 0.0, 1.0)
	_banner.position = Vector2((size.x - _banner.size.x) / 2.0, _field.global_position.y + 40.0)


func _update_hud() -> void:
	_cash_label.text = Num.cash(battle.cash)
	_coin_label.text = Num.fmt(Profile.data.coins + battle.coins_earned - _banked)
	_hp_meter.set_state(battle.keep_hp / battle.keep_max_hp(), "KEEP %s/%s" % [Num.fmt(battle.keep_hp), Num.fmt(battle.keep_max_hp())])
	_wave_meter.set_state(battle.wave_elapsed() / Defs.WAVE_SECONDS, "WAVE %d" % battle.wave)


func _on_field_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var field_pos: Vector2 = event.position / _field.stretch_shrink - view.position
		_select_slot(view.slot_at(field_pos))


func _select_slot(index: int) -> void:
	view.selected_slot = index
	_panel.show_slot(index)


func _cycle_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	view.speed = SPEEDS[_speed_index]
	_speed_button.text = "%dX" % int(SPEEDS[_speed_index])


func _show_banner(text: String, color: Color, seconds: float = 1.6) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_time = seconds


func _on_battle_event(e: Dictionary) -> void:
	match e["type"]:
		"wave":
			_bank_coins()
			if e["boss"]:
				_show_banner("WAVE %d\nJUGGERNAUT!" % e["wave"], Pal.ORANGE, 2.4)
			else:
				_show_banner("WAVE %d" % e["wave"], Pal.PARCHMENT)
		"interest":
			if e["cash"] >= 1.0:
				view.fx.float_text(Vector2(0, -34), "INTEREST +" + Num.cash(e["cash"]), Pal.CASH, 1.4)
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
	body.add_child(Kit.label("PAUSED", 6, Pal.PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(Kit.label("TIER %d  WAVE %d" % [tier, battle.wave], 3, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := Kit.button("RESUME", Kit.Btn.PRIMARY, 4, 80)
	resume.pressed.connect(_resume)
	body.add_child(resume)
	var retreat := Kit.button("RETREAT (END RUN)", Kit.Btn.DANGER, 3, 72)
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
	var dim := Kit.color_rect(Color(0.02, 0.03, 0.06, 0.82))
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var card := Kit.panel_container(Pal.PANEL, Pal.GOLD)
	card.custom_minimum_size.x = 460
	center.add_child(card)
	card.add_child(body)
	add_child(_overlay)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
