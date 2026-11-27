extends TestCase
## Research, labs and saving.


func _rich() -> ProfileData:
	var p := ProfileData.new()
	p.coins = 100000.0
	return p


func test_research_costs_and_times_grow_with_level() -> void:
	check(Research.cost("coin_bonus", 3) > Research.cost("coin_bonus", 2), "cost grows")
	check(Research.seconds("coin_bonus", 3) > Research.seconds("coin_bonus", 2), "time grows")
	check(Research.seconds("coin_bonus", 59) <= Research.MAX_SECONDS, "time is capped")


func test_starting_research_takes_coins_and_a_lab() -> void:
	var p := ProfileData.new()
	p.coins = 100.0
	check(p.start("coin_bonus", 1000.0), "affordable research starts")
	near(p.coins, 40.0, 0.001, "price paid")
	eq(p.lab_of("coin_bonus"), 0)
	eq(p.level("coin_bonus"), 0, "level only rises when the lab finishes")


func test_cannot_start_without_coins() -> void:
	var p := ProfileData.new()
	p.coins = 5.0
	eq(p.blocker("coin_bonus"), "NEED COINS")
	check(not p.start("coin_bonus", 0.0), "refused")
	near(p.coins, 5.0)


func test_one_lab_to_start_and_more_bought_with_gems() -> void:
	var p := _rich()
	eq(p.labs.size(), 1, "a new player has one lab")
	check(p.start("coin_bonus", 0.0), "lab 1")
	eq(p.blocker("siege"), "LABS BUSY")
	eq(p.blocker("coin_bonus"), "IN LAB", "the same research cannot run twice")
	check(not p.buy_lab_slot(), "no gems, no slot")
	p.gems = 200
	check(p.buy_lab_slot(), "slot 2 for 150 gems")
	eq(p.gems, 50)
	eq(p.labs.size(), 2)
	check(p.start("siege", 0.0), "the second lab works")
	eq(p.next_slot_gems(), Research.LAB_SLOT_GEMS[1], "slot 3 costs more")


func test_research_finishes_when_time_is_up() -> void:
	var p := _rich()
	p.start("coin_bonus", 0.0)
	var seconds := Research.seconds("coin_bonus", 0)
	eq(p.finish_due(seconds - 1.0).size(), 0, "not yet")
	var done := p.finish_due(seconds)
	eq(done, ["coin_bonus"] as Array[String])
	eq(p.level("coin_bonus"), 1)
	eq(p.free_lab(), 0, "the lab is free again")


func test_rings_must_be_unlocked_in_order() -> void:
	var p := _rich()
	check(p.blocker("ring_3").begins_with("NEEDS"), "ring 3 needs ring 2")
	p.research["ring_2"] = 1
	eq(p.blocker("ring_3"), "")
	eq(p.blocker("ring_2"), "MAX", "a ring is a single unlock")


func test_best_wave_and_tier_unlock() -> void:
	var p := ProfileData.new()
	check(p.record_run(1, 12, 100), "first run is a record")
	check(not p.record_run(1, 10, 80), "a worse run is not")
	eq(p.best(1), 12)
	eq(p.unlocked_tier, 1)
	p.record_run(1, Defs.TIER_UNLOCK_WAVE, 300)
	eq(p.unlocked_tier, 2, "reaching the unlock wave opens the next tier")
	eq(p.total_kills, 480)


func test_save_round_trip() -> void:
	var p := _rich()
	p.research = {"coin_bonus": 4, "ring_2": 1}
	p.workshop = {"damage": 7}
	p.start("cannon", 500.0)
	p.record_run(2, 30, 10)
	var copy := ProfileData.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	eq(copy.level("coin_bonus"), 4)
	eq(copy.workshop_level("damage"), 7)
	eq(copy.level("ring_2"), 1)
	eq(copy.lab_of("cannon"), 0)
	eq(copy.best(2), 30)
	near(copy.coins, p.coins)


func test_load_ignores_unknown_and_broken_fields() -> void:
	var copy := ProfileData.from_dict({"coins": "12", "research": {"laser_beams": 3}, "labs": [{"id": "nope"}], "unlocked_tier": 99})
	near(copy.coins, 12.0)
	eq(copy.level("laser_beams"), 0)
	eq(copy.free_lab(), 0, "an unknown lab job is dropped")
	eq(copy.unlocked_tier, Defs.MAX_TIER)


func test_weapon_research_raises_start_level_and_discount() -> void:
	check(Research.weapon_unlocked("musket", 0), "musket is free")
	check(not Research.weapon_unlocked("cannon", 0), "cannon starts locked")
	eq(Research.weapon_start_level("cannon", 1), 1, "first level only unlocks")
	eq(Research.weapon_start_level("cannon", 3), 3)
	eq(Research.weapon_start_level("musket", 2), 3)
	near(Research.weapon_discount("cannon", 3), 2 * Research.WEAPON_DISCOUNT_STEP)


