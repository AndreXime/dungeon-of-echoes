extends StaticBody3D

@export var max_hp: int = 3

var hp: int


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemy")
	hp = max_hp
	collision_layer = 4
	collision_mask = 1
	if not has_node("ModelRoot") and ResourceLoader.exists("res://assets/models/cut_vines.glb"):
		var root := Node3D.new()
		root.name = "ModelRoot"
		add_child(root)
		var packed := load("res://assets/models/cut_vines.glb") as PackedScene
		if packed:
			root.add_child(packed.instantiate())
	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.6, 2.2, 0.4)
		col.shape = shape
		col.position.y = 1.1
		add_child(col)


func take_hit(damage: int, _knockback: Vector3) -> void:
	hp -= damage
	Sfx.play(self, "hit", global_position)
	if hp <= 0:
		Sfx.play(self, "break", global_position)
		queue_free()
