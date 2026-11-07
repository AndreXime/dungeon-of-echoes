extends CharacterBody3D
class_name EnemyBase

@export var move_speed: float = 2.2
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.3
@export var attack_damage: int = 10
@export var max_hp: int = 30
@export var gold_reward: int = 10
@export var essence_reward: int = 1
@export var model_path: String = ""
@export var model_scale: float = 1.0
@export var flying: bool = false
@export var can_split: bool = false
@export var is_boss: bool = false
@export var ranged: bool = false
@export var projectile_damage: int = 8
@export var detect_range: float = 9.0
@export var lose_range: float = 14.0

var hp: int
var _attack_cd := 0.0
var _push_vel := Vector3.ZERO
var _split_done := false
var _aggro := false


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	if is_boss:
		detect_range = maxf(detect_range, 12.0)
		lose_range = maxf(lose_range, 18.0)
	_attach_model()
	if not has_node("CollisionShape3D"):
		var col := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.35
		shape.height = 1.4
		col.shape = shape
		col.position.y = 0.7
		add_child(col)


func _attach_model() -> void:
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return
	if has_node("ModelRoot"):
		return
	var root := Node3D.new()
	root.name = "ModelRoot"
	add_child(root)
	var packed := load(model_path) as PackedScene
	if packed:
		var model := packed.instantiate() as Node3D
		if not is_equal_approx(model_scale, 1.0):
			model.scale = Vector3.ONE * model_scale
		root.add_child(model)


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if not flying and not is_on_floor():
		velocity += get_gravity() * delta

	var player := _find_player()
	if player == null:
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	if not flying:
		to_player.y = 0.0
	var dist := to_player.length()

	_update_aggro(player, dist)

	if _push_vel.length() > 0.1:
		velocity.x = _push_vel.x
		velocity.z = _push_vel.z
		_push_vel = _push_vel.move_toward(Vector3.ZERO, 18.0 * delta)
	elif not _aggro:
		velocity.x = 0.0
		velocity.z = 0.0
		if flying:
			velocity.y = 0.0
	elif dist > attack_range:
		var dir := to_player.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if flying:
			velocity.y = dir.y * move_speed * 0.5
		if Vector3(dir.x, 0.0, dir.z).length() > 0.01:
			look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if flying:
			velocity.y = 0.0
		if _attack_cd <= 0.0:
			_do_attack(player)
			_attack_cd = attack_cooldown

	move_and_slide()


func _update_aggro(player: Node3D, dist: float) -> void:
	if dist > lose_range:
		_aggro = false
		return
	if _aggro:
		return
	if dist <= detect_range and _has_line_of_sight(player):
		_aggro = true


func _has_line_of_sight(player: Node3D) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return false
	var from := global_position + Vector3(0, 1.0, 0)
	var to := player.global_position + Vector3(0, 1.2, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()


func _do_attack(player: Node3D) -> void:
	if ranged:
		_shoot(player)
		return
	if player.has_method("is_blocking") and player.is_blocking():
		var to_me := (global_position - player.global_position).normalized()
		var facing := -player.global_transform.basis.z
		if facing.dot(to_me) > 0.35:
			Juice.on_block()
			return
	RunState.apply_damage(attack_damage)


func _shoot(player: Node3D) -> void:
	var proj := RigidBody3D.new()
	proj.set_script(load("res://scripts/enemy_projectile.gd"))
	proj.damage = projectile_damage
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 1.0, 0.3)
	mesh.material_override = mat
	proj.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.12
	col.shape = shape
	proj.add_child(col)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0, 1.0, 0)
	var dir := (player.global_position + Vector3(0, 1.0, 0) - proj.global_position).normalized()
	proj.linear_velocity = dir * 12.0
	Sfx.play(self, "shoot", global_position)


func _find_player() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node3D


func take_hit(damage: int, knockback: Vector3) -> void:
	hp -= damage
	_push_vel = knockback
	_aggro = true
	if hp <= 0:
		Juice.on_hit(self, true)
		_die()
	else:
		Juice.on_hit(self, false)


func apply_push(force: Vector3) -> void:
	_push_vel = force
	_aggro = true


func _die() -> void:
	RunState.add_gold(gold_reward)
	RunState.add_essence(essence_reward)
	if is_boss:
		RunState.boss_cleared = true
	if can_split and not _split_done:
		_split_done = true
		_spawn_split()
	queue_free()


func _spawn_split() -> void:
	for offset in [Vector3(-0.6, 0, 0), Vector3(0.6, 0, 0)]:
		var child := load("res://scenes/enemies/slime.tscn") as PackedScene
		if child == null:
			continue
		var s := child.instantiate() as Node3D
		s.set("can_split", false)
		s.set("max_hp", maxi(max_hp / 2, 8))
		s.scale = Vector3.ONE * 0.65
		get_parent().add_child(s)
		s.global_position = global_position + offset
		if "hp" in s:
			s.set("hp", s.get("max_hp"))
		s.set("_aggro", true)
