class_name Research
extends RefCounted
## Lab research: big permanent unlocks bought with coins that take real time in one of two labs
## (and keep running while the game is closed): game speed, weapons, powers, rings, and Siege
## lore, which slows how fast enemies grow. Plain stat boosts live in the Workshop instead.

## You start with one lab; slots 2, 3 and 4 cost gems.
const LAB_SLOT_GEMS := [150, 500, 1500]
const GEM_SECONDS := 600.0  ## finishing research early costs one gem per 10 minutes left
## First time reaching these waves in a tier pays these gems.
const MILESTONE_WAVES := [50, 100, 250, 500, 1000]
const MILESTONE_GEMS := [10, 20, 40, 80, 150]
const MAX_SECONDS := 12.0 * 3600.0

## group: section on the research screen. max: level cap. cost/growth: coin price and its
## multiplier per level. time/time_growth: seconds and its multiplier. step: effect per level.
## needs: research that must be done first. kind: how `step` reads (see describe()).
const ITEMS := {
	# Command: how fast and how hard the war goes
	"game_speed": {"name": "Game speed", "group": "Command", "max": 4, "cost": 300.0, "growth": 4.0, "time": 600.0, "time_growth": 3.0, "step": 1.0, "kind": "speed"},
	"siege": {"name": "Siege lore", "group": "Command", "max": 25, "cost": 200.0, "growth": 1.6, "time": 300.0, "time_growth": 1.4, "step": 0.03, "kind": "siege"},
	"coin_bonus": {"name": "Coin bonus", "group": "Command", "max": 40, "cost": 60.0, "growth": 1.5, "time": 60.0, "time_growth": 1.4, "step": 0.1, "kind": "pct"},
	"discount": {"name": "Quartermaster", "group": "Command", "max": 15, "cost": 100.0, "growth": 1.7, "time": 120.0, "time_growth": 1.5, "step": 0.02, "kind": "discount"},
	# Arsenal: level 1 of a locked weapon unlocks it; every level after that starts it one level
	# higher (its upgrade prices do not go up for it). The musket is unlocked from the start.
	"musket": {"name": "Muskets", "group": "Arsenal", "max": 30, "cost": 40.0, "growth": 1.5, "time": 30.0, "time_growth": 1.4, "step": 1.0, "kind": "weapon"},
	"cannon": {"name": "Cannons", "group": "Arsenal", "max": 31, "cost": 40.0, "growth": 1.5, "time": 40.0, "time_growth": 1.4, "step": 1.0, "kind": "weapon"},
	"volley": {"name": "Volley guns", "group": "Arsenal", "max": 31, "cost": 60.0, "growth": 1.5, "time": 60.0, "time_growth": 1.4, "step": 1.0, "kind": "weapon"},
	"sniper": {"name": "Rifle nests", "group": "Arsenal", "max": 31, "cost": 250.0, "growth": 1.5, "time": 300.0, "time_growth": 1.4, "step": 1.0, "kind": "weapon"},
	"arcane": {"name": "Arcane spires", "group": "Arsenal", "max": 31, "cost": 800.0, "growth": 1.5, "time": 900.0, "time_growth": 1.4, "step": 1.0, "kind": "weapon"},
	# Powers: level 1 unlocks the power; each level after makes it stronger and recharge faster
	"power_rain": {"name": "Arrow Rain", "group": "Powers", "max": 20, "cost": 400.0, "growth": 1.6, "time": 600.0, "time_growth": 1.4, "step": 1.0, "kind": "power"},
	"power_freeze": {"name": "Freeze", "group": "Powers", "max": 20, "cost": 600.0, "growth": 1.6, "time": 900.0, "time_growth": 1.4, "step": 1.0, "kind": "power"},
	"power_thunder": {"name": "Thunderstorm", "group": "Powers", "max": 20, "cost": 1000.0, "growth": 1.6, "time": 1200.0, "time_growth": 1.4, "step": 1.0, "kind": "power"},
	"power_gold": {"name": "Golden Hour", "group": "Powers", "max": 20, "cost": 1500.0, "growth": 1.6, "time": 1800.0, "time_growth": 1.4, "step": 1.0, "kind": "power"},
	# Fortress
	"ring_2": {"name": "Second ring", "group": "Fortress", "max": 1, "cost": 150.0, "growth": 1.0, "time": 120.0, "time_growth": 1.0, "step": 1.0, "kind": "ring"},
	"ring_3": {"name": "Third ring", "group": "Fortress", "max": 1, "cost": 1500.0, "growth": 1.0, "time": 1800.0, "time_growth": 1.0, "step": 1.0, "kind": "ring", "needs": "ring_2"},
	"ring_4": {"name": "Fourth ring", "group": "Fortress", "max": 1, "cost": 12000.0, "growth": 1.0, "time": 14400.0, "time_growth": 1.0, "step": 1.0, "kind": "ring", "needs": "ring_3"},
}
const GROUPS := ["Command", "Arsenal", "Powers", "Fortress"]
## Old research that moved to the workshop in 0.2: id -> workshop id (levels carry over).
const MOVED_TO_WORKSHOP := {
	"keep_damage": "damage", "keep_health": "health", "keep_regen": "regen", "keep_rate": "rate",
	"cash_bonus": "cash", "start_cash": "start_cash", "masonry": "masonry",
}
const STARTER_WEAPONS := ["musket"]
const WEAPON_DISCOUNT_STEP := 0.04
const WEAPON_DISCOUNT_MAX := 0.5


