class_name WsConnection
extends Connection
## One WebSocket client as the transport sees it: the socket plus incoming/outgoing byte buffers.
## The game server only ever calls send() and close().

const MAX_OUTBOUND_BYTES := 1048576

var peer: StreamPeerTCP
var inbound: PackedByteArray = PackedByteArray()
var outbound: PackedByteArray = PackedByteArray()
var fragments: PackedByteArray = PackedByteArray()
var fragments_are_text: bool = false
var closing: bool = false
var finished: bool = false


func send(message: Dictionary) -> void:
	if closing or finished:
		return
	_queue(WsFrames.encode_text(JSON.stringify(message)))


func close() -> void:
	if closing or finished:
		return
	closing = true
	outbound.append_array(WsFrames.encode_close(WsFrames.CLOSE_NORMAL))


func queue_raw(bytes: PackedByteArray) -> void:
	outbound.append_array(bytes)


func _queue(frame: PackedByteArray) -> void:
	if outbound.size() + frame.size() > MAX_OUTBOUND_BYTES:
		# A client that cannot keep up is cut off rather than allowed to eat memory.
		closing = true
		outbound = WsFrames.encode_close(WsFrames.CLOSE_TOO_BIG)
		return
	outbound.append_array(frame)
