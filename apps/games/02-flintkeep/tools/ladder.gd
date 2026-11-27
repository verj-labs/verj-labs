extends SceneTree
## Workshop ladder: how far a run gets as workshop levels rise (with light research). The point
## of progression is that each step adds a steady number of waves; a big jump between two steps
## is a "cliff" (see docs/BALANCE.md).
##
##   godot --headless --path godot -s ../tools/ladder.gd -- [levels=0,3,5,10,20,30] [seeds=3]

const BalanceTool := preload("res://../tools/balance.gd")


func _initialize() -> void:
	var opts := {"levels": "0,3,5,10,20,30", "seeds": "3", "cap": "1000", "seconds": "60"}
	for arg in OS.get_cmdline_user_args():
		if arg.contains("="):
			opts[arg.get_slice("=", 0)] = arg.get_slice("=", 1)
	var research := {"cannon": 2, "musket": 2}
	for text in opts["levels"].split(","):
		var n := int(text)
		var workshop := {"damage": n, "health": n, "regen": n / 2, "towers": n / 2, "cash": n / 2}
		var waves: Array[String] = []
		for seed_value in BalanceTool.SEEDS.slice(0, int(opts["seeds"])):
			var b: Battle = BalanceTool.run(research, workshop, seed_value, 1, "", int(opts["cap"]), float(opts["seconds"]))
			waves.append(str(b.wave) + ("+" if not b.over and b.wave < int(opts["cap"]) else ""))
		print("workshop %2d: %s" % [n, str(waves)])
	quit()
