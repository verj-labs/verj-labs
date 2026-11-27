class_name Battle
extends RefCounted
## One endless run: waves, enemies, the Keep, towers and walls, and the cash economy.
## No nodes, no drawing: call step(dt) and read the state, or drain `events` to animate it.
## The same code runs the game, the tests and the balance simulation.

const Enemy = Entities.Enemy
const Tower = Entities.Tower
const Slot = Entities.Slot
const Wall = Entities.Wall

const BASE_START_CASH := 60.0
const RUBBLE_REACH := 5.0  ## a raider this close to a broken section is standing on it
const BOSS_GEM_CHANCE := 0.15  ## a Juggernaut sometimes drops a gem
const REROLL_GEMS := 10  ## gems to swap the three perks on offer for three new ones
const SPAWN_MARGIN := 10.0
const MAX_ARMOR := 0.6

var tier: int
var rng := RandomNumberGenerator.new()
var research: Dictionary  ## id -> level, from the profile.
var record_events := true
var events: Array[Dictionary] = []
## Half the visible battlefield; enemies appear just outside it.
var spawn_extents := Vector2(140.0, 180.0)

var time := 0.0
var wave := 0
var wave_timer := 0.0
var heal_timer := 0.0  ## next shaman healing pulse
var cash := 0.0
var coins_earned := 0.0
var kinds_seen := {}  ## enemy kinds that raided this run (the profile's bestiary learns them)
var gems_earned := 0  ## rare boss drops, banked into the profile by the screen
var kills := 0
var over := false

var keep_hp := 0.0
var keep_cooldown := 0.0
var keep_fired := 0.0
var levels := {}  ## cash upgrade id -> level bought this run (see Upgrades)
var workshop: Dictionary  ## id -> level, from the profile's coin workshop

## Perks chosen this run (Perks), and the choice on offer: three ids and seconds left.
var perk := {}
var perk_offer: Array[String] = []
var perk_time := 0.0

## Powers (Powers): seconds until each is ready, which ones cast themselves, effect timers.
var power_cd := {}
var power_auto := {}
var freeze_left := 0.0
var gold_left := 0.0

## Tabs whose upgrades buy themselves when cash allows ("Attack", "Walls" ...).
var auto_tabs := {}
var _auto_timer := 0.0

## End-of-run report: damage by source, kills by enemy kind, what last hit the Keep.
var damage_by := {}
var kills_by := {}
var killed_by := ""

var rings_unlocked := 1
var slots: Array[Slot] = []
var walls: Array[Wall] = []  ## index = ring; walls[0] is unused
var enemies: Array[Enemy] = []

var _spawn_queue: Array = []  ## [seconds into the wave, kind, angle]
var _next_id := 1


func _init(p_research: Dictionary = {}, p_tier: int = 1, seed_value: int = 0, p_workshop: Dictionary = {}) -> void:
	research = p_research
	workshop = p_workshop
	tier = p_tier
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_build_layout()
	refresh_unlocks()
	cash = BASE_START_CASH + Workshop.effect("start_cash", _w("start_cash"))
	keep_hp = keep_max_hp()
	for id in Powers.ORDER:
		power_cd[id] = 0.0
		power_auto[id] = false
	_next_wave()


## Research and workshop levels are read live from the profile, so anything finished during a
## run applies at once. Rings are the one thing that needs a nudge when they unlock.
func refresh_unlocks() -> void:
	rings_unlocked = 1
	for ring in range(2, Defs.MAX_RING + 1):
		if _r("ring_%d" % ring) >= 1:
			rings_unlocked = ring


func _r(id: String) -> int:
	return int(research.get(id, 0))


func _w(id: String) -> int:
	return int(workshop.get(id, 0))


func _ws(id: String) -> float:
	return Workshop.effect(id, _w(id))


func perk_mult(stat: String) -> float:
	return float(perk.get(stat, 1.0))


func perk_add(stat: String) -> float:
	return float(perk.get(stat, 0.0))


