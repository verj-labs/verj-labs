#!/usr/bin/env bash
# Play the game on this Mac in a phone-shaped window.
#   ./run.sh           run the game
#   ./run.sh editor    open the Godot editor for this project
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "$0")/godot" && pwd)"
if [ ! -x "$GODOT_BIN" ]; then
  echo "Godot not found at $GODOT_BIN. Install it with: brew install --cask godot"
  exit 1
fi
if [ "${1:-}" = "editor" ]; then
  exec "$GODOT_BIN" --editor --path "$PROJECT_DIR"
fi
exec "$GODOT_BIN" --path "$PROJECT_DIR"
