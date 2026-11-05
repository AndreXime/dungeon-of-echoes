class_name ShopCatalog
extends RefCounted

const _ITEMS := {
	"potion_small": {"label": "Poção pequena (+2 HP)", "base_price": 5, "unique": false},
	"potion_large": {"label": "Poção grande (+5 HP)", "base_price": 12, "unique": false},
	"max_hp": {"label": "+1 vida máxima", "base_price": 15, "unique": false},
	"attack": {"label": "+1 ataque", "base_price": 18, "unique": false},
	"sword_better": {"label": "Espada melhor (+1 dano)", "base_price": 25, "unique": true},
}

static func item_ids() -> PackedStringArray:
	return PackedStringArray(_ITEMS.keys())

static func info(item_id: String) -> Dictionary:
	assert(_ITEMS.has(item_id))
	return _ITEMS[item_id].duplicate()

static func price(item_id: String, cycle: int) -> int:
	var base: int = int(info(item_id).base_price)
	var safe_cycle: int = maxi(1, cycle)
	return int(ceil(float(base) * pow(1.2, float(safe_cycle - 1))))
