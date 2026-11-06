extends Node

const RELIC_GLASS_EYE := "glass_eye"
const RELIC_CRYSTAL_VAMP := "crystal_vamp"
const RELIC_VOLCANIC := "volcanic"
const RELIC_GRAVITY := "gravity_core"

const BIOME_CATACOMBS := 0
const BIOME_MINES := 1
const BIOME_GARDEN := 2

var hp: int = 100
var max_hp: int = 100
var gold: int = 0
var essence: int = 0
var potions: int = 1
var seed_value: int = 0
var in_run: bool = false
var floor_index: int = 1
var biome: int = BIOME_CATACOMBS
var relics: Array[String] = []
var marked_enemies: Dictionary = {}
var map_rooms: Array[Dictionary] = []
var boss_cleared: bool = false


func reset_for_new_run() -> void:
	max_hp = 100 + MetaProgress.bonus_max_hp
	hp = max_hp
	gold = 0
	essence = 0
	potions = MetaProgress.potion_capacity
	seed_value = int(Time.get_unix_time_from_system())
	in_run = true
	floor_index = 1
	biome = BIOME_CATACOMBS
	relics.clear()
	marked_enemies.clear()
	map_rooms.clear()
	boss_cleared = false


func biome_name() -> String:
	match biome:
		BIOME_MINES:
			return "Minas de Fogo-Fátuo"
		BIOME_GARDEN:
			return "Jardim Sem Sol"
		_:
			return "Catacumbas Esquecidas"


func advance_floor() -> void:
	floor_index += 1
	boss_cleared = false
	if floor_index >= 7:
		biome = BIOME_GARDEN
	elif floor_index >= 4:
		biome = BIOME_MINES
	else:
		biome = BIOME_CATACOMBS
	seed_value = seed_value * 1103515245 + floor_index


func has_relic(id: String) -> bool:
	return relics.has(id)


func add_relic(id: String) -> bool:
	if relics.has(id):
		return false
	relics.append(id)
	return true


func sword_damage() -> int:
	return MetaProgress.sword_damage()


func melee_damage_against(enemy: Object) -> int:
	var dmg := sword_damage()
	if enemy != null and marked_enemies.has(enemy.get_instance_id()):
		dmg *= 2
		marked_enemies.erase(enemy.get_instance_id())
	return dmg


func mark_enemy(enemy: Object) -> void:
	if not has_relic(RELIC_GLASS_EYE) or enemy == null:
		return
	marked_enemies[enemy.get_instance_id()] = true


func apply_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)


func try_use_potion() -> bool:
	if potions <= 0 or hp >= max_hp:
		return false
	potions -= 1
	heal(35)
	return true


func add_gold(amount: int) -> void:
	gold += maxi(amount, 0)


func add_essence(amount: int) -> void:
	essence += maxi(amount, 0)


func is_dead() -> bool:
	return hp <= 0


func finish_run_and_return_to_hub() -> void:
	if not in_run:
		return
	in_run = false
	MetaProgress.add_run_gold(gold + essence / 2)
	MetaProgress.add_ore(essence / 3)
	gold = 0
	essence = 0
	hp = max_hp
	relics.clear()
	marked_enemies.clear()
	map_rooms.clear()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/hub.tscn")


func go_to_next_floor() -> void:
	advance_floor()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/dungeon_run.tscn")
