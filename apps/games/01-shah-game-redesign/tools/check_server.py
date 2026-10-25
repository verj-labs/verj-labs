"""Smoke test for a running Shah Exchange server, using only the Python standard library.

    python3 tools/check_server.py 8080            # local server on 127.0.0.1:8080
    python3 tools/check_server.py wss://my-app.up.railway.app   # a deployed server (TLS)

Does a real WebSocket handshake, creates a room with two bots, starts a game and plays a card.
Written from RFC 6455 independently of the Godot code, so it also checks interoperability.
"""
import base64, hashlib, json, os, socket, ssl, struct, sys, time

ARG = sys.argv[1] if len(sys.argv) > 1 else "8080"
TLS = ARG.startswith("wss://")
if ARG.startswith(("ws://", "wss://")):
    HOST, PORT = ARG.split("://", 1)[1].rstrip("/"), 443 if TLS else 80
    if ":" in HOST:
        HOST, port_text = HOST.rsplit(":", 1)
        PORT = int(port_text)
else:
    HOST, PORT = "127.0.0.1", int(ARG)
GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

def connect():
    s = socket.create_connection((HOST, PORT), timeout=10)
    if TLS:
        s = ssl.create_default_context().wrap_socket(s, server_hostname=HOST)
    key = base64.b64encode(os.urandom(16)).decode()
    s.sendall(("GET / HTTP/1.1\r\nHost: %s:%d\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
               "Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n" % (HOST, PORT, key)).encode())
    buf = b""
    while b"\r\n\r\n" not in buf:
        buf += s.recv(4096)
    head, rest = buf.split(b"\r\n\r\n", 1)
    assert b"101" in head.split(b"\r\n")[0], head
    expected = base64.b64encode(hashlib.sha1((key + GUID).encode()).digest()).decode()
    assert expected.encode() in head, "bad accept key"
    return s, bytearray(rest)

def send(s, obj):
    payload = json.dumps(obj).encode()
    mask = os.urandom(4)
    n = len(payload)
    header = bytes([0x81])
    if n < 126: header += bytes([0x80 | n])
    elif n < 65536: header += bytes([0x80 | 126]) + struct.pack(">H", n)
    else: header += bytes([0x80 | 127]) + struct.pack(">Q", n)
    s.sendall(header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))

def recv(s, buf, timeout=5):
    s.settimeout(timeout)
    while True:
        if len(buf) >= 2:
            n = buf[1] & 0x7F; off = 2
            if n == 126 and len(buf) >= 4: n = struct.unpack(">H", buf[2:4])[0]; off = 4
            elif n == 127 and len(buf) >= 10: n = struct.unpack(">Q", buf[2:10])[0]; off = 10
            elif n in (126, 127): n = None
            if n is not None and len(buf) >= off + n:
                op = buf[0] & 0x0F; data = bytes(buf[off:off + n]); del buf[:off + n]
                if op == 1: return json.loads(data)
                if op == 8: raise EOFError("server closed")
                continue
        chunk = s.recv(65536)
        if not chunk: raise EOFError("eof")
        buf.extend(chunk)

def expect(s, buf, kind, limit=40):
    for _ in range(limit):
        m = recv(s, buf)
        if m["type"] == kind: return m
        if m["type"] == "error": raise SystemExit("server error: %r" % m)
    raise SystemExit("never saw %s" % kind)

ORDER = "3456789JQKA"  # plus 10 and 2, handled in strength()

def strength(card):
    rank = card[:-1]
    return {"10": 7, "J": 8, "Q": 9, "K": 10, "A": 11, "2": 12}.get(rank, int(rank) - 3 if rank.isdigit() else 0)

def beating_single(pile, hand):
    """A single card that is a legal answer to a single-card pile (equal or higher, never a 2), or None."""
    if len(pile) != 1 or strength(pile[0]) == 12:
        return None
    options = [c for c in hand if not c.startswith("2") and strength(c) >= strength(pile[0])]
    return options[0] if options else None

s, buf = connect()
send(s, {"type": "hello", "version": 1, "name": "python"})
welcome = expect(s, buf, "welcome"); print("welcome:", welcome["name"], welcome["token"][:8] + "...")
send(s, {"type": "create_room"}); room = expect(s, buf, "room"); print("room:", room["code"], room["phase"])
send(s, {"type": "set_options", "difficulty": "easy", "speed": "fast"})
send(s, {"type": "add_bot"}); send(s, {"type": "add_bot"})
send(s, {"type": "start_game"})
start = expect(s, buf, "game_start")
st = start["state"]
print("game_start: seat", st["my_seat"], "hand", len(st["my_hand"]), "sizes", st["hand_sizes"], "names", st["names"])
assert len(st["my_hand"]) in (17, ) and st["hand_sizes"] == [17, 17, 17]
played = False
acted_seqs = set()
confirmed = False
for _ in range(400):
    m = recv(s, buf, timeout=15)
    if m["type"] != "update": continue
    state, turn = m["state"], m["turn"]
    if turn and turn["seat"] == state["my_seat"] and m["seq"] not in acted_seqs:
        acted_seqs.add(m["seq"])
        if state["pile"] is None:
            card = state["my_hand"][0]
            send(s, {"type": "play", "cards": [card]}); played = True; print("played", card)
        else:
            higher = beating_single(state["pile"], state["my_hand"])
            if higher:
                send(s, {"type": "play", "cards": [higher]}); played = True; print("played", higher, "on", state["pile"])
            else:
                send(s, {"type": "pass"}); print("passed on", state["pile"])
    ev = m["event"]
    if played and ev["type"] == "move" and ev["seat"] == state["my_seat"] and ev["cards"]:
        print("server confirmed my move:", ev["cards"], "effect", ev["effect"]); confirmed = True; break
assert played and confirmed
send(s, {"type": "leave_room"}); print("left:", expect(s, buf, "left")["reason"])
print("OK: independent python client interoperates")
