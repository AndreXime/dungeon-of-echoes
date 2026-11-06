extends Node3D

## Monta o acampamento com modelos GLB.

const PixelMat = preload("res://scripts/pixel_material.gd")


func _ready() -> void:
	_build_ground()
	_instance_glb("res://assets/models/campfire.glb", Vector3(0, 0, 0))
	_add_fire_light(Vector3(0, 1.2, 0))
	_build_npc(Vector3(-4, 0, -2), "Ferreiro", "blacksmith", "res://assets/models/npc_blacksmith.glb")
	_build_npc(Vector3(0, 0, -4), "Alquimista", "alchemist", "res://assets/models/npc_alchemist.glb")
	_build_npc(Vector3(4, 0, -2), "Cartógrafo", "cartographer", "res://assets/models/npc_cartographer.glb")
	_build_portal(Vector3(0, 0, 6))


func _flat(color: Color) -> StandardMaterial3D:
	return PixelMat.make(color)


func _instance_glb(path: String, pos: Vector3, parent: Node = null) -> Node3D:
	var host: Node = parent if parent else self
	if not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	model.position = pos
	host.add_child(model)
	PixelMat.enable_vertex_colors(model)
	return model


func _build_ground() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(40, 1, 40)
	mi.mesh = box
	mi.material_override = _flat(Color(0.28, 0.32, 0.26))
	mi.position.y = -0.5
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 1, 40)
	col.shape = shape
	col.position.y = -0.5
	body.add_child(col)


func _add_fire_light(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.65, 0.3)
	light.light_energy = 2.2
	light.omni_range = 12.0
	light.shadow_enabled = true
	add_child(light)


func _build_npc(pos: Vector3, label: String, action: String, model_path: String) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	var body := StaticBody3D.new()
	root.add_child(body)
	_instance_glb(model_path, Vector3.ZERO, body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 1.6, 0.5)
	col.shape = shape
	col.position.y = 0.8
	body.add_child(col)

	var tag := Label3D.new()
	tag.text = label
	tag.position = Vector3(0, 2.0, 0)
	tag.font_size = 48
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(tag)

	var area := Area3D.new()
	area.set_script(load("res://scripts/interactable.gd"))
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
	_instance_glb("res://assets/models/portal.glb", Vector3.ZERO, root)
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
	area.set_script(load("res://scripts/interactable.gd"))
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
