extends SceneTree
## Prints how far the AutoPlayer gets with different research and workshop levels, to tune the
## numbers in core/upgrades.gd, defs.gd, workshop.gd and research.gd.
##   godot --headless --path godot -s ../tools/balance.gd -- [max wave]

const SETUPS := {
	"fresh": [{}, {}],
	"early": [{"cannon": 1, "musket": 2}, {"damage": 5, "health": 5, "regen": 3}],
	"mid": [{"cannon": 6, "volley": 4, "musket": 6, "ring_2": 1, "siege": 6, "power_rain": 3, "game_speed": 2},
		{"damage": 20, "health": 20, "regen": 12, "rate": 10, "crit": 10, "towers": 15, "cash": 15, "masonry": 10}],
	"late": [{"cannon": 15, "volley": 12, "musket": 15, "sniper": 10, "arcane": 8, "ring_2": 1, "ring_3": 1, "ring_4": 1,
		"siege": 18, "power_rain": 10, "power_thunder": 8, "power_freeze": 8, "power_gold": 8, "game_speed": 4},
		{"damage": 60, "health": 60, "regen": 40, "rate": 40, "crit": 30, "towers": 50, "cash": 45, "masonry": 40, "start_cash": 30}],
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cap := int(args[0]) if args.size() > 0 else 600
	for name in (args.slice(1) if args.size() > 1 else SETUPS.keys()):
		var start := Time.get_ticks_msec()
		var waves := []
		var coins := []
		for seed_value in [11, 22, 33, 44]:
			var b := AutoPlayer.play(SETUPS[name][0], 1, seed_value, cap, SETUPS[name][1], 0.25)
			waves.append(b.wave)
			coins.append(int(b.coins_earned))
		print("%-6s waves %s  coins %s  (%d ms)" % [name, str(waves), str(coins), Time.get_ticks_msec() - start])
	quit()
