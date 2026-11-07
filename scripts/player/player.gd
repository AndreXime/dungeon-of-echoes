extends CharacterBody3D

enum Weapon { SWORD, DAGGER, CROSSBOW }

const SPEED := 5.0
const JUMP_VELOCITY := 5.2
const MOUSE_SENSITIVITY := 0.0025
const SWING_TIME := 0.2
const THRUST_TIME := 0.16
const HITBOX_TIME := 0.18
const KNOCKBACK_STRENGTH := 6.0
const DAGGER_DAMAGE := 9
const BOLT_DAMAGE := 14
const CROSSBOW_RELOAD := 1.15
const SWORD_GLB := KayKit.SWORD
const SHIELD_GLB := KayKit.SHIELD
const DAGGER_GLB := KayKit.DAGGER
const CROSSBOW_GLB := KayKit.CROSSBOW
const BOLT_GLB := KayKit.BOLT
const TORCH_GLB := KayKit.TORCH_LIT
## Layer só pra sombra do corpo (a tocha na mão não ilumina/sombreia essa layer).
const BODY_SHADOW_LAYER := 2

@onready var camera: Camera3D = $Camera3D
@onready var body_root: Node3D = $BodyRoot
@onready var weapons_root: Node3D = $Camera3D/WeaponsRoot
@onready var sword_pivot: Node3D = $Camera3D/WeaponsRoot/SwordPivot
@onready var shield_pivot: Node3D = $Camera3D/WeaponsRoot/ShieldPivot
@onready var dagger_pivot: Node3D = $Camera3D/WeaponsRoot/DaggerPivot
@onready var crossbow_pivot: Node3D = $Camera3D/WeaponsRoot/CrossbowPivot
@onready var sword_hitbox: Area3D = $Camera3D/WeaponsRoot/SwordPivot/SwordHitbox

var _sword_rest: Transform3D
var _shield_rest: Transform3D
var _swinging := false
var _thrusting := false
var _blocking := false
var _hit_targets: Dictionary = {}
var _space_was_down := false
var _weapon: Weapon = Weapon.SWORD
var _dagger_out := false
var _active_dagger: Node3D
var _crossbow_ready := true
var _reload_left := 0.0
var _torch_root: Node3D
## Offhand: true = tocha, false = escudo. Nunca os dois ao mesmo tempo.
var _torch_equipped := false
var _melee_slash_shape: BoxShape3D
var _body_anim: AnimationPlayer


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# FPS: corpo só na sombra (não aparece no POV).
	_attach_body_for_shadow()
	_attach_sword()
	_attach_weapon(SHIELD_GLB, shield_pivot, Vector3(0, -0.02, 0.04), Vector3(8, 20, -8), 0.72)
	_attach_weapon(DAGGER_GLB, dagger_pivot, Vector3(0, 0, 0), Vector3(-90, 0, 0), 1.15)
	# KayKit crossbow aponta no +Z. Câmera FPS olha no -Z, então 180° em Y.
	_attach_weapon(CROSSBOW_GLB, crossbow_pivot, Vector3(0.02, -0.02, 0.05), Vector3(-8, 180, 0), 1.05)
	_attach_torch()
	_sword_rest = sword_pivot.transform
	_shield_rest = shield_pivot.transform
	sword_hitbox.monitoring = false
	sword_hitbox.body_entered.connect(_on_sword_hit)
	sword_hitbox.area_entered.connect(_on_sword_hit_area)
	_melee_slash_shape = BoxShape3D.new()
	_melee_slash_shape.size = Vector3(1.15, 1.35, 1.75)
	_apply_start_weapon()
	_apply_weapon_visibility()
	_apply_offhand_visibility()


func _apply_start_weapon() -> void:
	match MetaProgress.selected_start_weapon:
		"dagger":
			if MetaProgress.unlocked_start_weapons.has("dagger"):
				_weapon = Weapon.DAGGER
		"crossbow":
			if MetaProgress.unlocked_start_weapons.has("crossbow"):
				_weapon = Weapon.CROSSBOW
		_:
			_weapon = Weapon.SWORD


