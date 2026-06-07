# scripts/tween/screen_shake.gd
# ============================================================
# ScreenShake — Camera2D 震动系统
# 可独立移植: ScreenShake.new(get_viewport()) 即用
# 依赖: Camera2D
# ============================================================
class_name ScreenShake
extends Node


# 可调参数
var max_offset: Vector2 = Vector2(20, 15)
var max_rotation: float = 2.0


# 一次性触发
func trigger(intensity: float, duration: float) -> void:
	var cam := _get_camera()
	if not cam:
		return

	var orig_pos: Vector2 = cam.position
	var orig_rot: float = cam.rotation

	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_method(
		func(t: float):
			var off_x := randf_range(-1.0, 1.0) * max_offset.x * t
			var off_y := randf_range(-1.0, 1.0) * max_offset.y * t
			var rot := randf_range(-1.0, 1.0) * deg_to_rad(max_rotation) * t
			cam.position = orig_pos + Vector2(off_x, off_y)
			cam.rotation = orig_rot + rot,
		intensity, 0.0, duration
	)
	tw.tween_callback(func():
		cam.position = orig_pos
		cam.rotation = orig_rot
	)


# ─── 创伤累积模式 ───

var _trauma: float = 0.0
var _decay_rate: float = 2.5

func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)
	if not is_inside_tree() and _trauma > 0.0:
		return
	set_process(true)


func _process(delta: float) -> void:
	_trauma = maxf(_trauma - _decay_rate * delta, 0.0)
	var cam := _get_camera()
	if not cam:
		return

	var shake: float = _trauma * _trauma  # quadratic falloff
	var off_x := randf_range(-1.0, 1.0) * max_offset.x * shake
	var off_y := randf_range(-1.0, 1.0) * max_offset.y * shake
	var rot := randf_range(-1.0, 1.0) * deg_to_rad(max_rotation) * shake
	cam.position = cam.position + Vector2(off_x, off_y)
	cam.rotation = cam.rotation + rot

	if _trauma <= 0.0:
		set_process(false)


# ─── 内部 ───

var _cam: Camera2D = null

func _get_camera() -> Camera2D:
	if not _cam or not is_instance_valid(_cam):
		_cam = get_viewport().get_camera_2d()
	return _cam
