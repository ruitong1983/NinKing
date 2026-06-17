extends Control
## Debug 评分测试场景 — 主界面布局 + 右侧控制面板 + 选牌队列。
##
## 与主场景共用同一种 LeftPanel / CenterColumn / HandArea 布局，
## DunArea 内部使用 CardGrid (HandCardContainer) 管理 3×3 卡牌网格，
## 与主场景 CardGrid 命名与结构完全一致。

const MAX_NINJAS: int = 5
const COLS: int = 3

const STAR_CHART_TYPES: Array[CardData.HandType3] = [
	CardData.HandType3.HIGH_CARD_3,
	CardData.HandType3.ONE_PAIR_3,
	CardData.HandType3.STRAIGHT_3,
	CardData.HandType3.FLUSH_3,
	CardData.HandType3.STRAIGHT_FLUSH_3,
	CardData.HandType3.THREE_OF_KIND_3,
]

# ── State ──
var _full_deck: Array[CardData.PlayingCard] = []
var _selected_ninjas: Array[Dictionary] = []
var _star_chart_levels: Dictionary = {}
var _selected_queue: Array[CardData.PlayingCard] = []
var _ninja_bar_node: NinjaBarNode
var _deck_visible: bool = false
var _star_tooltip: Control = null

# Flat 3×3 slot data: 9 entries (row * 3 + col), null = empty
var _slot_data: Array = []

# ── @onready references ──
@onready var _card_grid: HandCardContainer = %CardGrid
@onready var _score_label: Label = %ScoreLabel
@onready var _target_label: Label = %TargetScoreLabel
@onready var _progress: ProgressBar = %ProgressBar
@onready var _col_xi_label: Label = %ColXiLabel
@onready var _status_label: Label = %StatusLabel
@onready var _play_btn: Button = %PlayBtn
@onready var _ai_btn: Button = %AiRearrangeBtn
@onready var _deck_btn: Button = %DeckBtn
@onready var _hands_label: Label = %HandsLabel
@onready var _barrier_label: Label = %BarrierLabel
@onready var _ninja_status: Label = %NinjaStatusLabel
@onready var _ninja_bar: Control = %NinjaBar

var _anim_handler: AnimationHandler
var _ui_proxy: DebugUiProxy
@onready var _star_chart_container: VBoxContainer = %StarChartContainer

# Score detail panel
@onready var _score_detail_panel: Control = %ScoreDetailPanel
@onready var _detail_btn: Button = %ScoreDetailBtn
var _last_baseline_result: ScoreResult = null
var _last_ninja_result: ScoreResult = null
var _last_head_cards: Array[CardData.PlayingCard] = []
var _last_mid_cards: Array[CardData.PlayingCard] = []
var _last_tail_cards: Array[CardData.PlayingCard] = []
var _last_col_evals: Array = []
var _last_xi_result = null


