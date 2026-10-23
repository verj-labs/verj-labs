extends GdUnitTestSuite
## Turns, passing, skip, reset, finishing. (GAME_RULES sections 8-13)
## Hands are written out card by card so each test reads as a little story.

const NONE := PlayResult.Effect.NONE
const SKIP := PlayResult.Effect.SKIP
const RESET := PlayResult.Effect.RESET


func _game(hands: Array, start: int = 0, direction: int = Direction.CLOCKWISE) -> Game:
	return Game.with_hands(TestUtil.hands(hands), start, direction)


func _play(game: Game, seat: int, codes: String) -> MoveResult:
	return game.play(seat, TestUtil.cards(codes))


# --- basics -----------------------------------------------------------------------

func test_start_player_leads_and_turn_moves_clockwise() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"], 1)
	assert_int(game.current_player).is_equal(1)
	assert_bool(_play(game, 1, "6H").accepted).is_true()
	assert_int(game.current_player).is_equal(2)
	assert_bool(_play(game, 2, "7H").accepted).is_true()
	assert_int(game.current_player).is_equal(0)


func test_counter_clockwise_moves_the_other_way() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"], 1, Direction.COUNTER_CLOCKWISE)
	_play(game, 1, "6H")
	assert_int(game.current_player).is_equal(0)


func test_out_of_turn_is_rejected_and_changes_nothing() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"])
	var result := _play(game, 1, "6H")
	assert_bool(result.accepted).is_false()
	assert_str(result.reason).is_equal(MoveResult.REASON_NOT_YOUR_TURN)
	assert_int(game.hand_of(1).size()).is_equal(2)
	assert_int(game.current_player).is_equal(0)


func test_cannot_play_cards_you_do_not_hold() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"])
	var result := _play(game, 0, "AS")
	assert_str(result.reason).is_equal(MoveResult.REASON_CARDS_NOT_IN_HAND)


func test_cannot_play_the_same_card_twice_in_one_play() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"])
	assert_str(_play(game, 0, "5H 5H").reason).is_equal(MoveResult.REASON_CARDS_NOT_IN_HAND)


func test_mixed_ranks_are_not_a_set() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"])
	assert_str(_play(game, 0, "5H 9H").reason).is_equal(MoveResult.REASON_NOT_A_SET)


func test_rejected_by_pile_rules_keeps_the_hand() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"])
	_play(game, 0, "9H")
	var result := _play(game, 1, "6H")
	assert_str(result.reason).is_equal(PlayResult.REASON_RANK_TOO_LOW)
	assert_int(game.hand_of(1).size()).is_equal(2)
	assert_int(game.current_player).is_equal(1)


# --- passing and ending a round ---------------------------------------------------

func test_cannot_pass_on_an_empty_table() -> void:
	var game := _game(["5H 9H", "6H 9S", "7H 9D"])
	assert_str(game.pass_turn(0).reason).is_equal(MoveResult.REASON_MUST_LEAD)


func test_round_ends_when_everyone_else_passes_and_winner_leads_again() -> void:
	var game := _game(["5H 6H 9H", "6S 9S", "7S 9D"])
	_play(game, 0, "5H")
	assert_bool(game.pass_turn(1).accepted).is_true()
	var result := game.pass_turn(2)
	assert_int(result.round_won_by).is_equal(0)
	assert_object(game.pile).is_null()
	assert_int(game.current_player).is_equal(0)


func test_a_new_play_resets_the_pass_count() -> void:
	# 0 plays, 1 passes, 2 beats it: 1 must get another chance, so the round is not over.
	var game := _game(["5H 6H 9H", "6S 9S", "7S 9D"])
	_play(game, 0, "5H")
	game.pass_turn(1)
	var result := _play(game, 2, "7S")
	assert_int(result.round_won_by).is_equal(-1)
	assert_int(game.current_player).is_equal(0)
	game.pass_turn(0)
	assert_int(game.current_player).is_equal(1)


func test_passing_does_not_lock_you_out_of_later_rounds() -> void:
	var game := _game(["5H 6H 9H", "6S 9S 10S", "7S 9D JD"])
	_play(game, 0, "5H")
	game.pass_turn(1)
	game.pass_turn(2)
	assert_int(game.current_player).is_equal(0)
	_play(game, 0, "6H")
	assert_bool(_play(game, 1, "6S").accepted).is_true()


# --- skip -------------------------------------------------------------------------

func test_same_rank_skips_the_next_player() -> void:
	# 4 players. 0 plays 8; 1 and 2 pass would end... so instead 1 plays 9, 2 plays 9 (skip 3).
	var game := _game(["8H 3H", "9H 4H", "9S 5H", "6H 7H"])
	_play(game, 0, "8H")
	_play(game, 1, "9H")
	var result := _play(game, 2, "9S")
	assert_int(result.effect).is_equal(SKIP)
	# Seat 3 is skipped, so it is seat 0's turn.
	assert_int(game.current_player).is_equal(0)


