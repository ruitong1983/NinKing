# scripts/shader/shader_fx.gd
# ============================================================
# ShaderFX — Shader 纯函数库（Autoload: ShaderFX）
# 依赖: GlobalTweens（复用 tween_shader_param / shader_pulse）
# ============================================================
# 调用规范：外部代码只调 GlobalShaders，不直接调 ShaderFX。
# ShaderFX 是纯函数库，GlobalShaders 是唯一对外入口。
# ============================================================
extends Node

const GT = preload("res://scripts/tween/global_tweens.gd")


# ══════════════════════════════════════════
# Shader 资源管理
# ══════════════════════════════════════════

## 加载 .gdshader 资源。若已加载返回缓存实例。
static func load_shader(path: String) -> Shader:
	return load(path) as Shader


## 创建 ShaderMaterial 并设置初始参数。
## params: {param_name: value, ...}
static func create_material(shader: Shader, params: Dictionary = {}) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	for key: String in params:
		mat.set_shader_parameter(key, params[key])
	return mat


## 从 .gdshader 文件路径创建 ShaderMaterial（便捷方法）。
static func create_material_from_path(path: String, params: Dictionary = {}) -> ShaderMaterial:
	var shader: Shader = load_shader(path)
	if shader == null:
		push_warning("ShaderFX: 无法加载 shader: ", path)
		return null
	return create_material(shader, params)


# ══════════════════════════════════════════
# ShaderMaterial 生命周期
# ══════════════════════════════════════════

## 将 ShaderMaterial 应用到节点。
## 若 duplicate_if_shared=true 则 material.duplicate() 确保独享实例。
static func apply_material(node: CanvasItem, mat: ShaderMaterial, duplicate_if_shared: bool = true) -> void:
	if not is_instance_valid(node):
		return
	if duplicate_if_shared:
		node.material = mat.duplicate()
	else:
		node.material = mat


## 移除节点上的 ShaderMaterial（恢复为 null）。
static func remove_material(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		return
	node.material = null


## 检查节点是否已应用 ShaderMaterial。
static func has_shader(node: CanvasItem) -> bool:
	return is_instance_valid(node) and node.material is ShaderMaterial


## 获取节点的 ShaderMaterial（若有）。
static func get_material(node: CanvasItem) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null
	var mat = node.material
	return mat as ShaderMaterial if mat is ShaderMaterial else null


# ══════════════════════════════════════════
# 参数操作
# ══════════════════════════════════════════

## 设置 Shader 参数（安全版，检查 material 是否为 ShaderMaterial）。
static func set_param(mat: ShaderMaterial, name: String, value: Variant) -> void:
	if not is_instance_valid(mat):
		return
	mat.set_shader_parameter(name, value)


## 获取 Shader 参数值。
static func get_param(mat: ShaderMaterial, name: String) -> Variant:
	if not is_instance_valid(mat):
		return null
	return mat.get_shader_parameter(name)


# ══════════════════════════════════════════
# 噪声纹理工具
# ══════════════════════════════════════════

## 创建用于 dissolve 的噪声纹理。
## 若 seed_value < 0，使用随机种子。
static func create_dissolve_noise(seed_value: int = -1) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = 3.0
	noise.fractal_octaves = 3
	noise.seed = randi() if seed_value < 0 else seed_value

	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	return tex


## 随机化 dissolve 噪声种子的助手方法。
## 用于使每次溶解的图案不同。
static func randomize_noise_seed(mat: ShaderMaterial, param_name: String = "dissolve_texture") -> void:
	if not is_instance_valid(mat):
		return
	var noise_tex = mat.get_shader_parameter(param_name)
	if noise_tex is NoiseTexture2D and noise_tex.noise:
		noise_tex.noise.seed = randi()


# ══════════════════════════════════════════
# Shader 参数动效（委托 GlobalTweens）
# ══════════════════════════════════════════

## Shader 参数单次补间：委托给 GlobalTweens.tween_shader_param。
static func tween_param(context_node: Node, material: ShaderMaterial, param_name: String,
		to_value: Variant, duration: float = 0.15, auto_kill: bool = true) -> Tween:
	# 注意: GlobalTweens 是 autoload，可以通过 /root/GlobalTweens 访问
	# 但这里直接调用其方法需要先获取实例
	var gt := Engine.get_main_loop().root.get_node_or_null("/root/GlobalTweens") as GlobalTweens
	if gt == null:
		return null
	return gt.tween_shader_param(context_node, material, param_name, to_value, duration, auto_kill)


## Shader 参数脉冲循环：委托给 GlobalTweens.shader_pulse。
static func pulse_param(context_node: Node, material: ShaderMaterial, param_name: String,
		min_val: float, max_val: float, cycle_duration: float = 0.8, auto_kill: bool = true) -> Tween:
	var gt := Engine.get_main_loop().root.get_node_or_null("/root/GlobalTweens") as GlobalTweens
	if gt == null:
		return null
	return gt.shader_pulse(context_node, material, param_name, min_val, max_val, cycle_duration, auto_kill)
