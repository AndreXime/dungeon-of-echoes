extends Node

const PixelMat = preload("res://scripts/pixel_material.gd")
const ROOM_SIZE := Vector3(16, 5, 16)


func _add_model(parent: Node, packed: PackedScene, local_pos: Vector3 = Vector3.ZERO) -> Node3D:
	var model := packed.instantiate() as Node3D
	model.position = local_pos
	parent.add_child(model)
	PixelMat.enable_vertex_colors(model)
	return model

const ENEMIES_CATACOMBS := [
	"res://scenes/enemies/skeleton.tscn",
	"res://scenes/enemies/crystal_bat.tscn",
	"res://scenes/enemies/slime.tscn",
]
const ENEMIES_MINES := [
	"res://scenes/enemies/corrupted_miner.tscn",
	"res://scenes/enemies/stone_automaton.tscn",
	"res://scenes/enemies/acid_spider.tscn",
]
const ENEMIES_GARDEN := [
	"res://scenes/enemies/wood_guardian.tscn",
	"res://scenes/enemies/vine_golem.tscn",
	"res://scenes/enemies/foliage_shooter.tscn",
]

const RELICS := [
	{"id": "glass_eye", "name": "Olho de Vidro", "desc": "Projéteis marcam. Melee seguinte causa dobro."},
	{"id": "crystal_vamp", "name": "Vampirismo Cristalino", "desc": "Quebrar cenário cura um pouco."},
	{"id": "volcanic", "name": "Essência Vulcânica", "desc": "Impactos de lâmina geram explosão."},
	{"id": "gravity_core", "name": "Núcleo Gravitacional", "desc": "Ao puxar a adaga, inimigos próximos são atraídos."},
]

signal generation_done(player_spawn: Vector3, exit_pos: Vector3)


