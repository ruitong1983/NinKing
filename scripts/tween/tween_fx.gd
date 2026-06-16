# scripts/tween/tween_fx.gd
# ============================================================
# TweenFX — 纯静态 Tween 动效工具
# 可独立移植: 单文件拷走即用
# 依赖: 无
# ============================================================
extends Node


# ─── 防冲突基础设施 ───

static var _active_tweens: Dictionary = {}  # StringKey -> Tween（key = "%d_%s" % [node.get_instance_id(), domain]）

## 生成追踪用的复合键。同一 node 的不同 domain 不冲突。
static func _make_key(node: Node, domain: String) -> String:
	return "%d_%s" % [node.get_instance_id(), domain]


## 终止节点上指定 domain 的已追踪补间。在创建新补间前调用，防止属性争夺。
static func _kill_tracked(node: Node, domain: String) -> void:
	var key := _make_key(node, domain)
	if _active_tweens.has(key):
		var old: Tween = _active_tweens[key]
		if is_instance_valid(old) and old.is_valid():
			old.kill()
		_active_tweens.erase(key)


## 追踪补间以便后续 kill。finished 时自动清理。
static func _track(node: Node, tw: Tween, domain: String) -> void:
	var key := _make_key(node, domain)
	_active_tweens[key] = tw
	tw.finished.connect(_on_tracked_finished.bind(key), CONNECT_ONE_SHOT)


static func _on_tracked_finished(key: String) -> void:
	_active_tweens.erase(key)


# ─── 入场 / 退场 ───

static func pop_in(node: Node, duration: float = 0.3, from_scale: Vector2 = Vector2(0.1, 0.1), auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")
	node.scale = from_scale
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, duration)
	if auto_kill:
		_track(node, tw, "scale")
	return tw


static func pop_out(node: Node, duration: float = 0.2, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2(0.01, 0.01), duration)
	tw.tween_callback(node.queue_free)
	if auto_kill:
		_track(node, tw, "scale")
	return tw


# ─── 弹性冲入 ───

## 从当前 scale 弹性过冲到 peak_scale 再回弹到 1.0。pivot_offset 居中，不碰 position。
static func punch_in(node: Node, duration: float = 0.4, peak_scale: float = 1.5, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")
	var ctrl: Control = node as Control if node is Control else null
	var saved_pivot: Vector2 = ctrl.pivot_offset if ctrl else Vector2.ZERO
	if ctrl:
		ctrl.pivot_offset = ctrl.size * 0.5
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(node, "scale", Vector2(peak_scale, peak_scale), duration * 0.6)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.4)
	if ctrl:
		tw.tween_callback(func(): ctrl.pivot_offset = saved_pivot)
	if auto_kill:
		_track(node, tw, "scale")
	return tw


# ─── 淡入 / 淡出 ───

static func fade_in(node: CanvasItem, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "modulate")
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate:a", 1.0, duration)
	if auto_kill:
		_track(node, tw, "modulate")
	return tw


static func fade_out(node: CanvasItem, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "modulate")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	if auto_kill:
		_track(node, tw, "modulate")
	return tw


static func fade_out_then_free(node: CanvasItem, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "modulate")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	tw.tween_callback(node.queue_free)
	if auto_kill:
		_track(node, tw, "modulate")
	return tw


## Toast 通知：淡入 → 停留 → 淡出 → 自动释放
static func toast(node: CanvasItem, hold_duration: float = 1.5, fade_in_dur: float = 0.2, fade_out_dur: float = 0.3, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "modulate")
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate:a", 1.0, fade_in_dur)
	tw.tween_interval(hold_duration)
	tw.tween_property(node, "modulate:a", 0.0, fade_out_dur)
	tw.tween_callback(node.queue_free)
	if auto_kill:
		_track(node, tw, "modulate")
	return tw


# ─── 抖动 / 摇摆 ───

static func shake_node(node: Control, intensity: float = 4.0, duration: float = 0.25, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "position")
	var original_x: float = node.position.x
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.set_loops(maxi(int(duration / 0.05), 1))
	tw.tween_method(
		func(offset: float): node.position.x = original_x + offset,
		intensity, -intensity, duration
	)
	tw.tween_callback(func(): node.position.x = original_x)
	if auto_kill:
		_track(node, tw, "position")
	return tw


static func wobble(node: Node2D, angle_deg: float = 5.0, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "rotation")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "rotation", deg_to_rad(angle_deg), duration * 0.5)
	tw.tween_property(node, "rotation", deg_to_rad(-angle_deg), duration * 0.5)
	tw.tween_property(node, "rotation", 0.0, duration * 0.5)
	if auto_kill:
		_track(node, tw, "rotation")
	return tw


