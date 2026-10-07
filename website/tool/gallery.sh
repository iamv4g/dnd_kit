#!/usr/bin/env bash
# Build the Flutter example gallery for the web and bundle it into the site
# output at build/jaspr/flutter/, where the showcase page's iframe expects it.
#
# `jaspr build` cannot produce this — it is a separate Flutter web app — so
# without this script the "The same demos, on Flutter" section is a dead iframe
# on every machine, and only the deploy workflow ever sees it working. Keep this
# in step with the equivalent steps in .github/workflows/deploy-website.yml.
#
# Usage:
#   tool/gallery.sh                          # for a site served from / (as deployed)
#   tool/gallery.sh /some/subpath/flutter/   # for a site served below a subpath
set -euo pipefail
cd "$(dirname "$0")/.."

BASE_HREF="${1:-/flutter/}"
GALLERY="../examples/flutter_example_gallery"
OUT="build/jaspr/flutter"

# Prefer fvm when the repo is pinned through it, so this matches the SDK the
# rest of the workspace resolves against.
if command -v fvm >/dev/null 2>&1 && [ -f ../.fvmrc ]; then
  FLUTTER=(fvm flutter)
else
  FLUTTER=(flutter)
fi

echo "Building the Flutter gallery with --base-href $BASE_HREF ..."
(cd "$GALLERY" && "${FLUTTER[@]}" build web --release --base-href "$BASE_HREF")

mkdir -p "$OUT"
# rsync (not cp -r): the Flutter web output contains a self-referential
# `dnd_kit.flutter -> .` symlink that makes `cp -r` choke on a cycle.
rsync -a --delete --exclude='dnd_kit.flutter' "$GALLERY/build/web/" "$OUT/"
test -f "$OUT/index.html"

echo "Bundled the gallery into $OUT"
