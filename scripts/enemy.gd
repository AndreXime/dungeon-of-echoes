extends CharacterBody2D

signal died

const SPEED := 90.0
const MAX_HEALTH := 2

var health: int = MAX_HEALTH
var _player: Node2D

func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player")
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var direction := global_position.direction_to(_player.global_position)
	velocity = direction * SPEED
	move_and_slide()

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		died.emit()
		queue_free()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
