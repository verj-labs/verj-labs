extends Node
## Entry point of the online game server (run headless):
##   godot --headless --path godot res://server/server_main.tscn
## Environment: PORT (default 8080), ALLOWED_ORIGINS (comma separated, empty = any).

const DEFAULT_PORT := 8080
const STATS_SECONDS := 60.0

var _game: GameServer
var _ws: WsServer
var _since_stats: float = 0.0


func _ready() -> void:
	var port := int(OS.get_environment("PORT")) if OS.get_environment("PORT") != "" else DEFAULT_PORT
	_game = GameServer.new()
	_ws = WsServer.new()
	for origin in OS.get_environment("ALLOWED_ORIGINS").split(",", false):
		_ws.allowed_origins.append(origin.strip_edges())
	var error := _ws.start(port, _game)
	if error != OK:
		push_error("could not listen on port %d (error %d)" % [port, error])
		get_tree().quit(1)
		return
	print("[server] listening on port %d, protocol v%d, origins: %s" % [
		port, Protocol.VERSION, str(_ws.allowed_origins) if not _ws.allowed_origins.is_empty() else "any"
	])


func _process(delta: float) -> void:
	_ws.poll(delta)
	_game.tick(delta)
	_since_stats += delta
	if _since_stats >= STATS_SECONDS:
		_since_stats = 0.0
		print("[server] rooms=%d connections=%d" % [_game.room_count(), _game.connection_count()])


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("[server] shutting down")
		_ws.stop()
