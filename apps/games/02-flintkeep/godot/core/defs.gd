class_name Defs
extends RefCounted
## Game data for a run: the fortress layout, weapons, enemies and the cash upgrades.
## Distances are in battlefield pixels (the field is drawn at half resolution, so 1 px = 2 layout
## units). Change numbers here to rebalance; tests/test_balance.gd shows the effect.

# --- Fortress layout -------------------------------------------------------------------------

## Radius of each ring. Index 0 is the Keep itself.
const RING_RADII := [0.0, 32.0, 54.0, 75.0, 96.0]
## Build slots per ring (index 0 = the Keep). See docs/GAME_DESIGN.md for why it grows.
const SLOT_COUNTS := [0, 4, 6, 8, 12]
## Towers stand on their ring's wall; the wall sections are the arcs between them.
const WALL_OFFSET := 0.0
const MAX_RING := 4
const KEEP_RADIUS := 11.0

# --- Waves -----------------------------------------------------------------------------------

const WAVE_SECONDS := 24.0  ## A new wave starts every 24 s whether or not the last one is dead.
const SPAWN_SECONDS := 16.0  ## Each wave's enemies arrive over the first 16 s.
const BOSS_EVERY := 10
const SHAMAN_REACH := 26.0
const HP_GROWTH := 1.115  ## Enemy health multiplier per wave.
const DPS_GROWTH := 1.07
const CASH_GROWTH := 1.075
const COIN_GROWTH := 0.03  ## Coins per kill grow linearly: +3% of base per wave.
const WAVE_COINS := 1.0  ## Coins for each wave started, times the wave number.

# --- Tiers ("Level 1, 2, ..." on the menu) -----------------------------------------------------

const MAX_TIER := 10
const TIER_UNLOCK_WAVE := 25  ## Reaching this wave unlocks the next tier.


static func tier_enemy_mult(tier: int) -> float:
	return pow(2.2, tier - 1)


static func tier_coin_mult(tier: int) -> float:
	return 1.0 + 0.75 * (tier - 1)


# --- Weapons (built in ring slots with cash) ---------------------------------------------------

enum Target { GROUND, AIR, BOTH }
enum DamageType { PHYSICAL, MAGIC }

## cost: build price. dmg: damage per shot at level 1. rate: shots per second. range: px.
## splash: radius of area damage. chain: extra targets hit. pierce: share of armour ignored.
## focus: "near" shoots the enemy closest to the Keep, "strong" the one with the most health.
const WEAPONS := {
	"musket": {
		"name": "Musket Tower", "short": "Musket Tower", "cost": 25.0, "dmg": 5.0, "rate": 1.6, "range": 54.0,
		"target": Target.BOTH, "type": DamageType.PHYSICAL, "splash": 0.0, "chain": 0, "pierce": 0.0,
		"focus": "near", "about": "Hits ground and air. Cheap and steady.",
	},
	"cannon": {
		"name": "Cannon Battery", "short": "Cannon Battery", "cost": 60.0, "dmg": 16.0, "rate": 0.5, "range": 62.0,
		"target": Target.GROUND, "type": DamageType.PHYSICAL, "splash": 16.0, "chain": 0, "pierce": 0.0,
		"focus": "near", "about": "Ground only. Splash damage.",
	},
	"volley": {
		"name": "Volley Gun", "short": "Volley Gun", "cost": 50.0, "dmg": 4.5, "rate": 3.2, "range": 60.0,
		"target": Target.AIR, "type": DamageType.PHYSICAL, "splash": 0.0, "chain": 0, "pierce": 0.0,
		"focus": "near", "about": "Air only. Shreds flyers.",
	},
	"sniper": {
		"name": "Rifle Nest", "short": "Rifle Nest", "cost": 90.0, "dmg": 38.0, "rate": 0.35, "range": 120.0,
		"target": Target.BOTH, "type": DamageType.PHYSICAL, "splash": 0.0, "chain": 0, "pierce": 0.6,
		"focus": "strong", "about": "Long range. Picks off the biggest.",
	},
	"arcane": {
		"name": "Arcane Spire", "short": "Arcane Spire", "cost": 120.0, "dmg": 9.0, "rate": 1.0, "range": 64.0,
		"target": Target.BOTH, "type": DamageType.MAGIC, "splash": 0.0, "chain": 2, "pierce": 0.0,
		"focus": "near", "about": "Magic: ignores armour, chains.",
	},
}
const WEAPON_ORDER := ["musket", "cannon", "volley", "sniper", "arcane"]
const WEAPON_DMG_GROWTH := 1.32  ## Damage multiplier per tower level.
const WEAPON_RATE_GROWTH := 0.04  ## +4% fire rate per tower level.
const WEAPON_RANGE_GROWTH := 1.5  ## +1.5 px range per tower level.
const WEAPON_COST_GROWTH := 1.5  ## Upgrade price multiplier per level.
const WEAPON_UPGRADE_BASE := 0.8  ## First upgrade costs 80% of the build price.
const SELL_REFUND := 0.5

# --- Enemies ----------------------------------------------------------------------------------

