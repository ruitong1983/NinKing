# scripts/shader/edge_fade_fx.gd
# ============================================================
# EdgeFadeFX — 面板边缘水墨淡出特效子系统
# 封装 panel_edge_fade.gdshader，管理节点的边缘淡出材质。
# ============================================================
# 调用方式: GlobalShaders.apply_edge_fade(node, fade_start)
#           GlobalShaders.clear_edge_fade(node)
# ============================================================
class_name EdgeFadeFX
extends Node

const FADE_SHADER_PATH: String = "res://shaders/panel_edge_fade.gdshader"
const DEFAULT_FADE_START: float = 0.64

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(FADE_SHADER_PATH) as Shader
	if _shader == null:
		push_error("EdgeFadeFX: 无法加载 shader: ", FADE_SHADER_PATH)


## 应用边缘淡出材质到节点。
## fade_start: 淡出起始位置 (0.0-1.0)，值越大透明区域越小。
func apply(node: CanvasItem, fade_start: float = DEFAULT_FADE_START) -> void:
	if not is_instance_valid(node):
		return

	# 如果已有边缘淡出材质，只更新参数
	if _active.has(node) and is_instance_valid(_active[node]):
		var mat: ShaderMaterial = _active[node]
		mat.set_shader_parameter("fade_start", fade_start)
		return

	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("fade_start", fade_start)
	node.material = mat
	_active[node] = mat


## 移除节点的边缘淡出材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有追踪的边缘淡出材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用边缘淡出。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])
