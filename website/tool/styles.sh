#!/usr/bin/env bash
# Compile web/styles.tw.css -> web/styles.css with the standalone Tailwind CLI.
#
# jaspr_tailwind's build_runner integration pulls in build_modules, which
# collides with build_web_compilers in this workspace, so we run the standalone
# Tailwind CLI directly instead. The binary is downloaded on first run.
#
# Usage:
#   tool/styles.sh                 # one-shot build
#   tool/styles.sh --minify        # minified (use for production)
#   tool/styles.sh --watch         # rebuild on change (run beside `jaspr serve`)
set -euo pipefail
cd "$(dirname "$0")/.."

BIN="tool/tailwindcss"
VERSION="v3.4.17"

if [ ! -x "$BIN" ]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)   ASSET=tailwindcss-macos-arm64 ;;
    Darwin-x86_64)  ASSET=tailwindcss-macos-x64 ;;
    Linux-x86_64)   ASSET=tailwindcss-linux-x64 ;;
    Linux-aarch64)  ASSET=tailwindcss-linux-arm64 ;;
    *) echo "Unsupported platform: $(uname -s)-$(uname -m)"; exit 1 ;;
  esac
  echo "Downloading standalone tailwindcss $VERSION ($ASSET)..."
  curl -sL -o "$BIN" \
    "https://github.com/tailwindlabs/tailwindcss/releases/download/$VERSION/$ASSET"
  chmod +x "$BIN"
fi

exec "$BIN" -i web/styles.tw.css -o web/styles.css --config tailwind.config.js "$@"
