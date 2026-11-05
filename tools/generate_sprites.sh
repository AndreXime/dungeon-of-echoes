#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/assets/sprites"
convert -background none "$ROOT/assets/svg/player.svg" -resize 32x32 "$ROOT/assets/sprites/player.png"
convert -background none "$ROOT/assets/svg/enemy_slime.svg" -resize 32x32 "$ROOT/assets/sprites/enemy_slime.png"
convert -background none "$ROOT/assets/svg/bullet.svg" -resize 16x16 "$ROOT/assets/sprites/bullet.png"
convert -background none "$ROOT/assets/svg/tile_grass.svg" -resize 32x32 "$ROOT/assets/sprites/tile_grass.png"
convert -background none "$ROOT/assets/svg/tile_wall.svg" -resize 32x32 "$ROOT/assets/sprites/tile_wall.png"
echo "sprites ok"
ls -la "$ROOT/assets/sprites"
