extends RefCounted


static func make_dagger() -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(0.03, 0.03, 0.28), Vector3(0, 0, -0.14), Color(0.75, 0.75, 0.8)))
	root.add_child(_box(Vector3(0.08, 0.02, 0.03), Vector3(0, 0, 0.02), Color(0.35, 0.22, 0.12)))
	return root


static func make_crossbow() -> Node3D:
	var root := Node3D.new()
	root.add_child(_box(Vector3(0.08, 0.06, 0.35), Vector3(0, 0, -0.1), Color(0.4, 0.28, 0.16)))
	root.add_child(_box(Vector3(0.35, 0.04, 0.05), Vector3(0, 0.02, -0.2), Color(0.3, 0.22, 0.14)))
	return root


static func make_bolt_mesh() -> MeshInstance3D:
	return _box(Vector3(0.04, 0.04, 0.28), Vector3.ZERO, Color(0.55, 0.45, 0.3))


static func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	return mi