func generate(parent: Node3D, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else 1
	RunState.map_rooms.clear()

	var boss_floor := RunState.floor_index % 3 == 0
	var count := rng.randi_range(4, 6)
	var sequence: Array[String] = []
	for i in count:
		if i == count - 1:
			sequence.append("boss" if boss_floor else "end")
		elif i == 0:
			sequence.append("hall")
		else:
			var roll := rng.randf()
			if roll < 0.18:
				sequence.append("treasure")
			elif roll < 0.32:
				sequence.append("bridge")
			elif roll < 0.46:
				sequence.append("hazard")
			elif roll < 0.58:
				sequence.append("cross")
			else:
				sequence.append("hall")

	var cursor_z := 0.0
	var player_spawn := Vector3(0, 0.2, 2)
	var exit_pos := Vector3.ZERO
	var reveal := MetaProgress.cartographer_level

	for i in sequence.size():
		var kind: String = sequence[i]
		var room := _build_room(kind, rng)
		room.name = "Room_%d_%s" % [i, kind]
		room.position = Vector3(0, 0, cursor_z)
		parent.add_child(room)

		var map_entry := {
			"index": i,
			"kind": kind,
			"biome": RunState.biome,
			"revealed": i == 0 or i < reveal or kind in ["treasure", "boss", "end"],
			"cleared": false,
		}
		RunState.map_rooms.append(map_entry)

		if i == 0:
			player_spawn = room.global_position + Vector3(0, 0.2, ROOM_SIZE.z * 0.3)
		if kind == "end" or kind == "boss":
			exit_pos = room.global_position + Vector3(0, 1.0, -ROOM_SIZE.z * 0.3)
			_add_exit_trigger(room, Vector3(0, 1.0, -ROOM_SIZE.z * 0.3), kind == "boss")
		cursor_z -= ROOM_SIZE.z

	generation_done.emit(player_spawn, exit_pos)


func _palette() -> Dictionary:
	match RunState.biome:
		RunState.BIOME_MINES:
			return {
				"stone": Color(0.38, 0.22, 0.16),
				"floor": Color(0.2, 0.12, 0.1),
				"wood": Color(0.42, 0.28, 0.14),
				"accent": Color(1.0, 0.45, 0.2),
				"light": Color(1.0, 0.55, 0.3),
			}
		RunState.BIOME_GARDEN:
			return {
				"stone": Color(0.22, 0.32, 0.24),
				"floor": Color(0.14, 0.22, 0.16),
				"wood": Color(0.3, 0.38, 0.2),
				"accent": Color(0.45, 0.75, 0.35),
				"light": Color(0.55, 0.85, 0.55),
			}
		_:
			return {
				"stone": Color(0.32, 0.33, 0.36),
				"floor": Color(0.22, 0.23, 0.25),
				"wood": Color(0.35, 0.25, 0.16),
				"accent": Color(0.45, 0.4, 0.6),
				"light": Color(1.0, 0.75, 0.45),
			}


func _flat(color: Color) -> StandardMaterial3D:
	return PixelMat.make(color)


func _add_box(parent: Node, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _flat(color)
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _enemy_pool() -> Array:
	match RunState.biome:
		RunState.BIOME_MINES:
			return ENEMIES_MINES
		RunState.BIOME_GARDEN:
			return ENEMIES_GARDEN
		_:
			return ENEMIES_CATACOMBS


func _build_room(kind: String, rng: RandomNumberGenerator) -> Node3D:
	var room := Node3D.new()
	var pal := _palette()
	var stone: Color = pal["stone"]
	var floor_c: Color = pal["floor"]
	var wood: Color = pal["wood"]
	var hz := ROOM_SIZE.z * 0.5
	var hx := ROOM_SIZE.x * 0.5
	var hy := ROOM_SIZE.y * 0.5

	_add_box(room, Vector3(ROOM_SIZE.x, 0.5, ROOM_SIZE.z), Vector3(0, -0.25, 0), floor_c)
	_add_box(room, Vector3(ROOM_SIZE.x, 0.4, ROOM_SIZE.z), Vector3(0, ROOM_SIZE.y, 0), stone)
	_add_box(room, Vector3(6.0, ROOM_SIZE.y, 0.5), Vector3(-5.0, hy, hz), stone)
	_add_box(room, Vector3(6.0, ROOM_SIZE.y, 0.5), Vector3(5.0, hy, hz), stone)
	_add_box(room, Vector3(6.0, ROOM_SIZE.y, 0.5), Vector3(-5.0, hy, -hz), stone)
	_add_box(room, Vector3(6.0, ROOM_SIZE.y, 0.5), Vector3(5.0, hy, -hz), stone)
	_add_box(room, Vector3(0.5, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(hx, hy, 0), stone)
	_add_box(room, Vector3(0.5, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(-hx, hy, 0), stone)

	_spawn_torch(room, Vector3(-5.5, 2.2, 0))
	_spawn_torch(room, Vector3(5.5, 2.2, 0))

	var light := OmniLight3D.new()
	light.position = Vector3(0, 3.2, 0)
	light.light_color = pal["light"]
	light.light_energy = 1.5
	light.omni_range = 14.0
	light.shadow_enabled = true
	room.add_child(light)

	match kind:
		"bridge":
			_spawn_pit(room, Vector3(-4.5, 0, 0))
			_spawn_pit(room, Vector3(4.5, 0, 0))
			_add_box(room, Vector3(3.0, 0.3, 10.0), Vector3(0, 0.2, 0), wood)
			_spawn_spikes(room, Vector3(-4.5, 0.15, 3))
			_spawn_spikes(room, Vector3(4.5, 0.15, -3))
			_spawn_rope(room, Vector3(0, 0.4, 2))
		"hazard":
			_spawn_pit(room, Vector3(-3, 0, 1))
			_spawn_pit(room, Vector3(3, 0, -2))
			_spawn_rope(room, Vector3(0, 0.4, 0))
			_spawn_spikes(room, Vector3(0, 0.15, 3))
		"cross":
			_add_box(room, Vector3(2, 2, 2), Vector3(-4, 1, -3), stone)
			_add_box(room, Vector3(2, 1.2, 2), Vector3(4, 0.6, 2), stone)
			_spawn_spikes(room, Vector3(0, 0.15, 3))
			if rng.randf() > 0.35:
				_spawn_random_relic(room, Vector3(0, 0.2, -2), rng)
		"treasure":
			_add_box(room, Vector3(1.2, 1.2, 1.2), Vector3(0, 0.6, 0), pal["accent"])
			_spawn_random_relic(room, Vector3(2.5, 0.2, -1), rng)
			_spawn_random_relic(room, Vector3(-2.5, 0.2, -1), rng)
			for _i in 3:
				_spawn_crate(room, Vector3(rng.randf_range(-4, 4), 0.45, rng.randf_range(-3, 3)))
		"boss":
			_add_box(room, Vector3(2.0, 2.8, 0.5), Vector3(0, 1.4, -5), pal["accent"])
			_spawn_boss(room, Vector3(0, 0.1, -1))
			_spawn_random_relic(room, Vector3(3, 0.2, 2), rng)
		"end":
			_add_box(room, Vector3(1.5, 2.5, 0.4), Vector3(0, 1.25, -5), pal["accent"])
			_spawn_random_relic(room, Vector3(2.5, 0.2, -2), rng)
			_spawn_enemy(room, Vector3(rng.randf_range(-2, 2), 0.1, 0), rng)
		_:
			_add_box(room, Vector3(1.5, 1.5, 1.5), Vector3(-5, 0.75, 0), stone)
			if rng.randf() > 0.6:
				_spawn_random_relic(room, Vector3(4, 0.2, -2), rng)

	if RunState.biome == RunState.BIOME_GARDEN:
		_spawn_vines(room, Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-3, 3)))
		if rng.randf() > 0.4:
			_spawn_vines(room, Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-3, 3)))
		_scatter_grass(room, rng)
	elif RunState.biome == RunState.BIOME_MINES and rng.randf() > 0.4:
		_spawn_rope(room, Vector3(rng.randf_range(-3, 3), 0.4, rng.randf_range(-2, 2)))

	if kind not in ["end", "boss", "treasure"]:
		var n := 1 + int(rng.randf() > 0.45) + int(RunState.floor_index > 4)
		for _i in n:
			_spawn_enemy(room, Vector3(rng.randf_range(-3, 3), 0.1, rng.randf_range(-3, 1)), rng)
	elif kind == "treasure" and rng.randf() > 0.5:
		_spawn_enemy(room, Vector3(0, 0.1, 3), rng)

	if kind != "boss" and rng.randf() > 0.35:
		_spawn_crate(room, Vector3(rng.randf_range(-5, 5), 0.45, rng.randf_range(-4, 4)))
	if rng.randf() > 0.55:
		_spawn_crate(room, Vector3(rng.randf_range(-5, 5), 0.45, rng.randf_range(-4, 4)))

	return room


