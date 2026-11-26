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
var cash := 0.0
var coins_earned := 0.0
var kills := 0
var over := false

var keep_hp := 0.0
var keep_cooldown := 0.0
var keep_fired := 0.0
var keep_levels := {}  ## upgrade id -> level bought this run
var econ_levels := {}

var rings_unlocked := 1
var slots: Array[Slot] = []
var walls: Array[Wall] = []  ## index = ring; walls[0] is unused
var enemies: Array[Enemy] = []

var _spawn_queue: Array = []  ## [seconds into the wave, kind, angle]
var _next_id := 1


func _init(p_research: Dictionary = {}, p_tier: int = 1, seed_value: int = 0) -> void:
	research = p_research
	tier = p_tier
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	rings_unlocked = 1
	for ring in range(2, Defs.MAX_RING + 1):
		if _r("ring_%d" % ring) >= 1:
			rings_unlocked = ring
	_build_layout()
	cash = BASE_START_CASH + Research.effect("start_cash", _r("start_cash"))
	keep_hp = keep_max_hp()
	_next_wave()


func _r(id: String) -> int:
	return int(research.get(id, 0))


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
		walls.append(wall)


# --- The Keep and the economy ----------------------------------------------------------------

func discount() -> float:
	return Research.effect("discount", _r("discount"))


func keep_damage() -> float:
	var lvl: int = keep_levels.get("damage", 0)
	return Defs.KEEP["dmg"] * (1.0 + Research.effect("keep_damage", _r("keep_damage"))) * pow(1.0 + Defs.KEEP_UPGRADES["damage"]["step"], lvl)


func keep_rate() -> float:
	var lvl: int = keep_levels.get("rate", 0)
	return Defs.KEEP["rate"] * (1.0 + Research.effect("keep_rate", _r("keep_rate"))) * (1.0 + Defs.KEEP_UPGRADES["rate"]["step"] * lvl)


func keep_range() -> float:
	return Defs.KEEP["range"] + Defs.KEEP_UPGRADES["range"]["step"] * keep_levels.get("range", 0)


func keep_max_hp() -> float:
	var lvl: int = keep_levels.get("health", 0)
	return Defs.KEEP["hp"] * (1.0 + Research.effect("keep_health", _r("keep_health"))) * pow(1.0 + Defs.KEEP_UPGRADES["health"]["step"], lvl)


func keep_regen() -> float:
	var lvl: int = keep_levels.get("regen", 0)
	var mult: float = (1.0 + Research.effect("keep_regen", _r("keep_regen"))) * (1.0 + Defs.KEEP_UPGRADES["regen"]["step"] * lvl)
	return keep_max_hp() * Defs.KEEP["regen"] * mult


func keep_armor() -> float:
	return minf(Defs.KEEP_UPGRADES["armor"]["step"] * keep_levels.get("armor", 0), MAX_ARMOR)


func cash_mult() -> float:
	return (1.0 + Research.effect("cash_bonus", _r("cash_bonus"))) * (1.0 + Defs.ECON_UPGRADES["bounty"]["step"] * econ_levels.get("bounty", 0))


func coin_mult() -> float:
	var research_mult := 1.0 + Research.effect("coin_bonus", _r("coin_bonus"))
	var run_mult: float = 1.0 + Defs.ECON_UPGRADES["coin_bounty"]["step"] * econ_levels.get("coin_bounty", 0)
	return research_mult * run_mult * Defs.tier_coin_mult(tier)


func interest_rate() -> float:
	return Defs.ECON_UPGRADES["interest"]["step"] * econ_levels.get("interest", 0)


func upgrade_level(group: Dictionary, id: String) -> int:
	return int(group.get(id, 0))


func keep_upgrade_cost(id: String) -> float:
	return Defs.upgrade_cost(Defs.KEEP_UPGRADES[id], upgrade_level(keep_levels, id), discount())


func econ_upgrade_cost(id: String) -> float:
	return Defs.upgrade_cost(Defs.ECON_UPGRADES[id], upgrade_level(econ_levels, id), discount())


func keep_upgrade_maxed(id: String) -> bool:
	var cap: int = Defs.KEEP_UPGRADES[id]["max"]
	return cap > 0 and upgrade_level(keep_levels, id) >= cap


func econ_upgrade_maxed(id: String) -> bool:
	var cap: int = Defs.ECON_UPGRADES[id]["max"]
	return cap > 0 and upgrade_level(econ_levels, id) >= cap


func buy_keep_upgrade(id: String) -> bool:
	if keep_upgrade_maxed(id) or not _pay(keep_upgrade_cost(id)):
		return false
	var old_max := keep_max_hp()
	keep_levels[id] = upgrade_level(keep_levels, id) + 1
	keep_hp += keep_max_hp() - old_max  # extra health arrives full
	return true


func buy_econ_upgrade(id: String) -> bool:
	if econ_upgrade_maxed(id) or not _pay(econ_upgrade_cost(id)):
		return false
	econ_levels[id] = upgrade_level(econ_levels, id) + 1
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
	tower.invested = price
	slots[index].tower = tower
	_event({"type": "built", "slot": index})
	return true


