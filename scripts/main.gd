extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var wave_manager: Node = $WaveManager
@onready var hud: CanvasLayer = $HUD
@onready var spawn_points: Node2D = $SpawnPoints
@onready var walls: StaticBody2D = $Walls

func _ready() -> void:
	_build_ground()
	_build_walls()
	player.health_changed.connect(hud.set_health)
	player.died.connect(_on_player_died)
	wave_manager.wave_changed.connect(hud.set_wave)
	wave_manager.enemies_changed.connect(hud.set_enemies)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	hud.set_health(player.health, player.MAX_HEALTH)
	wave_manager.spawn_points_root = spawn_points
	wave_manager.enemies_root = $Enemies
	wave_manager.start()

func _on_player_died() -> void:
	hud.show_defeat()
	get_tree().paused = true

func _on_all_waves_cleared() -> void:
	hud.show_victory()
	get_tree().paused = true

func _build_ground() -> void:
	var tex: Texture2D = load("res://assets/sprites/tile_grass.png")
	var ground := Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	move_child(ground, 0)
	for x in range(0, 640, 32):
		for y in range(0, 480, 32):
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(x, y)
			ground.add_child(s)

func _build_walls() -> void:
	walls.collision_layer = 1
	walls.collision_mask = 0
	var thickness := 32.0
	_add_wall(Vector2(320, -thickness / 2), Vector2(704, thickness))
	_add_wall(Vector2(320, 480 + thickness / 2), Vector2(704, thickness))
	_add_wall(Vector2(-thickness / 2, 240), Vector2(thickness, 544))
	_add_wall(Vector2(640 + thickness / 2, 240), Vector2(thickness, 544))
	var tex: Texture2D = load("res://assets/sprites/tile_wall.png")
	for x in range(0, 640, 32):
		_add_wall_sprite(tex, Vector2(x, 0))
		_add_wall_sprite(tex, Vector2(x, 448))
	for y in range(32, 448, 32):
		_add_wall_sprite(tex, Vector2(0, y))
		_add_wall_sprite(tex, Vector2(608, y))

func _add_wall_sprite(tex: Texture2D, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	walls.add_child(s)

func _add_wall(center: Vector2, size: Vector2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	shape_node.position = center
	walls.add_child(shape_node)
