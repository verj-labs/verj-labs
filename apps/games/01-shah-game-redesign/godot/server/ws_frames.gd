class_name WsFrames
extends RefCounted
## WebSocket framing (RFC 6455) as pure functions on byte arrays, so it can be tested without
## any sockets. Clients must mask their frames; servers never do.

const OP_CONTINUATION := 0x0
const OP_TEXT := 0x1
const OP_BINARY := 0x2
const OP_CLOSE := 0x8
const OP_PING := 0x9
const OP_PONG := 0xA

const CLOSE_NORMAL := 1000
const CLOSE_PROTOCOL_ERROR := 1002
const CLOSE_UNSUPPORTED := 1003
const CLOSE_TOO_BIG := 1009


## A single unmasked (server -> client) frame.
static func encode(opcode: int, payload: PackedByteArray) -> PackedByteArray:
	var frame := PackedByteArray()
	frame.append(0x80 | opcode)
	var length := payload.size()
	if length <= 125:
		frame.append(length)
	elif length <= 0xFFFF:
		frame.append(126)
		frame.append((length >> 8) & 0xFF)
		frame.append(length & 0xFF)
	else:
		frame.append(127)
		for shift in range(56, -8, -8):
			frame.append((length >> shift) & 0xFF)
	frame.append_array(payload)
	return frame


static func encode_text(text: String) -> PackedByteArray:
	return encode(OP_TEXT, text.to_utf8_buffer())


static func encode_close(code: int = CLOSE_NORMAL) -> PackedByteArray:
	var payload := PackedByteArray()
	payload.append((code >> 8) & 0xFF)
	payload.append(code & 0xFF)
	return encode(OP_CLOSE, payload)


## Reads one client frame from the front of `buffer`.
## Returns {} when more bytes are needed, {"error": code} on a protocol violation, otherwise
## {"fin", "opcode", "payload", "consumed"}.
static func decode_client_frame(buffer: PackedByteArray, max_payload: int) -> Dictionary:
	if buffer.size() < 2:
		return {}
	var first := buffer[0]
	var second := buffer[1]
	if (first & 0x70) != 0:
		return {"error": CLOSE_PROTOCOL_ERROR}
	var fin := (first & 0x80) != 0
	var opcode := first & 0x0F
	if (second & 0x80) == 0:
		return {"error": CLOSE_PROTOCOL_ERROR}  # clients must mask
	var length := second & 0x7F
	var offset := 2
	if length == 126:
		if buffer.size() < 4:
			return {}
		length = (buffer[2] << 8) | buffer[3]
		offset = 4
	elif length == 127:
		if buffer.size() < 10:
			return {}
		length = 0
		for i in 8:
			length = (length << 8) | buffer[2 + i]
		if length < 0 or length > max_payload:
			return {"error": CLOSE_TOO_BIG}
		offset = 10
	if length > max_payload:
		return {"error": CLOSE_TOO_BIG}
	if opcode >= 0x8 and (not fin or length > 125):
		return {"error": CLOSE_PROTOCOL_ERROR}
	if buffer.size() < offset + 4 + length:
		return {}
	var mask := buffer.slice(offset, offset + 4)
	var payload := buffer.slice(offset + 4, offset + 4 + length)
	for i in length:
		payload[i] = payload[i] ^ mask[i % 4]
	return {"fin": fin, "opcode": opcode, "payload": payload, "consumed": offset + 4 + length}


## The `Sec-WebSocket-Accept` value for a client's `Sec-WebSocket-Key`.
static func accept_key(client_key: String) -> String:
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA1)
	hasher.update((client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").to_utf8_buffer())
	return Marshalls.raw_to_base64(hasher.finish())


## A masked (client -> server) text frame. Used by tests and the test client.
static func encode_masked_text(text: String, mask: PackedByteArray) -> PackedByteArray:
	var payload := text.to_utf8_buffer()
	var frame := PackedByteArray()
	frame.append(0x80 | OP_TEXT)
	var length := payload.size()
	if length <= 125:
		frame.append(0x80 | length)
	elif length <= 0xFFFF:
		frame.append(0x80 | 126)
		frame.append((length >> 8) & 0xFF)
		frame.append(length & 0xFF)
	else:
		frame.append(0x80 | 127)
		for shift in range(56, -8, -8):
			frame.append((length >> shift) & 0xFF)
	frame.append_array(mask)
	for i in length:
		frame.append(payload[i] ^ mask[i % 4])
	return frame
