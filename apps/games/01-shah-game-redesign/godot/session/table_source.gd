class_name TableSource
extends Node
## What the table screen talks to. TableController (single player) and RemoteTableSource (online)
## both fill in this surface, so the screen does not care which one it has. The screen reads
## `state` and the exchange data, calls submit_play/submit_pass, and listens to the signals.

signal game_started
signal state_changed
## `play` is null when the seat passed.
signal move_made(seat: int, play: Play, result: MoveResult)
## It is now your turn to act (the turn timer is running).
signal human_turn_started
## You ran out of time and the move that follows is made for you.
signal timed_out
signal game_finished(ranking: Array[int])
## The server refused a move you sent (online only; a local game answers immediately).
signal move_rejected(reason: String)
## Online only: the connection dropped (false) or came back (true).
signal connection_changed(connected: bool)

## Your seat.
var human_seat: int = 0
## What the screen draws from; refreshed on every change.
var state: TableState
## Bot thinking time in seconds; the screen scales its animation holds from this.
var think_time: float = GameRunner.DEFAULT_THINK_TIME
## Seconds you get for each turn, and what is left of the current one.
var turn_seconds: float = GameRunner.DEFAULT_TURN_SECONDS
var time_left: float = 0.0
## Card exchange before the current game (empty for game 1). Valid right after game_started.
## Each entry is {"from", "to", "cards"} (cards only if you are involved) or {"from", "to", "count"}.
var exchange_transfers: Array[Dictionary] = []
## Your hand before the exchange.
var dealt_hand: Array[Card] = []


func start_next_game() -> void:
	pass


func submit_play(_cards: Array) -> MoveResult:
	return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)


func submit_pass() -> MoveResult:
	return MoveResult.rejected(MoveResult.REASON_NOT_YOUR_TURN)


## True when the game is waiting for you to decide.
func is_human_turn() -> bool:
	return false


## Whether you may start the next game (online, only the host can).
func can_start_next_game() -> bool:
	return true


## Leaves the match (online: leaves the room). Single player has nothing to do.
func leave() -> void:
	pass


## Keeps the next player waiting a while (the screen's animations need time).
func hold_for(_seconds: float) -> void:
	pass


## How long the screen should keep the last play visible after a round ends.
func round_end_hold() -> float:
	return think_time * GameRunner.ROUND_END_PAUSE_FACTOR
