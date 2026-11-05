extends Area2D

var _velocity: Vector2 = Vector2.ZERO

func setup(direction: Vector2, speed: float = 400.0) -> void:
	_velocity = direction.normalized() * speed
	rotation = _velocity.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += _velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(1)
	queue_free()
