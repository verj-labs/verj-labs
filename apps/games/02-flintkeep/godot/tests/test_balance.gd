extends TestCase
## Whole runs played by the AutoPlayer. These guard the shape of the progression curve: a new
## player falls within a few minutes, research and the workshop push runs much further, and
## harder tiers end sooner. tools/balance.gd prints the details.

const EARLY := [{"cannon": 1, "musket": 2}, {"damage": 5, "health": 5, "regen": 3}]
const MID := [{"cannon": 6, "volley": 4, "musket": 6, "ring_2": 1, "siege": 6},
	{"damage": 20, "health": 20, "regen": 12, "rate": 10, "crit": 10, "towers": 15, "cash": 15, "masonry": 10}]


func test_a_fresh_run_falls_within_a_few_minutes() -> void:
	var b := AutoPlayer.play({}, 1, 11, 120, {}, 0.1)
	check(b.wave >= 10, "fresh run reached wave %d, expected at least 10" % b.wave)
	check(b.over and b.wave < 60, "fresh run should fall before wave 60 (reached %d)" % b.wave)


func test_upgrades_push_runs_much_further() -> void:
	var fresh := AutoPlayer.play({}, 1, 11, 120, {}, 0.1)
	var mid := AutoPlayer.play(MID[0], 1, 11, 150, MID[1], 0.1)
	check(mid.wave >= fresh.wave * 3, "workshop + research should multiply the waves reached (fresh %d, mid %d)" % [fresh.wave, mid.wave])


func test_higher_tiers_are_harder() -> void:
	var t1 := AutoPlayer.play(EARLY[0], 1, 11, 150, EARLY[1], 0.1)
	var t3 := AutoPlayer.play(EARLY[0], 3, 11, 150, EARLY[1], 0.1)
	check(t3.wave < t1.wave, "tier 3 (%d) should end sooner than tier 1 (%d)" % [t3.wave, t1.wave])