func _ready() -> void:
	_full_deck = CardData.create_standard_deck()
	_star_chart_levels = _default_star_chart_levels()
	_slot_data.resize(9)
	for i: int in range(9):
		_slot_data[i] = null

	# Setup NinjaBar with NinjaBarContainer + NinjaBarNode (matching main scene)
	var ninja_bar_container := NinjaBarContainer.new()
	ninja_bar_container.name = "BarContainer"
	_ninja_bar.add_child(ninja_bar_container)
	_ninja_bar_node = NinjaBarNode.new()
	_ninja_bar.add_child(_ninja_bar_node)
	_ninja_bar_node.set_container(ninja_bar_container)

	# Card tray
	%CardTray.setup(_full_deck)
	%CardTray.card_selected.connect(_on_tray_card_selected)

	# Ninja selector
	%NinjaSelector.ninjas_selected.connect(_on_ninjas_selected)
	%NinjaSelector.cancelled.connect(func(): pass)

	# Buttons
	_play_btn.pressed.connect(_on_play_pressed)
	%ClearBtn.pressed.connect(_on_clear_pressed)
	%DealBtn.pressed.connect(_on_deal_pressed)
	%RandomBtn.pressed.connect(_on_random_pressed)
	%BackBtn.pressed.connect(_on_back_pressed)
	%NinjaSelectBtn.pressed.connect(_on_ninja_select_pressed)
	_ai_btn.pressed.connect(_on_ai_pressed)
	_deck_btn.pressed.connect(_on_deck_toggle_pressed)

	# Star chart UI
	_rebuild_star_chart()

	# ── Scoring animation proxy & handler ──
	_ui_proxy = DebugUiProxy.new(self)
	_ui_proxy.score_label = _score_label
	_ui_proxy.progress_bar = _progress
	_ui_proxy.card_grid = _card_grid
	_ui_proxy.head_type_label = %HeadTypeLabel
	_ui_proxy.middle_type_label = %MiddleTypeLabel
	_ui_proxy.tail_type_label = %TailTypeLabel
	_ui_proxy.shadow_lv_label = %ShadowLv
	_ui_proxy.flash_lv_label = %FlashLv
	_ui_proxy.destroy_lv_label = %DestroyLv
	_ui_proxy.shadow_score_label = %ShadowScore
	_ui_proxy.flash_score_label = %FlashScore
	_ui_proxy.destroy_score_label = %DestroyScore
	_ui_proxy.left_col_type = %LeftColType
	_ui_proxy.mid_col_type = %MidColType
	_ui_proxy.right_col_type = %RightColType
	_ui_proxy.left_col_score = %LeftColScore
	_ui_proxy.mid_col_score = %MidColScore
	_ui_proxy.right_col_score = %RightColScore
	_ui_proxy.left_col_lv = %LeftColLv
	_ui_proxy.mid_col_lv = %MidColLv
	_ui_proxy.right_col_lv = %RightColLv
	_ui_proxy.col0_label = %Col0Label
	_ui_proxy.col1_label = %Col1Label
	_ui_proxy.col2_label = %Col2Label
	_ui_proxy.ninja_bar = _ninja_bar_node
	_ui_proxy.panel_bg = $MainVBox/ContentRow/LeftPanel/PanelBg
	_ui_proxy.game_bg = $GameBg

	_anim_handler = AnimationHandler.new()
	_anim_handler.setup(_ui_proxy, func(): pass)

	_detail_btn.pressed.connect(_on_detail_open)
	_score_detail_panel.close_requested.connect(_on_detail_close)

	_reset_ui()
	_update_button_states()


func _default_star_chart_levels() -> Dictionary:
	var d: Dictionary = {}
	for ht: CardData.HandType3 in STAR_CHART_TYPES:
		d[ht] = 0
	return d


# ══════════════════════════════════════════
# Star chart inline (replaces DebugStarChart)
# ══════════════════════════════════════════

func _rebuild_star_chart() -> void:
	_dismiss_star_tooltip()
	for child: Node in _star_chart_container.get_children():
		child.queue_free()

	for ht: CardData.HandType3 in STAR_CHART_TYPES:
		var name_str: String = CardData.get_hand_type3_name(ht)
		var lvl: int = _star_chart_levels.get(ht, 0)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = "%s  Lv.%d" % [name_str, lvl]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 14)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_entered.connect(_show_star_tooltip.bind(ht, lvl, label))
		label.mouse_exited.connect(_dismiss_star_tooltip)
		var plus_btn := Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(30, 30)
		plus_btn.pressed.connect(_on_star_plus.bind(ht))

		row.add_child(label)
		row.add_child(plus_btn)
		_star_chart_container.add_child(row)


func _on_star_plus(ht_int: int) -> void:
	var ht: CardData.HandType3 = ht_int as CardData.HandType3
	var current: int = _star_chart_levels.get(ht, 0)
	_star_chart_levels[ht] = current + 1
	_rebuild_star_chart()


