extends Panel
## Single ability slot in the NinjaBar.
## Displays full card illustration + category icon + ninja name.

@onready var card_art: TextureRect = $CardArt
@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label


func setup(ninja_name: String, icon_path: String = "", ninja_id: String = "") -> void:
	label.text = ninja_name

	var has_card_art: bool = false
	if ninja_id != "":
		var card_path: String = AssetRegistry.get_ninja_card_path(ninja_id)
		if ResourceLoader.exists(card_path):
			card_art.texture = load(card_path)
			has_card_art = true

	# Hide category icon when full card art is present — card art is the visual
	icon_rect.visible = not has_card_art and icon_path != "" and ResourceLoader.exists(icon_path)
	if icon_rect.visible:
		icon_rect.texture = load(icon_path)
