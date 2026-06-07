# scripts/tween/audio_coupler.gd
# ============================================================
# AudioCoupler — 动效-音效耦合
# 可独立移植: 单文件拷走即用
# 依赖: 无（自建 AudioStreamPlayer）
# ============================================================
class_name AudioCoupler
extends Node


# ─── Tween 内联音效 ───

## 在 Tween 播放到 at_elapsed 秒时触发音效
static func bind_sfx(tween: Tween, stream: AudioStream, at_elapsed: float = 0.0) -> void:
	if not is_instance_valid(tween) or not stream:
		return

	var parent_node: Node = tween.get_parent() if tween.get_parent() else null
	if not parent_node:
		return

	var sfx_tween := parent_node.create_tween()
	sfx_tween.set_ignore_time_scale(true)
	sfx_tween.tween_interval(at_elapsed)
	sfx_tween.tween_callback(_play_and_forget.bind(stream, 0.0))


# ─── 手动触发 ───

static func play_one_shot(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not stream:
		return null

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	# 调用方应在创建后立即将 player 加入场景树
	return player


# ─── 内部 ───

static func _play_and_forget(stream: AudioStream, volume_db: float) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)

	# 挂到 root 来播放
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(player)
		player.play()
	else:
		player.queue_free()
