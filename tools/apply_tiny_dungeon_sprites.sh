#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$ROOT/assets/third_party/kenney/tiny-dungeon/extracted/Tiles"
OUT="$ROOT/assets/sprites"
mkdir -p "$OUT"

# PNG32 (RGBA) evita colormap que o Godot às vezes não importa a tempo.
to_sprite() {
  local src="$1"
  local dest="$2"
  convert "$src" -filter point -resize 200% -define png:color-type=6 -strip "PNG32:$dest"
}

to_sprite "$D"/096_char_knight.png "$OUT/player.png"
to_sprite "$D"/108_enemy_slime.png "$OUT/enemy_slime.png"
to_sprite "$D"/105_sword_long_a.png "$OUT/sword.png"
to_sprite "$D"/048_floor_dirt_pebble_a.png "$OUT/tile_grass.png"
to_sprite "$D"/040_plank_wood_b.png "$OUT/tile_wall.png"

rm -f "$OUT"/*.import
if command -v godot >/dev/null 2>&1; then
  godot --headless --path "$ROOT" --import >/dev/null
fi

echo "Tiny Dungeon aplicado em assets/sprites/"
identify "$OUT"/*.png
