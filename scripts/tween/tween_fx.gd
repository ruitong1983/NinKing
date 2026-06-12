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

## 从当前 scale 弹性过冲到 peak_scale 再回弹到 1.0。不修改起始 scale。
static func punch_in(node: Node, duration: float = 0.4, peak_scale: float = 1.5, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tw.tween_property(node, "scale", Vector2(peak_scale, peak_scale), duration * 0.6)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.4)
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

static func scale_pop(node: Node, factor: float = 1.2, duration: float = 0.2, auto_kill: bool = true) -> Tween:
	if not is_instance_valid(node):
		return null
	if auto_kill:
		_kill_tracked(node, "scale")
	var tw := node.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2(factor, factor), duration * 0.6)
	tw.tween_property(node, "scale", Vector2.ONE, duration * 0.4)
	if auto_kill:
		_track(node, tw, "scale")
	return tw


# ─── 漂浮 ───

static func float_up(node: Node2D, offset_y: float = -40.0, duration: float = 0.8, auto_kill: bool = true) -> Tween:
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
