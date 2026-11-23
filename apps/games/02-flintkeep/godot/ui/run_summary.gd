class_name RunSummary
extends RefCounted
## The card shown when the Keep falls or the player retreats.


static func build(b: Battle, tier: int, record: bool, coins: float, goto: Callable) -> Control:
	var body := Kit.vbox(12)
	var fell := b.keep_hp <= 0.0
	body.add_child(Kit.label("THE KEEP" if fell else "YOU", 6, Pal.RED if fell else Pal.PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(Kit.label("HAS FALLEN" if fell else "RETREATED", 6, Pal.RED if fell else Pal.PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER))
	if record:
		body.add_child(Kit.label("NEW BEST!", 4, Pal.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(_stat("TIER", str(tier)))
	body.add_child(_stat("WAVE REACHED", str(b.wave)))
	body.add_child(_stat("BEST WAVE", str(Profile.data.best(tier))))
	body.add_child(_stat("ENEMIES SLAIN", Num.fmt(b.kills)))
	body.add_child(_stat("COINS EARNED", Num.fmt(coins), Pal.GOLD))
	if tier == Profile.data.unlocked_tier - 1 and b.wave >= Defs.TIER_UNLOCK_WAVE:
		body.add_child(Kit.label("TIER %d UNLOCKED!" % (tier + 1), 3, Pal.CYAN, HORIZONTAL_ALIGNMENT_CENTER))
	var research := Kit.button("RESEARCH", Kit.Btn.PRIMARY, 4, 76)
	research.pressed.connect(goto.bind("research"))
	body.add_child(research)
	var row := Kit.hbox(10)
	var again := Kit.button("PLAY AGAIN", Kit.Btn.BUY, 3, 68)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(goto.bind("again"))
	row.add_child(again)
	var menu := Kit.button("MENU", Kit.Btn.SECONDARY, 3, 68)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(goto.bind("menu"))
	row.add_child(menu)
	body.add_child(row)
	return body


static func _stat(name: String, value: String, color: Color = Pal.PARCHMENT) -> Control:
	var row := Kit.hbox(8)
	var l := Kit.label(name, 3, Pal.DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(Kit.label(value, 3, color, HORIZONTAL_ALIGNMENT_RIGHT))
	return row
