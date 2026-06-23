# scripts/shader/global_shaders.gd
# ============================================================
# GlobalShaders — 全局 Shader 调度（Autoload: GlobalShaders）
# 依赖: ShaderFX（纯函数库）+ DissolveFX / GlowFX / OutlineFX / EdgeFadeFX
#       + ChromaticAberrationFX / SplitGlitchFX / PixelExplosionFX / HaloFX
# ============================================================
# 调用规范：外部代码只调 GlobalShaders，不直接调 ShaderFX 或子系统。
# ShaderFX 是纯函数库，GlobalShaders 是唯一对外入口。
# ============================================================
extends Node

const SFX = preload("res://scripts/shader/shader_fx.gd")
const _EdgeFadeFX = preload("res://scripts/shader/edge_fade_fx.gd")
const _DissolveFX = preload("res://scripts/shader/dissolve_fx.gd")
const _GlowFX = preload("res://scripts/shader/glow_fx.gd")
const _OutlineFX = preload("res://scripts/shader/outline_fx.gd")
const _ChromaticAberrationFX = preload("res://scripts/shader/chromatic_aberration_fx.gd")
const _SplitGlitchFX = preload("res://scripts/shader/split_glitch_fx.gd")
const _PixelExplosionFX = preload("res://scripts/shader/pixel_explosion_fx.gd")
const _HaloFX = preload("res://scripts/shader/halo_fx.gd")

# ─── 子系统实例 ───
var edge_fade
var dissolve
var glow
var outline
var chromatic_aberration
var split_glitch
var pixel_explosion
var halo


func _ready() -> void:
	_init_subsystems()


func _init_subsystems() -> void:
	edge_fade = _EdgeFadeFX.new()
	edge_fade.name = "EdgeFadeFX"
	add_child(edge_fade)

	dissolve = _DissolveFX.new()
	dissolve.name = "DissolveFX"
	add_child(dissolve)

	glow = _GlowFX.new()
	glow.name = "GlowFX"
	add_child(glow)

	outline = _OutlineFX.new()
	outline.name = "OutlineFX"
	add_child(outline)

	chromatic_aberration = _ChromaticAberrationFX.new()
	chromatic_aberration.name = "ChromaticAberrationFX"
	add_child(chromatic_aberration)

	split_glitch = _SplitGlitchFX.new()
	split_glitch.name = "SplitGlitchFX"
	add_child(split_glitch)

	pixel_explosion = _PixelExplosionFX.new()
	pixel_explosion.name = "PixelExplosionFX"
	add_child(pixel_explosion)

	halo = _HaloFX.new()
	halo.name = "HaloFX"
	add_child(halo)


# ══════════════════════════════════════════
# 边缘淡出（Edge Fade — 面板水墨边缘）
# ══════════════════════════════════════════

func apply_edge_fade(node: CanvasItem, fade_start: float = 0.64) -> void:
	edge_fade.apply(node, fade_start)

func clear_edge_fade(node: CanvasItem) -> void:
	edge_fade.cleanup(node)

func has_edge_fade(node: CanvasItem) -> bool:
	return edge_fade.is_applied(node)


# ══════════════════════════════════════════
# 溶解消散（Dissolve — 卡牌消散）
# ══════════════════════════════════════════