func _build_layout() -> void:
	walls.append(null)
	for ring in range(1, Defs.MAX_RING + 1):
		var count: int = Defs.SLOT_COUNTS[ring]
		var offset := Defs.ring_angle_offset(ring)
		for i in count:
			var slot := Slot.new()
			slot.ring = ring
			slot.index = slots.size()
			slot.angle = offset + TAU * i / count
			slot.pos = Vector2(cos(slot.angle), sin(slot.angle)) * Defs.RING_RADII[ring]
			slots.append(slot)
		var wall := Wall.new()
		wall.ring = ring
		for i in count:
			wall.sections.append(false)
			wall.segments.append(0.0)
			wall.broken.append(false)
		walls.append(wall)


# --- The Keep and the economy ----------------------------------------------------------------

func discount() -> float:
	return Research.effect("discount", _r("discount"))


func level(id: String) -> int:
	return int(levels.get(id, 0))


func stat(id: String) -> float:
	return Upgrades.value(id, level(id))


func keep_damage() -> float:
	return stat("damage") * _ws("damage") * perk_mult("damage")


func keep_rate() -> float:
	return stat("rate") * (1.0 + _ws("rate"))


func keep_range() -> float:
	return stat("range")


func keep_max_hp() -> float:
	return stat("health") * _ws("health") * perk_mult("health")


func keep_regen() -> float:
	return keep_max_hp() * minf(stat("regen") * _ws("regen"), Defs.KEEP_REGEN_MAX) / 100.0


func keep_armor() -> float:
	return stat("armor")


func crit_chance() -> float:
	return minf(stat("crit_chance") + _ws("crit") + perk_add("crit"), 0.95)


func multishot_chance() -> float:
	return minf(stat("multishot") + perk_add("multishot"), 0.9)


## Extra enemies a multishot hits: one more for every 10 levels bought, up to 4.
func multishot_targets() -> int:
	return mini(1 + level("multishot") / 10, 4)


func bounce_chance() -> float:
	return minf(stat("bounce") + perk_add("bounce"), 0.8)


func push_chance() -> float:
	return minf(stat("push_chance") + perk_add("push"), 0.8)


func cash_mult() -> float:
	return stat("bounty") * _ws("cash") * perk_mult("cash") * (2.0 if gold_left > 0.0 else 1.0)


func coin_mult() -> float:
	var research_mult := 1.0 + Research.effect("coin_bonus", _r("coin_bonus"))
	return stat("coin_bounty") * research_mult * perk_mult("coins") * Defs.tier_coin_mult(tier)


## A few coins every wave; the Economy tab's "Coins per wave" raises it (kill bounty does not).
func wave_coins() -> float:
	return stat("wave_coins") * coin_mult() / stat("coin_bounty")


func interest_rate() -> float:
	return stat("interest")


func siege() -> float:
	return minf(Research.effect("siege", _r("siege")), 0.75)


## Enemies move this much slower while Freeze is active.
func enemy_speed_factor() -> float:
	return 0.3 if freeze_left > 0.0 else 1.0


func upgrade_cost(id: String) -> float:
	return Upgrades.price(id, level(id)) * (1.0 - discount())


func upgrade_maxed(id: String) -> bool:
	return Upgrades.maxed(id, level(id))


func buy_upgrade(id: String) -> bool:
	if upgrade_maxed(id) or not _pay(upgrade_cost(id)):
		return false
	var old_max := keep_max_hp()
	levels[id] = level(id) + 1
	keep_hp += keep_max_hp() - old_max  # extra health arrives full
	_event({"type": "bought", "id": id})
	return true


func _pay(amount: float) -> bool:
	if over or cash < amount - 0.001:
		return false
	cash -= amount
	return true


# --- Towers ---------------------------------------------------------------------------------

func weapon_unlocked(weapon: String) -> bool:
	return Research.weapon_unlocked(weapon, _r(weapon))


func slot_open(index: int) -> bool:
	return index >= 0 and index < slots.size() and slots[index].ring <= rings_unlocked


