extends StaticBody2D

signal health_changed(current: int, max_health: int)
signal destroyed

const MAX_HEALTH := 20

var health: int = MAX_HEALTH
var _destroyed: bool = false

func _ready() -> void:
	add_to_group("well")
	collision_layer = 1
	collision_mask = 0
	health_changed.emit(health, MAX_HEALTH)

func take_damage(amount: int) -> void:
	if _destroyed:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_destroyed = true
		destroyed.emit()
