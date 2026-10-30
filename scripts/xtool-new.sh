#!/usr/bin/env bash
# =============================================================================
# scripts/xtool-new.sh  —  Crea un proyecto xtool (iOS) con assets completos
# =============================================================================
# Uso:  xtool-new.sh <NombreDeLaApp>
#
# Hace:
#   1. `xtool new <nombre>` (proyecto SwiftPM básico, salta el setup).
#   2. Genera Assets.xcassets completos:
#        - AppIcon.appiconset (todos los tamaños iOS/iPad/marketing) con un
#          icono Tokyo Night cyberpunk (gato neón).
#        - AccentColor.colorset (azul #7aa2f7).
#   3. Declara los recursos en Package.swift.
#
# Requiere: ~/.local/bin/xtool (instalado por modules/ios-dev.nix) y magick.
# =============================================================================
set -euo pipefail

NAME="${1:?uso: xtool-new.sh <NombreDeLaApp>}"

XT=~/.local/bin/xtool
command -v magick >/dev/null || { echo "falta imagemagick (magick)"; exit 1; }
[ -x "$XT" ] || { echo "falta xtool; ejecuta install-toolchain.sh --user-only"; exit 1; }

# 1) Proyecto base ------------------------------------------------------------
"$XT" new "$NAME" --skip-setup

ASSETS="$NAME/Sources/$NAME/Assets.xcassets"
ICONSET="$ASSETS/AppIcon.appiconset"
mkdir -p "$ICONSET" "$ASSETS/AccentColor.colorset"

# 2) Icono maestro: fondo Tokyo Night + rejilla + gato neón -------------------
magick -size 1024x1024 gradient:'#0f1020'-'#1a1b26' \
  -fill 'rgba(122,162,247,0.06)' -stroke 'rgba(125,207,255,0.25)' -strokewidth 2 \
    -draw 'line 0,760 240,1024' -draw 'line 200,760 420,1024' -draw 'line 400,760 610,1024' \
    -draw 'line 600,760 790,1024' -draw 'line 800,760 980,1024' \
    -draw 'line 100,760 100,1024' -draw 'line 300,760 300,1024' \
    -draw 'line 500,760 500,1024' -draw 'line 700,760 700,1024' -draw 'line 900,760 900,1024' \
  -stroke 'rgba(187,154,247,0.5)' -strokewidth 3 -draw 'line 0,760 1024,760' \
  -stroke none \
  -fill '#bb9af7' -draw 'circle 512,470 512,300' \
  -fill '#1a1b26' -draw 'circle 512,470 512,315' \
  -stroke '#bb9af7' -strokewidth 14 \
    -draw 'line 470,400 420,285' -draw 'line 554,400 604,285' \
    -draw 'line 512,470 512,560' -draw 'line 512,515 455,555' -draw 'line 512,515 569,555' \
  -stroke none -fill '#7dcfff' \
    -draw 'circle 465,455 465,437' -draw 'circle 559,455 559,437' \
  -fill 'rgba(125,207,255,0.35)' -draw 'circle 512,470 512,120' \
  -depth 8 "$ICONSET/icon-master.png"

gen() { magick "$ICONSET/icon-master.png" -resize "$2" -depth 8 "$ICONSET/$1"; }
gen Icon-App-20x20@1x.png 20x20;    gen Icon-App-20x20@2x.png 40x40;  gen Icon-App-20x20@3x.png 60x60
gen Icon-App-29x29@1x.png 29x29;    gen Icon-App-29x29@2x.png 58x58;  gen Icon-App-29x29@3x.png 87x87
gen Icon-App-40x40@1x.png 40x40;    gen Icon-App-40x40@2x.png 80x80;  gen Icon-App-40x40@3x.png 120x120
gen Icon-App-60x60@2x.png 120x120;  gen Icon-App-60x60@3x.png 180x180
gen Icon-App-76x76@1x.png 76x76;    gen Icon-App-76x76@2x.png 152x152
gen Icon-App-83.5x83.5@2x.png 167x167
gen Icon-App-1024x1024@1x.png 1024x1024
rm -f "$ICONSET/icon-master.png"

# Contents.json de los iconos -------------------------------------------------
cat > "$ICONSET/Contents.json" <<'EOF'
{
  "images" : [
    { "size" : "20x20", "idiom" : "iphone", "filename" : "Icon-App-20x20@2x.png", "scale" : "2x" },
    { "size" : "20x20", "idiom" : "iphone", "filename" : "Icon-App-20x20@3x.png", "scale" : "3x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@1x.png", "scale" : "1x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@2x.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "Icon-App-29x29@3x.png", "scale" : "3x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "Icon-App-40x40@2x.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "Icon-App-40x40@3x.png", "scale" : "3x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "Icon-App-60x60@2x.png", "scale" : "2x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "Icon-App-60x60@3x.png", "scale" : "3x" },
    { "size" : "20x20", "idiom" : "ipad", "filename" : "Icon-App-20x20@1x.png", "scale" : "1x" },
    { "size" : "20x20", "idiom" : "ipad", "filename" : "Icon-App-20x20@2x.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "ipad", "filename" : "Icon-App-29x29@1x.png", "scale" : "1x" },
    { "size" : "29x29", "idiom" : "ipad", "filename" : "Icon-App-29x29@2x.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "ipad", "filename" : "Icon-App-40x40@1x.png", "scale" : "1x" },
    { "size" : "40x40", "idiom" : "ipad", "filename" : "Icon-App-40x40@2x.png", "scale" : "2x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "Icon-App-76x76@1x.png", "scale" : "1x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "Icon-App-76x76@2x.png", "scale" : "2x" },
    { "size" : "83.5x83.5", "idiom" : "ipad", "filename" : "Icon-App-83.5x83.5@2x.png", "scale" : "2x" },
    { "size" : "1024x1024", "idiom" : "ios-marketing", "filename" : "Icon-App-1024x1024@1x.png", "scale" : "1x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
EOF

# AccentColor + Contents.json raíz --------------------------------------------
cat > "$ASSETS/AccentColor.colorset/Contents.json" <<'EOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "0.478", "green" : "0.635", "blue" : "0.969", "alpha" : "1.000" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
EOF
cat > "$ASSETS/Contents.json" <<'EOF'
{
  "info" : { "version" : 1, "author" : "xcode" }
}
EOF

# 3) Declarar el recurso en Package.swift -------------------------------------
python3 - "$NAME/Package.swift" <<'PYEOF'
import sys
path = sys.argv[1]
proj = path.split('/')[0]
src = open(path).read()
# El target termina en `name: "<proj>"` SIN coma (último argumento). Al añadir
# `resources:` hay que ponerle la coma.
old = '            name: "' + proj + '"\n        ),'
new = '            name: "' + proj + '",\n            resources: [\n                // Asset catalog (icono de app, AccentColor...).\n                .process("Assets.xcassets")\n            ]\n        ),'
assert old in src, "target anchor not found"
open(path, 'w').write(src.replace(old, new, 1))
PYEOF

echo "✔ Proyecto '$NAME' creado con assets completos."
echo "  Build:      cd $NAME && xtool dev build"
echo "  Ejecutar:   cd $NAME && ~/omarchy-apple-dev/device-run.sh  (iPhone por USB)"
