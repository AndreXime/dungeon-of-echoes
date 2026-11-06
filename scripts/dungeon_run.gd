extends Node3D

@onready var world: Node3D = $World
@onready var hud_hp: Label = $HUD/HP
@onready var hud_gold: Label = $HUD/Gold
@onready var hud_weapon: Label = $HUD/Weapon
@onready var hud_relics: Label = $HUD/Relics
@onready var hud_message: Label = $HUD/Message
@onready var hud_floor: Label = $HUD/Floor
@onready var hud_map: Label = $HUD/Map
@onready var hud_hint: Label = $HUD/Hint

var _generator := preload("res://scripts/dungeon_generator.gd").new()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud_message.add_to_group("run_message")
	add_child(_generator)
	_generator.generation_done.connect(_on_generated)
	_generator.generate(world, RunState.seed_value)
	_apply_biome_environment()


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
		hud_weapon.text = "Arma: %s  |  1/2/3  |  Q poção  |  T tocha" % player.weapon_label()
	if RunState.relics.is_empty():
		hud_relics.text = "Relíquias: nenhuma"
	else:
		hud_relics.text = "Relíquias: %s" % ", ".join(PackedStringArray(RunState.relics))
	hud_map.text = _map_text()
	if hud_hint:
		hud_hint.text = "LMB atacar (frente=estocada) | RMB escudo/puxar | E relíquia | Q poção | T tocha | Empurre no escudo"


func _map_text() -> String:
	if RunState.map_rooms.is_empty():
		return "Mapa: —"
	var parts: PackedStringArray = []
	for room in RunState.map_rooms:
		if not bool(room.get("revealed", false)):
			parts.append("?")
			continue
		var kind := String(room.get("kind", "?"))
		match kind:
			"hall":
				parts.append("Sala")
			"bridge":
				parts.append("Ponte")
			"hazard":
				parts.append("Armadilha")
			"cross":
				parts.append("Cruz")
			"treasure":
				parts.append("Tesouro")
			"boss":
				parts.append("Chefe")
			"end":
				parts.append("Saída")
			_:
				parts.append(kind)
	return "Mapa: " + " → ".join(parts)


func _on_generated(player_spawn: Vector3, _exit_pos: Vector3) -> void:
	var player := $Player as Node3D
	if player:
		player.global_position = player_spawn
