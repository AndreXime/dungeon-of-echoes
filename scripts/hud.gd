extends CanvasLayer

@onready var health_label: Label = $Margin/VBox/HealthLabel
@onready var well_health_label: Label = $Margin/VBox/WellHealthLabel
@onready var gold_label: Label = $Margin/VBox/GoldLabel
@onready var potions_label: Label = $Margin/VBox/PotionsLabel
@onready var wave_label: Label = $Margin/VBox/WaveLabel
@onready var enemies_label: Label = $Margin/VBox/EnemiesLabel
@onready var overlay: ColorRect = $Overlay
@onready var overlay_label: Label = $Overlay/Center/VBox/Message
@onready var restart_button: Button = $Overlay/Center/VBox/RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	restart_button.pressed.connect(_on_restart_pressed)

func set_health(current: int, max_health: int) -> void:
	health_label.text = "Vida: %d/%d" % [current, max_health]

func set_well_health(current: int, max_health: int) -> void:
	well_health_label.text = "Poço: %d/%d" % [current, max_health]

func set_gold(amount: int) -> void:
	gold_label.text = "Ouro: %d" % amount

func set_potions(small: int, large: int) -> void:
	potions_label.text = "Poções: %d / %d" % [small, large]

func set_wave(wave_index: int, total_waves: int) -> void:
	wave_label.text = "Onda: %d/%d" % [wave_index, total_waves]

func set_enemies(remaining: int) -> void:
	enemies_label.text = "Inimigos: %d" % remaining

func show_victory() -> void:
	overlay_label.text = "Vitória!"
	overlay.visible = true

func show_defeat() -> void:
	overlay_label.text = "Derrota"
	overlay.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
