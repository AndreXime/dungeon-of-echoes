extends RefCounted
class_name PixelMaterial

## Material flat com textura procedural nearest-neighbor (look pixelado).


static func enable_vertex_colors(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				if mat is StandardMaterial3D:
					var sm := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					sm.vertex_color_use_as_albedo = true
					sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					mi.set_surface_override_material(s, sm)
	for child in node.get_children():
		enable_vertex_colors(child)


static func make(color: Color, pixel_size: int = 8) -> StandardMaterial3D:
	var img := Image.create(pixel_size, pixel_size, false, Image.FORMAT_RGBA8)
	for y in pixel_size:
		for x in pixel_size:
			var shade := 1.0
			if (x + y) % 2 == 0:
				shade = 0.92
			if x == 0 or y == 0 or x == pixel_size - 1 or y == pixel_size - 1:
				shade = 0.75
			img.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, 1.0))
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 1.0
	return mat
