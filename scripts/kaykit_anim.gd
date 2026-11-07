extends Object
class_name KayKitAnim

## Aplica AnimationPlayer KayKit (Rig_Medium) em personagens com hierarquia Rig_Medium/Skeleton3D.

const ANIM_GENERAL := "res://assets/kaykit/animations/Rig_Medium/Rig_Medium_General.glb"
const ANIM_MOVE := "res://assets/kaykit/animations/Rig_Medium/Rig_Medium_MovementBasic.glb"
const ANIM_SPECIAL := "res://assets/kaykit/animations/Rig_Medium/Rig_Medium_Special.glb"

const IDLE_HUMAN := &"general/Idle_A"
const WALK_HUMAN := &"move/Walking_A"
const IDLE_SKELETON := &"special/Skeletons_Idle"
const WALK_SKELETON := &"special/Skeletons_Walking"

static var _ready_libs := false
static var _lib_general: AnimationLibrary
static var _lib_move: AnimationLibrary
static var _lib_special: AnimationLibrary


static func is_rigged(model: Node) -> bool:
	return _find_character_root(model) != null


static func is_skeleton_model(model_path: String) -> bool:
	return model_path.contains("/skeletons/")


static func setup(model: Node, skeleton_style: bool = false) -> AnimationPlayer:
	var character := _find_character_root(model)
	if character == null:
		return null
	_ensure_libraries()
	var existing := character.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if existing:
		return existing
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	character.add_child(ap)
	if _lib_general:
		ap.add_animation_library("general", _lib_general)
	if _lib_move:
		ap.add_animation_library("move", _lib_move)
	if skeleton_style and _lib_special:
		ap.add_animation_library("special", _lib_special)
	return ap


static func play_idle(ap: AnimationPlayer, skeleton_style: bool = false) -> void:
	if ap == null:
		return
	var key := IDLE_SKELETON if skeleton_style else IDLE_HUMAN
	if not ap.has_animation(key) and skeleton_style:
		key = IDLE_HUMAN
	if ap.has_animation(key) and ap.current_animation != String(key):
		ap.play(key)


static func play_walk(ap: AnimationPlayer, skeleton_style: bool = false) -> void:
	if ap == null:
		return
	var key := WALK_SKELETON if skeleton_style else WALK_HUMAN
	if not ap.has_animation(key) and skeleton_style:
		key = WALK_HUMAN
	if ap.has_animation(key) and ap.current_animation != String(key):
		ap.play(key)


static func update_locomotion(ap: AnimationPlayer, moving: bool, skeleton_style: bool = false) -> void:
	if moving:
		play_walk(ap, skeleton_style)
	else:
		play_idle(ap, skeleton_style)


static func _ensure_libraries() -> void:
	if _ready_libs:
		return
	_lib_general = _library_from_glb(ANIM_GENERAL)
	_lib_move = _library_from_glb(ANIM_MOVE)
	_lib_special = _library_from_glb(ANIM_SPECIAL)
	_ready_libs = true


static func _library_from_glb(path: String) -> AnimationLibrary:
	if not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var root := packed.instantiate()
	var src := _find_animation_player(root)
	if src == null:
		root.free()
		return null
	var lib := AnimationLibrary.new()
	for anim_name in src.get_animation_list():
		var anim := src.get_animation(anim_name).duplicate(true) as Animation
		_apply_loop(anim, String(anim_name))
		lib.add_animation(anim_name, anim)
	root.free()
	return lib


static func _apply_loop(anim: Animation, anim_name: String) -> void:
	if anim_name == "T-Pose" or anim_name.ends_with("_Pose"):
		anim.loop_mode = Animation.LOOP_NONE
		return
	if (
		anim_name.contains("Idle")
		or anim_name.contains("Walking")
		or anim_name.contains("Running")
		or anim_name.contains("Blocking")
		or anim_name == "Melee_2H_Idle"
	):
		anim.loop_mode = Animation.LOOP_LINEAR


static func _find_character_root(node: Node) -> Node3D:
	if node == null:
		return null
	if node.get_node_or_null("Rig_Medium") != null:
		return node as Node3D
	for child in node.get_children():
		var found := _find_character_root(child)
		if found:
			return found
	return null


static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null
