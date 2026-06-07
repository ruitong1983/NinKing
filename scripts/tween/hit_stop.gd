# scripts/tween/hit_stop.gd
# ============================================================
# HitStop — 顿帧/冻结帧系统
# 可独立移植: 单文件拷走即用
# 依赖: 无（操作 Engine.time_scale）
# ============================================================
class_name HitStop
extends Node


var _pending: int = 0


# ─── API ───

## 基础顿帧: 冻结 duration 秒，之后平滑恢复
func freeze(duration: float = 0.06, time_scale: float = 0.05) -> void:
	Engine.time_scale = time_scale
	_pending += 1
	get_tree().create_timer(duration, true, false, true).timeout.connect(_on_freeze_expire, CONNECT_ONE_SHOT)


func freeze_stackable(duration: float = 0.06, time_scale: float = 0.05) -> void:
	var current_scale: float = Engine.time_scale
	if current_scale > time_scale:
		Engine.time_scale = time_scale
	_pending += 1
	get_tree().create_timer(duration, true, false, true).timeout.connect(_on_stackable_expire.bind(current_scale), CONNECT_ONE_SHOT)


func cancel() -> void:
	Engine.time_scale = 1.0
	_pending = 0


# ─── 内部 ───

func _on_freeze_expire() -> void:
	_pending = maxi(_pending - 1, 0)
	if _pending <= 0:
		_restore_time_scale()


func _on_stackable_expire(_previous_scale: float) -> void:
	_pending = maxi(_pending - 1, 0)
	if _pending <= 0:
		_restore_time_scale()


func _restore_time_scale() -> void:
	# 平滑恢复，避免突兀跳变
	var tw := create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_method(
		func(s: float): Engine.time_scale = s,
		Engine.time_scale, 1.0, 0.05
	)
