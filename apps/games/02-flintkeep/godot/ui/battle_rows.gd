class_name BattleRows
extends RefCounted
## Builds the upgrade rows of the battle panel. Each row reads the battle live, so prices
## and "now → next" values stay current as cash comes in.

const COMPASS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
const ARROW := "  →  "


static func _cash_action(b: Battle, label: Callable, price: Callable, run: Callable, kind: Kit.Btn = Kit.Btn.BUY) -> Dictionary:
	return {"label": label, "price": price, "run": run, "kind": kind, "wallet": func() -> float: return b.cash}


static func _price_label(prefix: String, price: Callable) -> Callable:
	return func() -> String:
		var p: float = price.call()
		if p < 0.0:
			return "Max"
		return (prefix + " " if prefix != "" else "") + Num.price(p)


# --- Keep -------------------------------------------------------------------------------------

static func keep_rows(b: Battle) -> Array[UpgradeRow]:
	var rows: Array[UpgradeRow] = []
	for id in Defs.KEEP_ORDER:
		var price := func() -> float: return -1.0 if b.keep_upgrade_maxed(id) else b.keep_upgrade_cost(id)
		var detail := func() -> String:
			var now := _keep_stat(b, id)
			if b.keep_upgrade_maxed(id):
				return now + "  (max)"
			b.keep_levels[id] = b.upgrade_level(b.keep_levels, id) + 1
			var next := _keep_stat(b, id)
			b.keep_levels[id] -= 1
			return now + ARROW + next
		rows.append(UpgradeRow.make(Defs.KEEP_UPGRADES[id]["name"], detail,
			[_cash_action(b, _price_label("", price), price, b.buy_keep_upgrade.bind(id))]))
	return rows


static func _keep_stat(b: Battle, id: String) -> String:
	match id:
		"damage": return Num.fmt(b.keep_damage())
		"rate": return "%.2f/s" % b.keep_rate()
		"range": return str(int(b.keep_range()))
		"health": return Num.fmt(b.keep_max_hp())
		"regen": return Num.fmt(b.keep_regen()) + "/s"
		"armor": return Num.pct(b.keep_armor())
	return ""


# --- Economy ------------------------------------------------------------------------------------

static func econ_rows(b: Battle) -> Array[UpgradeRow]:
	var rows: Array[UpgradeRow] = []
	for id in Defs.ECON_ORDER:
		var price := func() -> float: return -1.0 if b.econ_upgrade_maxed(id) else b.econ_upgrade_cost(id)
		var detail := func() -> String:
			var now := _econ_stat(b, id)
			if b.econ_upgrade_maxed(id):
				return now + "  (max)"
			b.econ_levels[id] = b.upgrade_level(b.econ_levels, id) + 1
			var next := _econ_stat(b, id)
			b.econ_levels[id] -= 1
			return now + ARROW + next
		rows.append(UpgradeRow.make(Defs.ECON_UPGRADES[id]["name"], detail,
			[_cash_action(b, _price_label("", price), price, b.buy_econ_upgrade.bind(id))], Color("#b7791f") if id == "coin_bounty" else Pal.TEXT))
	return rows


static func _econ_stat(b: Battle, id: String) -> String:
	match id:
		"bounty": return "Cash ×%.2f" % b.cash_mult()
		"coin_bounty": return "Coins ×%.2f" % b.coin_mult()
		"interest": return Num.pct(b.interest_rate()) + " a wave"
	return ""


# --- Walls --------------------------------------------------------------------------------------

static func wall_rows(b: Battle) -> Array[UpgradeRow]:
	var rows: Array[UpgradeRow] = []
	for ring in range(1, Defs.MAX_RING + 1):
		var count: int = Defs.SLOT_COUNTS[ring]
		var title := "Ring %d wall" % ring
		if ring > b.rings_unlocked:
			rows.append(UpgradeRow.make(title, func() -> String: return "Research this ring first", [], Pal.TEXT_DIM))
			continue
		var wall := b.walls[ring]
		var title_fn := func() -> String:
			return "Ring %d wall  ·  fortified!" % ring if wall.complete() else "Ring %d wall  ·  %d/%d" % [ring, wall.built_count(), count]
		var reinforce_price := func() -> float: return b.wall_reinforce_cost(ring) if wall.built else -1.0
		var repair_price := func() -> float:
			return b.wall_repair_cost(ring) if wall.built and wall.missing_share() > 0.0 else -1.0
		var main_price := func() -> float: return repair_price.call() if wall.complete() else b.wall_build_cost(ring)
		var detail := func() -> String:
			if not wall.complete():
				return "Finish it: +50% wall HP, +15% tower damage"
			return "Level %d  ·  %s HP  ·  %s intact" % [wall.level, Num.fmt(wall.max_hp), Num.pct(1.0 - wall.missing_share())]
		var actions := [
			_cash_action(b, func() -> String:
				if wall.complete():
					return "Fix " + (Num.price(repair_price.call()) if repair_price.call() >= 0.0 else "–")
				return "All " + Num.price(b.wall_build_cost(ring)),
				main_price,
				func() -> bool: return b.repair_wall(ring) if wall.complete() else b.build_wall(ring)),
			_cash_action(b, func() -> String: return "+HP " + Num.price(reinforce_price.call()) if wall.built else "+HP",
				reinforce_price, b.reinforce_wall.bind(ring), Kit.Btn.SECONDARY),
		]
		rows.append(UpgradeRow.make(title_fn, detail, actions))
	return rows


