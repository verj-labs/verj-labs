class_name ProfileData
extends RefCounted
## Everything that survives between runs: coins, research levels, labs, best waves.
## Pure data: time is passed in (`now`, unix seconds), so it is easy to test.

var coins: float = 0.0
var research: Dictionary = {}  ## id -> level
var labs: Array = []  ## one Dictionary per lab: {"id": "" when free, "ends": unix seconds}
var best_wave: Dictionary = {}  ## tier (as String) -> best wave reached
var unlocked_tier: int = 1
var runs: int = 0
var total_kills: int = 0


func _init() -> void:
	for i in Research.LAB_COUNT:
		labs.append({"id": "", "ends": 0.0})


func level(id: String) -> int:
	return int(research.get(id, 0))


func best(tier: int) -> int:
	return int(best_wave.get(str(tier), 0))


func is_maxed(id: String) -> bool:
	return level(id) >= int(Research.ITEMS[id]["max"])


func next_cost(id: String) -> float:
	return Research.cost(id, level(id))


func next_seconds(id: String) -> float:
	return Research.seconds(id, level(id))


func lab_of(id: String) -> int:
	for i in labs.size():
		if labs[i]["id"] == id:
			return i
	return -1


func free_lab() -> int:
	for i in labs.size():
		if labs[i]["id"] == "":
			return i
	return -1


## Why `id` cannot be started right now, or "" when it can.
func blocker(id: String) -> String:
	if is_maxed(id):
		return "MAX"
	if lab_of(id) != -1:
		return "IN LAB"
	var needs: String = Research.ITEMS[id].get("needs", "")
	if needs != "" and level(needs) < 1:
		return "NEEDS " + needs
	if free_lab() == -1:
		return "LABS BUSY"
	if coins < next_cost(id):
		return "NEED COINS"
	return ""


func start(id: String, now: float) -> bool:
	if blocker(id) != "":
		return false
	coins -= next_cost(id)
	labs[free_lab()] = {"id": id, "ends": now + next_seconds(id)}
	return true


func seconds_left(lab: int, now: float) -> float:
	return maxf(float(labs[lab]["ends"]) - now, 0.0)


## Completes every lab whose time is up. Returns the ids that finished.
func finish_due(now: float) -> Array[String]:
	var done: Array[String] = []
	for i in labs.size():
		var id: String = labs[i]["id"]
		if id != "" and now >= float(labs[i]["ends"]):
			research[id] = level(id) + 1
			labs[i] = {"id": "", "ends": 0.0}
			done.append(id)
	return done


## Stores the result of a run. Returns true when it was a new best for that tier.
func record_run(tier: int, wave: int, kills: int) -> bool:
	runs += 1
	total_kills += kills
	var record := wave > best(tier)
	if record:
		best_wave[str(tier)] = wave
	if wave >= Defs.TIER_UNLOCK_WAVE and tier == unlocked_tier and tier < Defs.MAX_TIER:
		unlocked_tier = tier + 1
	return record


func to_dict() -> Dictionary:
	return {
		"version": 1, "coins": coins, "research": research, "labs": labs, "best_wave": best_wave,
		"unlocked_tier": unlocked_tier, "runs": runs, "total_kills": total_kills,
	}


static func from_dict(data: Dictionary) -> ProfileData:
	var p := ProfileData.new()
	p.coins = float(data.get("coins", 0.0))
	for id in data.get("research", {}):
		if Research.ITEMS.has(id):
			p.research[id] = int(data["research"][id])
	var saved_labs: Array = data.get("labs", [])
	for i in mini(saved_labs.size(), p.labs.size()):
		var lab: Dictionary = saved_labs[i]
		var id: String = lab.get("id", "")
		if id == "" or Research.ITEMS.has(id):
			p.labs[i] = {"id": id, "ends": float(lab.get("ends", 0.0))}
	for tier in data.get("best_wave", {}):
		p.best_wave[str(tier)] = int(data["best_wave"][tier])
	p.unlocked_tier = clampi(int(data.get("unlocked_tier", 1)), 1, Defs.MAX_TIER)
	p.runs = int(data.get("runs", 0))
	p.total_kills = int(data.get("total_kills", 0))
	return p
