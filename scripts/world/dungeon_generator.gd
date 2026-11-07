extends Node

const TILE := KayKit.TILE
const ROOM_TILES := 4
const ROOM_SIZE := Vector3(TILE * ROOM_TILES, 4.0, TILE * ROOM_TILES)

const ENEMIES_CATACOMBS := [
	"res://scenes/enemies/skeleton_warrior.tscn",
	"res://scenes/enemies/skeleton_rogue.tscn",
	"res://scenes/enemies/skeleton_minion.tscn",
]
const ENEMIES_MINES := [
	"res://scenes/enemies/barbarian.tscn",
	"res://scenes/enemies/skeleton_minion_brute.tscn",
	"res://scenes/enemies/skeleton_minion_ranged.tscn",
]
const ENEMIES_GARDEN := [
	"res://scenes/enemies/ranger.tscn",
	"res://scenes/enemies/rogue_hooded.tscn",
	"res://scenes/enemies/ranger_archer.tscn",
]

const RELICS := [
	{"id": "glass_eye", "name": "Olho de Vidro", "desc": "Projéteis marcam. Melee seguinte causa dobro."},
	{"id": "crystal_vamp", "name": "Vampirismo Cristalino", "desc": "Quebrar cenário cura um pouco."},
	{"id": "volcanic", "name": "Essência Vulcânica", "desc": "Impactos de lâmina geram explosão."},
	{"id": "gravity_core", "name": "Núcleo Gravitacional", "desc": "Ao puxar a adaga, inimigos próximos são atraídos."},
]

signal generation_done(player_spawn: Vector3, exit_pos: Vector3)

var _spawned_relic_ids: Array[String] = []
var _floor_scene: PackedScene
var _wall_scene: PackedScene
var _wall_door_scene: PackedScene
var _wall_half_scene: PackedScene
var _ceiling_scene: PackedScene