func build_cost(weapon: String) -> float:
	return Defs.WEAPONS[weapon]["cost"] * (1.0 - discount())


func build(index: int, weapon: String) -> bool:
	if not slot_open(index) or slots[index].tower != null or not weapon_unlocked(weapon):
		return false
	var price := build_cost(weapon)
	if not _pay(price):
		return false
	var tower := Tower.new()
	tower.weapon = weapon
	tower.level = Research.weapon_start_level(weapon, _r(weapon))
	tower.start_level = tower.level
	tower.invested = price
	slots[index].tower = tower
	_event({"type": "built", "slot": index})
	return true


func tower_upgrade_cost(index: int) -> float:
	var tower := slots[index].tower
	var def: Dictionary = Defs.WEAPONS[tower.weapon]
	var off := 1.0 - maxf(discount(), 0.0)
	var weapon_off := 1.0 - Research.weapon_discount(tower.weapon, _r(tower.weapon))
	# priced by levels bought this run, so research that starts towers higher never costs more
	return def["cost"] * Defs.WEAPON_UPGRADE_BASE * pow(Defs.WEAPON_COST_GROWTH, tower.level - tower.start_level) * off * weapon_off


func upgrade_tower(index: int) -> bool:
	var tower := slots[index].tower
	if tower == null:
		return false
	var price := tower_upgrade_cost(index)
	if not _pay(price):
		return false
	tower.level += 1
	tower.invested += price
	_event({"type": "upgraded", "slot": index})
	return true


# --- Tower add-ons and whole-fortress actions -------------------------------------------------

func addon_count(id: String) -> int:
	var n := 0
	for slot in slots:
		if slot.tower != null and slot.tower.addons.has(id):
			n += 1
	return n


## Price of add-on `id` for the tower in slot `index`, or -1 if there is no tower or it has it.
func addon_cost(index: int, id: String, already: int = -1) -> float:
	var tower := slots[index].tower
	if tower == null or tower.addons.has(id):
		return -1.0
	var owned := addon_count(id) if already < 0 else already
	var base: float = Defs.WEAPONS[tower.weapon]["cost"] * Defs.ADDONS[id]["cost"]
	return base * pow(Defs.ADDON_GROWTH, owned) * (1.0 - maxf(discount(), 0.0))


func buy_addon(index: int, id: String) -> bool:
	var price := addon_cost(index, id)
	if price < 0.0 or over or not _pay(price):
		return false
	var tower := slots[index].tower
	tower.addons[id] = true
	tower.invested += price
	_event({"type": "upgraded", "slot": index})
	return true


## Slots whose tower lacks add-on `id`, cheapest weapon first.
func towers_without(id: String) -> Array[int]:
	var out: Array[int] = []
	for slot in slots:
		if slot.tower != null and slot_open(slot.index) and not slot.tower.addons.has(id):
			out.append(slot.index)
	out.sort_custom(func(a: int, c: int) -> bool: return Defs.WEAPONS[slots[a].tower.weapon]["cost"] < Defs.WEAPONS[slots[c].tower.weapon]["cost"])
	return out


## What giving every tower add-on `id` costs (each one dearer than the last), or -1 if all have it.
func addon_all_cost(id: String) -> float:
	var todo := towers_without(id)
	if todo.is_empty():
		return -1.0
	var total := 0.0
	var owned := addon_count(id)
	for index in todo:
		total += addon_cost(index, id, owned)
		owned += 1
	return total


## Gives add-on `id` to as many towers as cash allows, cheapest first.
func buy_addon_all(id: String) -> bool:
	var bought := false
	for index in towers_without(id):
		if not buy_addon(index, id):
			break
		bought = true
	return bought


## The cheapest single step of "upgrade all" (to enable its button), or -1 with no towers.
func cheapest_tower_upgrade() -> float:
	var best := -1.0
	for slot in slots:
		if slot.tower != null and slot_open(slot.index):
			var price := tower_upgrade_cost(slot.index)
			if best < 0.0 or price < best:
				best = price
	return best


