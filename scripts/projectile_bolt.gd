extends RigidBody3D

var damage: int = 12
var _spent := false


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	gravity_scale = 1.0
	collision_layer = 8
	collision_mask = 5
	get_tree().create_timer(4.0).timeout.connect(queue_free)


func _on_body_entered(body: Node) -> void:
	if _spent:
		return
	var target := _resolve_target(body)
	if target and target.has_method("take_hit"):
		_spent = true
		RunState.mark_enemy(target)
		target.take_hit(damage, linear_velocity.normalized() * 3.0)
		queue_free()
	elif body is StaticBody3D:
		_spent = true
		freeze = true
		get_tree().create_timer(1.2).timeout.connect(queue_free)


func _resolve_target(node: Node) -> Node:
	if node.is_in_group("enemy") or node.is_in_group("breakable"):
		return node
	if node.get_parent() and (node.get_parent().is_in_group("enemy") or node.get_parent().is_in_group("breakable")):
		return node.get_parent()
	return null
