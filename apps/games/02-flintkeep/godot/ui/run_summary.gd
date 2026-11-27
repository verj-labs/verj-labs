class_name RunSummary
extends RefCounted
## The card shown when the Keep falls or the player retreats.


static func build(b: Battle, tier: int, record: bool, coins: float, goto: Callable) -> Control:
	var body := Kit.vbox(10)
	var fell := b.keep_hp <= 0.0
	body.add_child(Kit.heading("The Keep has fallen!" if fell else "You retreated", 36, Pal.RED if fell else Pal.WHITE))
	if record:
		body.add_child(Kit.heading("New best wave!", 26, Pal.GOLD))
	var stats := Kit.vbox(6)
	stats.add_child(_stat("Tier", str(tier)))
	stats.add_child(_stat("Wave reached", str(b.wave)))
	stats.add_child(_stat("Best wave", str(Profile.data.best(tier))))
	stats.add_child(_stat("Enemies slain", Num.fmt(b.kills)))
	stats.add_child(_stat("Coins earned", Num.fmt(coins), Color("#b7791f")))
	_add_report(stats, b)
	var box := Kit.panel_container(Kit.card())
	box.add_child(stats)
	body.add_child(box)
	if tier == Profile.data.unlocked_tier - 1 and b.wave >= Defs.TIER_UNLOCK_WAVE:
		body.add_child(Kit.heading("Tier %d unlocked!" % (tier + 1), 24, Pal.CYAN))
	var ready: int = Profile.data.claimable()
	if ready > 0:
		body.add_child(Kit.heading("%d mission%s complete! Claim on the menu." % [ready, "" if ready == 1 else "s"], 21, Pal.CASH))
	var research := Kit.button("Research", Kit.Btn.PRIMARY, 30, 72)
	research.pressed.connect(goto.bind("research"))
	body.add_child(research)
	var row := Kit.hbox(10)
	var again := Kit.button("Play again", Kit.Btn.BUY, 24, 62)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(goto.bind("again"))
	row.add_child(again)
	var menu := Kit.button("Menu", Kit.Btn.SECONDARY, 24, 62)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(goto.bind("menu"))
	row.add_child(menu)
	body.add_child(row)
	return body


const ENEMY_NAMES := {"footman": "Raiders", "runner": "Sprinters", "brute": "Brutes", "balloon": "War balloons",
	"wyvern": "Wyverns", "sapper": "Sappers", "shaman": "Shamans", "juggernaut": "the Juggernaut",
	"warlord": "the Goblin Warlord", "golem": "the Siege Golem", "dragon": "the Dragon"}


## What did the damage, and what finally broke the Keep: so players know what to research next.
static func _add_report(stats: VBoxContainer, b: Battle) -> void:
	var total := 0.0
	for src in b.damage_by:
		total += float(b.damage_by[src])
	var sources: Array = b.damage_by.keys()
	sources.sort_custom(func(x: String, y: String) -> bool: return b.damage_by[x] > b.damage_by[y])
	for src in sources.slice(0, 3):
		stats.add_child(_stat("Damage: " + src, Num.pct(b.damage_by[src] / maxf(total, 1.0))))
	if b.keep_hp <= 0.0 and b.killed_by != "":
		stats.add_child(_stat("Keep broken by", ENEMY_NAMES.get(b.killed_by, b.killed_by), Pal.RED))


static func _stat(name: String, value: String, color: Color = Pal.TEXT) -> Control:
	var row := Kit.hbox(8)
	var l := Kit.label(name, 20, Pal.TEXT_DIM, Fonts.semibold())
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(Kit.label(value, 22, color, Fonts.heading(), HORIZONTAL_ALIGNMENT_RIGHT))
	return row
