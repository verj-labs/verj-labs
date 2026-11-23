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

	func pos() -> Vector2:
		return Vector2(cos(angle), sin(angle)) * dist

	func alive() -> bool:
		return hp > 0.0


class Tower:
	var weapon: String
	var level: int
	var cooldown: float = 0.0
	var invested: float = 0.0  ## Cash spent on it, for the sell refund.
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

	## True when at least one section stands.
	var built: bool:
		get:
			return sections.has(true)

	## Every section built: the ring is fortified.
	func complete() -> bool:
		return not sections.is_empty() and not sections.has(false)

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