func generate(parent: Node3D, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else 1
	RunState.map_rooms.clear()
	_spawned_relic_ids.clear()
	_cache_tiles()

	var layout := _build_layout(rng)
	var player_spawn := Vector3(0, 0.2, 2)
	var exit_pos := Vector3.ZERO
	var reveal := MetaProgress.cartographer_level
	var index := 0

	for cell in layout:
		var kind: String = cell["kind"]
		var grid: Vector2i = cell["grid"]
		var doors: Dictionary = cell["doors"]
		var room := _build_room(kind, rng, doors)
		room.name = "Room_%d_%s" % [index, kind]
		room.position = Vector3(float(grid.x) * ROOM_SIZE.x, 0.0, float(grid.y) * ROOM_SIZE.z)
		parent.add_child(room)

		RunState.map_rooms.append({
			"index": index,
			"kind": kind,
			"biome": RunState.biome,
			"grid": [grid.x, grid.y],
			"revealed": index == 0 or index < reveal or kind in ["treasure", "boss", "end"],
			"cleared": false,
		})

		if index == 0:
			player_spawn = room.global_position + Vector3(0, 0.2, ROOM_SIZE.z * 0.25)
		if kind == "end" or kind == "boss":
			exit_pos = room.global_position + Vector3(0, 1.0, -ROOM_SIZE.z * 0.3)
			_add_exit_trigger(room, Vector3(0, 1.0, -ROOM_SIZE.z * 0.3), kind == "boss")
		index += 1

	generation_done.emit(player_spawn, exit_pos)


func _cache_tiles() -> void:
	_floor_scene = load(KayKit.FLOOR_DIRT if RunState.biome == RunState.BIOME_MINES else KayKit.FLOOR) as PackedScene
	if _floor_scene == null:
		_floor_scene = load(KayKit.FLOOR) as PackedScene
	_wall_scene = load(KayKit.WALL) as PackedScene
	_wall_door_scene = load(KayKit.WALL_DOORWAY) as PackedScene
	_wall_half_scene = load(KayKit.WALL_HALF) as PackedScene
	_ceiling_scene = load(KayKit.CEILING) as PackedScene


func _build_layout(rng: RandomNumberGenerator) -> Array[Dictionary]:
	var boss_floor := RunState.floor_index % 3 == 0
	var main_count := rng.randi_range(5, 7)
	var occupied: Dictionary = {}
	var order: Array[Vector2i] = []
	var kinds: Dictionary = {}
	var doors: Dictionary = {}

	var pos := Vector2i(0, 0)
	occupied[pos] = true
	order.append(pos)
	kinds[pos] = "hall"
	doors[pos] = {"n": false, "s": false, "e": false, "w": false}

	var dirs := [
		Vector2i(0, -1),
		Vector2i(0, -1),
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
	]

	while order.size() < main_count:
		var placed := false
		var shuffled := dirs.duplicate()
		for i in shuffled.size():
			var j := rng.randi_range(i, shuffled.size() - 1)
			var tmp: Vector2i = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = tmp
		for d in shuffled:
			var nxt: Vector2i = pos + d
			if occupied.has(nxt):
				continue
			_link_doors(doors, pos, nxt, d)
			occupied[nxt] = true
			order.append(nxt)
			pos = nxt
			placed = true
			break
		if not placed:
			break

	for i in order.size():
		var p: Vector2i = order[i]
		if i == 0:
			kinds[p] = "hall"
		elif i == order.size() - 1:
			kinds[p] = "boss" if boss_floor else "end"
		else:
			var roll := rng.randf()
			if roll < 0.22:
				kinds[p] = "bridge"
			elif roll < 0.4:
				kinds[p] = "hazard"
			elif roll < 0.55:
				kinds[p] = "cross"
			else:
				kinds[p] = "hall"

	var branch_budget := 1 + int(rng.randf() > 0.45)
	var mid_candidates: Array[Vector2i] = []
	for i in range(1, maxi(order.size() - 1, 1)):
		mid_candidates.append(order[i])
	for _b in branch_budget:
		if mid_candidates.is_empty():
			break
		var from: Vector2i = mid_candidates[rng.randi_range(0, mid_candidates.size() - 1)]
		var side_dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
		for i in side_dirs.size():
			var j := rng.randi_range(i, side_dirs.size() - 1)
			var tmp2: Vector2i = side_dirs[i]
			side_dirs[i] = side_dirs[j]
			side_dirs[j] = tmp2
		for d in side_dirs:
			var nxt2: Vector2i = from + d
			if occupied.has(nxt2):
				continue
			_link_doors(doors, from, nxt2, d)
			occupied[nxt2] = true
			order.append(nxt2)
			kinds[nxt2] = "treasure" if rng.randf() > 0.35 else "cross"
			break

	var result: Array[Dictionary] = []
	for p2 in order:
		result.append({
			"grid": p2,
			"kind": kinds[p2],
			"doors": doors[p2],
		})
	return result


func _link_doors(doors: Dictionary, a: Vector2i, b: Vector2i, delta: Vector2i) -> void:
	if not doors.has(a):
		doors[a] = {"n": false, "s": false, "e": false, "w": false}
	if not doors.has(b):
		doors[b] = {"n": false, "s": false, "e": false, "w": false}
	if delta == Vector2i(0, -1):
		doors[a]["n"] = true
		doors[b]["s"] = true
	elif delta == Vector2i(0, 1):
		doors[a]["s"] = true
		doors[b]["n"] = true
	elif delta == Vector2i(1, 0):
		doors[a]["e"] = true
		doors[b]["w"] = true
	elif delta == Vector2i(-1, 0):
		doors[a]["w"] = true
		doors[b]["e"] = true


func _light_color() -> Color:
	match RunState.biome:
		RunState.BIOME_MINES:
			return Color(1.0, 0.55, 0.3)
		RunState.BIOME_GARDEN:
			return Color(0.55, 0.85, 0.55)
		_:
			return Color(1.0, 0.75, 0.45)


func _add_collision_box(parent: Node, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	return body


func _place_scene(parent: Node, packed: PackedScene, pos: Vector3, rot_y: float = 0.0, scale_f: float = 1.0) -> Node3D:
	if packed == null:
		return null
	var model := packed.instantiate() as Node3D
	model.position = pos
	model.rotation.y = rot_y
	if not is_equal_approx(scale_f, 1.0):
		model.scale = Vector3.ONE * scale_f
	parent.add_child(model)
	return model


func _place_door(parent: Node, pos: Vector3, rot_y: float = 0.0) -> Node3D:
	if _wall_door_scene == null:
		return null
	var model := _wall_door_scene.instantiate() as Node3D
	model.set_script(load("res://scripts/interactables/door_passage.gd"))
	model.position = pos
	model.rotation.y = rot_y
	parent.add_child(model)
	if model.has_method("setup"):
		model.setup()
	return model


func _enemy_pool() -> Array:
	match RunState.biome:
		RunState.BIOME_MINES:
			return ENEMIES_MINES
		RunState.BIOME_GARDEN:
			return ENEMIES_GARDEN
		_:
			return ENEMIES_CATACOMBS


func _build_room(kind: String, rng: RandomNumberGenerator, doors: Dictionary = {}) -> Node3D:
	var room := Node3D.new()
	room.set_meta("has_relic", false)
	var hz := ROOM_SIZE.z * 0.5
	var hx := ROOM_SIZE.x * 0.5
	var hy := ROOM_SIZE.y * 0.5
	var d_n := bool(doors.get("n", false))
	var d_s := bool(doors.get("s", false))
	var d_e := bool(doors.get("e", false))
	var d_w := bool(doors.get("w", false))

	_place_floor_and_ceiling(room)
	_add_collision_box(room, Vector3(ROOM_SIZE.x, 0.5, ROOM_SIZE.z), Vector3(0, -0.25, 0))
	_build_wall_ns(room, hz, hy, d_s, 0.0)
	_build_wall_ns(room, -hz, hy, d_n, PI)
	_build_wall_ew(room, hx, hy, d_e, -PI * 0.5)
	_build_wall_ew(room, -hx, hy, d_w, PI * 0.5)

	# Parede em ±hx, face interna ±(hx-0.5). torch_mounted: costas z≈0, chama +Z.
	# Porta EW fica em z=0: se houver porta, joga a tocha pro trecho sólido (±5).
	const TORCH_INSET := 0.04
	const TORCH_Y := 2.0
	var west_z := 5.0 if d_w else 0.0
	var east_z := -5.0 if d_e else 0.0
	_spawn_torch(room, Vector3(-hx + 0.5 + TORCH_INSET, TORCH_Y, west_z), PI * 0.5)
	_spawn_torch(room, Vector3(hx - 0.5 - TORCH_INSET, TORCH_Y, east_z), -PI * 0.5)

	match kind:
		"bridge":
			KayKit.add_model(room, KayKit.BOX_LARGE, Vector3(0, 0, 0), 0.0, 1.2)
			_add_collision_box(room, Vector3(3.0, 0.3, 10.0), Vector3(0, 0.15, 0))
			_spawn_spikes(room, Vector3(-4.5, 0, 3))
			_spawn_spikes(room, Vector3(4.5, 0, -3))
			_spawn_rope(room, Vector3(0, 0, 2))
		"hazard":
			_spawn_rope(room, Vector3(0, 0, 0))
			_spawn_spikes(room, Vector3(0, 0, 3))
			_spawn_spikes(room, Vector3(-4, 0, -2))
			_spawn_spikes(room, Vector3(4, 0, 2))
		"cross":
			_spawn_spikes(room, Vector3(0, 0, 3))
			if rng.randf() > 0.4:
				_spawn_random_relic(room, Vector3(0, 0, -2), rng)
		"treasure":
			KayKit.add_model(room, KayKit.CHEST_GOLD, Vector3(0, 0, 0))
			_spawn_random_relic(room, Vector3(0, 0, -2), rng, true)
			for _i in 3:
				_spawn_crate(room, Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-3, 3)))
		"boss":
			KayKit.add_model(room, KayKit.BANNER, Vector3(-2, 0, -6))
			KayKit.add_model(room, KayKit.BANNER, Vector3(2, 0, -6))
			_spawn_boss(room, Vector3(0, 0, -1))
			_spawn_random_relic(room, Vector3(3, 0, 2), rng, true)
		"end":
			_spawn_random_relic(room, Vector3(2.5, 0, -2), rng, true)
			_spawn_enemy(room, Vector3(rng.randf_range(-2, 2), 0, 0), rng)
		_:
			if rng.randf() > 0.72:
				_spawn_random_relic(room, Vector3(4, 0, -2), rng)

	if RunState.biome == RunState.BIOME_GARDEN:
		_spawn_vines(room, Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-3, 3)))
		if rng.randf() > 0.4:
			_spawn_vines(room, Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-3, 3)))
		_scatter_grass(room, rng)
	elif RunState.biome == RunState.BIOME_MINES and rng.randf() > 0.4:
		_spawn_rope(room, Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-2, 2)))

	if kind not in ["end", "boss", "treasure"]:
		var n := 1 + int(rng.randf() > 0.45) + int(RunState.floor_index > 4)
		for _i in n:
			_spawn_enemy(room, Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 1)), rng)
	elif kind == "treasure" and rng.randf() > 0.5:
		_spawn_enemy(room, Vector3(0, 0, 3), rng)

	if kind != "boss" and rng.randf() > 0.35:
		_spawn_crate(room, Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-4, 4)))
	if rng.randf() > 0.55:
		_spawn_crate(room, Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-4, 4)))

	return room