# ─── 脉冲 / 呼吸 ───

static func pulse(node: Node, scale_to: Vector2 = Vector2(1.1, 1.1), duration: float = 0.6, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.set_loops()
	tw.tween_property(node, "scale", scale_to, duration * 0.5)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.5)
	if auto_kill:
		_track(node, tw, "scale")
	return tw


# ─── 一次性缩放弹跳 ───

## pivot_offset 控制缩放原点，不碰 position，不破坏 Container 布局。
static func scale_pop(node: Node, factor: float = 1.2, duration: float = 0.2, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")

	var ctrl: Control = node as Control if node is Control else null
	var saved_pivot: Vector2 = Vector2.ZERO
	if ctrl != null:
		saved_pivot = ctrl.pivot_offset
		var is_right_aligned: bool = node is Label and (node as Label).horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT
		if is_right_aligned:
			ctrl.pivot_offset = Vector2(ctrl.size.x, ctrl.size.y * 0.5)
		else:
			ctrl.pivot_offset = ctrl.size * 0.5

	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2(factor, factor), duration * 0.6)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.4)

	if ctrl != null:
		tw.tween_callback(func(): ctrl.pivot_offset = saved_pivot)

	if auto_kill:
		_track(node, tw, "scale")
	return tw


# ─── 漂浮 ───

static func float_up(node: CanvasItem, offset_y: float = -40.0, duration: float = 0.8, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "float")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.set_parallel(true)
	tw.tween_property(node, "position:y", node.position.y + offset_y, duration)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	tw.set_parallel(false)
	tw.tween_callback(node.queue_free)
	if auto_kill:
		_track(node, tw, "float")
	return tw


# ─── 滑入 / 滑出 ───

enum SlideDir { LEFT, RIGHT, UP, DOWN }

static func slide_in(node: Control, from_dir: SlideDir = SlideDir.UP, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "position")
	var viewport_size: Vector2 = node.get_viewport_rect().size
	var target_pos := node.position
	var start_pos: Vector2
	match from_dir:
		SlideDir.LEFT: start_pos = Vector2(-viewport_size.x, target_pos.y)
		SlideDir.RIGHT: start_pos = Vector2(viewport_size.x, target_pos.y)
		SlideDir.UP: start_pos = Vector2(target_pos.x, -viewport_size.y)
		SlideDir.DOWN: start_pos = Vector2(target_pos.x, viewport_size.y)
	node.position = start_pos
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "position", target_pos, duration)
	if auto_kill:
		_track(node, tw, "position")
	return tw


static func slide_out(node: Control, to_dir: SlideDir = SlideDir.DOWN, duration: float = 0.25, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "position")
	var viewport_size: Vector2 = node.get_viewport_rect().size
	var end_pos: Vector2
	match to_dir:
		SlideDir.LEFT: end_pos = Vector2(-viewport_size.x, node.position.y)
		SlideDir.RIGHT: end_pos = Vector2(viewport_size.x, node.position.y)
		SlideDir.UP: end_pos = Vector2(node.position.x, -viewport_size.y)
		SlideDir.DOWN: end_pos = Vector2(node.position.x, viewport_size.y)
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(node, "position", end_pos, duration)
	tw.tween_callback(node.queue_free)
	if auto_kill:
		_track(node, tw, "position")
	return tw


## 列表逐项错峰入场：淡入 + 从左滑入，每项间隔 stagger 秒
## 注意：此函数不参与 auto_kill（操作数组，按项索引独立创建补间）
static func stagger_slide_in(nodes: Array, stagger: float = 0.12, dur: float = 0.3, slide_offset: float = 30.0) -> void:
	for i in range(nodes.size()):
		var node: CanvasItem = nodes[i]
		if not is_instance_valid(node):
			continue
		node.modulate.a = 0.0
		node.position.x -= slide_offset
		var tw := node.create_tween()
		tw.tween_interval(i * stagger)
		tw.set_parallel(true)
		tw.tween_property(node, "modulate:a", 1.0, dur)
		tw.tween_property(node, "position:x", node.position.x + slide_offset, dur)


## 卡片逐张 scale 0->1 弹入（仿落在纸面上）
## fire-and-forget，不返回 Tween
static func stagger_pop_in(nodes: Array, stagger: float = 0.06, duration: float = 0.25) -> void:
	for i in range(nodes.size()):
		var node: Node = nodes[i]
		if not is_instance_valid(node):
			continue
		node.scale = Vector2.ZERO
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector2.ONE, duration)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)\
			.set_delay(i * stagger)


