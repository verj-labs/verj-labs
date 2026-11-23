extends TestCase
## Whole runs played by the AutoPlayer. These guard the shape of the progression curve:
## a new player survives a few minutes, research pushes runs much further, and harder tiers
## are harder. Numbers are loose on purpose; tools/balance.gd prints the details.

const MID := {"keep_damage": 10, "keep_health": 10, "keep_regen": 5, "start_cash": 6, "cash_bonus": 6, "coin_bonus": 5,
	"musket": 4, "cannon": 4, "volley": 3, "ring_2": 1, "masonry": 5}


func test_a_fresh_run_lasts_a_few_waves_and_then_falls() -> void:
	var b := AutoPlayer.play({}, 1, 11, 60)
	check(b.wave >= 8, "fresh run reached wave %d, expected at least 8" % b.wave)
	check(b.over and b.wave < 30, "fresh run should fall before wave 30 (reached %d)" % b.wave)
	check(b.coins_earned >= 60.0, "a first run pays for a few cheap researches (%d coins)" % int(b.coins_earned))


func test_research_pushes_runs_further() -> void:
	var fresh := AutoPlayer.play({}, 1, 11, 60)
	var mid := AutoPlayer.play(MID, 1, 11, 120)
	check(mid.wave >= fresh.wave + 15, "research should add 15+ waves (fresh %d, mid %d)" % [fresh.wave, mid.wave])
	check(mid.coins_earned > fresh.coins_earned * 5.0, "and pay far more coins")


func test_higher_tiers_are_harder() -> void:
	var t1 := AutoPlayer.play(MID, 1, 11, 120)
	var t2 := AutoPlayer.play(MID, 2, 11, 120)
	check(t2.wave < t1.wave, "tier 2 (%d) should end sooner than tier 1 (%d)" % [t2.wave, t1.wave])
