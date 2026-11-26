extends Node
## Autoload "Profile": owns the saved ProfileData, writes it to disk and finishes research
## when its time is up (also research that finished while the game was closed).

signal changed
signal research_done(id: String)

const SAVE_PATH := "user://flintkeep_save.json"
const TICK := 1.0

## Tools point this elsewhere so screenshots never touch a real save.
var save_path := SAVE_PATH

var data := ProfileData.new()
var _since := 0.0


## Coins earned while the game was closed, waiting for the menu to show them.
var offline_pending := 0.0


func _ready() -> void:
	load_game()
	offline_pending = data.offline_coins(now())
	data.last_seen = now()
	_finish_research()


func _process(delta: float) -> void:
	_since += delta
	if _since >= TICK:
		_since = 0.0
		_finish_research()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


static func now() -> float:
	return Time.get_unix_time_from_system()


func start_research(id: String) -> bool:
	if not data.start(id, now()):
		return false
	save_game()
	changed.emit()
	return true


func start_workshop_research(id: String) -> bool:
	if not data.start_workshop_research(id, now()):
		return false
	save_game()
	changed.emit()
	return true


func add_coins(amount: float) -> void:
	if amount <= 0.0:
		return
	data.coins += amount
	changed.emit()


func _finish_research() -> void:
	var done := data.finish_due(now())
	if done.is_empty():
		return
	save_game()
	for id in done:
		research_done.emit(id)
	Sfx.play("research_done", 0.0)
	changed.emit()


func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var text := FileAccess.get_file_as_string(save_path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		data = ProfileData.from_dict(parsed)
	else:
		push_warning("Save file unreadable, starting fresh")


func collect_offline() -> float:
	var amount := offline_pending
	offline_pending = 0.0
	add_coins(amount)
	save_game()
	return amount


func save_game() -> void:
	data.last_seen = now()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data.to_dict()))


## Wipes all progress (used by the settings menu and tests).
func reset() -> void:
	data = ProfileData.new()
	save_game()
	changed.emit()
