extends Node
## Autoload "Sound": plays the music and the sound effects, and remembers the music and sound
## switches. Call it through Sfx.play("coin") / Sfx.music("battle") so scripts compile without
## the autoload.
##
## Music: a menu theme, a battle theme with a drum layer that fades in as the battle gets
## tougher (set_intensity), and a boss theme that takes over while a boss is on the field.
## Tracks crossfade; the battle theme and its drums always play in sync.

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

var _tracks := {}  ## "menu", "battle", "drums", "boss" -> AudioStreamPlayer
var _want := {}  ## track -> target volume 0..1
var _level := {}  ## track -> current volume 0..1
var _scene := "menu"
var _intensity := 0.0
var _boss := false
const FADE_PER_SECOND := 0.8
var _pool: Array[AudioStreamPlayer] = []
var _streams := {}
var _last := {}


func _ready() -> void:
	for name in SOUNDS:
		_streams[name] = load(DIR + name + ".wav")
	for track in ["menu", "battle", "drums", "boss"]:
		var player := AudioStreamPlayer.new()
		player.stream = load(DIR + "music_%s.wav" % track)  # looping is set at import
		player.volume_db = -80.0
		add_child(player)
		_tracks[track] = player
		_want[track] = 0.0
		_level[track] = 0.0
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
	for player in _tracks.values():
		player.stop()
		player.stream = null
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
	_update_targets()
	_save()


func set_sfx(on: bool) -> void:
	sfx_on = on
	_save()


## Which music fits: "menu" or "battle".
func music(scene: String) -> void:
	_scene = scene
	if scene != "battle":
		_intensity = 0.0
		_boss = false
	_update_targets()


## 0..1: how tense the battle is (the drum layer follows it).
func set_intensity(value: float) -> void:
	_intensity = clampf(value, 0.0, 1.0)
	_update_targets()


func set_boss(on: bool) -> void:
	if on != _boss:
		_boss = on
		_update_targets()


func _update_targets() -> void:
	for track in _want:
		_want[track] = 0.0
	if _scene == "battle":
		_want["battle"] = 0.0 if _boss else 1.0
		_want["drums"] = 0.0 if _boss else _intensity
		_want["boss"] = 1.0 if _boss else 0.0
	else:
		_want["menu"] = 1.0
	_apply_music()


func _process(delta: float) -> void:
	for track in _tracks:
		var target: float = _want[track] if music_on else 0.0
		_level[track] = move_toward(_level[track], target, delta * FADE_PER_SECOND)
		var player: AudioStreamPlayer = _tracks[track]
		player.volume_db = linear_to_db(maxf(_level[track], 0.0001)) + MUSIC_DB
		if _level[track] <= 0.0001 and target <= 0.0 and player.playing and track != "drums":
			player.stop()


func _apply_music() -> void:
	if DisplayServer.get_name() == "headless":
		return  # tests and tools: nothing to hear
	if not music_on:
		return
	for track in _tracks:
		var player: AudioStreamPlayer = _tracks[track]
		if _want[track] > 0.0 and not player.playing:
			if track == "battle" or track == "drums":
				_start_in_sync()
			else:
				player.play()


## The battle theme and its drum layer start together so they stay in time.
func _start_in_sync() -> void:
	var battle: AudioStreamPlayer = _tracks["battle"]
	var drums: AudioStreamPlayer = _tracks["drums"]
	if battle.playing and drums.playing:
		return
	var at := battle.get_playback_position() if battle.playing else 0.0
	battle.play(at)
	drums.play(at)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sfx", sfx_on)
	cfg.save(SETTINGS_PATH)
