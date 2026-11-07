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
	for i in 18:
		var ang := float(i) / 18.0 * TAU
		var r := 14.0 + float(i % 3)
		KayKit.add_model(
			self,
			KayKit.TREE_A if i % 2 == 0 else KayKit.TREE_B,
			Vector3(cos(ang) * r, 0.0, sin(ang) * r),
			ang,
			1.1 + float(i % 4) * 0.1
		)


func _build_campfire(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	KayKit.add_model(root, KayKit.CANDLE_LIT, Vector3(0.15, 0, 0.1), 0.0, 1.4)
	KayKit.add_model(root, KayKit.CANDLE_LIT, Vector3(-0.2, 0, -0.05), 0.4, 1.2)
	KayKit.add_model(root, KayKit.TORCH_LIT, Vector3(0, 0, 0), 0.0, 0.9)
	KayKit.add_model(root, KayKit.BOX_SMALL, Vector3(1.2, 0, 0.8), 0.3, 0.8)
	KayKit.add_model(root, KayKit.BARREL, Vector3(-1.4, 0, 0.6))


func _add_fire_light(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.65, 0.3)
	light.light_energy = 2.2
	light.omni_range = 12.0
	light.shadow_enabled = true
	add_child(light)


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

	var tag := Label3D.new()
	tag.text = label
	tag.position = Vector3(0, 2.2, 0)
	tag.font_size = 48
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(tag)

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
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 1.5, 0)
	glow.light_color = Color(0.45, 0.55, 1.0)
	glow.light_energy = 1.4
	glow.omni_range = 6.0
	root.add_child(glow)
	var tag := Label3D.new()
	tag.text = "Portal da Masmorra"
	tag.position = Vector3(0, 3.4, 0)
	tag.font_size = 42
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
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
