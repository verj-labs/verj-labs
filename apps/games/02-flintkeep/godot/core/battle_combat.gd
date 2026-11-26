class_name BattleCombat
extends RefCounted
## Movement, targeting and damage for a Battle. Static functions so Battle stays readable.

const Enemy = Entities.Enemy
const Tower = Entities.Tower

const SPLASH_SHARE := 0.6  ## Damage to enemies caught in a cannon blast, besides the target.
const CHAIN_SHARE := 0.6
const CHAIN_REACH := 34.0
const CONTACT_GAP := 1.0
const AIR_HOVER := 7.0  ## Flyers stop this far outside the Keep and bomb it.
const SHOT_ORIGIN_KEEP := Vector2(0.0, -10.0)
const BOUNCE_REACH := 40.0
const MAX_BOUNCES := 3
const ABSOLUTE_FLOOR := 0.1  ## absolute defense never blocks more than 90% of an attack
const PUSH_BOSS_SHARE := 0.25  ## bosses are pushed a quarter as far
const PUSH_COOLDOWN := 2.0  ## an enemy can be pushed at most once every 2 seconds


# --- Movement -------------------------------------------------------------------------------

static func move_enemies(b: Battle, dt: float) -> void:
	_heal(b, dt)
	for e in b.enemies:
		e.age += dt
		e.hit_flash = maxf(e.hit_flash - dt, 0.0)
		e.push_cd = maxf(e.push_cd - dt, 0.0)
		var stop_at: float
		var target := 0
		var segment := -1
		if e.air:
			stop_at = Defs.KEEP_RADIUS + AIR_HOVER + e.size * 0.5
		else:
			stop_at = Defs.KEEP_RADIUS + e.size * 0.5 + CONTACT_GAP
			for ring in range(b.rings_unlocked, 0, -1):
				var wall := b.walls[ring]
				var radius := b.wall_radius(ring)
				if e.dist < radius - 0.5:
					continue
				var seg := Battle.wall_segment(ring, e.angle)
				if wall.sections[seg] and wall.segments[seg] > 0.0:
					stop_at = radius + e.size * 0.5 + CONTACT_GAP
					target = ring
					segment = seg
					break
		if e.dist > stop_at + 0.01:
			e.dist = maxf(stop_at, e.dist - e.speed * b.enemy_speed_factor() * dt)
			e.attacking = -1
		else:
			e.attacking = target
			_attack(b, e, target, segment, dt)


## Shamans mend the raiders around them (not themselves).
static func _heal(b: Battle, dt: float) -> void:
	for s in b.enemies:
		if s.heal <= 0.0 or not s.alive():
			continue
		for e in b.enemies:
			if e != s and e.alive() and e.hp < e.max_hp and e.pos().distance_to(s.pos()) <= Defs.SHAMAN_REACH:
				e.hp = minf(e.hp + e.max_hp * s.heal * dt, e.max_hp)


## Spiked walls and Keep hand back a share of the damage an attacker deals.
static func _thorns(b: Battle, e: Enemy, damage: float, dt: float) -> void:
	var thorns := b.stat("thorns")
	if thorns <= 0.0 or not e.alive():
		return
	b._deal(e, damage * thorns, Defs.DamageType.PHYSICAL, 1.0, "Thorns")
	if b.rng.randf() < dt * 3.0:  # a few sparks a second, not every frame
		b._event({"type": "thorns", "pos": e.pos()})


static func _attack(b: Battle, e: Enemy, ring: int, segment: int, dt: float) -> void:
	var damage := e.dps * dt
	if e.burst > 0.0:  # a sapper: one big blast, then he is gone (and pays nothing)
		damage = e.burst
		e.hp = 0.0
		e.cash = 0.0
		e.coins = 0.0
		b._event({"type": "blast", "at": e.pos(), "radius": 10.0})
	if ring == 0:
		# absolute defense blocks a flat amount per second, then armour takes its share
		var blocked := minf(b.stat("absolute") * dt, damage * (1.0 - ABSOLUTE_FLOOR)) if e.burst <= 0.0 else 0.0
		var taken := (damage - blocked) * (1.0 - b.keep_armor())
		b.keep_hp -= taken
		b.killed_by = e.kind
		_thorns(b, e, damage, dt)
		return
	var wall := b.walls[ring]
	wall.segments[segment] = maxf(wall.segments[segment] - damage, 0.0)
	_thorns(b, e, damage, dt)
	if wall.segments[segment] <= 0.0:
		b._event({"type": "wall_broken", "ring": ring, "segment": segment})


# --- Shooting -------------------------------------------------------------------------------

static func fire(b: Battle, dt: float) -> void:
	_fire_keep(b, dt)
	for slot in b.slots:
		if slot.tower != null and slot.ring <= b.rings_unlocked:
			_fire_tower(b, slot, dt)


static func _fire_keep(b: Battle, dt: float) -> void:
	b.keep_fired += dt
	b.keep_cooldown -= dt
	if b.keep_cooldown > 0.0:
		return
	var target := find_target(b, Vector2.ZERO, b.keep_range(), Defs.Target.BOTH, "near")
	if target == null:
		b.keep_cooldown = 0.0
		return
	b.keep_cooldown += 1.0 / b.keep_rate()
	b.keep_fired = 0.0
	var targets: Array = [target]
	if b.rng.randf() < b.multishot_chance():
		targets.append_array(_others(b, target, Vector2.ZERO, b.keep_range(), b.multishot_targets()))
	for t in targets:
		_shoot(b, t, b.keep_damage(), Defs.DamageType.PHYSICAL, 0.0, "Keep")
		b._event({"type": "shot", "weapon": "keep", "from": SHOT_ORIGIN_KEEP, "to": t.pos()})


