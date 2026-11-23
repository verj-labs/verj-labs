class_name MissionsPanel
extends RefCounted
## Today's three missions with progress bars and Claim buttons (shown in a modal).


static func build(on_close: Callable) -> Control:
	var data: ProfileData = Engine.get_main_loop().root.get_node("Profile").data
	data.refresh_missions(Missions.today())
	var body := Kit.vbox(12)
	body.add_child(Kit.heading("Daily Missions", 40, Pal.WHITE))
	body.add_child(Kit.label("New missions every day. Finish them in any run.", 18, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true))
	for i in data.missions.size():
		body.add_child(_card(data, i))
	var close := Kit.button("Close", Kit.Btn.PRIMARY, 28, 66)
	close.pressed.connect(on_close)
	body.add_child(close)
	return body


static func _card(data: ProfileData, index: int) -> Control:
	var m: Dictionary = data.missions[index]
	var card := Kit.panel_container(Kit.card())
	var v := Kit.vbox(8)
	card.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	var title := Kit.label(Missions.title(m), 22, Pal.TEXT, Fonts.heading())
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(title)
	top.add_child(Kit.icon("coin", 26))
	top.add_child(Kit.label(str(m["reward"]), 22, Color("#b7791f"), Fonts.heading()))
	var bottom := Kit.hbox(10)
	v.add_child(bottom)
	var meter := Meter.new(Pal.CASH, 30, 17)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var progress := mini(int(m["progress"]), int(m["target"]))
	meter.set_state(float(progress) / float(m["target"]), "%d / %d" % [progress, int(m["target"])])
	bottom.add_child(meter)
	var claim := Kit.button("Claim", Kit.Btn.BUY, 20, 46)
	claim.custom_minimum_size.x = 104
	if m["claimed"]:
		claim.text = "Done"
		claim.disabled = true
	elif not Missions.done(m):
		claim.disabled = true
	claim.pressed.connect(func() -> void:
		var profile: Node = Engine.get_main_loop().root.get_node("Profile")
		if profile.data.claim(index):
			Sfx.play("coin", 0.0)
			profile.save_game()
			profile.changed.emit()
			claim.text = "Done"
			claim.disabled = true)
	bottom.add_child(claim)
	return card
