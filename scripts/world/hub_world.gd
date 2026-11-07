extends Node3D

## Acampamento com props e personagens KayKit.


func _ready() -> void:
	_build_ground()
	_build_campfire(Vector3(0, 0, 0))
	_add_fire_light(Vector3(0, 1.2, 0))
	_build_npc(Vector3(-4, 0, -2), "Ferreiro", "blacksmith", KayKit.BARBARIAN, KayKit.ANVIL)
	_build_npc(Vector3(0, 0, -4), "Alquimista", "alchemist", KayKit.MAGE, KayKit.JOURNAL)
	_build_npc(Vector3(4, 0, -2), "Cartógrafo", "cartographer", KayKit.RANGER, KayKit.MAP_PROP)
	_build_portal(Vector3(0, 0, 6))


func _instance_model(path: String, pos: Vector3, parent: Node = null, scale_f: float = 1.0) -> Node3D:
	var host: Node = parent if parent else self
	return KayKit.add_model(host, path, pos, 0.0, scale_f)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var visual := Node3D.new()
	body.add_child(visual)
	for x in range(-5, 6):
		for z in range(-5, 6):
			KayKit.add_model(
				visual,
				KayKit.FLOOR_DIRT,
				Vector3(float(x) * KayKit.TILE, 0.0, float(z) * KayKit.TILE)
			)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(44, 1, 44)
	col.shape = shape
	col.position.y = -0.5
	body.add_child(col)
	_build_tree_ring()


func _build_tree_ring() -> void:
	var trees: Array[String] = [KayKit.TREE_A, KayKit.TREE_B, KayKit.TREE_C]
	var rocks: Array[String] = [KayKit.ROCK_LARGE_A, KayKit.ROCK_LARGE_B, KayKit.ROCK_LARGE_C]
	# Anel interno fechado.
	const INNER_COUNT := 32
	const INNER_R := 14.5
	for i in INNER_COUNT:
		var ang := float(i) / float(INNER_COUNT) * TAU
		_add_tree(
			trees[i % trees.size()],
			Vector3(cos(ang) * INNER_R, 0.0, sin(ang) * INNER_R),
			ang + PI,
			1.15 + float(i % 5) * 0.08
		)
	# Pedras nos vãos entre as árvores do anel interno.
	for i in INNER_COUNT:
		var ang := (float(i) + 0.5) / float(INNER_COUNT) * TAU
		var r := INNER_R + 0.35
		_add_rock(
			rocks[i % rocks.size()],
			Vector3(cos(ang) * r, 0.0, sin(ang) * r),
			ang + float(i) * 0.7,
			0.72 + float(i % 4) * 0.06
		)
	# Anel externo intercalado.
	const OUTER_COUNT := 28
	const OUTER_R := 17.0
	for i in OUTER_COUNT:
		var ang := (float(i) + 0.5) / float(OUTER_COUNT) * TAU
		_add_tree(
			trees[(i + 1) % trees.size()],
			Vector3(cos(ang) * OUTER_R, 0.0, sin(ang) * OUTER_R),
			ang,
			1.25 + float(i % 4) * 0.1
		)
	# Pedras nos vãos do anel externo.
	for i in OUTER_COUNT:
		var ang := float(i) / float(OUTER_COUNT) * TAU
		var r := OUTER_R + 0.4
		_add_rock(
			rocks[(i + 2) % rocks.size()],
			Vector3(cos(ang) * r, 0.0, sin(ang) * r),
			ang * 1.3,
			0.8 + float(i % 3) * 0.08
		)


