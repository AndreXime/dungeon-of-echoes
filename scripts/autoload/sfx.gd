extends Node


func play(host: Node, kind: String, pos: Vector3 = Vector3.ZERO) -> void:
	if host == null or not is_instance_valid(host):
		return
	var tree := host.get_tree()
	if tree == null or tree.current_scene == null:
		return
	var use_3d := pos != Vector3.ZERO
	var player: Node = AudioStreamPlayer3D.new() if use_3d else AudioStreamPlayer.new()
	tree.current_scene.add_child(player)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	var n := 1600
	match kind:
		"swing":
			n = 1900
		"hit":
			n = 1400
		"kill":
			n = 2200
		"hurt":
			n = 1600
		"break":
			n = 2600
		"block":
			n = 900
		"shoot":
			n = 1300
	var samples := PackedByteArray()
	samples.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var env := (1.0 - t) * (1.0 - t)
		var freq := 160.0
		var noise := 0.0
		match kind:
			"swing":
				freq = 180.0 + t * 120.0
				noise = randf_range(-12.0, 12.0) * (1.0 - t)
			"hit":
				freq = 70.0 + (1.0 - t) * 40.0
				if t < 0.08:
					noise = randf_range(-40.0, 40.0)
			"kill":
				freq = 95.0 - t * 55.0
				if t < 0.1:
					noise = randf_range(-50.0, 50.0)
			"hurt":
				freq = 110.0 - t * 40.0
				noise = randf_range(-18.0, 18.0) * env
			"break":
				freq = 45.0 + float(i % 55)
				noise = randf_range(-30.0, 30.0) * env
			"block":
				freq = 320.0 - t * 80.0
				if t < 0.12:
					noise = randf_range(-25.0, 25.0)
			"shoot":
				freq = 400.0 - t * 220.0
		var v := int(sin(t * freq * TAU) * env * 78.0 + noise)
		samples[i] = clampi(128 + v, 0, 255)
	stream.data = samples
	if use_3d:
		var p3 := player as AudioStreamPlayer3D
		p3.stream = stream
		p3.global_position = pos
		p3.volume_db = -4.0
		p3.play()
	else:
		var p2 := player as AudioStreamPlayer
		p2.stream = stream
		p2.volume_db = -8.0
		p2.play()
	tree.create_timer(0.55, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.queue_free()
	)
