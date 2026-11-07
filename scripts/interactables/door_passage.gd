extends Node3D

## Porta KayKit: abre por proximidade. Colisão do vão só some no fim da animação.

const OPEN_ANGLE_ABS := deg_to_rad(95.0)
const OPEN_TIME := 0.5
const HINGE_X := -1.0

var _hinge: Node3D
var _door_body: AnimatableBody3D
var _blocker: StaticBody3D
var _opening := false
var _opened := false
var _setup_done := false


func _ready() -> void:
	setup()


func setup() -> void:
	if _setup_done:
		return
	_setup_done = true

	var door_mi := find_child("wall_doorway_door", true, false) as MeshInstance3D
	if door_mi == null:
		return

	var frame := door_mi.get_parent() as Node3D
	if frame == null:
		return

	_hinge = Node3D.new()
	_hinge.name = "DoorHinge"
	_hinge.position = Vector3(HINGE_X, 0.0, 0.0)
	frame.add_child(_hinge)

	# Local: a sala ainda pode estar fora da árvore no generate().
	var door_local := door_mi.transform
	door_mi.owner = null
	door_mi.reparent(_hinge, false)
	door_mi.transform = Transform3D(
		door_local.basis,
		door_local.origin - Vector3(HINGE_X, 0.0, 0.0)
	)

	# Colisão da FOLHA (gira com a porta).
	_door_body = AnimatableBody3D.new()
	_door_body.name = "DoorBody"
	_door_body.collision_layer = 1
	_door_body.collision_mask = 0
	_door_body.sync_to_physics = true
	_hinge.add_child(_door_body)
	var door_col := CollisionShape3D.new()
	var door_shape := BoxShape3D.new()
	door_shape.size = Vector3(1.95, 2.7, 0.45)
	door_col.shape = door_shape
	# Centro da folha à frente da dobradiça (folha ~2m de largura).
	door_col.position = Vector3(1.0, 1.35, 0.0)
	_door_body.add_child(door_col)

	# Bloqueio fixo no VÃO: impede atravessar no meio da animação.
	_blocker = StaticBody3D.new()
	_blocker.name = "PassageBlocker"
	_blocker.collision_layer = 1
	_blocker.collision_mask = 0
	add_child(_blocker)
	var block_col := CollisionShape3D.new()
	var block_shape := BoxShape3D.new()
	# Largura do vão livre entre as paredes (±1).
	block_shape.size = Vector3(2.0, 2.7, 0.55)
	block_col.shape = block_shape
	block_col.position = Vector3(0.0, 1.35, 0.0)
	_blocker.add_child(block_col)

	var detect := Area3D.new()
	detect.name = "DetectArea"
	detect.collision_layer = 0
	detect.collision_mask = 2
	detect.monitoring = true
	detect.monitorable = false
	add_child(detect)
	var detect_col := CollisionShape3D.new()
	var detect_shape := BoxShape3D.new()
	detect_shape.size = Vector3(3.0, 2.8, 4.5)
	detect_col.shape = detect_shape
	detect_col.position = Vector3(0.0, 1.4, 0.0)
	detect.add_child(detect_col)
	detect.body_entered.connect(_on_detect_body)


func _on_detect_body(body: Node) -> void:
	if _opened or _opening:
		return
	if body is Node3D and body.is_in_group("player"):
		_open_toward(body as Node3D)


func _open_angle_toward(player: Node3D) -> float:
	# Folha no +X local. Rotação +Y manda a folha pro −Z, −Y manda pro +Z.
	# Abre sempre pro lado em que o jogador está (puxa pra dentro da sala dele).
	var local_pos := to_local(player.global_position)
	if local_pos.z >= 0.0:
		return -OPEN_ANGLE_ABS
	return OPEN_ANGLE_ABS


func _open_toward(player: Node3D) -> void:
	if _opening or _opened or not is_instance_valid(_hinge):
		return
	_opening = true
	var angle := _open_angle_toward(player)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hinge, "rotation", Vector3(0.0, angle, 0.0), OPEN_TIME)
	tween.finished.connect(_on_open_finished, CONNECT_ONE_SHOT)


func _on_open_finished() -> void:
	_opening = false
	_opened = true
	# Só desliga colisão da porta / vão. Nunca mexe nas paredes da sala.
	if is_instance_valid(_blocker):
		_blocker.collision_layer = 0
		for child in _blocker.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = true
		_blocker.queue_free()
		_blocker = null
	if is_instance_valid(_door_body):
		_door_body.collision_layer = 0
		for child in _door_body.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = true
