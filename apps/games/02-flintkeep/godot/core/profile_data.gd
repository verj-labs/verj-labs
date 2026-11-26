class_name ProfileData
extends RefCounted
## Everything that survives between runs: coins, research levels, labs, best waves.
## Pure data: time is passed in (`now`, unix seconds), so it is easy to test.

var coins: float = 0.0
var gems: int = 0  ## rare: missions, milestones, boss drops; buys lab slots and instant finishes
var milestones: Dictionary = {}  ## "tier:wave" -> true once its gems were paid
var seen_enemies: Dictionary = {}  ## enemy kind -> true once it raided one of your runs (bestiary)
var day_mode := "cycle"  ## time of day on the battlefield: see DayNight.MODES
var research: Dictionary = {}  ## id -> level
var workshop: Dictionary = {}  ## id -> level (instant coin upgrades)
## One Dictionary per lab slot: {"id": "" when free, "ends": unix seconds, "total": seconds}.
## A workshop item being researched has the id "w:<workshop id>".
var labs: Array = []
var best_wave: Dictionary = {}  ## tier (as String) -> best wave reached
var unlocked_tier: int = 1
var runs: int = 0
var total_kills: int = 0
var tutorial_done := false
var last_seen := 0.0  ## unix seconds the game was last open, for offline earnings
var mission_day := ""
var missions: Array = []  ## today's missions, see Missions


func _init() -> void:
	labs.append(_empty_lab())  # one lab to start; more are bought with gems


static func _empty_lab() -> Dictionary:
	return {"id": "", "ends": 0.0, "total": 0.0}


func level(id: String) -> int:
	return int(research.get(id, 0))


func best(tier: int) -> int:
	return int(best_wave.get(str(tier), 0))


## True once `kind` has raided one of your runs (or your best waves prove you met it).
func enemy_seen(kind: String) -> bool:
	if seen_enemies.has(kind):
		return true
	for tier in range(1, Defs.MAX_TIER + 1):
		var arrives := Defs.enemy_arrives(kind, tier)
		if arrives >= 1 and best(tier) >= arrives:
			return true
	return false


func is_maxed(id: String) -> bool:
	return level(id) >= int(Research.ITEMS[id]["max"])


func workshop_level(id: String) -> int:
	return int(workshop.get(id, 0))


func workshop_cost(id: String) -> float:
	return Workshop.cost(id, workshop_level(id))


func buy_workshop(id: String) -> bool:
	if Workshop.maxed(id, workshop_level(id)) or coins < workshop_cost(id) or lab_of(WORKSHOP_PREFIX + id) != -1:
		return false
	coins -= workshop_cost(id)
	workshop[id] = workshop_level(id) + 1
	return true


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


# --- Workshop research: a cheaper, slower way to buy a workshop level --------------------------

const WORKSHOP_PREFIX := "w:"


## Why a workshop item cannot be researched right now, or "".
func workshop_blocker(id: String) -> String:
	if Workshop.maxed(id, workshop_level(id)):
		return "MAX"
	if lab_of(WORKSHOP_PREFIX + id) != -1:
		return "IN LAB"
	if free_lab() == -1:
		return "LABS BUSY"
	if coins < Workshop.research_cost(id, workshop_level(id)):
		return "NEED COINS"
	return ""


func start_workshop_research(id: String, now: float) -> bool:
	if workshop_blocker(id) != "":
		return false
	var lvl := workshop_level(id)
	coins -= Workshop.research_cost(id, lvl)
	var secs := Workshop.seconds(id, lvl)
	labs[free_lab()] = {"id": WORKSHOP_PREFIX + id, "ends": now + secs, "total": secs}
	return true


# --- Finishing early and lab slots ----------------------------------------------------------