func _show_star_tooltip(ht_int: int, lvl: int, label: Label) -> void:
	_dismiss_star_tooltip()
	var ht: CardData.HandType3 = ht_int as CardData.HandType3
	var name_str: String = CardData.get_hand_type3_name(ht)
	var tier_color: Color = _get_level_tier_color(lvl)

	var chips: int = CardData.get_hand_type3_leveled_chips(ht, _star_chart_levels)
	var mult: int = CardData.get_hand_type3_leveled_mult(ht, _star_chart_levels)
	var upgrade: Dictionary = CardData.get_star_chart_upgrade(ht)
	var up_chips: int = upgrade["chips"]
	var up_mult: int = upgrade["mult"]

	# ── Build tooltip Control ──
	var tooltip := Control.new()
	tooltip.name = "StarTooltip"
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", CardVisualComposer.create_tooltip_stylebox(tier_color))
	panel.size = Vector2(190, 68)
	tooltip.add_child(panel)

	var title := Label.new()
	title.text = "%s  Lv.%d" % [name_str, lvl]
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", tier_color)
	title.position = Vector2(10, 6)
	title.size = Vector2(170, 20)
	tooltip.add_child(title)

	var stats := Label.new()
	stats.text = "筹码 %d  倍率 %d" % [chips, max(mult, 1)]
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.85, 0.85, 0.80))
	stats.position = Vector2(10, 28)
	stats.size = Vector2(170, 20)
	tooltip.add_child(stats)

	var hint := Label.new()
	hint.text = "每级 +%d筹码  +%d倍率" % [up_chips, up_mult]
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.50))
	hint.position = Vector2(10, 48)
	hint.size = Vector2(170, 16)
	tooltip.add_child(hint)

	tooltip.size = Vector2(190, 68)

	# ── Position: left of the label, vertically aligned ──
	tooltip.global_position = Vector2(
		label.global_position.x - tooltip.size.x - 12,
		label.global_position.y - 2
	)

	get_tree().current_scene.add_child(tooltip)
	_star_tooltip = tooltip


func _dismiss_star_tooltip() -> void:
	if _star_tooltip != null and is_instance_valid(_star_tooltip):
		_star_tooltip.queue_free()
	_star_tooltip = null


func _get_level_tier_color(lvl: int) -> Color:
	if lvl <= 0:
		return Color(0.7, 0.7, 0.7)
	elif lvl <= 2:
		return Color("#7A7A7A")
	elif lvl <= 4:
		return Color("#588CF2")
	elif lvl <= 6:
		return Color("#C4A843")
	else:
		return Color("#AA66FF")


# ══════════════════════════════════════════
# Card tray → queue → deal
# ══════════════════════════════════════════

func _on_tray_card_selected(card_data: CardData.PlayingCard) -> void:
	# Toggle: if card already in queue, remove it
	for i: int in range(_selected_queue.size()):
		var qc: CardData.PlayingCard = _selected_queue[i]
		if qc.suit == card_data.suit and qc.rank == card_data.rank:
			_selected_queue.remove_at(i)
			_rebuild_queue_display()
			_update_button_states()
			_set_status("已移除 %s — 队列 %d/9" % [card_data.get_display_name(), _selected_queue.size()])
			return

	if _selected_queue.size() >= 9:
		_set_status("队列已满 (9张)，请先移除再添加")
		return

	_selected_queue.append(card_data)
	%CardTray.clear_highlight()
	_rebuild_queue_display()
	_update_button_states()
	_set_status("已添加 %s — 队列 %d/9" % [card_data.get_display_name(), _selected_queue.size()])


func _rebuild_queue_display() -> void:
	for child: Node in %CardQueueContainer.get_children():
		child.queue_free()

	%CardQueueLabel.text = "📋 已選隊列 (%d/9)" % _selected_queue.size()

	for i: int in range(_selected_queue.size()):
		var cd: CardData.PlayingCard = _selected_queue[i]
		var tag := Button.new()
		tag.text = cd.get_display_name()
		tag.flat = true
		tag.add_theme_font_size_override("font_size", 14)
		if cd.suit == CardData.Suit.HEARTS or cd.suit == CardData.Suit.DIAMONDS:
			tag.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		else:
			tag.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color.WHITE
		bg.set_corner_radius_all(3)
		tag.add_theme_stylebox_override("normal", bg)
		tag.add_theme_stylebox_override("hover", bg)
		tag.add_theme_stylebox_override("pressed", bg)
		var idx := i
		tag.pressed.connect(_remove_queue_card.bind(idx))
		%CardQueueContainer.add_child(tag)


