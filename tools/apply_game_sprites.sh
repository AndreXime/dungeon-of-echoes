#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$ROOT/assets/third_party/kenney/tiny-dungeon/extracted/Tiles"
T="$ROOT/assets/third_party/kenney/tiny-town/extracted/Tiles"
OUT="$ROOT/assets/sprites"
mkdir -p "$OUT"

to_sprite() {
  local src="$1"
  local dest="$2"
  convert "$src" -filter point -resize 200% -define png:color-type=6 -strip "PNG32:$dest"
}

# Personagem / combate
to_sprite "$D"/096_char_knight.png "$OUT/player.png"
to_sprite "$D"/105_sword_long_a.png "$OUT/sword.png"
to_sprite "$D"/107_sword_broad.png "$OUT/sword_better.png"
to_sprite "$D"/085_char_villager.png "$OUT/npc_villager.png"

# Inimigos
to_sprite "$D"/108_enemy_slime.png "$OUT/enemy_slime.png"
to_sprite "$D"/123_enemy_rat_brown.png "$OUT/enemy_rat.png"
to_sprite "$D"/120_enemy_bat.png "$OUT/enemy_bat.png"
to_sprite "$D"/122_enemy_spider.png "$OUT/enemy_spider.png"
to_sprite "$D"/121_enemy_ghost.png "$OUT/enemy_ghost.png"
to_sprite "$D"/112_enemy_archer.png "$OUT/enemy_archer.png"
to_sprite "$D"/111_enemy_cultist.png "$OUT/enemy_cultist.png"
to_sprite "$D"/110_enemy_crab.png "$OUT/enemy_crab.png"
to_sprite "$D"/109_enemy_ogre.png "$OUT/enemy_ogre.png"

# Itens HUD
to_sprite "$D"/115_potion_red.png "$OUT/potion_small.png"
to_sprite "$D"/114_potion_green.png "$OUT/potion_large.png"

# Vila (Tiny Town)
to_sprite "$T"/000_grass.png "$OUT/town_grass.png"
to_sprite "$T"/025_path_center_a.png "$OUT/town_path.png"
to_sprite "$T"/043_path_stone.png "$OUT/town_path_stone.png"
to_sprite "$T"/004_tree_round_green_top.png "$OUT/town_tree.png"
to_sprite "$T"/044_fence_h_a.png "$OUT/town_fence_h.png"
to_sprite "$T"/058_fence_v_a.png "$OUT/town_fence_v.png"
to_sprite "$T"/052_wall_orange_a.png "$OUT/town_house_wall.png"
to_sprite "$T"/048_roof_grey_a.png "$OUT/town_roof.png"
to_sprite "$T"/085_door_wood_closed.png "$OUT/town_door.png"
to_sprite "$T"/104_well.png "$OUT/town_well.png"

rm -f "$OUT"/*.import
if command -v godot >/dev/null 2>&1; then
  godot --headless --path "$ROOT" --import >/dev/null || true
fi

echo "Sprites do jogo aplicados em assets/sprites/"
ls "$OUT"/*.png | wc -l
