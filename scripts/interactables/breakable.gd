extends StaticBody3D

@export var gold_reward: int = 5
@export var max_hp: int = 2
@export var model_path: String = KayKit.BOX_SMALL

var hp: int


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemy")
	hp = max_hp
	collision_layer = 4
	collision_mask = 1
	_attach_model()


func _attach_model() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	var model := KayKit.instantiate(model_path)
	if model == null:
		return
	add_child(model)


func take_hit(damage: int, _knockback: Vector3) -> void:
	hp -= damage
	if hp <= 0:
		RunState.add_gold(gold_reward)
		if RunState.has_relic(RunState.RELIC_CRYSTAL_VAMP):
			RunState.heal(4)
		Juice.on_break(global_position)
		queue_free()
	else:
		Juice.flash(self, Color(2.0, 1.8, 1.4), 0.06)
		Sfx.play(self, "hit", global_position)
