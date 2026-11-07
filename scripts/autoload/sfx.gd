extends Node

const SFX_DIR := "res://assets/audio/sfx/"

var _cache: Dictionary = {}


func play(host: Node, kind: String, pos: Vector3 = Vector3.ZERO) -> void:
	if host == null or not is_instance_valid(host):
		return
	var tree := host.get_tree()
	if tree == null or tree.current_scene == null:
		return
	var stream := _get_stream(kind)
	if stream == null:
		return
	var use_3d := pos != Vector3.ZERO
	var player: Node = AudioStreamPlayer3D.new() if use_3d else AudioStreamPlayer.new()
	tree.current_scene.add_child(player)
	var duration := 0.6
	if stream is AudioStreamOggVorbis:
		duration = maxf((stream as AudioStreamOggVorbis).get_length() + 0.05, 0.2)
	if use_3d:
		var p3 := player as AudioStreamPlayer3D
		p3.stream = stream
		p3.global_position = pos
		p3.volume_db = -2.0
		p3.max_distance = 28.0
		p3.play()
	else:
		var p2 := player as AudioStreamPlayer
		p2.stream = stream
		p2.volume_db = -6.0
		p2.play()
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.queue_free()
	)


func _get_stream(kind: String) -> AudioStream:
	if _cache.has(kind):
		return _cache[kind] as AudioStream
	var path := SFX_DIR + kind + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	_cache[kind] = stream
	return stream
