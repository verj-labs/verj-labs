class_name Entities
extends RefCounted
## The things on the battlefield. Plain data; Battle moves them and decides who hits whom.


class Enemy:
	var id: int
	var kind: String
	var angle: float  ## Direction from the Keep (radians). Enemies march straight in.
	var dist: float  ## Distance from the centre of the Keep.
	var hp: float
	var max_hp: float
	var speed: float
	var dps: float
	var armor: float
	var ward: float
	var air: bool
	var boss: bool
	var cash: float
	var coins: float
	var size: float
	var attacking: int = -1  ## -1 marching, 0 the Keep, 1-4 the wall of that ring.
	var hit_flash: float = 0.0
	var age: float = 0.0
	var burst: float = 0.0  ## sappers: damage when they blow up
	var heal: float = 0.0  ## shamans: share of max health healed per second around them
	var push_cd: float = 0.0  ## seconds until this enemy can be pushed back again
	var aura: float = 0.0  ## Warlord: raiders near him move faster and take this much less damage
	var rallied: bool = false  ## within a Warlord's banner this step
	var wall_mult: float = 1.0  ## Siege Golem: damage against walls
	var standoff: float = 0.0  ## Dragon: hovers this much further out and attacks from range

	func pos() -> Vector2:
		return Vector2(cos(angle), sin(angle)) * dist

	func alive() -> bool:
		return hp > 0.0


class Tower:
	var weapon: String
	var level: int
	var start_level: int = 1  ## the level it was built at (upgrades are priced from here)
	var focus: String = ""  ## targeting mode: "" = the weapon's default, or "first", "strong", "close", "air"
	var cooldown: float = 0.0
	var invested: float = 0.0  ## Cash spent on it, for the sell refund.
	var addons: Dictionary = {}  ## add-on id -> true (see Defs.ADDONS)
	var fired: float = 0.0  ## Seconds since it last fired (for the recoil animation).


class Slot:
	var ring: int
	var index: int
	var angle: float
	var pos: Vector2
	var tower: Tower = null


class Wall:
	var ring: int
	var level: int = 0
	var max_hp: float = 0.0
	var sections: Array[bool] = []  ## which arcs between towers are built
	var segments: Array[float] = []  ## health of each section (0 when not built or broken)
	var addons: Dictionary = {}  ## wall add-on id -> true (see Defs.WALL_ADDONS)
	## Broken sections are rubble that raiders walk through. Wall regeneration rebuilds them, but
	## they only stand (and block) again once back to Defs.WALL_REBUILD_SHARE of their health.
	var broken: Array[bool] = []

	## True when at least one section stands.
	var built: bool:
		get:
			return sections.has(true)

	## Every section built: the ring is fortified.
	func complete() -> bool:
		return not sections.is_empty() and not sections.has(false)

	## True when section `i` stands and stops ground raiders.
	func stands(i: int) -> bool:
		return sections[i] and not broken[i] and segments[i] > 0.0

	func built_count() -> int:
		return sections.count(true)

	func missing_share() -> float:
		var n := built_count()
		if n == 0 or max_hp <= 0.0:
			return 0.0
		var missing := 0.0
		for i in sections.size():
			if sections[i]:
				missing += max_hp - segments[i]
		return missing / (max_hp * n)
