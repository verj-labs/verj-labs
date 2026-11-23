class_name BattleRows
extends RefCounted
## Builds the upgrade rows of the battle panel. Each row reads the battle live, so prices
## and "now > next" values stay current as cash comes in.

const COMPASS := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]


static func _cash_action(b: Battle, label: Callable, price: Callable, run: Callable, kind: Kit.Btn = Kit.Btn.BUY) -> Dictionary:
	return {"label": label, "price": price, "run": run, "kind": kind, "wallet": func() -> float: return b.cash}


static func _price_label(prefix: String, price: Callable) -> Callable:
	return func() -> String:
		var p: float = price.call()
		if p < 0.0:
			return "MAX"
		return (prefix + " " if prefix != "" else "") + Num.price(p)


# --- Keep -------------------------------------------------------------------------------------

static func keep_rows(b: Battle) -> Array[UpgradeRow]:
	var rows: Array[UpgradeRow] = []
	for id in Defs.KEEP_ORDER:
		var price := func() -> float: return -1.0 if b.keep_upgrade_maxed(id) else b.keep_upgrade_cost(id)
		var detail := func() -> String:
			var now := _keep_stat(b, id)
			if b.keep_upgrade_maxed(id):
				return now + "  MAX"
			b.keep_levels[id] = b.upgrade_level(b.keep_levels, id) + 1
			var next := _keep_stat(b, id)
			b.keep_levels[id] -= 1
			return "%s > %s" % [now, next]
		rows.append(UpgradeRow.make(Defs.KEEP_UPGRADES[id]["name"], detail,
			[_cash_action(b, _price_label("", price), price, b.buy_keep_upgrade.bind(id))]))
	return rows


static func _keep_stat(b: Battle, id: String) -> String:
	match id:
		"damage": return Num.fmt(b.keep_damage())
		"rate": return "%.2f/S" % b.keep_rate()
		"range": return str(int(b.keep_range()))
		"health": return Num.fmt(b.keep_max_hp())
		"regen": return Num.fmt(b.keep_regen()) + "/S"
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
				return now + "  MAX"
			b.econ_levels[id] = b.upgrade_level(b.econ_levels, id) + 1
			var next := _econ_stat(b, id)
			b.econ_levels[id] -= 1
			return "%s > %s" % [now, next]
		rows.append(UpgradeRow.make(Defs.ECON_UPGRADES[id]["name"], detail,
			[_cash_action(b, _price_label("", price), price, b.buy_econ_upgrade.bind(id))], Pal.GOLD if id == "coin_bounty" else Pal.PARCHMENT))
	return rows


static func _econ_stat(b: Battle, id: String) -> String:
	match id:
		"bounty": return "CASH X%.2f" % b.cash_mult()
		"coin_bounty": return "COINS X%.2f" % b.coin_mult()
		"interest": return Num.pct(b.interest_rate()) + " A WAVE"
	return ""


# --- Walls --------------------------------------------------------------------------------------

static func wall_rows(b: Battle) -> Array[UpgradeRow]:
	var rows: Array[UpgradeRow] = []
	for ring in range(1, Defs.MAX_RING + 1):
		var title := "RING %d WALL" % ring
		if ring > b.rings_unlocked:
			rows.append(UpgradeRow.make(title, func() -> String: return "RESEARCH THIS RING FIRST", [], Pal.MUTED))
			continue
		var wall := b.walls[ring]
		var build_price := func() -> float: return -1.0 if wall.built else b.wall_build_cost(ring)
		var reinforce_price := func() -> float: return b.wall_reinforce_cost(ring) if wall.built else -1.0
		var repair_price := func() -> float:
			return b.wall_repair_cost(ring) if wall.built and wall.missing_share() > 0.0 else -1.0
		var detail := func() -> String:
			if not wall.built:
				return "%d SECTIONS, %s HP EACH" % [Defs.SLOT_COUNTS[ring], Num.fmt(b.wall_max_hp(ring, 0))]
			return "LV%d  %s HP  %s INTACT" % [wall.level, Num.fmt(wall.max_hp), Num.pct(1.0 - wall.missing_share())]
		var actions := [
			_cash_action(b, func() -> String: return "BUILD " + Num.price(b.wall_build_cost(ring)) if not wall.built else "REPAIR " + (Num.price(repair_price.call()) if repair_price.call() >= 0.0 else "--"),
				func() -> float: return build_price.call() if not wall.built else repair_price.call(),
				func() -> bool: return b.build_wall(ring) if not wall.built else b.repair_wall(ring)),
			_cash_action(b, func() -> String: return "+HP " + Num.price(reinforce_price.call()) if wall.built else "+HP --",
				reinforce_price, b.reinforce_wall.bind(ring), Kit.Btn.SECONDARY),
		]
		rows.append(UpgradeRow.make(title, detail, actions))
	return rows


# --- A build slot -------------------------------------------------------------------------------

static func slot_title(b: Battle, index: int) -> String:
	var slot: Entities.Slot = b.slots[index]
	var octant := posmod(int(roundf(slot.angle / (TAU / 8.0))), 8)
	var where := "RING %d %s" % [slot.ring, COMPASS[octant]]
	if slot.tower == null:
		return where + ": BUILD"
	return "%s  LV%d" % [Defs.WEAPONS[slot.tower.weapon]["short"], slot.tower.level]


static func slot_rows(b: Battle, index: int, rebuild: Callable) -> Array[UpgradeRow]:
	var slot: Entities.Slot = b.slots[index]
	var rows: Array[UpgradeRow] = []
	if slot.tower == null:
		for weapon in Defs.WEAPON_ORDER:
			var def: Dictionary = Defs.WEAPONS[weapon]
			var color: Color = Pal.WEAPON_COLORS[weapon]
			if not b.weapon_unlocked(weapon):
				rows.append(UpgradeRow.make(def["short"], func() -> String: return "LOCKED: UNLOCK IN RESEARCH", [], Pal.MUTED))
				continue
			var price := func() -> float: return b.build_cost(weapon)
			var run := func() -> bool:
				var ok := b.build(index, weapon)
				if ok:
					rebuild.call_deferred()
				return ok
			rows.append(UpgradeRow.make(def["short"], func() -> String: return def["about"],
				[_cash_action(b, _price_label("", price), price, run)], color))
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
		return "DAMAGE %s > %s" % [Num.fmt(now), Num.fmt(next)]
	var upgrade := func() -> bool:
		var ok := b.upgrade_tower(index)
		if ok:
			rebuild.call_deferred()
		return ok
	rows.append(UpgradeRow.make("UPGRADE", up_detail, [_cash_action(b, _price_label("", up_price), up_price, upgrade)], Pal.WEAPON_COLORS[tower.weapon]))
	var stats := func() -> String:
		return "%.2f/S  RANGE %d" % [b.tower_rate(tower), int(b.tower_range(tower))]
	var about := func() -> String: return Defs.WEAPONS[tower.weapon]["about"]
	var sell_price := func() -> float: return 0.0
	var sell := func() -> bool:
		var ok := b.sell(index)
		if ok:
			rebuild.call_deferred()
		return ok
	rows.append(UpgradeRow.make(stats, about,
		[_cash_action(b, func() -> String: return "SELL +" + Num.cash(b.sell_value(index)) if slot.tower != null else "SELL", sell_price, sell, Kit.Btn.DANGER)], Pal.DIM))
	return rows
