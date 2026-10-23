extends GdUnitTestSuite
## The arcade pixel font: every glyph is well-formed and covers the characters the game prints.


func test_every_glyph_is_five_by_seven() -> void:
	for key: String in PixelFont.GLYPHS:
		var rows: Array = PixelFont.GLYPHS[key]
		assert_int(rows.size()).override_failure_message("glyph '%s' must have 7 rows" % key).is_equal(7)
		for row: String in rows:
			assert_int(row.length()).override_failure_message("glyph '%s' must be 5 wide" % key).is_equal(5)


func test_the_game_text_is_fully_covered() -> void:
	var needed := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?:-+/'#%()<>=*_"
	for ch in needed:
		assert_bool(PixelFont.GLYPHS.has(ch)).override_failure_message("missing glyph '%s'" % ch).is_true()


func test_lower_case_uses_the_capital_shapes() -> void:
	var font := PixelFont.font()
	assert_bool(font.has_char("a".unicode_at(0))).is_true()
	assert_bool(font.has_char("A".unicode_at(0))).is_true()


func test_font_sizes_are_whole_multiples_of_seven() -> void:
	for scale_value in [1, 2, 3, 5, 9]:
		assert_int(PixelFont.size_for(scale_value) % 7).is_equal(0)


func test_text_width_counts_the_gaps() -> void:
	assert_int(PixelFont.text_width("AB", 2)).is_equal((6 + 5) * 2)
	assert_int(PixelFont.text_width("", 3)).is_equal(0)
