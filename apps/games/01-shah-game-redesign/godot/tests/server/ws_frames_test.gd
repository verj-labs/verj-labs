extends GdUnitTestSuite
## WebSocket framing, checked against the examples published in RFC 6455.

const RFC_MASKED_HELLO := [0x81, 0x85, 0x37, 0xfa, 0x21, 0x3d, 0x7f, 0x9f, 0x4d, 0x51, 0x58]


func _bytes(values: Array) -> PackedByteArray:
	return PackedByteArray(values)


func _mask() -> PackedByteArray:
	return _bytes([0x12, 0x34, 0x56, 0x78])


func test_rfc_masked_hello_decodes() -> void:
	var frame := WsFrames.decode_client_frame(_bytes(RFC_MASKED_HELLO), 1000)
	assert_bool(frame["fin"]).is_true()
	assert_int(frame["opcode"]).is_equal(WsFrames.OP_TEXT)
	assert_str((frame["payload"] as PackedByteArray).get_string_from_utf8()).is_equal("Hello")
	assert_int(frame["consumed"]).is_equal(11)


func test_server_text_frames_match_the_rfc_layout() -> void:
	var frame := WsFrames.encode_text("Hello")
	assert_array(Array(frame)).is_equal([0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f])


func test_the_rfc_accept_key_example() -> void:
	assert_str(WsFrames.accept_key("dGhlIHNhbXBsZSBub25jZQ==")).is_equal("s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")


func test_close_frame_layout() -> void:
	assert_array(Array(WsFrames.encode_close(1000))).is_equal([0x88, 0x02, 0x03, 0xE8])


func test_every_length_form_round_trips(
	length: int, test_parameters := [[0], [1], [125], [126], [127], [300], [65535], [65536], [70000]]
) -> void:
	var text := "a".repeat(length)
	var frame := WsFrames.decode_client_frame(WsFrames.encode_masked_text(text, _mask()), 100000)
	assert_int((frame["payload"] as PackedByteArray).size()).is_equal(length)
	assert_str((frame["payload"] as PackedByteArray).get_string_from_utf8()).is_equal(text)


func test_server_frames_use_the_right_length_prefix() -> void:
	assert_int(WsFrames.encode_text("a".repeat(125)).size()).is_equal(2 + 125)
	assert_int(WsFrames.encode_text("a".repeat(126)).size()).is_equal(4 + 126)
	assert_int(WsFrames.encode_text("a".repeat(65536)).size()).is_equal(10 + 65536)


func test_multibyte_text_survives() -> void:
	var text := "héllo 🃏 ♠"
	var frame := WsFrames.decode_client_frame(WsFrames.encode_masked_text(text, _mask()), 1000)
	assert_str((frame["payload"] as PackedByteArray).get_string_from_utf8()).is_equal(text)


func test_incomplete_frames_ask_for_more_bytes() -> void:
	var whole := WsFrames.encode_masked_text("hello world", _mask())
	for cut in range(0, whole.size()):
		assert_bool(WsFrames.decode_client_frame(whole.slice(0, cut), 1000).is_empty()).override_failure_message("cut at %d should be incomplete" % cut).is_true()
	assert_bool(WsFrames.decode_client_frame(whole, 1000).is_empty()).is_false()


func test_two_frames_in_one_buffer_decode_one_at_a_time() -> void:
	var buffer := WsFrames.encode_masked_text("one", _mask())
	buffer.append_array(WsFrames.encode_masked_text("two", _mask()))
	var first := WsFrames.decode_client_frame(buffer, 1000)
	assert_str((first["payload"] as PackedByteArray).get_string_from_utf8()).is_equal("one")
	var second := WsFrames.decode_client_frame(buffer.slice(first["consumed"]), 1000)
	assert_str((second["payload"] as PackedByteArray).get_string_from_utf8()).is_equal("two")


func test_unmasked_client_frames_are_a_protocol_error() -> void:
	assert_int(WsFrames.decode_client_frame(_bytes([0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]), 1000)["error"]).is_equal(WsFrames.CLOSE_PROTOCOL_ERROR)


func test_reserved_bits_are_a_protocol_error() -> void:
	assert_int(WsFrames.decode_client_frame(_bytes([0xC1, 0x80, 0, 0, 0, 0]), 1000)["error"]).is_equal(WsFrames.CLOSE_PROTOCOL_ERROR)


func test_oversized_payloads_are_refused_before_they_are_read() -> void:
	var header := _bytes([0x81, 0xFE, 0xFF, 0xFF])  # claims 65535 bytes, none sent yet
	assert_int(WsFrames.decode_client_frame(header, 1000)["error"]).is_equal(WsFrames.CLOSE_TOO_BIG)
	var huge := _bytes([0x81, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
	assert_int(WsFrames.decode_client_frame(huge, 1000)["error"]).is_equal(WsFrames.CLOSE_TOO_BIG)


func test_fragmented_or_long_control_frames_are_refused() -> void:
	var fragmented_ping := _bytes([0x09, 0x80, 0, 0, 0, 0])  # fin bit missing
	assert_int(WsFrames.decode_client_frame(fragmented_ping, 1000)["error"]).is_equal(WsFrames.CLOSE_PROTOCOL_ERROR)
	var long_ping := _bytes([0x89, 0xFE, 0x00, 0x7E])  # 126 bytes
	assert_int(WsFrames.decode_client_frame(long_ping, 1000)["error"]).is_equal(WsFrames.CLOSE_PROTOCOL_ERROR)
