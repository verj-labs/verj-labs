class_name BattleWaves
extends RefCounted
## What each wave sends, when, and from where. Enemies come in loose groups from a few
## directions, so the player has to defend every side but can still see where the pressure is.

const GROUP_SIZE := 4
const GROUP_SPREAD := 0.28  ## Radians either side of the group's direction.
const JITTER := 0.35  ## Seconds of randomness in spawn timing.


## Returns [[seconds into the wave, kind, angle], ...] sorted by time.
static func plan(wave: int, rng: RandomNumberGenerator, tier: int = 1) -> Array:
	var count := Defs.wave_size(wave)
	var out: Array = []
	var group_angle := rng.randf() * TAU
	for i in count:
		if i % GROUP_SIZE == 0:
			group_angle = rng.randf() * TAU
		var at := Defs.SPAWN_SECONDS * i / count + rng.randf() * JITTER
		var angle := group_angle + rng.randf_range(-GROUP_SPREAD, GROUP_SPREAD)
		out.append([at, pick_kind(wave, rng, tier), angle])
	if wave % Defs.BOSS_EVERY == 0:
		out.append([Defs.SPAWN_SECONDS * 0.5, boss_for(wave), rng.randf() * TAU])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out


static func pick_kind(wave: int, rng: RandomNumberGenerator, tier: int = 1) -> String:
	var pool: Array[String] = []
	var total := 0.0
	for kind in Defs.ENEMY_ORDER:
		var arrives := Defs.enemy_arrives(kind, tier)
		var weight: float = Defs.ENEMY_ROSTER[kind]["weight"]
		if arrives >= 1 and wave >= arrives and weight > 0.0:
			pool.append(kind)
			total += weight
	var roll := rng.randf() * total
	for kind in pool:
		roll -= Defs.ENEMY_ROSTER[kind]["weight"]
		if roll <= 0.0:
			return kind
	return "footman"


## The kind that first raids on this wave in this tier ("" if none): the "New enemy" banner.
static func newcomer(wave: int, tier: int) -> String:
	for kind in Defs.ENEMY_ORDER:
		if kind != "juggernaut" and not kind in Defs.CHAMPIONS and Defs.enemy_arrives(kind, tier) == wave:
			return kind
	return ""


## The boss of a boss wave: a champion on its arrival wave, then on every 50th wave the champions
## that have arrived take turns; otherwise the Juggernaut.
static func boss_for(wave: int) -> String:
	var arrived: Array[String] = []
	for kind in Defs.CHAMPIONS:
		var at: int = Defs.ENEMY_ROSTER[kind]["wave"]
		if at == wave:
			return kind
		if at < wave:
			arrived.append(kind)
	if not arrived.is_empty() and wave % Defs.CHAMPION_RETURN == 0:
		return arrived[(wave / Defs.CHAMPION_RETURN) % arrived.size()]
	return "juggernaut"
