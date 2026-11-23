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


# --- Movement -------------------------------------------------------------------------------

static func move_enemies(b: Battle, dt: float) -> void:
	_heal(b, dt)
	for e in b.enemies:
		e.age += dt
		e.hit_flash = maxf(e.hit_flash - dt, 0.0)
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
			e.dist = maxf(stop_at, e.dist - e.speed * dt)
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


static func _attack(b: Battle, e: Enemy, ring: int, segment: int, dt: float) -> void:
	var damage := e.dps * dt
	if e.burst > 0.0:  # a sapper: one big blast, then he is gone (and pays nothing)
		damage = e.burst
		e.hp = 0.0
		e.cash = 0.0
		e.coins = 0.0
		b._event({"type": "blast", "at": e.pos(), "radius": 10.0})
	if ring == 0:
		b.keep_hp -= damage * (1.0 - b.keep_armor())
		return
	var wall := b.walls[ring]
	wall.segments[segment] = maxf(wall.segments[segment] - damage, 0.0)
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
	hit(target, b.keep_damage(), Defs.DamageType.PHYSICAL, 0.0)
	b._event({"type": "shot", "weapon": "keep", "from": SHOT_ORIGIN_KEEP, "to": target.pos()})


static func _fire_tower(b: Battle, s: Entities.Slot, dt: float) -> void:
	var tower := s.tower
	var from := s.pos
	tower.fired += dt
	tower.cooldown -= dt
	if tower.cooldown > 0.0:
		return
	var def: Dictionary = Defs.WEAPONS[tower.weapon]
	var target := find_target(b, from, b.tower_range(tower), def["target"], def["focus"])
	if target == null:
		tower.cooldown = 0.0
		return
	tower.cooldown += 1.0 / b.tower_rate(tower)
	tower.fired = 0.0
	var damage := b.slot_damage(s)
	var to := target.pos()
	hit(target, damage, def["type"], def["pierce"])
	b._event({"type": "shot", "weapon": tower.weapon, "from": from, "to": to, "slot": s.index})
	if def["splash"] > 0.0:
		_splash(b, target, to, def, damage * SPLASH_SHARE)
	if def["chain"] > 0:
		_chain(b, target, def, damage * CHAIN_SHARE)


static func _splash(b: Battle, center_enemy: Enemy, at: Vector2, def: Dictionary, damage: float) -> void:
	for e in b.enemies:
		if e == center_enemy or e.air or not e.alive():
			continue
		if e.pos().distance_to(at) <= def["splash"]:
			hit(e, damage, def["type"], def["pierce"])
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
		hit(best, damage, def["type"], def["pierce"])
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
		var score := e.dist if focus == "near" else -e.hp
		if score < best_score:
			best_score = score
			best = e
	return best


## Applies damage after armour (physical) or ward (magic). Returns the damage dealt.
static func hit(e: Enemy, amount: float, type: int, pierce: float) -> float:
	var mult := 1.0 - e.armor * (1.0 - pierce) if type == Defs.DamageType.PHYSICAL else 1.0 - e.ward
	var dealt := amount * mult
	e.hp -= dealt
	e.hit_flash = 0.08
	return dealt
