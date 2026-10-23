class_name ArcadeModal
extends Control
## A pop-up panel in the arcade style: dimmed backdrop, title, text, and an OK button.

signal closed


func _init(title: String, body: String, accent: Color = Palette.CYAN, button_label: String = "OK") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", Arcade.panel(Palette.PANEL, accent, true, true))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)
	column.add_child(ShadowLabel.new(title, 4, accent, Palette.BG_DEEP))
	var text := UIKit.make_label(body, 24, Palette.CREAM)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(text)
	var ok := ArcadeButton.make(button_label, ArcadeButton.Kind.PRIMARY)
	ok.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	column.add_child(ok)
