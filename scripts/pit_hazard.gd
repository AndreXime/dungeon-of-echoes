extends Area3D

@export var fall_damage: int = 18


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	RunState.apply_damage(fall_damage)
	Sfx.play(self, "hit", global_position)
	if body is CharacterBody3D:
		body.global_position += Vector3(0, 2.5, 2.0)
		body.velocity = Vector3.ZERO
