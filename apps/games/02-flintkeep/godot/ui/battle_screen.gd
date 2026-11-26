class_name BattleScreen
extends Control
## A run: the HUD on top, the battlefield in the middle (tap an empty foundation to build there,
## or a tower to upgrade it) and the upgrade panel at the bottom. Coins are banked into the
## profile every wave, so closing the app mid-run never loses them.

signal finished(goto: String)  ## "menu", "research" or "again"

const PANEL_HEIGHT := 340.0

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
var _tutorial: Tutorial
var _early_button: Button
var _boss_meter: Meter
var _perk_overlay: Control
var _perk_label: Label


func _init(p_tier: int) -> void:
	tier = p_tier
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	battle = Battle.new(Profile.data.research.duplicate(), tier, 0, Profile.data.workshop.duplicate())
	Profile.data.refresh_missions(Missions.today())
	var bg := Kit.color_rect(Pal.GRASS)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := SafeMargin.new(0)
	add_child(margin)
	var column := Kit.vbox(0)
	margin.add_child(column)
	column.add_child(_build_hud())
	column.add_child(_build_field())
	column.add_child(_build_panel())
	_banner = Kit.heading("", 48, Pal.WHITE)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	_show_banner("Wave 1", Pal.WHITE)
	if not Profile.data.tutorial_done:
		_tutorial = Tutorial.new(battle, view)
		_field.add_child(_tutorial)
		_tutorial.anchor_left = 0.0
		_tutorial.anchor_right = 1.0
		_tutorial.anchor_top = 1.0
		_tutorial.anchor_bottom = 1.0
		_tutorial.offset_left = 12
		_tutorial.offset_right = -12
		_tutorial.offset_bottom = -12
		_tutorial.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_update_hud()


func _build_hud() -> Control:
	var hud := PanelContainer.new()
	var style := Kit.box(Pal.WOOD, Pal.INK, 0, 0)
	style.border_width_bottom = 4
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	hud.add_theme_stylebox_override("panel", style)
	var v := Kit.vbox(8)
	hud.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	var cash: Array = Kit.pill("cash", Pal.CASH)
	_cash_label = cash[1]
	_cash_label.add_theme_font_size_override("font_size", 28)
	_cash_label.custom_minimum_size.x = 110
	top.add_child(cash[0])
	var coins: Array = Kit.pill("coin", Pal.GOLD)
	_coin_label = coins[1]
	top.add_child(coins[0])
	top.add_child(Kit.spacer(true))
	_speed_button = Kit.button("1x", Kit.Btn.SECONDARY, 22, 50)
	_speed_button.custom_minimum_size.x = 64
	_speed_button.pressed.connect(_cycle_speed)
	top.add_child(_speed_button)
	var pause := Kit.button("II", Kit.Btn.PRIMARY, 22, 50)
	pause.custom_minimum_size.x = 56
	pause.pressed.connect(_pause)
	top.add_child(pause)
	var bars := Kit.hbox(8)
	v.add_child(bars)
	bars.add_child(Kit.icon("heart", 30))
	_hp_meter = Meter.new(Color("#ff4d4d"), 32, 18)
	_hp_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_meter.size_flags_stretch_ratio = 1.5
	bars.add_child(_hp_meter)
	_wave_meter = Meter.new(Color("#3fb6ff"), 32, 18)
	_wave_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_child(_wave_meter)
	_early_button = Kit.button(">>", Kit.Btn.BUY, 18, 36)
	_early_button.custom_minimum_size.x = 52
	_early_button.tooltip_text = "Call the next wave now for bonus cash"
	_early_button.pressed.connect(func() -> void: battle.call_next_wave())
	bars.add_child(_early_button)
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
	_boss_meter = Meter.new(Color("#ff7a2a"), 30, 16)
	_boss_meter.anchor_left = 0.0
	_boss_meter.anchor_right = 1.0
	_boss_meter.offset_left = 60
	_boss_meter.offset_right = -60
	_boss_meter.offset_top = 8
	_boss_meter.offset_bottom = 38
	_boss_meter.visible = false
	_field.add_child(_boss_meter)
	return _field


func _build_panel() -> Control:
	var box := PanelContainer.new()
	var style := Kit.box(Pal.WOOD, Pal.INK, 22, 3)
	style.border_width_bottom = 0
	style.border_width_left = 0
	style.border_width_right = 0
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
	_update_boss_bar()
	if _perk_overlay != null:
		if battle.perk_offer.is_empty():
			_perk_overlay.queue_free()
			_perk_overlay = null
		else:
			_perk_label.text = "Picked for you in %ds" % int(ceil(battle.perk_time))
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
	_early_button.disabled = not battle.can_call_early()


func _on_field_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var slot := view.slot_at(event.position)
		if slot >= 0:
			Input.vibrate_handheld(12)
			_select_slot(slot)
			return
		var section := view.section_at(event.position)
		if section.x > 0:
			_select_section(section)
		else:
			_select_slot(-1)


func _select_slot(index: int) -> void:
	view.selected_slot = index
	view.selected_section = Vector2i(-1, -1)
	_panel.show_slot(index)