## Coins to finish a workshop research now: the rest of the difference to the buy price,
## shrinking as the timer runs down. -1 for lab research (that finishes with gems only).
func finish_coin_cost(lab: int, now: float) -> float:
	var id: String = labs[lab]["id"]
	if not id.begins_with(WORKSHOP_PREFIX):
		return -1.0
	var wid := id.trim_prefix(WORKSHOP_PREFIX)
	var lvl := workshop_level(wid)
	var gap := Workshop.cost(wid, lvl) - Workshop.research_cost(wid, lvl)
	var share := seconds_left(lab, now) / maxf(float(labs[lab].get("total", 1.0)), 1.0)
	return ceilf(gap * clampf(share, 0.0, 1.0))


## Gems to finish any research now: one gem per 10 minutes left (at least one).
func finish_gem_cost(lab: int, now: float) -> int:
	return maxi(int(ceil(seconds_left(lab, now) / Research.GEM_SECONDS)), 1)


func finish_with_coins(lab: int, now: float) -> bool:
	var price := finish_coin_cost(lab, now)
	if price < 0.0 or coins < price or labs[lab]["id"] == "":
		return false
	coins -= price
	_complete(lab)
	return true


func finish_with_gems(lab: int, now: float) -> bool:
	if labs[lab]["id"] == "" or gems < finish_gem_cost(lab, now):
		return false
	gems -= finish_gem_cost(lab, now)
	_complete(lab)
	return true


## Gems for the next lab slot, or -1 when every slot is bought.
func next_slot_gems() -> int:
	var index := labs.size() - 1
	return Research.LAB_SLOT_GEMS[index] if index < Research.LAB_SLOT_GEMS.size() else -1


func buy_lab_slot() -> bool:
	var price := next_slot_gems()
	if price < 0 or gems < price:
		return false
	gems -= price
	labs.append(_empty_lab())
	return true


func _complete(lab: int) -> void:
	var id: String = labs[lab]["id"]
	if id.begins_with(WORKSHOP_PREFIX):
		var wid := id.trim_prefix(WORKSHOP_PREFIX)
		workshop[wid] = workshop_level(wid) + 1
	else:
		research[id] = level(id) + 1
	labs[lab] = _empty_lab()


# --- Gems from milestones -------------------------------------------------------------------

## Pays the gems for any milestone wave reached for the first time. Returns the gems paid.
func reach_wave(tier: int, wave: int) -> int:
	var paid := 0
	for i in Research.MILESTONE_WAVES.size():
		var key := "%d:%d" % [tier, Research.MILESTONE_WAVES[i]]
		if wave >= Research.MILESTONE_WAVES[i] and not milestones.has(key):
			milestones[key] = true
			paid += Research.MILESTONE_GEMS[i]
	gems += paid
	return paid


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
	labs[free_lab()] = {"id": id, "ends": now + next_seconds(id), "total": next_seconds(id)}
	return true


func seconds_left(lab: int, now: float) -> float:
	return maxf(float(labs[lab]["ends"]) - now, 0.0)


## Completes every lab whose time is up. Returns the ids that finished.
func finish_due(now: float) -> Array[String]:
	var done: Array[String] = []
	for i in labs.size():
		var id: String = labs[i]["id"]
		if id != "" and now >= float(labs[i]["ends"]):
			_complete(i)
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


const OFFLINE_MIN_SECONDS := 300.0  ## away less than this pays nothing
const OFFLINE_MAX_HOURS := 8.0


## Coins earned per hour while the game is closed: the garrison keeps collecting tolls.
func offline_rate() -> float:
	var top := 0
	for tier in best_wave:
		top = maxi(top, int(best_wave[tier]) * int(tier))
	return 6.0 + 2.0 * top


## Coins owed for the time since last_seen (0 for a first launch or a short absence).
func offline_coins(now: float) -> float:
	if last_seen <= 0.0:
		return 0.0
	var away := now - last_seen
	if away < OFFLINE_MIN_SECONDS:
		return 0.0
	return roundf(offline_rate() * minf(away / 3600.0, OFFLINE_MAX_HOURS))


