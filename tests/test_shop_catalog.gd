extends SceneTree

func _init() -> void:
	assert(ShopCatalog.item_ids().size() == 5)
	assert(ShopCatalog.price("potion_small", 1) == 5)
	assert(ShopCatalog.price("potion_large", 1) == 12)
	assert(ShopCatalog.price("max_hp", 1) == 15)
	assert(ShopCatalog.price("attack", 1) == 18)
	assert(ShopCatalog.price("sword_better", 1) == 25)
	assert(ShopCatalog.price("potion_small", 2) == 6)
	assert(ShopCatalog.price("sword_better", 2) == 30)
	assert(ShopCatalog.info("sword_better").unique == true)
	print("TEST_SHOP_CATALOG_OK")
	quit(0)
