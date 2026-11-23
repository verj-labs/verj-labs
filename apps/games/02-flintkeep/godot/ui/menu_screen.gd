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
var _missions_button: Button


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
	var gear := Kit.button("Settings", Kit.Btn.SECONDARY, 20, 50)
	gear.pressed.connect(_open_settings)
	top.add_child(gear)
	top.add_child(Kit.spacer(true))
	var pill: Array = Kit.pill("coin", Pal.GOLD)
	_coins_label = pill[1]
	top.add_child(pill[0])
	col.add_child(top)

	col.add_child(Kit.spacer())
	col.add_child(Kit.heading("Flintkeep", 84, Pal.GOLD))
	col.add_child(Kit.label("Hold the Keep. Build your castle.", 22, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true))
	_hero = Control.new()
	_hero.custom_minimum_size = Vector2(0, 290)
	_hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_hero.draw.connect(_draw_hero)
	col.add_child(_hero)

	var picker := Kit.hbox(10)
	var prev := Kit.button("<", Kit.Btn.SECONDARY, 30, 64)
	prev.custom_minimum_size.x = 72
	prev.pressed.connect(_change_tier.bind(-1))
	picker.add_child(prev)
	_tier_label = Kit.heading("", 38, Pal.WHITE)
	_tier_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.add_child(_tier_label)
	var next := Kit.button(">", Kit.Btn.SECONDARY, 30, 64)
	next.custom_minimum_size.x = 72
	next.pressed.connect(_change_tier.bind(1))
	picker.add_child(next)
	col.add_child(picker)
	_best_label = Kit.label("", 19, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true)
	col.add_child(_best_label)

	var play_button := Kit.button("Defend!", Kit.Btn.BUY, 44, 92)
	play_button.pressed.connect(func() -> void: play.emit(_tier))
	col.add_child(play_button)
	var row := Kit.hbox(12)
	var research_button := Kit.button("Research", Kit.Btn.PRIMARY, 30, 74)
	research_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	research_button.pressed.connect(func() -> void: research.emit())
	row.add_child(research_button)
	_missions_button = Kit.button("Missions", Kit.Btn.SECONDARY, 30, 74)
	_missions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_missions_button.pressed.connect(_open_missions)
	row.add_child(_missions_button)
	col.add_child(row)
	_lab_label = Kit.label("", 18, Pal.WHITE, Fonts.bold(), HORIZONTAL_ALIGNMENT_CENTER, true)
	col.add_child(_lab_label)
	col.add_child(Kit.spacer())
	Profile.changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	_hero.queue_redraw()
	_lab_label.text = _lab_text()


func _open_missions() -> void:
	var holder := [null]
	holder[0] = Kit.modal(self, MissionsPanel.build(func() -> void:
		holder[0].queue_free()
		_refresh()), 480)


func _open_settings() -> void:
	var holder := [null]
	holder[0] = Kit.modal(self, SettingsPanel.build(func() -> void:
		holder[0].queue_free()
		_tier = clampi(_tier, 1, Profile.data.unlocked_tier)
		_refresh()))


func _change_tier(step: int) -> void:
	_tier = clampi(_tier + step, 1, Profile.data.unlocked_tier)
	_refresh()


func _refresh() -> void:
	_coins_label.text = Num.fmt(Profile.data.coins)
	Profile.data.refresh_missions(Missions.today())
	var ready := Profile.data.claimable()
	_missions_button.text = "Missions (%d)" % ready if ready > 0 else "Missions"
	Kit.style_button(_missions_button, Kit.Btn.BUY if ready > 0 else Kit.Btn.SECONDARY, 30)
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
	var c := Vector2(_hero.size.x / 2.0, _hero.size.y - 34.0)
	var pulse := 0.85 + 0.15 * sin(_time * 2.0)
	# a grassy hill with a sandy courtyard
	_hero.draw_set_transform(c + Vector2(0, 8), 0.0, Vector2(1.0, 0.3))
	_hero.draw_circle(Vector2(0, 14), 236, Pal.GRASS_DARK.darkened(0.25))
	_hero.draw_circle(Vector2.ZERO, 236, Pal.INK)
	_hero.draw_circle(Vector2.ZERO, 231, Pal.GRASS)
	_hero.draw_circle(Vector2(0, -8), 200, Pal.GRASS_LIGHT)
	_hero.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_hero.draw_texture_rect(_glow, Rect2(c - Vector2(190, 34), Vector2(380, 70)), false, Color(Pal.SAND, 0.95))
	_hero.draw_texture_rect(_glow, Rect2(c - Vector2(150, 250), Vector2(300, 300)), false, Color(1, 1, 1, 0.22 * pulse))
	var scale := 6.4  # px per field unit
	for side in [-1.0, 1.0]:
		var name := "musket" if side < 0.0 else "cannon"
		var r := Art.rect(name, Vector2.ZERO)
		_hero.draw_texture_rect(Art.tex(name), Rect2(c + Vector2(side * 150.0, 6) + r.position * scale * 0.85, r.size * scale * 0.85), false)
	var keep := Art.rect("keep", Vector2.ZERO)
	_hero.draw_texture_rect(Art.tex("keep"), Rect2(c + keep.position * scale, keep.size * scale), false)
	var crystal := c + (keep.position + keep.size * Vector2(0.5, 0.12)) * scale
	_hero.draw_texture_rect(_glow, Rect2(crystal - Vector2(60, 60), Vector2(120, 120)), false, Color(0.5, 0.95, 1.0, 0.45 * pulse))
