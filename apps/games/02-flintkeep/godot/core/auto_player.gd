class_name AutoPlayer
extends RefCounted
## A simple greedy player used by the balance tests (and handy for an attract mode later).
## Each think() it buys the cheapest useful thing it can afford: fill open slots, raise walls,
## repair them when they are hurt, then upgrade whatever is cheapest.

const REPAIR_BELOW := 0.35  ## Repair a wall once this share of it is missing.


static func think(b: Battle) -> void:
	for i in 20:  # spend in several steps, cheapest first
		if not _buy_one(b):
			return


static func _buy_one(b: Battle) -> bool:
	for ring in range(1, b.rings_unlocked + 1):
		var wall := b.walls[ring]
		if wall.built and wall.missing_share() >= REPAIR_BELOW and b.cash >= b.wall_repair_cost(ring):
			return b.repair_wall(ring)
	var options: Array = []  # [cost, Callable]
	var weapon := _next_weapon(b)
	for slot in b.slots:
		if b.slot_open(slot.index) and slot.tower == null:
			options.append([b.build_cost(weapon) * 0.5, b.build.bind(slot.index, weapon)])
			break
	for ring in range(1, b.rings_unlocked + 1):
		if not b.walls[ring].built:
			options.append([b.wall_build_cost(ring) * 0.8, b.build_wall.bind(ring)])
		elif b.wave > 6:
			options.append([b.wall_reinforce_cost(ring) * 1.5, b.reinforce_wall.bind(ring)])
	for id in ["damage", "health", "rate", "regen"]:
		if not b.keep_upgrade_maxed(id):
			options.append([b.keep_upgrade_cost(id), b.buy_keep_upgrade.bind(id)])
	if not b.econ_upgrade_maxed("bounty"):
		options.append([b.econ_upgrade_cost("bounty") * 1.2, b.buy_econ_upgrade.bind("bounty")])
	for slot in b.slots:
		if slot.tower != null:
			options.append([b.tower_upgrade_cost(slot.index), b.upgrade_tower.bind(slot.index)])
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
static func play(research: Dictionary, tier: int, seed_value: int, max_wave: int = 200) -> Battle:
	var b := Battle.new(research, tier, seed_value)
	b.record_events = false
	var dt := 1.0 / 20.0
	var think_every := 0.5
	var since := 0.0
	while not b.over and b.wave <= max_wave:
		b.step(dt)
		since += dt
		if since >= think_every:
			since = 0.0
			think(b)
	return b
