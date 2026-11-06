extends RigidBody3D

var damage: int = 8
var _spent := false


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 3
	gravity_scale = 0.35
	get_tree().create_timer(3.5).timeout.connect(queue_free)


func _on_body_entered(body: Node) -> void:
	if _spent:
		return
	if body.is_in_group("player"):
		_spent = true
		if body.has_method("is_blocking") and body.is_blocking():
			Sfx.play(self, "block", global_position)
			queue_free()
			return
		RunState.apply_damage(damage)
		Sfx.play(self, "hit", global_position)
		queue_free()
	elif body is StaticBody3D:
		_spent = true
		queue_free()
