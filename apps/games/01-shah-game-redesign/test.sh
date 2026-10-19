#!/usr/bin/env bash
# Run the tests.
#   ./test.sh           all tests, short output (failures + summary)
#   ./test.sh core      only tests/core
#   ./test.sh -v        all tests, full output
# Needs Godot: brew install --cask godot   (or set GODOT_BIN to your Godot binary)
# Exit code is 0 when everything passes, non-zero otherwise.
set -u

VERBOSE=0
if [ "${1:-}" = "-v" ]; then VERBOSE=1; shift; fi

GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "$0")/godot" && pwd)"
TARGET="res://tests${1:+/$1}"

if [ ! -x "$GODOT_BIN" ]; then
  echo "Godot not found at $GODOT_BIN. Install it with: brew install --cask godot"
  exit 1
fi

cd "$PROJECT_DIR" || exit 1

# Makes Godot register our class_name scripts (Card, Play, ...) before tests load them.
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1

LOG="$(mktemp)"
# --ignoreHeadlessMode: our tests are pure logic, so headless is fine.
# The "remote port" error Godot prints is harmless (gdUnit4 disables the interactive debugger on purpose).
"$GODOT_BIN" --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 \
  res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a "$TARGET" -c --ignoreHeadlessMode >"$LOG" 2>&1
CODE=$?

CLEAN="$(sed 's/\x1b\[[0-9;]*[A-Za-z]//g' "$LOG")"
if [ "$VERBOSE" -eq 1 ]; then
  echo "$CLEAN"
else
  echo "$CLEAN" | grep -E "FAILED|ERROR|Overall Summary|Open HTML Report|Abnormal exit|rror:" | grep -v "remote port\|Remote Debugger\|connect_to_host\|create_tcp"
fi
rm -f "$LOG"

if [ "$CODE" -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "TESTS FAILED (exit $CODE)"; fi
exit "$CODE"
