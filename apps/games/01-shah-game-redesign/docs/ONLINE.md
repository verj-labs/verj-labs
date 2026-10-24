# Online play: design and protocol (v1)

Status: **implemented** (server, client, lobby, tests). Not yet deployed. Source of truth for the server, the client and their tests. If code and this
document disagree, fix one of them in the same change.

## 1. Principles

1. **The server is the referee.** Clients send *intents* ("play these cards", "pass"). The server
   validates with the same `core/` engine the single-player game uses, applies the move and
   tells everyone what happened. A client can never make an illegal move succeed.
2. **One rules engine.** `core/` and `bots/` run unchanged on the server (headless Godot).
3. **Hidden information stays hidden.** Each player is sent only their own hand plus how many
   cards everyone else holds. Cards exchanged between two other players are sent as a count.
4. **Resync beats incremental sync.** Every update carries the complete state snapshot for that
   player. A client that missed anything is repaired by the next message. (Last time desync was
   the failure mode; snapshots are small, so we pay a few hundred bytes to remove the class of bug.)
5. **Time is the server's.** Turn timers and bot pacing run on the server. Clients render a
   countdown from `turn.ms_left`.
6. **Disconnects are normal.** Phones drop connections constantly. A dropped seat is held for a
   grace period, then a bot plays it, and the player can take it back by reconnecting.
7. **No database in v1.** Rooms are in memory. Accounts and leaderboards come later (see 9).

## 2. Architecture

```
Client (Godot, web/desktop)           Server (headless Godot, one process)
 RemoteSource  <--- WebSocket JSON --->  WsServer (own RFC 6455 framing + plain HTTP /health)
                                          GameServer  (sessions, routing, rate limits)
                                            RoomManager -> Room -> GameRunner -> core/ + bots/
```

* `GameRunner` (shared with single-player) owns the match, bots, bot pacing and turn timer, and
  is driven by `tick(delta)`, so it is fully testable with simulated time.
* `GameServer`, `Room` and friends never touch sockets. They talk to a `Connection` interface,
  so tests use in-memory fake clients and the transport is swappable.

## 3. Transport

* WebSocket text frames, one JSON object per frame, UTF-8. Max frame 16 KB.
* The server listens on `$PORT` (default 8080). TLS is terminated by the host (Railway); the
  server speaks plain `ws` behind it. Clients use `wss://` in production.
* `GET /health` (any non-WebSocket HTTP request) answers `200 ok` for platform health checks.
* Origin allow-list from `ALLOWED_ORIGINS` (comma separated, empty = allow all, for local dev).

## 4. Session lifecycle

1. Client opens the socket and sends `hello`.
2. Server replies `welcome` with a `token`. The client stores it (device storage).
3. On reconnect the client sends `hello` with the same `token`; the server re-attaches the
   session, then sends `room` and, if a game is running, the current `update` snapshot.
4. Clients send `ping` every 15 s; a connection silent for 45 s is dropped.
5. A session with no connection is *disconnected*. After `GRACE_SECONDS` (60) its seat is
   played by a bot; it can be reclaimed by reconnecting before the room closes.

## 5. Client -> server messages

Every message is an object with a string `type`. Unknown types or malformed fields yield an
`error` (code `bad_message`); repeated abuse closes the connection.

| type | fields | who / when |
|---|---|---|
| `hello` | `version` (int), `name` (string 1-12), `token` (string, optional) | first message |
| `create_room` | | any, not in a room |
| `join_room` | `code` (4 letters) | any, not in a room, room in lobby |
| `leave_room` | | in a room |
| `set_options` | `difficulty` (`easy`/`medium`), `speed` (`slow`/`normal`/`fast`) | host, lobby |
| `add_bot` | | host, lobby, free seat |
| `remove_seat` | `seat` (int) | host, lobby (kicks a human or removes a bot) |
| `start_game` | | host, lobby, 3-8 seats filled |
| `next_game` | | host, after `game_over` |
| `back_to_lobby` | | host, after `game_over` |
| `play` | `cards` (array of 1-4 card codes like `"7H"`, `"10S"`) | your turn |
| `pass` | | your turn, pile not empty |
| `ping` | | any |

## 6. Server -> client messages

| type | fields |
|---|---|
| `welcome` | `version`, `token`, `name` (possibly de-duplicated) |
| `room` | `code`, `phase` (`lobby`/`playing`/`game_over`), `host_seat`, `you_seat`, `options`, `seats` (array of `{seat, kind: empty/human/bot, name, connected}`) |
| `game_start` | `game_number`, `state`, `dealt_hand` (your cards before the exchange), `transfers` |
| `update` | `seq` (int, increases by 1), `event`, `state`, `turn` |
| `game_over` | `ranking` (array of seats, 1st first) |
| `left` | `reason` (`left`, `kicked`, `room_closed`). You are no longer in a room. |
| `error` | `code`, `message` |
| `pong` | |

