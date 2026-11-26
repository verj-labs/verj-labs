class_name UpgradeCard
extends PanelContainer
## A compact upgrade card for the two-column grid: name, "now → next", and a buy button.
## Reads everything through callables, so refresh() just re-asks the battle.

var _name_fn: Callable
var _value_fn: Callable
var _label_fn: Callable
var _price_fn: Callable
var _wallet_fn: Callable
var _run: Callable
var _name: Label
var _value: Label
var _button: Button


static func make(name: Variant, value: Callable, label: Callable, price: Callable, wallet: Callable, run: Callable, kind: Kit.Btn = Kit.Btn.BUY) -> UpgradeCard:
	var c := UpgradeCard.new()
	c._name_fn = name if name is Callable else func() -> String: return str(name)
	c._value_fn = value
	c._label_fn = label
	c._price_fn = price
	c._wallet_fn = wallet
	c._run = run
	c._build(kind)
	return c


func _build(kind: Kit.Btn) -> void:
	add_theme_stylebox_override("panel", Kit.card(12))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := Kit.vbox(3)
	add_child(v)
	_name = Kit.label("", 18, Pal.TEXT, Fonts.heading())
	_name.clip_text = true
	v.add_child(_name)
	_value = Kit.label("", 15, Pal.TEXT_DIM, Fonts.semibold())
	_value.clip_text = true
	v.add_child(_value)
	_button = Kit.button("", kind, 19, 46)
	_button.pressed.connect(_on_pressed)
	v.add_child(_button)
	refresh()


func _on_pressed() -> void:
	if _run.call():
		Input.vibrate_handheld(15)
		refresh()
	else:
		Sfx.play("denied")


func refresh() -> void:
	_name.text = _name_fn.call()
	_value.text = _value_fn.call()
	_button.text = _label_fn.call()
	var price: float = _price_fn.call()
	_button.disabled = price < 0.0 or float(_wallet_fn.call()) + 0.001 < price
