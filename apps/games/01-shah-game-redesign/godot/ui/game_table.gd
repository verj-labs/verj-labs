extends Control
## The playable table: players in a ring (you at the bottom), the pile in the middle, your hand
## underneath. Rules and bots live in core/ and bots/, timing in TableController, card
## animations in TableFx; this script wires them to the arcade-styled widgets.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const LOBBY_SCENE := "res://scenes/lobby_screen.tscn"
const BOT_NAMES := ["YOU", "ACE", "DUKE", "MIMI", "ROCCO", "ZED", "LOLA", "KIKO"]
const LOG_LINES := 2
const RESET_NOTES := ["", "A 2 RESETS", "TWO 2S: RESET!", "THREE 2S: RESET!", "FOUR 2S: RESET!"]
const ORDINALS := ["1ST", "2ND", "3RD", "4TH", "5TH", "6TH", "7TH", "8TH"]
const PLACE_COLORS := [Palette.YELLOW, Palette.CREAM, Palette.ORANGE]
const SHAKE_SECONDS := 0.28
const HEADER_HEIGHT := 64.0
const ACTION_HEIGHT := 96.0

var controller: TableSource
## Your seat (seat 0 in single player).
var _me: int = 0

var _world: Control
var _top: Control
var _ring: TableRing
var _fx: TableFx
var _layer: FxLayer
var _game_label: Label
var _direction_label: Label
var _log_label: Label
var _hint: Label
var _timer_bar: TurnTimerBar
var _timer_label: Label
var _hand: HandView
var _play_button: ArcadeButton
var _pass_button: ArcadeButton
var _overlay: Control
var _overlay_title: ShadowLabel
var _overlay_subtitle: Label
var _overlay_rows: VBoxContainer
var _next_button: ArcadeButton
var _match_over: bool = false
var _connection_banner: Label

var _log: Array[String] = []
## While set, the middle keeps showing the play that just won a round (or reset the pile).
var _held_play: Play = null
var _held_note: String = ""
var _hold_token: int = 0
var _shown_pile: Play = null
## Cards currently flying onto the pile: the middle is not redrawn until they land.
var _flights: int = 0
var _pending_origins: Array[Vector2] = []
var _exchange_active: bool = false
## Seat that reset with a 2 on their previous move (so the next 2 reads as "another reset").
var _chain_seat: int = -1


func _ready() -> void:
	_build_layout()
	_build_overlay()
	add_child(CrtOverlay.new())
	controller = _make_source()
	_me = controller.human_seat
	add_child(controller)
	controller.think_time = SessionConfig.think_seconds()
	controller.turn_seconds = SessionConfig.turn_seconds()
	controller.timed_out.connect(_on_timed_out)
	controller.human_turn_started.connect(func() -> void: AudioDirector.play_sfx("ping"))
	controller.game_started.connect(_on_game_started)
	controller.state_changed.connect(_refresh)
	controller.move_made.connect(_on_move_made)
	controller.game_finished.connect(_on_game_finished)
	controller.returned_to_lobby.connect(func() -> void: get_tree().change_scene_to_file(LOBBY_SCENE))
	controller.move_rejected.connect(_on_move_rejected)
	controller.connection_changed.connect(_on_connection_changed)
	_fx = TableFx.new()
	add_child(_fx)
	_fx.setup(_layer, _ring, _hand)
	_fx.human_seat = _me
	controller.start_next_game()


## An online match hands over its source through SessionConfig; otherwise this is a local game.
func _make_source() -> TableSource:
	if SessionConfig.online_source != null:
		var online: TableSource = SessionConfig.online_source
		SessionConfig.online_source = null  # the table owns it now
		return online
	var local := TableController.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var seat_names: Array[String] = []
	seat_names.assign(BOT_NAMES.slice(0, SessionConfig.player_count))
	local.names = seat_names
	local.setup(SessionConfig.player_count, SessionConfig.difficulty, rng)
	return local


