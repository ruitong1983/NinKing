# scripts/tween/bounce_score.gd
# ============================================================
# BounceScore — 计分弹性着陆动效（夸张版）
# 打包: 蓄力 → 数字过冲暴涨 → 缩放弹跳 → 进度条延迟 → 列喜预览闪 → 面板发光
# 依赖: TweenFX (color_flash)
# 用法: const BounceScore = preload(...) → BounceScore.play(...)
# ============================================================
extends RefCounted

const FX = preload("res://scripts/tween/tween_fx.gd")

const PREFIX: String = ""
const OVERSCALE: float = 1.6
const UNDERSHOOT: float = 0.82
const OVERSHOOT_RATIO: float = 0.30
const PHASE_WINDUP: float = 0.12
const PHASE_UP: float = 1.00
const PHASE_SETTLE: float = 0.15
const PHASE_RESTORE: float = 0.20
const PROGRESS_DELAY: float = 0.15
const PROGRESS_DUR: float = 0.40
const GLOW_DUR: float = 0.45


static func play(
	score_label: Label,
	progress_bar: ProgressBar,
	col_xi_label: Label,
	panel_bg: ColorRect,
	old_score: int,
	new_score: int,
	barrier_color: Color,
	bounce_sfx: AudioStream = null
) -> void:
	if not is_instance_valid(score_label):
		return

	# ── Zero-change guard ──
	if old_score == new_score:
		score_label.text = PREFIX + str(new_score)
		return

	# ── Decreasing score → simple count (no bounce) ──
	if new_score < old_score:
		_tween_count(score_label, old_score, new_score, 0.35)
		if is_instance_valid(progress_bar):
			_tween_progress(progress_bar, float(new_score), PROGRESS_DUR)
		return

	# ══════════════════════════════════════════
	# Full bounce sequence
	# ══════════════════════════════════════════

	# Center pivot so scale expands in all directions
	score_label.pivot_offset = score_label.size / 2.0

	var peak: int = int(float(new_score) * (1.0 + OVERSHOOT_RATIO))
	if peak <= new_score:
		peak = new_score + max(1, int(float(new_score) * 0.05))

	var tw: Tween = score_label.create_tween()
	tw.set_ignore_time_scale(true)

	# ── Wind-up: flash white + slight shrink (0 → 0.08s) ──
	tw.set_parallel(true)
	_tween_scale(tw, score_label, Vector2.ONE, Vector2(0.92, 0.92), PHASE_WINDUP)\
		.set_ease(Tween.EASE_IN)
	tw.tween_callback(_make_flash_callback(score_label, Color.WHITE, 0.06))
	tw.set_parallel(false)

	# ── Phase A: number + scale LAUNCH (0.08 → 0.66s) ──
	tw.set_parallel(true)
	_tween_count_method(tw, score_label, old_score, peak, PHASE_UP)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween_scale(tw, score_label, Vector2(0.92, 0.92), Vector2(OVERSCALE, OVERSCALE), PHASE_UP)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(false)

	# ── Peak SFX ──
	if bounce_sfx:
		tw.tween_callback(_make_sfx_callback(bounce_sfx))

	# ── Phase B: overshoot CRASH (0.66 → 0.74s) ──
	tw.set_parallel(true)
	_tween_count_method(tw, score_label, peak, new_score, PHASE_SETTLE)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween_scale(tw, score_label, Vector2(OVERSCALE, OVERSCALE), Vector2(UNDERSHOOT, UNDERSHOOT), PHASE_SETTLE)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.set_parallel(false)

	# ── Phase C: scale spring-back (0.74 → 0.86s) ──
	_tween_scale(tw, score_label, Vector2(UNDERSHOOT, UNDERSHOOT), Vector2.ONE, PHASE_RESTORE)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# ── mini delay before landing effects ──
	tw.tween_interval(PROGRESS_DELAY)

	# ── Phase D: landing effects (parallel) ──
	tw.set_parallel(true)
	if is_instance_valid(progress_bar):
		_tween_progress_on(tw, progress_bar, float(new_score), PROGRESS_DUR)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_make_flash_callback(col_xi_label, Color.GOLD, 0.15))
	tw.tween_callback(_make_flash_callback(panel_bg, barrier_color, GLOW_DUR))
	tw.tween_callback(_make_flash_callback(progress_bar, barrier_color.lightened(0.3), GLOW_DUR))


# ══════════════════════════════════════════
# Internal helpers
# ══════════════════════════════════════════

static func _tween_count_method(tw: Tween, label: Label, from_val: int, to_val: int, duration: float):
	return tw.tween_method(
		func(v: int): label.text = PREFIX + str(v),
		from_val, to_val, duration
	)


static func _tween_scale(tw: Tween, node: Node, from_scale: Vector2, to_scale: Vector2, duration: float) -> PropertyTweener:
	node.scale = from_scale
	return tw.tween_property(node, "scale", to_scale, duration)


static func _tween_count(label: Label, from_val: int, to_val: int, duration: float) -> void:
	if not is_instance_valid(label):
		return
	var tw := label.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_method(
		func(v: int): label.text = PREFIX + str(v),
		from_val, to_val, duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


static func _tween_progress(bar: ProgressBar, target: float, duration: float) -> void:
	if not is_instance_valid(bar):
		return
	var tw := bar.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(bar, "value", target, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


static func _tween_progress_on(tw: Tween, bar: ProgressBar, target: float, duration: float) -> PropertyTweener:
	return tw.tween_property(bar, "value", target, duration)


static func _make_flash_callback(node: CanvasItem, color: Color, duration: float) -> Callable:
	return func():
		if is_instance_valid(node):
			FX.color_flash(node, color, duration)


static func _make_sfx_callback(stream: AudioStream) -> Callable:
	return func():
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.finished.connect(player.queue_free)
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			tree.root.add_child(player)
			player.play()
		else:
			player.queue_free()
