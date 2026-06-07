# scripts/tween/card_tilt.gd
# ============================================================
# CardTilt — 卡牌倾斜/物理摊开感
# 可独立移植: 单文件拷走即用
# 依赖: 无（操作 Node2D 通用属性）
# ============================================================
class_name CardTilt
extends Node


# 可调参数
var tilt_strength: float = 0.03
var spread_angle: float = 8.0      # 度
var spread_radius: float = 400.0   # 像素
var lerp_speed: float = 12.0

var _tracked_nodes: Dictionary = {}  # CanvasItem -> bool（启用中）


# ─── 单卡倾斜 ───

func enable_single(node: CanvasItem) -> void:
	if not is_instance_valid(node):
		return
	_tracked_nodes[node] = true
	set_process(true)


func disable(node: CanvasItem) -> void:
	_tracked_nodes.erase(node)
	if _tracked_nodes.is_empty():
		set_process(false)

	# Tween 回正
	if is_instance_valid(node):
		var tw := node.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(node, "rotation", 0.0, 0.25)


func _process(delta: float) -> void:
	var vp := get_viewport()
	var mouse_pos: Vector2 = vp.get_mouse_position() if vp else Vector2.ZERO
	var viewport_size: Vector2 = vp.get_visible_rect().size if vp else Vector2.ONE

	for node in _tracked_nodes.keys():
		if not is_instance_valid(node):
			_tracked_nodes.erase(node)
			continue

		var ci: CanvasItem = node
		var card_center: Vector2 = ci.global_position
		var rel: Vector2 = (mouse_pos - card_center) / viewport_size
		var target_rot: float = rel.x * tilt_strength
		ci.rotation = lerpf(ci.rotation, target_rot, clampf(lerp_speed * delta, 0.0, 1.0))


# ─── 手牌摊开 ───

func apply_spread(nodes: Array, center_pos: Vector2 = Vector2.ZERO) -> void:
	var count := nodes.size()
	if count == 0:
		return

	var total_angle := deg_to_rad(spread_angle)
	var start_angle := -total_angle * 0.5

	for i in range(count):
		var node: CanvasItem = nodes[i]
		if not is_instance_valid(node):
			continue

		# 单张居中，多张扇形
		var t: float = float(i) / maxf(count - 1, 1) if count > 1 else 0.5
		var angle := start_angle + total_angle * t

		var arc_pos := center_pos + Vector2(
			sin(angle) * spread_radius,
			cos(angle) * spread_radius * 0.3  # 压缩 Y 轴，模拟透视
		)

		node.position = arc_pos
		node.rotation = angle * 0.5  # 微微倾斜，不要太大
