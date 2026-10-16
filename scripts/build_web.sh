#!/usr/bin/env bash
# Test, build the Web export (single-threaded, safe for GitHub Pages) and run the browser smoke test.
# Usage: scripts/build_web.sh   (run from anywhere)
#   SKIP_TESTS=1 skips headless tests, SKIP_SMOKE=1 skips the browser test.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$ROOT/tools/godot/Godot_v4.5.1-stable_linux.x86_64}"
OUT="$ROOT/build/web"

# Keep the bundled font in sync with every character used by the locale files.
if [[ -f /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc ]]; then
  python3 -I "$ROOT/scripts/make_font_subset.py" /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc \
    "$ROOT/game/fonts/NotoSansSC-subset.otf" "$ROOT/game/content/localization"
fi

"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true

if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  timeout 240 "$GODOT" --headless --path "$ROOT/game" res://tests/unit/run_unit.tscn | tee /dev/stderr | grep -a UNIT_OK >/dev/null
  timeout 240 "$GODOT" --headless --path "$ROOT/game" res://tests/smoke/run_smoke.tscn | tee /dev/stderr | grep -a SMOKE_OK >/dev/null
  # Restart test: two separate processes, the second must find what the first saved.
  timeout 120 "$GODOT" --headless --path "$ROOT/game" res://tests/smoke/run_persist.tscn -- write | tee /dev/stderr | grep -a PERSIST_WRITE_OK >/dev/null
  timeout 120 "$GODOT" --headless --path "$ROOT/game" res://tests/smoke/run_persist.tscn -- read | tee /dev/stderr | grep -a PERSIST_READ_OK >/dev/null
fi

rm -rf "$OUT"; mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT/game" --export-release "Web" ../build/web/index.html 2>&1 | grep -v savepack
ls -la "$OUT"

if [[ "${SKIP_SMOKE:-0}" != "1" ]]; then
  PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}" \
    python3 -I "$ROOT/scripts/web_smoke.py" "$OUT" "$ROOT/docs/spike/screens"
fi
