extends Node

const SAVE_PATH := "user://meta_save.cfg"
const SWORD_DAMAGE_CAP := 5
const HP_BONUS_CAP := 50
const POTION_CAP := 5
const CARTO_CAP := 3
const BASE_SWORD_DAMAGE := 10

var gold: int = 0
var ore: int = 0
var sword_damage_level: int = 0
var bonus_max_hp: int = 0
var potion_capacity: int = 1
var relic_luck: int = 0
var cartographer_level: int = 0
var unlocked_start_weapons: Array[String] = ["sword"]
var selected_start_weapon: String = "sword"


func _ready() -> void:
	load_save()


func sword_damage() -> int:
	return BASE_SWORD_DAMAGE + sword_damage_level


func upgrade_cost() -> int:
	return 20 * (sword_damage_level + 1)


func hp_upgrade_cost() -> int:
	return 25 + bonus_max_hp


func potion_upgrade_cost() -> int:
	return 30 * potion_capacity


func luck_upgrade_cost() -> int:
	return 40 + relic_luck * 25


func carto_upgrade_cost() -> int:
	return 35 * (cartographer_level + 1)


func try_upgrade_sword() -> bool:
	if sword_damage_level >= SWORD_DAMAGE_CAP:
		return false
	var cost := upgrade_cost()
	if gold < cost:
		return false
	gold -= cost
	sword_damage_level += 1
	save()
	return true


func try_upgrade_max_hp() -> bool:
	if bonus_max_hp >= HP_BONUS_CAP:
		return false
	var cost := hp_upgrade_cost()
	if gold < cost:
		return false
	gold -= cost
	bonus_max_hp += 10
	save()
	return true


func try_upgrade_potions() -> bool:
	if potion_capacity >= POTION_CAP:
		return false
	var cost := potion_upgrade_cost()
	if gold < cost:
		return false
	gold -= cost
	potion_capacity += 1
	save()
	return true


func try_upgrade_luck() -> bool:
	if relic_luck >= 5:
		return false
	var cost := luck_upgrade_cost()
	if gold < cost:
		return false
	gold -= cost
	relic_luck += 1
	save()
	return true


func try_upgrade_cartographer() -> bool:
	if cartographer_level >= CARTO_CAP:
		return false
	var cost := carto_upgrade_cost()
	if gold < cost:
		return false
	gold -= cost
	cartographer_level += 1
	save()
	return true


func try_unlock_weapon(weapon_id: String, ore_cost: int) -> bool:
	if unlocked_start_weapons.has(weapon_id):
		return false
	if ore < ore_cost:
		return false
	ore -= ore_cost
	unlocked_start_weapons.append(weapon_id)
	save()
	return true


func add_run_gold(amount: int) -> void:
	gold += maxi(amount, 0)
	save()


func add_ore(amount: int) -> void:
	ore += maxi(amount, 0)
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "gold", gold)
	cfg.set_value("meta", "ore", ore)
	cfg.set_value("meta", "sword_damage_level", sword_damage_level)
	cfg.set_value("meta", "bonus_max_hp", bonus_max_hp)
	cfg.set_value("meta", "potion_capacity", potion_capacity)
	cfg.set_value("meta", "relic_luck", relic_luck)
	cfg.set_value("meta", "cartographer_level", cartographer_level)
	cfg.set_value("meta", "unlocked_start_weapons", ",".join(PackedStringArray(unlocked_start_weapons)))
	cfg.set_value("meta", "selected_start_weapon", selected_start_weapon)
	cfg.save(SAVE_PATH)


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	gold = int(cfg.get_value("meta", "gold", 0))
	ore = int(cfg.get_value("meta", "ore", 0))
	sword_damage_level = int(cfg.get_value("meta", "sword_damage_level", 0))
	bonus_max_hp = int(cfg.get_value("meta", "bonus_max_hp", 0))
	potion_capacity = int(cfg.get_value("meta", "potion_capacity", 1))
	relic_luck = int(cfg.get_value("meta", "relic_luck", 0))
	cartographer_level = int(cfg.get_value("meta", "cartographer_level", 0))
	var unlocked := String(cfg.get_value("meta", "unlocked_start_weapons", "sword"))
	unlocked_start_weapons.clear()
	for part in unlocked.split(",", false):
		unlocked_start_weapons.append(part)
	if unlocked_start_weapons.is_empty():
		unlocked_start_weapons.append("sword")
	selected_start_weapon = String(cfg.get_value("meta", "selected_start_weapon", "sword"))