## One more level for every tower, or -1 with no towers.
func upgrade_all_cost() -> float:
	var total := -1.0
	for slot in slots:
		if slot.tower != null and slot_open(slot.index):
			total = maxf(total, 0.0) + tower_upgrade_cost(slot.index)
	return total


## Raises every tower one level, cheapest first, as far as cash allows.
func upgrade_all_towers() -> bool:
	var order: Array[int] = []
	for slot in slots:
		if slot.tower != null and slot_open(slot.index):
			order.append(slot.index)
	order.sort_custom(func(a: int, c: int) -> bool: return tower_upgrade_cost(a) < tower_upgrade_cost(c))
	var bought := false
	for index in order:
		if not upgrade_tower(index):
			break
		bought = true
	return bought


## Sets every tower's targeting ("" = each weapon's default).
func set_focus_all(focus: String) -> void:
	for slot in slots:
		if slot.tower != null:
			slot.tower.focus = focus


func sell_value(index: int) -> float:
	var tower := slots[index].tower
	return 0.0 if tower == null else tower.invested * Defs.SELL_REFUND


func sell(index: int) -> bool:
	if over or slots[index].tower == null:
		return false
	cash += sell_value(index)
	slots[index].tower = null
	return true


func tower_damage(tower: Tower) -> float:
	return Defs.WEAPONS[tower.weapon]["dmg"] * pow(Defs.WEAPON_DMG_GROWTH, tower.level - 1) * _ws("towers") * perk_mult("towers")


func tower_rate(tower: Tower) -> float:
	return Defs.WEAPONS[tower.weapon]["rate"] * (1.0 + Defs.WEAPON_RATE_GROWTH * (tower.level - 1))


func tower_range(tower: Tower) -> float:
	return Defs.WEAPONS[tower.weapon]["range"] + minf(Defs.WEAPON_RANGE_GROWTH * (tower.level - 1), Defs.WEAPON_RANGE_MAX)


# --- Walls ----------------------------------------------------------------------------------

func wall_radius(ring: int) -> float:
	return Defs.RING_RADII[ring] + Defs.WALL_OFFSET


func wall_max_hp(ring: int, level: int, fortified: bool = false) -> float:
	var masonry := _ws("masonry") * perk_mult("walls")
	var bonus := Defs.FORTIFIED_HP if fortified else 1.0
	return Defs.WALL_HP * pow(Defs.WALL_HP_RING_GROWTH, ring - 1) * pow(Defs.WALL_HP_GROWTH, level) * masonry * bonus


func section_cost(ring: int) -> float:
	return Defs.WALL_BUILD_BASE * Defs.WALL_SECTION_SHARE * pow(Defs.WALL_RING_GROWTH, ring - 1) * (1.0 - discount())


## The price of every section of `ring` still missing.
func wall_build_cost(ring: int) -> float:
	return section_cost(ring) * (Defs.SLOT_COUNTS[ring] - walls[ring].built_count())


func wall_reinforce_cost(ring: int) -> float:
	return Defs.WALL_BUILD_BASE * pow(Defs.WALL_RING_GROWTH, ring - 1) * (1.0 - discount()) * pow(Defs.WALL_REINFORCE_GROWTH, walls[ring].level + 1)


func wall_addon_count(id: String) -> int:
	var n := 0
	for ring in range(1, walls.size()):
		if walls[ring].addons.has(id):
			n += 1
	return n


## Why add-on `id` cannot be bought for `ring` yet ("" if it can, or it is owned).
func wall_addon_blocker(ring: int, id: String) -> String:
	var needs: String = Defs.WALL_ADDONS[id]["needs"]
	if needs != "" and level(needs) < 1:
		return "Unlock %s in Defense" % Upgrades.LIST[needs]["name"]
	if not walls[ring].built:
		return "Build the wall first"
	return ""


