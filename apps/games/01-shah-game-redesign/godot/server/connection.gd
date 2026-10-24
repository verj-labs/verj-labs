class_name Connection
extends RefCounted
## One client's line to the server. The server logic only knows this interface, so tests use an
## in-memory fake and the real transport (WebSocket) is swappable.

var id: int = 0


func send(_message: Dictionary) -> void:
	pass


func close() -> void:
	pass
