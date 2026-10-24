class_name Session
extends RefCounted
## One player's identity on the server. It outlives a dropped connection: reconnecting with the
## same token re-attaches to it, which is how a player returns to their seat.

var token: String = ""
## Base display name (cleaned). The room may add a number if two players share a name.
var name: String = ""
var connection: Connection = null
var room: Room = null
## Lobby slot, or seat number once a game has started.
var seat: int = -1
## Seconds since the connection dropped (counted by the room or server), or -1 while connected.
var disconnected_for: float = -1.0


func has_connection() -> bool:
	return connection != null


func send(message: Dictionary) -> void:
	if connection != null:
		connection.send(message)