## 卡牌从中心向弧位散开：卷轴展开效果。
## 单张居中，多张沿圆弧均匀分布（Y 轴压缩模拟透视）。
## 每张牌从中心 stagger 延迟后并行 scale+alpha 弹入归位。
## 注意：此函数不参与 auto_kill（操作数组，按项索引独立创建补间）
static func stagger_spread(nodes: Array[CanvasItem], center_pos: Vector2, radius: float = 400.0, spread_angle_deg: float = 40.0, stagger: float = 0.06, dur: float = 0.3) -> void:
	var n := nodes.size()
	if n == 0:
		return

	# 计算各牌的目标弧位
	var target_positions: Array[Vector2] = []
	if n == 1:
		target_positions.append(center_pos)
	else:
		var angle_span := deg_to_rad(spread_angle_deg)
		var rad_half := radius * 0.5
		for i in range(n):
			var t := float(i) / float(n - 1)  # 0..1
			var angle := -angle_span * 0.5 + angle_span * t
			var x := center_pos.x + sin(angle) * radius
			var y := center_pos.y + cos(angle) * rad_half  # Y 压缩模拟透视
			target_positions.append(Vector2(x, y))

	# 全部归位到中心 → stagger 弹出到目标位
	for i in range(n):
		var node: CanvasItem = nodes[i]
		if not is_instance_valid(node):
			continue
		var target := target_positions[i]
		node.modulate.a = 0.0
		node.scale = Vector2(0.5, 0.5)
		node.position = center_pos
		var tw := node.create_tween()
		tw.tween_interval(i * stagger)
		tw.set_parallel(true)
		tw.tween_property(node, "position", target, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(node, "scale", Vector2.ONE, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(node, "modulate:a", 1.0, dur * 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


# ─── 闪色 ───

static func color_flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.1, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "modulate")
	var original_modulate: Color = node.modulate
	node.modulate = color
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", original_modulate, duration)
	if auto_kill:
		_track(node, tw, "modulate")
	return tw


# ─── 悬浮（card_hover / card_unhover）───

static func card_hover(node: CanvasItem, scale_to: Vector2 = Vector2(1.05, 1.05), offset_y: float = -4.0, duration: float = 0.15, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	var key := _make_key(node, "hover")
	var is_resting := not _active_tweens.has(key)
	if auto_kill:
		_kill_tracked(node, "hover")
	# 仅在节点静止时保存原始值 — 动画中途重入不覆盖，防止 scale 漂移
	if is_resting:
		node.set_meta("_fx_hover_orig_scale", node.scale)
		node.set_meta("_fx_hover_orig_y", node.position.y)
		node.set_meta("_fx_hover_orig_pivot", node.pivot_offset)
		node.set_meta("_fx_hover_had_y", abs(offset_y) > 0.01)
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(node, "scale", scale_to, duration)
	if abs(offset_y) > 0.01:
		tw.tween_property(node, "position:y", node.position.y + offset_y, duration)
	if auto_kill:
		_track(node, tw, "hover")
	return tw


static func card_unhover(node: CanvasItem, original_scale: Vector2 = Vector2.ONE, original_y: float = 0.0, duration: float = 0.15, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "hover")
	# 优先使用 card_hover 保存的原始值（兼容 Container 布局场景）
	var target_scale: Vector2 = node.get_meta("_fx_hover_orig_scale", original_scale)
	var target_y: float = node.get_meta("_fx_hover_orig_y", original_y)
	var had_y_offset: bool = node.has_meta("_fx_hover_had_y")
	var target_pivot: Vector2 = node.get_meta("_fx_hover_orig_pivot", Vector2.ZERO)
	node.pivot_offset = target_pivot
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(true)
	tw.tween_property(node, "scale", target_scale, duration)
	if had_y_offset:
		tw.tween_property(node, "position:y", target_y, duration)
	# 动画完成后再清 meta，防止中途重入时 card_hover 误存中间值
	tw.finished.connect(func():
		node.remove_meta("_fx_hover_orig_scale")
		node.remove_meta("_fx_hover_orig_y")
		node.remove_meta("_fx_hover_orig_pivot")
		node.remove_meta("_fx_hover_had_y")
	, CONNECT_ONE_SHOT)
	if auto_kill:
		_track(node, tw, "hover")
	return tw


# ─── 弧线弹性补间（借鉴 Fake3D demo to_pos() type 4）───

## 弧线弹性补间：前 73% 沿贝塞尔弧线线性运动，后 27% 弹性归位。
## 接受 CanvasItem（兼容 Node2D 和 Control），使用 global_position 计算。
## control_offset: 控制点垂直偏移系数，越大弧线弧度越大。0 = 直线。
## auto_kill: 在 "position" domain 上防冲突（与 slide_in/shake_node 共享）。
static func move_arc(
	node: CanvasItem,
	end_global_pos: Vector2,
	control_offset: float = 0.5,
	duration: float = 0.5,
	auto_kill: bool = true
) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "position")

	var start_pos: Vector2 = node.global_position
	var parent_pos: Vector2 = node.get_parent().global_position if node.get_parent() else Vector2.ZERO
	var final_pos: Vector2 = end_global_pos - parent_pos

	# 计算贝塞尔控制点
	var cps: Array[Vector2] = _calculate_control_points(start_pos, end_global_pos, control_offset)
	var cp1 := cps[0] - parent_pos
	var cp2 := cps[1] - parent_pos

	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_LINEAR)

	# Phase 1: 贝塞尔弧线（73% 时长，LINEAR）
	tw.tween_method(
		_method_bezier.bind(node, start_pos - parent_pos, cp1, cp2, final_pos),
		0.0, 0.73, duration * 0.3
	)
	# Phase 2: 弹性归位（27% 时长，ELASTIC EASE_OUT）
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_method(
		_method_bezier.bind(node, start_pos - parent_pos, cp1, cp2, final_pos),
		0.73, 1.0, duration * 0.7
	)

	if auto_kill:
		_track(node, tw, "position")
	return tw


## 三次贝塞尔曲线计算
static func _bezier_cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	var tt := t * t
	var uu := u * u
	var uuu := uu * u
	var ttt := tt * t
	var p := uuu * p0          # (1-t)^3 * p0
	p += 3.0 * uu * t * p1     # 3*(1-t)^2*t * p1
	p += 3.0 * u * tt * p2     # 3*(1-t)*t^2 * p2
	p += ttt * p3              # t^3 * p3
	return p


## 计算贝塞尔控制点（垂直偏移）
static func _calculate_control_points(start: Vector2, end: Vector2, intensity: float) -> Array[Vector2]:
	var direction := (end - start).normalized()
	var distance := start.distance_to(end)
	var perpendicular := Vector2(-direction.y, direction.x) * intensity
	var c1 := start + direction * (distance * 0.3) + perpendicular * (distance * 0.5)
	var c2 := start + direction * (distance * 0.7) + perpendicular * (distance * 0.3)
	return [c1, c2]


## tween_method 回调：更新节点 position 到贝塞尔曲线上的 t 位置
static func _method_bezier(
	_t: float,
	node: CanvasItem,
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	p3: Vector2
) -> void:
	if not is_instance_valid(node):
		return
	node.position = _bezier_cubic(p0, p1, p2, p3, _t)


# ─── 忍者触发动效（弹起 + 金框 + squash 落回）───

## 忍者触发组合动画：弹起 → 停顿 → squash 落回（Balatro 风格强化打击感）
## Phase 1: scale 1.0→1.35 + y -18px + rotation ±3°（snappy pop）
## Phase 2: 短暂峰值停留 + rotation 反向 wobble
## Phase 3: squash 压缩(0.85) → 弹性归位 1.0
##
## duration: 动画总时长（所有阶段按比例缩放，默认 0.6s，基准 0.55s）
## auto_kill domain: "ninja"（与 scale/position/modulate 隔离）
static func ninja_pop_trigger(node: Node, duration: float = 0.6, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "ninja")

	var ctrl: Control = node as Control if node is Control else null
	var saved_pivot: Vector2 = ctrl.pivot_offset if ctrl else Vector2.ZERO
	if ctrl:
		ctrl.pivot_offset = ctrl.size * 0.5
	var orig_y: float = node.position.y
	var orig_rot: float = node.rotation

	# Scale all phase durations proportionally to match requested total duration.
	# Base total ≈ 0.55s (0.10 + 0.08 + 0.07 + 0.08 + 0.22).
	const BASE_TOTAL: float = 0.55
	var s: float = duration / BASE_TOTAL

	var tw := node.create_tween()

	# Phase 1: snappy bounce up — scale 1.0→1.35, y -18px, rotation wobble ±3° (parallel)
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2(1.35, 1.35), 0.10 * s) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(node, "position:y", -18.0, 0.10 * s) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD).as_relative()
	tw.tween_property(node, "rotation", deg_to_rad(3.0), 0.10 * s) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Phase 2: brief hold at peak → rotation reverse wobble
	tw.set_parallel(false)
	tw.tween_interval(0.08 * s)
	tw.tween_property(node, "rotation", deg_to_rad(-2.0), 0.07 * s) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Phase 3: squash compress → elastic spring back (sequential)
	# 3a: quick squash down
	tw.tween_property(node, "scale", Vector2(0.85, 0.85), 0.08 * s) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	# 3b: elastic spring back to 1.0 + y restore + rotation reset (parallel)
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22 * s) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(node, "position:y", orig_y, 0.22 * s) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "rotation", orig_rot, 0.18 * s) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Cleanup
	tw.tween_callback(func():
		if ctrl and is_instance_valid(ctrl):
			ctrl.pivot_offset = saved_pivot
	)

	if auto_kill:
		_track(node, tw, "ninja")
	return tw


