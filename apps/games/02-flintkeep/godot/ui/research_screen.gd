class_name ResearchScreen
extends Control
## Spend coins on permanent upgrades. Two labs work at once; research keeps going while the
## game is closed.

signal back

const GROUP_ICONS := {"Command": "keep", "Arsenal": "cannon", "Powers": "arcane", "Fortress": "slot"}

var _coins_label: Label
var _lab_meters: Array[Meter] = []
var _rows: Array[UpgradeRow] = []
var _refresh_timer := 0.0
var _tab_workshop: Button
var _tab_labs: Button
var _workshop_list: VBoxContainer
var _labs_list: VBoxContainer
var _labs_box: Control


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	add_child(Kit.backdrop())
	var margin := SafeMargin.new(16)
	add_child(margin)
	var col := Kit.vbox(10)
	margin.add_child(col)

	var top := Kit.hbox(10)
	var back_button := Kit.button("<", Kit.Btn.SECONDARY, 30, 58)
	back_button.custom_minimum_size.x = 64
	back_button.pressed.connect(func() -> void: back.emit())
	top.add_child(back_button)
	var title := Kit.heading("Upgrades", 40, Pal.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var pill: Array = Kit.pill("coin", Pal.GOLD)
	_coins_label = pill[1]
	top.add_child(pill[0])
	col.add_child(top)

	var tabs := Kit.hbox(6)
	_tab_workshop = Kit.button("Workshop", Kit.Btn.TAB_ON, 22, 50)
	_tab_labs = Kit.button("Labs", Kit.Btn.TAB, 22, 50)
	for b in [_tab_workshop, _tab_labs]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	_tab_workshop.pressed.connect(_show.bind(true))
	_tab_labs.pressed.connect(_show.bind(false))
	col.add_child(tabs)
	var labs := Kit.panel_container(Kit.wood())
	_labs_box = labs
	var lab_list := Kit.vbox(8)
	labs.add_child(lab_list)
	for i in Profile.data.labs.size():
		var m := Meter.new(Color("#b45cff"), 36, 18)
		lab_list.add_child(m)
		_lab_meters.append(m)
	col.add_child(labs)

	var frame := Kit.panel_container(Kit.wood())
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(frame)
	var scroll := TouchScroll.new()
	frame.add_child(scroll)
	var holder := Kit.vbox(8)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	_workshop_list = Kit.vbox(8)
	holder.add_child(_workshop_list)
	_workshop_list.add_child(Kit.label("Instant, permanent upgrades. Expensive, and they stack.", 18, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true))
	for id in Workshop.ORDER:
		var row := _workshop_row(id)
		_workshop_list.add_child(row)
		_rows.append(row)
	var list := Kit.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(list)
	_labs_list = list
	for group in Research.GROUPS:
		var header := Kit.hbox(10)
		header.custom_minimum_size.y = 48
		header.add_child(Kit.icon(GROUP_ICONS[group], 30))
		header.add_child(Kit.heading(group, 28, Pal.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		list.add_child(header)
		for id in Research.ids_in(group):
			var row := _row(id)
			list.add_child(row)
			_rows.append(row)
	Profile.changed.connect(_refresh)
	_show(true)
	_refresh()


func _show(workshop: bool) -> void:
	_workshop_list.visible = workshop
	_labs_list.visible = not workshop
	_labs_box.visible = not workshop
	Kit.style_button(_tab_workshop, Kit.Btn.TAB_ON if workshop else Kit.Btn.TAB, 22)
	Kit.style_button(_tab_labs, Kit.Btn.TAB if workshop else Kit.Btn.TAB_ON, 22)


func _workshop_row(id: String) -> UpgradeRow:
	var data := Profile.data
	var item: Dictionary = Workshop.ITEMS[id]
	var title := func() -> String: return "%s  ·  Lv %d" % [item["name"], data.workshop_level(id)]
	var detail := func() -> String: return Workshop.describe(id, data.workshop_level(id))
	var price := func() -> float: return -1.0 if Workshop.maxed(id, data.workshop_level(id)) else data.workshop_cost(id)
	var label := func() -> String: return "Max" if Workshop.maxed(id, data.workshop_level(id)) else Num.fmt(data.workshop_cost(id))
	var buy := func() -> bool:
		var ok := data.buy_workshop(id)
		if ok:
			Sfx.play("upgrade", 0.0)
			Profile.save_game()
			Profile.changed.emit()
		return ok
	var action := {"label": label, "price": price, "run": buy, "kind": Kit.Btn.PRIMARY, "wallet": func() -> float: return data.coins}
	return UpgradeRow.make(title, detail, [action], Pal.TEXT)


func _row(id: String) -> UpgradeRow:
	var data := Profile.data
	var title := func() -> String:
		var item: Dictionary = Research.ITEMS[id]
		if int(item["max"]) == 1:
			return item["name"]
		return "%s  ·  Lv %d" % [item["name"], data.level(id)]
	var detail := func() -> String:
		var text := Research.describe(id, data.level(id))
		if not data.is_maxed(id):
			text += "   ·   " + Num.duration(data.next_seconds(id)).to_lower()
		return text
	var price := func() -> float:
		var block := data.blocker(id)
		return -1.0 if block != "" and block != "NEED COINS" else data.next_cost(id)
	var label := func() -> String:
		match data.blocker(id):
			"MAX": return "Done"
			"IN LAB": return "In lab"
			"LABS BUSY": return "Busy"
		if data.blocker(id).begins_with("NEEDS"):
			return "Locked"
		return Num.fmt(data.next_cost(id))
	var action := {"label": label, "price": price, "run": Profile.start_research.bind(id), "kind": Kit.Btn.PRIMARY,
		"wallet": func() -> float: return data.coins}
	var icon := id if Defs.WEAPONS.has(id) else ("arcane" if id.begins_with("power_") else "")
	var row := UpgradeRow.make(title, detail, [action], Pal.TEXT, icon)
	row.acted.connect(_refresh)
	return row


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.25
		_refresh()


func _refresh() -> void:
	var data := Profile.data
	_coins_label.text = Num.fmt(data.coins)
	var now := Profile.now()
	for i in _lab_meters.size():
		var lab: Dictionary = data.labs[i]
		var id: String = lab["id"]
		if id == "":
			_lab_meters[i].set_state(0.0, "Lab %d is idle" % (i + 1))
			continue
		var total := Research.seconds(id, data.level(id))
		var left := data.seconds_left(i, now)
		_lab_meters[i].set_state(1.0 - left / maxf(total, 1.0), "%s  ·  %s" % [Research.ITEMS[id]["name"], Num.duration(left).to_lower()])
	for r in _rows:
		r.refresh()
