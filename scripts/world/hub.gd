extends Node3D

@onready var prompt_panel: PanelContainer = $HUD/PromptPanel
@onready var prompt: Label = $HUD/PromptPanel/Prompt
@onready var message_panel: PanelContainer = $HUD/MessagePanel
@onready var message: Label = $HUD/MessagePanel/Message

var _near_interactable: Area3D
var _pause_menu: Node
var _shop: Node


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Music.play_hub()
	_hide_message()
	prompt_panel.visible = false
	for node in get_tree().get_nodes_in_group("hub_interactable"):
		if node.has_signal("interacted"):
			node.interacted.connect(_on_interact.bind(node))
	var pause_packed := load("res://scenes/pause_menu.tscn") as PackedScene
	if pause_packed:
		_pause_menu = pause_packed.instantiate()
		add_child(_pause_menu)
		if _pause_menu.has_method("setup"):
			_pause_menu.setup(false)
	var shop_packed := load("res://scenes/ui/npc_shop.tscn") as PackedScene
	if shop_packed:
		_shop = shop_packed.instantiate()
		add_child(_shop)
		if _shop.has_signal("stock_changed"):
			_shop.stock_changed.connect(_on_shop_stock_changed)


func _process(_delta: float) -> void:
	if _shop_open() or (_pause_menu and _pause_menu.has_method("is_open") and _pause_menu.is_open()):
		prompt_panel.visible = false
		return
	_near_interactable = null
	for node in get_tree().get_nodes_in_group("hub_interactable"):
		if node.has_method("is_player_near") and node.is_player_near():
			_near_interactable = node
			break
	if _near_interactable:
		prompt.text = _prompt_for(_near_interactable)
		prompt_panel.visible = true
	else:
		prompt_panel.visible = false


func _shop_open() -> bool:
	return _shop != null and _shop.has_method("is_open") and _shop.is_open()


func _prompt_for(node: Area3D) -> String:
	var action := String(node.action_id) if "action_id" in node else ""
	match action:
		"blacksmith":
			return "Falar com o Ferreiro"
		"alchemist":
			return "Falar com o Alquimista"
		"cartographer":
			return "Falar com o Cartógrafo"
		"portal":
			return "Entrar na masmorra"
		_:
			var name := String(node.prompt_text) if "prompt_text" in node else "alguém"
			return "Falar com %s" % name


func _on_shop_stock_changed(msg: String) -> void:
	_show_message(msg)


func _on_interact(interactable: Node) -> void:
	if _shop_open():
		return
	var action := ""
	if "action_id" in interactable:
		action = interactable.action_id
	match action:
		"blacksmith", "alchemist", "cartographer":
			if _shop and _shop.has_method("open_for"):
				_shop.open_for(action)
		"portal":
			RunState.reset_for_new_run()
			get_tree().change_scene_to_file("res://scenes/dungeon_run.tscn")
		_:
			_show_message("...")


func _show_message(text: String) -> void:
	message.text = text
	message_panel.visible = text != ""
	var panel_id := message_panel.get_instance_id()
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		var live := instance_from_id(panel_id) as PanelContainer
		if live:
			live.visible = false
	)


func _hide_message() -> void:
	message.text = ""
	message_panel.visible = false