func _process(_delta: float) -> void:
	if controller == null or controller.state == null:
		return
	var my_turn := controller.is_human_turn()
	_timer_bar.show_time(my_turn, controller.time_left / controller.turn_seconds)
	_timer_label.text = "%d" % ceili(controller.time_left) if my_turn else ""
	_timer_label.add_theme_color_override("font_color", Palette.RED if controller.time_left < 5.0 else Palette.CREAM)


# --- building the screen -----------------------------------------------------------

func _build_layout() -> void:
	_world = Control.new()
	_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_world)
	_world.add_child(ArcadeBackground.new(0.7))

	var margin := SafeMargin.new(16)
	_world.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	column.add_child(_build_header())

	_ring = TableRing.new()
	_ring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ring.custom_minimum_size = Vector2(0, 300)
	column.add_child(_ring)

	_log_label = UIKit.make_label("", 20, Palette.DIM)
	_log_label.custom_minimum_size = Vector2(0, 56)
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	column.add_child(_log_label)
	_hint = UIKit.pixel_label("", 3, Palette.CYAN, true)
	_hint.custom_minimum_size = Vector2(0, 26)
	column.add_child(_hint)
	column.add_child(_build_timer_row())

	_hand = HandView.new()
	_hand.selection_changed.connect(_refresh_buttons)
	column.add_child(_hand)
	column.add_child(_build_buttons())

	_layer = FxLayer.new()
	_world.add_child(_layer)

	_top = Control.new()
	_top.set_anchors_preset(Control.PRESET_FULL_RECT)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)


func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, HEADER_HEIGHT)
	row.add_theme_constant_override("separation", 10)
	var menu := ArcadeButton.make("MENU", ArcadeButton.Kind.SECONDARY, 3)
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.custom_minimum_size.y = HEADER_HEIGHT
	menu.pressed.connect(_leave_to_menu)
	row.add_child(menu)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_theme_constant_override("separation", 2)
	_game_label = UIKit.pixel_label("", 3, Palette.CREAM)
	_direction_label = UIKit.pixel_label("", 2, Palette.CYAN)
	titles.add_child(_game_label)
	titles.add_child(_direction_label)
	row.add_child(titles)
	row.add_child(AudioToggle.make(AudioToggle.Kind.MUSIC, HEADER_HEIGHT))
	row.add_child(AudioToggle.make(AudioToggle.Kind.SFX, HEADER_HEIGHT))
	return row


func _build_timer_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_timer_bar = TurnTimerBar.new()
	_timer_label = UIKit.pixel_label("", 3, Palette.CREAM)
	_timer_label.custom_minimum_size = Vector2(64, 0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_timer_bar)
	row.add_child(_timer_label)
	return row


func _build_buttons() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_pass_button = ArcadeButton.make("PASS", ArcadeButton.Kind.SECONDARY, 4)
	_pass_button.custom_minimum_size.y = ACTION_HEIGHT
	_pass_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pass_button.pressed.connect(func() -> void: controller.submit_pass())
	_play_button = ArcadeButton.make("PLAY", ArcadeButton.Kind.PRIMARY, 5)
	_play_button.custom_minimum_size.y = ACTION_HEIGHT
	_play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_button.size_flags_stretch_ratio = 2.0
	_play_button.pressed.connect(_on_play_pressed)
	row.add_child(_pass_button)
	row.add_child(_play_button)
	return row


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 0)
	panel.add_theme_stylebox_override("panel", Arcade.panel(Palette.PANEL, Palette.YELLOW, true, true))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	_overlay_title = ShadowLabel.new("GAME OVER", 6, Palette.RED, Palette.BG_DEEP)
	column.add_child(_overlay_title)
	_overlay_subtitle = UIKit.pixel_label("", 2, Palette.CYAN)
	column.add_child(_overlay_subtitle)
	_overlay_rows = VBoxContainer.new()
	_overlay_rows.add_theme_constant_override("separation", 8)
	column.add_child(_overlay_rows)
	_next_button = ArcadeButton.make("NEXT GAME", ArcadeButton.Kind.PRIMARY, 3)
	_next_button.pressed.connect(_on_next_pressed)
	column.add_child(_next_button)
	var menu := ArcadeButton.make("MENU", ArcadeButton.Kind.SECONDARY, 3)
	menu.pressed.connect(_leave_to_menu)
	column.add_child(menu)


