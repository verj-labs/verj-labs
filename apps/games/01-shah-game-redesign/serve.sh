#!/usr/bin/env bash
# Runs the online game server locally.   ./serve.sh            (port 8080)
#                                         PORT=9000 ./serve.sh
# Needs Godot: brew install --cask godot   (or set GODOT_BIN).
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "$0")/godot" && pwd)"
if [ ! -x "$GODOT_BIN" ]; then
  echo "Godot not found at $GODOT_BIN. Install it with: brew install --cask godot"
  exit 1
fi
exec "$GODOT_BIN" --headless --path "$PROJECT_DIR" res://server/server_main.tscn -- --server