func _remove_queue_card(idx: int) -> void:
	if idx >= 0 and idx < _selected_queue.size():
		var cd := _selected_queue[idx]
		_selected_queue.remove_at(idx)
		_rebuild_queue_display()
		_update_button_states()
		_set_status("已移除 %s — 队列 %d/9" % [cd.get_display_name(), _selected_queue.size()])


func _on_deal_pressed() -> void:
	if _selected_queue.size() != 9:
		return
	for i: int in range(9):
		_slot_data[i] = _selected_queue[i]
	_rebuild_grid_display()
	_update_button_states()
	_preview_dun_labels()
	_invalidate_detail()
	_set_status("已发牌 — 9 张牌进入手牌区")


func _rebuild_grid_display() -> void:
	_card_grid.clear_cards()
	for i: int in range(9):
		var cd = _slot_data[i]
		if cd != null:
			var card := _create_card(cd)
			_card_grid.add_card(card)
			card.update_display()


func _create_card(cd: CardData.PlayingCard) -> NinKingCard:
	var card := NinKingCard.new()
	card.card_size = Vector2(125, 175)
	card.playing_card_data = cd
	card.name = "DebugCard_%d_%d" % [cd.suit, cd.rank]
	card.show_front = true
	card.can_be_interacted_with = false
	return card


# ══════════════════════════════════════════
# Scoring
# ══════════════════════════════════════════

func _on_play_pressed() -> void:
	var total: int = _cards_on_table()
	if total != 9:
		_set_status("需要恰好 9 张牌，当前 %d 张" % total)
		return

	var head_cards: Array[CardData.PlayingCard] = _row_data(0)
	var mid_cards: Array[CardData.PlayingCard] = _row_data(1)
	var tail_cards: Array[CardData.PlayingCard] = _row_data(2)

	var head_eval := HandEvaluator3.evaluate(head_cards)
	var mid_eval := HandEvaluator3.evaluate(mid_cards)
	var tail_eval := HandEvaluator3.evaluate(tail_cards)

	var col_evals: Array[HandEvaluator3.EvalResult] = [
		_eval_column(0, head_cards, mid_cards, tail_cards),
		_eval_column(1, head_cards, mid_cards, tail_cards),
		_eval_column(2, head_cards, mid_cards, tail_cards),
	]

	var xi_result := XiDetector.detect(head_cards, mid_cards, tail_cards, head_eval, mid_eval, tail_eval)

	# ── Baseline: empty ninjas ──
	var baseline_result: ScoreResult = ScoreCalculator.calculate(
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval,
	)

	# ── Main: selected ninjas ──
	var result: ScoreResult = ScoreCalculator.calculate(
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval,
		col_evals, _selected_ninjas, _star_chart_levels, xi_result, {}, 0
	)

	# ── Store for detail panel ──
	_last_baseline_result = baseline_result
	_last_ninja_result = result
	_last_head_cards = head_cards.duplicate()
	_last_mid_cards = mid_cards.duplicate()
	_last_tail_cards = tail_cards.duplicate()
	_last_col_evals = col_evals.duplicate()
	_last_xi_result = xi_result

	# ── Build play_data and trigger scoring animation ──
	var play_data: Dictionary = {
		"score_result": result,
		"xi_result": xi_result,
		"col_evals": col_evals,
		"head_eval": head_eval,
		"mid_eval": mid_eval,
		"tail_eval": tail_eval,
		"current_score": 0,
		"target_score": 99999,
		"plays_remaining": 3,
		"barrier_num": 1,
		"owned_ninjas": _selected_ninjas,
		"gold": 0,
		"star_chart_levels": _star_chart_levels,
		"current_arrangement": {
			"head": head_cards,
			"mid": mid_cards,
			"tail": tail_cards,
			"head_eval": head_eval,
			"mid_eval": mid_eval,
			"tail_eval": tail_eval,
		},
	}
	NinKingGameState.current_arrangement = Arrangement.new(
		head_cards, mid_cards, tail_cards, head_eval, mid_eval, tail_eval
	)
	NinKingGameState.owned_ninjas = _selected_ninjas.duplicate()
	_anim_handler.current_play_data = play_data
	await _anim_handler.run_scoring()
	_update_score_display(result, head_eval, mid_eval, tail_eval, col_evals, xi_result)
	_detail_btn.visible = true
	_set_status("动画完成 — 总分: %d" % result.total_score)


