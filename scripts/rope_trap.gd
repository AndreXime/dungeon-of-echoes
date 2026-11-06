extends Area3D

@export var trip_damage: int = 8
var _armed := true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not _armed or not body.is_in_group("player"):
		return
	_armed = false
	RunState.apply_damage(trip_damage)
	Sfx.play(self, "break", global_position)
	if body is CharacterBody3D:
		var away: Vector3 = (body.global_position - global_position).normalized()
		away.y = 0.0
		if away.length() < 0.1:
			away = Vector3(0, 0, 1)
		(body as CharacterBody3D).velocity += away * 7.0 + Vector3(0, 3.5, 0)
	visible = false
	get_tree().create_timer(0.2).timeout.connect(queue_free)