## Rows for one wall section, after tapping its arc on the battlefield.
static func section_rows(b: Battle, ring: int, seg: int, rebuild: Callable) -> Array[UpgradeRow]:
	var wall := b.walls[ring]
	var rows: Array[UpgradeRow] = []
	if not wall.sections[seg]:
		var run := func() -> bool:
			var ok := b.build_section(ring, seg)
			if ok:
				rebuild.call_deferred()
			return ok
		var price := func() -> float: return b.section_cost(ring)
		rows.append(UpgradeRow.make("Build this section", func() -> String:
			return "%s HP  ·  stops ground enemies" % Num.fmt(b.wall_max_hp(ring, wall.level, false)),
			[_cash_action(b, _price_label("", price), price, run)]))
	else:
		rows.append(UpgradeRow.make("Section health", func() -> String:
			return "%s / %s HP" % [Num.fmt(wall.segments[seg]), Num.fmt(wall.max_hp)], []))
	rows.append_array(wall_rows(b).slice(ring - 1, ring))
	return rows


# --- A build slot -------------------------------------------------------------------------------

static func section_title(ring: int, seg: int) -> String:
	var octant := posmod(int(roundf(Battle.section_angle(ring, seg) / (TAU / 8.0))), 8)
	return "Wall: ring %d, %s" % [ring, COMPASS[octant]]


static func slot_title(b: Battle, index: int) -> String:
	var slot: Entities.Slot = b.slots[index]
	var octant := posmod(int(roundf(slot.angle / (TAU / 8.0))), 8)
	if slot.tower == null:
		return "Build: ring %d, %s" % [slot.ring, COMPASS[octant]]
	return "%s  ·  Lv %d" % [Defs.WEAPONS[slot.tower.weapon]["short"], slot.tower.level]


static func slot_rows(b: Battle, index: int, rebuild: Callable) -> Array[UpgradeRow]:
	var slot: Entities.Slot = b.slots[index]
	var rows: Array[UpgradeRow] = []
	if slot.tower == null:
		for weapon in Defs.WEAPON_ORDER:
			var def: Dictionary = Defs.WEAPONS[weapon]
			var color: Color = Pal.WEAPON_TEXT[weapon]
			if not b.weapon_unlocked(weapon):
				rows.append(UpgradeRow.make(def["short"], func() -> String: return "Locked: unlock it in Research", [], Pal.TEXT_DIM, weapon))
				continue
			var price := func() -> float: return b.build_cost(weapon)
			var run := func() -> bool:
				var ok := b.build(index, weapon)
				if ok:
					rebuild.call_deferred()
				return ok
			rows.append(UpgradeRow.make(def["short"], func() -> String: return def["about"],
				[_cash_action(b, _price_label("", price), price, run)], color, weapon))
		return rows
	var tower := slot.tower
	var up_price := func() -> float: return b.tower_upgrade_cost(index) if slot.tower != null else -1.0
	var up_detail := func() -> String:
		if slot.tower == null:
			return ""
		var now := b.tower_damage(tower)
		tower.level += 1
		var next := b.tower_damage(tower)
		tower.level -= 1
		return "Damage " + Num.fmt(now) + ARROW + Num.fmt(next)
	var upgrade := func() -> bool:
		var ok := b.upgrade_tower(index)
		if ok:
			rebuild.call_deferred()
		return ok
	rows.append(UpgradeRow.make("Upgrade", up_detail, [_cash_action(b, _price_label("", up_price), up_price, upgrade)], Pal.TEXT, tower.weapon))
	var stats := func() -> String:
		return "%.2f shots/s  ·  range %d" % [b.tower_rate(tower), int(b.tower_range(tower))]
	var about := func() -> String: return Defs.WEAPONS[tower.weapon]["about"]
	var sell_price := func() -> float: return 0.0
	var sell := func() -> bool:
		var ok := b.sell(index)
		if ok:
			rebuild.call_deferred()
		return ok
	rows.append(UpgradeRow.make(stats, about,
		[_cash_action(b, func() -> String: return "Sell +" + Num.cash(b.sell_value(index)) if slot.tower != null else "Sell", sell_price, sell, Kit.Btn.DANGER)], Pal.TEXT_DIM))
	return rows
