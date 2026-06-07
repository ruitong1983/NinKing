# scripts/tween/count_up.gd
# ============================================================
# CountUp — 数字滚动系统
# 可独立移植: 单文件拷走即用
# 依赖: FX.color_flash（仅 play_gold）
# ============================================================
extends RefCounted

const FX = preload("res://scripts/tween/tween_fx.gd")


# ─── 线性递增 ───

static func play(label: Label, from_value: int, to_value: int, duration: float = 0.5,
		prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	if not is_instance_valid(label):
		return null

	var tw := label.create_tween()
	tw.set_ignore_time_scale(true)  # HitStop 不影响数字滚动
	tw.tween_method(
		func(v: int):
			var new_text := prefix + str(v) + suffix
			if label.text != new_text and per_tick.is_valid():
				per_tick.call()
			label.text = new_text,
		from_value, to_value, duration
	)
	return tw


# ─── 缓出递增（先快后慢）───

static func play_eased(label: Label, from_value: int, to_value: int, duration: float = 0.5,
		prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	if not is_instance_valid(label):
		return null

	var tw := label.create_tween()
	tw.set_ignore_time_scale(true)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(
		func(v: int):
			var new_text := prefix + str(v) + suffix
			if label.text != new_text and per_tick.is_valid():
				per_tick.call()
			label.text = new_text,
		from_value, to_value, duration
	)
	return tw


# ─── 金币计数（带金色闪烁）───

static func play_gold(label: Label, amount: int, duration: float = 0.6,
		prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	if not is_instance_valid(label):
		return null

	var tw := label.create_tween()
	tw.set_ignore_time_scale(true)
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(
		func(v: int):
			var new_text := prefix + str(v) + suffix
			if label.text != new_text and per_tick.is_valid():
				per_tick.call()
			label.text = new_text,
		0, amount, duration
	)
	# 到达目标瞬间金色闪烁
	tw.tween_callback(func():
		if is_instance_valid(label):
			FX.color_flash(label, Color.GOLD, 0.15)
	)
	return tw
