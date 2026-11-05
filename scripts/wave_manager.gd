extends Node

signal wave_started(wave_index: int, total_waves: int)
signal enemies_changed(remaining: int)
signal shop_started(cycle: int)
signal enemy_killed(coins: int)
signal all_waves_cleared

@export var enemy_scene: PackedScene
@export var spawn_points_root: Node2D
@export var enemies_root: Node2D

var _wave_index: int = 0
var _alive: int = 0
var _spawning: bool = false

func start() -> void:
	_wave_index = 0
	_spawn_next_wave()

func continue_after_shop() -> void:
	_spawn_next_wave()

func _spawn_next_wave() -> void:
	_wave_index += 1
	if _wave_index > WaveConfig.total_waves():
		all_waves_cleared.emit()
		return
	_spawning = true
	var count: int = WaveConfig.enemy_count(_wave_index)
	wave_started.emit(_wave_index, WaveConfig.total_waves())
	var points := _spawn_points()
	var speed_mult := WaveConfig.speed_multiplier(_wave_index)
	var bonus_chance := 0.1 if _wave_index > 8 else 0.0
	for i in count:
		var enemy := enemy_scene.instantiate()
		var point: Node2D = points[i % points.size()]
		enemies_root.add_child(enemy)
		enemy.setup(_pick_kind(_wave_index), speed_mult)
		enemy.bonus_coin_chance = bonus_chance
		enemy.global_position = point.global_position
		enemy.died.connect(_on_enemy_died)
		_alive += 1
	enemies_changed.emit(_alive)
	_spawning = false

func _pick_kind(wave: int) -> String:
	var pool: PackedStringArray = WaveConfig.pick_kinds_for_wave(wave)
	if pool.is_empty():
		return "slime"
	if wave == 2 and pool.size() >= 2:
		return "slime" if randf() < 0.8 else "rato"
	return pool[randi() % pool.size()]

func _spawn_points() -> Array:
	var result: Array = []
	for child in spawn_points_root.get_children():
		if child is Marker2D:
			result.append(child)
	assert(result.size() > 0, "SpawnPoints precisa de Marker2D")
	return result

func _on_enemy_died(coins: int) -> void:
	enemy_killed.emit(coins)
	_alive = maxi(0, _alive - 1)
	enemies_changed.emit(_alive)
	if _alive == 0 and not _spawning:
		_on_wave_cleared()

func _on_wave_cleared() -> void:
	if _wave_index >= WaveConfig.total_waves():
		all_waves_cleared.emit()
		return
	if WaveConfig.is_shop_wave(_wave_index):
		shop_started.emit(WaveConfig.shop_cycle(_wave_index))
		return
	get_tree().create_timer(WaveConfig.wave_interval()).timeout.connect(_spawn_next_wave)
