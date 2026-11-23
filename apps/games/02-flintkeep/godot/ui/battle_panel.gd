class_name BattlePanel
extends VBoxContainer
## The bottom half of the battle screen: KEEP / WALLS / ECONOMY tabs of cash upgrades, or the
## build-and-upgrade sheet of the slot the player tapped.

signal close_slot

const TABS := ["KEEP", "WALLS", "ECONOMY"]

var battle: Battle
var _tab := "KEEP"
var _slot := -1
var _tab_buttons := {}
var _tabs_row: HBoxContainer
var _header: HBoxContainer
var _header_label: Label
var _list: VBoxContainer
var _scroll: TouchScroll
var _rows: Array[UpgradeRow] = []
var _refresh_timer := 0.0
var _slot_built := false


func _init(p_battle: Battle) -> void:
	battle = p_battle
	add_theme_constant_override("separation", 8)
	_tabs_row = Kit.hbox(6)
	add_child(_tabs_row)
	for t in TABS:
		var b := Kit.button(t, Kit.Btn.SECONDARY, 3, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_set_tab.bind(t))
		_tabs_row.add_child(b)
		_tab_buttons[t] = b
	_header = Kit.hbox(8)
	_header_label = Kit.label("", 3, Pal.GOLD)
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(_header_label)
	var close := Kit.button("X", Kit.Btn.GHOST, 3, 56)
	close.custom_minimum_size.x = 64
	close.pressed.connect(func() -> void: close_slot.emit())
	_header.add_child(close)
	add_child(_header)
	_scroll = TouchScroll.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_list = Kit.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_rebuild()


func show_slot(index: int) -> void:
	_slot = index
	_rebuild()


func _set_tab(t: String) -> void:
	_tab = t
	_slot = -1
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
	for r in _rows:
		r.refresh()


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	_tabs_row.visible = _slot < 0
	_header.visible = _slot >= 0
	for t in TABS:
		Kit.style_button(_tab_buttons[t], Kit.Btn.PRIMARY if t == _tab else Kit.Btn.SECONDARY, 3)
	var rows: Array[UpgradeRow] = []
	_slot_built = _slot >= 0 and battle.slots[_slot].tower != null
	if _slot >= 0:
		rows = BattleRows.slot_rows(battle, _slot, _rebuild)
		_header_label.text = BattleRows.slot_title(battle, _slot)
	else:
		match _tab:
			"KEEP": rows = BattleRows.keep_rows(battle)
			"WALLS": rows = BattleRows.wall_rows(battle)
			"ECONOMY": rows = BattleRows.econ_rows(battle)
	for r in rows:
		_list.add_child(r)
		_rows.append(r)
	_scroll.scroll_vertical = 0