func _place_floor_and_ceiling(room: Node3D) -> void:
	var visuals := Node3D.new()
	visuals.name = "Tiles"
	room.add_child(visuals)
	for xi in ROOM_TILES:
		for zi in ROOM_TILES:
			var pos := Vector3((float(xi) - 1.5) * TILE, 0.0, (float(zi) - 1.5) * TILE)
			_place_scene(visuals, _floor_scene, pos)
			_place_scene(visuals, _ceiling_scene, pos + Vector3(0, ROOM_SIZE.y, 0))


func _build_wall_ns(room: Node3D, z: float, hy: float, has_door: bool, rot_y: float) -> void:
	var visuals := room.get_node_or_null("Tiles") as Node3D
	if visuals == null:
		visuals = room
	if has_door:
		_place_scene(visuals, _wall_scene, Vector3(-6.0, 0.0, z), rot_y)
		_place_scene(visuals, _wall_half_scene, Vector3(-4.0, 0.0, z), rot_y)
		_place_door(visuals, Vector3(0.0, 0.0, z), rot_y)
		_place_scene(visuals, _wall_half_scene, Vector3(4.0, 0.0, z), rot_y + PI)
		_place_scene(visuals, _wall_scene, Vector3(6.0, 0.0, z), rot_y)
		# Vão da folha ~±1. Batentes (−2..−1 e 1..2) precisam de colisão.
		_add_collision_box(room, Vector3(7.0, ROOM_SIZE.y, 0.5), Vector3(-4.5, hy, z))
		_add_collision_box(room, Vector3(7.0, ROOM_SIZE.y, 0.5), Vector3(4.5, hy, z))
	else:
		for x in [-6.0, -2.0, 2.0, 6.0]:
			_place_scene(visuals, _wall_scene, Vector3(x, 0.0, z), rot_y)
		_add_collision_box(room, Vector3(ROOM_SIZE.x, ROOM_SIZE.y, 0.5), Vector3(0, hy, z))


