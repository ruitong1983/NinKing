# scripts/system/crt_filter.gd
# ============================================================
# CRTFilter — 全屏 CRT 滤镜
# 可独立移植: 单文件拷走 + crt_filter.gdshader 即可
# 依赖: CanvasLayer + ColorRect + ShaderMaterial
# ============================================================
class_name CRTFilter
extends Node

var _canvas_layer: CanvasLayer
var _color_rect: ColorRect
var _material: ShaderMaterial

var enabled: bool:
	get = _get_enabled, set = set_enabled


func _init() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "__CRTLayer__"
	_canvas_layer.layer = 128

	_color_rect = ColorRect.new()
	_color_rect.name = "CRTColorRect"
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	_material = ShaderMaterial.new()
	_material.shader = preload("res://resources/shaders/crt_filter.gdshader")

	_color_rect.material = _material
	_color_rect.visible = false
	_canvas_layer.add_child(_color_rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_cleanup()


func _cleanup() -> void:
	if _color_rect:
		_color_rect.material = null
	if _material:
		_material.shader = null
	_material = null
	if _canvas_layer:
		if _canvas_layer.get_parent():
			_canvas_layer.get_parent().remove_child(_canvas_layer)
		_canvas_layer.queue_free()
	_canvas_layer = null
	_color_rect = null


func attach_to_root() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var root := tree.root
	# 避免重复挂载
	if _canvas_layer.get_parent() == root:
		return
	if root.has_node("__CRTLayer__"):
		return
	root.add_child(_canvas_layer)


# ─── 属性控制 ───

func _get_enabled() -> bool:
	return _color_rect.visible

func set_enabled(value: bool) -> void:
	_color_rect.visible = value


func set_scanline(v: float) -> void:
	_material.set_shader_parameter("scanline_intensity", v)

func set_aberration(v: float) -> void:
	_material.set_shader_parameter("aberration_amount", v)

func set_vignette(v: float) -> void:
	_material.set_shader_parameter("vignette_amount", v)

func set_warp(v: float) -> void:
	_material.set_shader_parameter("warp_amount", v)

func set_brightness(v: float) -> void:
	_material.set_shader_parameter("brightness", v)