func _attach_torch() -> void:
	_torch_root = Node3D.new()
	_torch_root.name = "TorchRoot"
	# Mesma mão do escudo. Mesh sobe no +Y: escala menor + offset pra não furar o topo do POV.
	weapons_root.add_child(_torch_root)
	# −Z = pra frente da câmera (menos colado no POV).
	_torch_root.position = shield_pivot.position + Vector3(0.02, -0.08, -0.14)
	_torch_root.rotation_degrees = Vector3(18, 12, -10)
	if ResourceLoader.exists(TORCH_GLB):
		var packed := load(TORCH_GLB) as PackedScene
		if packed:
			var torch_model := packed.instantiate() as Node3D
			_torch_root.add_child(torch_model)
			torch_model.position = Vector3(0.0, -0.22, 0.0)
			torch_model.scale = Vector3.ONE * 0.75
			_make_torch_look_lit(torch_model)
	var glow := OmniLight3D.new()
	glow.name = "TorchLight"
	glow.position = Vector3(0.0, 0.42, 0.0)
	glow.light_color = Color(1.0, 0.72, 0.35)
	glow.light_energy = 1.7
	glow.omni_range = 9.0
	glow.shadow_enabled = true
	# Não usa o corpo do jogador: a sombra dele apagava a própria tocha.
	glow.light_cull_mask = 0xFFFFF & ~BODY_SHADOW_LAYER
	_torch_root.add_child(glow)


