# scripts/ui/toast_manager.gd
# Toast 消息提示 (Autoload)
extends Node

const FX = preload("res://scripts/tween/tween_fx.gd")

func show(msg: String, duration: float = 1.5) -> void:
	var label := Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_top = 0.85
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))

	get_tree().root.add_child(label)
	FX.toast(label, duration)
