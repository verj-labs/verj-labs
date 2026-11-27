extends TestCase
## The rules of a run: building, walls, damage types, rewards and losing.

const SEED := 4242


func _battle(research: Dictionary = {}) -> Battle:
	var b := Battle.new(research, 1, SEED)
	b.enemies.clear()
	return b


func _run(b: Battle, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		b.step(0.05)
		t += 0.05


func test_fortress_layout_grows_outward() -> void:
	var b := _battle()
	eq(b.slots.size(), 4 + 4 + 6 + 8, "rings of 4, 4, 6 and 8 towers")
	eq(b.rings_unlocked, 1)
	check(b.slot_open(0), "ring 1 is open")
	check(not b.slot_open(4), "ring 2 starts locked")
	eq(_battle({"ring_2": 1, "ring_3": 1}).rings_unlocked, 3)


func test_ring_one_is_a_cross_and_ring_two_a_plus() -> void:
	var b := _battle({"ring_2": 1})
	var r1: float = Defs.RING_RADII[1]
	near(absf(b.slots[0].pos.x), absf(b.slots[0].pos.y), 0.01, "ring 1 towers sit on the diagonals (an X)")
	near(b.slots[0].pos.length(), r1, 0.01)
	near(b.slots[4].pos.x, 0.0, 0.01, "ring 2 starts due north (a plus)")
	near(b.slots[4].pos.y, -Defs.RING_RADII[2], 0.01)


func test_building_costs_cash() -> void:
	var b := _battle()
	b.cash = 100.0
	check(b.build(0, "musket"), "built")
	near(b.cash, 75.0)
	check(not b.build(0, "musket"), "slot already taken")
	check(not b.build(1, "cannon"), "locked weapon")
	check(not b.build(5, "musket"), "locked ring")


func test_cannot_build_without_cash() -> void:
	var b := _battle()
	b.cash = 10.0
	check(not b.build(0, "musket"), "too poor")
	near(b.cash, 10.0)


func test_research_sets_tower_start_level_and_cheaper_upgrades() -> void:
	var plain := _battle()
	var drilled := _battle({"musket": 3})
	plain.cash = 1000.0
	drilled.cash = 1000.0
	plain.build(0, "musket")
	drilled.build(0, "musket")
	eq(drilled.slots[0].tower.level, 4)
	check(drilled.tower_upgrade_cost(0) < plain.tower_upgrade_cost(0), "a higher start level never makes upgrades pricier")
	check(drilled.tower_damage(drilled.slots[0].tower) > plain.tower_damage(plain.slots[0].tower), "higher start level hits harder")


func test_selling_refunds_half() -> void:
	var b := _battle()
	b.cash = 100.0
	b.build(0, "musket")
	b.upgrade_tower(0)
	var spent := 100.0 - b.cash
	check(b.sell(0), "sold")
	near(b.cash, 100.0 - spent * 0.5)
	check(b.slots[0].tower == null, "slot is empty again")


func test_ground_enemy_stops_at_an_intact_wall() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.build_wall(1)
	b.levels["damage"] = -200  # the Keep cannot hurt anything; we only watch movement
	var e := b.spawn("footman", -PI / 2.0)
	e.hp = 1e9
	_run(b, 20.0)
	check(e.dist > b.wall_radius(1), "held outside the wall")
	eq(e.attacking, 1, "attacking the ring 1 wall")
	var seg := Battle.wall_segment(1, e.angle)
	check(b.walls[1].segments[seg] < b.walls[1].max_hp, "the wall section takes damage")


func test_broken_wall_lets_enemies_through() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.build_wall(1)
	b.levels["damage"] = -200
	var e := b.spawn("footman", -PI / 2.0)
	e.hp = 1e9
	b.walls[1].segments[Battle.wall_segment(1, e.angle)] = 0.0
	_run(b, 20.0)
	eq(e.attacking, 0, "straight on to the Keep")


func test_flyers_ignore_walls() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.build_wall(1)
	b.levels["damage"] = -200
	var e := b.spawn("balloon", 0.0)
	e.hp = 1e9
	_run(b, 25.0)
	eq(e.attacking, 0)
	check(e.dist < b.wall_radius(1), "flew over")


func test_armour_blocks_physical_but_not_magic() -> void:
	var b := _battle()
	var brute := b.spawn("brute", 0.0)
	var hp := brute.hp
	near(BattleCombat.hit(brute, 10.0, Defs.DamageType.PHYSICAL, 0.0), 10.0 * (1.0 - brute.armor))
	near(BattleCombat.hit(brute, 10.0, Defs.DamageType.MAGIC, 0.0), 10.0)
	near(BattleCombat.hit(brute, 10.0, Defs.DamageType.PHYSICAL, 1.0), 10.0, 0.001, "full pierce ignores armour")
	check(brute.hp < hp, "damage applied")


func test_volley_guns_only_shoot_flyers() -> void:
	var b := _battle({"volley": 1})
	var ground := b.spawn("footman", 0.0)
	ground.dist = 40.0
	check(BattleCombat.find_target(b, Vector2.ZERO, 100.0, Defs.Target.AIR, "near") == null, "no air target")
	var flyer := b.spawn("balloon", 0.0)
	flyer.dist = 45.0
	check(BattleCombat.find_target(b, Vector2.ZERO, 100.0, Defs.Target.AIR, "near") == flyer, "finds the flyer")


func test_kills_pay_cash_and_coins() -> void:
	var b := _battle()
	var cash := b.cash
	var coins := b.coins_earned
	var e := b.spawn("footman", 0.0)
	e.dist = 30.0
	e.hp = 0.1
	b.step(0.05)
	eq(b.kills, 1)
	check(b.cash > cash, "cash for the kill")
	check(b.coins_earned > coins, "coins for the kill")
	check(b.cash - cash > b.coins_earned - coins, "coins come slower than cash")


func test_waves_arrive_on_a_timer_and_pay_coins() -> void:
	var b := Battle.new({}, 1, SEED)
	b.levels["health"] = 60  # survive long enough to watch
	var coins := b.coins_earned
	_run(b, Defs.WAVE_SECONDS + 0.1)
	eq(b.wave, 2)
	check(b.coins_earned > coins, "each wave pays coins")


func test_boss_every_tenth_wave() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var kinds := BattleWaves.plan(10, rng).map(func(e: Array) -> String: return e[1])
	check("juggernaut" in kinds, "wave 10 has a juggernaut")
	kinds = BattleWaves.plan(9, rng).map(func(e: Array) -> String: return e[1])
	check(not ("juggernaut" in kinds), "wave 9 does not")


func test_interest_is_capped_per_wave() -> void:
	var b := _battle()
	b.levels["interest"] = 10
	b.cash = 1_000_000.0
	b.wave_timer = 0.01
	var wave_pay := b.stat("wave_cash") * Upgrades.cash_scale(1)
	b.step(0.05)
	var cap := Defs.INTEREST_CAP_PER_WAVE * Upgrades.cash_scale(1) * 10.0
	near(b.cash, 1_000_000.0 + wave_pay + cap, 1.0, "interest stops at the cap")


func test_the_run_ends_when_the_keep_falls() -> void:
	var b := _battle()
	b.keep_hp = 0.5
	var e := b.spawn("brute", 0.0)
	e.dist = Defs.KEEP_RADIUS + 1.0
	e.hp = 1e9
	_run(b, 1.0)
	check(b.over, "game over")
	check(not b.build(0, "musket"), "no shopping after the end")


func test_keep_health_upgrade_heals_the_difference() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.keep_hp = 50.0
	var before := b.keep_max_hp()
	b.buy_upgrade("health")
	near(b.keep_hp, 50.0 + b.keep_max_hp() - before)


func test_walls_can_be_reinforced() -> void:
	var b := _battle()
	b.cash = 10000.0
	b.build_wall(1)
	var hp := b.walls[1].max_hp
	b.reinforce_wall(1)
	check(b.walls[1].max_hp > hp, "reinforced walls are tougher")


func test_wall_sections_sit_between_towers() -> void:
	# Ring 2 towers are N, E, S, W; section 0 runs from the north tower to the east one.
	var north := -PI / 2.0
	eq(Battle.wall_segment(2, north + 0.1), 0, "just east of north is section 0")
	eq(Battle.wall_segment(2, north - 0.1), 3, "just west of north is the last section")
	near(Battle.section_angle(2, 0), north + PI / 4.0, 0.001, "section 0 is centred on the north-east")
	near(Battle.section_angle(1, 0), 0.0, 0.001, "ring 1 (an X) has its first section due east")


func test_sections_are_bought_one_at_a_time() -> void:
	var b := _battle()
	b.cash = 1000.0
	var price := b.section_cost(1)
	check(b.build_section(1, 0), "built")
	near(b.cash, 1000.0 - price)
	check(not b.build_section(1, 0), "already built")
	check(not b.build_section(2, 0), "ring 2 is locked")
	eq(b.walls[1].built_count(), 1)
	check(not b.walls[1].complete(), "one of four is not fortified")
	near(b.wall_build_cost(1), price * 3.0, 0.01, "finishing costs the three missing sections")


func test_an_enemy_only_stops_at_a_built_section() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.levels["damage"] = -200
	b.build_section(1, 0)  # north-east arc only
	var blocked := b.spawn("footman", Battle.section_angle(1, 0))
	var free := b.spawn("footman", Battle.section_angle(1, 2))
	blocked.hp = 1e9
	free.hp = 1e9
	_run(b, 19.5)  # both have arrived; later the wave's raiders break the section
	eq(blocked.attacking, 1, "stopped by the wall")
	eq(free.attacking, 0, "walked through the gap to the Keep")


func test_completing_a_ring_fortifies_it() -> void:
	var b := _battle()
	b.cash = 10000.0
	b.build(0, "musket")
	var plain_damage := b.slot_damage(b.slots[0])
	for seg in 3:
		b.build_section(1, seg)
	var hp_before := b.walls[1].max_hp
	b.build_section(1, 3)
	check(b.walls[1].complete(), "fortified")
	near(b.walls[1].max_hp, hp_before * Defs.FORTIFIED_HP, 0.01, "tougher walls")
	near(b.slot_damage(b.slots[0]), plain_damage * (1.0 + Defs.FORTIFIED_DAMAGE), 0.001, "towers hit harder")
	near(b.walls[1].segments[0], b.walls[1].max_hp, 0.01, "existing sections grow with it")


func test_sappers_blow_up_against_walls() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.levels["damage"] = -200
	b.build_wall(1)
	var seg := Battle.wall_segment(1, PI / 4.0)
	var hp := b.walls[1].segments[seg]
	var e := b.spawn("sapper", PI / 4.0)
	e.dist = b.wall_radius(1) + 3.0
	var cash := b.cash
	_run(b, 1.0)
	check(b.walls[1].segments[seg] < hp, "the wall took the blast")
	check(not b.enemies.has(e), "the sapper is gone")
	near(b.cash, cash, 0.001, "a sapper that blows himself up pays nothing")


func test_shamans_heal_raiders_near_them() -> void:
	var b := _battle()
	b.levels["damage"] = -200
	var shaman := b.spawn("shaman", 0.0)
	var friend := b.spawn("footman", 0.0)
	friend.hp = friend.max_hp * 0.5
	var far := b.spawn("footman", PI)
	far.hp = far.max_hp * 0.5
	BattleCombat._heal(b, 1.0)
	check(friend.hp > friend.max_hp * 0.5, "healed")
	near(far.hp, far.max_hp * 0.5, 0.001, "out of reach")
	near(shaman.hp, shaman.max_hp, 0.001, "shamans do not heal themselves (they are full anyway)")


func test_calling_the_next_wave_early_pays_a_bonus() -> void:
	var b := _battle()
	check(not b.call_next_wave(), "not while the wave is still arriving")
	_run(b, Defs.SPAWN_SECONDS + 0.5)
	b.keep_hp = b.keep_max_hp()
	var cash := b.cash
	var bonus := b.early_bonus()
	check(bonus > 0.0, "time left is worth something")
	var wave := b.wave
	check(b.call_next_wave(), "called")
	eq(b.wave, wave + 1)
	check(b.cash >= cash + bonus - 0.01, "bonus paid")


func test_upgrade_caps_hold() -> void:
	var b := _battle()
	b.levels["bounce"] = 999
	b.levels["push_chance"] = 999
	b.levels["lifesteal"] = Upgrades.LIST["lifesteal"]["max"]
	check(b.bounce_chance() <= 0.8 + 0.0001, "bounce tops out at 80%")
	check(b.push_chance() <= 0.8 + 0.0001, "pushback chance tops out at 80%")
	near(b.stat("lifesteal"), 0.05, 0.0001, "lifesteal tops out at 5%")
	check(Upgrades.maxed("lifesteal", 50), "and cannot be bought further")


func test_prices_grow_faster_than_effects() -> void:
	# the rule that keeps runs finite: no upgrade pays for itself forever
	for id in Upgrades.LIST:
		var u: Dictionary = Upgrades.LIST[id]
		if u["kind"] == "mult":
			check(u["growth"] > u["step"], "%s: price growth must beat effect growth" % id)


func test_multishot_and_bounce_hit_more_enemies() -> void:
	var b := _battle()
	b.levels["multishot"] = 40
	b.levels["bounce"] = 40
	b.perk["multishot"] = 0.5  # 80% + 50%: always
	for i in 4:
		var e := b.spawn("footman", 0.1 * i)
		e.dist = 30.0
		e.hp = 1e9
	_run(b, 2.0)  # a few volleys (each has a 90% multishot chance)
	var hit := 0
	for e in b.enemies:
		if e.hp < 1e9:
			hit += 1
	check(hit >= 2, "one volley hurt several enemies (%d)" % hit)


func test_pushback_knocks_ground_enemies_back() -> void:
	var b := _battle()
	b.levels["push_chance"] = 40
	b.perk["push"] = 0.5
	var e := b.spawn("footman", 0.0)
	e.dist = 40.0
	e.hp = 1e9
	b.keep_cooldown = 0.0
	b.step(0.01)
	check(e.dist > 40.0, "pushed back (now %.1f)" % e.dist)


func test_a_perk_is_offered_every_fifty_waves_and_picked_if_ignored() -> void:
	var b := _battle()
	b.levels["health"] = 300  # survive long enough to watch the timer
	b.keep_hp = b.keep_max_hp()
	b.wave = Defs.PERK_EVERY - 1
	b.wave_timer = 0.01
	b.step(0.05)
	eq(b.wave, Defs.PERK_EVERY)
	eq(b.perk_offer.size(), 3, "three perks on offer")
	_run(b, Defs.PERK_SECONDS + 0.5)
	check(b.perk_offer.is_empty(), "one was picked at random when time ran out")
	check(not b.perk.is_empty(), "and it applies")


func test_powers_need_research_and_recharge() -> void:
	var b := _battle()
	check(not b.cast("rain"), "locked without research")
	var r := _battle({"power_rain": 1})
	var e := r.spawn("footman", 0.0)
	var hp := e.hp
	check(r.cast("rain"), "cast")
	check(e.hp < hp, "Arrow Rain hit the enemy")
	check(not r.cast("rain"), "recharging")


func test_auto_buy_spends_cash_in_its_tab() -> void:
	var b := _battle()
	b.cash = 500.0
	b.set_auto("Attack", true)
	_run(b, 1.1)
	var bought := 0
	for id in Upgrades.ids_in("Attack"):
		bought += b.level(id)
	check(bought > 0, "auto-buy bought attack upgrades")
	eq(b.level("health"), 0, "and nothing from other tabs")


func test_workshop_and_research_make_runs_stronger() -> void:
	var plain := Battle.new({}, 1, 1)
	var strong := Battle.new({"siege": 10}, 1, 1, {"damage": 10, "health": 10, "start_cash": 2})
	check(strong.keep_damage() > plain.keep_damage() * 2.0, "workshop damage compounds")
	check(strong.keep_max_hp() > plain.keep_max_hp() * 2.0, "workshop health compounds")
	check(strong.cash > plain.cash, "starting cash")
	check(Upgrades.enemy_scale(500, strong.siege()) < Upgrades.enemy_scale(500, plain.siege()), "siege lore slows enemy growth")



func test_coins_every_wave_grow_with_the_economy_upgrade() -> void:
	var b := _battle()
	var few := b.wave_coins()
	check(few > 0.0 and few < 10.0, "a few coins a wave (%.1f)" % few)
	b.levels["wave_coins"] = 10
	check(b.wave_coins() > few * 2.0, "the Coins per wave upgrade raises it")


func test_waves_stop_at_the_maximum() -> void:
	var b := _battle()
	b.levels["health"] = 400
	b.keep_hp = b.keep_max_hp()
	b.wave = Defs.MAX_WAVE
	b.wave_timer = 0.01
	b.step(0.05)
	eq(b.wave, Defs.MAX_WAVE, "the last wave repeats")
	check(b.perk_offer.is_empty(), "no extra perk offers while it repeats")


func test_higher_tiers_are_the_same_curve_raised() -> void:
	var t1 := Battle.new({}, 1, 3)
	var t2 := Battle.new({}, 2, 3)
	t1.wave = 40
	t2.wave = 40
	var a := t1.spawn("footman", 0.0)
	var c := t2.spawn("footman", 0.0)
	near(c.max_hp / a.max_hp, Defs.tier_enemy_mult(2), 0.001, "tier 2 multiplies every wave by the same factor")



func test_thorns_cost_a_lot_to_unlock_and_walls_need_the_add_on() -> void:
	check(Upgrades.price("thorns", 0) > Upgrades.price("thorns", 1) * 5.0, "the first level is the expensive unlock")
	var b := _battle()
	b.cash = 1e6
	b.build_wall(1)
	b.levels["damage"] = -200
	eq(b.wall_addon_cost(1, "thorns"), -1.0, "wall thorns need Thorns unlocked first")
	b.levels["thorns"] = 10
	var e := b.spawn("brute", Battle.section_angle(1, 0))
	e.dist = b.wall_radius(1) + 4.0
	e.hp = 1e6
	_run(b, 2.0)
	eq(e.attacking, 1, "hacking at the wall")
	near(e.hp, 1e6, 0.001, "a plain wall does not hurt back")
	check(b.buy_wall_addon(1, "thorns"), "ring 1 bought thorns")
	_run(b, 2.0)
	check(e.hp < 1e6, "now the spiked wall hurts it back")
	check(b.damage_by.has("Thorns"), "and the run report counts it")


func test_wall_add_ons_are_bought_ring_by_ring() -> void:
	var b := _battle({"ring_2": 1})
	b.cash = 1e9
	b.levels["thorns"] = 1
	eq(b.wall_addon_cost(1, "absolute"), -1.0, "needs a wall")
	b.build_wall(1)
	b.build_wall(2)
	var first := b.wall_addon_cost(1, "absolute")
	check(b.buy_wall_addon(1, "absolute"), "ring 1")
	check(not b.buy_wall_addon(1, "absolute"), "once per ring")
	near(b.wall_addon_cost(2, "absolute"), first * Defs.WALL_RING_GROWTH * Defs.ADDON_GROWTH, 0.01, "the next ring costs more")
	check(not b.walls[2].addons.has("absolute"), "ring 2 does not get it for free")


func test_absolute_defense_on_a_wall_blocks_damage() -> void:
	var plain := _battle()
	var guarded := _battle()
	for b: Battle in [plain, guarded]:
		b.cash = 1e9
		b.build_wall(1)
		b.levels["damage"] = -200
		b.levels["absolute"] = 20
	guarded.buy_wall_addon(1, "absolute")
	for b: Battle in [plain, guarded]:
		var e: Entities.Enemy = b.spawn("brute", Battle.section_angle(1, 0))
		e.dist = b.wall_radius(1) + 4.0
		e.hp = 1e9
		_run(b, 3.0)
	check(guarded.walls[1].segments[0] > plain.walls[1].segments[0], "the guarded wall lost less")


func test_research_finished_mid_run_applies_at_once() -> void:
	var research := {}
	var workshop := {}
	var b := Battle.new(research, 1, 5, workshop)
	var before := b.keep_damage()
	workshop["damage"] = 5  # the profile's dictionaries are shared with the battle
	check(b.keep_damage() > before, "workshop level applies straight away")
	research["ring_2"] = 1
	b.refresh_unlocks()
	eq(b.rings_unlocked, 2, "a ring researched mid-run opens")


func test_perks_can_be_rerolled() -> void:
	var b := _battle()
	check(not b.reroll_perks(), "nothing to reroll")
	b.perk_offer = Perks.pick_three(b.rng)
	b.perk_time = 3.0
	check(b.reroll_perks(), "rerolled")
	eq(b.perk_offer.size(), 3)
	near(b.perk_time, Defs.PERK_SECONDS, 0.001, "the timer starts again")




func test_keep_regeneration_is_a_capped_share_of_health() -> void:
	var b := Battle.new({}, 1, 1, {"regen": 200})
	b.levels["regen"] = Upgrades.LIST["regen"]["max"]
	near(b.keep_regen(), b.keep_max_hp() * Defs.KEEP_REGEN_MAX / 100.0, 0.01, "capped however much is bought")
	check(Upgrades.maxed("regen", Upgrades.LIST["regen"]["max"]), "the in-run upgrade has a last level")



func test_towers_need_add_ons_for_the_keeps_effects() -> void:
	var b := _battle()
	b.cash = 1e9
	b.levels["crit_chance"] = 80
	b.build(0, "musket")
	var tower := b.slots[0].tower
	var e := b.spawn("footman", 0.0)
	e.max_hp = 1e12
	e.hp = 1e12
	e.dist = 20.0
	b.record_events = true
	for i in 40:
		BattleCombat._shoot(b, e, 1.0, Defs.DamageType.PHYSICAL, 0.0, "test", tower.addons)
	check(not b.drain_events().any(func(ev: Dictionary) -> bool: return ev["type"] == "crit"), "no crits without the add-on")
	check(b.buy_addon(0, "crit"), "bought")
	check(not b.buy_addon(0, "crit"), "only once per tower")
	for i in 40:
		BattleCombat._shoot(b, e, 1.0, Defs.DamageType.PHYSICAL, 0.0, "test", tower.addons)
	check(b.drain_events().any(func(ev: Dictionary) -> bool: return ev["type"] == "crit"), "the add-on uses the Keep's crit chance")


func test_each_add_on_costs_more_the_more_towers_have_it() -> void:
	var b := _battle()
	b.cash = 1e9
	b.build(0, "musket")
	b.build(1, "musket")
	var first := b.addon_cost(0, "bounce")
	b.buy_addon(0, "bounce")
	near(b.addon_cost(1, "bounce"), first * Defs.ADDON_GROWTH, 0.01)
	eq(b.addon_cost(0, "bounce"), -1.0, "already has it")
	var invested := b.slots[0].tower.invested
	check(invested > b.build_cost("musket"), "add-ons count towards the sell refund")


func test_upgrade_all_and_add_ons_for_all() -> void:
	var b := _battle()
	b.cash = 1e9
	for i in 4:
		b.build(i, "musket")
	var total := b.upgrade_all_cost()
	var before := b.cash
	check(b.upgrade_all_towers(), "upgraded")
	near(before - b.cash, total, 0.01, "one level each costs the shown total")
	for i in 4:
		eq(b.slots[i].tower.level, 2)
	check(b.addon_all_cost("multishot") > 0.0, "priced")
	check(b.buy_addon_all("multishot"), "bought for all")
	eq(b.addon_count("multishot"), 4)
	eq(b.addon_all_cost("multishot"), -1.0, "nothing left to buy")
	b.set_focus_all("strong")
	check(b.slots.filter(func(s: Entities.Slot) -> bool: return s.tower != null).all(func(s: Entities.Slot) -> bool: return s.tower.focus == "strong"), "targeting set for all")


func test_buy_all_stops_when_cash_runs_out() -> void:
	var b := _battle()
	b.cash = 1e9
	for i in 4:
		b.build(i, "musket")
	b.cash = b.addon_cost(0, "crit") * 1.5
	check(b.buy_addon_all("crit"), "bought what it could")
	eq(b.addon_count("crit"), 1, "only one was affordable")


func test_new_enemies_arrive_on_planned_waves() -> void:
	var seen := {}
	for kind in Defs.ENEMY_ORDER:
		if kind == "footman" or kind == "juggernaut" or kind in Defs.CHAMPIONS:
			continue  # champions arrive as the boss of their wave (see the champion tests)
		for tier in range(1, Defs.MAX_TIER + 1):
			var wave := Defs.enemy_arrives(kind, tier)
			if wave < 0:
				continue
			eq(wave % 5, 0, kind + " arrives on a wave ending in 5")
			check(wave % Defs.BOSS_EVERY != 0, kind + " never arrives with a boss")
			var key := "%d:%d" % [tier, wave]
			check(not seen.has(key) or wave < 15, "one newcomer per wave (%s)" % key)
			seen[key] = true
	for kind in Defs.ENEMY_ORDER:
		if int(Defs.ENEMY_ROSTER[kind]["tier"]) == 1 and not kind in Defs.CHAMPIONS:
			check(Defs.enemy_arrives(kind, 1) <= 45, kind + ": all of tier 1's raiders have arrived by wave 45")
	eq(Defs.enemy_arrives("wyvern", 1), -1, "wyverns only raid from tier 2")
	check(Defs.enemy_arrives("wyvern", 2) > 0, "and do raid in tier 2")


func test_waves_only_send_enemies_that_have_arrived() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for wave in [1, 14]:
		for entry in BattleWaves.plan(wave, rng, 1):
			check(entry[1] in ["footman", "juggernaut"], "only raiders before wave 15 (got %s)" % entry[1])
	var kinds := {}
	for i in 20:
		for entry in BattleWaves.plan(60, rng, 1):
			kinds[entry[1]] = true
	check(kinds.has("sapper") and not kinds.has("wyvern"), "tier 1 wave 60: all tier-1 kinds, no wyverns")
	eq(BattleWaves.newcomer(15, 1), "runner", "sprinters are the first newcomer")
	eq(BattleWaves.newcomer(10, 1), "", "boss waves bring no newcomer")


func test_sprinters_are_fast_and_bosses_slow() -> void:
	var footman: float = Defs.ENEMIES["footman"]["speed"]
	check(Defs.ENEMIES["runner"]["speed"] >= footman * 1.8, "sprinters are much faster than raiders")
	check(Defs.ENEMIES["juggernaut"]["speed"] < footman * 0.5, "the boss is slow")
	check(Defs.ENEMIES["brute"]["speed"] < footman, "heavies are slow")


func test_walls_mend_themselves_from_the_start() -> void:
	near(Upgrades.value("wall_regen", 0), 0.001, 0.00001, "0.1% a second before any upgrade")
	check(Upgrades.value("wall_regen", 1) > Upgrades.value("wall_regen", 0), "the upgrade speeds it up")
	var b := _battle()
	b.cash = 1e6
	b.build_wall(1)
	b.walls[1].segments[1] = b.walls[1].max_hp * 0.5
	_run(b, 5.0)
	check(b.walls[1].segments[1] > b.walls[1].max_hp * 0.5, "a hurt wall mends on its own")


func test_wall_regeneration_rebuilds_broken_sections() -> void:
	var b := _battle()
	b.cash = 1e6
	b.build_wall(1)
	b.levels["damage"] = -200
	var e := b.spawn("brute", Battle.section_angle(1, 0))
	e.dist = b.wall_radius(1) + 4.0
	e.hp = 1e12
	e.max_hp = 1e12
	e.dps = b.walls[1].max_hp * 10.0
	_run(b, 1.0)
	check(b.walls[1].broken[0], "the brute broke through")
	e.hp = 0.0  # gone
	b.levels["wall_regen"] = 29
	_run(b, 2.0)
	check(b.walls[1].segments[0] > 0.0, "a broken section regrows")
	check(not b.walls[1].stands(0), "but it does not block until it is half rebuilt")
	_run(b, 20.0)
	check(b.walls[1].stands(0), "half rebuilt: it stands again")


func test_rubble_does_not_regrow_under_raiders() -> void:
	var b := _battle()
	b.cash = 1e6
	b.build_wall(1)
	b.levels["damage"] = -200
	b.levels["wall_regen"] = 29
	b.walls[1].segments[0] = 0.0
	b.walls[1].broken[0] = true
	var e := b.spawn("brute", Battle.section_angle(1, 0))
	e.dist = b.wall_radius(1)
	e.speed = 0.0  # stands right on the rubble
	e.hp = 1e12
	_run(b, 2.0)
	near(b.walls[1].segments[0], 0.0, 0.001, "nothing regrows while a raider stands on it")
	e.hp = 0.0
	_run(b, 2.0)
	check(b.walls[1].segments[0] > 0.0, "it starts again once they are gone")


func test_regrowing_rubble_does_not_stop_raiders() -> void:
	var b := _battle()
	b.cash = 1e6
	b.build_wall(1)
	b.levels["damage"] = -200
	b.levels["wall_regen"] = 29
	b.walls[1].segments[0] = 0.0
	b.walls[1].broken[0] = true
	var e := b.spawn("footman", Battle.section_angle(1, 0))
	e.dist = b.wall_radius(1) + 6.0
	e.hp = 1e12
	_run(b, 1.5)
	check(e.dist < b.wall_radius(1), "walked through the rubble")
	check(e.attacking != 1, "never stopped at the wall")



func test_champions_are_the_bosses_of_waves_250_500_750() -> void:
	eq(BattleWaves.boss_for(10), "juggernaut")
	eq(BattleWaves.boss_for(240), "juggernaut", "before any champion")
	eq(BattleWaves.boss_for(250), "warlord")
	eq(BattleWaves.boss_for(500), "golem")
	eq(BattleWaves.boss_for(750), "dragon")
	eq(BattleWaves.boss_for(260), "juggernaut", "ordinary boss waves keep the Juggernaut")
	check(BattleWaves.boss_for(300) in ["warlord"], "the Warlord returns every 50 waves")
	var later := {}
	for w in range(800, 1001, 50):
		later[BattleWaves.boss_for(w)] = true
	eq(later.size(), 3, "after wave 750 all three champions take turns")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var kinds := BattleWaves.plan(250, rng).map(func(e: Array) -> String: return e[1])
	check("warlord" in kinds and not ("juggernaut" in kinds), "wave 250 brings the Warlord instead")


func test_warlord_rallies_raiders_near_him() -> void:
	var b := _battle()
	var lord := b.spawn("warlord", 0.0)
	lord.dist = 120.0
	var near_one := b.spawn("footman", 0.05)
	near_one.dist = 120.0
	var far_one := b.spawn("footman", PI)
	far_one.dist = 120.0
	BattleCombat._rally(b)
	check(near_one.rallied and not far_one.rallied, "only raiders under the banner")
	near_one.hp = 100.0
	far_one.hp = 100.0
	var a := BattleCombat.hit(near_one, 10.0, Defs.DamageType.MAGIC, 0.0)
	var c := BattleCombat.hit(far_one, 10.0, Defs.DamageType.MAGIC, 0.0)
	check(a < c, "rallied raiders take less damage")


func test_golem_smashes_walls_and_dragon_attacks_from_range() -> void:
	var b := _battle()
	b.cash = 1e6
	b.build_wall(1)
	b.levels["damage"] = -200
	var golem := b.spawn("golem", Battle.section_angle(1, 0))
	golem.dist = b.wall_radius(1) + 8.0
	golem.hp = 1e12
	var raider := b.spawn("footman", Battle.section_angle(1, 2))
	raider.dist = b.wall_radius(1) + 4.0
	raider.hp = 1e12
	raider.dps = golem.dps
	b.walls[1].max_hp = 1e9
	b.walls[1].segments[0] = 1e9
	b.walls[1].segments[2] = 1e9
	_run(b, 3.0)
	check(1e9 - b.walls[1].segments[0] > (1e9 - b.walls[1].segments[2]) * 4.0, "the golem hits walls far harder")
	var dragon := b.spawn("dragon", 1.0)
	dragon.dist = 200.0
	dragon.hp = 1e12
	_run(b, 30.0)
	check(dragon.attacking == 0, "the dragon attacks the Keep")
	check(dragon.dist > b.keep_range(), "from beyond the Keep's reach")
