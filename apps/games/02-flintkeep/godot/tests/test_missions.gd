extends TestCase
## Daily missions.


func test_same_day_gives_the_same_missions() -> void:
	var a := Missions.generate("2026-11-23", 12)
	var b := Missions.generate("2026-11-23", 12)
	eq(a.size(), Missions.PER_DAY)
	eq(a, b, "stable for the day")
	var kinds := {}
	for m in a:
		kinds[m["kind"]] = true
	eq(kinds.size(), Missions.PER_DAY, "no duplicate kinds")


func test_new_players_get_no_boss_mission() -> void:
	for d in 30:
		for m in Missions.generate("2026-12-%02d" % (d + 1), 4):
			check(m["kind"] != "boss", "no Juggernaut mission below wave 10")


func test_progress_counts_up_and_wave_keeps_the_best() -> void:
	var list := [{"kind": "kills", "target": 10, "progress": 0, "reward": 50, "claimed": false},
		{"kind": "wave", "target": 12, "progress": 0, "reward": 80, "claimed": false}]
	Missions.track(list, "kills", 4)
	Missions.track(list, "kills", 3)
	eq(list[0]["progress"], 7)
	Missions.track(list, "wave", 9)
	Missions.track(list, "wave", 5)
	eq(list[1]["progress"], 9, "the best wave counts, not the sum")
	check(not Missions.track(list, "build", 1), "unrelated events change nothing")


func test_claim_pays_once_and_only_when_done() -> void:
	var p := ProfileData.new()
	p.missions = [{"kind": "kills", "target": 5, "progress": 2, "reward": 50, "claimed": false}]
	check(not p.claim(0), "not done yet")
	p.missions[0]["progress"] = 5
	eq(p.claimable(), 1)
	check(p.claim(0), "claimed")
	near(p.coins, 50.0)
	check(not p.claim(0), "cannot claim twice")
	eq(p.claimable(), 0)


func test_missions_roll_over_each_day_and_survive_saving() -> void:
	var p := ProfileData.new()
	p.refresh_missions("2026-11-23")
	p.missions[0]["progress"] = 3
	p.refresh_missions("2026-11-23")
	eq(p.missions[0]["progress"], 3, "same day keeps progress")
	var copy := ProfileData.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	eq(copy.missions.size(), Missions.PER_DAY)
	eq(copy.missions[0]["progress"], 3)
	copy.refresh_missions("2026-11-24")
	eq(copy.mission_day, "2026-11-24")
	eq(copy.missions[0]["progress"], 0, "a new day starts fresh")