# ─── 溶解消散（独立 API，不替代 pop_out）───

## 溶解消散：需要节点材质已挂载 dissolve2d.gdshader。
## 自动随机化噪声种子，tween dissolve_value 1.0→0.0，完成后 queue_free。
## 不参与 auto_kill（消散过程不打断）。
static func dissolve_out(
	node: CanvasItem,
	duration: float = 1.0,
	burn_border_size: float = 0.2,
	burn_color: Color = Color(1.0, 0.4, 0.1, 1.0)
) -> Tween:
	if not is_instance_valid(node):
		return null

	# 配置燃烧参数
	if node.material is ShaderMaterial:
		var mat: ShaderMaterial = node.material
		mat.set_shader_parameter("burn_border_size", burn_border_size)
		mat.set_shader_parameter("burn_color", burn_color)

		# 随机化噪声种子
		var noise_tex = mat.get_shader_parameter("dissolve_texture")
		if noise_tex is NoiseTexture2D and noise_tex.noise:
			noise_tex.noise.seed = randi()

	# 启用子节点材质继承（保证 FrontFace/BackFace 同时溶解）
	var tex_rects: Array[TextureRect] = []
	for child in node.find_children("*", "TextureRect", false, false):
		if child is TextureRect:
			child.use_parent_material = true
			tex_rects.append(child)

	var tw := node.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node.material, "shader_parameter/dissolve_value", 0.0, duration).from(1.0)
	tw.tween_callback(func():
		# 恢复 use_parent_material
		for tex_rect: TextureRect in tex_rects:
			if is_instance_valid(tex_rect):
				tex_rect.use_parent_material = false
		if is_instance_valid(node):
			node.queue_free()
	)
	return tw


