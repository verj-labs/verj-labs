class_name BattlePanel
extends VBoxContainer
## The bottom of the battle screen: six tabs (Attack, Defense, Walls, Towers, Economy, Powers) of
## upgrade cards in a two-column grid, each tab with an Auto-buy switch; or, after tapping the
## battlefield, the sheet of a tower, an empty pedestal or a wall section. The Towers tab acts on
## every tower at once (upgrade all, add-ons for all, targeting).

signal close_slot

var battle: Battle
var _tab := "Attack"
var _slot := -1
var _section := Vector2i(-1, -1)  ## (ring, segment) of a selected wall section
var _slot_built := false
var _tab_buttons := {}
var _tabs_row: HBoxContainer
var _header: HBoxContainer
var _header_label: Label
var _list: VBoxContainer
var _scroll: TouchScroll
var _refreshers: Array = []  ## cards and rows with a refresh() method
var _auto_button: Button
var _refresh_timer := 0.0


func _init(p_battle: Battle) -> void:
	battle = p_battle
	add_theme_constant_override("separation", 8)
	_tabs_row = Kit.hbox(4)
	add_child(_tabs_row)
	for t in Upgrades.TABS:
		var b := Kit.button(t, Kit.Btn.TAB, 15, 46)
		Kit.tighten(b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		b.pressed.connect(_set_tab.bind(t))
		_tabs_row.add_child(b)
		_tab_buttons[t] = b
	_header = Kit.hbox(8)
	_header_label = Kit.heading("", 24, Pal.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_label.clip_text = true
	_header.add_child(_header_label)
	var close := Kit.button("Done", Kit.Btn.SECONDARY, 20, 46)
	close.custom_minimum_size.x = 88
	close.pressed.connect(func() -> void: close_slot.emit())
	_header.add_child(close)
	add_child(_header)
	_scroll = TouchScroll.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_list = Kit.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_rebuild()


func show_slot(index: int) -> void:
	_slot = index
	_section = Vector2i(-1, -1)
	_rebuild()


func show_section(ring: int, seg: int) -> void:
	_slot = -1
	_section = Vector2i(ring, seg)
	_rebuild()


func _set_tab(t: String) -> void:
	_tab = t
	_slot = -1
	_section = Vector2i(-1, -1)
	close_slot.emit()
	_rebuild()


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.15
		refresh()


func refresh() -> void:
	if _slot >= 0 and (battle.slots[_slot].tower != null) != _slot_built:
		_rebuild()  # the slot changed under us (built or sold elsewhere)
		return
	for r in _refreshers:
		if is_instance_valid(r):
			r.refresh()
	if is_instance_valid(_auto_button):
		_paint_auto()


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_refreshers.clear()
	_auto_button = null
	var focused := _slot >= 0 or _section.x > 0
	_tabs_row.visible = not focused
	_header.visible = focused
	for t in Upgrades.TABS:
		Kit.style_button(_tab_buttons[t], Kit.Btn.TAB_ON if t == _tab else Kit.Btn.TAB, 15)
		Kit.tighten(_tab_buttons[t])
	_slot_built = _slot >= 0 and battle.slots[_slot].tower != null
	if _slot >= 0:
		_header_label.text = BattleRows.slot_title(battle, _slot)
		_add_rows(BattleRows.slot_rows(battle, _slot, _rebuild))
	elif _section.x > 0:
		_header_label.text = BattleRows.section_title(_section.x, _section.y)
		_add_rows(BattleRows.section_rows(battle, _section.x, _section.y, _rebuild))
	else:
		_build_tab()
	_scroll.scroll_vertical = 0


func _build_tab() -> void:
	if _tab != "Powers":
		_auto_button = Kit.button("", Kit.Btn.SECONDARY, 17, 40)
		_auto_button.pressed.connect(func() -> void:
			battle.set_auto(_tab, not battle.auto_tabs.get(_tab, false))
			_paint_auto())
		_list.add_child(_auto_button)
		_paint_auto()
	if _tab == "Walls":
		_add_rows(BattleRows.wall_rows(battle))
	var cards: Array[Control]
	match _tab:
		"Powers": cards = BattleRows.power_cards(battle)
		"Towers": cards = BattleRows.tower_cards(battle)
		_: cards = BattleRows.upgrade_cards(battle, _tab)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c in cards:
		grid.add_child(c)
		_refreshers.append(c)
	_list.add_child(grid)


func _paint_auto() -> void:
	var on: bool = battle.auto_tabs.get(_tab, false)
	_auto_button.text = "Auto-buy %s: %s" % [_tab, "on" if on else "off"]
	Kit.style_button(_auto_button, Kit.Btn.BUY if on else Kit.Btn.SECONDARY, 17)


func _add_rows(rows: Array) -> void:
	for r in rows:
		_list.add_child(r)
		_refreshers.append(r)
