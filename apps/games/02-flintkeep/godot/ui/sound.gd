extends Node
## Autoload "Sound": plays the music loop and the sound effects, and remembers the music and
## sound switches. Call it through Sfx.play("coin") so scripts compile without the autoload.

const DIR := "res://assets/audio/"
const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_DB := -15.0
const SFX_DB := -4.0
const POOL_SIZE := 16
## name -> [volume offset in dB, minimum seconds between plays]. Rapid-fire sounds are quieter
## and rate-limited so a big wave does not turn into noise.
const SOUNDS := {
	"musket": [-12.0, 0.06], "volley": [-13.0, 0.08], "cannon": [-6.0, 0.12], "sniper": [-8.0, 0.1],
	"arcane": [-10.0, 0.08], "keep": [-14.0, 0.08], "kill": [-11.0, 0.05], "coin": [-4.0, 0.08],
	"build": [0.0, 0.0], "upgrade": [-2.0, 0.0], "wall_break": [-4.0, 0.2], "wave": [-4.0, 0.0],
	"boss": [0.0, 0.0], "game_over": [0.0, 0.0], "click": [-6.0, 0.03], "denied": [-6.0, 0.1],
	"research_done": [-2.0, 0.0],
}

var music_on := true
var sfx_on := true

var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _streams := {}
var _last := {}


func _ready() -> void:
	for name in SOUNDS:
		_streams[name] = load(DIR + name + ".wav")
	var song: AudioStreamWAV = load(DIR + "music.wav")
	song.loop_mode = AudioStreamWAV.LOOP_FORWARD
	song.loop_begin = 0
	song.loop_end = song.data.size() / 2  # 16-bit mono
	_music = AudioStreamPlayer.new()
	_music.stream = song
	_music.volume_db = MUSIC_DB
	add_child(_music)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_on = cfg.get_value("audio", "music", true)
		sfx_on = cfg.get_value("audio", "sfx", true)
	_apply_music()


func _exit_tree() -> void:
	_music.stop()
	_music.stream = null
	for p in _pool:
		p.stop()
		p.stream = null
	_streams.clear()


func play(name: String, jitter: float = 0.04) -> void:
	if not sfx_on or not _streams.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var spec: Array = SOUNDS[name]
	if now - float(_last.get(name, -10.0)) < spec[1]:
		return
	_last[name] = now
	var player := _pool[0]
	for p in _pool:
		if not p.playing:
			player = p
			break
	player.stream = _streams[name]
	player.volume_db = SFX_DB + spec[0]
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.play()


func set_music(on: bool) -> void:
	music_on = on
	_apply_music()
	_save()


func set_sfx(on: bool) -> void:
	sfx_on = on
	_save()


func _apply_music() -> void:
	if DisplayServer.get_name() == "headless":
		return  # tests and tools: nothing to hear
	if music_on and not _music.playing:
		_music.play()
	elif not music_on:
		_music.stop()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sfx", sfx_on)
	cfg.save(SETTINGS_PATH)
