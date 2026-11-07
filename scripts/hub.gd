extends Node3D

@onready var hud: Label = $HUD/Status
@onready var prompt: Label = $HUD/Prompt
@onready var message: Label = $HUD/Message

var _near_interactable: Area3D
var _alchemist_mode := 0
var _smith_mode := 0
var _pause_menu: Node


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_hud()
	message.text = ""
	for node in get_tree().get_nodes_in_group("hub_interactable"):
		if node.has_signal("interacted"):
			node.interacted.connect(_on_interact.bind(node))
	var packed := load("res://scenes/pause_menu.tscn") as PackedScene
	if packed:
		_pause_menu = packed.instantiate()
		add_child(_pause_menu)
		if _pause_menu.has_method("setup"):
			_pause_menu.setup(false)


func _process(_delta: float) -> void:
	_near_interactable = null
	for node in get_tree().get_nodes_in_group("hub_interactable"):
		if node.has_method("is_player_near") and node.is_player_near():
			_near_interactable = node
			break
	if _near_interactable:
		prompt.text = "E — %s" % _prompt_for(_near_interactable)
	else:
		prompt.text = ""


func _prompt_for(node: Area3D) -> String:
	var action := String(node.action_id) if "action_id" in node else ""
	match action:
		"blacksmith":
			return _smith_prompt()
		"alchemist":
			return _alchemist_prompt()
		"cartographer":
			return "Cartógrafo (mapa Nv.%d)" % MetaProgress.cartographer_level
		_:
			return String(node.prompt_text) if "prompt_text" in node else "Interagir"


func _smith_prompt() -> String:
	match _smith_mode % 4:
		1:
			return "Ferreiro: desbloquear Adaga (12 minério)"
		2:
			return "Ferreiro: desbloquear Besteira (18 minério)"
		3:
			return "Ferreiro: arma inicial (%s)" % MetaProgress.selected_start_weapon
		_:
			return "Ferreiro: reforçar espada (%d ouro)" % MetaProgress.upgrade_cost()


func _alchemist_prompt() -> String:
	match _alchemist_mode % 3:
		1:
			return "Alquimista: +1 poção (%d ouro)" % MetaProgress.potion_upgrade_cost()
		2:
			return "Alquimista: sorte de relíquia (%d ouro)" % MetaProgress.luck_upgrade_cost()
		_:
			return "Alquimista: +10 HP (%d ouro)" % MetaProgress.hp_upgrade_cost()


func _refresh_hud() -> void:
	hud.text = "Ouro: %d  |  Minério: %d" % [
		MetaProgress.gold,
		MetaProgress.ore,
	]


func _on_interact(interactable: Node) -> void:
	var action := ""
	if "action_id" in interactable:
		action = interactable.action_id
	match action:
		"blacksmith":
			_do_blacksmith()
		"alchemist":
			_do_alchemist()
		"cartographer":
			if MetaProgress.cartographer_level >= MetaProgress.CARTO_CAP:
				_show_message("Cartógrafo: mapa no máximo. Salas especiais reveladas.")
			elif MetaProgress.try_upgrade_cartographer():
				_show_message("Cartógrafo: revela +1 sala no mapa da run!")
				_refresh_hud()
			else:
				_show_message("Ouro insuficiente. Precisa de %d." % MetaProgress.carto_upgrade_cost())
		"portal":
			RunState.reset_for_new_run()
			get_tree().change_scene_to_file("res://scenes/dungeon_run.tscn")
		_:
			_show_message("...")


func _do_blacksmith() -> void:
	match _smith_mode % 4:
		1:
			if MetaProgress.unlocked_start_weapons.has("dagger"):
				_show_message("Adaga já desbloqueada.")
			elif MetaProgress.try_unlock_weapon("dagger", 12):
				_show_message("Ferreiro: Adaga desbloqueada!")
				_refresh_hud()
			else:
				_show_message("Minério insuficiente (12).")
		2:
			if MetaProgress.unlocked_start_weapons.has("crossbow"):
				_show_message("Besteira já desbloqueada.")
			elif MetaProgress.try_unlock_weapon("crossbow", 18):
				_show_message("Ferreiro: Besteira desbloqueada!")
				_refresh_hud()
			else:
				_show_message("Minério insuficiente (18).")
		3:
			var options: Array[String] = []
			for w in MetaProgress.unlocked_start_weapons:
				options.append(w)
			if options.is_empty():
				options.append("sword")
			var idx := options.find(MetaProgress.selected_start_weapon)
			idx = (idx + 1) % options.size()
			MetaProgress.selected_start_weapon = options[idx]
			MetaProgress.save()
			_show_message("Arma inicial: %s" % MetaProgress.selected_start_weapon)
			_refresh_hud()
		_:
			if MetaProgress.sword_damage_level >= MetaProgress.SWORD_DAMAGE_CAP:
				_show_message("Espada já está no nível máximo.")
			elif MetaProgress.try_upgrade_sword():
				_show_message("Ferreiro: lâmina reforçada!")
				_refresh_hud()
			else:
				_show_message("Ouro insuficiente. Precisa de %d." % MetaProgress.upgrade_cost())
	_smith_mode += 1


func _do_alchemist() -> void:
	match _alchemist_mode % 3:
		1:
			if MetaProgress.potion_capacity >= MetaProgress.POTION_CAP:
				_show_message("Capacidade de poções no máximo.")
			elif MetaProgress.try_upgrade_potions():
				_show_message("Alquimista: +1 poção por run!")
				_refresh_hud()
			else:
				_show_message("Ouro insuficiente. Precisa de %d." % MetaProgress.potion_upgrade_cost())
		2:
			if MetaProgress.relic_luck >= 5:
				_show_message("Sorte de relíquia no máximo.")
			elif MetaProgress.try_upgrade_luck():
				_show_message("Alquimista: relíquias aparecem mais!")
				_refresh_hud()
			else:
				_show_message("Ouro insuficiente. Precisa de %d." % MetaProgress.luck_upgrade_cost())
		_:
			if MetaProgress.bonus_max_hp >= MetaProgress.HP_BONUS_CAP:
				_show_message("Alquimista: vitalidade no máximo.")
			elif MetaProgress.try_upgrade_max_hp():
				_show_message("Alquimista: +10 vida máxima permanente!")
				_refresh_hud()
			else:
				_show_message("Ouro insuficiente. Precisa de %d." % MetaProgress.hp_upgrade_cost())
	_alchemist_mode += 1


func _show_message(text: String) -> void:
	message.text = text
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if is_instance_valid(message):
			message.text = ""
	)
