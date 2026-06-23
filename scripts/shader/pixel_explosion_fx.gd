# scripts/shader/pixel_explosion_fx.gd
# ============================================================
# PixelExplosionFX — 像素爆炸消散特效子系统
# 封装 pixel_explosion.gdshader，管理节点的像素爆炸材质生命周期。
# ============================================================
# 调用方式: GlobalShaders.apply_pixel_explosion(node, params)
#           GlobalShaders.pixel_explode(node, params) → Tween
# ============================================================
class_name PixelExplosionFX
extends Node

const SHADER_PATH: String = "res://shaders/effects/pixel_explosion.gdshader"

var _shader: Shader
var _active: Dictionary = {}  # node -> ShaderMaterial


func _init() -> void:
	_shader = load(SHADER_PATH) as Shader
	if _shader == null:
		push_error("PixelExplosionFX: 无法加载 shader: ", SHADER_PATH)


## 为节点应用像素爆炸材质。
## params 支持: progress, strength,
##             noise_tex_normal（法线贴图→方向）, noise_tex（噪声→溶解遮罩）
## 若不传噪声纹理，自动创建默认纹理。
func apply(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	if not is_instance_valid(node):
		return null

	var mat := ShaderMaterial.new()
	mat.shader = _shader

	# 噪声纹理
	mat.set_shader_parameter("noise_tex_normal",
		params.get("noise_tex_normal", _create_default_normal_noise()))
	mat.set_shader_parameter("noise_tex",
		params.get("noise_tex", _create_default_dissolve_noise()))

	mat.set_shader_parameter("progress", params.get("progress", -1.0))
	mat.set_shader_parameter("strength", params.get("strength", 1.0))

	node.material = mat
	_active[node] = mat
	return mat


## 播放像素爆炸消散动画，完成后自动清理材质。
## params 额外支持: duration, peak_strength
## 返回 Tween 可 await。
func explode(node: CanvasItem, params: Dictionary = {}) -> Tween:
	if not is_instance_valid(node):
		return null

	var duration: float = params.get("duration", 0.8)
	var peak_strength: float = params.get("peak_strength", 1.0)

	var mat: ShaderMaterial = _active.get(node) if _active.has(node) else null
	if mat == null or not is_instance_valid(mat):
		mat = apply(node, params)

	# 确保 progress 起始在 -1
	mat.set_shader_parameter("progress", -1.0)
	mat.set_shader_parameter("strength", peak_strength)

	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	# progress: -1 → 1（消散过程）
	tw.tween_property(mat, "shader_parameter/progress", 1.0, duration)
	# 完成后清理
	tw.tween_callback(func():
		cleanup(node)
	)
	return tw


## 移除节点的像素爆炸材质。
func cleanup(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		_active.erase(node)
		return
	node.material = null
	_active.erase(node)


## 清除所有已追踪的像素爆炸材质。
func cleanup_all() -> void:
	for node: Variant in _active.keys():
		if is_instance_valid(node):
			node.material = null
	_active.clear()


## 检查节点是否已应用像素爆炸材质。
func is_applied(node: CanvasItem) -> bool:
	return _active.has(node) and is_instance_valid(_active[node])


# ══════════════════════════════════════════
# Internal helpers
# ══════════════════════════════════════════

## 创建默认法线噪声纹理（用于爆炸方向）。
func _create_default_normal_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.5
	noise.seed = randi()

	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 64
	tex.height = 64
	tex.normalize = true
	tex.as_normal_map = true  # 输出为法线贴图
	return tex


## 创建默认溶解噪声纹理（用于爆炸消散遮罩）。
func _create_default_dissolve_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = 3.0
	noise.fractal_octaves = 3
	noise.seed = randi()

	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	return tex
