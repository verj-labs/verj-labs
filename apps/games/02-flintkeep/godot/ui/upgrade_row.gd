class_name UpgradeRow
extends PanelContainer
## One line of an upgrade list: an optional icon, a title, a detail line ("12.4 → 15.1") and
## one or more buttons. Everything is read through callables, so refresh() just re-asks.
##
## actions: [{"label": Callable -> String, "price": Callable -> float (-1 = unavailable),
##            "run": Callable -> bool, "kind": Kit.Btn (optional), "wallet": Callable -> float}]

signal acted

var _title_fn: Callable
var _detail_fn: Callable
var _actions: Array
var _title: Label
var _detail: Label
var _buttons: Array[Button] = []


static func make(title: Variant, detail: Callable, actions: Array, accent: Color = Pal.TEXT, icon: String = "") -> UpgradeRow:
	var row := UpgradeRow.new()
	row._title_fn = title if title is Callable else func() -> String: return str(title)
	row._detail_fn = detail
	row._actions = actions
	row._build(accent, icon)
	return row


func _build(accent: Color, icon: String) -> void:
	add_theme_stylebox_override("panel", Kit.card())
	custom_minimum_size.y = 72
	var h := Kit.hbox(10)
	add_child(h)
	if icon != "":
		var art := Kit.icon(icon, 46)
		art.custom_minimum_size = Vector2(40, 56)
		h.add_child(art)
	var texts := Kit.vbox(2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(texts)
	_title = Kit.label("", 22, accent, Fonts.heading())
	_title.clip_text = true
	texts.add_child(_title)
	_detail = Kit.label("", 17, Pal.TEXT_DIM, Fonts.semibold())
	_detail.clip_text = true
	texts.add_child(_detail)
	for a in _actions:
		var b := Kit.button("", a.get("kind", Kit.Btn.BUY), 22 if _actions.size() == 1 else 18, 54)
		b.custom_minimum_size.x = 124 if _actions.size() == 1 else 104
		b.pressed.connect(_on_pressed.bind(a))
		h.add_child(b)
		_buttons.append(b)
	refresh()


func _on_pressed(action: Dictionary) -> void:
	if (action["run"] as Callable).call():
		acted.emit()
	else:
		Sfx.play("denied")


func refresh() -> void:
	_title.text = _title_fn.call()
	_detail.text = _detail_fn.call()
	for i in _actions.size():
		var a: Dictionary = _actions[i]
		var b := _buttons[i]
		b.text = (a["label"] as Callable).call()
		var price: float = (a["price"] as Callable).call()
		var wallet: float = (a["wallet"] as Callable).call()
		b.disabled = price < 0.0 or wallet + 0.001 < price