func tower_upgrade_cost(index: int) -> float:
	var tower := slots[index].tower
	var def: Dictionary = Defs.WEAPONS[tower.weapon]
	var off := 1.0 - maxf(discount(), 0.0)
	var weapon_off := 1.0 - Research.weapon_discount(tower.weapon, _r(tower.weapon))
	return def["cost"] * Defs.WEAPON_UPGRADE_BASE * pow(Defs.WEAPON_COST_GROWTH, tower.level - 1) * off * weapon_off


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
	return Defs.WEAPONS[tower.weapon]["dmg"] * pow(Defs.WEAPON_DMG_GROWTH, tower.level - 1)


func tower_rate(tower: Tower) -> float:
	return Defs.WEAPONS[tower.weapon]["rate"] * (1.0 + Defs.WEAPON_RATE_GROWTH * (tower.level - 1))


func tower_range(tower: Tower) -> float:
	return Defs.WEAPONS[tower.weapon]["range"] + Defs.WEAPON_RANGE_GROWTH * (tower.level - 1)


# --- Walls ----------------------------------------------------------------------------------

func wall_radius(ring: int) -> float:
	return Defs.RING_RADII[ring] + Defs.WALL_OFFSET


func wall_max_hp(ring: int, level: int, fortified: bool = false) -> float:
	var masonry := 1.0 + Research.effect("masonry", _r("masonry"))
	var bonus := Defs.FORTIFIED_HP if fortified else 1.0
	return Defs.WALL_HP * pow(Defs.WALL_HP_RING_GROWTH, ring - 1) * pow(Defs.WALL_HP_GROWTH, level) * masonry * bonus


func section_cost(ring: int) -> float:
	return Defs.WALL_BUILD_BASE * Defs.WALL_SECTION_SHARE * pow(Defs.WALL_RING_GROWTH, ring - 1) * (1.0 - discount())


## The price of every section of `ring` still missing.
func wall_build_cost(ring: int) -> float:
	return section_cost(ring) * (Defs.SLOT_COUNTS[ring] - walls[ring].built_count())


func wall_reinforce_cost(ring: int) -> float:
	return Defs.WALL_BUILD_BASE * pow(Defs.WALL_RING_GROWTH, ring - 1) * (1.0 - discount()) * pow(Defs.WALL_REINFORCE_GROWTH, walls[ring].level + 1)


func wall_repair_cost(ring: int) -> float:
	return ceilf(wall_reinforce_cost(ring) * Defs.WALL_REPAIR_SHARE * walls[ring].missing_share())


func section_open(ring: int, seg: int) -> bool:
	return ring >= 1 and ring <= rings_unlocked and seg >= 0 and seg < Defs.SLOT_COUNTS[ring]


func build_section(ring: int, seg: int) -> bool:
	if not section_open(ring, seg) or walls[ring].sections[seg] or not _pay(section_cost(ring)):
		return false
	var wall := walls[ring]
	wall.sections[seg] = true
	_update_wall_hp(wall)
	wall.segments[seg] = wall.max_hp
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


func repair_wall(ring: int) -> bool:
	var wall := walls[ring]
	if not wall.built or wall.missing_share() <= 0.0 or not _pay(wall_repair_cost(ring)):
		return false
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
	BattleCombat.move_enemies(self, dt)
	keep_hp = minf(keep_hp + keep_regen() * dt, keep_max_hp())
	BattleCombat.fire(self, dt)
	_collect_dead()
	if keep_hp <= 0.0:
		keep_hp = 0.0
		over = true
		_event({"type": "game_over"})


const EARLY_BONUS_PER_SECOND := 0.6  ## cash per second skipped, times the wave number


## Starts the next wave now; pays a bonus for the time skipped. Only once the current wave
## has finished arriving.
func early_bonus() -> float:
	return floorf(maxf(wave_timer, 0.0) * EARLY_BONUS_PER_SECOND * wave)


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


func wave_elapsed() -> float:
	return Defs.WAVE_SECONDS - wave_timer


func _next_wave() -> void:
	if wave > 0 and interest_rate() > 0.0:
		var gain := minf(cash * interest_rate(), Defs.INTEREST_CAP_PER_WAVE * wave)
		cash += gain
		_event({"type": "interest", "cash": gain})
	wave += 1
	wave_timer += Defs.WAVE_SECONDS
	coins_earned += Defs.WAVE_COINS * wave * coin_mult()
	_spawn_queue = BattleWaves.plan(wave, rng)
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
	e.max_hp = def["hp"] * pow(Defs.HP_GROWTH, w) * tier_mult
	e.hp = e.max_hp
	e.dps = def["dps"] * pow(Defs.DPS_GROWTH, w) * sqrt(tier_mult)
	e.speed = def["speed"]
	e.armor = def["armor"]
	e.ward = def["ward"]
	e.air = def["air"]
	e.boss = kind == "juggernaut"
	e.cash = def["cash"] * pow(Defs.CASH_GROWTH, w)
	e.coins = def["coins"] * (1.0 + Defs.COIN_GROWTH * w)
	e.size = def["size"]
	e.burst = def.get("burst", 0.0) * pow(Defs.DPS_GROWTH, w) * sqrt(tier_mult)
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
		_event({"type": "kill", "pos": e.pos(), "cash": cash_gain, "coins": coin_gain, "kind": e.kind, "boss": e.boss})
		enemies.remove_at(i)


func _event(data: Dictionary) -> void:
	if record_events:
		events.append(data)


func drain_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out
