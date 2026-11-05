class_name EnemyCatalog
extends RefCounted

const _TABLE := {
	"slime": {"hp": 2, "damage": 1, "coins": 1, "speed": 90.0, "texture": "res://assets/sprites/enemy_slime.png", "unlock_wave": 1},
	"rato": {"hp": 2, "damage": 1, "coins": 1, "speed": 100.0, "texture": "res://assets/sprites/enemy_rat.png", "unlock_wave": 2},
	"morcego": {"hp": 2, "damage": 1, "coins": 2, "speed": 110.0, "texture": "res://assets/sprites/enemy_bat.png", "unlock_wave": 3},
	"aranha": {"hp": 3, "damage": 1, "coins": 2, "speed": 95.0, "texture": "res://assets/sprites/enemy_spider.png", "unlock_wave": 5},
	"fantasma": {"hp": 3, "damage": 1, "coins": 3, "speed": 85.0, "texture": "res://assets/sprites/enemy_ghost.png", "unlock_wave": 6},
	"arqueiro": {"hp": 3, "damage": 1, "coins": 3, "speed": 90.0, "texture": "res://assets/sprites/enemy_archer.png", "unlock_wave": 7},
	"cultista": {"hp": 4, "damage": 1, "coins": 4, "speed": 88.0, "texture": "res://assets/sprites/enemy_cultist.png", "unlock_wave": 8},
	"caranguejo": {"hp": 5, "damage": 1, "coins": 4, "speed": 80.0, "texture": "res://assets/sprites/enemy_crab.png", "unlock_wave": 9},
	"ogro": {"hp": 6, "damage": 2, "coins": 5, "speed": 70.0, "texture": "res://assets/sprites/enemy_ogre.png", "unlock_wave": 10},
}

static func kinds() -> PackedStringArray:
	return PackedStringArray(_TABLE.keys())

static func stats(kind: String) -> Dictionary:
	assert(_TABLE.has(kind), "tipo desconhecido: %s" % kind)
	return _TABLE[kind].duplicate()

static func kinds_unlocked_at(wave: int) -> PackedStringArray:
	var out := PackedStringArray()
	for kind in _TABLE.keys():
		if int(_TABLE[kind].unlock_wave) <= wave:
			out.append(kind)
	return out
