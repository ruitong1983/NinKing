# scripts/tween/particle_pool.gd
# ============================================================
# ParticlePool — 粒子预设池
# 可独立移植: 单文件拷走即用
# 依赖: CPUParticles2D
# ============================================================
class_name ParticlePool
extends Node


var _placeholder_tex: ImageTexture = null
var _shuriken_tex: ImageTexture = null
var _sakura_tex: ImageTexture = null


func _init() -> void:
	_placeholder_tex = _make_radial_texture(Color.WHITE)
	_shuriken_tex = _make_shuriken_texture()
	_sakura_tex = _make_sakura_texture()


# ─── 预设爆发 ───

func burst(position: Vector2, preset: String = "sparkle") -> void:
	var cfg := _get_preset(preset)
	_burst_internal(position, cfg.amount, cfg.lifetime, cfg.color, cfg.spread, cfg.velocity_range, cfg.texture)


func burst_custom(position: Vector2, amount: int, lifetime: float, color: Color,
		texture: Texture2D = null, spread: float = 90.0, velocity_min: float = 40.0, velocity_max: float = 120.0) -> void:
	_burst_internal(position, amount, lifetime, color, spread, Vector2(velocity_min, velocity_max), texture)


# ─── 内部 ───

class PresetConfig:
	var amount: int
	var lifetime: float
	var color: Color
	var spread: float
	var velocity_range: Vector2
	var texture: ImageTexture = null

	func _init(p_amount: int, p_lifetime: float, p_color: Color, p_spread: float, p_vel_range: Vector2, p_texture: ImageTexture = null) -> void:
		amount = p_amount
		lifetime = p_lifetime
		color = p_color
		spread = p_spread
		velocity_range = p_vel_range
		texture = p_texture


func _get_preset(preset: String) -> PresetConfig:
	match preset:
		"dust":
			return PresetConfig.new(6, 0.3, Color(0.7, 0.7, 0.7, 0.8), 30.0, Vector2(20, 60))
		"confetti":
			return PresetConfig.new(18, 0.8, Color.GOLD, 120.0, Vector2(60, 150))
		"shuriken":
			return PresetConfig.new(8, 0.35, Color(0.35, 0.35, 0.4, 0.85), 360.0, Vector2(60, 130), _shuriken_tex)
		"sakura":
			return PresetConfig.new(12, 0.7, Color(0.95, 0.65, 0.75, 0.8), 150.0, Vector2(30, 90), _sakura_tex)
		_:  # sparkle (default)
			return PresetConfig.new(10, 0.4, Color(1.0, 0.843, 0.0, 0.9), 90.0, Vector2(40, 100))


func _burst_internal(pos: Vector2, amount: int, lifetime: float, color: Color,
		spread: float, vel_range: Vector2, tex: Texture2D = null) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

	# 粒子外观
	particles.texture = tex if tex else _placeholder_tex
	particles.modulate = color

	# 发射参数
	particles.spread = spread
	particles.initial_velocity_min = vel_range.x
	particles.initial_velocity_max = vel_range.y
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.damping_min = 2.0
	particles.damping_max = 4.0
	particles.direction = Vector2(0, -1)

	add_child(particles)


# ─── 纹理生成 ───

static func _make_radial_texture(base_color: Color) -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var cx := 3.5
	var cy := 3.5
	var r := 3.0
	for y in range(8):
		for x in range(8):
			var d := Vector2(float(x) - cx, float(y) - cy).length() / r
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(base_color.r, base_color.g, base_color.b, a))
	return ImageTexture.create_from_image(img)


## 手里剑纹理 — 铁灰色 4 尖十字星
static func _make_shuriken_texture() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	# 星型 pattern: 十字 + X 形对角线形成 4 尖
	for y in range(8):
		for x in range(8):
			var fx := float(x) - 3.5
			var fy := float(y) - 3.5
			# 十字骨架：水平 + 垂直
			var cross_dist := minf(absf(fx), absf(fy))
			# 距中心距离
			var center_dist := Vector2(fx, fy).length()
			# 星尖沿对角线方向亮，内部渐暗
			var a: float
			if center_dist < 1.0:
				a = 1.0  # 中心亮
			elif center_dist > 3.5:
				a = 0.0  # 边缘透明
			elif cross_dist < 0.6:
				a = 1.0 - center_dist / 3.5  # 十字臂
			else:
				a = maxf(0.0, 0.3 - center_dist / 5.0)  # 对角方向微亮形成尖
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## 樱花纹理 — 淡粉色 5 瓣柔点
static func _make_sakura_texture() -> ImageTexture:
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	# 柔和的径向渐变 + 微偏心产生花瓣感
	for y in range(8):
		for x in range(8):
			var fx := float(x) - 3.5
			var fy := float(y) - 3.5
			var d := Vector2(fx, fy).length()
			# 柔边径向渐变
			var a := clampf(1.0 - d / 3.5, 0.0, 1.0)
			# 平滑 falloff
			a = a * a * (3.0 - 2.0 * a)  # smoothstep
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)
