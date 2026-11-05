extends CharacterBody2D

signal health_changed(current: int, max_health: int)
signal gold_changed(amount: int)
signal potions_changed(small: int, large: int)
signal died

const SPEED := 180.0
const BASE_MAX_HEALTH := 5
const BASE_ATTACK_DAMAGE := 1
const ATTACK_COOLDOWN := 0.4
const ATTACK_SWING_TIME := 0.22
const ATTACK_REACH := 30.0
const IFRAME_TIME := 0.6
const SWORD_TIP_OFFSET := PI * 0.5
const HAND_DISTANCE := 8.0
const IDLE_HAND := Vector2(11, 2)
const SWING_FROM := deg_to_rad(70.0)
const SWING_TO := deg_to_rad(-70.0)

var max_health: int = BASE_MAX_HEALTH
var health: int = BASE_MAX_HEALTH
var attack_damage: int = BASE_ATTACK_DAMAGE
var gold: int = 0
var potion_small: int = 0
var potion_large: int = 0
var has_better_sword: bool = false
var _attack_timer: float = 0.0
var _iframe_timer: float = 0.0
var _dead: bool = false
var _attacking: bool = false
var _attack_hits: Dictionary = {}
var _facing := Vector2.RIGHT
var _aim_angle: float = 0.0
var _swing_tween: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _sword: Sprite2D = $Sword
@onready var _hitbox: Area2D = $AttackHitbox

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	_sword.visible = true
	_sword.z_index = 1
	_sword.centered = true
	_sword.offset = Vector2(0, -10)
	_hitbox.monitoring = false
	_hitbox.body_entered.connect(_on_attack_hit)
	_place_sword_idle()
	health_changed.emit(health, max_health)
	gold_changed.emit(gold)
	potions_changed.emit(potion_small, potion_large)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_iframe_timer = maxf(0.0, _iframe_timer - delta)
	if Input.is_action_just_pressed("potion_small"):
		use_potion_small()
	if Input.is_action_just_pressed("potion_large"):
		use_potion_large()
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	move_and_slide()
	var aim_dir := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim_dir.length_squared() > 0.01:
		_facing = aim_dir.normalized()
		_aim_angle = _facing.angle()
		_sprite.flip_h = _facing.x < 0.0
		if not _attacking and _attack_timer <= 0.0:
			_start_attack()
	if not _attacking:
		_place_sword_idle()

func take_damage(amount: int) -> void:
	if _dead or _iframe_timer > 0.0:
		return
	health = maxi(0, health - amount)
	_iframe_timer = IFRAME_TIME
	health_changed.emit(health, max_health)
	modulate.a = 0.5
	get_tree().create_timer(IFRAME_TIME).timeout.connect(func() -> void: modulate.a = 1.0)
	if health <= 0:
		_dead = true
		died.emit()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func use_potion_small() -> void:
	if potion_small <= 0 or _dead:
		return
	potion_small -= 1
	health = mini(max_health, health + 2)
	potions_changed.emit(potion_small, potion_large)
	health_changed.emit(health, max_health)

func use_potion_large() -> void:
	if potion_large <= 0 or _dead:
		return
	potion_large -= 1
	health = mini(max_health, health + 5)
	potions_changed.emit(potion_small, potion_large)
	health_changed.emit(health, max_health)

func try_buy(item_id: String, price: int) -> bool:
	if gold < price or _dead:
		return false
	match item_id:
		"potion_small":
			gold -= price
			potion_small += 1
			potions_changed.emit(potion_small, potion_large)
		"potion_large":
			gold -= price
			potion_large += 1
			potions_changed.emit(potion_small, potion_large)
		"max_hp":
			gold -= price
			max_health += 1
			health = mini(max_health, health + 1)
			health_changed.emit(health, max_health)
		"attack":
			gold -= price
			attack_damage += 1
		"sword_better":
			if has_better_sword:
				return false
			gold -= price
			has_better_sword = true
			attack_damage += 1
			_sword.texture = load("res://assets/sprites/sword_better.png")
		_:
			return false
	gold_changed.emit(gold)
	return true

func _place_sword_idle() -> void:
	var facing_x := -1.0 if _sprite.flip_h else 1.0
	_sword.flip_h = false
	_sword.flip_v = false
	_sword.position = Vector2(IDLE_HAND.x * facing_x, IDLE_HAND.y)
	_sword.rotation = SWORD_TIP_OFFSET * facing_x

func _start_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	_attacking = true
	_attack_hits.clear()
	if _swing_tween != null and _swing_tween.is_valid():
		_swing_tween.kill()
	_sword.flip_h = false
	_sword.flip_v = false
	_aim_angle = _facing.angle()
	_sword.position = Vector2.from_angle(_aim_angle) * HAND_DISTANCE
	var start_angle := _aim_angle + SWING_FROM
	var end_angle := _aim_angle + SWING_TO
	_set_swing_angle(start_angle)
	_hitbox.monitoring = true
	_swing_tween = create_tween()
	_swing_tween.set_trans(Tween.TRANS_SINE)
	_swing_tween.set_ease(Tween.EASE_OUT)
	_swing_tween.tween_method(_set_swing_angle, start_angle, end_angle, ATTACK_SWING_TIME)
	_swing_tween.finished.connect(_end_attack)

func _set_swing_angle(angle: float) -> void:
	_sword.rotation = angle + SWORD_TIP_OFFSET
	_sword.position = Vector2.from_angle(_aim_angle) * HAND_DISTANCE
	_update_hitbox(angle)

func _update_hitbox(angle: float) -> void:
	_hitbox.position = Vector2.from_angle(angle) * ATTACK_REACH
	_hitbox.rotation = angle

func _end_attack() -> void:
	if not is_instance_valid(self):
		return
	_attacking = false
	_hitbox.monitoring = false
	_place_sword_idle()

func _on_attack_hit(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	var id := body.get_instance_id()
	if _attack_hits.has(id):
		return
	_attack_hits[id] = true
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)

func _ensure_input_actions() -> void:
	_replace_key_action("move_left", [KEY_A])
	_replace_key_action("move_right", [KEY_D])
	_replace_key_action("move_up", [KEY_W])
	_replace_key_action("move_down", [KEY_S])
	_replace_key_action("aim_left", [KEY_LEFT])
	_replace_key_action("aim_right", [KEY_RIGHT])
	_replace_key_action("aim_up", [KEY_UP])
	_replace_key_action("aim_down", [KEY_DOWN])
	_replace_key_action("potion_small", [KEY_1])
	_replace_key_action("potion_large", [KEY_2])
	_replace_key_action("interact", [KEY_E])

func _replace_key_action(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
