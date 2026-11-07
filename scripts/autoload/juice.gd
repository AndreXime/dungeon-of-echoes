extends Node

const HIT_STOP := 0.045
const HIT_SCALE := 0.15
const KILL_STOP := 0.09
const KILL_SCALE := 0.08
const HIT_SHAKE := 0.04
const KILL_SHAKE := 0.09
const HURT_SHAKE := 0.07
const BLOCK_SHAKE := 0.025

var _hitstop_active := false
var _shake_token := 0


func _ready() -> void:
	if not RunState.damaged.is_connected(_on_run_damaged):
		RunState.damaged.connect(_on_run_damaged)


func _on_run_damaged(_amount: int) -> void:
	if RunState.in_run:
		on_player_hurt()


func hitstop(duration: float, scale: float = HIT_SCALE) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = scale
	var tree := get_tree()
	if tree == null:
		_end_hitstop()
		return
	tree.create_timer(duration, true, false, true).timeout.connect(_end_hitstop)


func _end_hitstop() -> void:
	Engine.time_scale = 1.0
	_hitstop_active = false


func _find_player_camera() -> Camera3D:
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("player"):
		if n is Node and n.has_node("Camera3D"):
			return n.get_node("Camera3D") as Camera3D
	return null


func shake(amplitude: float, duration: float, camera: Camera3D = null) -> void:
	var cam := camera if camera else _find_player_camera()
	if cam == null:
		return
	_shake_token += 1
	var token := _shake_token
	var origin := cam.position
	var elapsed := 0.0
	while elapsed < duration and token == _shake_token and is_instance_valid(cam):
		var t := 1.0 - (elapsed / duration)
		cam.position = origin + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			0.0
		) * amplitude * t
		await get_tree().process_frame
		elapsed += get_process_delta_time() / maxf(Engine.time_scale, 0.001)
	if is_instance_valid(cam) and token == _shake_token:
		cam.position = origin


func flash(node: Node3D, color: Color = Color(2.0, 2.0, 2.0), duration: float = 0.08) -> void:
	if node == null or not is_instance_valid(node):
		return
	var restores: Array[Dictionary] = []
	_collect_flash_targets(node, restores, color)
	if restores.is_empty():
		return
	var tree := get_tree()
	if tree == null:
		_restore_flash(restores)
		return
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void:
		_restore_flash(restores)
	)


func _collect_flash_targets(node: Node, restores: Array[Dictionary], color: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var original: Material = mi.get_surface_override_material(s)
					var sm := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					sm.emission_enabled = true
					sm.emission = color
					sm.emission_energy_multiplier = 2.2
					mi.set_surface_override_material(s, sm)
					restores.append({"mi": mi, "surface": s, "mat": original})
	for child in node.get_children():
		_collect_flash_targets(child, restores, color)


func _restore_flash(restores: Array[Dictionary]) -> void:
	for entry in restores:
		var mi: MeshInstance3D = entry["mi"]
		if not is_instance_valid(mi):
			continue
		mi.set_surface_override_material(int(entry["surface"]), entry["mat"])


func burst(pos: Vector3, color: Color, count: int = 8) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var parts := CPUParticles3D.new()
	parts.emitting = false
	parts.one_shot = true
	parts.explosiveness = 1.0
	parts.amount = maxi(count, 1)
	parts.lifetime = 0.35
	parts.direction = Vector3(0, 1, 0)
	parts.spread = 180.0
	parts.initial_velocity_min = 2.5
	parts.initial_velocity_max = 5.5
	parts.gravity = Vector3(0, -8, 0)
	parts.scale_amount_min = 0.04
	parts.scale_amount_max = 0.09
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	parts.mesh = SphereMesh.new()
	(parts.mesh as SphereMesh).radius = 0.05
	(parts.mesh as SphereMesh).height = 0.1
	parts.material_override = mat
	tree.current_scene.add_child(parts)
	parts.global_position = pos + Vector3(0, 0.6, 0)
	parts.emitting = true
	tree.create_timer(0.7, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(parts):
			parts.queue_free()
	)


func on_hit(target: Node3D, is_kill: bool = false) -> void:
	if target == null or not is_instance_valid(target):
		return
	var pos := target.global_position
	if is_kill:
		hitstop(KILL_STOP, KILL_SCALE)
		shake(KILL_SHAKE, 0.18)
		flash(target, Color(2.2, 1.4, 0.6), 0.12)
		burst(pos, Color(1.0, 0.65, 0.25), 14)
		Sfx.play(self, "kill", pos)
	else:
		hitstop(HIT_STOP, HIT_SCALE)
		shake(HIT_SHAKE, 0.1)
		flash(target, Color(2.0, 2.0, 2.0), 0.07)
		burst(pos, Color(0.95, 0.85, 0.7), 6)
		Sfx.play(self, "hit", pos)


func on_player_hurt() -> void:
	shake(HURT_SHAKE, 0.16)
	Sfx.play(self, "hurt", Vector3.ZERO)


func on_block() -> void:
	shake(BLOCK_SHAKE, 0.08)
	var cam := _find_player_camera()
	var pos := cam.global_position if cam else Vector3.ZERO
	Sfx.play(self, "block", pos)


func on_break(pos: Vector3) -> void:
	hitstop(0.03, 0.2)
	shake(0.03, 0.1)
	burst(pos, Color(0.7, 0.5, 0.3), 10)
	Sfx.play(self, "break", pos)
