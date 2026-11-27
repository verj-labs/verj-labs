class_name HeroesPanel
extends RefCounted
## Pick the hero who stands by the Keep in your runs. Locked heroes say which champion's wave to
## beat; the choice is saved and used from the next run.


static func build(on_close: Callable) -> Control:
	var profile: Node = Engine.get_main_loop().root.get_node("Profile")
	var body := Kit.vbox(12)
	body.add_child(Kit.heading("Heroes", 40, Pal.WHITE))
	body.add_child(Kit.para("Beat a champion's wave to unlock a hero. One hero stands by the Keep each run.",
		18, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true))
	var list := Kit.vbox(10)
	body.add_child(list)
	var refresh := [Callable()]
	refresh[0] = func() -> void:
		for c in list.get_children():
			c.queue_free()
		for id in Heroes.ORDER:
			list.add_child(_card(profile, id, refresh[0]))
		var none := Kit.button("No hero" if profile.data.hero != "" else "No hero (chosen)", Kit.Btn.SECONDARY, 20, 50)
		none.disabled = profile.data.hero == ""
		none.pressed.connect(func() -> void:
			profile.data.hero = ""
			profile.save_game()
			refresh[0].call())
		list.add_child(none)
	refresh[0].call()
	var close := Kit.button("Close", Kit.Btn.PRIMARY, 28, 66)
	close.pressed.connect(on_close)
	body.add_child(close)
	return body


static func _card(profile: Node, id: String, refresh: Callable) -> Control:
	var h: Dictionary = Heroes.LIST[id]
	var unlocked: bool = profile.data.hero_unlocked(id)
	var card := Kit.panel_container(Kit.card())
	var row := Kit.hbox(12)
	card.add_child(row)
	var art := Kit.icon(id, 70)
	if not unlocked:
		art.modulate = Color(0.05, 0.05, 0.1, 0.75)
	row.add_child(art)
	var v := Kit.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(Kit.label(h["name"] if unlocked else "???", 24, Pal.TEXT, Fonts.heading()))
	if not unlocked:
		var champion: String = Defs.ENEMY_ROSTER[h["champion"]]["name"]
		v.add_child(Kit.para("Beat wave %d (the %s) to unlock" % [Heroes.unlock_wave(id), champion], 17, Pal.TEXT_DIM, Fonts.semibold()))
		return card
	v.add_child(Kit.para(h["passive"], 16, Pal.TEXT, Fonts.bold()))
	v.add_child(Kit.para("%s: %s (every %ds)" % [h["ability"], h["about"], int(h["cooldown"])], 16, Pal.TEXT_DIM, Fonts.semibold()))
	var chosen: bool = profile.data.hero == id
	var pick := Kit.button("Chosen" if chosen else "Choose", Kit.Btn.BUY if not chosen else Kit.Btn.SECONDARY, 20, 48)
	pick.custom_minimum_size.x = 110
	pick.disabled = chosen
	pick.pressed.connect(func() -> void:
		profile.data.hero = id
		profile.save_game()
		refresh.call())
	row.add_child(pick)
	return card
