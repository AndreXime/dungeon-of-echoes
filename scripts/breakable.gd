extends StaticBody3D

@export var gold_reward: int = 5
@export var max_hp: int = 2
@export_file("*.glb") var model_path: String = "res://assets/models/crate.glb"

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
	if not ResourceLoader.exists(model_path):
		return
	var packed := load(model_path) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	add_child(model)
	var PixelMat = preload("res://scripts/pixel_material.gd")
	PixelMat.enable_vertex_colors(model)
	if model_path.ends_with("crate.glb"):
		model.position = Vector3(0, -0.4, 0)
	elif model_path.ends_with("barrel.glb"):
		model.position = Vector3(0, -0.45, 0)
	elif model_path.ends_with("vase.glb"):
		model.position = Vector3(0, -0.4, 0)


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
