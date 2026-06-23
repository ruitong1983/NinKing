# scripts/shader/chromatic_aberration_fx.gd
# ============================================================
# ChromaticAberrationFX — 色差特效子系统
# 封装 chromatic_aberration.gdshader，管理节点的色差材质生命周期。
# ============================================================
# 调用方式: GlobalShaders.apply_chromatic_aberration(node, params)
#           GlobalShaders.clear_chromatic_aberration(node)
# ============================================================
class_name ChromaticAberrationFX
extends Node

const SHADER_PATH: String = "res://shaders/effects/chromatic_aberration.gdshader"

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(SHADER_PATH) as Shader
	if _shader == null:
		push_error("ChromaticAberrationFX: 无法加载 shader: ", SHADER_PATH)


## 为节点应用色差材质。
## params 支持: intensity, red_amount, green_amount, blue_amount,
##             radial, angle, jitter_speed, jitter_strength, samples
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	var mat := ShaderMaterial.new()
	mat.shader = _shader

	mat.set_shader_parameter("intensity", params.get("intensity", 0.6))
	mat.set_shader_parameter("red_amount", params.get("red_amount", 0.01))
	mat.set_shader_parameter("green_amount", params.get("green_amount", 0.007))
	mat.set_shader_parameter("blue_amount", params.get("blue_amount", 0.013))
	mat.set_shader_parameter("radial", params.get("radial", true))
	mat.set_shader_parameter("angle", params.get("angle", 0.0))
	mat.set_shader_parameter("jitter_speed", params.get("jitter_speed", 0.0))
	mat.set_shader_parameter("jitter_strength", params.get("jitter_strength", 0.0))
	mat.set_shader_parameter("samples", params.get("samples", 2))

	node.material = mat
	_active[node] = mat
	return mat


## 移除节点的色差材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有已追踪的色差材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用色差材质。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])
