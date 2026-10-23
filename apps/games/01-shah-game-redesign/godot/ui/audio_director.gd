extends Node
## Autoload (see project.godot): plays the background music and all sound effects.
## Music and sound effects have separate on/off switches that are remembered between runs.
## Use AudioDirector.play_sfx("throw") from anywhere.

signal music_enabled_changed(enabled: bool)
signal sfx_enabled_changed(enabled: bool)

const AUDIO_DIR := "res://assets/audio/"
const SFX_NAMES := [
	"throw", "land", "swoosh_out", "swoosh_in", "select", "click",
	"reset", "skip", "boing", "ping", "win", "game_over",
]
const MUSIC_NAME := "music"
const MUSIC_DB := -17.0
const SFX_DB := -5.0
const POOL_SIZE := 12
const SETTINGS_PATH := "user://settings.cfg"

var music_enabled: bool = true
var sfx_enabled: bool = true

var _music_player: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func _ready() -> void:
	for sfx_name: String in SFX_NAMES:
		_streams[sfx_name] = load(AUDIO_DIR + sfx_name + ".wav")
	var music: AudioStreamWAV = load(AUDIO_DIR + MUSIC_NAME + ".wav")
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = music.data.size() / 2  # 16-bit mono: 2 bytes per sample
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = music
	_music_player.volume_db = MUSIC_DB
	add_child(_music_player)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = SFX_DB
		add_child(player)
		_pool.append(player)
	_load_settings()
	_apply_music()


func _exit_tree() -> void:
	# Let go of the sounds so Godot does not report them as leaked at shutdown.
	_music_player.stream = null
	for player in _pool:
		player.stream = null
	_streams.clear()


## `jitter` randomises the pitch a little (0.05 = up to 5%) so repeats do not sound robotic.
func play_sfx(sfx_name: String, jitter: float = 0.0, volume_db: float = 0.0) -> void:
	if not sfx_enabled or not _streams.has(sfx_name):
		return
	var player := _free_player()
	player.stream = _streams[sfx_name]
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.volume_db = SFX_DB + volume_db
	player.play()


## Plays a sound after a delay (used to line sounds up with staggered card flights).
func play_sfx_after(delay: float, sfx_name: String, jitter: float = 0.0, volume_db: float = 0.0) -> void:
	if delay <= 0.0:
		play_sfx(sfx_name, jitter, volume_db)
		return
	get_tree().create_timer(delay).timeout.connect(func() -> void: play_sfx(sfx_name, jitter, volume_db))


func set_music_enabled(value: bool) -> void:
	if value == music_enabled:
		return
	music_enabled = value
	_apply_music()
	_save_settings()
	music_enabled_changed.emit(music_enabled)


func set_sfx_enabled(value: bool) -> void:
	if value == sfx_enabled:
		return
	sfx_enabled = value
	if not sfx_enabled:
		for player in _pool:
			player.stop()
	_save_settings()
	sfx_enabled_changed.emit(sfx_enabled)


func is_music_playing() -> bool:
	return _music_player.playing


func _apply_music() -> void:
	if music_enabled and not _music_player.playing:
		_music_player.play()
	elif not music_enabled:
		_music_player.stop()


func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return _pool[0]  # all busy: steal the first


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_enabled = config.get_value("audio", "music", true)
		sfx_enabled = config.get_value("audio", "sfx", true)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_enabled)
	config.set_value("audio", "sfx", sfx_enabled)
	config.save(SETTINGS_PATH)
