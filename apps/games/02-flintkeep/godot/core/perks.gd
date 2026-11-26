class_name Perks
extends RefCounted
## Every 100 waves the player picks one of three perks for the rest of the run. If they do not
## choose within 20 seconds (the phone is on the table), one is picked at random: the game is
## meant to keep playing itself.

## stat: what it changes in Battle.perk. "mult" multiplies, "add" adds.
const LIST := {
	"fury": {"name": "Fury", "about": "Keep damage ×1.3", "stat": "damage", "kind": "mult", "value": 1.3},
	"fortune": {"name": "Fortune", "about": "Cash ×1.3", "stat": "cash", "kind": "mult", "value": 1.3},
	"stone": {"name": "Stoneheart", "about": "Keep health ×1.3, fully healed", "stat": "health", "kind": "mult", "value": 1.3},
	"masons": {"name": "Master masons", "about": "Wall HP ×1.3, walls repaired", "stat": "walls", "kind": "mult", "value": 1.3},
	"eagle": {"name": "Eagle eye", "about": "+10% critical chance", "stat": "crit", "kind": "add", "value": 0.1},
	"volley": {"name": "Volley", "about": "+10% multishot", "stat": "multishot", "kind": "add", "value": 0.1},
	"ricochet": {"name": "Ricochet", "about": "+10% bounce", "stat": "bounce", "kind": "add", "value": 0.1},
	"gale": {"name": "Gale", "about": "+10% pushback chance", "stat": "push", "kind": "add", "value": 0.1},
	"arsenal": {"name": "Arsenal", "about": "Tower damage ×1.4", "stat": "towers", "kind": "mult", "value": 1.4},
	"scholar": {"name": "Scholar", "about": "Coins ×1.25", "stat": "coins", "kind": "mult", "value": 1.25},
}


static func pick_three(rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array = LIST.keys()
	var out: Array[String] = []
	while out.size() < 3:
		var id: String = pool[rng.randi() % pool.size()]
		pool.erase(id)
		out.append(id)
	return out
