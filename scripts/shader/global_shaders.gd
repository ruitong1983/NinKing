# scripts/shader/global_shaders.gd
# ============================================================
# GlobalShaders — 全局 Shader 调度（Autoload: GlobalShaders）
# 依赖: ShaderFX（纯函数库）+ DissolveFX / GlowFX / OutlineFX / EdgeFadeFX
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

# ─── 子系统实例 ───
var edge_fade
var dissolve
var glow
var outline


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
