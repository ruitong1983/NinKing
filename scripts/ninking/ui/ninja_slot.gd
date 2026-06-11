extends Panel
## Single ability slot in the NinjaBar.
## Displays category icon + ninja name or "空".

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label


func setup(ninja_name: String, icon_path: String = "") -> void:
	label.text = ninja_name
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
		icon_rect.visible = true
	else:
		icon_rect.visible = false