func _eval_column(idx: int, head: Array, mid: Array, tail: Array) -> HandEvaluator3.EvalResult:
	return HandEvaluator3.evaluate([head[idx], mid[idx], tail[idx]])


func _row_data(row: int) -> Array[CardData.PlayingCard]:
	var arr: Array[CardData.PlayingCard] = []
	var start := row * COLS
	for col: int in range(COLS):
		var idx := start + col
		if idx < _slot_data.size() and _slot_data[idx] != null:
			arr.append(_slot_data[idx] as CardData.PlayingCard)
	return arr


func _cards_on_table() -> int:
	var count := 0
	for cd in _slot_data:
		if cd != null:
			count += 1
	return count


# ══════════════════════════════════════════
# Score display
# ══════════════════════════════════════════

func _update_score_display(
	result: ScoreResult,
	head_eval: HandEvaluator3.EvalResult,
	mid_eval: HandEvaluator3.EvalResult,
	tail_eval: HandEvaluator3.EvalResult,
	col_evals: Array,
	xi_result: XiDetector.XiResult
) -> void:
	_score_label.text = "%d ×%d = %d" % [result.chips_sum, max(result.mult_sum, 1), result.total_score]
	_progress.value = result.total_score

	%HeadTypeLabel.text = CardData.get_hand_type3_name(head_eval.hand_type)
	%MiddleTypeLabel.text = CardData.get_hand_type3_name(mid_eval.hand_type)
	%TailTypeLabel.text = CardData.get_hand_type3_name(tail_eval.hand_type)

	if col_evals.size() == 3:
		%Col0Label.text = CardData.get_hand_type3_name(col_evals[0].hand_type)
		%Col1Label.text = CardData.get_hand_type3_name(col_evals[1].hand_type)
		%Col2Label.text = CardData.get_hand_type3_name(col_evals[2].hand_type)

	if xi_result and xi_result.has_any():
		var xi_parts: Array[String] = []
		for xi_name: String in xi_result.triggered:
			var x_val: int = 1
			for defn: Dictionary in XiDetector.XI_DEFINITIONS:
				if defn["name"] == xi_name:
					x_val = defn["x_mult"]
					break
			xi_parts.append("%s×%d" % [xi_name, x_val])
		_col_xi_label.text = "喜: " + "  ".join(xi_parts)
	else:
		_col_xi_label.text = "喜: -"


func _update_hand_type_labels(
	result: ScoreResult,
	head_eval: HandEvaluator3.EvalResult,
	mid_eval: HandEvaluator3.EvalResult,
	tail_eval: HandEvaluator3.EvalResult,
	col_evals: Array
) -> void:
	%ShadowType.text = CardData.get_hand_type3_name(head_eval.hand_type)
	%ShadowLv.text = "Lv.%d" % _star_chart_levels.get(head_eval.hand_type, 0)
	%ShadowScore.text = _fmt_chips_x_mult(result.head_chips, result.head_mult, result.head_score)

	%FlashType.text = CardData.get_hand_type3_name(mid_eval.hand_type)
	%FlashLv.text = "Lv.%d" % _star_chart_levels.get(mid_eval.hand_type, 0)
	%FlashScore.text = _fmt_chips_x_mult(result.mid_chips, result.mid_mult, result.mid_score)

	%DestroyType.text = CardData.get_hand_type3_name(tail_eval.hand_type)
	%DestroyLv.text = "Lv.%d" % _star_chart_levels.get(tail_eval.hand_type, 0)
	%DestroyScore.text = _fmt_chips_x_mult(result.tail_chips, result.tail_mult, result.tail_score)

	if col_evals.size() == 3 and result.col_scores.size() == 3:
		%LeftColType.text = CardData.get_hand_type3_name(col_evals[0].hand_type)
		%LeftColLv.text = "Lv.%d" % _star_chart_levels.get(col_evals[0].hand_type, 0)
		%LeftColScore.text = str(result.col_scores[0]) if result.col_scores[0] > 0 else "-"

		%MidColType.text = CardData.get_hand_type3_name(col_evals[1].hand_type)
		%MidColLv.text = "Lv.%d" % _star_chart_levels.get(col_evals[1].hand_type, 0)
		%MidColScore.text = str(result.col_scores[1]) if result.col_scores[1] > 0 else "-"

		%RightColType.text = CardData.get_hand_type3_name(col_evals[2].hand_type)
		%RightColLv.text = "Lv.%d" % _star_chart_levels.get(col_evals[2].hand_type, 0)
		%RightColScore.text = str(result.col_scores[2]) if result.col_scores[2] > 0 else "-"

	_progress.max_value = max(300.0, float(result.total_score))
	_target_label.text = "最大 %d" % max(300, result.total_score)