## Rolls over to a new set of missions when the day changes.
func refresh_missions(day: String) -> void:
	if day == mission_day and not missions.is_empty():
		return
	var top := 0
	for tier in best_wave:
		top = maxi(top, int(best_wave[tier]))
	mission_day = day
	missions = Missions.generate(day, top)


func claimable() -> int:
	var n := 0
	for m in missions:
		if Missions.done(m) and not m["claimed"]:
			n += 1
	return n


func claim(index: int) -> bool:
	if index < 0 or index >= missions.size():
		return false
	var m: Dictionary = missions[index]
	if m["claimed"] or not Missions.done(m):
		return false
	m["claimed"] = true
	coins += m["reward"]
	gems += int(m.get("gems", 0))
	return true


func to_dict() -> Dictionary:
	return {
		"version": 3, "coins": coins, "gems": gems, "milestones": milestones, "seen_enemies": seen_enemies, "day_mode": day_mode, "research": research, "workshop": workshop, "labs": labs, "best_wave": best_wave,
		"unlocked_tier": unlocked_tier, "runs": runs, "total_kills": total_kills,
		"tutorial_done": tutorial_done, "last_seen": last_seen, "mission_day": mission_day, "missions": missions,
	}


static func from_dict(data: Dictionary) -> ProfileData:
	var p := ProfileData.new()
	p.coins = float(data.get("coins", 0.0))
	for id in data.get("research", {}):
		if Research.ITEMS.has(id):
			p.research[id] = int(data["research"][id])
		elif Research.MOVED_TO_WORKSHOP.has(id):  # 0.1 saves: stat research became workshop levels
			p.workshop[Research.MOVED_TO_WORKSHOP[id]] = int(data["research"][id])
	for id in data.get("workshop", {}):
		if Workshop.ITEMS.has(id):
			p.workshop[id] = int(data["workshop"][id])
	p.gems = int(data.get("gems", 0))
	for key in data.get("milestones", {}):
		p.milestones[str(key)] = true
	for kind in data.get("seen_enemies", {}):
		if Defs.ENEMY_ROSTER.has(kind):
			p.seen_enemies[kind] = true
	p.day_mode = str(data.get("day_mode", "cycle"))
	var saved_labs: Array = data.get("labs", [])
	# saves from before lab slots (version < 3) had two labs: players keep both
	var slots := saved_labs.size() if int(data.get("version", 1)) >= 3 else maxi(saved_labs.size(), 2)
	p.labs.clear()
	for i in clampi(slots, 1, Research.LAB_SLOT_GEMS.size() + 1):
		p.labs.append(_empty_lab())
	for i in mini(saved_labs.size(), p.labs.size()):
		var lab: Dictionary = saved_labs[i]
		var id: String = lab.get("id", "")
		var known := Research.ITEMS.has(id) or (id.begins_with(WORKSHOP_PREFIX) and Workshop.ITEMS.has(id.trim_prefix(WORKSHOP_PREFIX)))
		if id == "" or known:
			p.labs[i] = {"id": id, "ends": float(lab.get("ends", 0.0)), "total": float(lab.get("total", 0.0))}
	for tier in data.get("best_wave", {}):
		p.best_wave[str(tier)] = int(data["best_wave"][tier])
	p.unlocked_tier = clampi(int(data.get("unlocked_tier", 1)), 1, Defs.MAX_TIER)
	p.runs = int(data.get("runs", 0))
	p.total_kills = int(data.get("total_kills", 0))
	p.tutorial_done = bool(data.get("tutorial_done", false))
	p.mission_day = str(data.get("mission_day", ""))
	p.last_seen = float(data.get("last_seen", 0.0))
	for m in data.get("missions", []):
		if m is Dictionary and Missions.POOL.has(m.get("kind", "")):
			p.missions.append({"kind": m["kind"], "target": int(m.get("target", 1)), "progress": int(m.get("progress", 0)),
				"reward": int(m.get("reward", 0)), "gems": int(m.get("gems", 0)), "claimed": bool(m.get("claimed", false))})
	return p
