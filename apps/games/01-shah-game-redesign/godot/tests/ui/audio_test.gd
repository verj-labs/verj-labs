extends GdUnitTestSuite
## Sound: every file is present and sensibly sized, and the director behaves. Music and sound
## effects have separate switches.


func after_test() -> void:
	AudioDirector.set_music_enabled(true)  # never leave the user's settings switched off by a test
	AudioDirector.set_sfx_enabled(true)


func test_every_sound_effect_loads_and_has_a_sensible_length(sfx_name: String, test_parameters := [
	["throw"], ["land"], ["swoosh_out"], ["swoosh_in"], ["select"], ["click"],
	["reset"], ["skip"], ["boing"], ["ping"], ["win"], ["game_over"]
]) -> void:
	var stream: AudioStreamWAV = load("res://assets/audio/%s.wav" % sfx_name)
	assert_object(stream).is_not_null()
	assert_float(stream.get_length()).is_between(0.03, 3.0)


func test_the_music_loop_is_long_enough_to_not_feel_repetitive() -> void:
	var stream: AudioStreamWAV = load("res://assets/audio/music.wav")
	assert_float(stream.get_length()).is_greater(20.0)


func test_every_name_the_director_knows_has_a_file() -> void:
	for sfx_name: String in AudioDirector.SFX_NAMES:
		assert_bool(FileAccess.file_exists("res://assets/audio/%s.wav" % sfx_name)).is_true()


func test_music_loops_and_plays_when_music_is_on() -> void:
	AudioDirector.set_music_enabled(true)
	assert_bool(AudioDirector.is_music_playing()).is_true()
	var music: AudioStreamWAV = AudioDirector._music_player.stream
	assert_int(music.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
	assert_int(music.loop_end).is_greater(0)


func test_music_off_stops_the_music_but_effects_still_play() -> void:
	AudioDirector.set_music_enabled(false)
	assert_bool(AudioDirector.is_music_playing()).is_false()
	AudioDirector.play_sfx("land")
	var playing := 0
	for player in AudioDirector._pool:
		if player.playing:
			playing += 1
	assert_int(playing).is_equal(1)


func test_sfx_off_silences_effects_but_the_music_keeps_going() -> void:
	AudioDirector.set_sfx_enabled(true)
	AudioDirector.play_sfx("throw")
	AudioDirector.set_sfx_enabled(false)
	for player in AudioDirector._pool:
		assert_bool(player.playing).is_false()
	AudioDirector.play_sfx("throw")  # muted: must stay silent
	for player in AudioDirector._pool:
		assert_bool(player.playing).is_false()
	assert_bool(AudioDirector.is_music_playing()).is_true()


func test_unknown_effect_names_are_ignored() -> void:
	AudioDirector.play_sfx("does_not_exist")
	for player in AudioDirector._pool:
		assert_bool(player.playing).is_false()


func test_many_effects_at_once_do_not_overflow() -> void:
	for i in AudioDirector.POOL_SIZE * 2:
		AudioDirector.play_sfx("throw", 0.05)
	assert_int(AudioDirector._pool.size()).is_equal(AudioDirector.POOL_SIZE)


func test_the_music_button_follows_the_music_setting() -> void:
	var button := AudioToggle.make(AudioToggle.Kind.MUSIC)
	add_child(button)
	auto_free(button)
	AudioDirector.set_music_enabled(true)
	assert_bool(button._cross.visible).is_false()
	AudioDirector.set_music_enabled(false)
	assert_bool(button._cross.visible).is_true()
	assert_bool(AudioDirector.sfx_enabled).is_true()  # the other switch is untouched


func test_the_sfx_button_follows_the_sfx_setting() -> void:
	var button := AudioToggle.make(AudioToggle.Kind.SFX)
	add_child(button)
	auto_free(button)
	AudioDirector.set_sfx_enabled(true)
	assert_bool(button._cross.visible).is_false()
	AudioDirector.set_sfx_enabled(false)
	assert_bool(button._cross.visible).is_true()
	assert_bool(AudioDirector.music_enabled).is_true()


func test_pressing_a_toggle_flips_only_its_own_setting() -> void:
	var button := AudioToggle.make(AudioToggle.Kind.SFX)
	add_child(button)
	auto_free(button)
	button.pressed.emit()
	assert_bool(AudioDirector.sfx_enabled).is_false()
	assert_bool(AudioDirector.music_enabled).is_true()
