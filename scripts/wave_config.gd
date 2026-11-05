class_name WaveConfig
extends RefCounted

static func total_waves() -> int:
	return 12

static func enemy_count(wave: int) -> int:
	return 4 + wave

static func wave_interval() -> float:
	return 1.5

static func is_shop_wave(wave: int) -> bool:
	return wave > 0 and wave % 4 == 0 and wave < total_waves()

static func shop_cycle(wave: int) -> int:
	if not is_shop_wave(wave):
		return 0
	return int(wave / 4)

static func speed_multiplier(wave: int) -> float:
	return 1.0 + 0.05 * float(int((wave - 1) / 4))

static func pick_kinds_for_wave(wave: int) -> PackedStringArray:
	var unlocked: PackedStringArray = EnemyCatalog.kinds_unlocked_at(wave)
	if wave <= 1:
		return PackedStringArray(["slime"])
	if wave == 2:
		return PackedStringArray(["slime", "rato"])
	return unlocked
