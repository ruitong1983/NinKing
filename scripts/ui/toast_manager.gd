# scripts/ui/toast_manager.gd
# Toast 消息提示 (Autoload)
extends Node

const FX = preload("res://scripts/tween/tween_fx.gd")

func show(msg: String, duration: float = 1.5) -> void:
	# Panel container — dark semi-transparent background for readability
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.20
	panel.anchor_bottom = 0.20
	panel.offset_left = -200.0
	panel.offset_right = 200.0
	panel.offset_top = -28.0
	panel.offset_bottom = 28.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.75)
	sb.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", sb)

	var label := Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	panel.add_child(label)

	get_tree().root.add_child(panel)
	FX.toast(panel, duration)
