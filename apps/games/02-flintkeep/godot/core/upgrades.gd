class_name Upgrades
extends RefCounted
## The cash upgrades bought during a run, by tab. Each has a price curve and an effect curve:
##   price(level) = base * growth^level
##   "mult": value = start * step^level          (compounds: damage, health ...)
##   "add":  value = start + step * level, capped (chances, flat bonuses ...)
## max is a level cap (0 = none). Values are read through Battle.stat(id).
## Rule: every upgrade gets pricier faster than it gets stronger (and income upgrades much
## faster), so a run's power grows a little slower than the enemies and every run ends. How far
## it gets is set by research and the workshop, whose bonuses multiply (see docs/DECISIONS.md).

const TABS := ["Attack", "Defense", "Walls", "Economy", "Powers"]

const LIST := {
	# --- Attack (the Keep's own shot; crits, multishot, bounce and pushback apply to every shot)
	"damage": {"tab": "Attack", "name": "Damage", "kind": "mult", "start": 10.0, "step": 1.1, "base": 6.0, "growth": 1.13, "max": 0},
	"rate": {"tab": "Attack", "name": "Fire rate", "kind": "add", "start": 1.2, "step": 0.04, "base": 10.0, "growth": 1.14, "max": 70},
	"range": {"tab": "Attack", "name": "Range", "kind": "add", "start": 58.0, "step": 1.5, "base": 12.0, "growth": 1.3, "max": 20},
	"crit_chance": {"tab": "Attack", "name": "Critical chance", "kind": "add", "start": 0.0, "step": 0.01, "base": 15.0, "growth": 1.11, "max": 80},
	"crit_factor": {"tab": "Attack", "name": "Critical damage", "kind": "add", "start": 1.5, "step": 0.1, "base": 18.0, "growth": 1.12, "max": 0},
	"multishot": {"tab": "Attack", "name": "Multishot", "kind": "add", "start": 0.0, "step": 0.02, "base": 30.0, "growth": 1.13, "max": 40},
	"bounce": {"tab": "Attack", "name": "Bounce", "kind": "add", "start": 0.0, "step": 0.02, "base": 30.0, "growth": 1.13, "max": 40},
	"push_chance": {"tab": "Attack", "name": "Pushback chance", "kind": "add", "start": 0.0, "step": 0.02, "base": 25.0, "growth": 1.13, "max": 40},
	"push_dist": {"tab": "Attack", "name": "Pushback distance", "kind": "add", "start": 2.0, "step": 0.75, "base": 25.0, "growth": 1.18, "max": 24},
	# --- Defense
	"health": {"tab": "Defense", "name": "Health", "kind": "mult", "start": 150.0, "step": 1.1, "base": 6.0, "growth": 1.13, "max": 0},
	"regen": {"tab": "Defense", "name": "Regeneration", "kind": "mult", "start": 0.5, "step": 1.1, "base": 8.0, "growth": 1.13, "max": 0},
	"armor": {"tab": "Defense", "name": "Armour", "kind": "add", "start": 0.0, "step": 0.01, "base": 12.0, "growth": 1.1, "max": 75},
	"absolute": {"tab": "Defense", "name": "Absolute defense", "kind": "mult", "start": 1.0, "step": 1.1, "base": 20.0, "growth": 1.13, "max": 0},
	"thorns": {"tab": "Defense", "name": "Thorns", "kind": "add", "start": 0.0, "step": 0.02, "base": 25.0, "growth": 1.14, "max": 40},
	"lifesteal": {"tab": "Defense", "name": "Lifesteal", "kind": "add", "start": 0.0, "step": 0.001, "base": 30.0, "growth": 1.12, "max": 50},
	# --- Walls (sections are bought on the field; these improve every wall)
	"wall_regen": {"tab": "Walls", "name": "Wall regeneration", "kind": "add", "start": 0.0, "step": 0.001, "base": 20.0, "growth": 1.15, "max": 30},
	# --- Economy
	"bounty": {"tab": "Economy", "name": "Cash bounty", "kind": "mult", "start": 1.0, "step": 1.03, "base": 15.0, "growth": 1.15, "max": 0},
	"coin_bounty": {"tab": "Economy", "name": "Coin bounty", "kind": "mult", "start": 1.0, "step": 1.03, "base": 20.0, "growth": 1.15, "max": 0},
	"wave_cash": {"tab": "Economy", "name": "Cash per wave", "kind": "mult", "start": 8.0, "step": 1.04, "base": 15.0, "growth": 1.15, "max": 0},
	"wave_coins": {"tab": "Economy", "name": "Coins per wave", "kind": "mult", "start": 2.0, "step": 1.08, "base": 30.0, "growth": 1.17, "max": 0},
	"interest": {"tab": "Economy", "name": "Interest", "kind": "add", "start": 0.0, "step": 0.005, "base": 25.0, "growth": 1.2, "max": 10},
}


static func ids_in(tab: String) -> Array[String]:
	var out: Array[String] = []
	for id in LIST:
		if LIST[id]["tab"] == tab:
			out.append(id)
	return out


static func value(id: String, level: int) -> float:
	var u: Dictionary = LIST[id]
	if u["kind"] == "mult":
		return u["start"] * pow(u["step"], level)
	return u["start"] + u["step"] * level


static func price(id: String, level: int) -> float:
	var u: Dictionary = LIST[id]
	return u["base"] * pow(u["growth"], level)


static func maxed(id: String, level: int) -> bool:
	var cap: int = LIST[id]["max"]
	return cap > 0 and level >= cap


## How a value reads on a card.
static func show(id: String, v: float) -> String:
	match id:
		"rate": return "%.2f/s" % v
		"range", "push_dist": return "%.1f" % v
		"crit_factor": return "×%.2f" % v
		"crit_chance", "multishot", "bounce", "push_chance", "armor", "lifesteal", "interest": return Num.pct(v)
		"thorns": return Num.pct(v) + " back"
		"regen": return Num.pct(v / 100.0) + "/s"
		"wall_regen": return Num.pct(v) + "/s"
		"bounty", "coin_bounty": return "×%.2f" % v
		"absolute": return Num.fmt(v) + "/s"
		"wave_cash": return Num.cash(v)
		"wave_coins": return "%.1f coins" % v
	return Num.fmt(v)


# --- Enemy scaling ------------------------------------------------------------------------------
## Health multiplier at a wave: steep for the first waves, then about +2% a wave, so the
## numbers reach ~1e11 at wave 1,000 (fine for floats; the HUD prints them with suffixes).
## `siege` (research) slows the long-run growth.

const SCALE_A := 1.5
const SCALE_B := 10.0
const SCALE_C := 0.02


static func enemy_scale(wave: int, siege: float = 0.0) -> float:
	var w := float(maxi(wave - 1, 0))
	return exp(SCALE_A * log(1.0 + w / SCALE_B) + SCALE_C * (1.0 - siege) * w)


## Cash per kill grows slower than health, so upgrades have to compound to keep up.
static func cash_scale(wave: int, siege: float = 0.0) -> float:
	return pow(enemy_scale(wave, siege), 0.7)


## Enemy damage grows slower still: your defences are about outlasting them, not one-shots.
static func dps_scale(wave: int, siege: float = 0.0) -> float:
	return pow(enemy_scale(wave, siege), 0.97)