func _preview_dun_labels() -> void:
	## 发牌后即时评估行/列牌型，更新 DunArea 标签 + 左边栏牌型（不触发完整计分）。
	if _cards_on_table() != 9:
		return

	var head_cards: Array = _row_data(0)
	var mid_cards: Array = _row_data(1)
	var tail_cards: Array = _row_data(2)

	var head_eval := HandEvaluator3.evaluate(head_cards)
	var mid_eval := HandEvaluator3.evaluate(mid_cards)
	var tail_eval := HandEvaluator3.evaluate(tail_cards)

	# ── 中间 DunArea 标签 ──
	%HeadTypeLabel.text = CardData.get_hand_type3_name(head_eval.hand_type)
	%MiddleTypeLabel.text = CardData.get_hand_type3_name(mid_eval.hand_type)
	%TailTypeLabel.text = CardData.get_hand_type3_name(tail_eval.hand_type)

	# ── 左边栏 HandTypeVBox 牌型 ──
	%ShadowType.text = CardData.get_hand_type3_name(head_eval.hand_type)
	%FlashType.text = CardData.get_hand_type3_name(mid_eval.hand_type)
	%DestroyType.text = CardData.get_hand_type3_name(tail_eval.hand_type)

	# Level & 公式（根据 _star_chart_levels）
	%ShadowLv.text = "Lv.%d" % _star_chart_levels.get(head_eval.hand_type, 0)
	%FlashLv.text = "Lv.%d" % _star_chart_levels.get(mid_eval.hand_type, 0)
	%DestroyLv.text = "Lv.%d" % _star_chart_levels.get(tail_eval.hand_type, 0)
	%ShadowScore.text = _fmt_chips_x_mult_preview(head_eval.hand_type)
	%FlashScore.text = _fmt_chips_x_mult_preview(mid_eval.hand_type)
	%DestroyScore.text = _fmt_chips_x_mult_preview(tail_eval.hand_type)

	var col_evals: Array[HandEvaluator3.EvalResult] = [
		_eval_column(0, head_cards, mid_cards, tail_cards),
		_eval_column(1, head_cards, mid_cards, tail_cards),
		_eval_column(2, head_cards, mid_cards, tail_cards),
	]
	%Col0Label.text = CardData.get_hand_type3_name(col_evals[0].hand_type)
	%Col1Label.text = CardData.get_hand_type3_name(col_evals[1].hand_type)
	%Col2Label.text = CardData.get_hand_type3_name(col_evals[2].hand_type)

	# ── 左边栏 ColumnBar 类型（如果场景有这些节点） ──
	if has_node("%LeftColType"):
		%LeftColType.text = CardData.get_hand_type3_name(col_evals[0].hand_type) if col_evals[0].hand_type != CardData.HandType3.HIGH_CARD_3 else ""
	if has_node("%MidColType"):
		%MidColType.text = CardData.get_hand_type3_name(col_evals[1].hand_type) if col_evals[1].hand_type != CardData.HandType3.HIGH_CARD_3 else ""
	if has_node("%RightColType"):
		%RightColType.text = CardData.get_hand_type3_name(col_evals[2].hand_type) if col_evals[2].hand_type != CardData.HandType3.HIGH_CARD_3 else ""

	# ── 喜即时检测 —— 手牌变动即刻更新左边栏 ──
	_update_xi_preview(head_cards, mid_cards, tail_cards, head_eval, mid_eval, tail_eval)


