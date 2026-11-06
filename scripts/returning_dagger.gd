extends Area3D

enum Phase { FLY, RETURN }

const FLY_SPEED := 22.0
const RETURN_SPEED := 28.0
const RETURN_DAMAGE_MULT := 1.35

var damage: int = 8
var phase: Phase = Phase.FLY
var _owner_player: Node3D
var _dir := Vector3.FORWARD
var _hit_ids: Dictionary = {}


func setup(player: Node3D, direction: Vector3, dmg: int) -> void:
	_owner_player = player
	_dir = direction.normalized()
	damage = dmg
	collision_layer = 8
	collision_mask = 5
	monitoring = true
	body_entered.connect(_on_body_entered)
	look_at(global_position + _dir, Vector3.UP)


func _physics_process(delta: float) -> void:
	match phase:
		Phase.FLY:
			global_position += _dir * FLY_SPEED * delta
		Phase.RETURN:
			if not is_instance_valid(_owner_player):
				queue_free()
				return
			var to_player := _owner_player.global_position + Vector3(0, 1.2, 0) - global_position
			if to_player.length() < 0.6:
				if _owner_player.has_method("on_dagger_returned"):
					_owner_player.on_dagger_returned()
				queue_free()
				return
			global_position += to_player.normalized() * RETURN_SPEED * delta
			if to_player.length() > 0.01:
				look_at(global_position + to_player.normalized(), Vector3.UP)


func start_return() -> void:
	if phase == Phase.RETURN:
		return
	phase = Phase.RETURN
	_hit_ids.clear()
	if RunState.has_relic(RunState.RELIC_GRAVITY):
		_pull_nearby_enemies()


func _pull_nearby_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node3D and node.has_method("apply_push"):
			var n3 := node as Node3D
			if n3.global_position.distance_to(global_position) < 6.0:
				var pull := (_owner_player.global_position - n3.global_position).normalized() * 10.0
				node.apply_push(pull)


func _on_body_entered(body: Node) -> void:
	var target := _resolve_target(body)
	if target == null:
		if body is StaticBody3D and phase == Phase.FLY:
			start_return()
		return
	var id := target.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	var dmg := damage
	if phase == Phase.RETURN:
		dmg = int(round(float(damage) * RETURN_DAMAGE_MULT))
	else:
		RunState.mark_enemy(target)
	if target.has_method("take_hit"):
		var knock := _dir * 4.0 if phase == Phase.FLY else -_dir * 2.0
		target.take_hit(dmg, knock)
	if phase == Phase.FLY:
		start_return()


func _resolve_target(node: Node) -> Node:
	if node == _owner_player:
		return null
	if node.is_in_group("enemy") or node.is_in_group("breakable"):
		return node
	if node.get_parent() and (node.get_parent().is_in_group("enemy") or node.get_parent().is_in_group("breakable")):
		return node.get_parent()
	return null
