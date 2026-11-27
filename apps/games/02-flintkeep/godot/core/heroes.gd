class_name Heroes
extends RefCounted
## Heroes: one stands by the Keep for a whole run. Each is unlocked by beating the wave of a
## champion for the first time (in any tier), so long runs have rewards ahead as well as new
## threats. A hero has a passive bonus and an ability with a cooldown, cast like a power (or set
## to cast itself). Picked on the menu before a run.

const ORDER := ["captain", "engineer", "archmage"]
const LIST := {
	"captain": {"name": "Captain", "champion": "warlord", "ability": "Rally",
		"passive": "Towers deal +10% damage", "about": "Towers fire 60% faster for 10 s", "cooldown": 60.0},
	"engineer": {"name": "Engineer", "champion": "golem", "ability": "Rebuild",
		"passive": "Walls mend 1% a second faster", "about": "Every wall back to full health, broken sections too", "cooldown": 90.0},
	"archmage": {"name": "Archmage", "champion": "dragon", "ability": "Meteor",
		"passive": "Keep shots arc to a second raider", "about": "A meteor hits the toughest raider for 30x Keep damage", "cooldown": 50.0},
}

const CAPTAIN_DAMAGE := 1.1
const RALLY_RATE := 1.6
const RALLY_SECONDS := 10.0
const ENGINEER_REGEN := 0.01
const ARC_SHARE := 0.5  ## the Archmage's arc: half the Keep's damage to one more raider ...
const ARC_REACH := 40.0  ## ... this close to the first
const METEOR_MULT := 30.0
const METEOR_SPLASH := 0.3  ## raiders near the meteor take this share
const METEOR_RADIUS := 22.0


## The wave whose champion must be beaten (survived) to unlock `id`.
static func unlock_wave(id: String) -> int:
	return int(Defs.ENEMY_ROSTER[LIST[id]["champion"]]["wave"])
