extends CharacterBody3D

const SPEED := 2.2
const ATTACK_RANGE := 1.6
const ATTACK_COOLDOWN := 1.4
const ATTACK_DAMAGE := 12
const MAX_HP := 40
const GOLD_REWARD := 15
const FRONT_DAMAGE_MULT := 0.45
const SKELETON_GLB := KayKit.SKELETON_WARRIOR

var hp: int = MAX_HP
var _attack_cd := 0.0
var _push_vel := Vector3.ZERO

@onready var _model_root: Node3D = $ModelRoot


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	_attach_model()


func _attach_model() -> void:
	if not ResourceLoader.exists(SKELETON_GLB):
		return
	var packed := load(SKELETON_GLB) as PackedScene
	if packed == null:
		return
	_model_root.add_child(packed.instantiate())


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	if not is_on_floor():
		velocity += get_gravity() * delta

	var player := _find_player()
	if player == null:
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if _push_vel.length() > 0.1:
		velocity.x = _push_vel.x
		velocity.z = _push_vel.z
		_push_vel = _push_vel.move_toward(Vector3.ZERO, 20.0 * delta)
	elif dist > ATTACK_RANGE:
		var dir := to_player.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		look_at(global_position + dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if _attack_cd <= 0.0:
			_attack(player)
			_attack_cd = ATTACK_COOLDOWN

	move_and_slide()


func _find_player() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node3D


func _attack(player: Node3D) -> void:
	if player.has_method("is_blocking") and player.is_blocking():
		var to_me := (global_position - player.global_position).normalized()
		var facing := -player.global_transform.basis.z
		if facing.dot(to_me) > 0.35:
			return
	RunState.apply_damage(ATTACK_DAMAGE)


func take_hit(damage: int, knockback: Vector3) -> void:
	var final_damage := damage
	var player := _find_player()
	if player:
		var to_player := (player.global_position - global_position).normalized()
		var facing := -global_transform.basis.z
		if facing.dot(to_player) > 0.35:
			final_damage = int(round(float(damage) * FRONT_DAMAGE_MULT))

	hp -= final_damage
	_push_vel = knockback
	if hp <= 0:
		_die()


func apply_push(force: Vector3) -> void:
	_push_vel = force


func _die() -> void:
	RunState.add_gold(GOLD_REWARD)
	queue_free()
