extends SceneTree
## Prints how far the AutoPlayer gets with different research, to tune Defs/Research numbers.
##   godot --headless --path godot -s ../tools/balance.gd

func _initialize() -> void:
	var setups := {
		"fresh": {},
		"early": {"keep_damage": 3, "keep_health": 3, "start_cash": 2, "cash_bonus": 2, "musket": 1, "cannon": 1},
		"mid": {"keep_damage": 10, "keep_health": 10, "keep_regen": 5, "start_cash": 6, "cash_bonus": 6, "coin_bonus": 5, "musket": 4, "cannon": 4, "volley": 3, "ring_2": 1, "masonry": 5},
	}
	for name in setups:
		for tier in [1, 2]:
			var waves := []
			var coins := []
			var start := Time.get_ticks_msec()
			for seed_value in [11, 22, 33]:
				var b := AutoPlayer.play(setups[name], tier, seed_value, 120)
				waves.append(b.wave)
				coins.append(int(b.coins_earned))
			print("%-6s tier %d  waves %s  coins %s  (%d ms)" % [name, tier, str(waves), str(coins), Time.get_ticks_msec() - start])
	quit()