# --- reacting to the game -----------------------------------------------------------

func _on_game_started() -> void:
	if not _ring.is_built():
		_ring.setup(controller.state.player_count, controller.state.names, _me)
	_overlay.visible = false
	_release_hold()
	_hand.clear_selection()
	_chain_seat = -1
	_log.clear()
	_refresh_log()
	_match_over = false
	_game_label.text = _game_title()
	var transfers := controller.exchange_transfers
	if transfers.is_empty():
		return
	_exchange_active = true
	controller.hold_for(TableFx.exchange_seconds(transfers, _me))
	_run_exchange(transfers)


func _run_exchange(transfers: Array[Dictionary]) -> void:
	_show_toast("EXCHANGE!", Palette.YELLOW, 8)
	await _fx.run_exchange(transfers, controller.dealt_hand, controller.state.my_hand)
	if not is_inside_tree():
		return
	_exchange_active = false
	for transfer in transfers:
		if transfer["from"] == _me:
			_add_log("You gave %s to %s" % [_codes(transfer["cards"]), _name(transfer["to"])])
		elif transfer["to"] == _me:
			_add_log("%s gave you %s" % [_name(transfer["from"]), _codes(transfer["cards"])])
	_refresh()


func _on_game_finished(ranking: Array[int]) -> void:
	var you_won := ranking[0] == _me
	_match_over = controller.match_over
	var champion := controller.standings[0] if _match_over and not controller.standings.is_empty() else -1
	if _match_over:
		var you_champion := champion == _me
		_overlay_title.set_text("CHAMPION!" if you_champion else "MATCH OVER")
		_overlay_title.set_colors(Palette.LIME if you_champion else Palette.YELLOW, Palette.BG_DEEP)
		_overlay_subtitle.text = "FINAL STANDINGS" if not you_champion else "YOU WON THE MATCH!"
	else:
		_overlay_title.set_text("YOU WIN!" if you_won else "GAME OVER")
		_overlay_title.set_colors(Palette.LIME if you_won else Palette.RED, Palette.BG_DEEP)
		_overlay_subtitle.text = "GAME %d OF %d" % [controller.state.game_number, controller.total_games]
	for row in _overlay_rows.get_children():
		_overlay_rows.remove_child(row)
		row.queue_free()
	_overlay_rows.add_child(_result_row("", -1, "GAME" if not _match_over else "", "TOTAL", true))
	var order: Array[int] = controller.standings if _match_over else ranking
	for place in order.size():
		var seat := order[place]
		var earned := ""
		if not _match_over:
			earned = "+%d" % ShahMatch.points_for_place(place, ranking.size())
		var total := str(controller.scores[seat]) if seat < controller.scores.size() else ""
		_overlay_rows.add_child(_result_row(ORDINALS[place], seat, earned, total, false, place))
	_set_next_button()
	AudioDirector.play_sfx("win" if (you_won and not _match_over) or champion == _me else "game_over")
	if (you_won and not _match_over) or champion == _me:
		_celebrate()
	_overlay.visible = true


func _set_next_button() -> void:
	var can_continue := controller.can_start_next_game()
	_next_button.disabled = not can_continue
	if not _match_over:
		_next_button.text = "NEXT GAME" if can_continue else "WAITING FOR HOST"
	elif controller is TableController:
		_next_button.text = "PLAY AGAIN"
	else:
		_next_button.text = "BACK TO LOBBY" if can_continue else "WAITING FOR HOST"


func _on_next_pressed() -> void:
	if not _match_over:
		controller.start_next_game()
	elif controller is TableController:
		get_tree().reload_current_scene()
	else:
		controller.return_to_lobby()


func _game_title() -> String:
	var state := controller.state
	if state.total_games > 0:
		return "GAME %d/%d" % [state.game_number, state.total_games]
	return "GAME %d" % state.game_number


