#!/usr/bin/env bash
# Run the tests.
#   ./test.sh              all tests
#   ./test.sh battle       only tests whose file::name contains "battle"
# Needs Godot 4.7: brew install --cask godot   (or set GODOT_BIN to your Godot binary)
# Exit code is 0 when everything passes.
set -u

if [ -z "${GODOT_BIN:-}" ]; then
  if [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
  else
    GODOT_BIN="$(command -v godot || true)"
  fi
fi
if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
  echo "Godot not found. Install it (brew install --cask godot) or set GODOT_BIN."
  exit 1
fi

cd "$(dirname "$0")/godot" || exit 1
# Registers our class_name scripts before the tests load them.
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path . -s ../tools/run_tests.gd -- "${1:-}" 2>&1 \
  | grep -E "FAIL|passed|ERROR|Error|    " | grep -v "profile.gd\|autoload\|at: "
exit "${PIPESTATUS[0]}"
