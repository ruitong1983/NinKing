# scripts/shader/dissolve_fx.gd
# ============================================================
# DissolveFX — 溶解/消散特效子系统
# 封装 dissolve2d.gdshader，管理节点的溶解材质生命周期。
# ============================================================
# 调用方式: GlobalShaders.apply_dissolve(node, params)
#           GlobalShaders.dissolve_out(node, params) → Tween
# ============================================================
class_name DissolveFX
extends Node

const DISSOLVE_SHADER_PATH: String = "res://shaders/fake3d/dissolve2d.gdshader"
const DISSOLVE_NOISE_PATH: String = "res://resources/materials/dissolve_noise.tres"

var _shader: Shader
var _noise_tex: NoiseTexture2D
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(DISSOLVE_SHADER_PATH) as Shader
	if _shader == null:
		push_error("DissolveFX: 无法加载 shader: ", DISSOLVE_SHADER_PATH)
	_noise_tex = load(DISSOLVE_NOISE_PATH) as NoiseTexture2D


## 为节点应用溶解材质。
## params 支持：burn_color, burn_border_size, dissolve_value
## 返回创建的 ShaderMaterial（可用于后续参数补间）。
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	var mat := ShaderMaterial.new()
	mat.shader = _shader

	# 噪声纹理
	if _noise_tex:
		mat.set_shader_parameter("dissolve_texture", _noise_tex)

	# 参数
	mat.set_shader_parameter("dissolve_value", params.get("dissolve_value", 1.0))
	mat.set_shader_parameter("burn_border_size", params.get("burn_border_size", 0.2))
	mat.set_shader_parameter("burn_color", params.get("burn_color", Color(1.0, 0.4, 0.1, 1.0)))

	node.material = mat

	# 启用子节点材质继承（保证 FrontFace/BackFace 同时溶解）
	_enable_child_materials(node)

	_active[node] = mat
	return mat


## 应用溶解材质并播放溶解动画，完成后 queue_free。
## params 额外支持：duration, auto_kill
## 返回 Tween 可 await。
func dissolve_out(node: CanvasItem, params: Dictionary = {}) -> Tween:
	if not is_instance_valid(node):
		return null

	var duration: float = params.get("duration", 1.0)
	var burn_border_size: float = params.get("burn_border_size", 0.2)
	var burn_color: Color = params.get("burn_color", Color(1.0, 0.4, 0.1, 1.0))

	# 如果节点还没有溶解材质，创建一个
	var mat: ShaderMaterial = _active.get(node) if _active.has(node) else null
	if mat == null or not is_instance_valid(mat):
		mat = apply(node, {
			"burn_border_size": burn_border_size,
			"burn_color": burn_color,
			"dissolve_value": 1.0,
		})

	# 随机化噪声种子
	_randomize_noise_seed(mat)

	var children: Array[TextureRect] = []
	for child in node.find_children("*", "TextureRect", false, false):
		if child is TextureRect:
			child.use_parent_material = true
			children.append(child)

	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "shader_parameter/dissolve_value", 0.0, duration).from(1.0)
	tw.tween_callback(func():
		# 恢复子节点材质继承
		for tex_rect: TextureRect in children:
			if is_instance_valid(tex_rect):
				tex_rect.use_parent_material = false
		# 清理追踪
		_active.erase(node)
		if is_instance_valid(node):
			node.queue_free()
	)
	return tw


## 移除节点的溶解材质，恢复默认渲染。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)
	_disable_child_materials(node)


## 清除所有已追踪的溶解材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用溶解材质。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])


# ══════════════════════════════════════════
# Internal helpers
# ══════════════════════════════════════════

func _enable_child_materials(node: CanvasItem) -> void:
	for child in node.find_children("*", "CanvasItem", false, false):
		if child is CanvasItem:
			child.use_parent_material = true


func _disable_child_materials(node: CanvasItem) -> void:
	for child in node.find_children("*", "CanvasItem", false, false):
		if child is CanvasItem:
			child.use_parent_material = false


func _randomize_noise_seed(mat: ShaderMaterial) -> void:
	var noise_tex = mat.get_shader_parameter("dissolve_texture")
	if noise_tex is NoiseTexture2D and noise_tex.noise:
		noise_tex.noise.seed = randi()
