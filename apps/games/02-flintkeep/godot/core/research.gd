class_name Research
extends RefCounted
## Permanent upgrades bought with coins between runs. Each takes real time in a lab, and keeps
## running while the game is closed. Research is what makes the next run go further.

const LAB_COUNT := 2
const MAX_SECONDS := 12.0 * 3600.0

## group: section on the research screen. max: level cap. cost/growth: coin price and its
## multiplier per level. time/time_growth: seconds and its multiplier. step: effect per level.
## needs: research that must be done first. kind: how `step` reads (see describe()).
const ITEMS := {
	# Keep
	"keep_damage": {"name": "KEEP DAMAGE", "group": "KEEP", "max": 60, "cost": 20.0, "growth": 1.55, "time": 20.0, "time_growth": 1.45, "step": 0.15, "kind": "pct"},
	"keep_health": {"name": "KEEP HEALTH", "group": "KEEP", "max": 60, "cost": 20.0, "growth": 1.55, "time": 20.0, "time_growth": 1.45, "step": 0.15, "kind": "pct"},
	"keep_regen": {"name": "KEEP REGEN", "group": "KEEP", "max": 40, "cost": 30.0, "growth": 1.6, "time": 30.0, "time_growth": 1.45, "step": 0.25, "kind": "pct"},
	"keep_rate": {"name": "KEEP RATE", "group": "KEEP", "max": 25, "cost": 40.0, "growth": 1.7, "time": 45.0, "time_growth": 1.5, "step": 0.05, "kind": "pct"},
	# Economy
	"cash_bonus": {"name": "CASH BONUS", "group": "ECONOMY", "max": 40, "cost": 30.0, "growth": 1.6, "time": 30.0, "time_growth": 1.45, "step": 0.1, "kind": "pct"},
	"coin_bonus": {"name": "COIN BONUS", "group": "ECONOMY", "max": 40, "cost": 40.0, "growth": 1.65, "time": 45.0, "time_growth": 1.45, "step": 0.1, "kind": "pct"},
	"start_cash": {"name": "STARTING CASH", "group": "ECONOMY", "max": 30, "cost": 25.0, "growth": 1.6, "time": 30.0, "time_growth": 1.45, "step": 20.0, "kind": "cash"},
	"discount": {"name": "QUARTERMASTER", "group": "ECONOMY", "max": 15, "cost": 60.0, "growth": 1.8, "time": 60.0, "time_growth": 1.55, "step": 0.02, "kind": "discount"},
	# Arsenal: level 1 of a locked weapon unlocks it; every level after that starts it one level
	# higher and makes its upgrades cheaper. The musket is unlocked from the start.
	"musket": {"name": "MUSKETS", "group": "ARSENAL", "max": 20, "cost": 30.0, "growth": 1.7, "time": 30.0, "time_growth": 1.5, "step": 1.0, "kind": "weapon"},
	"cannon": {"name": "CANNONS", "group": "ARSENAL", "max": 21, "cost": 40.0, "growth": 1.7, "time": 40.0, "time_growth": 1.5, "step": 1.0, "kind": "weapon"},
	"volley": {"name": "VOLLEY GUNS", "group": "ARSENAL", "max": 21, "cost": 50.0, "growth": 1.7, "time": 60.0, "time_growth": 1.5, "step": 1.0, "kind": "weapon"},
	"sniper": {"name": "RIFLE NESTS", "group": "ARSENAL", "max": 21, "cost": 250.0, "growth": 1.7, "time": 300.0, "time_growth": 1.5, "step": 1.0, "kind": "weapon"},
	"arcane": {"name": "ARCANE SPIRES", "group": "ARSENAL", "max": 21, "cost": 800.0, "growth": 1.7, "time": 900.0, "time_growth": 1.5, "step": 1.0, "kind": "weapon"},
	# Fortress
	"ring_2": {"name": "SECOND RING", "group": "FORTRESS", "max": 1, "cost": 150.0, "growth": 1.0, "time": 120.0, "time_growth": 1.0, "step": 1.0, "kind": "ring"},
	"ring_3": {"name": "THIRD RING", "group": "FORTRESS", "max": 1, "cost": 1500.0, "growth": 1.0, "time": 1800.0, "time_growth": 1.0, "step": 1.0, "kind": "ring", "needs": "ring_2"},
	"ring_4": {"name": "FOURTH RING", "group": "FORTRESS", "max": 1, "cost": 12000.0, "growth": 1.0, "time": 14400.0, "time_growth": 1.0, "step": 1.0, "kind": "ring", "needs": "ring_3"},
	"masonry": {"name": "MASONRY", "group": "FORTRESS", "max": 40, "cost": 30.0, "growth": 1.6, "time": 30.0, "time_growth": 1.45, "step": 0.2, "kind": "pct"},
}
const GROUPS := ["KEEP", "ECONOMY", "ARSENAL", "FORTRESS"]
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


## One line for the research screen: what the current level gives and what the next one adds.
static func describe(id: String, level: int) -> String:
	var item: Dictionary = ITEMS[id]
	var at_max: bool = level >= item["max"]
	match item["kind"]:
		"pct":
			return "+%s" % Num.pct(effect(id, level)) + ("" if at_max else " > +%s" % Num.pct(effect(id, level + 1)))
		"cash":
			return "+%s" % Num.cash(effect(id, level)) + ("" if at_max else " > +%s" % Num.cash(effect(id, level + 1)))
		"discount":
			return "-%s" % Num.pct(effect(id, level)) + ("" if at_max else " > -%s" % Num.pct(effect(id, level + 1)))
		"ring":
			return "BUILT" if at_max else "UNLOCK %d MORE SLOTS" % Defs.SLOT_COUNTS[int(id.right(1))]
		"weapon":
			if not weapon_unlocked(id, level):
				return "UNLOCK"
			var text := "START LV%d" % weapon_start_level(id, level)
			if not at_max:
				text += " > LV%d" % weapon_start_level(id, level + 1)
			return text
	return ""
