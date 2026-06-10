class_name NinjaBarDisplay
extends RefCounted

## Manages the ninja ability bar — clear, populate, empty slots.
## Extracted from UIManager.

var _ability_bar: HBoxContainer

const ABILITY_SLOT_SCENE: PackedScene = preload("res://scenes/ninking/ability_slot.tscn")


func setup(ability_bar: HBoxContainer) -> void:
	_ability_bar = ability_bar


func refresh(owned_ninjas: Array, max_slots: int) -> void:
	for child: Node in _ability_bar.get_children():
		child.queue_free()
	for ninja: Dictionary in owned_ninjas:
		_make_slot(ninja["name"])
	var empty: int = max_slots - owned_ninjas.size()
	for _i: int in range(empty):
		_make_slot("空")


func _make_slot(text: String) -> void:
	var slot: Panel = ABILITY_SLOT_SCENE.instantiate()
	var label: Label = slot.get_node_or_null("Label")
	if label != null:
		label.text = text
	_ability_bar.add_child(slot)