## Price of wall add-on `id` for `ring`, or -1 if it is owned or cannot be bought yet.
func wall_addon_cost(ring: int, id: String) -> float:
	if walls[ring].addons.has(id) or wall_addon_blocker(ring, id) != "":
		return -1.0
	var base := Defs.WALL_BUILD_BASE * pow(Defs.WALL_RING_GROWTH, ring - 1) * (1.0 - discount())
	return base * Defs.WALL_ADDONS[id]["cost"] * pow(Defs.ADDON_GROWTH, wall_addon_count(id))


func buy_wall_addon(ring: int, id: String) -> bool:
	var price := wall_addon_cost(ring, id)
	if price < 0.0 or over or not _pay(price):
		return false
	walls[ring].addons[id] = true
	_event({"type": "wall_built", "ring": ring})
	return true


func section_open(ring: int, seg: int) -> bool:
	return ring >= 1 and ring <= rings_unlocked and seg >= 0 and seg < Defs.SLOT_COUNTS[ring]


func build_section(ring: int, seg: int) -> bool:
	if not section_open(ring, seg) or walls[ring].sections[seg] or not _pay(section_cost(ring)):
		return false
	var wall := walls[ring]
	wall.sections[seg] = true
	_update_wall_hp(wall)
	wall.segments[seg] = wall.max_hp
	wall.broken[seg] = false
	_event({"type": "wall_built", "ring": ring, "segment": seg})
	if wall.complete():
		_event({"type": "fortified", "ring": ring})
	return true


## Builds every missing section of `ring` at once.
func build_wall(ring: int) -> bool:
	if ring > rings_unlocked or walls[ring].complete() or not _pay(wall_build_cost(ring)):
		return false
	var wall := walls[ring]
	for i in wall.sections.size():
		if not wall.sections[i]:
			wall.sections[i] = true
			wall.segments[i] = 0.0
	_update_wall_hp(wall)
	_heal_wall(wall)
	_event({"type": "fortified", "ring": ring})
	return true


func reinforce_wall(ring: int) -> bool:
	var wall := walls[ring]
	if not wall.built or not _pay(wall_reinforce_cost(ring)):
		return false
	wall.level += 1
	_update_wall_hp(wall)
	_heal_wall(wall)
	return true


## Keeps each built section's share of health when the maximum changes.
func _update_wall_hp(wall: Wall) -> void:
	var old := wall.max_hp
	wall.max_hp = wall_max_hp(wall.ring, wall.level, wall.complete())
	if old > 0.0:
		for i in wall.segments.size():
			wall.segments[i] *= wall.max_hp / old


func _heal_wall(wall: Wall) -> void:
	for i in wall.segments.size():
		wall.segments[i] = wall.max_hp if wall.sections[i] else 0.0
		wall.broken[i] = false
	_event({"type": "wall_built", "ring": wall.ring})


## Damage of a tower in its slot: towers on a fortified ring hit harder.
func slot_damage(slot: Slot) -> float:
	var dmg := tower_damage(slot.tower)
	if walls[slot.ring].complete():
		dmg *= 1.0 + Defs.FORTIFIED_DAMAGE
	return dmg


## Which section of a ring's wall stands in the way of an enemy coming from `angle`.
## Sections run between neighbouring towers: section i spans tower i to tower i + 1.
static func wall_segment(ring: int, angle: float) -> int:
	var count: int = Defs.SLOT_COUNTS[ring]
	var step := TAU / count
	return posmod(int(floor((angle - Defs.ring_angle_offset(ring)) / step)), count)


## The angle at the middle of a section.
static func section_angle(ring: int, seg: int) -> float:
	var step: float = TAU / Defs.SLOT_COUNTS[ring]
	return Defs.ring_angle_offset(ring) + step * (seg + 0.5)


# --- Running the battle ---------------------------------------------------------------------