func _build_wall_ew(room: Node3D, x: float, hy: float, has_door: bool, rot_y: float) -> void:
	var visuals := room.get_node_or_null("Tiles") as Node3D
	if visuals == null:
		visuals = room
	if has_door:
		_place_scene(visuals, _wall_scene, Vector3(x, 0.0, -6.0), rot_y)
		_place_scene(visuals, _wall_half_scene, Vector3(x, 0.0, -4.0), rot_y)
		_place_door(visuals, Vector3(x, 0.0, 0.0), rot_y)
		_place_scene(visuals, _wall_half_scene, Vector3(x, 0.0, 4.0), rot_y + PI)
		_place_scene(visuals, _wall_scene, Vector3(x, 0.0, 6.0), rot_y)
		_add_collision_box(room, Vector3(0.5, ROOM_SIZE.y, 7.0), Vector3(x, hy, -4.5))
		_add_collision_box(room, Vector3(0.5, ROOM_SIZE.y, 7.0), Vector3(x, hy, 4.5))
	else:
		for z in [-6.0, -2.0, 2.0, 6.0]:
			_place_scene(visuals, _wall_scene, Vector3(x, 0.0, z), rot_y)
		_add_collision_box(room, Vector3(0.5, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(x, hy, 0))


func _spawn_torch(room: Node3D, local_pos: Vector3, rot_y: float = 0.0) -> void:
	var root := Node3D.new()
	root.position = local_pos
	root.rotation.y = rot_y
	room.add_child(root)
	var model := KayKit.add_model(root, KayKit.TORCH_MOUNTED)
	if model == null:
		model = KayKit.add_model(root, KayKit.TORCH_LIT)
	# Mesh da tocha não precisa projetar sombra (evita auto-sombra estranha).
	if model:
		_disable_shadows(model)
	var glow := OmniLight3D.new()
	# Luz um pouco pra dentro da sala: radial no cômodo, parede bloqueia o vizinho.
	glow.position = Vector3(0.0, 0.55, 1.05)
	glow.light_color = _light_color()
	glow.light_energy = 1.55
	glow.omni_range = 8.5
	glow.omni_attenuation = 1.0
	glow.shadow_enabled = true
	glow.shadow_blur = 2.0
	glow.shadow_bias = 0.04
	glow.shadow_normal_bias = 1.0
	root.add_child(glow)


func _spawn_rope(room: Node3D, local_pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = local_pos
	room.add_child(root)
	KayKit.add_model(root, KayKit.ROPE)
	KayKit.add_model(root, KayKit.BEARTRAP, Vector3(0.4, 0, 0), 0.0, 0.85)
	var area := Area3D.new()
	area.set_script(load("res://scripts/interactables/rope_trap.gd"))
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
	vines.set_script(load("res://scripts/interactables/cut_vines.gd"))
	room.add_child(vines)


func _scatter_grass(room: Node3D, rng: RandomNumberGenerator) -> void:
	for _i in rng.randi_range(4, 8):
		var g := KayKit.add_model(
			room,
			KayKit.GRASS,
			Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6)),
			rng.randf() * TAU,
			rng.randf_range(0.8, 1.3)
		)
		if g:
			_disable_shadows(g)