func test_skipped_player_gets_a_last_chance_before_the_round_is_won() -> void:
	# 0 plays 8, 1 plays 8 (skips 2), 0 passes. Everyone else is done, but seat 2 never got a
	# turn, so they are offered one. When they pass, seat 1 wins the round.
	var game := _game(["8H 3H 4H", "8S 5H 6H", "7H 9H 10H"])
	_play(game, 0, "8H")
	var skip := _play(game, 1, "8S")
	assert_int(skip.effect).is_equal(SKIP)
	assert_int(skip.skipped_player).is_equal(2)
	assert_bool(game.is_skipped(2)).is_true()
	assert_int(game.current_player).is_equal(0)
	var offered := game.pass_turn(0)
	assert_int(offered.round_won_by).is_equal(-1)
	assert_int(game.current_player).is_equal(2)
	assert_object(game.pile).is_not_null()
	var result := game.pass_turn(2)
	assert_int(result.round_won_by).is_equal(1)
	assert_int(game.current_player).is_equal(1)
	assert_object(game.pile).is_null()
	assert_bool(game.is_skipped(2)).is_false()


func test_last_chance_player_may_play_and_the_round_continues() -> void:
	var game := _game(["8H 3H 4H", "8S 5H 6H", "9S 9H 10H"])
	_play(game, 0, "8H")
	_play(game, 1, "8S")
	game.pass_turn(0)
	assert_int(game.current_player).is_equal(2)
	var result := _play(game, 2, "9S")
	assert_bool(result.accepted).is_true()
	assert_int(result.round_won_by).is_equal(-1)
	assert_int(game.pile_owner).is_equal(2)
	assert_int(game.current_player).is_equal(0)


func test_example_one_six_players_skipped_player_is_offered_a_turn() -> void:
	# p1 plays 5, p2 plays 5 (p3 skipped), everyone else passes -> p3 may play before p2 wins.
	var game := _game(["5H 9H", "5S 9S", "6H 9D", "7H 9C", "8H 10H", "8S 10S"])
	_play(game, 0, "5H")
	var skip := _play(game, 1, "5S")
	assert_int(skip.skipped_player).is_equal(2)
	assert_int(game.current_player).is_equal(3)
	game.pass_turn(3)
	game.pass_turn(4)
	game.pass_turn(5)
	game.pass_turn(0)
	assert_int(game.current_player).is_equal(2)
	assert_int(game.pile_owner).is_equal(1)
	assert_bool(_play(game, 2, "6H").accepted).is_true()
	# Round continues normally from the player after p3.
	assert_int(game.current_player).is_equal(3)
	assert_int(game.pile_owner).is_equal(2)


func test_example_two_only_the_last_skipped_player_is_offered_a_turn() -> void:
	# p1 5, p2 5 (p3 skipped), p4 6, p5 6 (p6 skipped). p1..p4 pass. p3 already had a normal turn
	# (their pass), so only p6 is offered a turn before p5 wins.
	var game := _game(["5H 9H", "5S 9S", "3H 9D", "6H 9C", "6S 10H", "4H 10S"])
	_play(game, 0, "5H")
	_play(game, 1, "5S")
	assert_bool(game.is_skipped(2)).is_true()
	_play(game, 3, "6H")
	var skip := _play(game, 4, "6S")
	assert_bool(game.is_skipped(2)).is_false()  # only the last skipped player is marked
	assert_int(skip.skipped_player).is_equal(5)
	assert_int(game.current_player).is_equal(0)
	game.pass_turn(0)
	game.pass_turn(1)
	game.pass_turn(2)
	assert_bool(game.is_skipped(2)).is_false()
	var last := game.pass_turn(3)
	assert_int(last.round_won_by).is_equal(-1)
	assert_int(game.current_player).is_equal(5)
	var result := game.pass_turn(5)
	assert_int(result.round_won_by).is_equal(4)
	assert_int(game.current_player).is_equal(4)
	assert_object(game.pile).is_null()


func test_skipped_player_does_not_get_a_turn() -> void:
	var game := _game(["8H 3H", "8S 4H", "5H 9H", "6H 9S"])
	_play(game, 0, "8H")
	_play(game, 1, "8S")
	# Seat 2 is skipped, so it is seat 3's turn.
	assert_int(game.current_player).is_equal(3)


