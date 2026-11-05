extends SceneTree

func _init() -> void:
	var sizes: Array = WaveConfig.wave_sizes()
	assert(sizes.size() == 3, "esperado 3 ondas")
	assert(sizes[0] == 4, "onda 1 deve ter 4")
	assert(sizes[1] == 6, "onda 2 deve ter 6")
	assert(sizes[2] == 8, "onda 3 deve ter 8")
	assert(is_equal_approx(WaveConfig.wave_interval(), 1.5), "intervalo 1.5s")
	print("TEST_WAVE_CONFIG_OK")
	quit(0)
