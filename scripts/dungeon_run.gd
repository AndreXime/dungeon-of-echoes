extends Node3D

@onready var world: Node3D = $World
@onready var hud_hp: Label = $HUD/HP
@onready var hud_gold: Label = $HUD/Gold
@onready var hud_weapon: Label = $HUD/Weapon
@onready var hud_relics: Label = $HUD/Relics
@onready var hud_message: Label = $HUD/Message
@onready var hud_floor: Label = $HUD/Floor
var _generator := preload("res://scripts/dungeon_generator.gd").new()
var _pause_menu: Node


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Music.play_dungeon()
	hud_message.add_to_group("run_message")
	add_child(_generator)
	_generator.generation_done.connect(_on_generated)
	_generator.generate(world, RunState.seed_value)
	_apply_biome_environment()
	_spawn_pause_menu()
	if has_node("HUD/Hint"):
		$HUD/Hint.visible = false
	if has_node("HUD/Map"):
		$HUD/Map.visible = false


func _spawn_pause_menu() -> void:
	var packed := load("res://scenes/pause_menu.tscn") as PackedScene
	if packed == null:
		return
	_pause_menu = packed.instantiate()
	add_child(_pause_menu)
	if _pause_menu.has_method("setup"):
		_pause_menu.setup(true)


func _apply_biome_environment() -> void:
	var env_node := $WorldEnvironment as WorldEnvironment
	if env_node == null or env_node.environment == null:
		return
	var env := env_node.environment
	match RunState.biome:
		RunState.BIOME_MINES:
			env.background_color = Color(0.08, 0.03, 0.02)
			env.ambient_light_color = Color(0.35, 0.18, 0.1)
		RunState.BIOME_GARDEN:
			env.background_color = Color(0.02, 0.06, 0.03)
			env.ambient_light_color = Color(0.15, 0.28, 0.18)
		_:
			env.background_color = Color(0.02, 0.02, 0.03)
			env.ambient_light_color = Color(0.2, 0.18, 0.16)


func _process(_delta: float) -> void:
	hud_hp.text = "HP %d/%d  |  Poções %d" % [RunState.hp, RunState.max_hp, RunState.potions]
	hud_gold.text = "Ouro: %d  |  Essência: %d" % [RunState.gold, RunState.essence]
	hud_floor.text = "Andar %d — %s" % [RunState.floor_index, RunState.biome_name()]
	var player := $Player
	if player and player.has_method("weapon_label"):
		hud_weapon.text = "Arma: %s" % player.weapon_label()
	if RunState.relics.is_empty():
		hud_relics.text = "Relíquias: nenhuma"
	else:
		hud_relics.text = "Relíquias: %s" % ", ".join(PackedStringArray(RunState.relics))


func _on_generated(player_spawn: Vector3, _exit_pos: Vector3) -> void:
	var player := $Player as Node3D
	if player:
		player.global_position = player_spawn
