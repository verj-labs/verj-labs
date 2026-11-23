class_name BattleWaves
extends RefCounted
## What each wave sends, when, and from where. Enemies come in loose groups from a few
## directions, so the player has to defend every side but can still see where the pressure is.

const GROUP_SIZE := 4
const GROUP_SPREAD := 0.28  ## Radians either side of the group's direction.
const JITTER := 0.35  ## Seconds of randomness in spawn timing.


## Returns [[seconds into the wave, kind, angle], ...] sorted by time.
static func plan(wave: int, rng: RandomNumberGenerator) -> Array:
	var count := Defs.wave_size(wave)
	var out: Array = []
	var group_angle := rng.randf() * TAU
	for i in count:
		if i % GROUP_SIZE == 0:
			group_angle = rng.randf() * TAU
		var at := Defs.SPAWN_SECONDS * i / count + rng.randf() * JITTER
		var angle := group_angle + rng.randf_range(-GROUP_SPREAD, GROUP_SPREAD)
		out.append([at, pick_kind(wave, rng), angle])
	if wave % Defs.BOSS_EVERY == 0:
		out.append([Defs.SPAWN_SECONDS * 0.5, "juggernaut", rng.randf() * TAU])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out


static func pick_kind(wave: int, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for kind in Defs.ENEMY_WAVES:
		if wave >= Defs.ENEMY_WAVES[kind][0]:
			total += Defs.ENEMY_WAVES[kind][1]
	var roll := rng.randf() * total
	for kind in Defs.ENEMY_WAVES:
		if wave < Defs.ENEMY_WAVES[kind][0]:
			continue
		roll -= Defs.ENEMY_WAVES[kind][1]
		if roll <= 0.0:
			return kind
	return "footman"
