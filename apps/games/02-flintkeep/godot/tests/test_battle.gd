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
	eq(b.slots.size(), 4 + 6 + 8 + 12)
	eq(b.rings_unlocked, 1)
	check(b.slot_open(0), "ring 1 is open")
	check(not b.slot_open(4), "ring 2 starts locked")
	eq(_battle({"ring_2": 1, "ring_3": 1}).rings_unlocked, 3)


func test_ring_one_sits_on_the_compass_points() -> void:
	var b := _battle()
	near(b.slots[0].pos.x, 0.0, 0.01, "first slot is north")
	near(b.slots[0].pos.y, -Defs.RING_RADII[1], 0.01)


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
	var plain_price := Defs.WEAPONS["musket"]["cost"] * Defs.WEAPON_UPGRADE_BASE * pow(Defs.WEAPON_COST_GROWTH, 3)
	check(drilled.tower_upgrade_cost(0) < plain_price, "research makes upgrades cheaper")
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
	b.keep_levels["damage"] = -100  # the Keep cannot hurt anything; we only watch movement
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
	b.keep_levels["damage"] = -100
	var e := b.spawn("footman", -PI / 2.0)
	e.hp = 1e9
	b.walls[1].segments[Battle.wall_segment(1, e.angle)] = 0.0
	_run(b, 20.0)
	eq(e.attacking, 0, "straight on to the Keep")


func test_flyers_ignore_walls() -> void:
	var b := _battle()
	b.cash = 1000.0
	b.build_wall(1)
	b.keep_levels["damage"] = -100
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
	b.keep_levels["health"] = 60  # survive long enough to watch
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
	b.econ_levels["interest"] = 10
	b.cash = 1_000_000.0
	b.wave_timer = 0.01
	b.step(0.05)
	near(b.cash, 1_000_000.0 + Defs.INTEREST_CAP_PER_WAVE * 1.0, 1.0)


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
	b.buy_keep_upgrade("health")
	near(b.keep_hp, 50.0 + b.keep_max_hp() - before)


func test_walls_repair_and_reinforce() -> void:
	var b := _battle()
	b.cash = 10000.0
	b.build_wall(1)
	var hp := b.walls[1].max_hp
	b.walls[1].segments[0] = 0.0
	check(b.wall_repair_cost(1) > 0.0, "damage costs something to fix")
	check(b.repair_wall(1), "repaired")
	near(b.walls[1].segments[0], hp)
	check(not b.repair_wall(1), "nothing left to repair")
	b.reinforce_wall(1)
	check(b.walls[1].max_hp > hp, "reinforced walls are tougher")


func test_wall_sections_sit_between_towers() -> void:
	# Ring 1 towers are N, E, S, W; section 0 runs from the north tower to the east one.
	var north := -PI / 2.0
	eq(Battle.wall_segment(1, north + 0.1), 0, "just east of north is section 0")
	eq(Battle.wall_segment(1, north - 0.1), 3, "just west of north is the last section")
	near(Battle.section_angle(1, 0), north + PI / 4.0, 0.001, "section 0 is centred on the north-east")


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
	b.keep_levels["damage"] = -100
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
	b.keep_levels["damage"] = -100
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
	b.keep_levels["damage"] = -100
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
