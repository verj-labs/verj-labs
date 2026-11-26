class_name Powers
extends RefCounted
## Special powers, unlocked and levelled in the labs. Each has a cooldown; the player can cast it
## or set it to cast itself. Level L >= 1.

const ORDER := ["rain", "freeze", "thunder", "gold"]
const LIST := {
	"rain": {"name": "Arrow Rain", "research": "power_rain", "about": "Hits every enemy on the field"},
	"freeze": {"name": "Freeze", "research": "power_freeze", "about": "Slows every enemy to a crawl"},
	"thunder": {"name": "Thunderstorm", "research": "power_thunder", "about": "Lightning strikes the toughest foes"},
	"gold": {"name": "Golden Hour", "research": "power_gold", "about": "Double cash for a while"},
}


static func cooldown(id: String, level: int) -> float:
	match id:
		"rain": return maxf(60.0 - 2.0 * level, 30.0)
		"freeze": return maxf(90.0 - 3.0 * level, 40.0)
		"thunder": return maxf(75.0 - 2.5 * level, 35.0)
		"gold": return maxf(120.0 - 3.0 * level, 60.0)
	return 60.0


## Damage as a multiple of the Keep's damage (rain, thunder), or seconds (freeze, gold).
static func power(id: String, level: int) -> float:
	match id:
		"rain": return 10.0 + 3.0 * level
		"thunder": return 25.0 + 6.0 * level
		"freeze": return 6.0 + 0.5 * level
		"gold": return 15.0 + 1.0 * level
	return 0.0


static func strikes(level: int) -> int:
	return 6 + level
