class_name ArcadeConfirm
extends Control
## A yes/no pop-up in the arcade style: dimmed backdrop, title, text and two buttons. The safe
## choice (`cancel_label`) is the big yellow one; the risky one is red and underneath.

signal confirmed
signal cancelled


func _init(title: String, body: String, confirm_label: String, cancel_label: String = "STAY", accent: Color = Palette.ORANGE) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", Arcade.panel(Palette.PANEL, accent, true, true))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	column.add_child(ShadowLabel.new(title, 4, accent, Palette.BG_DEEP))
	var text := UIKit.make_label(body, 22, Palette.CREAM)
	column.add_child(text)
	var stay := ArcadeButton.make(cancel_label, ArcadeButton.Kind.PRIMARY, 4)
	stay.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free()
	)
	column.add_child(stay)
	var leave := ArcadeButton.make(confirm_label, ArcadeButton.Kind.DANGER, 3)
	leave.pressed.connect(func() -> void:
		confirmed.emit()
		queue_free()
	)
	column.add_child(leave)
