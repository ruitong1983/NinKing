# scripts/shader/split_glitch_fx.gd
# ============================================================
# SplitGlitchFX — 分裂故障特效子系统
# 封装 split_glitch.gdshader，管理节点的故障扰动材质生命周期。
# ============================================================
# 调用方式: GlobalShaders.apply_split_glitch(node, params)
#           GlobalShaders.clear_split_glitch(node)
#           GlobalShaders.split_glitch_burst(node, params) → Tween
# ============================================================
class_name SplitGlitchFX
extends Node

const SHADER_PATH: String = "res://shaders/effects/split_glitch.gdshader"

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(SHADER_PATH) as Shader
	if _shader == null:
		push_error("SplitGlitchFX: 无法加载 shader: ", SHADER_PATH)


## 为节点应用故障扰动材质。
## params 支持: distort_strength, grid_size_base, grid_size_max_add,
##             time_cycle, wave_frequency, random_iterations,
##             rand_coeff1, rand_coeff2, clamp_uv
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	var mat := ShaderMaterial.new()
	mat.shader = _shader

	mat.set_shader_parameter("distort_strength", params.get("distort_strength", 0.1))
	mat.set_shader_parameter("grid_size_base", params.get("grid_size_base", 10))
	mat.set_shader_parameter("grid_size_max_add", params.get("grid_size_max_add", 50))
	mat.set_shader_parameter("time_cycle", params.get("time_cycle", 5.0))
	mat.set_shader_parameter("wave_frequency", params.get("wave_frequency", 25.0))
	mat.set_shader_parameter("random_iterations", params.get("random_iterations", 8))
	mat.set_shader_parameter("rand_coeff1", params.get("rand_coeff1", -38.0))
	mat.set_shader_parameter("rand_coeff2", params.get("rand_coeff2", 0.2))
	mat.set_shader_parameter("clamp_uv", params.get("clamp_uv", true))

	node.material = mat
	_active[node] = mat
	return mat


## 执行一次故障爆发动画：distort_strength 从 0 → peak → 0。
## params 额外支持: duration（总时长，默认 1.0）, peak（最大强度，默认 0.8）
## 返回 Tween 可 await。
func burst(node: CanvasItem, params: Dictionary = {}) -> Tween:
	if not is_instance_valid(node):
		return null

	var duration: float = params.get("duration", 1.0)
	var peak: float = params.get("peak", 0.8)

	var mat: ShaderMaterial = _active.get(node) if _active.has(node) else null
	if mat == null or not is_instance_valid(mat):
		mat = apply(node, params)

	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "shader_parameter/distort_strength", peak, duration * 0.4)
	tw.tween_property(mat, "shader_parameter/distort_strength", 0.0, duration * 0.6)
	return tw


## 移除节点的故障材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有已追踪的故障材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用故障材质。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])
