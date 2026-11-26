extends Control
## Root of the game: swaps between the menu, a battle and the research screen.

var _screen: Control
var _last_tier := 1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Kit.theme()
	show_menu()


func show_menu() -> void:
	Sfx.music("menu")
	var menu := MenuScreen.new()
	menu.play.connect(show_battle)
	menu.research.connect(show_research)
	_swap(menu)


func show_battle(tier: int) -> void:
	_last_tier = tier
	Sfx.music("battle")
	var battle := BattleScreen.new(tier)
	battle.finished.connect(_after_battle)
	_swap(battle)


func show_research() -> void:
	var research := ResearchScreen.new()
	research.back.connect(show_menu)
	_swap(research)


func _after_battle(goto: String) -> void:
	match goto:
		"again": show_battle(_last_tier)
		"research": show_research()
		_: show_menu()


func _swap(screen: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
