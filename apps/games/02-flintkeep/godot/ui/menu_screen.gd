class_name MenuScreen
extends Control
## Title screen: the Keep standing in the night, the tier picker, PLAY and RESEARCH.

signal play(tier: int)
signal research

var _tier := 1
var _tier_label: Label
var _best_label: Label
var _coins_label: Label
var _lab_label: Label
var _time := 0.0
var _hero: Control


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_tier = Profile.data.unlocked_tier
	var bg := Kit.color_rect(Pal.BG)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := SafeMargin.new(24)
	add_child(margin)
	var col := Kit.vbox(14)
	margin.add_child(col)

	var top := Kit.hbox(8)
	top.add_child(Kit.spacer(true))
	top.add_child(Kit.icon(Sprites.get_tex("coin"), 4))
	_coins_label = Kit.label("", 4, Pal.GOLD)
	top.add_child(_coins_label)
	col.add_child(top)

	col.add_child(Kit.spacer())
	col.add_child(Kit.label("FLINTKEEP", 9, Pal.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(Kit.label("HOLD THE KEEP. HOLD THE NIGHT.", 2, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	_hero = Control.new()
	_hero.custom_minimum_size = Vector2(0, 260)
	_hero.draw.connect(_draw_hero)
	col.add_child(_hero)

	var picker := Kit.hbox(10)
	var prev := Kit.button("<", Kit.Btn.SECONDARY, 4, 72)
	prev.custom_minimum_size.x = 80
	prev.pressed.connect(_change_tier.bind(-1))
	picker.add_child(prev)
	var mid := Kit.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tier_label = Kit.label("", 5, Pal.PARCHMENT, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(_tier_label)
	picker.add_child(mid)
	var next := Kit.button(">", Kit.Btn.SECONDARY, 4, 72)
	next.custom_minimum_size.x = 80
	next.pressed.connect(_change_tier.bind(1))
	picker.add_child(next)
	col.add_child(picker)
	_best_label = Kit.label("", 2, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_best_label)

	var play_button := Kit.button("DEFEND", Kit.Btn.PRIMARY, 6, 100)
	play_button.pressed.connect(func() -> void: play.emit(_tier))
	col.add_child(play_button)
	var research_button := Kit.button("RESEARCH", Kit.Btn.SECONDARY, 4, 80)
	research_button.pressed.connect(func() -> void: research.emit())
	col.add_child(research_button)
	_lab_label = Kit.label("", 2, Pal.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_lab_label)
	col.add_child(Kit.spacer())
	Profile.changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	_hero.queue_redraw()
	_lab_label.text = _lab_text()


func _change_tier(step: int) -> void:
	_tier = clampi(_tier + step, 1, Profile.data.unlocked_tier)
	_refresh()


func _refresh() -> void:
	_coins_label.text = Num.fmt(Profile.data.coins)
	_tier_label.text = "TIER %d" % _tier
	var best := Profile.data.best(_tier)
	var line := "BEST WAVE %d    COINS X%.2f" % [best, Defs.tier_coin_mult(_tier)]
	if _tier == Profile.data.unlocked_tier and _tier < Defs.MAX_TIER:
		line += "\nWAVE %d UNLOCKS TIER %d" % [Defs.TIER_UNLOCK_WAVE, _tier + 1]
	_best_label.text = line


func _lab_text() -> String:
	var busy := 0
	var soonest := INF
	for i in Profile.data.labs.size():
		if Profile.data.labs[i]["id"] != "":
			busy += 1
			soonest = minf(soonest, Profile.data.seconds_left(i, Profile.now()))
	if busy == 0:
		return "LABS IDLE: START SOME RESEARCH"
	return "%d/%d LABS WORKING. NEXT IN %s" % [busy, Profile.data.labs.size(), Num.duration(soonest)]


func _draw_hero() -> void:
	var c := _hero.size / 2.0
	var keep := Sprites.get_tex("keep")
	var scale := 6.0
	var glow := 0.5 + 0.5 * sin(_time * 2.0)
	for i in 6:
		var r := 130.0 - i * 18.0
		_hero.draw_circle(c + Vector2(0, 40), r, Color(0.37, 0.95, 1.0, 0.018 + 0.012 * glow))
	_hero.draw_rect(Rect2(c.x - 150, c.y + 90, 300, 6), Pal.EARTH)
	var size := keep.get_size() * scale
	_hero.draw_texture_rect(keep, Rect2((c - Vector2(size.x / 2.0, size.y / 2.0 - 4.0)).floor(), size), false)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var tex := Sprites.get_tex("musket" if i == 0 else "cannon")
		var s := tex.get_size() * 4.0
		_hero.draw_texture_rect(tex, Rect2(Vector2(c.x + side * 120.0 - s.x / 2.0, c.y + 92.0 - s.y).floor(), s), false)
