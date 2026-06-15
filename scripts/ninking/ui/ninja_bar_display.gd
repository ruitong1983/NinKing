class_name NinjaBarDisplay
extends RefCounted

## Manages the ninja bar — clear, populate, empty slots.
## Used by the debug test scene. Main game uses NinjaBarNode + NinjaBarContainer.
## Instantiates ninja_card.tscn for consistent framed display.

const NINJA_CARD_SCENE = preload("res://scenes/ninking/ninja_card.tscn")

var _ninja_bar: Control


func setup(ninja_bar: Control) -> void:
	_ninja_bar = ninja_bar


func refresh(owned_ninjas: Array, max_slots: int) -> void:
	for child: Node in _ninja_bar.get_children():
		child.queue_free()
	for ninja: Dictionary in owned_ninjas:
		var card := NINJA_CARD_SCENE.instantiate() as NinjaInventoryCard
		card.setup(ninja["name"], ninja)
		_ninja_bar.add_child(card)
	var empty: int = max_slots - owned_ninjas.size()
	for _i: int in range(empty):
		var label := Label.new()
		label.text = "空"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(125, 175)
		_ninja_bar.add_child(label)