func step(dt: float) -> void:
	if over:
		return
	time += dt
	wave_timer -= dt
	if wave_timer <= 0.0:
		_next_wave()
	_spawn_due()
	_tick_effects(dt)
	BattleCombat.move_enemies(self, dt)
	keep_hp = minf(keep_hp + keep_regen() * dt, keep_max_hp())
	BattleCombat.fire(self, dt)
	_collect_dead()
	_auto_timer += dt
	if _auto_timer >= 0.5:
		_auto_timer = 0.0
		_auto_buy()
	if keep_hp <= 0.0:
		keep_hp = 0.0
		over = true
		perk_offer.clear()
		_event({"type": "game_over"})


const EARLY_BONUS_PER_SECOND := 0.6  ## cash per second skipped (times 4x the wave's cash scale)


## Starts the next wave now; pays a bonus for the time skipped. Only once the current wave
## has finished arriving.
func early_bonus() -> float:
	return floorf(maxf(wave_timer, 0.0) * EARLY_BONUS_PER_SECOND * 4.0 * Upgrades.cash_scale(wave, siege()))


func can_call_early() -> bool:
	return not over and wave_elapsed() >= Defs.SPAWN_SECONDS and _spawn_queue.is_empty()


func call_next_wave() -> bool:
	if not can_call_early():
		return false
	var bonus := early_bonus()
	cash += bonus
	_event({"type": "early", "cash": bonus})
	wave_timer = 0.0
	_next_wave()
	return true


# --- Perks ---------------------------------------------------------------------------------

func choose_perk(id: String) -> bool:
	if not perk_offer.has(id):
		return false
	var p: Dictionary = Perks.LIST[id]
	var key: String = p["stat"]
	if p["kind"] == "mult":
		perk[key] = perk_mult(key) * p["value"]
	else:
		perk[key] = perk_add(key) + p["value"]
	if key == "health":
		keep_hp = keep_max_hp()
	if key == "walls":
		for ring in range(1, Defs.MAX_RING + 1):
			if walls[ring].built:
				_update_wall_hp(walls[ring])
				_heal_wall(walls[ring])
	perk_offer.clear()
	_event({"type": "perk_chosen", "id": id})
	return true


## New perks on offer (the screen charges the gems). The timer starts again.
func reroll_perks() -> bool:
	if perk_offer.is_empty():
		return false
	perk_offer = Perks.pick_three(rng)
	perk_time = Defs.PERK_SECONDS
	return true


# --- Powers --------------------------------------------------------------------------------

func power_level(id: String) -> int:
	return _r(Powers.LIST[id]["research"])


func power_ready(id: String) -> bool:
	return power_level(id) >= 1 and float(power_cd[id]) <= 0.0 and not over


func cast(id: String) -> bool:
	if not power_ready(id):
		return false
	var lvl := power_level(id)
	power_cd[id] = Powers.cooldown(id, lvl)
	match id:
		"rain":
			for e in enemies:
				_deal(e, keep_damage() * Powers.power(id, lvl), Defs.DamageType.PHYSICAL, 0.5, "Arrow Rain")
		"thunder":
			var targets := enemies.duplicate()
			targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.hp > b.hp)
			for e in targets.slice(0, Powers.strikes(lvl)):
				_deal(e, keep_damage() * Powers.power(id, lvl), Defs.DamageType.MAGIC, 0.0, "Thunderstorm")
				_event({"type": "chain", "from": e.pos() + Vector2(0, -60), "to": e.pos()})
		"freeze":
			freeze_left = Powers.power(id, lvl)
		"gold":
			gold_left = Powers.power(id, lvl)
	_event({"type": "power", "id": id})
	return true


func _tick_effects(dt: float) -> void:
	freeze_left = maxf(freeze_left - dt, 0.0)
	gold_left = maxf(gold_left - dt, 0.0)
	for id in Powers.ORDER:
		power_cd[id] = maxf(float(power_cd[id]) - dt, 0.0)
		if power_auto[id] and power_ready(id) and enemies.size() >= 3:
			cast(id)
	if not perk_offer.is_empty():
		perk_time -= dt
		if perk_time <= 0.0:
			choose_perk(perk_offer[rng.randi() % perk_offer.size()])
	_regrow_walls(dt)


