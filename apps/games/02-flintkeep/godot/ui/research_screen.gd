class_name ResearchScreen
extends Control
## Spend coins on permanent upgrades. Two labs work at once; research keeps going while the
## game is closed.

signal back

var _coins_label: Label
var _lab_meters: Array[Meter] = []
var _rows: Array[UpgradeRow] = []
var _refresh_timer := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	var bg := Kit.color_rect(Pal.BG)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := SafeMargin.new(16)
	add_child(margin)
	var col := Kit.vbox(10)
	margin.add_child(col)

	var top := Kit.hbox(10)
	var back_button := Kit.button("<", Kit.Btn.SECONDARY, 4, 64)
	back_button.custom_minimum_size.x = 72
	back_button.pressed.connect(func() -> void: back.emit())
	top.add_child(back_button)
	var title := Kit.label("RESEARCH", 5, Pal.PARCHMENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(Kit.icon(Sprites.get_tex("coin"), 4))
	_coins_label = Kit.label("", 4, Pal.GOLD)
	top.add_child(_coins_label)
	col.add_child(top)

	for i in Profile.data.labs.size():
		var m := Meter.new(Pal.ARCANE, 40, 2)
		col.add_child(m)
		_lab_meters.append(m)

	var scroll := TouchScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var list := Kit.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for group in Research.GROUPS:
		var header := Kit.label(group, 3, Pal.CYAN)
		header.custom_minimum_size.y = 40
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
		return "%s LV%d" % [item["name"], data.level(id)]
	var detail := func() -> String:
		var text := Research.describe(id, data.level(id))
		if not data.is_maxed(id):
			text += "  " + Num.duration(data.next_seconds(id))
		return text
	var price := func() -> float:
		var block := data.blocker(id)
		return -1.0 if block != "" and block != "NEED COINS" else data.next_cost(id)
	var label := func() -> String:
		var block := data.blocker(id)
		if block in ["MAX", "IN LAB", "LABS BUSY"] or block.begins_with("NEEDS"):
			return "MAX" if block == "MAX" else ("IN LAB" if block == "IN LAB" else ("BUSY" if block == "LABS BUSY" else "LOCKED"))
		return Num.fmt(data.next_cost(id))
	var action := {"label": label, "price": price, "run": Profile.start_research.bind(id), "kind": Kit.Btn.PRIMARY,
		"wallet": func() -> float: return data.coins}
	var row := UpgradeRow.make(title, detail, [action], Pal.PARCHMENT)
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
			_lab_meters[i].set_state(0.0, "LAB %d: IDLE" % (i + 1))
			continue
		var total := Research.seconds(id, data.level(id))
		var left := data.seconds_left(i, now)
		_lab_meters[i].set_state(1.0 - left / maxf(total, 1.0), "%s  %s" % [Research.ITEMS[id]["name"], Num.duration(left)])
	for r in _rows:
		r.refresh()
