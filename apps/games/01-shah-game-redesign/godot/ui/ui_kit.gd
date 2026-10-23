class_name UIKit
extends RefCounted
## Small helpers so every screen builds labels, buttons and layouts the same way.


## A normal (clean, readable) text label.
static func make_label(text: String, size: int, color: Color, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return label


## An arcade pixel-font label. `pixel_scale` 2 = 14px text, 3 = 21px, 5 = 35px ...
static func pixel_label(text: String, pixel_scale: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	PixelFont.apply(label, pixel_scale, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return label


static func primary_button(text: String) -> ArcadeButton:
	return ArcadeButton.make(text, ArcadeButton.Kind.PRIMARY)


static func secondary_button(text: String) -> ArcadeButton:
	return ArcadeButton.make(text, ArcadeButton.Kind.SECONDARY)


static func spacer(expand_ratio: float = 1.0) -> Control:
	var node := Control.new()
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.size_flags_stretch_ratio = expand_ratio
	return node


## Adds the backdrop and CRT overlay to `root` and returns a padded column for content.
static func screen_column(root: Control, background_intensity: float = 1.0) -> VBoxContainer:
	root.add_child(ArcadeBackground.new(background_intensity))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	root.add_child(CrtOverlay.new())
	return column