## Walls mend themselves (there is no paid repair): every built section regenerates, 0.1% of
## its health a second to start, faster with the Wall regeneration upgrade. A broken section
## regrows as rubble that raiders walk through, and only while no raider stands on it; it
## stands (and blocks) again at WALL_REBUILD_SHARE of its health. Blocking from the first
## sliver would make walls with regeneration unbreakable.
func _regrow_walls(dt: float) -> void:
	var regen := stat("wall_regen")
	if regen <= 0.0:
		return
	var occupied := _raiders_on_rubble()
	for ring in range(1, rings_unlocked + 1):
		var wall := walls[ring]
		for i in wall.segments.size():
			if not wall.sections[i] or wall.segments[i] >= wall.max_hp:
				continue
			if wall.broken[i] and occupied.has(ring * 100 + i):
				continue  # raiders are climbing through the gap
			wall.segments[i] = minf(wall.segments[i] + wall.max_hp * regen * dt, wall.max_hp)
			if wall.broken[i] and wall.segments[i] >= wall.max_hp * Defs.WALL_REBUILD_SHARE:
				wall.broken[i] = false
				_event({"type": "wall_built", "ring": ring, "segment": i, "regrown": true})


## Broken sections with a ground raider on them, as ring * 100 + segment.
func _raiders_on_rubble() -> Dictionary:
	var out := {}
	for e in enemies:
		if e.air or not e.alive():
			continue
		for ring in range(1, rings_unlocked + 1):
			if absf(e.dist - wall_radius(ring)) <= e.size * 0.5 + RUBBLE_REACH:
				var seg := wall_segment(ring, e.angle)
				if walls[ring].broken[seg]:
					out[ring * 100 + seg] = true
	return out


## Damage from any source, with armour/ward, run stats and lifesteal. Returns damage dealt.
func _deal(e: Enemy, amount: float, type: int, pierce: float, source: String) -> float:
	var dealt := BattleCombat.hit(e, amount, type, pierce)
	damage_by[source] = float(damage_by.get(source, 0.0)) + dealt
	var steal := stat("lifesteal")
	if steal > 0.0 and source == "Keep":  # lifesteal heals from the Keep's own shots
		keep_hp = minf(keep_hp + dealt * steal, keep_max_hp())
	return dealt


# --- Auto-buy ------------------------------------------------------------------------------

func set_auto(tab: String, on: bool) -> void:
	auto_tabs[tab] = on


## Buys the cheapest affordable upgrade in each auto tab (walls: missing sections, then add-ons).
func _auto_buy() -> void:
	for tab in auto_tabs:
		if not auto_tabs[tab]:
			continue
		if tab == "Walls":
			_auto_walls()
		if tab == "Towers":
			_auto_towers()
		var best := ""
		for id in Upgrades.ids_in(tab):
			if not upgrade_maxed(id) and (best == "" or upgrade_cost(id) < upgrade_cost(best)):
				best = id
		if best != "" and cash >= upgrade_cost(best):
			buy_upgrade(best)


## The Towers tab's auto-buy: the cheapest tower level or add-on.
func _auto_towers() -> void:
	var best_price := INF
	var best: Callable
	for slot in slots:
		if slot.tower == null or not slot_open(slot.index):
			continue
		var up := tower_upgrade_cost(slot.index)
		if up < best_price:
			best_price = up
			best = upgrade_tower.bind(slot.index)
		for id in Defs.ADDON_ORDER:
			var price := addon_cost(slot.index, id)
			if price >= 0.0 and price < best_price:
				best_price = price
				best = buy_addon.bind(slot.index, id)
	if best.is_valid() and cash >= best_price:
		best.call()


func _auto_walls() -> void:
	for ring in range(1, rings_unlocked + 1):
		var gap := walls[ring].sections.find(false)
		if gap != -1 and build_section(ring, gap):
			return
	for ring in range(1, rings_unlocked + 1):
		for id in Defs.WALL_ADDON_ORDER:
			if buy_wall_addon(ring, id):
				return


