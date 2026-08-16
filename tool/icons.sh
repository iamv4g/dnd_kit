#!/usr/bin/env bash
# Regenerate every derived app icon from the canonical dnd_kit mark.
#
# The mark has exactly one source of truth — website/web/favicon.svg. Everything
# else in the repo is generated from it by this script, so a second drawing can
# never drift out of step with the first. Re-run whenever the mark changes; do
# not hand-edit any of the outputs.
#
# Outputs:
#   examples/flutter_example_gallery/web/favicon.png       (64px)
#   examples/flutter_example_gallery/web/icons/Icon-*.png  (192/512, + maskable)
#   examples/jaspr_example_gallery/web/favicon.svg         (copy of the mark)
#
# Requires librsvg (`brew install librsvg`).
#
# Usage:
#   tool/icons.sh
set -euo pipefail
cd "$(dirname "$0")/.."

MARK="website/web/favicon.svg"
FLUTTER_WEB="examples/flutter_example_gallery/web"
JASPR_WEB="examples/jaspr_example_gallery/web"

test -f "$MARK" || { echo "Cannot find the mark at $MARK"; exit 1; }
command -v rsvg-convert >/dev/null 2>&1 || {
  echo "rsvg-convert not found — install librsvg (brew install librsvg)"; exit 1
}

# --- Flutter gallery: a Flutter web shell needs raster icons. ----------------
echo "Rendering Flutter gallery icons from $MARK ..."
rsvg-convert -w 64  -h 64  "$MARK" -o "$FLUTTER_WEB/favicon.png"
rsvg-convert -w 192 -h 192 "$MARK" -o "$FLUTTER_WEB/icons/Icon-192.png"
rsvg-convert -w 512 -h 512 "$MARK" -o "$FLUTTER_WEB/icons/Icon-512.png"

# Maskable icons are drawn separately: Android crops them to an arbitrary shape,
# so they need a full-bleed background with the glyph inside the ~80% safe zone.
# Reusing the squircle tile here would have its corners cropped away.
MASKABLE="$(mktemp -t dndkit-maskable).svg"
cat > "$MASKABLE" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <defs>
    <linearGradient id="tile" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0" stop-color="#0175C2"/>
      <stop offset="1" stop-color="#02569B"/>
    </linearGradient>
    <linearGradient id="trace" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0" stop-color="#FFAE7E" stop-opacity="0"/>
      <stop offset="1" stop-color="#FFAE7E" stop-opacity="0.9"/>
    </linearGradient>
  </defs>
  <rect width="32" height="32" fill="url(#tile)"/>
  <g transform="translate(16 16) scale(0.62) translate(-16 -16)">
    <g fill="#FBFAF7" fill-opacity="0.94">
      <circle cx="11.5" cy="10.5" r="2"/>
      <circle cx="11.5" cy="16.5" r="2"/>
      <circle cx="19.5" cy="16.5" r="2"/>
      <circle cx="11.5" cy="22.5" r="2"/>
      <circle cx="19.5" cy="22.5" r="2"/>
    </g>
    <circle cx="19.5" cy="10.5" r="1.9" fill="none" stroke="#FBFAF7" stroke-opacity="0.34" stroke-width="1.3"/>
    <path d="M21 9.4C22 9 22.7 8.5 23.4 7.7" stroke="url(#trace)" stroke-width="2.5" stroke-linecap="round" fill="none"/>
    <circle cx="25.4" cy="6.6" r="2.4" fill="#FFAE7E"/>
  </g>
</svg>
SVG

rsvg-convert -w 192 -h 192 "$MASKABLE" -o "$FLUTTER_WEB/icons/Icon-maskable-192.png"
rsvg-convert -w 512 -h 512 "$MASKABLE" -o "$FLUTTER_WEB/icons/Icon-maskable-512.png"
rm -f "$MASKABLE"

# --- Jaspr gallery: a plain web shell, so it takes the vector as-is. ---------
echo "Copying the mark to the Jaspr gallery ..."
cp "$MARK" "$JASPR_WEB/favicon.svg"

echo "Done."
