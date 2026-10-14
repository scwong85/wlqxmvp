#!/usr/bin/env bash
# Sets up everything needed to build the Jade Valley Chronicles WEB target on a fresh Linux box
# (Debian/Ubuntu style, x86_64). Windows and Android are intentionally not covered yet.
#
# Needs: bash, curl, unzip, python3 (+pip), git. Internet access to github.com.
# Usage: bash scripts/setup_env.sh
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.5.1-stable}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS="$ROOT/tools"
GODOT_BIN="$TOOLS/godot/Godot_v${GODOT_VERSION}_linux.x86_64"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION//-/.}"
BASE="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 1; }; }
for t in curl unzip python3 git; do need "$t"; done

echo "==> Godot editor ${GODOT_VERSION}"
if [[ ! -x "$GODOT_BIN" ]]; then
  mkdir -p "$TOOLS/dl_editor" "$TOOLS/godot"
  curl -fL -o "$TOOLS/dl_editor/godot.zip" "$BASE/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  unzip -q -o "$TOOLS/dl_editor/godot.zip" -d "$TOOLS/godot"
  chmod +x "$GODOT_BIN"
fi
"$GODOT_BIN" --headless --version

echo "==> Web export templates (about 1.3 GB download, only the web_* files are kept)"
if [[ ! -f "$TEMPLATE_DIR/web_nothreads_release.zip" ]]; then
  mkdir -p "$TOOLS/dl_templates" "$TEMPLATE_DIR"
  curl -fL -o "$TOOLS/dl_templates/templates.tpz" "$BASE/Godot_v${GODOT_VERSION}_export_templates.tpz"
  unzip -q -o -j "$TOOLS/dl_templates/templates.tpz" "templates/web_*" "templates/version.txt" -d "$TEMPLATE_DIR"
fi
ls "$TEMPLATE_DIR"

echo "==> Python packages for the font subset and browser smoke test"
python3 -m pip install --quiet --break-system-packages fonttools playwright || \
  python3 -m pip install --quiet fonttools playwright

echo "==> Chromium for the smoke test (skip if it fails; the build itself does not need it)"
python3 -m playwright install chromium || echo "Playwright browser install failed; smoke test will be unavailable."

echo "==> CJK font source for subsetting (Noto Sans CJK, SIL OFL)"
if ! fc-list 2>/dev/null | grep -qi "NotoSansCJK"; then
  echo "Install it with:  sudo apt-get install -y fonts-noto-cjk"
fi

cat <<EOF

Done. Build and test the web version with:
  bash scripts/build_web.sh
Output: build/web/index.html (serve over http, e.g. 'python3 -m http.server -d build/web 8080')
EOF
