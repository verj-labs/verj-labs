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
	var built: bool = false
	var level: int = 0
	var max_hp: float = 0.0
	var segments: Array[float] = []  ## Health of each section, one per build slot of the ring.

	func missing_share() -> float:
		if not built or max_hp <= 0.0:
			return 0.0
		var missing := 0.0
		for hp in segments:
			missing += max_hp - hp
		return missing / (max_hp * segments.size())
