#!/usr/bin/env bash
# Génère les icônes PWA 192×192 et 512×512 avec fond opaque (bonne pratique maskable).
# Nécessite ImageMagick : sudo apt install imagemagick  ou  brew install imagemagick
#
# Usage : depuis la racine du projet : ./scripts/generate-pwa-icons.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ICONS_DIR="$ROOT_DIR/public/icons"
SOURCE="$ROOT_DIR/app/assets/images/favicon-512.png"
BG_COLOR="#007bff"   # Couleur primaire Grenoble Roller (--gr-primary)

if ! command -v convert &>/dev/null; then
  echo "ImageMagick (convert) n'est pas installé."
  echo "  Ubuntu/Debian : sudo apt install imagemagick"
  echo "  macOS : brew install imagemagick"
  echo "  Sinon : utilisez https://maskable.app/editor pour générer les icônes avec fond."
  exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "Source introuvable : $SOURCE"
  exit 1
fi

mkdir -p "$ICONS_DIR"

# Safe zone ~80 % : logo centré à 80 % de la taille du canvas (recommandation maskable)
echo "Génération icon-512.png (fond $BG_COLOR, logo 80 % safe zone)..."
convert -size 512x512 "xc:$BG_COLOR" \
  \( "$SOURCE" -resize 410x410 \) -gravity center -composite \
  "$ICONS_DIR/icon-512.png"

echo "Génération icon-192.png (fond $BG_COLOR, logo 80 % safe zone)..."
convert -size 192x192 "xc:$BG_COLOR" \
  \( "$SOURCE" -resize 154x154 \) -gravity center -composite \
  "$ICONS_DIR/icon-192.png"

echo "OK. Fichiers créés : $ICONS_DIR/icon-192.png, $ICONS_DIR/icon-512.png"
