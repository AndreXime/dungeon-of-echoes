extends Node


func play(host: Node, kind: String, pos: Vector3 = Vector3.ZERO) -> void:
	if host == null or not is_instance_valid(host):
		return
	var use_3d := pos != Vector3.ZERO
	var player: Node = AudioStreamPlayer3D.new() if use_3d else AudioStreamPlayer.new()
	host.get_tree().current_scene.add_child(player)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	var n := 1600
	match kind:
		"swing":
			n = 1700
		"hit":
			n = 1100
		"break":
			n = 2400
		"block":
			n = 800
		"shoot":
			n = 1300
	var samples := PackedByteArray()
	samples.resize(n)
	for i in n:
		var t := float(i) / float(n)
		var env := 1.0 - t
		var freq := 160.0
		match kind:
			"swing":
				freq = 240.0 + t * 60.0
			"hit":
				freq = 85.0
			"break":
				freq = 50.0 + float(i % 40)
			"block":
				freq = 300.0
			"shoot":
				freq = 380.0 - t * 180.0
		var v := int(sin(t * freq * TAU) * env * 70.0)
		samples[i] = clampi(128 + v, 0, 255)
	stream.data = samples
	if use_3d:
		var p3 := player as AudioStreamPlayer3D
		p3.stream = stream
		p3.global_position = pos
		p3.play()
	else:
		var p2 := player as AudioStreamPlayer
		p2.stream = stream
		p2.volume_db = -10.0
		p2.play()
	host.get_tree().create_timer(0.4).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.queue_free()
	)
