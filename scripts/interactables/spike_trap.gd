extends Area3D

@export var damage: int = 25


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 6
	monitoring = true


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		RunState.apply_damage(damage)
	elif body.is_in_group("enemy") and body.has_method("take_hit"):
		body.take_hit(999, Vector3.ZERO)
