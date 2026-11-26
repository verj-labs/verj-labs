class_name BestiaryPanel
extends RefCounted
## The bestiary (from the menu): every raider you have met, with what it does and its base
## stats (they grow every wave). Raiders you have not met yet are dark silhouettes that say when
## they arrive: "Arrives at wave 35", or "Raids from tier 2".


static func build(on_close: Callable) -> Control:
	var data: ProfileData = Engine.get_main_loop().root.get_node("Profile").data
	var body := Kit.vbox(12)
	body.add_child(Kit.heading("Bestiary", 40, Pal.WHITE))
	var met := Defs.ENEMY_ORDER.filter(func(kind: String) -> bool: return data.enemy_seen(kind)).size()
	body.add_child(Kit.label("%d of %d raiders met. Stats are at wave 1; they grow every wave." % [met, Defs.ENEMY_ORDER.size()],
		18, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true))
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size.y = 600
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := Kit.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for kind in Defs.ENEMY_ORDER:
		list.add_child(_card(kind, data.enemy_seen(kind)))
	var close := Kit.button("Close", Kit.Btn.PRIMARY, 28, 66)
	close.pressed.connect(on_close)
	body.add_child(close)
	return body


static func _card(kind: String, met: bool) -> Control:
	var info: Dictionary = Defs.ENEMY_ROSTER[kind]
	var stats: Dictionary = Defs.ENEMIES[kind]
	var card := Kit.panel_container(Kit.card())
	var row := Kit.hbox(12)
	card.add_child(row)
	var art := Kit.icon(kind, 76)
	if not met:
		art.modulate = Color(0.05, 0.05, 0.1, 0.75)  # a silhouette until you meet it
	row.add_child(art)
	var v := Kit.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(Kit.label(info["name"] if met else "???", 24, Pal.TEXT, Fonts.heading()))
	if not met:
		v.add_child(Kit.label(arrival(kind), 18, Pal.TEXT_DIM, Fonts.semibold(), HORIZONTAL_ALIGNMENT_LEFT, true))
		return card
	v.add_child(Kit.label(info["about"], 16, Pal.TEXT_DIM, Fonts.semibold(), HORIZONTAL_ALIGNMENT_LEFT, true))
	var lines: Array[String] = []
	lines.append("Health %s  ·  %s" % [Num.fmt(stats["hp"]), speed_word(stats["speed"])])
	if float(stats.get("burst", 0.0)) > 0.0:
		lines.append("Blast %s on a wall" % Num.fmt(stats["burst"]))
	else:
		lines.append("Damage %s/s" % Num.fmt(stats["dps"]))
	var traits: Array[String] = []
	if stats["air"]:
		traits.append("Flies")
	if stats["armor"] > 0.0:
		traits.append("Armour " + Num.pct(stats["armor"]))
	if stats["ward"] > 0.0:
		traits.append("Ward " + Num.pct(stats["ward"]))
	if float(stats.get("heal", 0.0)) > 0.0:
		traits.append("Heals " + Num.pct(stats["heal"]) + "/s")
	traits.append("Bounty $" + Num.fmt(stats["cash"]))
	lines.append("  ·  ".join(traits))
	lines.append(arrival(kind))
	for line in lines:
		v.add_child(Kit.label(line, 17, Pal.TEXT, Fonts.bold(), HORIZONTAL_ALIGNMENT_LEFT, true))
	return card


## When a kind first raids: "Every 10th wave", "Arrives at wave 35", "Raids from tier 2 (wave 5)".
static func arrival(kind: String) -> String:
	var info: Dictionary = Defs.ENEMY_ROSTER[kind]
	if kind == "juggernaut":
		return "Every %dth wave" % Defs.BOSS_EVERY
	var tier := int(info["tier"])
	if tier > 1:
		return "Raids from tier %d (wave %d)" % [tier, int(info["wave"])]
	return "From the first wave" if int(info["wave"]) <= 1 else "Arrives at wave %d" % int(info["wave"])


static func speed_word(speed: float) -> String:
	var word := "Slow"
	if speed >= 30.0:
		word = "Very fast"
	elif speed >= 18.0:
		word = "Fast"
	elif speed >= 14.0:
		word = "Steady"
	return "%s (%d)" % [word, int(speed)]
