class_name MenuScreen
extends Control
## Title screen: the Keep glowing in the night, the tier picker, Defend and Research.

signal play(tier: int)
signal research

var _tier := 1
var _tier_label: Label
var _best_label: Label
var _coins_label: Label
var _lab_label: Label
var _time := 0.0
var _hero: Control
var _glow: Texture2D


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_tier = Profile.data.unlocked_tier
	_glow = FieldFx.soft_disc()
	add_child(Kit.backdrop())
	var margin := SafeMargin.new(24)
	add_child(margin)
	var col := Kit.vbox(14)
	margin.add_child(col)

	var top := Kit.hbox(8)
	top.add_child(Kit.spacer(true))
	var pill := Kit.panel_container(Pal.PANEL_DEEP, Pal.LINE, 22)
	var coins := Kit.hbox(8)
	coins.add_child(Kit.icon("coin", 26))
	_coins_label = Kit.label("", 22, Pal.GOLD, Fonts.bold())
	coins.add_child(_coins_label)
	pill.add_child(coins)
	top.add_child(pill)
	col.add_child(top)

	col.add_child(Kit.spacer())
	col.add_child(Kit.heading("Flintkeep", 68, Pal.GOLD))
	col.add_child(Kit.label("Hold the Keep. Hold the night.", 20, Pal.DIM, Fonts.body(), HORIZONTAL_ALIGNMENT_CENTER))
	_hero = Control.new()
	_hero.custom_minimum_size = Vector2(0, 290)
	_hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_hero.draw.connect(_draw_hero)
	col.add_child(_hero)

	var picker := Kit.hbox(10)
	var prev := Kit.button("‹", Kit.Btn.SECONDARY, 34, 64)
	prev.custom_minimum_size.x = 72
	prev.pressed.connect(_change_tier.bind(-1))
	picker.add_child(prev)
	_tier_label = Kit.heading("", 32, Pal.PARCHMENT)
	_tier_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.add_child(_tier_label)
	var next := Kit.button("›", Kit.Btn.SECONDARY, 34, 64)
	next.custom_minimum_size.x = 72
	next.pressed.connect(_change_tier.bind(1))
	picker.add_child(next)
	col.add_child(picker)
	_best_label = Kit.label("", 18, Pal.DIM, Fonts.body(), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_best_label)

	var play_button := Kit.button("Defend", Kit.Btn.PRIMARY, 34, 88)
	play_button.add_theme_font_override("font", Fonts.heading())
	play_button.pressed.connect(func() -> void: play.emit(_tier))
	col.add_child(play_button)
	var research_button := Kit.button("Research", Kit.Btn.SECONDARY, 24, 70)
	research_button.pressed.connect(func() -> void: research.emit())
	col.add_child(research_button)
	_lab_label = Kit.label("", 17, Pal.CYAN, Fonts.body(), HORIZONTAL_ALIGNMENT_CENTER)
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
	_tier_label.text = "Tier %d" % _tier
	var best := Profile.data.best(_tier)
	var line := "Best wave %d   ·   coins ×%.2f" % [best, Defs.tier_coin_mult(_tier)]
	if _tier == Profile.data.unlocked_tier and _tier < Defs.MAX_TIER:
		line += "\nReach wave %d to unlock tier %d" % [Defs.TIER_UNLOCK_WAVE, _tier + 1]
	_best_label.text = line


func _lab_text() -> String:
	var busy := 0
	var soonest := INF
	for i in Profile.data.labs.size():
		if Profile.data.labs[i]["id"] != "":
			busy += 1
			soonest = minf(soonest, Profile.data.seconds_left(i, Profile.now()))
	if busy == 0:
		return "Your labs are idle: start some research"
	return "%d of %d labs working  ·  next done in %s" % [busy, Profile.data.labs.size(), Num.duration(soonest).to_lower()]


func _draw_hero() -> void:
	var c := Vector2(_hero.size.x / 2.0, _hero.size.y - 30.0)
	var pulse := 0.85 + 0.15 * sin(_time * 2.0)
	_hero.draw_texture_rect(_glow, Rect2(c - Vector2(230, 200), Vector2(460, 300)), false, Color(0.44, 0.89, 1.0, 0.16 * pulse))
	_hero.draw_texture_rect(_glow, Rect2(c - Vector2(220, 40), Vector2(440, 80)), false, Color(Pal.EARTH, 0.9))
	var scale := 6.4  # px per field unit
	for side in [-1.0, 1.0]:
		var name := "musket" if side < 0.0 else "cannon"
		var r := Art.rect(name, Vector2.ZERO)
		_hero.draw_texture_rect(Art.tex(name), Rect2(c + Vector2(side * 140.0, 0) + r.position * scale * 0.8, r.size * scale * 0.8), false)
	var keep := Art.rect("keep", Vector2.ZERO)
	_hero.draw_texture_rect(Art.tex("keep"), Rect2(c + keep.position * scale, keep.size * scale), false)
	var crystal := c + (keep.position + keep.size * Vector2(0.5, 0.12)) * scale
	_hero.draw_texture_rect(_glow, Rect2(crystal - Vector2(60, 60), Vector2(120, 120)), false, Color(0.44, 0.89, 1.0, 0.35 * pulse))
