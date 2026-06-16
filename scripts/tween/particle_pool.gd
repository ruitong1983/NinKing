# scripts/tween/particle_pool.gd  [V8 updated 2026-06-11]
# ============================================================
# ParticlePool — 粒子预设池
# 可独立移植: 单文件拷走即用
# 依赖: CPUParticles2D
# ============================================================
class_name ParticlePool
extends Node

var _placeholder_tex: ImageTexture = null

# Preloaded manga-style particle textures
var _manga_burst_tex: Texture2D
var _manga_ink_tex: Texture2D
var _shuriken_particle_tex: Texture2D
var _sakura_particle_tex: Texture2D

func _init() -> void:
	_placeholder_tex = _make_radial_texture(Color.WHITE)
	_manga_burst_tex = load("res://assets/images/effects/particle_manga_burst.png")
	_manga_ink_tex = load("res://assets/images/effects/particle_manga_ink.png")
	_shuriken_particle_tex = load("res://assets/images/effects/shuriken_particle.png")
	_sakura_particle_tex = load("res://assets/images/effects/sakura_particle.png")
	

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
		"manga_burst":
			return PresetConfig.new(8, 0.5, Color(1.0, 1.0, 1.0, 0.9), 30.0, Vector2(40, 100), _manga_burst_tex)
		"manga_ink":
			return PresetConfig.new(12, 0.6, Color(0.1, 0.1, 0.1, 0.85), 60.0, Vector2(30, 80), _manga_ink_tex)
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