## One line of the results table. `header` rows only show the column titles.
func _result_row(ordinal: String, seat: int, earned: String, total: String, header: bool, place: int = 0) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var place_color: Color = PLACE_COLORS[place] if place < PLACE_COLORS.size() else Palette.DIM
	var text_scale := 2 if header else 3
	var ordinal_label := UIKit.pixel_label(ordinal, 3, place_color)
	ordinal_label.custom_minimum_size = Vector2(56, 0)
	row.add_child(ordinal_label)
	var chip := ColorRect.new()
	chip.color = Palette.seat_color(seat) if seat >= 0 else Color.TRANSPARENT
	chip.custom_minimum_size = Vector2(20, 20)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chip)
	var player_name := _name(seat) if seat >= 0 else ""
	var name_scale := 3 if PixelFont.text_width(player_name, 3) <= 150 else 2
	var name_label := UIKit.pixel_label(player_name, name_scale, Palette.CYAN if seat == _me else Palette.CREAM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	row.add_child(name_label)
	var earned_label := UIKit.pixel_label(earned, text_scale, Palette.LIME if not header else Palette.DIM)
	earned_label.custom_minimum_size = Vector2(60, 0)
	earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(earned_label)
	var total_label := UIKit.pixel_label(total, text_scale, Palette.YELLOW if not header else Palette.DIM)
	total_label.custom_minimum_size = Vector2(72, 0)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(total_label)
	return row


func _on_move_made(seat: int, play: Play, result: MoveResult) -> void:
	_release_hold()
	_log_move(seat, play, result)
	if seat == _me:
		_hand.clear_selection()
	if play == null:
		_chain_seat = -1
		_announce(seat, null, result)
		return
	var origins: Array[Vector2] = []
	if seat == _me:
		origins = _pending_origins
	_pending_origins = []
	_flights += 1
	await _fx.throw_play(seat, play, origins)
	_flights -= 1
	if not is_inside_tree():
		return
	_announce(seat, play, result)
	_refresh()


## Effects that should appear once the cards have landed: SKIP, RESET, round won.
func _announce(seat: int, play: Play, result: MoveResult) -> void:
	if result.effect == PlayResult.Effect.SKIP:
		_show_toast("SKIP!", Palette.ORANGE, 11, 0.09)
		AudioDirector.play_sfx("skip")
	elif result.effect == PlayResult.Effect.RESET:
		var note: String = "ANOTHER RESET!" if _chain_seat == seat else RESET_NOTES[play.size]
		_chain_seat = seat
		_show_toast("RESET!", Palette.LIME, 11)
		AudioDirector.play_sfx("reset")
		_shake(14.0)
		Burst.spawn(_top, _pile_center(), [Palette.LIME, Palette.CYAN, Palette.YELLOW])
		_hold(play, note, controller.think_time)
	else:
		_chain_seat = -1
	if result.round_won_by >= 0:
		var shown := play if play != null else _shown_pile
		_hold(shown, "%s TOOK THE ROUND" % _name(result.round_won_by), controller.round_end_hold())


func _leave_to_menu() -> void:
	controller.leave()
	get_tree().change_scene_to_file(MENU_SCENE)


## The server refused a move: forget the pending animation and say why.
func _on_move_rejected(reason: String) -> void:
	_pending_origins = []
	_hint.text = reason.to_upper()
	_hint.add_theme_color_override("font_color", Palette.RED)


func _on_connection_changed(connected: bool) -> void:
	if _connection_banner == null:
		_connection_banner = UIKit.pixel_label("RECONNECTING...", 3, Palette.ORANGE)
		_top.add_child(_connection_banner)
		_connection_banner.position = Vector2(
			(size.x - PixelFont.text_width(_connection_banner.text, 3)) / 2.0,
			SafeMargin.insets(get_viewport()).y + HEADER_HEIGHT + 24.0
		)
	_connection_banner.visible = not connected


func _on_timed_out() -> void:
	_show_toast("TIME!", Palette.RED, 11)
	AudioDirector.play_sfx("boing")


func _log_move(seat: int, play: Play, result: MoveResult) -> void:
	if play == null:
		_add_log("%s passed" % _name(seat))
	elif result.effect == PlayResult.Effect.RESET:
		_add_log("%s reset the pile with %s" % [_name(seat), _describe(play)])
	else:
		_add_log("%s played %s" % [_name(seat), _describe(play)])
	if result.skipped_player >= 0:
		_add_log("%s was skipped" % _name(result.skipped_player))
	if result.round_won_by >= 0:
		_add_log("%s took the round" % _name(result.round_won_by))


func _on_play_pressed() -> void:
	_pending_origins = _hand.selected_global_centers()
	var result := controller.submit_play(_hand.selected_cards())
	if not result.accepted:
		_pending_origins = []
		_hint.text = _explain(result.reason)
		_hint.add_theme_color_override("font_color", Palette.RED)


# --- drawing the current state ------------------------------------------------------

func _refresh() -> void:
	var state := controller.state
	if state == null:
		return
	if not _ring.is_built():
		_ring.setup(state.player_count, state.names, _me)
	_ring.set_turn(state.current_player, state.direction)
	_direction_label.text = "CLOCKWISE" if state.direction == Direction.CLOCKWISE else "REVERSE"
	if not _exchange_active:
		_hand.set_cards(state.my_hand)
	_hand.interactive = controller.is_human_turn() and not _exchange_active
	_refresh_pile()
	for seat in state.player_count:
		_refresh_seat(seat)
	_refresh_buttons()


func _refresh_pile() -> void:
	if _flights > 0:
		return
	var state := controller.state
	if _held_play != null:
		_ring.pile_view.show_pile(_held_play, "", _held_note)
		return
	if state.pile != null:
		_shown_pile = state.pile
	_ring.pile_view.show_pile(state.pile, _name(state.pile_owner) if state.pile_owner >= 0 else "")


func _refresh_seat(seat: int) -> void:
	var state := controller.state
	var out := state.is_finished(seat)
	var skipped := state.is_skipped(seat)
	var is_turn := seat == state.current_player
	var status := ""
	var mode := "idle"
	if out:
		status = "OUT #%d" % (state.finished.find(seat) + 1)
		mode = "out"
	elif is_turn and skipped:
		status = "LAST CHANCE!"
		mode = "last_chance"
	elif is_turn:
		status = "YOUR TURN" if seat == _me else "Thinking..."
		mode = "turn"
	elif skipped:
		status = "SKIPPED"
		mode = "skipped"
	elif state.has_declined(seat):
		status = "Passed"
	elif seat == state.pile_owner:
		status = "On top"
	_ring.seat_view(seat).refresh(state.hand_size(seat), status, mode)


func _refresh_buttons() -> void:
	var state := controller.state
	if state == null:
		return
	var my_turn := controller.is_human_turn() and not _exchange_active
	var nothing_playable := my_turn and state.pile != null and state.legal_plays().is_empty()
	_pass_button.disabled = not (my_turn and state.pile != null)
	_pass_button.set_kind(ArcadeButton.Kind.PRIMARY if nothing_playable else ArcadeButton.Kind.SECONDARY, 4)
	_pass_button.custom_minimum_size.y = ACTION_HEIGHT
	var chosen := _hand.selected_cards()
	var verdict := _check_selection(chosen)
	_play_button.disabled = not (my_turn and verdict == "")
	_hint.add_theme_color_override("font_color", Palette.CYAN)
	_hint.text = _hint_text(state, my_turn, nothing_playable, chosen, verdict)


func _hint_text(state: TableState, my_turn: bool, nothing_playable: bool, chosen: Array[Card], verdict: String) -> String:
	if _exchange_active:
		return "SWAPPING CARDS..."
	if state.is_over():
		return ""
	if state.is_finished(_me):
		return "YOU'RE OUT! WATCHING..."
	if not my_turn:
		return "%s IS THINKING..." % _name(state.current_player)
	if nothing_playable:
		return "NOTHING TO PLAY: PASS"
	if chosen.is_empty():
		if state.is_skipped(_me):
			return "SKIPPED! PLAY OR PASS"
		return "YOUR TURN: LEAD!" if state.pile == null else "YOUR TURN: BEAT OR PASS"
	return verdict.to_upper() if verdict != "" else "READY TO PLAY!"


## "" if the selected cards can be played right now, otherwise a short reason.
func _check_selection(chosen: Array[Card]) -> String:
	if chosen.is_empty():
		return "pick cards"
	var verdict := controller.state.evaluate(Play.from_cards(chosen))
	return "" if verdict.legal else _explain(verdict.reason)


func _explain(reason: String) -> String:
	match reason:
		PlayResult.REASON_SIZE_MISMATCH:
			return "Play as many cards as the pile"
		PlayResult.REASON_RANK_TOO_LOW:
			return "Too low for the pile"
		PlayResult.REASON_INVALID_RESET:
			return "Reset needs 1 two (single or double), 2 (triple), 3 (quad)"
		_:
			return "Can't play that"


# --- effects and small helpers -------------------------------------------------------

func _name(seat: int) -> String:
	if controller != null and controller.state != null and seat < controller.state.names.size():
		return controller.state.names[seat]
	return BOT_NAMES[seat]


func _pile_center() -> Vector2:
	var pile := _ring.pile_view
	return pile.global_position + pile.size / 2.0


## "Double 9" style text for the move log.
func _describe(play: Play) -> String:
	return "%s %s" % [PileView.SIZE_NAMES[play.size].capitalize(), play.cards[0].rank_text()]


func _codes(cards: Array) -> String:
	var codes: PackedStringArray = []
	for card: Card in cards:
		codes.append(card.to_code())
	return " ".join(codes)


func _add_log(line: String) -> void:
	_log.append(line)
	while _log.size() > LOG_LINES:
		_log.pop_front()
	_refresh_log()


func _refresh_log() -> void:
	_log_label.text = "\n".join(_log)


## Keep showing `play` in the middle for `seconds`, with `note` as its caption.
func _hold(play: Play, note: String, seconds: float) -> void:
	if play == null or seconds <= 0.0:
		return
	_held_play = play
	_held_note = note
	_hold_token += 1
	var token := _hold_token
	await get_tree().create_timer(seconds).timeout
	if is_inside_tree() and token == _hold_token:
		_release_hold()
		_refresh()


func _release_hold() -> void:
	_hold_token += 1
	_held_play = null
	_held_note = ""


## A big pixel word that pops onto the screen, wobbles (optionally), then floats away.
func _show_toast(text: String, color: Color, pixel_scale: int, wobble: float = 0.0) -> void:
	var toast := ShadowLabel.new(text, pixel_scale, color, Palette.BG_DEEP)
	_top.add_child(toast)
	toast.position = (size - toast.size) / 2.0 - Vector2(0, 40)
	toast.pivot_offset = toast.size / 2.0
	toast.scale = Vector2.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(toast, "scale", Vector2.ONE * 1.18, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(toast, "scale", Vector2.ONE, 0.08)
	if wobble > 0.0:
		for sign_value in [1, -1, 1, -1]:
			tween.tween_property(toast, "rotation", wobble * sign_value, 0.07)
		tween.tween_property(toast, "rotation", 0.0, 0.05)
	else:
		tween.tween_interval(0.5)
	tween.tween_interval(0.35)
	tween.set_parallel(true)
	tween.tween_property(toast, "modulate:a", 0.0, 0.3)
	tween.tween_property(toast, "position:y", toast.position.y - 40.0, 0.3)
	tween.chain().tween_callback(toast.queue_free)


## A quick screen jolt.
func _shake(strength: float) -> void:
	var tween := create_tween()
	for i in 6:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength)) * (1.0 - i / 6.0)
		tween.tween_property(_world, "position", offset, SHAKE_SECONDS / 7.0)
	tween.tween_property(_world, "position", Vector2.ZERO, SHAKE_SECONDS / 7.0)


func _celebrate() -> void:
	var colors: Array[Color] = [Palette.YELLOW, Palette.PINK, Palette.CYAN, Palette.LIME]
	for x in [0.2, 0.5, 0.8]:
		Burst.spawn(_top, Vector2(size.x * x, size.y * 0.35), colors, 1.4)
