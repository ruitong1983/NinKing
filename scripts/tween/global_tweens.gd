# scripts/tween/global_tweens.gd
# ============================================================
# GlobalTweens — 全局动效调度（Autoload: GlobalTweens）
# 依赖: 本项目 8 个 VFX 子系统
# ============================================================
# 调用规范：外部代码只调 GlobalTweens，不直接调 TweenFX 或子系统。
# TweenFX 是纯函数库，GlobalTweens 是唯一对外入口。
# ============================================================
extends Node

const FX = preload("res://scripts/tween/tween_fx.gd")
const CU = preload("res://scripts/tween/count_up.gd")

# ─── 子系统实例 ───

var crt: CRTFilter
var shake: ScreenShake
var tilt: CardTilt
var particles: ParticlePool
var hit_stop: HitStop


func _ready() -> void:
	_init_subsystems()
	# CRT 需要在场景加载后挂载
	if get_tree():
		get_tree().root.child_entered_tree.connect(_on_first_scene_loaded, CONNECT_ONE_SHOT)


func _init_subsystems() -> void:
	crt = CRTFilter.new()
	shake = ScreenShake.new()
	shake.name = "ScreenShake"
	add_child(shake)
	tilt = CardTilt.new()
	tilt.name = "CardTilt"
	add_child(tilt)
	particles = ParticlePool.new()
	particles.name = "ParticlePool"
	add_child(particles)
	hit_stop = HitStop.new()
	hit_stop.name = "HitStop"
	add_child(hit_stop)


func _on_first_scene_loaded(_node: Node) -> void:
	crt.attach_to_root()


# ── CRT ──

func set_crt_enabled(enabled: bool) -> void:
	crt.set_enabled(enabled)

func set_crt_aberration(v: float) -> void:
	crt.set_aberration(v)

func set_crt_breath(v: float) -> void:
	crt.set_breath(v)


# ── 基础补间 & 卡牌动效（委托 TweenFX，透传 auto_kill）──

func pop_in(node: Node, duration: float = 0.3, from_scale: Vector2 = Vector2(0.1, 0.1), auto_kill: bool = true) -> Tween:
	return FX.pop_in(node, duration, from_scale, auto_kill)

func pop_out(node: Node, duration: float = 0.2, auto_kill: bool = true) -> Tween:
	return FX.pop_out(node, duration, auto_kill)

func fade_in(node: CanvasItem, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	return FX.fade_in(node, duration, auto_kill)

func fade_out(node: CanvasItem, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	return FX.fade_out(node, duration, auto_kill)

func fade_out_then_free(node: CanvasItem, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	return FX.fade_out_then_free(node, duration, auto_kill)

func scale_pop(node: Node, factor: float = 1.2, duration: float = 0.2, auto_kill: bool = true) -> Tween:
	return FX.scale_pop(node, factor, duration, auto_kill)

func punch_in(node: Node, duration: float = 0.4, peak_scale: float = 1.5, auto_kill: bool = true) -> Tween:
	return FX.punch_in(node, duration, peak_scale, auto_kill)

func toast(node: CanvasItem, hold_duration: float = 1.5, fade_in_dur: float = 0.2, fade_out_dur: float = 0.3, auto_kill: bool = true) -> Tween:
	return FX.toast(node, hold_duration, fade_in_dur, fade_out_dur, auto_kill)

func stagger_slide_in(nodes: Array, stagger: float = 0.12, dur: float = 0.3, slide_offset: float = 30.0) -> void:
	FX.stagger_slide_in(nodes, stagger, dur, slide_offset)

func stagger_spread(nodes: Array, center_pos: Vector2, radius: float = 400.0, spread_angle_deg: float = 40.0, stagger: float = 0.06, dur: float = 0.3) -> void:
	FX.stagger_spread(nodes, center_pos, radius, spread_angle_deg, stagger, dur)

func shake_node(node: Control, intensity: float = 4.0, duration: float = 0.25, auto_kill: bool = true) -> Tween:
	return FX.shake_node(node, intensity, duration, auto_kill)

func wobble(node: Node2D, angle_deg: float = 5.0, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	return FX.wobble(node, angle_deg, duration, auto_kill)

func pulse(node: Node, scale_to: Vector2 = Vector2(1.1, 1.1), duration: float = 0.6, auto_kill: bool = true) -> Tween:
	return FX.pulse(node, scale_to, duration, auto_kill)

func float_up(node: Node2D, offset_y: float = -40.0, duration: float = 0.8, auto_kill: bool = true) -> Tween:
	return FX.float_up(node, offset_y, duration, auto_kill)

func slide_in(node: Control, from_dir: TweenFX.SlideDir = TweenFX.SlideDir.UP, duration: float = 0.3, auto_kill: bool = true) -> Tween:
	return FX.slide_in(node, from_dir, duration, auto_kill)

func slide_out(node: Control, to_dir: TweenFX.SlideDir = TweenFX.SlideDir.DOWN, duration: float = 0.25, auto_kill: bool = true) -> Tween:
	return FX.slide_out(node, to_dir, duration, auto_kill)

func color_flash(node: CanvasItem, color: Color = Color.WHITE, duration: float = 0.1, auto_kill: bool = true) -> Tween:
	return FX.color_flash(node, color, duration, auto_kill)

func card_hover(node: CanvasItem, scale_to: Vector2 = Vector2(1.05, 1.05), offset_y: float = -4.0, duration: float = 0.15, auto_kill: bool = true) -> Tween:
	return FX.card_hover(node, scale_to, offset_y, duration, auto_kill)

func card_unhover(node: CanvasItem, original_scale: Vector2 = Vector2.ONE, original_y: float = 0.0, duration: float = 0.15, auto_kill: bool = true) -> Tween:
	return FX.card_unhover(node, original_scale, original_y, duration, auto_kill)

func enable_card_tilt(node: CanvasItem) -> void:
	tilt.enable_single(node)

func disable_card_tilt(node: CanvasItem) -> void:
	tilt.disable(node)

func set_hand_spread(cards: Array, center_pos: Vector2 = Vector2.ZERO) -> void:
	tilt.apply_spread(cards, center_pos)


# ── 震动 & 顿帧 ──

func screen_shake(intensity: float = 0.15, duration: float = 0.08) -> void:
	shake.trigger(intensity, duration)

func shake_screen(intensity: float = 0.15, duration: float = 0.08) -> void:
	shake.trigger(intensity, duration)

func do_hit_stop(duration: float = 0.06, time_scale: float = 0.05) -> void:
	hit_stop.freeze(duration, time_scale)


# ── 数字滚动 ──

func count_up(label: Label, to_value: int, duration: float = 0.5, prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	return CU.play(label, 0, to_value, duration, prefix, suffix, per_tick)

func count_up_gold(label: Label, amount: int, duration: float = 0.6, prefix: String = "", suffix: String = "", per_tick: Callable = Callable()) -> Tween:
	return CU.play_gold(label, amount, duration, prefix, suffix, per_tick)


# ── 粒子 ──

func burst_particles(position: Vector2, preset: String = "sparkle") -> void:
	particles.burst(position, preset)


# ── 音效 ──

func bind_sfx(tween: Tween, stream: AudioStream, at_elapsed: float = 0.0) -> void:
	AudioCoupler.bind_sfx(tween, stream, at_elapsed)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.add_child(player)
		player.play()
	else:
		player.queue_free()