## hp, dps (damage per second to walls/Keep), speed (px/s), armour (share of physical damage
## blocked), ward (share of magic damage blocked), cash and coins per kill at wave 1.
## Sappers have no dps: they blow up against the first wall (or the Keep) for `burst` damage.
## Shamans heal raiders near them by `heal` of their max health per second.
const ENEMIES := {
	"footman": {"hp": 14.0, "dps": 3.0, "speed": 11.0, "armor": 0.0, "ward": 0.0, "air": false, "cash": 3.0, "coins": 0.5, "size": 4.0},
	"runner": {"hp": 8.0, "dps": 2.0, "speed": 19.0, "armor": 0.0, "ward": 0.0, "air": false, "cash": 2.0, "coins": 0.4, "size": 3.5},
	"brute": {"hp": 46.0, "dps": 8.0, "speed": 7.0, "armor": 0.5, "ward": 0.0, "air": false, "cash": 5.0, "coins": 1.2, "size": 6.0},
	"balloon": {"hp": 22.0, "dps": 5.0, "speed": 8.0, "armor": 0.0, "ward": 0.0, "air": true, "cash": 4.0, "coins": 1.0, "size": 6.0},
	"wyvern": {"hp": 20.0, "dps": 5.0, "speed": 16.0, "armor": 0.0, "ward": 0.5, "air": true, "cash": 4.0, "coins": 1.0, "size": 6.0},
	"sapper": {"hp": 16.0, "dps": 0.0, "speed": 15.0, "armor": 0.0, "ward": 0.0, "air": false, "cash": 3.0, "coins": 0.6, "size": 4.0, "burst": 45.0},
	"shaman": {"hp": 30.0, "dps": 2.0, "speed": 8.0, "armor": 0.0, "ward": 0.3, "air": false, "cash": 6.0, "coins": 1.5, "size": 4.5, "heal": 0.04},
	"juggernaut": {"hp": 300.0, "dps": 12.0, "speed": 4.5, "armor": 0.35, "ward": 0.2, "air": false, "cash": 60.0, "coins": 15.0, "size": 9.0},
}
## [first wave it appears, spawn weight]
const ENEMY_WAVES := {
	"footman": [1, 1.0], "runner": [3, 0.5], "balloon": [5, 0.3], "brute": [6, 0.35], "sapper": [8, 0.2],
	"wyvern": [12, 0.25], "shaman": [15, 0.12],
}


static func wave_size(wave: int) -> int:
	return mini(6 + int(wave * 1.2), 70)


# --- The Keep ----------------------------------------------------------------------------------

## regen is a share of max health per second (0.005 = 0.5%/s).
const KEEP := {"hp": 100.0, "regen": 0.005, "dmg": 6.0, "rate": 1.2, "range": 58.0}

# --- Cash upgrades bought during a run --------------------------------------------------------
## base: first price, growth: price multiplier per level, step: effect per level, max: level cap
## (0 = no cap). How each step applies is in Battle (keep_stat / bounty_mult ...).

const KEEP_UPGRADES := {
	"damage": {"name": "Damage", "base": 8.0, "growth": 1.32, "step": 0.22, "max": 0},
	"rate": {"name": "Fire rate", "base": 10.0, "growth": 1.4, "step": 0.08, "max": 30},
	"range": {"name": "Range", "base": 12.0, "growth": 1.55, "step": 3.0, "max": 12},
	"health": {"name": "Health", "base": 8.0, "growth": 1.3, "step": 0.2, "max": 0},
	"regen": {"name": "Regeneration", "base": 10.0, "growth": 1.35, "step": 0.25, "max": 0},
	"armor": {"name": "Armour", "base": 15.0, "growth": 1.45, "step": 0.03, "max": 20},
}
const KEEP_ORDER := ["damage", "rate", "range", "health", "regen", "armor"]

const ECON_UPGRADES := {
	"bounty": {"name": "Cash bounty", "base": 15.0, "growth": 1.4, "step": 0.1, "max": 0},
	"coin_bounty": {"name": "Coin bounty", "base": 20.0, "growth": 1.45, "step": 0.08, "max": 0},
	"interest": {"name": "Interest", "base": 25.0, "growth": 1.5, "step": 0.01, "max": 10},
}
const ECON_ORDER := ["bounty", "coin_bounty", "interest"]
const INTEREST_CAP_PER_WAVE := 15.0  ## Interest pays at most this times the wave number.

# --- Walls -------------------------------------------------------------------------------------

const WALL_BUILD_BASE := 30.0  ## A whole ring 1 wall; one section costs a share of this.
const WALL_SECTION_SHARE := 0.3  ## Ring 1 has 4 sections: each costs 30% (a full ring 120%).
const FORTIFIED_HP := 1.5  ## A ring with every section built has 50% tougher walls ...
const FORTIFIED_DAMAGE := 0.15  ## ... and its towers deal 15% more damage.
const WALL_RING_GROWTH := 1.8  ## Each ring further out costs this much more.
const WALL_HP := 60.0  ## Per segment, ring 1, level 1.
const WALL_HP_RING_GROWTH := 1.25
const WALL_HP_GROWTH := 1.35  ## Per reinforce level.
const WALL_REINFORCE_GROWTH := 1.45
const WALL_REPAIR_SHARE := 0.5  ## Repairing every segment from zero costs half a reinforce.


static func upgrade_cost(def: Dictionary, level: int, discount: float = 0.0) -> float:
	return def["base"] * pow(def["growth"], level) * (1.0 - discount)


static func ring_angle_offset(ring: int) -> float:
	## Ring 1 sits on the compass points (N, E, S, W); the others are turned half a slot so their
	## towers fill the gaps of the ring inside.
	var count: int = SLOT_COUNTS[ring]
	return -PI / 2.0 + (0.0 if ring == 1 else PI / count)
