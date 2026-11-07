extends Object
class_name GameFonts

## Lilita One (OFL): display cheia, legível em PT-BR no HUD.
const PATH := "res://assets/fonts/LilitaOne.ttf"


static func font() -> Font:
	if not ResourceLoader.exists(PATH):
		return null
	return load(PATH) as Font


static func style_label3d(label: Label3D, size: int = 42) -> void:
	var f := font()
	if f != null:
		label.font = f
	label.font_size = size