func wave_elapsed() -> float:
	return Defs.WAVE_SECONDS - wave_timer


func _next_wave() -> void:
	if wave > 0:
		var pay := stat("wave_cash") * Upgrades.cash_scale(wave, siege()) * _ws("cash")
		if interest_rate() > 0.0:
			pay += minf(cash * interest_rate(), Defs.INTEREST_CAP_PER_WAVE * Upgrades.cash_scale(wave, siege()) * 10.0)
		cash += pay
		_event({"type": "interest", "cash": pay})
	var advanced := wave < Defs.MAX_WAVE  # after the last wave it just repeats
	if advanced:
		wave += 1
	if advanced and wave % Defs.PERK_EVERY == 0:
		perk_offer = Perks.pick_three(rng)
		perk_time = Defs.PERK_SECONDS
		_event({"type": "perk_offer"})
	wave_timer += Defs.WAVE_SECONDS
	coins_earned += wave_coins()
	_spawn_queue = BattleWaves.plan(wave, rng, tier)
	_event({"type": "wave", "wave": wave, "boss": wave % Defs.BOSS_EVERY == 0})


func _spawn_due() -> void:
	var elapsed := wave_elapsed()
	while not _spawn_queue.is_empty() and _spawn_queue[0][0] <= elapsed:
		var entry: Array = _spawn_queue.pop_front()
		spawn(entry[1], entry[2])


## Puts an enemy at the edge of the field in direction `angle`, scaled to the current wave.
func spawn(kind: String, angle: float) -> Enemy:
	var def: Dictionary = Defs.ENEMIES[kind]
	var e := Enemy.new()
	e.id = _next_id
	_next_id += 1
	e.kind = kind
	e.angle = angle
	var c := absf(cos(angle))
	var s := absf(sin(angle))
	var edge := minf(spawn_extents.x / maxf(c, 0.001), spawn_extents.y / maxf(s, 0.001))
	e.dist = edge + SPAWN_MARGIN
	var w := wave - 1
	var tier_mult := Defs.tier_enemy_mult(tier)
	e.max_hp = def["hp"] * Upgrades.enemy_scale(wave, siege()) * tier_mult
	e.hp = e.max_hp
	e.dps = def["dps"] * Upgrades.dps_scale(wave, siege()) * sqrt(tier_mult)
	e.speed = def["speed"]
	e.armor = def["armor"]
	e.ward = def["ward"]
	e.air = def["air"]
	e.boss = kind == "juggernaut" or kind in Defs.CHAMPIONS
	e.aura = def.get("aura", 0.0)
	e.wall_mult = def.get("wall_mult", 1.0)
	e.standoff = def.get("standoff", 0.0)
	kinds_seen[kind] = true
	e.cash = def["cash"] * Upgrades.cash_scale(wave, siege())
	e.coins = def["coins"] * (1.0 + Defs.COIN_GROWTH * w)
	e.size = def["size"]
	e.burst = def.get("burst", 0.0) * Upgrades.dps_scale(wave, siege()) * sqrt(tier_mult)
	e.heal = def.get("heal", 0.0)
	enemies.append(e)
	return e


func _collect_dead() -> void:
	var i := 0
	while i < enemies.size():
		var e := enemies[i]
		if e.alive():
			i += 1
			continue
		var cash_gain := e.cash * cash_mult()
		var coin_gain := e.coins * coin_mult()
		cash += cash_gain
		coins_earned += coin_gain
		kills += 1
		kills_by[e.kind] = int(kills_by.get(e.kind, 0)) + 1
		if e.boss and rng.randf() < BOSS_GEM_CHANCE:
			gems_earned += 1
			_event({"type": "gem", "pos": e.pos()})
		_event({"type": "kill", "pos": e.pos(), "cash": cash_gain, "coins": coin_gain, "kind": e.kind, "boss": e.boss})
		enemies.remove_at(i)


func _event(data: Dictionary) -> void:
	if record_events:
		events.append(data)


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out
