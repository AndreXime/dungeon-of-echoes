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
const TORCH_GLB := KayKit.TORCH_HAND

@onready var camera: Camera3D = $Camera3D
@onready var body_root: Node3D = $BodyRoot
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


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# FPS: sem corpo local (o Knight inteiro ficava dentro da câmera).
	if body_root:
		body_root.visible = false
	_attach_weapon(SWORD_GLB, sword_pivot, Vector3(0.02, -0.02, -0.05), Vector3(10, 0, -10), 1.1)
	_attach_weapon(SHIELD_GLB, shield_pivot, Vector3(0, 0, 0), Vector3(0, 0, 0), 1.0)
	_attach_weapon(DAGGER_GLB, dagger_pivot, Vector3(0, 0, 0), Vector3(-90, 0, 0), 1.15)
	_attach_weapon(CROSSBOW_GLB, crossbow_pivot, Vector3(0, 0, 0), Vector3(-80, 0, 0), 1.0)
	_attach_torch()
	_sword_rest = sword_pivot.transform
	_shield_rest = shield_pivot.transform
	sword_hitbox.monitoring = false
	sword_hitbox.body_entered.connect(_on_sword_hit)
	sword_hitbox.area_entered.connect(_on_sword_hit_area)
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
	camera.add_child(_torch_root)
	_torch_root.position = Vector3(-0.32, -0.38, -0.45)
	_torch_root.rotation_degrees = Vector3(25, 15, -8)
	if ResourceLoader.exists(TORCH_GLB):
		var packed := load(TORCH_GLB) as PackedScene
		if packed:
			var torch_model := packed.instantiate()
			_torch_root.add_child(torch_model)
	var glow := OmniLight3D.new()
	glow.name = "TorchLight"
	glow.position = Vector3(0, 0.25, 0)
	glow.light_color = Color(1.0, 0.72, 0.35)
	glow.light_energy = 1.35
	glow.omni_range = 9.0
	glow.shadow_enabled = true
	_torch_root.add_child(glow)


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


func _swing() -> void:
	_swinging = true
	_hit_targets.clear()
	_arm_sword_hitbox()
	Sfx.play(self, "swing", global_position)

	var swung := _sword_rest
	swung.origin = _sword_rest.origin + Vector3(-0.08, -0.04, -0.55)
	swung.basis = _sword_rest.basis.rotated(Vector3.RIGHT, deg_to_rad(-75.0)).rotated(Vector3.UP, deg_to_rad(-45.0))

	var tween := create_tween()
	tween.tween_property(sword_pivot, "transform", swung, SWING_TIME * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_pivot, "transform", _sword_rest, SWING_TIME * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_end_swing)
	get_tree().create_timer(HITBOX_TIME).timeout.connect(func() -> void:
		if is_instance_valid(sword_hitbox):
			sword_hitbox.monitoring = false
	)


func _thrust() -> void:
	_thrusting = true
	_blocking = false
	_hit_targets.clear()
	_arm_sword_hitbox()
	Sfx.play(self, "swing", global_position)

	var thrusted := _sword_rest
	thrusted.origin = _sword_rest.origin + Vector3(0.0, -0.02, -0.85)
	thrusted.basis = _sword_rest.basis.rotated(Vector3.RIGHT, deg_to_rad(-25.0))

	var tween := create_tween()
	tween.tween_property(sword_pivot, "transform", thrusted, THRUST_TIME * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword_pivot, "transform", _sword_rest, THRUST_TIME * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_thrusting = false
		sword_hitbox.monitoring = false
		sword_pivot.transform = _sword_rest
	)
	get_tree().create_timer(HITBOX_TIME).timeout.connect(func() -> void:
		if is_instance_valid(sword_hitbox):
			sword_hitbox.monitoring = false
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
	get_tree().create_timer(0.85).timeout.connect(func() -> void:
		if is_instance_valid(dagger) and dagger.phase == dagger.Phase.FLY:
			dagger.start_return()
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