func _carve_pit(room: Node3D, pos: Vector3, size: Vector3) -> void:
	# Remove solid floor under pit by covering with dark void marker + hazard.
	var void_mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	void_mi.mesh = box
	void_mi.position = pos + Vector3(0, -0.05, 0)
	void_mi.material_override = _flat(Color(0.05, 0.04, 0.06))
	room.add_child(void_mi)
	_spawn_pit_area(room, pos + Vector3(0, 0.4, 0), size)


func _spawn_pit(room: Node3D, local_pos: Vector3) -> void:
	_carve_pit(room, local_pos, Vector3(3.2, 0.5, 3.2))


func _spawn_pit_area(room: Node3D, pos: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.position = pos
	area.set_script(load("res://scripts/pit_hazard.gd"))
	room.add_child(area)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x * 0.85, 1.2, size.z * 0.85)
	col.shape = shape
	area.add_child(col)


func _spawn_torch(room: Node3D, local_pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = local_pos
	room.add_child(root)
	if ResourceLoader.exists("res://assets/models/torch.glb"):
		var packed := load("res://assets/models/torch.glb") as PackedScene
		if packed:
			_add_model(root, packed)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 0.35, 0)
	glow.light_color = Color(1.0, 0.7, 0.35)
	glow.light_energy = 0.9
	glow.omni_range = 5.0
	root.add_child(glow)


func _spawn_rope(room: Node3D, local_pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = local_pos
	room.add_child(root)
	if ResourceLoader.exists("res://assets/models/rope_trap.glb"):
		var packed := load("res://assets/models/rope_trap.glb") as PackedScene
		if packed:
			_add_model(root, packed)
	var area := Area3D.new()
	area.set_script(load("res://scripts/rope_trap.gd"))
	root.add_child(area)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 0.6, 0.4)
	col.shape = shape
	col.position.y = 0.2
	area.add_child(col)


func _spawn_vines(room: Node3D, local_pos: Vector3) -> void:
	var vines := StaticBody3D.new()
	vines.position = local_pos
	vines.set_script(load("res://scripts/cut_vines.gd"))
	room.add_child(vines)


func _scatter_grass(room: Node3D, rng: RandomNumberGenerator) -> void:
	if not ResourceLoader.exists("res://assets/models/grass.glb"):
		return
	var packed := load("res://assets/models/grass.glb") as PackedScene
	if packed == null:
		return
	for _i in rng.randi_range(4, 8):
		var g := _add_model(room, packed, Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6)))
		g.rotate_y(rng.randf() * TAU)
		g.scale = Vector3.ONE * rng.randf_range(0.8, 1.3)


func _spawn_enemy(room: Node3D, local_pos: Vector3, rng: RandomNumberGenerator) -> void:
	var pool := _enemy_pool()
	var path: String = pool[rng.randi_range(0, pool.size() - 1)]
	var enemy_scene := load(path) as PackedScene
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node3D
	enemy.position = local_pos
	if path.ends_with("crystal_bat.tscn"):
		enemy.position.y = 1.6
	room.add_child(enemy)