# ─── Shader 参数动效 ───

## Shader 参数单次补间：将 node.material.shader_parameter/<param_name>
## 从当前值补间到 to_value。提供 auto_kill, domain "shader_param|<name>"。
## context_node: 用于 create_tween() 的节点（必须在场景树中）。
## material: 目标 ShaderMaterial（与 context_node 不同，可以是 Resource）。
static func tween_shader_param(
	context_node: Node,
	material: ShaderMaterial,
	param_name: String,
	to_value: Variant,
	duration: float = 0.15,
	auto_kill: bool = true
) -> Tween:
	if not is_instance_valid(context_node) or not is_instance_valid(material):
		return null
	var domain := "shader_param|%s" % param_name
	if auto_kill:
		_kill_tracked(context_node, domain)
	var tw := context_node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(material, "shader_parameter/%s" % param_name, to_value, duration)
	if auto_kill:
		_track(context_node, tw, domain)
	return tw


## Shader 参数脉冲（无限循环）：material.shader_parameter/<param_name>
## 在 min_val ↔ max_val 之间循环往复，EASE_IN_OUT_SINE。
## 适用于呼吸发光等持续性动效。
## context_node: 用于 create_tween() 的节点（必须在场景树中）。
## auto_kill domain: "shader_pulse|<name>"
static func shader_pulse(
	context_node: Node,
	material: ShaderMaterial,
	param_name: String,
	min_val: float,
	max_val: float,
	cycle_duration: float = 0.8,
	auto_kill: bool = true
) -> Tween:
	if not is_instance_valid(context_node) or not is_instance_valid(material):
		return null
	var domain := "shader_pulse|%s" % param_name
	if auto_kill:
		_kill_tracked(context_node, domain)
	var tw := context_node.create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.set_loops()
	tw.tween_property(material, "shader_parameter/%s" % param_name, max_val, cycle_duration * 0.5)
	tw.tween_property(material, "shader_parameter/%s" % param_name, min_val, cycle_duration * 0.5)
	if auto_kill:
		_track(context_node, tw, domain)
	return tw
