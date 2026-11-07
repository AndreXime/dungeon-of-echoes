extends StaticBody3D

@export var max_hp: int = 3

var hp: int


func _ready() -> void:
	add_to_group("breakable")
	add_to_group("enemy")
	hp = max_hp
	collision_layer = 4
	collision_mask = 1
	if not has_node("ModelRoot"):
		var root := Node3D.new()
		root.name = "ModelRoot"
		add_child(root)
		KayKit.add_model(root, KayKit.BUSH, Vector3.ZERO, 0.0, 1.3)
		KayKit.add_model(root, KayKit.COBWEB, Vector3(0, 1.0, 0.2), 0.2, 0.9)
	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.6, 2.2, 0.4)
		col.shape = shape
		col.position.y = 1.1
		add_child(col)


func take_hit(damage: int, _knockback: Vector3) -> void:
	hp -= damage
	if hp <= 0:
		Juice.on_break(global_position)
		queue_free()
	else:
		Juice.flash(self, Color(1.4, 2.0, 1.2), 0.06)
		Sfx.play(self, "hit", global_position)
