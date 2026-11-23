class_name RunSummary
extends RefCounted
## The card shown when the Keep falls or the player retreats.


static func build(b: Battle, tier: int, record: bool, coins: float, goto: Callable) -> Control:
	var body := Kit.vbox(10)
	var fell := b.keep_hp <= 0.0
	body.add_child(Kit.heading("The Keep has fallen" if fell else "You retreated", 34, Pal.RED if fell else Pal.PARCHMENT))
	if record:
		body.add_child(Kit.label("New best wave!", 22, Pal.GOLD, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER))
	var stats := Kit.vbox(6)
	stats.add_child(_stat("Tier", str(tier)))
	stats.add_child(_stat("Wave reached", str(b.wave)))
	stats.add_child(_stat("Best wave", str(Profile.data.best(tier))))
	stats.add_child(_stat("Enemies slain", Num.fmt(b.kills)))
	stats.add_child(_stat("Coins earned", Num.fmt(coins), Pal.GOLD))
	var box := Kit.panel_container(Pal.PANEL_DEEP, Pal.LINE)
	box.add_child(stats)
	body.add_child(box)
	if tier == Profile.data.unlocked_tier - 1 and b.wave >= Defs.TIER_UNLOCK_WAVE:
		body.add_child(Kit.label("Tier %d unlocked!" % (tier + 1), 22, Pal.CYAN, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER))
	var research := Kit.button("Research", Kit.Btn.PRIMARY, 26, 70)
	research.pressed.connect(goto.bind("research"))
	body.add_child(research)
	var row := Kit.hbox(10)
	var again := Kit.button("Play again", Kit.Btn.BUY, 21, 60)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(goto.bind("again"))
	row.add_child(again)
	var menu := Kit.button("Menu", Kit.Btn.SECONDARY, 21, 60)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(goto.bind("menu"))
	row.add_child(menu)
	body.add_child(row)
	return body


static func _stat(name: String, value: String, color: Color = Pal.PARCHMENT) -> Control:
	var row := Kit.hbox(8)
	var l := Kit.label(name, 19, Pal.DIM, Fonts.body())
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(Kit.label(value, 21, color, Fonts.bold(), HORIZONTAL_ALIGNMENT_RIGHT))
	return row