func _make_torch_look_lit(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if mi.mesh:
			for surface_i in mi.mesh.get_surface_count():
				var base := mi.get_active_material(surface_i)
				var lit: StandardMaterial3D
				if base is StandardMaterial3D:
					lit = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				else:
					lit = StandardMaterial3D.new()
					if base:
						lit.next_pass = base
				lit.emission_enabled = true
				lit.emission = Color(1.0, 0.5, 0.15)
				lit.emission_energy_multiplier = 2.2
				# Usa albedo da textura como mapa de emissão (chama brilha, cabo menos).
				if lit.albedo_texture != null:
					lit.emission_texture = lit.albedo_texture
				mi.set_surface_override_material(surface_i, lit)
	for child in node.get_children():
		_make_torch_look_lit(child)


func _attach_body_for_shadow() -> void:
	if body_root == null or not ResourceLoader.exists(KayKit.KNIGHT):
		return
	var packed := load(KayKit.KNIGHT) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	body_root.add_child(model)
	_body_anim = KayKitAnim.setup(model, false)
	KayKitAnim.play_idle(_body_anim, false)
	# Invisible na câmera, mas projeta sombra no chão/paredes.
	_set_geometry_shadows_only(body_root)


func _set_geometry_shadows_only(node: Node) -> void:
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		gi.layers = BODY_SHADOW_LAYER
	for child in node.get_children():
		_set_geometry_shadows_only(child)


func _attach_sword() -> void:
	if not ResourceLoader.exists(SWORD_GLB):
		return
	var packed := load(SWORD_GLB) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	sword_pivot.add_child(model)
	model.position = Vector3(0.04, -0.02, 0.0)
	model.scale = Vector3.ONE * 0.8
	# KayKit: +Y = ponta, +X = largura, +Z = espessura.
	# Idle: ponta pra cima. Largura no eixo da câmera pra ver o fio de perfil.
	var tip_up := Vector3(0, 1, 0)
	var width_along_view := Vector3(0, 0, -1)
	var thickness := width_along_view.cross(tip_up).normalized()
	model.basis = Basis(width_along_view, tip_up, thickness)
	# Inclina um pouco a ponta pra frente/fora, sem deitar.
	model.rotate_object_local(Vector3.RIGHT, deg_to_rad(-18.0))
	model.rotate_object_local(Vector3.FORWARD, deg_to_rad(12.0))


func _attach_weapon(path: String, pivot: Node3D, pos: Vector3, rot_deg: Vector3, scale_f: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var model := packed.instantiate() as Node3D
	pivot.add_child(model)
	model.position = pos
	model.rotation_degrees = rot_deg
	model.scale = Vector3.ONE * scale_f


func is_blocking() -> bool:
	return _blocking and _weapon == Weapon.SWORD and not _torch_equipped


func has_torch() -> bool:
	return _torch_equipped


func on_dagger_returned() -> void:
	_dagger_out = false
	_active_dagger = null
	dagger_pivot.visible = _weapon == Weapon.DAGGER


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if event.is_action_pressed("weapon_1"):
		_set_weapon(Weapon.SWORD)
	elif event.is_action_pressed("weapon_2"):
		_set_weapon(Weapon.DAGGER)
	elif event.is_action_pressed("weapon_3"):
		_set_weapon(Weapon.CROSSBOW)

	if event.is_action_pressed("use_potion"):
		if RunState.try_use_potion():
			Sfx.play(self, "block", global_position)

	if event.is_action_pressed("toggle_torch"):
		_toggle_offhand()

	if event.is_action_pressed("attack"):
		_primary_action()
	if event.is_action_pressed("block") and _weapon == Weapon.DAGGER and _dagger_out:
		_recall_dagger()


func _toggle_offhand() -> void:
	_torch_equipped = not _torch_equipped
	_blocking = false
	_apply_offhand_visibility()
	_update_shield_pose()


func _physics_process(delta: float) -> void:
	_reload_left = maxf(_reload_left - delta, 0.0)
	if _reload_left <= 0.0:
		_crossbow_ready = true

	_blocking = (
		Input.is_action_pressed("block")
		and _weapon == Weapon.SWORD
		and not _torch_equipped
		and not _swinging
		and not _thrusting
	)
	_update_shield_pose()

	if not is_on_floor():
		velocity += get_gravity() * delta

	if (Input.is_action_just_pressed("ui_accept") or _just_pressed_space()) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()
	_push_enemies()
	var planar_speed := Vector3(velocity.x, 0.0, velocity.z).length()
	KayKitAnim.update_locomotion(_body_anim, planar_speed > 0.35, false)
	# Area3D body_entered falha se o inimigo já estava sobreposto ao ativar a hitbox
	if sword_hitbox.monitoring:
		_poll_sword_overlaps()

	if RunState.in_run and RunState.is_dead():
		RunState.finish_run_and_return_to_hub()


func _set_weapon(w: Weapon) -> void:
	if _swinging or _thrusting or _dagger_out:
		return
	if w == Weapon.DAGGER and not MetaProgress.unlocked_start_weapons.has("dagger") and MetaProgress.selected_start_weapon != "dagger":
		# Adaga sempre disponível na run após começar, mas se não desbloqueou no hub ainda permite 2
		pass
	_weapon = w
	_blocking = false
	_apply_weapon_visibility()
	_apply_offhand_visibility()


func _apply_weapon_visibility() -> void:
	sword_pivot.visible = _weapon == Weapon.SWORD
	dagger_pivot.visible = _weapon == Weapon.DAGGER and not _dagger_out
	crossbow_pivot.visible = _weapon == Weapon.CROSSBOW
	_apply_offhand_visibility()


func _apply_offhand_visibility() -> void:
	var shield_ready := _weapon == Weapon.SWORD and not _torch_equipped
	shield_pivot.visible = shield_ready
	if is_instance_valid(_torch_root):
		_torch_root.visible = _torch_equipped
		var light := _torch_root.get_node_or_null("TorchLight") as OmniLight3D
		if light:
			light.visible = _torch_equipped
			light.light_energy = 1.35 if _torch_equipped else 0.0


func weapon_label() -> String:
	var offhand := ""
	if _torch_equipped:
		offhand = " + Tocha"
	elif _weapon == Weapon.SWORD:
		offhand = " + Escudo"
	match _weapon:
		Weapon.SWORD:
			return "Espada%s" % offhand
		Weapon.DAGGER:
			return "Adaga" + (" (fora)" if _dagger_out else "") + offhand
		Weapon.CROSSBOW:
			return "Besteira" + (" (recarregando)" if not _crossbow_ready else "") + offhand
	return "?"


func _primary_action() -> void:
	match _weapon:
		Weapon.SWORD:
			if not _swinging and not _thrusting and not _blocking:
				var forward := -transform.basis.z
				var moving := Vector3(velocity.x, 0.0, velocity.z)
				if moving.length() > 2.5 and moving.normalized().dot(forward) > 0.55:
					_thrust()
				else:
					_swing()
		Weapon.DAGGER:
			if not _dagger_out:
				_throw_dagger()
			else:
				_recall_dagger()
		Weapon.CROSSBOW:
			_shoot_crossbow()


func _push_enemies() -> void:
	if not is_blocking():
		return
	var forward := -global_transform.basis.z
	var moving_forward := (-transform.basis.z).dot(Vector3(velocity.x, 0.0, velocity.z).normalized()) > 0.3 if velocity.length() > 0.4 else false
	if not moving_forward:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider is Node and collider.is_in_group("enemy") and collider.has_method("apply_push"):
			collider.apply_push(forward * 8.0)


func _just_pressed_space() -> bool:
	var down := Input.is_physical_key_pressed(KEY_SPACE)
	var pressed := down and not _space_was_down
	_space_was_down = down
	return pressed


func _update_shield_pose() -> void:
	if _weapon != Weapon.SWORD or _torch_equipped:
		return
	if _blocking:
		shield_pivot.position = _shield_rest.origin + Vector3(0.08, 0.04, -0.18)
		shield_pivot.rotation_degrees = Vector3(-25, 30, 0)
	elif not _swinging and not _thrusting:
		shield_pivot.transform = _shield_rest


func _arm_sword_hitbox() -> void:
	sword_hitbox.monitoring = true


func _poll_sword_overlaps() -> void:
	if not is_instance_valid(sword_hitbox) or not sword_hitbox.monitoring:
		return
	for body in sword_hitbox.get_overlapping_bodies():
		_on_sword_hit(body)
	for area in sword_hitbox.get_overlapping_areas():
		_on_sword_hit_area(area)
	# Area filha da espada erra props baixos: volume frontal na câmera.
	_query_melee_volume()


func _query_melee_volume() -> void:
	var space := get_world_3d().direct_space_state
	if space == null or _melee_slash_shape == null:
		return
	var forward := -camera.global_transform.basis.z
	var up := camera.global_transform.basis.y
	var right := camera.global_transform.basis.x
	var origin := camera.global_position + forward * 1.05 + up * -0.4 + right * 0.12
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _melee_slash_shape
	query.transform = Transform3D(camera.global_transform.basis, origin)
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	for hit in space.intersect_shape(query, 32):
		var collider: Variant = hit.get("collider")
		if collider is Node:
			_try_damage(collider as Node)


func _swing() -> void:
	_swinging = true
	_hit_targets.clear()
	_arm_sword_hitbox()
	Sfx.play(self, "swing", global_position)

	var swung := _sword_rest
	# Desce o pivot pra lâmina (eixo +Y) cruzar props no chão.
	swung.origin = _sword_rest.origin + Vector3(-0.08, -0.42, -0.52)
	# Idle ponta pra cima (+Y) → corte diagonal à frente (−Z).
	swung.basis = (
		_sword_rest.basis
		.rotated(Vector3.RIGHT, deg_to_rad(-100.0))
		.rotated(Vector3.UP, deg_to_rad(-40.0))
	)

	var tween := create_tween()
	tween.tween_property(sword_pivot, "transform", swung, SWING_TIME * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_pivot, "transform", _sword_rest, SWING_TIME * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_end_swing)
	var hitbox_id := sword_hitbox.get_instance_id()
	get_tree().create_timer(HITBOX_TIME).timeout.connect(func() -> void:
		var hb := instance_from_id(hitbox_id) as Area3D
		if hb:
			hb.monitoring = false
	)


func _thrust() -> void:
	_thrusting = true
	_blocking = false
	_hit_targets.clear()
	_arm_sword_hitbox()
	Sfx.play(self, "swing", global_position)

	var thrusted := _sword_rest
	thrusted.origin = _sword_rest.origin + Vector3(0.0, -0.28, -0.7)
	# Estoca: ponta (+Y) vira pra frente (−Z).
	thrusted.basis = _sword_rest.basis.rotated(Vector3.RIGHT, deg_to_rad(-85.0))

	var tween := create_tween()
	tween.tween_property(sword_pivot, "transform", thrusted, THRUST_TIME * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_pivot, "transform", _sword_rest, THRUST_TIME * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_thrusting = false
		sword_hitbox.monitoring = false
		sword_pivot.transform = _sword_rest
	)
	var thrust_hitbox_id := sword_hitbox.get_instance_id()
	get_tree().create_timer(HITBOX_TIME).timeout.connect(func() -> void:
		var hb := instance_from_id(thrust_hitbox_id) as Area3D
		if hb:
			hb.monitoring = false
	)


func _end_swing() -> void:
	_swinging = false
	sword_hitbox.monitoring = false
	sword_pivot.transform = _sword_rest


func _throw_dagger() -> void:
	_dagger_out = true
	dagger_pivot.visible = false
	Sfx.play(self, "shoot", global_position)
	var dagger := Area3D.new()
	dagger.set_script(load("res://scripts/player/returning_dagger.gd"))
	_attach_weapon(DAGGER_GLB, dagger, Vector3.ZERO, Vector3(-90, 0, 0), 1.0)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	shape.shape = sphere
	dagger.add_child(shape)
	get_tree().current_scene.add_child(dagger)
	dagger.global_position = camera.global_position + (-camera.global_transform.basis.z) * 0.6
	dagger.setup(self, -camera.global_transform.basis.z, DAGGER_DAMAGE)
	_active_dagger = dagger
	var dagger_id := dagger.get_instance_id()
	get_tree().create_timer(0.85).timeout.connect(func() -> void:
		var live := instance_from_id(dagger_id)
		if live != null and int(live.get("phase")) == 0 and live.has_method("start_return"):
			live.start_return()
	)


func _recall_dagger() -> void:
	if is_instance_valid(_active_dagger) and _active_dagger.has_method("start_return"):
		_active_dagger.start_return()


func _shoot_crossbow() -> void:
	if not _crossbow_ready:
		return
	_crossbow_ready = false
	_reload_left = CROSSBOW_RELOAD
	Sfx.play(self, "shoot", global_position)

	var bolt := RigidBody3D.new()
	bolt.set_script(load("res://scripts/player/projectile_bolt.gd"))
	bolt.damage = BOLT_DAMAGE
	if ResourceLoader.exists(BOLT_GLB):
		var packed := load(BOLT_GLB) as PackedScene
		if packed:
			bolt.add_child(packed.instantiate())
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.08, 0.08, 0.3)
	col.shape = shape
	bolt.add_child(col)
	get_tree().current_scene.add_child(bolt)
	var origin := camera.global_position + (-camera.global_transform.basis.z) * 0.8
	bolt.global_position = origin
	bolt.look_at(origin + (-camera.global_transform.basis.z), Vector3.UP)
	bolt.linear_velocity = (-camera.global_transform.basis.z) * 28.0 + Vector3(0, 0.8, 0)


func _on_sword_hit(body: Node3D) -> void:
	_try_damage(body)


func _on_sword_hit_area(area: Area3D) -> void:
	_try_damage(area)


func _try_damage(node: Node) -> void:
	var target: Node = node
	if not target.is_in_group("enemy") and not target.is_in_group("breakable"):
		if target.get_parent() and (target.get_parent().is_in_group("enemy") or target.get_parent().is_in_group("breakable")):
			target = target.get_parent()
		else:
			if RunState.has_relic(RunState.RELIC_VOLCANIC) and target is StaticBody3D:
				_volcanic_burst(sword_hitbox.global_position)
			return
	var id := target.get_instance_id()
	if _hit_targets.has(id):
		return
	_hit_targets[id] = true

	var forward := -global_transform.basis.z
	var moving := Vector3(velocity.x, 0.0, velocity.z)
	var knock := Vector3.ZERO
	if moving.length() > 0.5 and moving.normalized().dot(forward) > 0.25:
		knock = forward * KNOCKBACK_STRENGTH
	if _thrusting:
		knock = forward * (KNOCKBACK_STRENGTH * 1.35)

	if target.has_method("take_hit"):
		target.take_hit(RunState.melee_damage_against(target), knock)
		_weapon_recoil()
	if RunState.has_relic(RunState.RELIC_VOLCANIC):
		_volcanic_burst(target.global_position if target is Node3D else sword_hitbox.global_position)


func _weapon_recoil() -> void:
	var pivot: Node3D = sword_pivot
	match _weapon:
		Weapon.DAGGER:
			pivot = dagger_pivot
		Weapon.CROSSBOW:
			pivot = crossbow_pivot
		_:
			pivot = sword_pivot
	var rest := pivot.position
	var kick := rest + Vector3(0.0, 0.01, 0.05)
	var tween := create_tween()
	tween.tween_property(pivot, "position", kick, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(pivot, "position", rest, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _volcanic_burst(pos: Vector3) -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		if node is Node3D and node.has_method("take_hit"):
			if node.global_position.distance_to(pos) < 2.2:
				node.take_hit(6, Vector3.ZERO)
