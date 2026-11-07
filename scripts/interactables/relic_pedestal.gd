extends Area3D

@export var relic_id: String = "glass_eye"
@export var relic_name: String = "Olho de Vidro"
@export var relic_desc: String = "Projéteis marcam. Próximo melee causa dobro."

var _taken := false
var _player_near := false


func _ready() -> void:
	body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_near = true
	)
	body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_player_near = false
	)
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	add_to_group("relic_pedestal")


func _unhandled_input(event: InputEvent) -> void:
	if _taken or not _player_near:
		return
	if event.is_action_pressed("interact"):
		_take()


func prompt() -> String:
	if _taken:
		return ""
	return "E — Pegar %s" % relic_name


func _take() -> void:
	if _taken:
		return
	if not RunState.add_relic(relic_id):
		return
	_taken = true
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = "Relíquia coletada"
	var msg := get_tree().get_first_node_in_group("run_message") as Label
	if msg:
		msg.text = "%s: %s" % [relic_name, relic_desc]
		var label_id := msg.get_instance_id()
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			var live := instance_from_id(label_id) as Label
			if live:
				live.text = ""
		)