func apply_dissolve(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return dissolve.apply(node, params)

func dissolve_out(node: CanvasItem, params: Dictionary = {}) -> Tween:
	return dissolve.dissolve_out(node, params)

func clear_dissolve(node: CanvasItem) -> void:
	dissolve.cleanup(node)

func has_dissolve(node: CanvasItem) -> bool:
	return dissolve.is_applied(node)


# ══════════════════════════════════════════
# 发光（Glow — Sprite 辉光）
# ══════════════════════════════════════════

func apply_glow(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return glow.apply(node, params)

func pulse_glow(node: CanvasItem, params: Dictionary = {}) -> Tween:
	return glow.pulse(node, params)

func clear_glow(node: CanvasItem) -> void:
	glow.cleanup(node)

func has_glow(node: CanvasItem) -> bool:
	return glow.is_applied(node)


# ══════════════════════════════════════════
# 描边（Outline — 卡牌选中高亮）
# ══════════════════════════════════════════

func apply_outline(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return outline.apply(node, params)

func clear_outline(node: CanvasItem) -> void:
	outline.cleanup(node)

func has_outline(node: CanvasItem) -> bool:
	return outline.is_applied(node)


# ══════════════════════════════════════════
# 色差（Chromatic Aberration — 故障/受击反馈）
# ══════════════════════════════════════════

func apply_chromatic_aberration(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return chromatic_aberration.apply(node, params)

func clear_chromatic_aberration(node: CanvasItem) -> void:
	chromatic_aberration.cleanup(node)

func has_chromatic_aberration(node: CanvasItem) -> bool:
	return chromatic_aberration.is_applied(node)


# ══════════════════════════════════════════
# 分裂故障（Split Glitch — Boss 战过渡/受击扰动）
# ══════════════════════════════════════════

func apply_split_glitch(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return split_glitch.apply(node, params)

func split_glitch_burst(node: CanvasItem, params: Dictionary = {}) -> Tween:
	return split_glitch.burst(node, params)

func clear_split_glitch(node: CanvasItem) -> void:
	split_glitch.cleanup(node)

func has_split_glitch(node: CanvasItem) -> bool:
	return split_glitch.is_applied(node)


# ══════════════════════════════════════════
# 像素爆炸（Pixel Explosion — 忍者消散/结算爆炸）
# ══════════════════════════════════════════

func apply_pixel_explosion(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return pixel_explosion.apply(node, params)

func pixel_explode(node: CanvasItem, params: Dictionary = {}) -> Tween:
	return pixel_explosion.explode(node, params)

func clear_pixel_explosion(node: CanvasItem) -> void:
	pixel_explosion.cleanup(node)

func has_pixel_explosion(node: CanvasItem) -> bool:
	return pixel_explosion.is_applied(node)


# ══════════════════════════════════════════
# 边框光晕（Halo — 稀有度动态边框）
# ══════════════════════════════════════════

func apply_halo(node: CanvasItem, params: Dictionary = {}) -> ShaderMaterial:
	return halo.apply(node, params)

func clear_halo(node: CanvasItem) -> void:
	halo.cleanup(node)

func has_halo(node: CanvasItem) -> bool:
	return halo.has_halo(node)


# ══════════════════════════════════════════
# 通用 Shader 参数动效（委托 ShaderFX → GlobalTweens）
# ══════════════════════════════════════════

func tween_param(material: ShaderMaterial, param_name: String, to_value: Variant,
		duration: float = 0.15, auto_kill: bool = true) -> Tween:
	return SFX.tween_param(self, material, param_name, to_value, duration, auto_kill)

func pulse_param(material: ShaderMaterial, param_name: String, min_val: float, max_val: float,
		cycle_duration: float = 0.8, auto_kill: bool = true) -> Tween:
	return SFX.pulse_param(self, material, param_name, min_val, max_val, cycle_duration, auto_kill)


# ══════════════════════════════════════════
# 批量清理
# ══════════════════════════════════════════

func remove_all_shaders(node: CanvasItem) -> void:
	edge_fade.cleanup(node)
	dissolve.cleanup(node)
	glow.cleanup(node)
	outline.cleanup(node)
	chromatic_aberration.cleanup(node)
	split_glitch.cleanup(node)
	pixel_explosion.cleanup(node)
	halo.cleanup(node)


# ══════════════════════════════════════════
# Shader 资源管理快捷方法
# ══════════════════════════════════════════

func load_shader(path: String) -> Shader:
	return SFX.load_shader(path)

func create_material(shader: Shader, params: Dictionary = {}) -> ShaderMaterial:
	return SFX.create_material(shader, params)

func create_material_from_path(path: String, params: Dictionary = {}) -> ShaderMaterial:
	return SFX.create_material_from_path(path, params)

func apply_material(node: CanvasItem, mat: ShaderMaterial, duplicate_if_shared: bool = true) -> void:
	SFX.apply_material(node, mat, duplicate_if_shared)

func has_shader(node: CanvasItem) -> bool:
	return SFX.has_shader(node)

func get_material(node: CanvasItem) -> ShaderMaterial:
	return SFX.get_material(node)

func remove_material(node: CanvasItem) -> void:
	SFX.remove_material(node)
