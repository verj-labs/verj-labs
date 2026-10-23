extends GdUnitTestSuite
## Bots only make legal moves, never cheat, and the medium bot really is better than random.


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _view(hands: Array, seat: int, pile_codes: String = "") -> PlayerView:
	var game := Game.with_hands(TestUtil.hands(hands), seat)
	if pile_codes != "":
		# Put a pile on the table by letting the previous seat play it.
		var previous := posmod(seat - 1, hands.size())
		game.current_player = previous
		var placed := game.play(previous, TestUtil.cards(pile_codes))
		assert(placed.accepted, "test setup: the previous seat must hold the pile card " + pile_codes)
	return game.view_for(seat)


func test_view_shows_own_hand_but_only_counts_for_others() -> void:
	var view := _view(["5H 9H", "6H 9S 4D", "7H 9D"], 0)
	assert_int(view.hand.size()).is_equal(2)
	assert_array(view.hand_sizes).is_equal([2, 3, 2])


# --- medium bot decisions ---------------------------------------------------------

func test_medium_goes_out_when_it_can() -> void:
	var view := _view(["9H 9S", "3H 4H 5H", "6H 7H 8H"], 0)
	var choice := MediumBot.new().choose(view)
	assert_int(choice.size).is_equal(2)


func test_medium_leads_with_its_lowest_group_in_full() -> void:
	var view := _view(["4H 4S 9H AH", "3H 5H 6H", "6S 7H 8H"], 0)
	var choice := MediumBot.new().choose(view)
	assert_int(choice.rank).is_equal(4)
	assert_int(choice.size).is_equal(2)


func test_medium_does_not_lead_a_two_when_it_has_other_cards() -> void:
	var view := _view(["2H 9H AH", "3H 5H 6H", "6S 7H 8H"], 0)
	assert_int(MediumBot.new().choose(view).rank).is_equal(9)


func test_medium_follows_with_the_cheapest_play() -> void:
	var view := _view(["8H JH KH 4D", "3H 5H 6H", "6S 7S 8S"], 0, "7S")
	# Pile is a single 7 played by seat 2 (previous seat).
	assert_int(MediumBot.new().choose(view).rank).is_equal(8)


func test_medium_avoids_breaking_a_pair_when_a_single_will_do() -> void:
	var view := _view(["8H 8S 9H 4D", "3H 5H 6H", "6S 7S 8D"], 0, "7S")
	# Single 8 would split the pair of 8s; single 9 keeps it intact.
	assert_int(MediumBot.new().choose(view).rank).is_equal(9)


func test_medium_saves_its_two_on_a_low_pile() -> void:
	var view := _view(["2H 4D 5D 6D 3D", "3H 5H 6H 8H 9H 10H", "6S 7S 8S JH QH KH"], 0, "7S")
	# Nothing in hand beats a 7 except the 2, which is not worth spending on a low pile.
	assert_object(MediumBot.new().choose(view)).is_null()


func test_medium_resets_a_high_pile_with_its_two() -> void:
	var view := _view(["2H 4D 5D 6D 7D", "3H 5H 6H 8H 9H 10H", "6S 7H 8S JH QH KS"], 0, "KS")
	var choice := MediumBot.new().choose(view)
	assert_object(choice).is_not_null()
	assert_bool(choice.is_two()).is_true()


func test_medium_spends_its_two_when_an_opponent_is_nearly_out() -> void:
	var view := _view(["2H 4D 5D 6D 7D", "3H", "6S 7H 8S JH QH KS"], 0, "KS")
	var choice := MediumBot.new().choose(view)
	assert_object(choice).is_not_null()
	assert_bool(choice.is_two()).is_true()


# --- every bot, many games --------------------------------------------------------

func test_bots_only_ever_make_legal_moves_and_games_finish(
	players: int, test_parameters := [[3], [4], [5], [8]]
) -> void:
	var rng := _rng(500 + players)
	for game_number in 40:
		var dealt := Dealer.deal(players, rng)
		var game := Game.with_hands(dealt["hands"], rng.randi_range(0, players - 1), Direction.CLOCKWISE, dealt["discarded"])
		var bots: Array[Bot] = []
		for seat in players:
			bots.append(BotFactory.create(Bot.Difficulty.EASY if seat % 2 == 0 else Bot.Difficulty.MEDIUM, rng))
		var errors: Array[String] = []
		var ranking := TestUtil.play_bot_game(game, bots, errors)
		assert_array(errors).is_empty()
		assert_int(ranking.size()).is_equal(players)


func test_medium_beats_easy_clearly() -> void:
	# One medium bot (rotating seat) against three easy bots, 4 players, 300 games.
	# A bot with no skill would win about 25% of the time.
	var rng := _rng(2024)
	var medium_wins := 0
	var games := 300
	for game_number in games:
		var medium_seat := game_number % 4
		var dealt := Dealer.deal(4, rng)
		var game := Game.with_hands(dealt["hands"], rng.randi_range(0, 3), Direction.CLOCKWISE, dealt["discarded"])
		var bots: Array[Bot] = []
		for seat in 4:
			bots.append(MediumBot.new() if seat == medium_seat else EasyBot.new(rng))
		var errors: Array[String] = []
		var ranking := TestUtil.play_bot_game(game, bots, errors)
		assert_array(errors).is_empty()
		if ranking[0] == medium_seat:
			medium_wins += 1
	assert_bool(medium_wins > games * 0.40).override_failure_message("medium won only %d of %d" % [medium_wins, games]).is_true()
