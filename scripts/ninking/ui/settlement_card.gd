class_name SettlementCard
extends Control

## 结算卡片「封印解除」
## Phase E 独立结算环节：计分完成后弹出，展示战果（封印名 / 分数 / 金币），
## 玩家点击「封印解除」按钮后进入商店。
##
## 场景树实例：ninking_main.tscn → UIManager → SettlementOverlay
## 所有节点在 Godot 编辑器中可直接拖拽调整。

const SB = preload("res://scripts/config/sound_bank.gd")

signal unlock_pressed()

# ── 子节点 ──
@onready var _card_panel: Control = $CardPanel
@onready var _seal_title: Label = %SealTitle
@onready var _break_label: Label = %BreakLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _total_gold_label: Label = %TotalGoldLabel
@onready var _lord_label: Label = %LordLabel
@onready var _unlock_btn: Button = %UnlockBtn

# stagger 入场节点（按序）
var _stagger_nodes: Array[Label] = []

# 封印属性编号（粒子颜色用）
var _barrier_num: int = 1

# 本局金币获得（count-up 用）
var _gold_gain: int = 0

# 动画控制
var _entrance_busy: bool = false


func _ready() -> void:
	_unlock_btn.pressed.connect(_on_unlock_pressed)
	# 初始态：所有内容隐藏
	_reset_animation_state()


## 展示结算卡片。
## data keys: barrier_num, seal_idx, score, gold_gained, total_gold, seal_lord_name
func show_card(data: Dictionary) -> void:
	if _entrance_busy:
		return
	_entrance_busy = true

	_barrier_num = data.get("barrier_num", 1)
	var seal_idx: int = data.get("seal_idx", 0)
	var seal_names: Array[String] = ["修羅ノ封印", "明王ノ封印", "夜叉ノ封印"]

	# 配置文字
	_seal_title.text = "%s · %s" % [BarrierTheme.get_barrier_name(_barrier_num), seal_names[seal_idx]]
	_score_label.text = "%d" % data.get("num", 0)

	_gold_gain = max(0, data.get("gold_gained", 0))
	_gold_label.text = "+%d $" % _gold_gain
	_total_gold_label.text = "所持: %d $" % data.get("total_gold", 0)

	var lord: String = data.get("seal_lord_name", "")
	_lord_label.visible = lord != ""
	if lord != "":
		_lord_label.text = "封印ノ主: %s" % lord

	# 确保可见（show_view 已设 visible=true，此句为防御）
	visible = true

	# 重置动画态
	_reset_animation_state()

	# 播放入场
	await _play_entrance()
	_entrance_busy = false


func _reset_animation_state() -> void:
	## 重置所有节点到入场前状态，杀死残留 tween。
	if not is_inside_tree():
		return

	# 杀死已有 tween
	var tw := create_tween()
	tw.kill()

	_card_panel.scale = Vector2.ZERO
	_card_panel.modulate = Color.WHITE

	_stagger_nodes = [_seal_title, _break_label, _score_label]
	for node: Control in _stagger_nodes:
		node.modulate = Color(1, 1, 1, 0)
		node.scale = Vector2(0.5, 0.5)

	_gold_label.modulate = Color(1, 1, 1, 0)
	_gold_label.scale = Vector2.ONE
	_total_gold_label.modulate = Color(1, 1, 1, 0)
	_total_gold_label.scale = Vector2.ONE

	_unlock_btn.disabled = true
	_unlock_btn.modulate = Color.WHITE


func _play_entrance() -> void:
	## 入场动画序列。
	if not is_inside_tree():
		return

	# 1. manga_burst 粒子 + hit_stop
	var viewport_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5
	GlobalTweens.burst_particles(center, "manga_burst", BarrierTheme.get_particle_color(_barrier_num))
	GlobalTweens.do_hit_stop(0.06, 0.04)

	# 2. CardPanel scale in
	_card_panel.scale = Vector2.ZERO
	var card_tw := create_tween()
	card_tw.tween_property(_card_panel, "scale", Vector2(1.05, 1.05), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	card_tw.tween_property(_card_panel, "scale", Vector2.ONE, 0.08)
	await card_tw.finished

	if not is_inside_tree():
		return

	# 3. Stagger in: seal_title → break_label → score_label
	for node: Control in _stagger_nodes:
		var stw := create_tween()
		stw.set_parallel(true)
		stw.tween_property(node, "modulate", Color.WHITE, 0.15).set_ease(Tween.EASE_OUT)
		stw.tween_property(node, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await stw.finished
		await get_tree().create_timer(0.05).timeout
		if not is_inside_tree():
			return

	# 4. GoldLabel count-up（重点）
	_show_gold_count_up()

	# 5. TotalGoldLabel fade in
	var totw := create_tween()
	totw.tween_property(_total_gold_label, "modulate", Color.WHITE, 0.15)
	await totw.finished

	if not is_inside_tree():
		return

	# 6. 启用按钮 + 脉冲辉光
	_unlock_btn.disabled = false
	_start_button_pulse()


func _show_gold_count_up() -> void:
	## 金币数字 count-up 动画。
	_gold_label.modulate = Color(1, 1, 1, 0)
	_gold_label.text = "+0 $"

	# 淡入 + count-up
	var gold_tw := create_tween()
	gold_tw.set_parallel(true)
	gold_tw.tween_property(_gold_label, "modulate", Color.WHITE, 0.2)
	gold_tw.tween_method(
		func(v: float): _gold_label.text = "+%d $" % int(v),
		0.0, float(_gold_gain), 0.5
	).set_ease(Tween.EASE_OUT)
	await gold_tw.finished

	GlobalTweens.play_sfx(SB.UI_COIN)
	# 小 pulse 强调
	var pulse_tw := create_tween()
	pulse_tw.tween_property(_gold_label, "scale", Vector2(1.15, 1.15), 0.1)
	pulse_tw.tween_property(_gold_label, "scale", Vector2.ONE, 0.15)


func _start_button_pulse() -> void:
	## 按钮脉冲辉光（无限循环）。
	var pulse_tw := create_tween().set_loops()
	pulse_tw.tween_property(_unlock_btn, "modulate", Color(1.08, 1.08, 1.08, 1.0), 0.6)\
		.set_ease(Tween.EASE_IN_OUT)
	pulse_tw.tween_property(_unlock_btn, "modulate", Color.WHITE, 0.6)\
		.set_ease(Tween.EASE_IN_OUT)


func _on_unlock_pressed() -> void:
	## 按钮点击：退出动画 → 发射信号。
	if _unlock_btn.disabled:
		return
	_unlock_btn.disabled = true

	# 卡片收缩 + 淡出
	var exit_tw := create_tween()
	exit_tw.set_parallel(true)
	exit_tw.tween_property(_card_panel, "scale", Vector2(1.05, 1.05), 0.1)
	exit_tw.tween_property(_card_panel, "scale", Vector2.ZERO, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	exit_tw.tween_property(_card_panel, "modulate", Color.TRANSPARENT, 0.2)
	await exit_tw.finished

	if is_inside_tree():
		unlock_pressed.emit()
