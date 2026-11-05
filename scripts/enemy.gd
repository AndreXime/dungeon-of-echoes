extends CharacterBody2D

signal died(coins: int)

var kind: String = "slime"
var health: int = 2
var contact_damage: int = 1
var coins: int = 1
var speed: float = 90.0
var bonus_coin_chance: float = 0.0
var _well: Node2D
var _attack_cooldown: float = 0.0
var _setup_done: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

func setup(enemy_kind: String, speed_mult: float = 1.0) -> void:
	kind = enemy_kind
	var s: Dictionary = EnemyCatalog.stats(kind)
	health = int(s.hp)
	contact_damage = int(s.damage)
	coins = int(s.coins)
	speed = float(s.speed) * speed_mult
	_setup_done = true
	if is_node_ready():
		_apply_texture(String(s.texture))

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	if not _setup_done:
		var s: Dictionary = EnemyCatalog.stats(kind)
		health = int(s.hp)
		contact_damage = int(s.damage)
		coins = int(s.coins)
		speed = float(s.speed)
	_apply_texture(String(EnemyCatalog.stats(kind).texture))
	_well = get_tree().get_first_node_in_group("well")
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)

func _apply_texture(path: String) -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D")
	if _sprite:
		_sprite.texture = load(path)

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _well == null or not is_instance_valid(_well):
		_well = get_tree().get_first_node_in_group("well")
		return
	var direction := global_position.direction_to(_well.global_position)
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(_well.global_position) < 22.0 and _attack_cooldown <= 0.0:
		if _well.has_method("take_damage"):
			_well.take_damage(contact_damage)
			_attack_cooldown = 0.8

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		var drop := coins
		if bonus_coin_chance > 0.0 and randf() < bonus_coin_chance:
			drop += 1
		died.emit(drop)
		queue_free()

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