func _update_xi_preview(
	head_cards: Array, mid_cards: Array, tail_cards: Array,
	head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult,
	tail_eval: HandEvaluator3.EvalResult
) -> void:
	var xi_result := XiDetector.detect(head_cards, mid_cards, tail_cards, head_eval, mid_eval, tail_eval)
	if xi_result and xi_result.has_any():
		var xi_parts: Array[String] = []
		for xi_name: String in xi_result.triggered:
			var x_val: int = 1
			for defn: Dictionary in XiDetector.XI_DEFINITIONS:
				if defn["name"] == xi_name:
					x_val = defn["x_mult"]
					break
			xi_parts.append("%s×%d" % [xi_name, x_val])
		_col_xi_label.text = "喜: " + "  ".join(xi_parts)
	else:
		_col_xi_label.text = "喜: -"


func _clear_all_type_labels() -> void:
	for node: Node in [%ShadowType, %FlashType, %DestroyType,
			%LeftColType, %MidColType, %RightColType]:
		(node as Label).text = "-"
	for node: Node in [%ShadowLv, %FlashLv, %DestroyLv,
			%LeftColLv, %MidColLv, %RightColLv]:
		(node as Label).text = ""
	for node: Node in [%ShadowScore, %FlashScore, %DestroyScore,
			%LeftColScore, %MidColScore, %RightColScore]:
		(node as RichTextLabel).text = ""
	%HeadTypeLabel.text = ""
	%MiddleTypeLabel.text = ""
	%TailTypeLabel.text = ""
	%Col0Label.text = ""
	%Col1Label.text = ""
	%Col2Label.text = ""
	_col_xi_label.text = ""


func _fmt_chips_x_mult(chips: int, mult: int, score: int) -> String:
	return "%d ×%d = %d" % [chips, max(mult, 1), score]


## Preview formula using base chips/mult × star chart level.
func _fmt_chips_x_mult_preview(hand_type: CardData.HandType3) -> String:
	var lvl: int = _star_chart_levels.get(hand_type, 0)
	if lvl <= 0:
		return ""
	var base: Dictionary = CardData.get_hand_type3_base(hand_type)
	var upgrade: Dictionary = CardData.get_star_chart_upgrade(hand_type)
	var total_chips: int = base["chips"] + upgrade["chips"] * lvl
	var total_mult: int = base["mult"] + upgrade["mult"] * lvl
	var score: int = total_chips * max(total_mult, 1)
	return "%d ×%d = %d" % [total_chips, total_mult, score]


# ══════════════════════════════════════════
# Clear / Random / Back
# ══════════════════════════════════════════

func _on_clear_pressed() -> void:
	_clear_all_cards()
	_reset_ui()
	_invalidate_detail()
	_set_status("已清空牌桌")


func _on_random_pressed() -> void:
	_clear_all_cards()
	_full_deck.shuffle()
	var cards: Array[CardData.PlayingCard] = _full_deck.slice(0, 9)

	for i: int in range(9):
		_slot_data[i] = cards[i]

	_rebuild_grid_display()
	_update_button_states()
	_preview_dun_labels()
	_invalidate_detail()
	_set_status("已随机发 9 张牌，点击「討伐」查看分数")


func _clear_all_cards() -> void:
	_card_grid.clear_cards()
	for i: int in range(9):
		_slot_data[i] = null
	%CardTray.clear_highlight()
	_selected_queue.clear()
	_rebuild_queue_display()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_launcher.tscn")


# ══════════════════════════════════════════
# AI Arrange
# ══════════════════════════════════════════

