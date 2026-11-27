class_name AutoPlayer
extends RefCounted
## A simple greedy player used by the balance tests (and handy for an attract mode later).
## Each think() it buys the cheapest useful thing it can afford: fill open slots, raise walls,
## then upgrade whatever is cheapest.

## Which cash upgrades the bot buys, and how keen it is (lower = sooner).
const WEIGHTS := {
	"damage": 1.0, "health": 1.0, "rate": 1.2, "regen": 1.3, "crit_chance": 1.3, "crit_factor": 1.6,
	"multishot": 1.6, "bounce": 1.8, "armor": 1.4, "absolute": 1.8, "lifesteal": 2.0, "bounty": 1.3,
	"wave_cash": 1.5, "wall_regen": 2.0, "push_chance": 2.5,
}
const ADDON_WEIGHTS := {"crit": 1.2, "multishot": 1.4, "bounce": 1.5, "push": 2.5}


static func think(b: Battle) -> void:
	for i in 20:  # spend in several steps, cheapest first
		if not _buy_one(b):
			return


static func _buy_one(b: Battle) -> bool:
	var options: Array = []  # [cost, Callable]
	var weapon := _next_weapon(b)
	for slot in b.slots:
		if b.slot_open(slot.index) and slot.tower == null:
			options.append([b.build_cost(weapon) * 0.5, b.build.bind(slot.index, weapon)])
			break
	for ring in range(1, b.rings_unlocked + 1):
		var gap := b.walls[ring].sections.find(false)
		if gap != -1:
			options.append([b.section_cost(ring) * 0.8, b.build_section.bind(ring, gap)])
		elif b.wave > 6:
			options.append([b.wall_reinforce_cost(ring) * 1.5, b.reinforce_wall.bind(ring)])
	for ring in range(1, b.rings_unlocked + 1):
		for id in Defs.WALL_ADDON_ORDER:
			var price := b.wall_addon_cost(ring, id)
			if price >= 0.0:
				options.append([price * 1.6, b.buy_wall_addon.bind(ring, id)])
	for id in WEIGHTS:
		if not b.upgrade_maxed(id):
			options.append([b.upgrade_cost(id) * WEIGHTS[id], b.buy_upgrade.bind(id)])
	for slot in b.slots:
		if slot.tower != null:
			options.append([b.tower_upgrade_cost(slot.index), b.upgrade_tower.bind(slot.index)])
			for id in Defs.ADDON_ORDER:
				var price := b.addon_cost(slot.index, id)
				if price >= 0.0:
					options.append([price * ADDON_WEIGHTS[id], b.buy_addon.bind(slot.index, id)])
	options.sort_custom(func(a: Array, c: Array) -> bool: return a[0] < c[0])
	if options.is_empty():
		return false
	# Weighted choice: save up for the best-value option instead of buying something else.
	return (options[0][1] as Callable).call()


## Mixes weapons: mostly muskets, plus an anti-air or splash tower when they are unlocked.
static func _next_weapon(b: Battle) -> String:
	var counts := {}
	for slot in b.slots:
		if slot.tower != null:
			counts[slot.tower.weapon] = counts.get(slot.tower.weapon, 0) + 1
	for weapon in ["cannon", "volley", "sniper", "arcane"]:
		if b.weapon_unlocked(weapon) and counts.get(weapon, 0) < counts.get("musket", 0):
			return weapon
	return "musket"


## Plays a whole run as fast as possible. Returns the wave the Keep fell on.
static func play(research: Dictionary, tier: int, seed_value: int, max_wave: int = 200, workshop: Dictionary = {}, dt: float = 1.0 / 20.0) -> Battle:
	var b := Battle.new(research, tier, seed_value, workshop)
	b.record_events = false
	var think_every := 0.5
	var since := 0.0
	while not b.over and b.wave <= max_wave:
		b.step(dt)
		since += dt
		if since >= think_every:
			since = 0.0
			think(b)
			if not b.perk_offer.is_empty():
				b.choose_perk(b.perk_offer[0])
			for id in Powers.ORDER:
				b.cast(id)
			b.cast_hero()
	return b
