extends Control
## Placeholder table. The rules engine and card UI land here next.


func _ready() -> void:
	var column := UIKit.screen_column(self)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	column.add_child(UIKit.make_label("TABLE", 64, Palette.NEON_LIME))
	column.add_child(UIKit.make_label("Game coming soon.", 28, Palette.TEXT_MUTED))

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer2)

	var back := UIKit.secondary_button("BACK TO MENU")
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	column.add_child(back)
