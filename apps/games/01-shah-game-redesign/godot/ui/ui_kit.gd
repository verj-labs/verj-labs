class_name UIKit
extends RefCounted
## Small helpers so every screen builds buttons and panels the same way.

const RADIUS := 8


static func box(fill: Color, border: Color = Palette.BORDER, border_width: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(RADIUS)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


static func style_button(btn: Button, fill: Color, text_color: Color) -> void:
	btn.add_theme_stylebox_override("normal", box(fill, fill.darkened(0.3), 2))
	btn.add_theme_stylebox_override("hover", box(fill.lightened(0.12), fill.darkened(0.3), 2))
	btn.add_theme_stylebox_override("pressed", box(fill.darkened(0.15), fill.darkened(0.4), 2))
	btn.add_theme_stylebox_override("focus", box(fill, Palette.TEXT_PRIMARY, 2))
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, text_color)
	btn.add_theme_font_size_override("font_size", 26)
	btn.custom_minimum_size = Vector2(0, 80)


static func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func primary_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	style_button(btn, Palette.ELECTRIC_YELLOW, Palette.BG_0)
	return btn


static func secondary_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	style_button(btn, Palette.SURFACE, Palette.TEXT_PRIMARY)
	return btn


## Full-screen dark background plus a padded column. Returns the column to add content to.
static func screen_column(root: Control) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Palette.BG_0
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	return column
