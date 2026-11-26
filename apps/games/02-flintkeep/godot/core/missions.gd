class_name Missions
extends RefCounted
## Daily missions: three goals a day, picked from a pool by the date (so everyone's day is
## stable and the list survives restarts), scaled to how far the player has got. Completing one
## lets the player claim coins. Progress is fed from battle events through track().

const PER_DAY := 3
## kind -> [title with %d, base target, target per best wave, reward multiplier]
const POOL := {
	"kills": ["Defeat %d enemies", 120, 6.0, 1.0],
	"flyers": ["Shoot down %d flyers", 15, 0.8, 1.2],
	"wave": ["Reach wave %d in one run", 8, 0.6, 1.5],
	"build": ["Build %d towers", 8, 0.2, 0.8],
	"upgrade": ["Upgrade towers %d times", 10, 0.5, 1.0],
	"boss": ["Defeat %d Juggernaut", 1, 0.0, 2.0],
	"walls": ["Build or repair walls %d times", 4, 0.1, 0.8],
}


static func today() -> String:
	return Time.get_date_string_from_system(true)


## Three missions for `day`, sized for a player whose best wave so far is `best`.
static func generate(day: String, best: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day)
	var kinds: Array = POOL.keys()
	if best < 10:
		kinds.erase("boss")  # no Juggernaut before wave 10
	var out: Array = []
	while out.size() < PER_DAY:
		var kind: String = kinds[rng.randi() % kinds.size()]
		kinds.erase(kind)
		var spec: Array = POOL[kind]
		var target := int(spec[1] + spec[2] * best)
		if kind == "wave":
			target = maxi(int(spec[1]), int(best * 0.8))
		out.append({"kind": kind, "target": target, "progress": 0, "reward": reward(best, spec[3]),
			"gems": 3 if spec[3] >= 1.5 else 2, "claimed": false})
	return out


static func reward(best: int, mult: float) -> int:
	return int(roundf((30.0 + 5.0 * best) * mult / 5.0) * 5.0)


static func title(m: Dictionary) -> String:
	return POOL[m["kind"]][0] % int(m["target"])


static func done(m: Dictionary) -> bool:
	return int(m["progress"]) >= int(m["target"])


## Applies a battle event to today's missions. "wave" keeps the highest value, others add up.
static func track(list: Array, kind: String, amount: int) -> bool:
	var changed := false
	for m in list:
		if m["kind"] != kind or m["claimed"] or done(m):
			continue
		var before := int(m["progress"])
		m["progress"] = maxi(before, amount) if kind == "wave" else before + amount
		changed = changed or int(m["progress"]) != before
	return changed
