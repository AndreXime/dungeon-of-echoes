extends CanvasLayer

signal resumed
signal quit_to_hub

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Center/Panel
@onready var stats: Label = $Root/Center/Panel/Margin/VBox/Body/Stats
@onready var controls: Label = $Root/Center/Panel/Margin/VBox/Body/Controls
@onready var tab_ficha: Button = $Root/Center/Panel/Margin/VBox/Tabs/TabFicha
@onready var tab_controles: Button = $Root/Center/Panel/Margin/VBox/Tabs/TabControles
@onready var btn_resume: Button = $Root/Center/Panel/Margin/VBox/Resume
@onready var btn_hub: Button = $Root/Center/Panel/Margin/VBox/QuitHub
@onready var btn_quit: Button = $Root/Center/Panel/Margin/VBox/QuitGame

var _open := false
var _allow_quit_hub := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	visible = false
	root.visible = false
	btn_resume.pressed.connect(close)
	btn_hub.pressed.connect(_on_quit_hub)
	btn_quit.pressed.connect(_on_quit_game)
	tab_ficha.pressed.connect(func() -> void: _show_tab(true))
	tab_controles.pressed.connect(func() -> void: _show_tab(false))
	btn_hub.visible = _allow_quit_hub
	_refresh_controls()
	_show_tab(true)


func setup(allow_quit_hub: bool) -> void:
	_allow_quit_hub = allow_quit_hub
	if btn_hub:
		btn_hub.visible = allow_quit_hub
	_refresh_controls()


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _open:
		close()
		get_viewport().set_input_as_handled()
		return
	for node in get_tree().get_nodes_in_group("npc_shop"):
		if node.has_method("is_open") and node.is_open():
			return
	open()
	get_viewport().set_input_as_handled()


func open() -> void:
	if _open:
		return
	_open = true
	visible = true
	root.visible = true
	Engine.time_scale = 1.0
	_show_tab(true)
	_refresh_stats()
	_refresh_controls()
	_fit_panel()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	btn_resume.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	root.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()


func _show_tab(ficha: bool) -> void:
	tab_ficha.set_pressed_no_signal(ficha)
	tab_controles.set_pressed_no_signal(not ficha)
	stats.visible = ficha
	controls.visible = not ficha
	_fit_panel()


func _fit_panel() -> void:
	if panel == null:
		return
	panel.reset_size()



func _refresh_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var weapon := "?"
	if player and player.has_method("weapon_label"):
		weapon = player.weapon_label()
	var relics := "nenhuma"
	if not RunState.relics.is_empty():
		relics = ", ".join(PackedStringArray(RunState.relics))
	var map_line := _map_text()
	if RunState.in_run:
		stats.text = "\n".join(PackedStringArray([
			"Andar %d — %s" % [RunState.floor_index, RunState.biome_name()],
			"HP %d/%d   Poções %d" % [RunState.hp, RunState.max_hp, RunState.potions],
			"Ouro da run: %d   Essência: %d" % [RunState.gold, RunState.essence],
			"Arma: %s" % weapon,
			"Relíquias: %s" % relics,
			"",
			map_line,
			"",
			"Meta — Ouro: %d   Minério: %d" % [MetaProgress.gold, MetaProgress.ore],
		]))
	else:
		stats.text = "\n".join(PackedStringArray([
			"Acampamento",
			"Ouro: %d   Minério: %d" % [MetaProgress.gold, MetaProgress.ore],
			"Espada Nv.%d (dano %d)" % [MetaProgress.sword_damage_level, MetaProgress.sword_damage()],
			"HP bônus +%d   Poções %d" % [MetaProgress.bonus_max_hp, MetaProgress.potion_capacity],
			"Sorte %d   Mapa Nv.%d" % [MetaProgress.relic_luck, MetaProgress.cartographer_level],
			"Arma inicial: %s" % MetaProgress.selected_start_weapon,
		]))


func _refresh_controls() -> void:
	if controls == null:
		return
	if _allow_quit_hub or RunState.in_run:
		controls.text = "\n".join(PackedStringArray([
			"Movimento",
			"  WASD — andar",
			"  Mouse — olhar",
			"  Espaço — pular",
			"  Esc — pausar / fechar menu",
			"",
			"Combate",
			"  1 / 2 / 3 — espada, adaga, besta",
			"  LMB — atacar (avançando = estocada)",
			"  RMB — escudo (espada) ou puxar adaga",
			"  T — alternar tocha ↔ escudo",
			"  Q — usar poção",
			"  E — pegar relíquia",
			"",
			"Dicas",
			"  Empurre inimigos no escudo (espinhos)",
			"  Tocha e escudo não ficam ativos juntos",
		]))
	else:
		controls.text = "\n".join(PackedStringArray([
			"Movimento",
			"  WASD — andar",
			"  Mouse — olhar",
			"  Espaço — pular",
			"  Esc — ficha / controles / pausa",
			"",
			"Acampamento",
			"  E — abrir loja do NPC / portal",
			"  Na loja: clique na oferta · Esc fecha",
			"  ‹ › — mudar página se houver várias",
			"",
			"Geral",
			"  F4 — tela cheia",
		]))


func _map_text() -> String:
	if RunState.map_rooms.is_empty():
		return "Mapa: —"
	var parts: PackedStringArray = []
	for room in RunState.map_rooms:
		if not bool(room.get("revealed", false)):
			parts.append("?")
			continue
		var kind := String(room.get("kind", "?"))
		match kind:
			"hall":
				parts.append("Sala")
			"bridge":
				parts.append("Ponte")
			"hazard":
				parts.append("Armadilha")
			"cross":
				parts.append("Cruz")
			"treasure":
				parts.append("Tesouro")
			"boss":
				parts.append("Chefe")
			"end":
				parts.append("Saída")
			_:
				parts.append(kind)
	return "Mapa: " + " → ".join(parts)


func _on_quit_hub() -> void:
	close()
	quit_to_hub.emit()
	RunState.finish_run_and_return_to_hub()


func _on_quit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
