class_name Workshop
extends RefCounted
## The coin workshop: permanent stat upgrades bought instantly with coins between runs.
## Deliberately expensive (prices grow 16-20% a level) so coins stay precious; the effects
## compound, so they keep mattering deep into a 1,000-wave run.

## kind "mult": x step^level. "add": + step * level (max caps it). "cash": + dollars.
const ITEMS := {
	"damage": {"name": "Keep damage", "kind": "mult", "step": 1.08, "cost": 150.0, "growth": 1.16, "max": 0},
	"health": {"name": "Keep health", "kind": "mult", "step": 1.08, "cost": 150.0, "growth": 1.16, "max": 0},
	"regen": {"name": "Keep regeneration", "kind": "mult", "step": 1.08, "cost": 200.0, "growth": 1.17, "max": 0},
	"rate": {"name": "Keep fire rate", "kind": "add", "step": 0.02, "cost": 250.0, "growth": 1.2, "max": 50},
	"crit": {"name": "Critical chance", "kind": "add", "step": 0.005, "cost": 300.0, "growth": 1.2, "max": 40},
	"towers": {"name": "Tower damage", "kind": "mult", "step": 1.08, "cost": 200.0, "growth": 1.16, "max": 0},
	"cash": {"name": "Cash bonus", "kind": "mult", "step": 1.06, "cost": 200.0, "growth": 1.17, "max": 0},
	"start_cash": {"name": "Starting cash", "kind": "cash", "step": 30.0, "cost": 150.0, "growth": 1.18, "max": 50},
	"masonry": {"name": "Masonry (wall HP)", "kind": "mult", "step": 1.08, "cost": 150.0, "growth": 1.16, "max": 0},
}
const ORDER := ["damage", "health", "regen", "rate", "crit", "towers", "cash", "start_cash", "masonry"]


static func cost(id: String, level: int) -> float:
	var item: Dictionary = ITEMS[id]
	return roundf(item["cost"] * pow(item["growth"], level))


static func maxed(id: String, level: int) -> bool:
	var cap: int = ITEMS[id]["max"]
	return cap > 0 and level >= cap


## The effect at a level: a multiplier for "mult", a bonus for "add" / "cash".
static func effect(id: String, level: int) -> float:
	var item: Dictionary = ITEMS[id]
	if item["kind"] == "mult":
		return pow(item["step"], level)
	return item["step"] * level


static func describe(id: String, level: int) -> String:
	var item: Dictionary = ITEMS[id]
	var at_max := maxed(id, level)
	match item["kind"]:
		"mult":
			return "×%.2f" % effect(id, level) + ("" if at_max else " → ×%.2f" % effect(id, level + 1))
		"cash":
			return "+" + Num.cash(effect(id, level)) + ("" if at_max else " → +" + Num.cash(effect(id, level + 1)))
	return "+" + Num.pct(effect(id, level)) + ("" if at_max else " → +" + Num.pct(effect(id, level + 1)))
