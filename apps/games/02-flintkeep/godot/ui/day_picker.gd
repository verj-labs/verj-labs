class_name DayPicker
extends RefCounted
## The time-of-day choice: Auto (a 5-minute loop), My clock (follows the phone's time), or a
## fixed Sunrise, Day, Sunset or Night. A segmented control in two rows; used in Settings and in
## the battle's sun/moon button. The choice is saved in the profile.


static func build(on_change: Callable = Callable()) -> Control:
	var profile: Node = Engine.get_main_loop().root.get_node("Profile")
	var box := Kit.vbox(8)
	var buttons := {}
	var paint := func() -> void:
		for mode in buttons:
			Kit.style_button(buttons[mode], Kit.Btn.TAB_ON if profile.data.day_mode == mode else Kit.Btn.TAB, 19)
	var rows := [DayNight.MODES.slice(0, 2), DayNight.MODES.slice(2)]
	for modes in rows:
		var row := Kit.hbox(6)
		box.add_child(row)
		for mode in modes:
			var b := Kit.button(DayNight.MODE_NAMES[mode], Kit.Btn.TAB, 19, 52)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.clip_text = true
			b.pressed.connect(func() -> void:
				profile.data.day_mode = mode
				profile.save_game()
				paint.call()
				if on_change.is_valid():
					on_change.call(mode))
			row.add_child(b)
			buttons[mode] = b
	paint.call()
	return box


## A card with a title, a line of explanation and the picker (for Settings).
static func card() -> Control:
	var panel := Kit.panel_container(Kit.card())
	var v := Kit.vbox(8)
	panel.add_child(v)
	v.add_child(Kit.label("Time of day", 24, Pal.TEXT, Fonts.heading()))
	v.add_child(Kit.para("Auto loops sunrise, day, sunset and night every 5 minutes.", 16, Pal.TEXT_DIM, Fonts.semibold()))
	v.add_child(build())
	return panel