static func ids_in(group: String) -> Array[String]:
	var out: Array[String] = []
	for id in ITEMS:
		if ITEMS[id]["group"] == group:
			out.append(id)
	return out


static func cost(id: String, level: int) -> float:
	var item: Dictionary = ITEMS[id]
	return roundf(item["cost"] * pow(item["growth"], level))


static func seconds(id: String, level: int) -> float:
	var item: Dictionary = ITEMS[id]
	return minf(roundf(item["time"] * pow(item["time_growth"], level)), MAX_SECONDS)


## Total effect at a level: a fraction for "pct"/"discount", dollars for "cash".
static func effect(id: String, level: int) -> float:
	return ITEMS[id]["step"] * level


# --- Weapons -------------------------------------------------------------------------------

static func weapon_unlocked(weapon: String, level: int) -> bool:
	return weapon in STARTER_WEAPONS or level >= 1


## The level a weapon's tower has when it is built.
static func weapon_start_level(weapon: String, level: int) -> int:
	var bonus := level if weapon in STARTER_WEAPONS else maxi(level - 1, 0)
	return 1 + bonus


## How much cheaper a weapon's in-run upgrades are.
static func weapon_discount(weapon: String, level: int) -> float:
	var bonus := level if weapon in STARTER_WEAPONS else maxi(level - 1, 0)
	return minf(bonus * WEAPON_DISCOUNT_STEP, WEAPON_DISCOUNT_MAX)


## The fastest game speed researched (1 = no research).
static func max_speed(level: int) -> int:
	return 1 + level


## One line for the research screen: what the current level gives and what the next one adds.
static func describe(id: String, level: int) -> String:
	var item: Dictionary = ITEMS[id]
	var at_max: bool = level >= item["max"]
	match item["kind"]:
		"pct":
			return "+%s" % Num.pct(effect(id, level)) + ("" if at_max else " → +%s" % Num.pct(effect(id, level + 1)))
		"cash":
			return "+%s" % Num.cash(effect(id, level)) + ("" if at_max else " → +%s" % Num.cash(effect(id, level + 1)))
		"discount":
			return "-%s" % Num.pct(effect(id, level)) + ("" if at_max else " → -%s" % Num.pct(effect(id, level + 1)))
		"ring":
			return "Built" if at_max else "Adds a ring of %d towers" % Defs.SLOT_COUNTS[int(id.right(1))]
		"speed":
			return "Up to %dx" % (1 + level) + ("" if at_max else " → %dx" % (2 + level))
		"siege":
			return "Enemies grow %s slower" % Num.pct(effect(id, level)) + ("" if at_max else " → %s" % Num.pct(effect(id, level + 1)))
		"power":
			if level == 0:
				return "Unlocks the power"
			return "Power level %d" % level + ("" if at_max else " → %d" % (level + 1))
		"weapon":
			if not weapon_unlocked(id, level):
				return "Unlocks the tower"
			var text := "Starts at level %d" % weapon_start_level(id, level)
			if not at_max:
				text += " → %d" % weapon_start_level(id, level + 1)
			return text
	return ""
