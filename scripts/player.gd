extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal died

const SPEED := 180.0
const MAX_HEALTH := 5
const SHOOT_COOLDOWN := 0.25
const IFRAME_TIME := 0.6

@export var bullet_scene: PackedScene

var health: int = MAX_HEALTH
var _shoot_timer: float = 0.0
var _iframe_timer: float = 0.0
var _dead: bool = false

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	health_changed.emit(health, MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_shoot_timer = maxf(0.0, _shoot_timer - delta)
	_iframe_timer = maxf(0.0, _iframe_timer - delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	move_and_slide()
	look_at(get_global_mouse_position())
	if Input.is_action_pressed("shoot") and _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = SHOOT_COOLDOWN

func take_damage(amount: int) -> void:
	if _dead or _iframe_timer > 0.0:
		return
	health = maxi(0, health - amount)
	_iframe_timer = IFRAME_TIME
	health_changed.emit(health, MAX_HEALTH)
	modulate.a = 0.5
	get_tree().create_timer(IFRAME_TIME).timeout.connect(func() -> void: modulate.a = 1.0)
	if health <= 0:
		_dead = true
		died.emit()

func _shoot() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	var direction := (get_global_mouse_position() - global_position).normalized()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + direction * 18.0
	bullet.setup(direction)

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", mouse)
		var space := InputEventKey.new()
		space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("shoot", space)

func _add_key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
