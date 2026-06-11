class_name NinjaBarDisplay
extends RefCounted

## Manages the ninja bar — clear, populate, empty slots.
## Extracted from UIManager.

var _ninja_bar: HBoxContainer

const NINJA_SLOT_SCENE: PackedScene = preload("res://scenes/ninking/ninja_slot.tscn")


func setup(ninja_bar: HBoxContainer) -> void:
	_ninja_bar = ninja_bar


func refresh(owned_ninjas: Array, max_slots: int) -> void:
	for child: Node in _ninja_bar.get_children():
		child.queue_free()
	for ninja: Dictionary in owned_ninjas:
		var icon_path: String = AssetRegistry.get_icon_path(ninja["id"], ninja.get("effect", {}))
		_make_slot(ninja["name"], icon_path)
	var empty: int = max_slots - owned_ninjas.size()
	for _i: int in range(empty):
		_make_slot("空")


func _make_slot(text: String, icon_path: String = "") -> void:
	var slot: Panel = NINJA_SLOT_SCENE.instantiate()
	_ninja_bar.add_child(slot)
	if slot.has_method("setup"):
		slot.setup(text, icon_path)
	else:
		var label: Label = slot.get_node_or_null("Label")
		if label != null:
			label.text = text
