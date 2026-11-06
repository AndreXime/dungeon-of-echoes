extends Node3D

## Floresta low poly com props GLB. Borda = muro de árvores (sem parede invisível / fog de borda).

const MAP_SIZE := 160.0
const HALF := MAP_SIZE * 0.5
const TREE_COUNT := 140
const ROCK_COUNT := 55
const GRASS_COVERAGE := 0.6
const GRASS_CELL := 1.35
const CLEARING_RADIUS := 8.0
const EDGE_TREE_SPACING := 1.35
const EDGE_ROWS := 3
const EDGE_INSET := 1.2

const TREE_PATHS := [
	"res://assets/models/tree_a.glb",
	"res://assets/models/tree_b.glb",
]
const ROCK_PATHS := [
	"res://assets/models/rock_a.glb",
	"res://assets/models/rock_b.glb",
]
const GRASS_PATH := "res://assets/models/grass.glb"

var _rng := RandomNumberGenerator.new()
var _tree_scenes: Array[PackedScene] = []
var _rock_scenes: Array[PackedScene] = []
var _grass_scene: PackedScene
var _mat_ground: StandardMaterial3D


func _ready() -> void:
	_rng.seed = 20261106
	_load_props()
	_build_materials()
	_build_ground()
	_build_tree_wall()
	_scatter_props()


func _load_props() -> void:
	for path in TREE_PATHS:
		var packed := load(path) as PackedScene
		if packed:
			_tree_scenes.append(packed)
	for path in ROCK_PATHS:
		var packed := load(path) as PackedScene
		if packed:
			_rock_scenes.append(packed)
	_grass_scene = load(GRASS_PATH) as PackedScene


func _build_materials() -> void:
	_mat_ground = StandardMaterial3D.new()
	_mat_ground.albedo_color = Color(0.34, 0.52, 0.28)
	_mat_ground.roughness = 1.0


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	add_child(body)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	mesh_inst.mesh = box
	mesh_inst.position.y = -0.5
	mesh_inst.material_override = _mat_ground
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 1.0, MAP_SIZE)
	col.shape = shape
	col.position.y = -0.5
	body.add_child(col)


func _build_tree_wall() -> void:
	if _tree_scenes.is_empty():
		return

	var wall := Node3D.new()
	wall.name = "TreeWall"
	add_child(wall)

	for row in EDGE_ROWS:
		var inset := EDGE_INSET + float(row) * 1.15
		var y_line := -HALF + inset
		var x := -HALF + inset
		while x <= HALF - inset:
			wall.add_child(_spawn_border_tree(Vector3(x, 0.0, y_line)))
			wall.add_child(_spawn_border_tree(Vector3(x, 0.0, HALF - inset)))
			x += EDGE_TREE_SPACING

		var z := -HALF + inset + EDGE_TREE_SPACING
		while z <= HALF - inset - EDGE_TREE_SPACING:
			wall.add_child(_spawn_border_tree(Vector3(-HALF + inset, 0.0, z)))
			wall.add_child(_spawn_border_tree(Vector3(HALF - inset, 0.0, z)))
			z += EDGE_TREE_SPACING


func _spawn_border_tree(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos + Vector3(
		_rng.randf_range(-0.2, 0.2),
		0.0,
		_rng.randf_range(-0.2, 0.2)
	)
	root.rotation.y = _rng.randf_range(0.0, TAU)
	root.scale = Vector3.ONE * _rng.randf_range(1.15, 1.55)

	var scene: PackedScene = _tree_scenes[_rng.randi_range(0, _tree_scenes.size() - 1)]
	root.add_child(scene.instantiate())

	# Colisor mais largo no muro pra não passar entre os troncos.
	var body := StaticBody3D.new()
	root.add_child(body)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.85
	shape.height = 3.2
	col.shape = shape
	col.position.y = 1.6
	body.add_child(col)
	return root


func _scatter_props() -> void:
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)

	var inner_margin := EDGE_INSET + float(EDGE_ROWS) * 1.15 + 2.0

	if not _tree_scenes.is_empty():
		for _i in TREE_COUNT:
			props.add_child(_spawn_tree(_random_ground_point(CLEARING_RADIUS, inner_margin)))

	if not _rock_scenes.is_empty():
		for _i in ROCK_COUNT:
			props.add_child(_spawn_rock(_random_ground_point(CLEARING_RADIUS * 0.6, inner_margin)))

	if _grass_scene != null:
		_scatter_grass_coverage(props, inner_margin)


func _random_ground_point(min_center: float, edge_margin: float) -> Vector3:
	for _attempt in 40:
		var x := _rng.randf_range(-HALF + edge_margin, HALF - edge_margin)
		var z := _rng.randf_range(-HALF + edge_margin, HALF - edge_margin)
		if Vector2(x, z).length() >= min_center:
			return Vector3(x, 0.0, z)
	return Vector3(_rng.randf_range(10.0, 20.0), 0.0, _rng.randf_range(10.0, 20.0))


func _scatter_grass_coverage(props: Node3D, edge_margin: float) -> void:
	var x := -HALF + edge_margin
	while x < HALF - edge_margin:
		var z := -HALF + edge_margin
		while z < HALF - edge_margin:
			if _rng.randf() <= GRASS_COVERAGE:
				var pos := Vector3(
					x + _rng.randf_range(-GRASS_CELL * 0.35, GRASS_CELL * 0.35),
					0.0,
					z + _rng.randf_range(-GRASS_CELL * 0.35, GRASS_CELL * 0.35)
				)
				if Vector2(pos.x, pos.z).length() >= 2.5:
					props.add_child(_spawn_grass(pos))
			z += GRASS_CELL
		x += GRASS_CELL


func _spawn_tree(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf_range(0.0, TAU)
	var scale_f := _rng.randf_range(0.85, 1.45)
	root.scale = Vector3.ONE * scale_f

	var scene: PackedScene = _tree_scenes[_rng.randi_range(0, _tree_scenes.size() - 1)]
	root.add_child(scene.instantiate())

	var body := StaticBody3D.new()
	root.add_child(body)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 2.6
	col.shape = shape
	col.position.y = 1.3
	body.add_child(col)
	return root


func _spawn_rock(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf_range(0.0, TAU)
	var scale_f := _rng.randf_range(0.65, 1.25)
	root.scale = Vector3.ONE * scale_f

	var scene: PackedScene = _rock_scenes[_rng.randi_range(0, _rock_scenes.size() - 1)]
	root.add_child(scene.instantiate())

	var body := StaticBody3D.new()
	root.add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.95, 0.5, 0.8)
	col.shape = shape
	col.position.y = 0.25
	body.add_child(col)
	return root


func _spawn_grass(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = _rng.randf_range(0.0, TAU)
	root.scale = Vector3.ONE * _rng.randf_range(0.8, 1.4)
	var model := _grass_scene.instantiate() as Node3D
	root.add_child(model)
	_disable_shadows(model)
	return root


func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)
