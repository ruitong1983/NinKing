# scripts/tween/count_up.gd
# ============================================================
# CountUp — 数字滚动系统
# 可独立移植: 单文件拷走即用
# 依赖: FX.color_flash（仅 play_gold / play_score）
# ============================================================
extends RefCounted

const FX = preload("res://scripts/tween/tween_fx.gd")


# ─── Per-label 防重入 ───

static var _label_tweens: Dictionary = {}

static func _kill_label_tween(label: Control) -> void:
	var key: int = label.get_instance_id()
	var old: Tween = _label_tweens.get(key)
	if old != null and old.is_valid():
		old.kill()
	_label_tweens.erase(key)

static func _track_label_tween(label: Control, tw: Tween) -> void:
	var key: int = label.get_instance_id()
	_label_tweens[key] = tw
	tw.tween_callback(func(): _label_tweens.erase(key))


# ─── 线性递增 ───

static func play(label: Label, from_value: int, to_value: int, duration: float = 0.5,
		prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	if not is_instance_valid(label):
		return null

	_kill_label_tween(label)
	var tw := label.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_method(
		func(v: int):
			var new_text := prefix + str(v) + suffix
			if label.text != new_text and per_tick.is_valid():
				per_tick.call()
			label.text = new_text,
		from_value, to_value, duration
	)
	_track_label_tween(label, tw)
	return tw


# ─── 缓出递增（先快后慢）───

static func play_eased(label: Label, from_value: int, to_value: int, duration: float = 0.5,
		prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	if not is_instance_valid(label):
		return null

	_kill_label_tween(label)
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
	_track_label_tween(label, tw)
	return tw


# ─── 金币计数（带金色闪烁）───

static func play_gold(label: Label, amount: int, duration: float = 0.6,
		prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	if not is_instance_valid(label):
		return null

	_kill_label_tween(label)
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
	_track_label_tween(label, tw)
	tw.tween_callback(func():
		if is_instance_valid(label):
			FX.color_flash(label, Color.GOLD, 0.15)
	)
	return tw


# ─── 多段数字滚动（通用）───

static func play_multi(label: Control, segments: Array[Dictionary],
		per_tick: Callable = Callable()) -> Tween:
	## segments: [{"value": int, "duration": float, "delay": float?, "ticks": int?, "ease": int?, "trans": int?, "color": String?},
	##            {"text": String}, ...]
	## Value segments with delay start after their delay has elapsed.
	## Tick SFX: milestone-based (ticks per segment, evenly spread along easing curve).
	if not is_instance_valid(label):
		return null
	if segments.is_empty():
		return null

	_kill_label_tween(label)

	var descs: Array[Dictionary] = []
	var max_dur: float = 0.0
	var all_zero: bool = true
	var has_value: bool = false

	for seg: Dictionary in segments:
		if seg.has("text"):
			descs.append({"type": "text", "text": seg["text"]})
		else:
			var val: int = seg.get("value", 0)
			var dur: float = seg.get("duration", 0.5)
			var delay: float = seg.get("delay", 0.0)
			var ticks: int = seg.get("ticks", 8)
			var ease_type: int = seg.get("ease", Tween.EASE_OUT)
			var trans_type: int = seg.get("trans", Tween.TRANS_CUBIC)
			var curve: float = _ease_curve(ease_type, trans_type)
			var d: Dictionary = {
				"type": "value", "val": val, "dur": dur, "curve": curve,
				"delay": delay, "ticks": ticks,
			}
			if seg.has("color"):
				d["color"] = seg["color"]
			descs.append(d)
			var seg_end: float = delay + dur
			if seg_end > max_dur:
				max_dur = seg_end
			if val > 0:
				all_zero = false
			has_value = true

	if max_dur <= 0.0 or all_zero:
		_multi_render(label, descs, max_dur, _safe_tick(per_tick, has_value), {})
		return null

	var tw: Tween = label.create_tween()
	tw.set_ignore_time_scale(true)

	var tracker: Dictionary = {}
	var safe_tick: Callable = _safe_tick(per_tick, has_value)
	tw.tween_method(
		func(t: float): _multi_render(label, descs, t, safe_tick, tracker),
		0.0, max_dur, max_dur
	)

	_track_label_tween(label, tw)
	return tw


# ─── 计分行快捷包装 ───

static func play_score(label: Control, chips: int, mult: int, result: int,
		_duration_unused: float = 0.5, per_tick: Callable = Callable()) -> Tween:
	## Value-driven sequential count-up: chips → mult → result.
	## 7 tiers keyed by result: 20/100/200/400/800/1600.
	## _duration_unused kept for signature compatibility.

	label.bbcode_enabled = true
	const CHIPS_COLOR := "#588CF2"
	const MULT_COLOR := "#E04040"

	var t: Dictionary = _score_tier(result)
	var chips_ticks: int = t["c_ticks"]
	var mult_ticks: int = t["m_ticks"]
	var result_ticks: int = t["r_ticks"]
	var dt: float = t["dt"]

	var chips_dur: float = maxf(0.40, chips_ticks * dt)
	var mult_dur: float = maxf(0.28, mult_ticks * dt)
	var result_dur: float = maxf(0.40, result_ticks * dt)

	# Sequential timing with widening gaps for higher tiers
	var gap1: float = 0.05 + t.get("gap_bonus", 0.0)
	var gap2: float = 0.06 + t.get("gap_bonus", 0.0) * 1.2
	var mult_delay: float = chips_dur + gap1
	var result_delay: float = mult_delay + mult_dur + gap2

	var tw: Tween = play_multi(label, [
		{"value": chips,  "duration": chips_dur,  "delay": 0.0,           "ticks": chips_ticks,  "ease": Tween.EASE_OUT, "trans": Tween.TRANS_CUBIC, "color": CHIPS_COLOR},
		{"text": " × "},
		{"value": mult,   "duration": mult_dur,   "delay": mult_delay,    "ticks": mult_ticks,   "ease": Tween.EASE_OUT, "trans": Tween.TRANS_CUBIC, "color": MULT_COLOR},
		{"text": " = "},
		{"value": result, "duration": result_dur, "delay": result_delay,  "ticks": result_ticks, "ease": Tween.EASE_OUT, "trans": Tween.TRANS_CUBIC},
	], per_tick)
	if tw != null:
		tw.tween_callback(func():
			if is_instance_valid(label):
				FX.color_flash(label, Color.GOLD, 0.15)
		)
	return tw


static func _score_tier(result: int) -> Dictionary:
	var thresholds: Array[int] = [20, 100, 200, 400, 800, 1600]
	var tier: int = 0
	for th: int in thresholds:
		if result >= th:
			tier += 1

	# {c_ticks, m_ticks, r_ticks, dt (dur_per_tick), gap_bonus}
	var table: Array[Dictionary] = [
		{"c_ticks": 3,  "m_ticks": 2,  "r_ticks": 3,  "dt": 0.16, "gap_bonus": 0.00},  # <20   → ~1.4s
		{"c_ticks": 4,  "m_ticks": 3,  "r_ticks": 4,  "dt": 0.15, "gap_bonus": 0.01},  # 20-99 → ~1.8s
		{"c_ticks": 6,  "m_ticks": 4,  "r_ticks": 6,  "dt": 0.17, "gap_bonus": 0.03},  # 100-199 → ~2.9s
		{"c_ticks": 7,  "m_ticks": 5,  "r_ticks": 8,  "dt": 0.16, "gap_bonus": 0.04},  # 200-399 → ~3.4s
		{"c_ticks": 9,  "m_ticks": 6,  "r_ticks": 10, "dt": 0.17, "gap_bonus": 0.06},  # 400-799 → ~4.5s
		{"c_ticks": 10, "m_ticks": 7,  "r_ticks": 12, "dt": 0.18, "gap_bonus": 0.08},  # 800-1599 → ~5.5s
		{"c_ticks": 11, "m_ticks": 8,  "r_ticks": 14, "dt": 0.19, "gap_bonus": 0.10},  # 1600+ → ~6.6s
	]
	return table[tier]


# ─── 内部辅助 ───

static func _safe_tick(per_tick: Callable, has_value: bool) -> Callable:
	if has_value:
		return per_tick
	return Callable()


static func _ease_curve(ease_type: int, trans_type: int) -> float:
	## Map Godot Tween.EASE_*/TRANS_* to ease() curve parameter.
	if ease_type == Tween.EASE_OUT and trans_type == Tween.TRANS_CUBIC:
		return 2.0
	elif ease_type == Tween.EASE_OUT and trans_type == Tween.TRANS_QUAD:
		return 1.0
	elif ease_type == Tween.EASE_OUT and trans_type == Tween.TRANS_LINEAR:
		return 0.0
	elif ease_type == Tween.EASE_IN:
		return -1.0
	return 2.0


static func _color_wrap(text: String, color: String) -> String:
	if color.is_empty():
		return text
	return "[color=%s]%s[/color]" % [color, text]


static func _multi_render(label: Control, descs: Array[Dictionary], elapsed: float,
		per_tick: Callable, tracker: Dictionary) -> void:
	if not is_instance_valid(label):
		return

	# One-time init: milestone tracker + global pitch
	if not tracker.has("milestones"):
		tracker["milestones"] = {}
		tracker["tick_pitch"] = 0.88

	var milestones: Dictionary = tracker["milestones"]
	var parts: Array[String] = []
	var tick_triggered: bool = false

	for seg_idx: int in range(descs.size()):
		var desc: Dictionary = descs[seg_idx]
		if desc["type"] == "text":
			parts.append(desc["text"])
		else:
			var val: int = desc["val"]
			var dur: float = desc["dur"]
			var delay: float = desc.get("delay", 0.0)
			var ticks: int = desc.get("ticks", 8)

			var seg_elapsed: float = maxf(0.0, elapsed - delay)
			var seg_color: String = desc.get("color", "")

			if seg_elapsed <= 0.0 or dur <= 0.0 or val <= 0:
				parts.append(_color_wrap("0", seg_color))
				continue

			var t: float = clampf(seg_elapsed / dur, 0.0, 1.0)
			var curve: float = desc["curve"]
			var eased: float = ease(t, curve)
			var current: int = int(round(eased * val))
			parts.append(_color_wrap(str(current), seg_color))

			# Milestone-based tick: evenly spaced along easing curve
			var milestone: int = int(floor(eased * ticks))
			var last_ms: int = milestones.get(seg_idx, -1)
			if milestone > last_ms and milestone < ticks:
				tick_triggered = true
				milestones[seg_idx] = milestone

	var new_text: String = "".join(parts)
	if label.text != new_text:
		label.text = new_text

	if tick_triggered and per_tick.is_valid():
		var pitch: float = tracker["tick_pitch"]
		per_tick.call(pitch)
		tracker["tick_pitch"] = minf(pitch + 0.05, 1.22)