### `state` (always personal to the receiver)

```
{ game_number, player_count, my_seat, names[], kinds[], hand_sizes[], my_hand[],
  pile: null | [codes], pile_owner (-1 if none), current_player (-1 when over),
  direction (1 clockwise / -1 reverse), finished[], skipped (-1 or seat), declined[] }
```

### `event` (what just happened)

```
{ type: "move", seat, cards: [codes] | null (null = pass), effect: "none"|"skip"|"reset",
  skipped_player (-1 or seat), round_won_by (-1 or seat), player_finished (bool), game_over (bool) }
{ type: "timeout", seat }     // sent just before the automatic move that follows it
{ type: "turn", seat }        // a human seat must now act (timer started); see `turn`
{ type: "sync" }              // you (re)connected: here is the current state
```

### `turn`

`{ seat, ms_left }` when a human must act, otherwise `null`. A `turn` event arrives when the wait starts, after the bot/event pauses. After a `timeout` the server
plays for the player (pass, or lowest set when leading) and sends that move as a normal event.

### `transfers` (card exchange before game 2+)

`[{from, to, cards: [codes]}, ...]`. `cards` is present only if you are `from` or `to`;
otherwise `{from, to, count}`.

### Error codes

`bad_message`, `bad_version`, `bad_name`, `not_in_room`, `already_in_room`, `no_such_room`,
`room_full`, `room_started`, `not_host`, `not_your_turn`, `illegal_move` (with the engine's
reason in `message`), `not_enough_players`, `rate_limited`, `server_busy`.

## 7. Rooms

* Code: 4 letters from `ABCDEFGHJKLMNPQRSTUVWXYZ` (no I/O), unique among live rooms.
* Seat 0 is the creator (host). Joiners fill the next free seat. Up to 8 seats.
* The host may add bots, kick players, set options, and start with 3-8 filled seats. At start,
  empty seats are dropped and seats are renumbered 0..n-1 in order.
* If the host leaves, the next human becomes host. A room with no humans connected for
  `ROOM_IDLE_SECONDS` (120 in game, 600 in lobby) is closed.
* Limits: 200 rooms and 800 connections per process (configurable), 20 messages/second per connection.

## 8. Timing (server side)

| setting | slow | normal | fast |
|---|---|---|---|
| bot think time | 1.8 s | 1.2 s | 0.6 s |
| human turn limit | 60 s | 20 s | 10 s |

Event pauses (after SKIP/RESET/round end) and the exchange pause are multiples of the think
time, exactly as in single-player, so clients have time to animate.

## 9. Later: accounts and leaderboards (Supabase)

Not built yet; the design leaves room for it:

* `hello` gains an optional `ticket` (a short-lived HS256 token signed with a shared secret,
  issued by the accounts service after Supabase sign-in). The server verifies the HMAC and
  derives a stable `user_id`. No ticket = guest.
* `Room` calls a `ResultReporter` when a game ends. v1 uses a no-op reporter; later it POSTs
  `{room, game_number, ranking: [user_id|guest], bots: [...]}` with a server secret.
* Only the server reports results. Rooms containing bots or fewer than 3 signed-in humans are
  unranked.

## 10. Testing plan

* Unit: `GameRunner` with simulated time; `TableState` round trip; frame encode/decode.
* In-memory fake clients against `GameServer`: create/join/leave, ready flow, privacy of hands,
  illegal moves, timeouts, disconnect -> bot -> reclaim, host migration, rate limiting.
* Real sockets on localhost: Godot's own `WebSocketPeer` as the client against `WsServer`.
* Bot soak: many rooms of bot-driven fake clients playing full matches with simulated time.
* Deploy check: the same Docker image locally, then on Railway, including a redeploy while
  connected.


## 11. Running and deploying

Locally: `./serve.sh` (port 8080, or `PORT=9000 ./serve.sh`), then in the game choose PLAY ONLINE
and set the server to `ws://127.0.0.1:8080`.

Environment: `PORT` (default 8080), `ALLOWED_ORIGINS` (comma separated browser origins, empty = any).

Docker: `docker build -t shah-server .` then `docker run --rm -p 8080:8080 shah-server` (from this
folder). The image downloads the Godot Linux binary at build time (`GODOT_VERSION` build arg).

Railway: new service from this repo, **Root Directory = `apps/games/01-shah-game-redesign`**; it
reads `railway.toml` (Dockerfile build, `/health` check). Generate a public domain and use
`wss://<that-domain>` as the server address in clients. Keep it to ONE replica (rooms live in
memory). A redeploy ends running games, so deploy when nobody is playing.

Smoke test of a running server (any machine with Python 3): see `tools/check_server.py`.