func _add_tree(path: String, pos: Vector3, rot_y: float, scale_f: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	KayKit.add_model(root, path, Vector3.ZERO, 0.0, scale_f)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	# Tronco + copa (folhas).
	_add_cylinder_shape(body, 0.55 * scale_f, 2.4 * scale_f, Vector3(0.0, 1.2 * scale_f, 0.0))
	_add_sphere_shape(body, 1.85 * scale_f, Vector3(0.0, 3.0 * scale_f, 0.0))


func _add_rock(path: String, pos: Vector3, rot_y: float, scale_f: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	add_child(root)
	KayKit.add_model(root, path, Vector3.ZERO, 0.0, scale_f)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	# Bloco generoso: pedras grandes formam a barreira orgânica.
	var h := 2.8 * scale_f
	_add_box_shape(body, Vector3(2.6 * scale_f, h, 2.4 * scale_f), Vector3(0.0, h * 0.45, 0.0))


func _build_campfire(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var candle_a := KayKit.add_model(root, KayKit.CANDLE_LIT, Vector3(0.15, 0, 0.1), 0.0, 1.4)
	var candle_b := KayKit.add_model(root, KayKit.CANDLE_LIT, Vector3(-0.2, 0, -0.05), 0.4, 1.2)
	var torch := KayKit.add_model(root, KayKit.TORCH_LIT, Vector3(0, 0, 0), 0.0, 0.9)
	# Mesh da chama não projeta sombra (senão o omni some em fatias).
	for m in [candle_a, candle_b, torch]:
		if m:
			_disable_shadows(m)

	# Caixa e barril: colisão + sombra da luz da fogueira.
	var crate_pos := Vector3(1.2, 0, 0.8)
	var crate_scale := 0.8
	var crate_rot := 0.3
	KayKit.add_model(root, KayKit.BOX_SMALL, crate_pos, crate_rot, crate_scale)
	_add_prop_collision(root, crate_pos, crate_rot, Vector3(crate_scale, crate_scale, crate_scale), true)

	var barrel_pos := Vector3(-1.4, 0, 0.6)
	KayKit.add_model(root, KayKit.BARREL, barrel_pos)
	_add_prop_collision(root, barrel_pos, 0.0, Vector3(1.0, 1.02, 1.0), false)


func _add_prop_collision(
	parent: Node3D, local_pos: Vector3, rot_y: float, size: Vector3, is_box: bool
) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = local_pos
	body.rotation.y = rot_y
	parent.add_child(body)
	if is_box:
		_add_box_shape(body, size, Vector3(0.0, size.y * 0.5, 0.0))
	else:
		_add_cylinder_shape(body, size.x * 0.5, size.y, Vector3(0.0, size.y * 0.5, 0.0))


func _add_fire_light(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	# Acima das velas: ilumina em volta e projeta sombra do barril/caixa.
	light.position = pos + Vector3(0.0, 0.85, 0.0)
	light.light_color = Color(1.0, 0.65, 0.3)
	light.light_energy = 2.4
	light.omni_range = 14.0
	light.omni_attenuation = 0.9
	light.shadow_enabled = true
	light.shadow_blur = 2.0
	light.shadow_bias = 0.05
	light.shadow_normal_bias = 1.2
	add_child(light)


func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)


func _build_npc(pos: Vector3, label: String, action: String, model_path: String, prop_path: String) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var body := StaticBody3D.new()
	root.add_child(body)
	var character := _instance_model(model_path, Vector3.ZERO, body)
	if character:
		var ap := KayKitAnim.setup(character, false)
		KayKitAnim.play_idle(ap, false)
	# Gira o root (não o mesh) para a fogueira. O mesh já tem +180° no setup.
	var toward := -root.global_position
	toward.y = 0.0
	if toward.length() > 0.1:
		root.look_at(root.global_position + toward, Vector3.UP)
	_instance_model(prop_path, Vector3(0.7, 0, 0.3), body, 0.9)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 1.6, 0.5)
	col.shape = shape
	col.position.y = 0.8
	body.add_child(col)

	var area := Area3D.new()
	area.set_script(load("res://scripts/interactables/interactable.gd"))
	area.prompt_text = label
	area.action_id = action
	area.add_to_group("hub_interactable")
	root.add_child(area)
	var ac := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	ashape.radius = 1.8
	ac.shape = ashape
	ac.position.y = 0.9
	area.add_child(ac)


func _build_portal(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	KayKit.add_model(root, KayKit.MIRROR, Vector3.ZERO, 0.0, 1.4)
	KayKit.add_model(root, KayKit.COLUMN, Vector3(-1.2, 0, 0), 0.0, 1.6)
	KayKit.add_model(root, KayKit.COLUMN, Vector3(1.2, 0, 0), 0.0, 1.6)

	# Colisão física (layer world). Area3D abaixo só detecta interação.
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	_add_box_shape(body, Vector3(2.4, 4.0, 0.45), Vector3(0.0, 2.0, 0.0))
	_add_cylinder_shape(body, 0.55, 2.3, Vector3(-1.2, 1.15, 0.0))
	_add_cylinder_shape(body, 0.55, 2.3, Vector3(1.2, 1.15, 0.0))

	var tag := Label3D.new()
	tag.text = "Portal da Masmorra"
	tag.position = Vector3(0, 3.4, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	GameFonts.style_label3d(tag, 42)
	root.add_child(tag)

	var area := Area3D.new()
	area.set_script(load("res://scripts/interactables/interactable.gd"))
	area.prompt_text = "Entrar na masmorra"
	area.action_id = "portal"
	area.add_to_group("hub_interactable")
	root.add_child(area)
	var ac := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	ashape.radius = 2.0
	ac.shape = ashape
	ac.position.y = 1.0
	area.add_child(ac)


func _add_box_shape(body: StaticBody3D, size: Vector3, local_pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = local_pos
	body.add_child(col)


func _add_cylinder_shape(body: StaticBody3D, radius: float, height: float, local_pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	col.shape = shape
	col.position = local_pos
	body.add_child(col)


func _add_sphere_shape(body: StaticBody3D, radius: float, local_pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	col.shape = shape
	col.position = local_pos
	body.add_child(col)
