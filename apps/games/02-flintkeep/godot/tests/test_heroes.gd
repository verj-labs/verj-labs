extends TestCase
## Heroes: unlocked by beating a champion's wave, a passive and an ability.

const SEED := 4242


func _battle(hero: String) -> Battle:
	var b := Battle.new({}, 1, SEED)
	b.enemies.clear()
	b.hero = hero
	return b


func test_heroes_unlock_past_their_champions_wave() -> void:
	var p := ProfileData.new()
	check(not p.hero_unlocked("captain"), "locked at first")
	p.best_wave["1"] = 250
	check(not p.hero_unlocked("captain"), "reaching the Warlord's wave is not beating it")
	p.best_wave["1"] = 251
	check(p.hero_unlocked("captain"), "beating wave 250 unlocks the Captain")
	check(not p.hero_unlocked("engineer"), "the Engineer needs wave 500")
	p.hero = "engineer"
	eq(p.run_hero(), "", "a locked hero never comes along")
	p.hero = "captain"
	eq(p.run_hero(), "captain")
	var copy := ProfileData.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	eq(copy.hero, "captain", "saved")


func test_captain_rally_makes_towers_fire_faster() -> void:
	var b := _battle("captain")
	b.cash = 1e6
	b.build(0, "musket")
	var tower := b.slots[0].tower
	var plain := Battle.new({}, 1, SEED)
	plain.cash = 1e6
	plain.build(0, "musket")
	check(b.tower_damage(tower) > plain.tower_damage(plain.slots[0].tower), "passive: towers hit harder")
	var before := b.tower_rate(tower)
	check(b.cast_hero(), "Rally")
	check(b.tower_rate(tower) > before * 1.5, "towers fire much faster")
	check(not b.cast_hero(), "then it cools down")


func test_engineer_rebuilds_every_wall() -> void:
	var b := _battle("engineer")
	b.cash = 1e6
	b.build_wall(1)
	b.walls[1].segments[0] = 0.0
	b.walls[1].broken[0] = true
	b.walls[1].segments[1] = 1.0
	check(b.cast_hero(), "Rebuild")
	check(b.walls[1].stands(0), "the broken section stands again")
	near(b.walls[1].segments[1], b.walls[1].max_hp, 0.01, "and every section is at full health")


func test_archmage_meteor_hits_the_toughest() -> void:
	var b := _battle("archmage")
	var small := b.spawn("footman", 0.0)
	small.dist = 150.0
	var big := b.spawn("brute", 2.0)
	big.dist = 150.0
	big.max_hp = 1e9
	big.hp = 1e9
	check(b.cast_hero(), "Meteor")
	check(big.hp < 1e9, "the toughest raider was hit")
	eq(b.damage_by.has("Meteor"), true)
	var empty := _battle("archmage")
	check(not empty.cast_hero(), "with nobody to hit it stays ready")
	check(empty.hero_ready(), "still ready")


func test_no_hero_means_no_ability() -> void:
	var b := _battle("")
	check(not b.hero_ready(), "nothing to cast")
	check(not b.cast_hero(), "refused")
