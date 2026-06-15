class_name DebugUiProxy
extends RefCounted
## Adapter that maps Debug scene nodes to AnimationHandler's _ui property access.
##
## Created by DebugController in _ready(), populated with %-node references.
## AnimationHandler._ui is untyped, so this duck-typing proxy works without
## inheriting UIManager.

var score_label: Label
var progress_bar: ProgressBar
var card_grid: HandCardContainer

# — Type labels (影/瞬/滅 head/mid/tail)
var head_type_label: Label
var middle_type_label: Label
var tail_type_label: Label

# — Level labels (shadow/flash/destroy)
var shadow_lv_label: Label
var flash_lv_label: Label
var destroy_lv_label: Label

# — Score labels (left panel rows)
var shadow_score_label: RichTextLabel
var flash_score_label: RichTextLabel
var destroy_score_label: RichTextLabel

# — Column labels (left panel)
var left_col_type: Label
var mid_col_type: Label
var right_col_type: Label
var left_col_score: RichTextLabel
var mid_col_score: RichTextLabel
var right_col_score: RichTextLabel
var left_col_lv: Label
var mid_col_lv: Label
var right_col_lv: Label

# — Column labels (DunArea)
var col0_label: Label
var col1_label: Label
var col2_label: Label

# — Ninja bar (must expose ._container._held_cards)
var ninja_bar: Node

# — Visual containers
var panel_bg: ColorRect
var game_bg: TextureRect

# — Host node for add_child (debug scene root)
var _host: Node


func _init(host: Node) -> void:
	_host = host


func get_tree() -> SceneTree:
	return _host.get_tree()


func get_viewport_rect() -> Rect2:
	return _host.get_viewport_rect()


func add_child(node: Node) -> void:
	if _host:
		_host.add_child(node)


func set_score_formula(value: int, xi_val: int) -> void:
	if score_label:
		if xi_val > 1:
			score_label.text = "%d × %d = %d" % [value, xi_val, value * xi_val]
		else:
			score_label.text = "%d" % value


func update_score(_score: int, _target: int) -> void:
	pass  # Debug scene uses score_label directly


func update_xi_display(_text: String) -> void:
	pass  # Debug scene has %ColXiLabel but managed separately