func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)


func _spawn_enemy(room: Node3D, local_pos: Vector3, rng: RandomNumberGenerator) -> void:
	var pool := _enemy_pool()
	var path: String = pool[rng.randi_range(0, pool.size() - 1)]
	var enemy_scene := load(path) as PackedScene
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Node3D
	enemy.position = local_pos
	room.add_child(enemy)


func _spawn_boss(room: Node3D, local_pos: Vector3) -> void:
	var path := "res://scenes/enemies/skeleton_mage.tscn"
	match RunState.biome:
		RunState.BIOME_MINES:
			path = "res://scenes/enemies/skeleton_minion_brute.tscn"
		RunState.BIOME_GARDEN:
			path = "res://scenes/enemies/rogue_hooded.tscn"
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
	# Laje + espinhos juntos. Scale uniforme pra não separar as meshes (espinhos y=2 → ~0.7).
	const TRAP_SCALE := 0.35
	KayKit.add_model(root, KayKit.FLOOR_SPIKES, Vector3.ZERO, 0.0, TRAP_SCALE)
	# Hitbox só na área dos espinhos (AABB 2.2×2.0×2.2), mesma origem da laje.
	var spike_size := Vector3(2.2, 2.0, 2.2) * TRAP_SCALE
	var area := Area3D.new()
	area.set_script(load("res://scripts/interactables/spike_trap.gd"))
	root.add_child(area)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = spike_size
	col.shape = shape
	col.position.y = spike_size.y * 0.5
	area.add_child(col)


func _spawn_random_relic(room: Node3D, local_pos: Vector3, rng: RandomNumberGenerator, force: bool = false) -> void:
	if bool(room.get_meta("has_relic", false)):
		return
	var luck_bonus := MetaProgress.relic_luck * 0.08
	if not force and rng.randf() > 0.5 + luck_bonus:
		return
	var available: Array[Dictionary] = []
	for relic in RELICS:
		var id := String(relic["id"])
		if _spawned_relic_ids.has(id):
			continue
		if RunState.has_relic(id):
			continue
		available.append(relic)
	if available.is_empty():
		return
	var pick: Dictionary = available[rng.randi_range(0, available.size() - 1)]
	_spawn_relic(room, local_pos, pick["id"], pick["name"], pick["desc"])


func _spawn_relic(room: Node3D, local_pos: Vector3, relic_id: String, relic_name: String, relic_desc: String) -> void:
	if bool(room.get_meta("has_relic", false)):
		return
	if _spawned_relic_ids.has(relic_id) or RunState.has_relic(relic_id):
		return
	room.set_meta("has_relic", true)
	_spawned_relic_ids.append(relic_id)
	var root := Node3D.new()
	root.position = local_pos
	room.add_child(root)
	KayKit.add_model(root, KayKit.CHEST_GOLD, Vector3.ZERO, 0.0, 0.85)
	KayKit.add_model(root, KayKit.COIN, Vector3(0, 0.95, 0), 0.0, 1.4)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 0.7, 0)
	light.light_color = Color(0.5, 0.85, 1.0)
	light.light_energy = 1.2
	light.omni_range = 4.0
	root.add_child(light)
	var label := Label3D.new()
	label.name = "Label"
	label.text = relic_name
	label.position = Vector3(0, 1.4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	GameFonts.style_label3d(label, 42)
	root.add_child(label)
	var area := Area3D.new()
	area.set_script(load("res://scripts/interactables/relic_pedestal.gd"))
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
	KayKit.add_model(area, KayKit.MIRROR, Vector3(0, 0, 0), 0.0, 1.2)
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
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	GameFonts.style_label3d(tag, 56)
	area.add_child(tag)


func _show_run_message(text: String) -> void:
	for node in get_tree().get_nodes_in_group("run_message"):
		if node is Label:
			node.text = text
			var label_id := node.get_instance_id()
			get_tree().create_timer(2.0).timeout.connect(func() -> void:
				var live := instance_from_id(label_id) as Label
				if live:
					live.text = ""
			)
			return
