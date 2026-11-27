extends SceneTree
## Balance report: plays whole runs with the AutoPlayer for a few research/workshop profiles and
## prints the wave each run reached. See docs/BALANCE.md for how to read it and what to aim for.
##
##   godot --headless --path godot -s ../tools/balance.gd -- [profiles...] [cap=1000] [seeds=4]
##       [tier=1] [hero=captain] [seconds=60]
##
## Profiles: fresh, early, mid, late (all four if none are named). A run that hits the time limit
## is printed as "N+" (still alive at wave N): a run that never ends is a balance bug.

const PROFILES := {
	"fresh": [{}, {}],
	"early": [{"cannon": 1, "musket": 2}, {"damage": 5, "health": 5, "regen": 3}],
	"mid": [{"cannon": 6, "volley": 4, "musket": 6, "ring_2": 1, "siege": 6, "power_rain": 3, "game_speed": 2},
		{"damage": 20, "health": 20, "regen": 12, "rate": 10, "crit": 10, "towers": 15, "cash": 15, "masonry": 10}],
	"late": [{"cannon": 15, "volley": 12, "musket": 15, "sniper": 10, "arcane": 8, "ring_2": 1, "ring_3": 1, "ring_4": 1,
		"siege": 18, "power_rain": 10, "power_thunder": 8, "power_freeze": 8, "power_gold": 8, "game_speed": 4},
		{"damage": 60, "health": 60, "regen": 40, "rate": 40, "crit": 30, "towers": 50, "cash": 45, "masonry": 40, "start_cash": 30}],
}
const SEEDS := [11, 22, 33, 44, 55, 66, 77, 88]
const STEP := 0.25  ## simulation step (seconds); the game uses 1/30, this is close and much faster


func _initialize() -> void:
	var opts := {"cap": "1000", "seeds": "4", "tier": "1", "hero": "", "seconds": "60"}
	var names: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.contains("="):
			opts[arg.get_slice("=", 0)] = arg.get_slice("=", 1)
		elif PROFILES.has(arg):
			names.append(arg)
	if names.is_empty():
		names = PROFILES.keys()
	print("curve A=%s B=%s C=%s · tier %s · hero %s" % [Upgrades.SCALE_A, Upgrades.SCALE_B, Upgrades.SCALE_C, opts["tier"],
		opts["hero"] if opts["hero"] != "" else "none"])
	for name in names:
		var waves: Array[String] = []
		var coins: Array[int] = []
		for seed_value in SEEDS.slice(0, int(opts["seeds"])):
			var b := run(PROFILES[name][0], PROFILES[name][1], seed_value, int(opts["tier"]), opts["hero"], int(opts["cap"]), float(opts["seconds"]))
			waves.append(str(b.wave) + ("+" if not b.over and b.wave < int(opts["cap"]) else ""))
			coins.append(int(b.coins_earned))
		print("%-6s waves %s  coins %s" % [name, str(waves), str(coins)])
	quit()


## One run as the AutoPlayer plays it, stopped at `cap` waves or after `seconds` of real time.
static func run(research: Dictionary, workshop: Dictionary, seed_value: int, tier: int, hero: String, cap: int, seconds: float) -> Battle:
	var b := Battle.new(research, tier, seed_value, workshop)
	b.record_events = false
	b.hero = hero
	b.hero_auto = hero != ""
	var since := 0.0
	var start := Time.get_ticks_msec()
	while not b.over and b.wave < cap and Time.get_ticks_msec() - start < seconds * 1000.0:
		b.step(STEP)
		since += STEP
		if since >= 0.5:
			since = 0.0
			AutoPlayer.think(b)
			if not b.perk_offer.is_empty():
				b.choose_perk(b.perk_offer[0])
			for id in Powers.ORDER:
				b.cast(id)
	return b