static func _fire_tower(b: Battle, s: Entities.Slot, dt: float) -> void:
	var tower := s.tower
	var from := s.pos
	tower.fired += dt
	tower.cooldown -= dt
	if tower.cooldown > 0.0:
		return
	var def: Dictionary = Defs.WEAPONS[tower.weapon]
	var focus: String = tower.focus if tower.focus != "" else def["focus"]
	var target := find_target(b, from, b.tower_range(tower), def["target"], focus)
	if target == null:
		tower.cooldown = 0.0
		return
	tower.cooldown += 1.0 / b.tower_rate(tower)
	tower.fired = 0.0
	var damage := b.slot_damage(s)
	var to := target.pos()
	_shoot(b, target, damage, def["type"], def["pierce"], def["short"])
	b._event({"type": "shot", "weapon": tower.weapon, "from": from, "to": to, "slot": s.index})
	if def["splash"] > 0.0:
		_splash(b, target, to, def, damage * SPLASH_SHARE)
	if def["chain"] > 0:
		_chain(b, target, def, damage * CHAIN_SHARE)


## One shot landing: critical hits, pushback, then maybe bouncing on to other enemies.
static func _shoot(b: Battle, target: Enemy, damage: float, type: int, pierce: float, source: String) -> void:
	var current := target
	var hit_ids := {}
	for bounce in MAX_BOUNCES + 1:
		var amount := damage
		if b.rng.randf() < b.crit_chance():
			amount *= b.stat("crit_factor")
			b._event({"type": "crit", "pos": current.pos(), "amount": amount})
		b._deal(current, amount, type, pierce, source)
		if current.push_cd <= 0.0 and not current.air and b.rng.randf() < b.push_chance():
			current.push_cd = PUSH_COOLDOWN
			var push := b.stat("push_dist") * (PUSH_BOSS_SHARE if current.boss else 1.0)
			current.dist += push
			current.attacking = -1
		hit_ids[current.id] = true
		if bounce == MAX_BOUNCES or b.rng.randf() >= b.bounce_chance():
			return
		var next := _nearest(b, current.pos(), BOUNCE_REACH, hit_ids)
		if next == null:
			return
		b._event({"type": "chain", "from": current.pos(), "to": next.pos(), "bounce": true})
		current = next


static func _nearest(b: Battle, at: Vector2, reach: float, skip: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	for e in b.enemies:
		if skip.has(e.id) or not e.alive():
			continue
		var d := e.pos().distance_to(at)
		if d <= best_d:
			best_d = d
			best = e
	return best


## Up to `count` more enemies in reach besides `first` (for multishot).
static func _others(b: Battle, first: Enemy, from: Vector2, reach: float, count: int) -> Array:
	var out: Array = []
	for e in b.enemies:
		if out.size() >= count:
			break
		if e != first and e.alive() and e.pos().distance_to(from) <= reach:
			out.append(e)
	return out


static func _splash(b: Battle, center_enemy: Enemy, at: Vector2, def: Dictionary, damage: float) -> void:
	for e in b.enemies:
		if e == center_enemy or e.air or not e.alive():
			continue
		if e.pos().distance_to(at) <= def["splash"]:
			b._deal(e, damage, def["type"], def["pierce"], def["short"])
	b._event({"type": "blast", "at": at, "radius": def["splash"]})


static func _chain(b: Battle, first: Enemy, def: Dictionary, damage: float) -> void:
	var hit_ids := {first.id: true}
	var current := first
	for i in int(def["chain"]):
		var best: Enemy = null
		var best_d := CHAIN_REACH
		for e in b.enemies:
			if hit_ids.has(e.id) or not e.alive():
				continue
			var d := e.pos().distance_to(current.pos())
			if d <= best_d:
				best_d = d
				best = e
		if best == null:
			return
		hit_ids[best.id] = true
		b._deal(best, damage, def["type"], def["pierce"], def["short"])
		b._event({"type": "chain", "from": current.pos(), "to": best.pos()})
		current = best


static func find_target(b: Battle, from: Vector2, reach: float, kind: int, focus: String) -> Enemy:
	var best: Enemy = null
	var best_score := INF
	var reach_sq := reach * reach
	for e in b.enemies:
		if not e.alive() or (kind == Defs.Target.GROUND and e.air) or (kind == Defs.Target.AIR and not e.air):
			continue
		if e.pos().distance_squared_to(from) > reach_sq:
			continue
		var score: float
		match focus:
			"strong": score = -e.hp
			"close": score = e.pos().distance_squared_to(from)
			"air": score = e.dist - (10000.0 if e.air else 0.0)
			_: score = e.dist  # "near" / "first": the enemy closest to the Keep
		if score < best_score:
			best_score = score
			best = e
	return best


## Applies damage after armour (physical) or ward (magic). Returns the damage dealt.
static func hit(e: Enemy, amount: float, type: int, pierce: float) -> float:
	var mult := 1.0 - e.armor * (1.0 - pierce) if type == Defs.DamageType.PHYSICAL else 1.0 - e.ward
	var dealt := minf(amount * mult, maxf(e.hp, 0.0))  # overkill does not count
	e.hp -= amount * mult
	e.hit_flash = 0.08
	return dealt
