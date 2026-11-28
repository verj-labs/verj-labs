#!/usr/bin/env bash
# Render the scripted screenshot scene to PNGs.
#   ./tools/screenshots.sh [out-dir]       (default: out/shots)
# Needs the Godot 4.7 .NET editor (GODOT_BIN or `godot` on PATH) and the .NET 8 SDK.
# On a Linux machine without a display it uses xvfb-run; set VK_ICD_FILENAMES for a software
# Vulkan driver (lavapipe) if there is no GPU.
set -eu
cd "$(dirname "$0")/.."
mkdir -p "${1:-out/shots}"
OUT="$(readlink -f "${1:-out/shots}")"
GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
DOTNET="${DOTNET:-$(command -v dotnet || echo "$HOME/.dotnet/dotnet")}"
[ -x "$GODOT_BIN" ] || { echo "Set GODOT_BIN to the Godot 4.7 .NET binary"; exit 1; }
(cd godot && "$DOTNET" build --nologo -v q)
RUN=()
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run > /dev/null; then RUN=(xvfb-run -a -s "-screen 0 1600x900x24"); fi
"${RUN[@]}" "$GODOT_BIN" --path godot --resolution 1600x900 -- --shots="$OUT"
ls "$OUT"
