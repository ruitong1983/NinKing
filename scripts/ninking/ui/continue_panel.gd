extends Control

## Continue panel for main menu.
## Extracted from main_menu.gd `_build_continue_panel()` for cleaner code.

signal continue_confirmed()
signal dismissed()

@onready var _info: Label = %ContinueInfo
@onready var _go_btn: Button = %GoBtn
@onready var _back_btn: Button = %BackBtn


func _ready() -> void:
	_go_btn.pressed.connect(_on_go_pressed)
	_back_btn.pressed.connect(_on_back_pressed)


## Show the panel with saved run data.
func show_panel(data: Dictionary) -> void:
	var barrier: int = data.get("barrier_num", 1)
	var seal_names: Array[String] = ["修羅", "明王", "夜叉"]
	var seal_idx: int = data.get("seal_idx", 0)
	var seal_name: String = seal_names[seal_idx] if seal_idx < seal_names.size() else "?"
	var gold: int = data.get("gold", 0)
	var ninja_count: int = (data.get("owned_ninjas", []) as Array).size()
	var score: int = data.get("current_score", 0)
	var target: int = data.get("target_score", 0)

	_info.text = "结界 %d · %s封印\n当前忍気: %d / %d\n金币: $%d · 忍者: %d 人" % [
		barrier, seal_name, score, target, gold, ninja_count
	]
	show()


func _on_go_pressed() -> void:
	continue_confirmed.emit()


func _on_back_pressed() -> void:
	dismissed.emit()
