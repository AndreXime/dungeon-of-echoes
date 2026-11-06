extends Area3D

signal interacted

@export var prompt_text: String = "Interagir"
@export var action_id: String = ""

var _player_inside := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 2
	monitoring = true


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		interacted.emit()
		var viewport := get_viewport()
		if viewport:
			viewport.set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func is_player_near() -> bool:
	return _player_inside
