extends Node3D

@onready var world: Node3D = $World
@onready var status_panel: PanelContainer = $HUD/Root/StatusPanel
@onready var hud_hp: Label = $HUD/Root/StatusPanel/StatusBox/HP
@onready var hud_gold: Label = $HUD/Root/StatusPanel/StatusBox/Gold
@onready var hud_weapon: Label = $HUD/Root/StatusPanel/StatusBox/Weapon
@onready var hud_relics: Label = $HUD/Root/StatusPanel/StatusBox/Relics
@onready var hud_message: Label = $HUD/Root/MessageCenter/MessagePanel/Message
@onready var hud_message_panel: PanelContainer = $HUD/Root/MessageCenter/MessagePanel
@onready var hud_floor: Label = $HUD/Root/StatusPanel/StatusBox/Floor
var _generator := preload("res://scripts/world/dungeon_generator.gd").new()
var _pause_menu: Node


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Music.play_dungeon()
	hud_message.add_to_group("run_message")
	hud_message_panel.visible = false
	add_child(_generator)
	_generator.generation_done.connect(_on_generated)
	_generator.generate(world, RunState.seed_value)
	_apply_biome_environment()
	_spawn_pause_menu()
	_fit_status_panel()


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
			env.ambient_light_energy = 0.38
		RunState.BIOME_GARDEN:
			env.background_color = Color(0.02, 0.06, 0.03)
			env.ambient_light_color = Color(0.15, 0.28, 0.18)
			env.ambient_light_energy = 0.34
		_:
			env.background_color = Color(0.02, 0.02, 0.03)
			env.ambient_light_color = Color(0.2, 0.18, 0.16)
			env.ambient_light_energy = 0.32


func _process(_delta: float) -> void:
	hud_hp.text = "HP %d/%d  ·  Poções %d" % [RunState.hp, RunState.max_hp, RunState.potions]
	hud_gold.text = "Ouro %d  ·  Essência %d" % [RunState.gold, RunState.essence]
	hud_floor.text = "Andar %d — %s" % [RunState.floor_index, RunState.biome_name()]
	var player := $Player
	if player and player.has_method("weapon_label"):
		hud_weapon.text = "Arma: %s" % player.weapon_label()
	if RunState.relics.is_empty():
		hud_relics.text = "Relíquias: nenhuma"
	else:
		hud_relics.text = "Relíquias: %s" % ", ".join(PackedStringArray(RunState.relics))
	var has_msg := hud_message.text.strip_edges() != ""
	if hud_message_panel.visible != has_msg:
		hud_message_panel.visible = has_msg
	_fit_status_panel()


func _fit_status_panel() -> void:
	# Fixa canto e deixa a caixa crescer só o necessário.
	var min_size := status_panel.get_combined_minimum_size()
	status_panel.position = Vector2(14, 12)
	status_panel.size = min_size


func _on_generated(player_spawn: Vector3, _exit_pos: Vector3) -> void:
	var player := $Player as Node3D
	if player:
		player.global_position = player_spawn
