extends PanelContainer

signal next_wave_pressed

var _cycle: int = 1
var _player: Node

@onready var _gold_label: Label = $VBox/GoldLabel
@onready var _btn_small: Button = $VBox/BuyPotionSmall
@onready var _btn_large: Button = $VBox/BuyPotionLarge
@onready var _btn_hp: Button = $VBox/BuyMaxHp
@onready var _btn_atk: Button = $VBox/BuyAttack
@onready var _btn_sword: Button = $VBox/BuySword
@onready var _btn_next: Button = $VBox/NextWaveButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_btn_small.pressed.connect(func(): _buy("potion_small"))
	_btn_large.pressed.connect(func(): _buy("potion_large"))
	_btn_hp.pressed.connect(func(): _buy("max_hp"))
	_btn_atk.pressed.connect(func(): _buy("attack"))
	_btn_sword.pressed.connect(func(): _buy("sword_better"))
	_btn_next.pressed.connect(func(): next_wave_pressed.emit())

func open(cycle: int, player: Node) -> void:
	_cycle = cycle
	_player = player
	visible = true
	_refresh()

func close() -> void:
	visible = false
	_player = null

func _buy(item_id: String) -> void:
	if _player == null:
		return
	var price: int = ShopCatalog.price(item_id, _cycle)
	if _player.try_buy(item_id, price):
		_refresh()

func _refresh() -> void:
	if _player == null:
		return
	_gold_label.text = "Ouro: %d" % int(_player.gold)
	_btn_small.text = "%s (%d)" % [ShopCatalog.info("potion_small").label, ShopCatalog.price("potion_small", _cycle)]
	_btn_large.text = "%s (%d)" % [ShopCatalog.info("potion_large").label, ShopCatalog.price("potion_large", _cycle)]
	_btn_hp.text = "%s (%d)" % [ShopCatalog.info("max_hp").label, ShopCatalog.price("max_hp", _cycle)]
	_btn_atk.text = "%s (%d)" % [ShopCatalog.info("attack").label, ShopCatalog.price("attack", _cycle)]
	_btn_sword.text = "%s (%d)" % [ShopCatalog.info("sword_better").label, ShopCatalog.price("sword_better", _cycle)]
	_btn_sword.disabled = bool(_player.has_better_sword)
