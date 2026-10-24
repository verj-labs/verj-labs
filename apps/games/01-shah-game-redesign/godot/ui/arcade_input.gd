class_name ArcadeInput
extends LineEdit
## A text box in the arcade style: chunky border that lights up when focused.


## `pixel` uses the pixel font (names, codes); off uses the clean font (web addresses).
static func make(placeholder: String, max_chars: int, pixel: bool = true, uppercase: bool = false) -> ArcadeInput:
	var input := ArcadeInput.new()
	input.placeholder_text = placeholder
	input.max_length = max_chars
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.custom_minimum_size = Vector2(0, 72)
	input.add_theme_stylebox_override("normal", Arcade.compact_panel(Palette.BG_DEEP, Palette.LINE))
	input.add_theme_stylebox_override("focus", Arcade.compact_panel(Palette.BG_DEEP, Palette.YELLOW))
	input.add_theme_stylebox_override("read_only", Arcade.compact_panel(Palette.BG_DEEP, Palette.LINE))
	if pixel:
		PixelFont.apply(input, 3, Palette.CREAM)
	else:
		input.add_theme_font_size_override("font_size", 22)
		input.add_theme_color_override("font_color", Palette.CREAM)
	input.add_theme_color_override("font_placeholder_color", Palette.DIM.darkened(0.2))
	input.add_theme_color_override("caret_color", Palette.YELLOW)
	input.add_theme_color_override("selection_color", Palette.PANEL_LIGHT)
	if uppercase:
		input.text_changed.connect(func(text: String) -> void:
			var caret := input.caret_column
			input.text = text.to_upper()
			input.caret_column = caret
		)
	return input
