class_name UIKit
extends RefCounted
## Small helpers so every screen builds labels, buttons and layouts the same way.
## The layout is 540 units wide (about 0.73 pt per unit on a 393 pt phone), so a 44 pt touch
## target is roughly 60 units and the smallest readable pixel text is scale 3.

const SCREEN_PADDING := 28


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


## Adds the backdrop and CRT overlay to `root` and returns a padded column for content that
## stays clear of the notch and home bar. `scrollable` lets a tall screen scroll on a short phone;
## the column then has a "footer" meta (a VBoxContainer pinned below the scroll area) for the
## buttons that must always stay reachable.
static func screen_column(root: Control, background_intensity: float = 1.0, scrollable: bool = false) -> VBoxContainer:
	root.add_child(ArcadeBackground.new(background_intensity))
	var margin := SafeMargin.new(SCREEN_PADDING)
	root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	if scrollable:
		var outer := VBoxContainer.new()
		outer.add_theme_constant_override("separation", 12)
		margin.add_child(outer)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		outer.add_child(scroll)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(column)
		var footer := VBoxContainer.new()
		footer.add_theme_constant_override("separation", 12)
		outer.add_child(footer)
		column.set_meta("footer", footer)
	else:
		margin.add_child(column)
	root.add_child(CrtOverlay.new())
	return column
