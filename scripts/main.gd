extends Node2D

const TILE := 32
const MAP_W := 20
const MAP_H := 15

@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var spawn_points: Node2D = $SpawnPoints
@onready var walls: StaticBody2D = $Walls
@onready var shop_panel: PanelContainer = $HUD/ShopPanel
@onready var npc: Sprite2D = $NPC

var _well: Node2D

func _ready() -> void:
	_build_village()
	_well = preload("res://scenes/well.tscn").instantiate()
	_well.position = Vector2(320, 240)
	add_child(_well)
	move_child(_well, walls.get_index() + 1)
	npc.visible = false
	player.position = Vector2(280, 280)
	player.health_changed.connect(hud.set_health)
	player.gold_changed.connect(hud.set_gold)
	player.potions_changed.connect(hud.set_potions)
	player.died.connect(_on_player_died)
	_well.health_changed.connect(hud.set_well_health)
	_well.destroyed.connect(_on_well_destroyed)
	wave_manager.wave_started.connect(hud.set_wave)
	wave_manager.enemies_changed.connect(hud.set_enemies)
	wave_manager.shop_started.connect(_on_shop_started)
	wave_manager.enemy_killed.connect(func(coins: int): player.add_gold(coins))
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	shop_panel.next_wave_pressed.connect(_on_shop_next)
	hud.set_health(player.health, player.max_health)
	hud.set_well_health(_well.health, _well.MAX_HEALTH)
	hud.set_gold(player.gold)
	hud.set_potions(player.potion_small, player.potion_large)
	wave_manager.spawn_points_root = spawn_points
	wave_manager.enemies_root = $Enemies
	wave_manager.start()

func _on_player_died() -> void:
	hud.show_defeat()
	get_tree().paused = true

func _on_well_destroyed() -> void:
	hud.show_defeat()
	get_tree().paused = true

func _on_all_waves_cleared() -> void:
	hud.show_victory()
	get_tree().paused = true

func _on_shop_started(cycle: int) -> void:
	npc.visible = true
	get_tree().paused = true
	shop_panel.open(cycle, player)

func _on_shop_next() -> void:
	shop_panel.close()
	npc.visible = false
	get_tree().paused = false
	wave_manager.continue_after_shop()

func _build_village() -> void:
	var grass: Texture2D = load("res://assets/sprites/town_grass.png")
	var path: Texture2D = load("res://assets/sprites/town_path.png")
	var ground := Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	move_child(ground, 0)
	for x in MAP_W:
		for y in MAP_H:
			var s := Sprite2D.new()
			s.texture = grass
			s.centered = false
			s.position = Vector2(x * TILE, y * TILE)
			ground.add_child(s)
	for x in range(8, 12):
		for y in MAP_H:
			_set_tile(ground, path, x, y)
	for y in range(6, 9):
		for x in MAP_W:
			_set_tile(ground, path, x, y)
	_add_house(Vector2(3 * TILE, 2 * TILE))
	_add_house(Vector2(14 * TILE, 2 * TILE))
	_add_prop("res://assets/sprites/town_tree.png", Vector2(1 * TILE, 11 * TILE), true)
	_add_prop("res://assets/sprites/town_tree.png", Vector2(17 * TILE, 11 * TILE), true)
	_add_prop("res://assets/sprites/town_tree.png", Vector2(2 * TILE, 1 * TILE), true)
	_add_prop("res://assets/sprites/town_tree.png", Vector2(16 * TILE, 1 * TILE), true)
	for x in range(6, 14):
		_add_prop("res://assets/sprites/town_fence_h.png", Vector2(x * TILE, 4 * TILE), true)
	walls.collision_layer = 1
	walls.collision_mask = 0
	var thickness := 32.0
	_add_wall(Vector2(320, -thickness / 2), Vector2(704, thickness))
	_add_wall(Vector2(320, 480 + thickness / 2), Vector2(704, thickness))
	_add_wall(Vector2(-thickness / 2, 240), Vector2(thickness, 544))
	_add_wall(Vector2(640 + thickness / 2, 240), Vector2(thickness, 544))

func _set_tile(ground: Node2D, tex: Texture2D, tx: int, ty: int) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(tx * TILE, ty * TILE)
	ground.add_child(s)

func _add_house(origin: Vector2) -> void:
	var wall_tex: Texture2D = load("res://assets/sprites/town_house_wall.png")
	var roof_tex: Texture2D = load("res://assets/sprites/town_roof.png")
	var door_tex: Texture2D = load("res://assets/sprites/town_door.png")
	for dx in 3:
		_add_sprite_child(roof_tex, origin + Vector2(dx * TILE, 0))
		_add_sprite_child(wall_tex, origin + Vector2(dx * TILE, TILE))
	_add_sprite_child(door_tex, origin + Vector2(TILE, TILE))
	_add_blocking_rect(origin + Vector2(1.5 * TILE, 1.0 * TILE), Vector2(3 * TILE, 2 * TILE))

func _add_prop(path: String, pos: Vector2, blocking: bool) -> void:
	var tex: Texture2D = load(path)
	_add_sprite_child(tex, pos)
	if blocking:
		_add_blocking_rect(pos + Vector2(TILE * 0.5, TILE * 0.5), Vector2(24, 24))

func _add_sprite_child(tex: Texture2D, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	s.z_index = 1
	add_child(s)

func _add_blocking_rect(center: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	shape_node.position = center
	walls.add_child(shape_node)

func _add_wall(center: Vector2, size: Vector2) -> void:
	_add_blocking_rect(center, size)
