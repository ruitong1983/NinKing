# scripts/shader/glow_fx.gd
# ============================================================
# GlowFX — Sprite 发光特效子系统
# 封装 baked_sprite_glow.gdshader，管理节点的发光材质。
# S5: 新增 emissive 模式（加法发光，覆盖 blink.gdshader）。
# ============================================================
# 调用方式: GlobalShaders.apply_glow(node, params)
#           GlobalShaders.pulse_glow(node, params) → Tween
# ============================================================
class_name GlowFX
extends Node

const GLOW_SHADER_PATH: String = "res://shaders/baked_sprite_glow.gdshader"

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(GLOW_SHADER_PATH) as Shader
	if _shader == null:
		push_error("GlowFX: 无法加载 shader: ", GLOW_SHADER_PATH)


## 为节点应用发光材质。
## params 支持：
##   tint_front, tint_back, alpha_falloff_front, alpha_falloff_back,
##   blend_amount, falloff_max_alpha (传统混合发光)
##   emissive_mode, emissive_color, emissive_frequency, emissive_intensity (S5 加法发光)
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	var mat := ShaderMaterial.new()
	mat.shader = _shader

	# 传统混合发光参数
	mat.set_shader_parameter("tint_front", params.get("tint_front", Color.WHITE))
	mat.set_shader_parameter("tint_back", params.get("tint_back", Color.WHITE))
	mat.set_shader_parameter("alpha_falloff_front", params.get("alpha_falloff_front", 1.0))
	mat.set_shader_parameter("alpha_falloff_back", params.get("alpha_falloff_back", 1.0))
	mat.set_shader_parameter("blend_amount", params.get("blend_amount", 1.0))
	mat.set_shader_parameter("falloff_max_alpha", params.get("falloff_max_alpha", 1.0))

	# S5: emissive 模式参数
	mat.set_shader_parameter("emissive_mode", params.get("emissive_mode", false))
	mat.set_shader_parameter("emissive_color", params.get("emissive_color", Color(1.0, 0.8, 0.2, 1.0)))
	mat.set_shader_parameter("emissive_frequency", params.get("emissive_frequency", 2.0))
	mat.set_shader_parameter("emissive_intensity", params.get("emissive_intensity", 0.5))

	node.material = mat
	_active[node] = mat
	return mat


## 呼吸发光脉冲：在强度/颜色之间循环。
## params 额外支持：duration, min_intensity, max_intensity
## 返回 Tween 可 await。
func pulse(node: CanvasItem, params: Dictionary = {}) -> Tween:
	if not is_instance_valid(node):
		return null

	var mat: ShaderMaterial = _active.get(node) if _active.has(node) else null
	if mat == null or not is_instance_valid(mat):
		mat = apply(node, params)

	var min_val: float = params.get("min_intensity", 0.3)
	var max_val: float = params.get("max_intensity", 1.0)
	var cycle_duration: float = params.get("duration", 0.8)

	# 脉冲 blend_amount (传统模式) 或 emissive_intensity (emissive 模式)
	var prop_name: String = "emissive_intensity" if params.get("emissive_mode", false) else "blend_amount"

	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.set_loops()
	tw.tween_property(mat, "shader_parameter/" + prop_name, max_val, cycle_duration * 0.5)
	tw.tween_property(mat, "shader_parameter/" + prop_name, min_val, cycle_duration * 0.5)
	return tw


## 移除发光材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有发光材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用发光材质。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])
