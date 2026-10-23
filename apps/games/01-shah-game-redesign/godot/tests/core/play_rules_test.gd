extends GdUnitTestSuite
## Beating the pile, skip, and the 2-reset. (GAME_RULES sections 8-10 and 12)

const NONE := PlayResult.Effect.NONE
const SKIP := PlayResult.Effect.SKIP
const RESET := PlayResult.Effect.RESET


func _legal(pile: String, play: String) -> PlayResult:
	var pile_play: Play = TestUtil.play(pile) if pile != "" else null
	return PlayRules.evaluate(pile_play, TestUtil.play(play))


# --- Section 8: starting a round --------------------------------------------------

func test_any_set_may_start_a_round(
	play: String,
	test_parameters := [["3H"], ["AH"], ["9H 9S"], ["4H 4S 4D"], ["AH AS AD AC"]]
) -> void:
	var result := _legal("", play)
	assert_bool(result.legal).is_true()
	assert_int(result.effect).is_equal(NONE)


func test_twos_on_an_empty_table_are_a_reset_not_a_card(
	play: String, test_parameters := [["2H"], ["2H 2S"], ["2H 2S 2D"], ["2H 2S 2D 2C"]]
) -> void:
	var result := _legal("", play)
	assert_bool(result.legal).is_true()
	assert_int(result.effect).is_equal(RESET)


# --- Section 9: beating the pile --------------------------------------------------

func test_higher_rank_same_size_is_legal() -> void:
	var result := _legal("9H 9S", "10H 10S")
	assert_bool(result.legal).is_true()
	assert_int(result.effect).is_equal(NONE)


func test_ace_beats_king() -> void:
	assert_bool(_legal("KH", "AH").legal).is_true()


func test_lower_rank_is_rejected() -> void:
	var result := _legal("9H", "8H")
	assert_bool(result.legal).is_false()
	assert_str(result.reason).is_equal(PlayResult.REASON_RANK_TOO_LOW)


func test_size_must_match(
	pile: String,
	play: String,
	test_parameters := [
		["7H", "9H 9S"],
		["7H 7S", "9H"],
		["7H 7S", "9H 9S 9D"],
		["7H 7S 7D", "9H 9S"],
		["7H 7S 7D 7C", "9H 9S 9D"],
	]
) -> void:
	var result := _legal(pile, play)
	assert_bool(result.legal).is_false()
	assert_str(result.reason).is_equal(PlayResult.REASON_SIZE_MISMATCH)


func test_size_is_checked_before_rank() -> void:
	# Wrong size AND lower rank: the size problem is reported.
	assert_str(_legal("9H 9S", "4H").reason).is_equal(PlayResult.REASON_SIZE_MISMATCH)


# --- Section 10: skip on same rank ------------------------------------------------

func test_same_rank_is_legal_and_skips_the_next_player(
	pile: String,
	play: String,
	test_parameters := [
		["8H", "8S"],
		["QH QS", "QD QC"],
		["5H 5S 5D", "5C 5H 5S"],
		["AH AS AD AC", "AH AS AD AC"],
	]
) -> void:
	var result := _legal(pile, play)
	assert_bool(result.legal).is_true()
	assert_int(result.effect).is_equal(SKIP)


func test_same_rank_but_different_size_is_not_a_skip() -> void:
	var result := _legal("8H", "8S 8D")
	assert_bool(result.legal).is_false()


func test_higher_rank_does_not_skip() -> void:
	assert_int(_legal("8H", "9H").effect).is_equal(NONE)


# --- Section 12: the 2 reset ------------------------------------------------------

func test_reset_table_from_rules_12_1(
	pile: String,
	two: String,
	test_parameters := [
		["10H", "2S"],  # single -> single 2
		["KH KS", "2S"],  # double -> single 2
		["7H 7S 7D", "2H 2S"],  # triple -> double 2
		["9H 9S 9D 9C", "2H 2S 2D"],  # quad -> triple 2
	]
) -> void:
	var result := _legal(pile, two)
	assert_bool(result.legal).is_true()
	assert_int(result.effect).is_equal(RESET)


func test_wrong_number_of_twos_is_not_a_reset(
	pile: String,
	two: String,
	test_parameters := [
		["10H", "2H 2S"],  # single needs exactly one 2
		["KH KS", "2H 2S"],  # double needs exactly one 2
		["7H 7S 7D", "2H"],  # triple needs two 2s
		["7H 7S 7D", "2H 2S 2D"],  # ... not three
		["9H 9S 9D 9C", "2H 2S"],  # quad needs three 2s
		["9H 9S 9D 9C", "2H 2S 2D 2C"],  # ... not four
	]
) -> void:
	var result := _legal(pile, two)
	assert_bool(result.legal).is_false()
	assert_str(result.reason).is_equal(PlayResult.REASON_INVALID_RESET)


func test_a_two_never_beats_by_rank() -> void:
	# A double 2 is not "a double that outranks double A". Only the reset table applies.
	assert_bool(_legal("AH AS", "2H 2S").legal).is_false()
