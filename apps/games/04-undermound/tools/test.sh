#!/usr/bin/env bash
# Run the simulation core tests (no Godot needed).
#   ./tools/test.sh            all tests
#   ./tools/test.sh water      only tests whose name contains "water"
set -eu
cd "$(dirname "$0")/../tests"
DOTNET="${DOTNET:-$(command -v dotnet || echo "$HOME/.dotnet/dotnet")}"
export DOTNET_ROOT="${DOTNET_ROOT:-$(dirname "$(readlink -f "$DOTNET")")}"
"$DOTNET" build --nologo -v q -o ../.test-bin > /dev/null
"$DOTNET" ../.test-bin/Undermound.Tests.dll "${1:-}"