func test_offline_coins_need_time_away_and_are_capped() -> void:
	var p := ProfileData.new()
	eq(p.offline_coins(10000.0), 0.0, "first launch pays nothing")
	p.last_seen = 10000.0
	eq(p.offline_coins(10000.0 + 60.0), 0.0, "a minute away pays nothing")
	near(p.offline_coins(10000.0 + 3600.0), p.offline_rate(), 1.0, "an hour pays the hourly rate")
	near(p.offline_coins(10000.0 + 100 * 3600.0), p.offline_rate() * ProfileData.OFFLINE_MAX_HOURS, 1.0, "capped at 8 hours")
	var slow := p.offline_rate()
	p.best_wave["1"] = 30
	check(p.offline_rate() > slow, "better players earn more while away")



func test_old_stat_research_moves_to_the_workshop() -> void:
	var copy := ProfileData.from_dict({"research": {"keep_damage": 6, "masonry": 3, "cannon": 2}})
	eq(copy.workshop_level("damage"), 6, "keep damage research became workshop damage")
	eq(copy.workshop_level("masonry"), 3)
	eq(copy.level("cannon"), 2, "weapon research stays research")


func test_workshop_is_instant_and_expensive() -> void:
	var p := ProfileData.new()
	p.coins = 100.0
	check(not p.buy_workshop("damage"), "150 coins needed")
	p.coins = 1000.0
	check(p.buy_workshop("damage"), "bought")
	eq(p.workshop_level("damage"), 1)
	check(p.workshop_cost("damage") > Workshop.cost("damage", 0), "and the next costs more")



func test_old_saves_keep_both_labs() -> void:
	var copy := ProfileData.from_dict({"version": 2, "labs": [{"id": "", "ends": 0.0}, {"id": "", "ends": 0.0}]})
	eq(copy.labs.size(), 2, "players from before lab slots keep their two labs")
	var fresh := ProfileData.from_dict(ProfileData.new().to_dict())
	eq(fresh.labs.size(), 1)


func test_workshop_items_can_be_researched_for_less() -> void:
	var p := ProfileData.new()
	p.coins = 1000.0
	var full := Workshop.cost("damage", 0)
	check(p.start_workshop_research("damage", 0.0), "researching")
	near(p.coins, 1000.0 - Workshop.research_cost("damage", 0), 0.01, "40% of the price")
	check(Workshop.research_cost("damage", 0) < full, "cheaper than buying")
	check(not p.buy_workshop("damage"), "cannot also buy it while it is in the lab")
	p.finish_due(Workshop.seconds("damage", 0))
	eq(p.workshop_level("damage"), 1, "the level arrives when the lab finishes")


func test_finishing_early_costs_less_as_time_runs_down() -> void:
	var p := ProfileData.new()
	p.coins = 10000.0
	p.start_workshop_research("damage", 0.0)
	var secs := Workshop.seconds("damage", 0)
	var at_start := p.finish_coin_cost(0, 0.0)
	var halfway := p.finish_coin_cost(0, secs / 2.0)
	near(at_start, Workshop.cost("damage", 0) - Workshop.research_cost("damage", 0), 1.0, "right away: the rest of the price")
	check(halfway < at_start, "cheaper later")
	check(p.finish_with_coins(0, secs / 2.0), "finished with coins")
	eq(p.workshop_level("damage"), 1)
	p.start("coin_bonus", 0.0)
	eq(p.finish_coin_cost(0, 0.0), -1.0, "lab research only finishes early with gems")
	p.gems = 50
	var gems := p.finish_gem_cost(0, 0.0)
	check(p.finish_with_gems(0, 0.0), "finished with gems")
	eq(p.gems, 50 - gems)
	eq(p.level("coin_bonus"), 1)


func test_milestones_pay_gems_once() -> void:
	var p := ProfileData.new()
	eq(p.reach_wave(1, 49), 0)
	eq(p.reach_wave(1, 50), Research.MILESTONE_GEMS[0], "wave 50 pays")
	eq(p.reach_wave(1, 60), 0, "only once")
	eq(p.reach_wave(2, 120), Research.MILESTONE_GEMS[0] + Research.MILESTONE_GEMS[1], "each tier has its own")
	eq(p.gems, Research.MILESTONE_GEMS[0] * 2 + Research.MILESTONE_GEMS[1])


func test_missions_pay_a_few_gems() -> void:
	var p := ProfileData.new()
	p.missions = [{"kind": "kills", "target": 1, "progress": 1, "reward": 10, "gems": 3, "claimed": false}]
	check(p.claim(0), "claimed")
	eq(p.gems, 3)


func test_bestiary_learns_enemies_from_runs_and_best_waves() -> void:
	var p := ProfileData.new()
	check(p.enemy_seen("footman"), "everyone has met raiders")
	check(not p.enemy_seen("brute"), "brutes arrive at wave 25")
	p.best_wave["1"] = 30
	check(p.enemy_seen("brute"), "a best wave of 30 means you met them")
	check(not p.enemy_seen("wyvern"), "wyverns only raid tier 2")
	p.seen_enemies["wyvern"] = true
	var copy := ProfileData.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	check(copy.enemy_seen("wyvern"), "saved")
