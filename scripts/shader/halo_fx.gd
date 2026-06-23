# scripts/shader/halo_fx.gd
# ============================================================
# HaloFX — 卡牌边框光晕环特效子系统
# 封装 shaders/effects/halo.gdshader，管理节点的光晕材质。
# ============================================================
# 调用方式: GlobalShaders.apply_halo(node, params)
#           GlobalShaders.clear_halo(node)
#           GlobalShaders.has_halo(node)
# ============================================================
# params 支持:
#   color1, color2       — 双色基础 (Color, 默认紫/青)
#   ring_width           — 光环宽度 (0.01-0.5, 默认0.1)
#   glow_spread          — 泛光范围 (0.01-0.2, 默认0.06)
#   rotate_speed         — 旋转速度 (默认0, 由外部 GlobalTweens 驱动)
#   pulse_speed          — 呼吸速度 (默认0)
#   color_speed          — 颜色变化速度 (默认0)
#   brightness           — 亮度 (0-2, 默认1.2)
#   bloom_intensity      — 泛光强度 (0.1-1.0, 默认0.35)
#   highlight_strength   — 高光强度 (0-2, 默认1.2)
#   animate              — 启用内部动画 (bool, 默认true)
#   edge_offset          — 边缘偏移 (默认0.05)
# ============================================================
class_name HaloFX
extends Node

const HALO_SHADER_PATH: String = "res://shaders/effects/halo.gdshader"

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(HALO_SHADER_PATH) as Shader
	if _shader == null:
		push_error("HaloFX: 无法加载 shader: ", HALO_SHADER_PATH)


## 应用边框光晕材质到节点。
## params 接受可选的参数字典覆盖默认值。
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	# 如果已有光晕材质，只更新参数
	if _active.has(node) and is_instance_valid(_active[node]):
		var existing_mat: ShaderMaterial = _active[node]
		_set_params(existing_mat, params)
		return existing_mat

	var new_mat := ShaderMaterial.new()
	new_mat.shader = _shader
	_set_params(new_mat, params)
	node.material = new_mat
	_active[node] = new_mat
	return new_mat


## 移除节点的光晕材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有追踪的光晕材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用光晕。
func has_halo(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])


## 批量设置 shader 参数。
func _set_params(mat: ShaderMaterial, params: Dictionary) -> void:
	if params.has("color1"):
		mat.set_shader_parameter("color1", params.color1)
	if params.has("color2"):
		mat.set_shader_parameter("color2", params.color2)
	if params.has("ring_width"):
		mat.set_shader_parameter("ring_width", params.ring_width)
	if params.has("ring_softness"):
		mat.set_shader_parameter("ring_softness", params.ring_softness)
	if params.has("glow_spread"):
		mat.set_shader_parameter("glow_spread", params.glow_spread)
	if params.has("edge_offset"):
		mat.set_shader_parameter("edge_offset", params.edge_offset)
	if params.has("color_mix_range"):
		mat.set_shader_parameter("color_mix_range", params.color_mix_range)
	if params.has("highlight_color"):
		mat.set_shader_parameter("highlight_color", params.highlight_color)
	if params.has("rotate_speed"):
		mat.set_shader_parameter("rotate_speed", params.rotate_speed)
	if params.has("color_speed"):
		mat.set_shader_parameter("color_speed", params.color_speed)
	if params.has("pulse_speed"):
		mat.set_shader_parameter("pulse_speed", params.pulse_speed)
	if params.has("brightness"):
		mat.set_shader_parameter("brightness", params.brightness)
	if params.has("bloom_intensity"):
		mat.set_shader_parameter("bloom_intensity", params.bloom_intensity)
	if params.has("highlight_strength"):
		mat.set_shader_parameter("highlight_strength", params.highlight_strength)
	if params.has("animate"):
		mat.set_shader_parameter("animate", params.animate)