func _on_ai_pressed() -> void:
	var all_cards: Array[CardData.PlayingCard] = []
	for cd in _slot_data:
		if cd != null:
			all_cards.append(cd)
	if all_cards.size() != 9:
		_set_status("需要 9 张牌才能自动排列，当前 %d 张" % all_cards.size())
		return

	var arr := AutoArranger.find_best(all_cards, _empty_ninja(), _empty_ninja(), _empty_ninja(), _star_chart_levels)
	if arr == null:
		_set_status("未找到合法排列")
		return

	_clear_all_cards()

	for col: int in range(COLS):
		_slot_data[0 * COLS + col] = arr.head[col]
	for col: int in range(COLS):
		_slot_data[1 * COLS + col] = arr.mid[col]
	for col: int in range(COLS):
		_slot_data[2 * COLS + col] = arr.tail[col]

	_rebuild_grid_display()
	_update_button_states()
	_preview_dun_labels()
	_set_status("已自动排列为最佳阵型 — 影 %s / 瞬 %s / 滅 %s" % [
		CardData.get_hand_type3_name(arr.head_eval.hand_type),
		CardData.get_hand_type3_name(arr.mid_eval.hand_type),
		CardData.get_hand_type3_name(arr.tail_eval.hand_type),
	])


func _empty_ninja() -> Dictionary:
	return { "chips": 0, "mult": 0, "x_stack": [] }


# ══════════════════════════════════════════
# Ninja selection
# ══════════════════════════════════════════

func _on_ninja_select_pressed() -> void:
	%NinjaSelector.open(NinjaData.ALL_NINJAS, _selected_ninjas)


func _on_ninjas_selected(selected: Array[Dictionary]) -> void:
	_selected_ninjas = selected.duplicate()
	NinKingGameState.owned_ninjas = _selected_ninjas.duplicate()
	_ninja_status.text = "已選: %d/%d" % [_selected_ninjas.size(), MAX_NINJAS]
	_ninja_bar_node.refresh(_selected_ninjas, MAX_NINJAS)


# ══════════════════════════════════════════
# Deck toggle
# ══════════════════════════════════════════

func _on_deck_toggle_pressed() -> void:
	_deck_visible = not _deck_visible
	var placed: int = _cards_on_table()
	var remaining: int = _full_deck.size() - placed
	_deck_btn.text = "牌库: %d (剩余 %d)" % [_full_deck.size(), remaining]
	if _deck_visible:
		_set_status("牌库共 %d 张，已放置 %d 张" % [_full_deck.size(), placed])


# ══════════════════════════════════════════
# UI helpers
# ══════════════════════════════════════════

func _set_status(msg: String) -> void:
	_status_label.text = msg


func _reset_ui() -> void:
	_score_label.text = "0 ×0 = 0"
	_progress.value = 0
	_progress.max_value = 300
	_target_label.text = "封印 300"
	_barrier_label.text = "結界 DEBUG"
	_hands_label.text = "討伐 0"
	_clear_all_type_labels()
	_update_button_states()


func _update_button_states() -> void:
	var count: int = _cards_on_table()
	_play_btn.disabled = (count != 9)
	_ai_btn.disabled = (count != 9)
	%DealBtn.disabled = (_selected_queue.size() != 9)
	_deck_btn.text = "牌库: %d" % (_full_deck.size() - count)


# ══════════════════════════════════════════
# Score detail panel + button management
# ══════════════════════════════════════════

func _on_detail_open() -> void:
	_detail_btn.visible = false
	_score_detail_panel.show_detail(
		_last_baseline_result, _last_ninja_result,
		_last_head_cards, _last_mid_cards, _last_tail_cards,
		_last_col_evals, _last_xi_result,
		_star_chart_levels, _selected_ninjas
	)


func _on_detail_close() -> void:
	_detail_btn.visible = true


func _invalidate_detail() -> void:
	_score_detail_panel.hide_detail()
	_detail_btn.visible = false
	_last_baseline_result = null
	_last_ninja_result = null
	_last_head_cards.clear()
	_last_mid_cards.clear()
	_last_tail_cards.clear()
	_last_col_evals.clear()
	_last_xi_result = null