func _select_section(section: Vector2i) -> void:
	view.selected_slot = -1
	view.selected_section = section
	_panel.show_section(section.x, section.y)


## Cycles 1x, 2x ... up to the fastest speed researched in the labs.
func _cycle_speed() -> void:
	var top := Research.max_speed(Profile.data.level("game_speed"))
	if top <= 1:
		_show_banner("Research Game speed\nto play faster", Pal.WHITE, 2.0)
		return
	_speed_index = (_speed_index + 1) % top
	view.speed = 1.0 + _speed_index
	_speed_button.text = "%dx" % (1 + _speed_index)


func _show_banner(text: String, color: Color, seconds: float = 1.6) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_time = seconds


func _update_boss_bar() -> void:
	var boss: Entities.Enemy = null
	for e in battle.enemies:
		if e.boss:
			boss = e
			break
	_boss_meter.visible = boss != null
	if boss != null:
		_boss_meter.set_state(boss.hp / boss.max_hp, "Juggernaut  %s" % Num.fmt(maxf(boss.hp, 0.0)))


## Every 100 waves: three perks to choose from, picked at random when the timer runs out.
func _offer_perks() -> void:
	if _perk_overlay != null:
		return
	var body := Kit.vbox(10)
	body.add_child(Kit.heading("Choose a perk", 34, Pal.GOLD))
	_perk_label = Kit.label("", 18, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true)
	body.add_child(_perk_label)
	for id in battle.perk_offer:
		var p: Dictionary = Perks.LIST[id]
		var b := Kit.button("%s: %s" % [p["name"], p["about"]], Kit.Btn.PRIMARY, 18, 58)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void: battle.choose_perk(id))
		body.add_child(b)
	_perk_overlay = Kit.modal(self, body, 480)


func _on_battle_event(e: Dictionary) -> void:
	_track_missions(e)
	match e["type"]:
		"perk_offer":
			_offer_perks()
		"perk_chosen":
			_show_banner(Perks.LIST[e["id"]]["name"] + "!", Pal.GOLD)
		"power":
			_show_banner(Powers.LIST[e["id"]]["name"] + "!", Pal.CYAN, 1.2)
		"wave":
			_bank_coins()
			Sfx.play("boss" if e["boss"] else "wave", 0.0)
			var fresh := _new_enemy(e["wave"])
			if fresh != "" and not e["boss"]:
				_show_banner("Wave %d\nNew enemy: %s" % [e["wave"], fresh], Pal.ORANGE, 2.4)
			elif e["boss"]:
				_show_banner("Wave %d\nThe Juggernaut comes" % e["wave"], Pal.ORANGE, 2.6)
			else:
				_show_banner("Wave %d" % e["wave"], Pal.WHITE)
		"early":
			view.fx.float_text(Vector2(0, -48), "Early! +" + Num.cash(e["cash"]), Pal.CASH, 1.4, 8)
		"interest":
			if e["cash"] >= 1.0:
				view.fx.float_text(Vector2(0, -40), "Wave pay +" + Num.cash(e["cash"]), Pal.CASH, 1.4, 7)
		"game_over":
			Sfx.play("game_over", 0.0)
			_end_run()


const ENEMY_NAMES := {"runner": "Runners", "balloon": "War balloons (flyers)", "brute": "Armoured brutes",
	"sapper": "Sappers (blow up walls)", "wyvern": "Wyverns (flyers)", "shaman": "Shamans (heal others)"}


func _new_enemy(wave: int) -> String:
	for kind in Defs.ENEMY_WAVES:
		if int(Defs.ENEMY_WAVES[kind][0]) == wave and ENEMY_NAMES.has(kind):
			return ENEMY_NAMES[kind]
	return ""


func _track_missions(e: Dictionary) -> void:
	var list: Array = Profile.data.missions
	match e["type"]:
		"kill":
			Missions.track(list, "kills", 1)
			if Defs.ENEMIES[e["kind"]]["air"]:
				Missions.track(list, "flyers", 1)
			if e["boss"]:
				Missions.track(list, "boss", 1)
		"wave": Missions.track(list, "wave", e["wave"])
		"built": Missions.track(list, "build", 1)
		"upgraded": Missions.track(list, "upgrade", 1)
		"wall_built": Missions.track(list, "walls", 1)


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
	body.add_child(Kit.heading("Paused", 44))
	body.add_child(Kit.label("Tier %d  ·  Wave %d" % [tier, battle.wave], 22, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true))
	var resume := Kit.button("Resume", Kit.Btn.PRIMARY, 26, 72)
	resume.pressed.connect(_resume)
	body.add_child(resume)
	var settings := Kit.button("Settings", Kit.Btn.SECONDARY, 24, 62)
	settings.pressed.connect(func() -> void:
		_close_overlay()
		_open_overlay(SettingsPanel.build(func() -> void:
			_close_overlay()
			_pause(), false)))
	body.add_child(settings)
	var retreat := Kit.button("Retreat and end the run", Kit.Btn.DANGER, 22, 60)
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
	_overlay = Kit.modal(self, body)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