func _spawn_boss(room: Node3D, local_pos: Vector3) -> void:
	var path := "res://scenes/enemies/boss_skeleton.tscn"
	match RunState.biome:
		RunState.BIOME_MINES:
			path = "res://scenes/enemies/stone_automaton.tscn"
		RunState.BIOME_GARDEN:
			path = "res://scenes/enemies/vine_golem.tscn"
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var boss := packed.instantiate() as Node3D
	boss.position = local_pos
	if "is_boss" in boss:
		boss.set("is_boss", true)
	if "max_hp" in boss:
		boss.set("max_hp", int(boss.get("max_hp") * 1.8))
	if "gold_reward" in boss:
		boss.set("gold_reward", int(boss.get("gold_reward")) * 3)
	if "essence_reward" in boss:
		boss.set("essence_reward", int(boss.get("essence_reward")) * 3)
	room.add_child(boss)


func _spawn_crate(room: Node3D, local_pos: Vector3) -> void:
	var paths := [
		"res://scenes/breakable_crate.tscn",
		"res://scenes/breakable_barrel.tscn",
		"res://scenes/breakable_vase.tscn",
	]
	var path: String = paths[randi() % paths.size()]
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var prop := packed.instantiate() as Node3D
	prop.position = local_pos
	room.add_child(prop)


func _spawn_spikes(room: Node3D, local_pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = local_pos
	room.add_child(root)
	if ResourceLoader.exists("res://assets/models/spikes.glb"):
		var packed := load("res://assets/models/spikes.glb") as PackedScene
		if packed:
			_add_model(root, packed)
	var area := Area3D.new()
	area.set_script(load("res://scripts/spike_trap.gd"))
	root.add_child(area)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.7, 0.8)
	col.shape = shape
	col.position.y = 0.3
	area.add_child(col)


func _spawn_random_relic(room: Node3D, local_pos: Vector3, rng: RandomNumberGenerator) -> void:
	var luck_bonus := MetaProgress.relic_luck * 0.08
	if rng.randf() > 0.55 + luck_bonus:
		return
	var relic: Dictionary = RELICS[rng.randi_range(0, RELICS.size() - 1)]
	_spawn_relic(room, local_pos, relic["id"], relic["name"], relic["desc"])


func _spawn_relic(room: Node3D, local_pos: Vector3, relic_id: String, relic_name: String, relic_desc: String) -> void:
	var root := Node3D.new()
	root.position = local_pos
	room.add_child(root)
	if ResourceLoader.exists("res://assets/models/relic_pedestal.glb"):
		var packed := load("res://assets/models/relic_pedestal.glb") as PackedScene
		if packed:
			_add_model(root, packed)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.7, 0)
	light.light_color = Color(0.5, 0.85, 1.0)
	light.light_energy = 1.2
	light.omni_range = 4.0
	root.add_child(light)
	var label := Label3D.new()
	label.name = "Label"
	label.text = relic_name
	label.position = Vector3(0, 1.1, 0)
	label.font_size = 42
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	var area := Area3D.new()
	area.set_script(load("res://scripts/relic_pedestal.gd"))
	area.relic_id = relic_id
	area.relic_name = relic_name
	area.relic_desc = relic_desc
	root.add_child(area)
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.4
	col.shape = shape
	col.position.y = 0.5
	area.add_child(col)


func _add_exit_trigger(room: Node3D, local_pos: Vector3, requires_boss: bool) -> void:
	var area := Area3D.new()
	area.name = "ExitTrigger"
	area.position = local_pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.body_entered.connect(func(body: Node) -> void:
		if not body.is_in_group("player"):
			return
		if requires_boss and not RunState.boss_cleared:
			_show_run_message("Derrote o chefe para avançar.")
			return
		if RunState.floor_index >= 9:
			RunState.finish_run_and_return_to_hub()
		else:
			RunState.go_to_next_floor()
	)
	room.add_child(area)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5, 3.0, 2.0)
	col.shape = shape
	area.add_child(col)
	var tag := Label3D.new()
	tag.text = "Próximo andar" if RunState.floor_index < 9 else "Vitória"
	tag.position = Vector3(0, 2.2, 0)
	tag.font_size = 56
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	area.add_child(tag)


func _show_run_message(text: String) -> void:
	for node in get_tree().get_nodes_in_group("run_message"):
		if node is Label:
			node.text = text
			get_tree().create_timer(2.0).timeout.connect(func() -> void:
				if is_instance_valid(node):
					node.text = ""
			)
			return
