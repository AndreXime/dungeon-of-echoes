extends Node

signal wave_changed(wave_index: int, total_waves: int)
signal enemies_changed(remaining: int)
signal all_waves_cleared

@export var enemy_scene: PackedScene
@export var spawn_points_root: Node2D
@export var enemies_root: Node2D

var _wave_index: int = -1
var _alive: int = 0
var _spawning: bool = false

func start() -> void:
	_wave_index = -1
	_spawn_next_wave()

func _spawn_next_wave() -> void:
	var sizes: Array = WaveConfig.wave_sizes()
	_wave_index += 1
	if _wave_index >= sizes.size():
		all_waves_cleared.emit()
		return
	_spawning = true
	var count: int = sizes[_wave_index]
	wave_changed.emit(_wave_index + 1, sizes.size())
	var points := _spawn_points()
	for i in count:
		var enemy := enemy_scene.instantiate()
		var point: Node2D = points[i % points.size()]
		enemies_root.add_child(enemy)
		enemy.global_position = point.global_position
		enemy.died.connect(_on_enemy_died)
		_alive += 1
	enemies_changed.emit(_alive)
	_spawning = false

func _spawn_points() -> Array:
	var result: Array = []
	for child in spawn_points_root.get_children():
		if child is Marker2D:
			result.append(child)
	assert(result.size() > 0, "SpawnPoints precisa de Marker2D")
	return result

func _on_enemy_died() -> void:
	_alive = maxi(0, _alive - 1)
	enemies_changed.emit(_alive)
	if _alive == 0 and not _spawning:
		var sizes: Array = WaveConfig.wave_sizes()
		if _wave_index >= sizes.size() - 1:
			all_waves_cleared.emit()
		else:
			get_tree().create_timer(WaveConfig.wave_interval()).timeout.connect(_spawn_next_wave)
