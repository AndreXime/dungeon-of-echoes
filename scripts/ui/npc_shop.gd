extends CanvasLayer

signal closed
signal stock_changed(message: String)

const PAGE_SIZE := 5

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var wallet_label: Label = $Root/Panel/Margin/VBox/Wallet
@onready var list: VBoxContainer = $Root/Panel/Margin/VBox/List
@onready var page_label: Label = $Root/Panel/Margin/VBox/PageRow/PageLabel
@onready var btn_prev: Button = $Root/Panel/Margin/VBox/PageRow/Prev
@onready var btn_next: Button = $Root/Panel/Margin/VBox/PageRow/Next
@onready var btn_close: Button = $Root/Panel/Margin/VBox/Actions/Close

var _npc_id := ""
var _offers: Array[Dictionary] = []
var _page := 0
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	add_to_group("npc_shop")
	visible = false
	root.visible = false
	btn_prev.pressed.connect(func() -> void: _set_page(_page - 1))
	btn_next.pressed.connect(func() -> void: _set_page(_page + 1))
	btn_close.pressed.connect(close)


func is_open() -> bool:
	return _open


func open_for(npc_id: String) -> void:
	_npc_id = npc_id
	_offers = _build_offers(npc_id)
	_page = 0
	_open = true
	visible = true
	root.visible = true
	title_label.text = _npc_title(npc_id)
	_refresh_wallet()
	_refresh_list()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_set_page(_page - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_set_page(_page + 1)
		get_viewport().set_input_as_handled()


func _npc_title(npc_id: String) -> String:
	match npc_id:
		"blacksmith":
			return "Ferreiro"
		"alchemist":
			return "Alquimista"
		"cartographer":
			return "Cartógrafo"
		_:
			return "Comerciante"


func _build_offers(npc_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match npc_id:
		"blacksmith":
			out.append(_offer(
				"sword",
				"Reforçar espada",
				"%d ouro · Nv.%d/%d" % [MetaProgress.upgrade_cost(), MetaProgress.sword_damage_level, MetaProgress.SWORD_DAMAGE_CAP],
				MetaProgress.sword_damage_level < MetaProgress.SWORD_DAMAGE_CAP,
				MetaProgress.gold >= MetaProgress.upgrade_cost()
			))
			var has_dagger := MetaProgress.unlocked_start_weapons.has("dagger")
			out.append(_offer(
				"dagger",
				"Desbloquear adaga",
				"12 minério" if not has_dagger else "Já desbloqueada",
				not has_dagger,
				MetaProgress.ore >= 12
			))
			var has_bow := MetaProgress.unlocked_start_weapons.has("crossbow")
			out.append(_offer(
				"crossbow",
				"Desbloquear besta",
				"18 minério" if not has_bow else "Já desbloqueada",
				not has_bow,
				MetaProgress.ore >= 18
			))
			out.append(_offer(
				"start_weapon",
				"Arma inicial: %s" % _weapon_name(MetaProgress.selected_start_weapon),
				"Grátis · E cicla",
				true,
				true
			))
		"alchemist":
			out.append(_offer(
				"hp",
				"+10 vida máxima",
				"%d ouro · bônus %d/%d" % [MetaProgress.hp_upgrade_cost(), MetaProgress.bonus_max_hp, MetaProgress.HP_BONUS_CAP],
				MetaProgress.bonus_max_hp < MetaProgress.HP_BONUS_CAP,
				MetaProgress.gold >= MetaProgress.hp_upgrade_cost()
			))
			out.append(_offer(
				"potion",
				"+1 poção por run",
				"%d ouro · %d/%d" % [MetaProgress.potion_upgrade_cost(), MetaProgress.potion_capacity, MetaProgress.POTION_CAP],
				MetaProgress.potion_capacity < MetaProgress.POTION_CAP,
				MetaProgress.gold >= MetaProgress.potion_upgrade_cost()
			))
			out.append(_offer(
				"luck",
				"Sorte de relíquia",
				"%d ouro · Nv.%d/5" % [MetaProgress.luck_upgrade_cost(), MetaProgress.relic_luck],
				MetaProgress.relic_luck < 5,
				MetaProgress.gold >= MetaProgress.luck_upgrade_cost()
			))
		"cartographer":
			out.append(_offer(
				"map",
				"Revelar +1 sala no mapa",
				"%d ouro · Nv.%d/%d" % [MetaProgress.carto_upgrade_cost(), MetaProgress.cartographer_level, MetaProgress.CARTO_CAP],
				MetaProgress.cartographer_level < MetaProgress.CARTO_CAP,
				MetaProgress.gold >= MetaProgress.carto_upgrade_cost()
			))
	return out


func _offer(id: String, title: String, detail: String, available: bool, affordable: bool) -> Dictionary:
	return {
		"id": id,
		"title": title,
		"detail": detail,
		"available": available,
		"affordable": affordable,
	}


func _weapon_name(id: String) -> String:
	match id:
		"dagger":
			return "Adaga"
		"crossbow":
			return "Besta"
		_:
			return "Espada"


func _page_count() -> int:
	return maxi(1, int(ceil(float(_offers.size()) / float(PAGE_SIZE))))


func _set_page(page: int) -> void:
	_page = clampi(page, 0, _page_count() - 1)
	_refresh_list()


func _refresh_wallet() -> void:
	wallet_label.text = "Ouro %d  ·  Minério %d" % [MetaProgress.gold, MetaProgress.ore]


func _refresh_list() -> void:
	_refresh_wallet()
	for child in list.get_children():
		child.queue_free()
	var start := _page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, _offers.size())
	for i in range(start, end):
		var offer: Dictionary = _offers[i]
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var mark := ""
		if not bool(offer["available"]):
			mark = "  ·  esgotado"
			btn.disabled = true
		elif not bool(offer["affordable"]):
			mark = "  ·  sem recurso"
		btn.text = "%s — %s%s" % [String(offer["title"]), String(offer["detail"]), mark]
		var offer_id := String(offer["id"])
		btn.pressed.connect(_on_offer_pressed.bind(offer_id))
		list.add_child(btn)
	page_label.text = "Página %d/%d" % [_page + 1, _page_count()]
	btn_prev.disabled = _page <= 0
	btn_next.disabled = _page >= _page_count() - 1
	btn_prev.visible = _offers.size() > PAGE_SIZE
	btn_next.visible = _offers.size() > PAGE_SIZE
	page_label.visible = _offers.size() > PAGE_SIZE


func _on_offer_pressed(offer_id: String) -> void:
	var msg := _try_buy(offer_id)
	_offers = _build_offers(_npc_id)
	_page = clampi(_page, 0, _page_count() - 1)
	_refresh_list()
	stock_changed.emit(msg)


func _try_buy(offer_id: String) -> String:
	match _npc_id:
		"blacksmith":
			return _buy_blacksmith(offer_id)
		"alchemist":
			return _buy_alchemist(offer_id)
		"cartographer":
			return _buy_cartographer(offer_id)
		_:
			return "..."


func _buy_blacksmith(offer_id: String) -> String:
	match offer_id:
		"sword":
			if MetaProgress.sword_damage_level >= MetaProgress.SWORD_DAMAGE_CAP:
				return "Espada no nível máximo."
			if MetaProgress.try_upgrade_sword():
				return "Lâmina reforçada!"
			return "Ouro insuficiente (%d)." % MetaProgress.upgrade_cost()
		"dagger":
			if MetaProgress.unlocked_start_weapons.has("dagger"):
				return "Adaga já desbloqueada."
			if MetaProgress.try_unlock_weapon("dagger", 12):
				return "Adaga desbloqueada!"
			return "Minério insuficiente (12)."
		"crossbow":
			if MetaProgress.unlocked_start_weapons.has("crossbow"):
				return "Besta já desbloqueada."
			if MetaProgress.try_unlock_weapon("crossbow", 18):
				return "Besta desbloqueada!"
			return "Minério insuficiente (18)."
		"start_weapon":
			var options: Array[String] = []
			for w in MetaProgress.unlocked_start_weapons:
				options.append(w)
			if options.is_empty():
				options.append("sword")
			var idx := options.find(MetaProgress.selected_start_weapon)
			idx = (idx + 1) % options.size()
			MetaProgress.selected_start_weapon = options[idx]
			MetaProgress.save()
			return "Arma inicial: %s" % _weapon_name(MetaProgress.selected_start_weapon)
		_:
			return "..."


func _buy_alchemist(offer_id: String) -> String:
	match offer_id:
		"hp":
			if MetaProgress.bonus_max_hp >= MetaProgress.HP_BONUS_CAP:
				return "Vitalidade no máximo."
			if MetaProgress.try_upgrade_max_hp():
				return "+10 vida máxima permanente!"
			return "Ouro insuficiente (%d)." % MetaProgress.hp_upgrade_cost()
		"potion":
			if MetaProgress.potion_capacity >= MetaProgress.POTION_CAP:
				return "Poções no máximo."
			if MetaProgress.try_upgrade_potions():
				return "+1 poção por run!"
			return "Ouro insuficiente (%d)." % MetaProgress.potion_upgrade_cost()
		"luck":
			if MetaProgress.relic_luck >= 5:
				return "Sorte no máximo."
			if MetaProgress.try_upgrade_luck():
				return "Relíquias aparecem mais!"
			return "Ouro insuficiente (%d)." % MetaProgress.luck_upgrade_cost()
		_:
			return "..."


func _buy_cartographer(offer_id: String) -> String:
	if offer_id != "map":
		return "..."
	if MetaProgress.cartographer_level >= MetaProgress.CARTO_CAP:
		return "Mapa no máximo."
	if MetaProgress.try_upgrade_cartographer():
		return "Mapa revela +1 sala!"
	return "Ouro insuficiente (%d)." % MetaProgress.carto_upgrade_cost()
