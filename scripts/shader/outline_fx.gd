# scripts/shader/outline_fx.gd
# ============================================================
# OutlineFX — 卡牌描边特效子系统
# 封装 outline2D_inner_outer.gdshader，管理节点的描边材质。
# ============================================================
# 调用方式: GlobalShaders.apply_outline(node, params)
#           GlobalShaders.clear_outline(node)
# ============================================================
class_name OutlineFX
extends Node

const OUTLINE_SHADER_PATH: String = "res://shaders/outline2D_inner_outer.gdshader"

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(OUTLINE_SHADER_PATH) as Shader
	if _shader == null:
		push_error("OutlineFX: 无法加载 shader: ", OUTLINE_SHADER_PATH)


## 为节点应用描边材质（内外描边）。
## params 支持：line_color, line_thickness
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	var mat := ShaderMaterial.new()
	mat.shader = _shader

	mat.set_shader_parameter("line_color", params.get("line_color", Color.WHITE))
	mat.set_shader_parameter("line_thickness", params.get("line_thickness", 1.0))

	node.material = mat
	_active[node] = mat
	return mat


## 移除描边材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有描边材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用描边。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])
