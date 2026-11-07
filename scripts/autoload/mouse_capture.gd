extends CanvasLayer

## Na Web o browser só permite pointer lock após um gesto (clique).
## Mostra um overlay e captura o mouse nesse clique, também após Esc/loja.

var _dim: ColorRect
var _label: Label


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_refresh()


func _build_overlay() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.05, 0.03, 0.02, 0.55)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_dim)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text = "Clique para jogar"
	_label.add_theme_font_size_override("font_size", 28)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var want_overlay := _needs_click_to_capture()
	visible = want_overlay


func _needs_click_to_capture() -> bool:
	if _ui_blocks_capture():
		return false
	# Desktop: só se o cursor ficou livre no meio da run (Alt+Tab / Esc browser).
	# Web: sempre precisa de clique após load e após soltar o lock.
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return false
	return true


func _ui_blocks_capture() -> bool:
	if get_tree() == null:
		return true
	for node in get_tree().get_nodes_in_group("npc_shop"):
		if node.has_method("is_open") and node.is_open():
			return true
	# PauseMenu não está em grupo; detecta CanvasLayer com método is_open.
	for node in get_tree().get_nodes_in_group("pause_menu"):
		if node.has_method("is_open") and node.is_open():
			return true
	return false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Precisa ser no mesmo gesto do clique (exigência do browser).
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		visible = false
		get_viewport().set_input_as_handled()
