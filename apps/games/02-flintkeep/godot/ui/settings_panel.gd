class_name SettingsPanel
extends RefCounted
## Music and sound switches, the time of day, and resetting progress (with a second tap to confirm).


static func build(on_close: Callable, allow_reset: bool = true) -> Control:
	var body := Kit.vbox(14)
	body.add_child(Kit.heading("Settings", 44, Pal.WHITE))
	var sound := Sfx.node()
	body.add_child(_toggle("Music", func() -> bool: return sound.music_on, func(on: bool) -> void: sound.set_music(on)))
	body.add_child(_toggle("Sound effects", func() -> bool: return sound.sfx_on, func(on: bool) -> void: sound.set_sfx(on)))
	body.add_child(DayPicker.card())
	if allow_reset:
		var reset := Kit.button("Reset progress", Kit.Btn.DANGER, 22, 58)
		var armed := [false]
		reset.pressed.connect(func() -> void:
			if not armed[0]:
				armed[0] = true
				reset.text = "Tap again to erase everything"
				return
			Engine.get_main_loop().root.get_node("Profile").reset()
			reset.text = "Progress reset"
			reset.disabled = true)
		body.add_child(reset)
	var close := Kit.button("Close", Kit.Btn.PRIMARY, 28, 66)
	close.pressed.connect(on_close)
	body.add_child(close)
	return body


static func _toggle(name: String, get_on: Callable, set_on: Callable) -> Control:
	var row := Kit.panel_container(Kit.card())
	var h := Kit.hbox(10)
	row.add_child(h)
	var l := Kit.label(name, 24, Pal.TEXT, Fonts.heading())
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := Kit.button("", Kit.Btn.BUY, 22, 52)
	b.custom_minimum_size.x = 110
	var paint := func() -> void:
		var on: bool = get_on.call()
		b.text = "On" if on else "Off"
		Kit.style_button(b, Kit.Btn.BUY if on else Kit.Btn.DANGER, 22)
	paint.call()
	b.pressed.connect(func() -> void:
		set_on.call(not get_on.call())
		paint.call())
	h.add_child(b)
	return row
