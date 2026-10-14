#!/usr/bin/env bash
# Build the Web export (single-threaded, safe for GitHub Pages) and run the smoke test.
# Usage: scripts/build_web.sh   (run from anywhere)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$ROOT/tools/godot/Godot_v4.5.1-stable_linux.x86_64}"
OUT="$ROOT/build/web"

mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT/game" --import
"$GODOT" --headless --path "$ROOT/game" --export-release "Web" ../build/web/index.html
ls -la "$OUT"

if [[ "${SKIP_SMOKE:-0}" != "1" ]]; then
  PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}" \
    python3 -I "$ROOT/scripts/web_smoke.py" "$OUT" "$ROOT/docs/spike/screens"
fi
