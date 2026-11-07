extends Object
class_name KayKit

## Paths centralizados dos assets KayKit (gltf/glb).

const TILE := 4.0

const DUNGEON := "res://assets/kaykit/dungeon/"
const ADV_CHAR := "res://assets/kaykit/adventurers/characters/"
const ADV_PROP := "res://assets/kaykit/adventurers/props/"
const SKEL_CHAR := "res://assets/kaykit/skeletons/characters/"
const WEAPONS := "res://assets/kaykit/weapons/"
const TOOLS := "res://assets/kaykit/tools/"
const FOREST := "res://assets/kaykit/forest/"
const MIXED := "res://assets/kaykit/mixed/"

const WALL := DUNGEON + "wall.gltf"
const WALL_DOORWAY := DUNGEON + "wall_doorway.gltf"
const WALL_HALF := DUNGEON + "wall_half.gltf"
const FLOOR := DUNGEON + "floor_tile_large.gltf"
const FLOOR_DIRT := DUNGEON + "floor_dirt_large.gltf"
const FLOOR_SPIKES := DUNGEON + "floor_tile_big_spikes.gltf"
const CEILING := DUNGEON + "ceiling_tile.gltf"
const TORCH_MOUNTED := DUNGEON + "torch_mounted.gltf"
const TORCH_LIT := DUNGEON + "torch_lit.gltf"
const BOX_SMALL := DUNGEON + "box_small.gltf"
const BOX_LARGE := DUNGEON + "box_large.gltf"
const BARREL := DUNGEON + "barrel_small.gltf"
const BOTTLE := DUNGEON + "bottle_A_brown.gltf"
const CHEST := DUNGEON + "chest.gltf"
const CHEST_GOLD := DUNGEON + "chest_gold.gltf"
const COLUMN := DUNGEON + "column.gltf"
const COIN := DUNGEON + "coin.gltf"
const CANDLE_LIT := DUNGEON + "candle_lit.gltf"
const BANNER := DUNGEON + "banner_red.gltf"

const KNIGHT := ADV_CHAR + "Knight.glb"
const MAGE := ADV_CHAR + "Mage.glb"
const RANGER := ADV_CHAR + "Ranger.glb"
const ROGUE := ADV_CHAR + "Rogue.glb"
const ROGUE_HOODED := ADV_CHAR + "Rogue_Hooded.glb"
const BARBARIAN := ADV_CHAR + "Barbarian.glb"

const SWORD := ADV_PROP + "sword_1handed.gltf"
const SHIELD := ADV_PROP + "shield_round.gltf"
const DAGGER := ADV_PROP + "dagger.gltf"
const CROSSBOW := ADV_PROP + "crossbow_1handed.gltf"
const BOLT := ADV_PROP + "arrow_crossbow.gltf"

const SKELETON_WARRIOR := SKEL_CHAR + "Skeleton_Warrior.glb"
const SKELETON_MAGE := SKEL_CHAR + "Skeleton_Mage.glb"
const SKELETON_ROGUE := SKEL_CHAR + "Skeleton_Rogue.glb"
const SKELETON_MINION := SKEL_CHAR + "Skeleton_Minion.glb"

const TORCH_HAND := TOOLS + "torch.gltf"
const LANTERN := TOOLS + "lantern.gltf"
const ANVIL := TOOLS + "anvil.gltf"
const HAMMER := TOOLS + "hammer.gltf"
const PICKAXE := TOOLS + "pickaxe.gltf"
const MAP_PROP := TOOLS + "map.gltf"
const ROPE := TOOLS + "rope_bundle_A.gltf"
const JOURNAL := TOOLS + "journal_closed.gltf"

const BOOK_MIMIC := MIXED + "book_mimic.gltf"
const BEARTRAP := MIXED + "beartrap_A.gltf"
const COBWEB := MIXED + "cobweb_A.gltf"
const MIRROR := MIXED + "ornate_mirror.gltf"

const TREE_A := FOREST + "Tree_1_A_Color1.gltf"
const TREE_B := FOREST + "Tree_2_A_Color1.gltf"
const TREE_C := FOREST + "Tree_3_A_Color1.gltf"
const ROCK_A := FOREST + "Rock_1_A_Color1.gltf"
const ROCK_B := FOREST + "Rock_2_A_Color1.gltf"
const ROCK_LARGE_A := FOREST + "Rock_3_R_Color1.gltf"
const ROCK_LARGE_B := FOREST + "Rock_3_Q_Color1.gltf"
const ROCK_LARGE_C := FOREST + "Rock_1_J_Color1.gltf"
const GRASS := FOREST + "Grass_1_A_Color1.gltf"
const BUSH := FOREST + "Bush_1_A_Color1.gltf"


static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)


static func instantiate(path: String) -> Node3D:
	if not exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	return packed.instantiate() as Node3D


static func add_model(parent: Node, path: String, local_pos: Vector3 = Vector3.ZERO, rot_y: float = 0.0, scale_f: float = 1.0) -> Node3D:
	var model := instantiate(path)
	if model == null:
		return null
	model.position = local_pos
	model.rotation.y = rot_y
	if not is_equal_approx(scale_f, 1.0):
		model.scale = Vector3.ONE * scale_f
	parent.add_child(model)
	return model
