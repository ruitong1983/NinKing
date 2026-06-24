# scripts/tween/particle_pool.gd  [V9 updated 2026-06-23]
# ============================================================
# ParticlePool — 粒子预设池
# 可独立移植: 单文件拷走即用
# 依赖: CPUParticles2D
# ============================================================
class_name ParticlePool
extends Node

var _placeholder_tex: ImageTexture = null
var _particle_canvas: CanvasLayer  ## 画布层 — 确保所有粒子渲染在 UI 之上

# ⚠️ Deprecated manga-style textures (少年漫画遗留, 将在后续版本移除)
var _manga_burst_tex: Texture2D
var _manga_ink_tex: Texture2D

# Existing particle textures
var _shuriken_particle_tex: Texture2D
var _sakura_particle_tex: Texture2D

# 🆕 Healing-style textures (治愈漫画, 程序化生成)
var _heal_glow_tex: Texture2D
var _heal_petal_tex: Texture2D
var _heal_float_tex: Texture2D
var _heal_sparkle_tex: Texture2D

func _ready() -> void:
	# 创建专用 CanvasLayer，确保粒子渲染在所有 UI 之上
	_particle_canvas = CanvasLayer.new()
	_particle_canvas.layer = 1
	_particle_canvas.name = "ParticleCanvas"
	add_child(_particle_canvas)


func _init() -> void:
	_placeholder_tex = _make_radial_texture(Color.WHITE)
	_manga_burst_tex = load("res://assets/images/effects/particle_manga_burst.png")
	_manga_ink_tex = load("res://assets/images/effects/particle_manga_ink.png")
	_shuriken_particle_tex = load("res://assets/images/effects/shuriken_particle.png")
	_sakura_particle_tex = load("res://assets/images/effects/sakura_particle.png")
	# 治愈系粒子纹理 — 全部程序化生成，无需外部PNG
	_heal_glow_tex = _make_radial_texture(Color(1.0, 0.95, 0.8))  # 暖色柔光
	_heal_petal_tex = _make_petal_texture()
	_heal_float_tex = _make_soft_dot_texture()
	_heal_sparkle_tex = _make_sparkle_texture()


# ─── 预设爆发 ───

func burst(position: Vector2, preset: String = "sparkle") -> void:
	var cfg := _get_preset(preset)
	_burst_internal(position, cfg.amount, cfg.lifetime, cfg.color, cfg.spread, cfg.velocity_range, cfg.texture)

func burst_custom(position: Vector2, amount: int, lifetime: float, color: Color,
		texture: Texture2D = null, spread: float = 90.0, velocity_min: float = 40.0, velocity_max: float = 120.0) -> void:
	_burst_internal(position, amount, lifetime, color, spread, Vector2(velocity_min, velocity_max), texture)


# ─── 预设定义 ───

class PresetConfig:
	var amount: int
	var lifetime: float
	var color: Color
	var spread: float
	var velocity_range: Vector2
	var texture: Texture2D = null

	func _init(p_amount: int, p_lifetime: float, p_color: Color, p_spread: float, p_vel_range: Vector2, p_texture: Texture2D = null) -> void:
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
			return PresetConfig.new(8, 0.35, Color(0.35, 0.35, 0.4, 0.85), 360.0, Vector2(60, 130), _shuriken_particle_tex)
		"sakura":
			return PresetConfig.new(12, 0.7, Color(0.95, 0.65, 0.75, 0.8), 150.0, Vector2(30, 90), _sakura_particle_tex)
		# ⚠️ Deprecated: 少年漫画遗留, 将在后续版本移除。替换为 heal_* 系列
		"manga_burst":
			return PresetConfig.new(8, 0.5, Color(1.0, 1.0, 1.0, 0.9), 30.0, Vector2(40, 100), _manga_burst_tex)
		"manga_ink":
			return PresetConfig.new(12, 0.6, Color(0.1, 0.1, 0.1, 0.85), 60.0, Vector2(30, 80), _manga_ink_tex)
		# 🆕 治愈系粒子预设 — heal_* 系列
		"heal_glow":
			# 暖色柔光绽放 — 适合情绪节点（Boss揭晓/封印达成/喜触发）
			return PresetConfig.new(8, 0.7, Color(1.0, 0.9, 0.6, 0.75), 60.0, Vector2(20, 60), _heal_glow_tex)
		"heal_petal":
			# 花瓣飘落 — 轻柔弧线, 适合过关/转场
			return PresetConfig.new(6, 1.5, Color(1.0, 0.7, 0.8, 0.6), 360.0, Vector2(15, 35), _heal_petal_tex)
		"heal_float":
			# 暖光点上浮 — 持续氛围, 适合商店/待机
			return PresetConfig.new(10, 2.0, Color(1.0, 0.95, 0.7, 0.5), 360.0, Vector2(10, 25), _heal_float_tex)
		"heal_sparkle":
			# 温和闪光 — 短暂闪烁, 适合按钮反馈/获得道具
			return PresetConfig.new(8, 0.45, Color(1.0, 0.95, 0.5, 0.85), 120.0, Vector2(30, 70), _heal_sparkle_tex)
		_:  # sparkle (default)
			return PresetConfig.new(10, 0.4, Color(1.0, 0.843, 0.0, 0.9), 90.0, Vector2(40, 100))


# ─── 内部爆发逻辑 ───

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
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 2.0
	particles.damping_min = 2.0
	particles.damping_max = 4.0
	particles.direction = Vector2(0, -1)

	if _particle_canvas:
		_particle_canvas.add_child(particles)
	else:
		add_child(particles)


# ─── 程序化纹理生成 ───

## 圆形径向渐变纹理（暖色柔光用）
static func _make_radial_texture(base_color: Color) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var cx := 7.5
	var cy := 7.5
	var r := 7.0
	for y in range(16):
		for x in range(16):
			var d := Vector2(float(x) - cx, float(y) - cy).length() / r
			var a := clampf(1.0 - d * d, 0.0, 1.0)  # quadratic falloff for softer edge
			img.set_pixel(x, y, Color(base_color.r, base_color.g, base_color.b, a))
	return ImageTexture.create_from_image(img)

## 花瓣形纹理（heal_petal）
static func _make_petal_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var cx := 8.0
	var cy := 10.0
	for y in range(16):
		for x in range(16):
			var dx := float(x) - cx
			var dy := float(y) - cy
			# 花瓣形状: 顶部尖 + 底部圆 + 左右对称
			var _dist := sqrt(dx * dx + dy * dy)
			var angle := atan2(dy, dx)
			var petal_r := 6.0 + sin(angle * 2.0) * 2.0  # 花瓣曲线
			var a := clampf(1.0 - _dist / petal_r, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)

## 柔和光点纹理（heal_float）
static func _make_soft_dot_texture() -> ImageTexture:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var cx := 5.5
	var cy := 5.5
	var r := 5.0
	for y in range(12):
		for x in range(12):
			var d := Vector2(float(x) - cx, float(y) - cy).length() / r
			var a := clampf(1.0 - d * d * d, 0.0, 1.0)  # very soft falloff
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)

## 星形闪烁纹理（heal_sparkle）
static func _make_sparkle_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var cx := 7.5
	var cy := 7.5
	for y in range(16):
		for x in range(16):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var _dist := sqrt(dx * dx + dy * dy)
			# 四角星: |x|+|y| 菱形 + 十字扩展
			var star_d: float = (abs(dx) + abs(dy)) / 6.0
			var cross_d: float = (max(abs(dx), abs(dy))) / 5.0
			var blend: float = min(star_d, cross_d)
			var a := clampf(1.0 - blend, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)