func test_skip_with_two_players_left_still_offers_the_skipped_player_a_turn() -> void:
	# Seat 2 finishes first. 0 plays 8 and 1 plays 8: 0 is skipped, but being the only other
	# player they are offered a turn before seat 1 wins the round.
	var game := _game(["8H 3H", "8S 4H", "5H"], 2)
	_play(game, 2, "5H")
	assert_bool(game.is_finished(2)).is_true()
	assert_int(game.current_player).is_equal(0)
	_play(game, 0, "8H")
	var result := _play(game, 1, "8S")
	assert_int(result.round_won_by).is_equal(-1)
	assert_int(game.current_player).is_equal(0)
	var won := game.pass_turn(0)
	assert_int(won.round_won_by).is_equal(1)
	assert_int(game.current_player).is_equal(1)
	assert_object(game.pile).is_null()


# --- the 2 reset ------------------------------------------------------------------

func test_reset_clears_the_pile_and_the_same_player_leads_again() -> void:
	var game := _game(["9H 2S 4H", "10H 5H", "JH 6H"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	var result := _play(game, 0, "2S")
	assert_int(result.effect).is_equal(RESET)
	assert_object(game.pile).is_null()
	assert_int(game.current_player).is_equal(0)


func test_after_a_reset_the_player_must_lead_not_pass() -> void:
	var game := _game(["9H 2S 4H", "10H 5H", "JH 6H"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	_play(game, 0, "2S")
	assert_str(game.pass_turn(0).reason).is_equal(MoveResult.REASON_MUST_LEAD)
	assert_bool(_play(game, 0, "4H").accepted).is_true()


func test_two_resets_in_a_row_then_a_normal_lead() -> void:
	# Seat 0 holds 2S and 2H. Pile: single 9. Reset (2S), lead single 3, others beat it,
	# seat 0 resets again (2H) and finally leads their last card.
	var game := _game(["9H 2S 2H 3H 4H", "10H 5H 7S", "JH 6H 8S"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	assert_int(_play(game, 0, "2S").effect).is_equal(RESET)
	_play(game, 0, "3H")
	_play(game, 1, "5H")
	_play(game, 2, "6H")
	assert_int(_play(game, 0, "2H").effect).is_equal(RESET)
	assert_object(game.pile).is_null()
	assert_bool(_play(game, 0, "4H").accepted).is_true()


func test_reset_that_empties_the_hand_finishes_and_next_player_leads() -> void:
	var game := _game(["9H 2S", "10H 4H", "JH 5H"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	var result := _play(game, 0, "2S")
	assert_bool(result.player_finished).is_true()
	assert_int(game.finished[0]).is_equal(0)
	assert_object(game.pile).is_null()
	assert_int(game.current_player).is_equal(1)


func test_wrong_two_play_is_rejected() -> void:
	var game := _game(["9H 9S 2S 2H", "10H 10S 4D", "JH JS 4C"])
	_play(game, 0, "9H 9S")
	_play(game, 1, "10H 10S")
	_play(game, 2, "JH JS")
	assert_str(_play(game, 0, "2S 2H").reason).is_equal(PlayResult.REASON_INVALID_RESET)


# --- finishing --------------------------------------------------------------------

func test_player_who_empties_their_hand_is_skipped_from_then_on() -> void:
	var game := _game(["5H", "6H 9H", "7H 9S", "8H 9D"], 0)
	var result := _play(game, 0, "5H")
	assert_bool(result.player_finished).is_true()
	assert_int(game.finished[0]).is_equal(0)
	_play(game, 1, "6H")
	_play(game, 2, "7H")
	_play(game, 3, "8H")
	# Seat 0 is out, so after seat 3 it is seat 1 again (round not over: 1 has not passed).
	assert_int(game.current_player).is_equal(1)


func test_round_winner_who_finished_hands_the_lead_to_the_next_active_player() -> void:
	var game := _game(["5H", "6H 9H", "7H 9S", "8H 9D"], 0)
	_play(game, 0, "5H")  # seat 0 finishes with the pile on the table
	game.pass_turn(1)
	game.pass_turn(2)
	var result := game.pass_turn(3)
	assert_int(result.round_won_by).is_equal(0)
	assert_int(game.current_player).is_equal(1)
	assert_object(game.pile).is_null()


func test_game_ends_when_one_player_is_left_and_they_are_last() -> void:
	var game := _game(["5H", "6H", "7H 9H"], 0)
	_play(game, 0, "5H")
	var result := _play(game, 1, "6H")
	assert_bool(result.game_over).is_true()
	assert_bool(game.is_over()).is_true()
	assert_int(game.current_player).is_equal(-1)
	var ranking := game.ranking()
	assert_int(ranking[0]).is_equal(0)
	assert_int(ranking[1]).is_equal(1)
	assert_int(ranking[2]).is_equal(2)


func test_nothing_can_be_played_after_the_game_is_over() -> void:
	var game := _game(["5H", "6H", "7H 9H"], 0)
	_play(game, 0, "5H")
	_play(game, 1, "6H")
	assert_str(_play(game, 2, "7H").reason).is_equal(MoveResult.REASON_GAME_OVER)
	assert_str(game.pass_turn(2).reason).is_equal(MoveResult.REASON_GAME_OVER)


# --- legal plays ------------------------------------------------------------------

func test_legal_plays_on_an_empty_table_include_every_set_size() -> void:
	var game := _game(["7H 7S 9D", "3H 3S", "4H 4S"])
	var plays := game.legal_plays(0)
	var labels: Array[String] = []
	for p in plays:
		labels.append("%d x %d" % [p.size, p.rank])
	assert_array(labels).contains_exactly(["1 x 7", "2 x 7", "1 x 9"])


func test_legal_plays_respect_the_pile() -> void:
	var game := _game(["5H 9H 9S 2D", "6H 6S", "7H 7S"])
	_play(game, 0, "5H")
	_play(game, 1, "6H")
	# Seat 2 faces a single 6. Legal: single 7. Nothing else.
	var plays := game.legal_plays(2)
	assert_int(plays.size()).is_equal(1)
	assert_int(plays[0].rank).is_equal(7)
	assert_int(plays[0].size).is_equal(1)


# --- 2s are always a reset ---------------------------------------------------------

func test_scenario_one_three_twos_chain_then_play_anything() -> void:
	# Seat 0 holds three 2s. Pile: single 9 (then beaten twice so it is seat 0's turn again).
	var game := _game(["9H 2S 2H 2D 3H 4H", "10H 5H 7S", "JH 6H 8S"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	assert_int(_play(game, 0, "2S").effect).is_equal(RESET)
	assert_object(game.pile).is_null()
	assert_int(game.current_player).is_equal(0)
	assert_int(_play(game, 0, "2H").effect).is_equal(RESET)
	assert_int(game.current_player).is_equal(0)
	# Now they can play anything...
	var lead := _play(game, 0, "3H")
	assert_int(lead.effect).is_equal(NONE)
	assert_int(game.pile.rank).is_equal(3)


func test_scenario_one_reset_again_then_play_anything() -> void:
	var game := _game(["9H 2S 2H 2D 3H 4H", "10H 5H 7S", "JH 6H 8S"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	_play(game, 0, "2S")
	_play(game, 0, "2H")
	assert_int(_play(game, 0, "2D").effect).is_equal(RESET)
	assert_int(game.hand_of(0).size()).is_equal(2)
	assert_bool(_play(game, 0, "4H").accepted).is_true()
	assert_int(game.pile.rank).is_equal(4)


func test_scenario_two_last_card_a_two_takes_the_player_out_and_the_next_leads() -> void:
	var game := _game(["9H 2S", "10H 4H 2H", "JH 5H"])
	_play(game, 0, "9H")
	_play(game, 1, "10H")
	_play(game, 2, "JH")
	var result := _play(game, 0, "2S")
	assert_bool(result.player_finished).is_true()
	assert_int(result.effect).is_equal(RESET)
	assert_object(game.pile).is_null()
	# Seat 0 is out and cannot play again; the next player leads anything.
	assert_int(game.current_player).is_equal(1)
	assert_str(_play(game, 0, "2S").reason).is_equal(MoveResult.REASON_NOT_YOUR_TURN)
	assert_bool(_play(game, 1, "4H").accepted).is_true()


func test_a_two_never_stays_on_the_table(
	codes: String, test_parameters := [["2S"], ["2S 2H"], ["2S 2H 2D"]]
) -> void:
	var game := _game(["2S 2H 2D 4H", "5H 6H", "7H 8H"])
	var result := _play(game, 0, codes)
	assert_int(result.effect).is_equal(RESET)
	assert_object(game.pile).is_null()
	assert_int(game.current_player).is_equal(0)


func test_a_player_holding_only_twos_can_always_go_out() -> void:
	var game := _game(["2S 2H", "5H 6H", "7H 8H"])
	var result := _play(game, 0, "2S")
	assert_int(game.current_player).is_equal(0)
	assert_bool(_play(game, 0, "2H").player_finished).is_true()
	assert_bool(game.is_finished(0)).is_true()
	assert_int(game.current_player).is_equal(1)


# --- only one skipped player ----------------------------------------------------------

func test_a_new_skip_replaces_the_previous_skipped_mark() -> void:
	var game := _game(["5H 9H", "5S 9S", "3H 9D", "6H 9C", "6S 10H", "4H 10S"])
	_play(game, 0, "5H")
	_play(game, 1, "5S")
	assert_bool(game.is_skipped(2)).is_true()
	_play(game, 3, "6H")
	_play(game, 4, "6S")
	assert_bool(game.is_skipped(5)).is_true()
	assert_bool(game.is_skipped(2)).is_false()
