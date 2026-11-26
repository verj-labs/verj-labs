class_name ResearchScreen
extends Control
## Spend coins on permanent upgrades. Two labs work at once; research keeps going while the
## game is closed.

signal back

const GROUP_ICONS := {"Keep": "keep", "Economy": "coin", "Arsenal": "cannon", "Fortress": "slot"}

var _coins_label: Label
var _lab_meters: Array[Meter] = []
var _rows: Array[UpgradeRow] = []
var _refresh_timer := 0.0


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
	var title := Kit.heading("Research", 42, Pal.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var pill: Array = Kit.pill("coin", Pal.GOLD)
	_coins_label = pill[1]
	top.add_child(pill[0])
	col.add_child(top)

	var labs := Kit.panel_container(Kit.wood())
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
	var list := Kit.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
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
	_refresh()


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
	var icon := id if Defs.WEAPONS.has(id) else ""
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
