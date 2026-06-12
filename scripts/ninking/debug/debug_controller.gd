extends Control
## Debug 计分测试场景 — 主控制器。
## 零侵入主场景：不引用 UIManager/NinKingGameState/game_manager。
## 复用：Hand.tscn × 3、NinKingCard、ScoreCalculator、HandEvaluator3、XiDetector、NinjaBarDisplay。
## 所有 LeftPanel 标签手动更新，不依赖 HandTypeLabeler（其引用了 NinKingGameState）。

signal back_to_launcher()

# ═══ LeftPanel references ═══
@onready var score_label: Label = %ScoreLabel
@onready var target_score_label: Label = %TargetScoreLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var col_xi_label: Label = %ColXiLabel
@onready var head_type_label: Label = %HeadTypeLabel
@onready var middle_type_label: Label = %MiddleTypeLabel
@onready var tail_type_label: Label = %TailTypeLabel
@onready var shadow_type_label: Label = %ShadowType
@onready var flash_type_label: Label = %FlashType
@onready var destroy_type_label: Label = %DestroyType
@onready var shadow_score_label: Label = %ShadowScore
@onready var flash_score_label: Label = %FlashScore
@onready var destroy_score_label: Label = %DestroyScore

# ═══ Center references ═══
@onready var play_btn: Button = %PlayBtn
@onready var head_cards: Hand = %HeadCards
@onready var middle_cards: Hand = %MiddleCards
@onready var tail_cards: Hand = %TailCards
@onready var ninja_bar_container: HBoxContainer = %NinjaBar
@onready var status_label: Label = %StatusLabel
@onready var dun_head: Panel = %DunHead
@onready var dun_middle: Panel = %DunMiddle
@onready var dun_tail: Panel = %DunTail
@onready var hands_label: Label = %HandsLabel
@onready var gold_label: Label = %GoldLabel
@onready var barrier_label: Label = %BarrierLabel
@onready var round_label: Label = %RoundLabel

# ═══ Right panel references ═══
@onready var ninja_select_btn: Button = %NinjaSelectBtn
@onready var ninja_status_label: Label = %NinjaStatusLabel
@onready var star_chart_container: VBoxContainer = %StarChartContainer
@onready var clear_btn: Button = %ClearBtn
@onready var random_btn: Button = %RandomBtn
@onready var back_btn: Button = %BackBtn

# ═══ Tray ═══
@onready var card_tray: Control = %CardTray

# ═══ Ninja selector ═══
@onready var ninja_selector: Control = %NinjaSelector

# ═══ Delegates ═══
var _tray: Control
var _ninja_bar: NinjaBarDisplay
var _star_chart_ui: RefCounted

# ═══ State ═══
var _full_deck: Array[CardData.PlayingCard] = []
var _selected_ninjas: Array[Dictionary] = []
var _star_chart_levels: Dictionary = {}
var _current_tray_card: CardData.PlayingCard = null


enum DunSlot { HEAD, MID, TAIL }

const DUN_NAMES: Dictionary = {
	DunSlot.HEAD: "影",
	DunSlot.MID: "瞬",
	DunSlot.TAIL: "滅",
}


func _ready() -> void:
	_full_deck = CardData.create_standard_deck()
	_init_star_chart_ui()
	_init_tray()
	_init_ninja_bar()
	_connect_signals()
	_reset_ui()


# ══════════════════════════════════════════
# Initialization
# ══════════════════════════════════════════

func _init_star_chart_ui() -> void:
	_star_chart_ui = preload("res://scripts/ninking/debug/debug_star_chart.gd").new()
	_star_chart_ui.setup(star_chart_container, _star_chart_levels)


func _init_tray() -> void:
	_tray = card_tray
	_tray.setup(_full_deck)


func _init_ninja_bar() -> void:
	_ninja_bar = NinjaBarDisplay.new()
	_ninja_bar.setup(ninja_bar_container)


func _connect_signals() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	random_btn.pressed.connect(_on_random_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	ninja_select_btn.pressed.connect(_on_ninja_select_pressed)
	_tray.card_selected.connect(_on_tray_card_selected)

	# Hand clicks for placing / removing cards
	head_cards.gui_input.connect(_on_hand_gui_input.bind(DunSlot.HEAD))
	middle_cards.gui_input.connect(_on_hand_gui_input.bind(DunSlot.MID))
	tail_cards.gui_input.connect(_on_hand_gui_input.bind(DunSlot.TAIL))

	# Ninja selector
	ninja_selector.ninjas_selected.connect(_on_ninjas_selected)
	ninja_selector.cancelled.connect(_on_ninja_selector_cancelled)


func _reset_ui() -> void:
	score_label.text = "気 0"
	target_score_label.text = "封印 0"
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	col_xi_label.text = ""
	status_label.text = "从底栏选中牌 → 点击上方空格放入"
	hands_label.text = "討伐 3"
	gold_label.text = "$0"
	barrier_label.text = "結界 DEBUG"
	round_label.text = ""

	# Reset HandTypeRow labels
	shadow_type_label.text = "-"
	flash_type_label.text = "-"
	destroy_type_label.text = "-"
	shadow_score_label.text = ""
	flash_score_label.text = ""
	destroy_score_label.text = ""

	# Build star chart UI
	_build_star_chart_ui()
	_update_ninja_status()


# ══════════════════════════════════════════
# Star Chart UI
# ══════════════════════════════════════════

func _build_star_chart_ui() -> void:
	_star_chart_ui.rebuild()


# ══════════════════════════════════════════
# Tray → Hand card placement
# ══════════════════════════════════════════

func _on_tray_card_selected(card_data: CardData.PlayingCard) -> void:
	_current_tray_card = card_data
	status_label.text = "已选: %s  点击上方空格放入" % card_data.get_display_name()


func _on_hand_gui_input(event: InputEvent, slot: DunSlot) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed:
		return

	if mb.button_index == MOUSE_BUTTON_LEFT and _current_tray_card != null:
		var hand: Hand = _hand_for_slot(slot)
		if hand.get_card_count() < 3:
			_add_card_to_hand(hand, _current_tray_card)
			_current_tray_card = null
			_tray.clear_highlight()
			status_label.text = "从底栏选中牌 → 点击上方空格放入"


func _on_hand_card_gui_input(event: InputEvent, card: NinKingCard, hand: Hand) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if not mb.pressed:
		return

	match mb.button_index:
		MOUSE_BUTTON_RIGHT:
			hand.remove_card(card)
			card.queue_free()
			_update_left_panel_labels()

		MOUSE_BUTTON_LEFT:
			if _current_tray_card != null:
				card.playing_card_data = _current_tray_card
				card.update_display()
				_current_tray_card = null
				_tray.clear_highlight()
				_update_left_panel_labels()


func _add_card_to_hand(hand: Hand, card_data: CardData.PlayingCard) -> void:
	var nc: NinKingCard = NinKingCard.new()
	nc.card_size = Vector2(140, 196)
	nc.playing_card_data = card_data
	nc.gui_input.connect(_on_hand_card_gui_input.bind(nc, hand))
	hand.add_card(nc)
	nc.update_display()
	_update_left_panel_labels()


func _hand_for_slot(slot: DunSlot) -> Hand:
	match slot:
		DunSlot.HEAD:
			return head_cards
		DunSlot.MID:
			return middle_cards
		_:
			return tail_cards


# ══════════════════════════════════════════
# 討伐 — Score calculation
# ══════════════════════════════════════════

func _on_play_pressed() -> void:
	var head_data: Array[CardData.PlayingCard] = _get_hand_data(head_cards)
	var mid_data: Array[CardData.PlayingCard] = _get_hand_data(middle_cards)
	var tail_data: Array[CardData.PlayingCard] = _get_hand_data(tail_cards)

	if head_data.size() != 3 or mid_data.size() != 3 or tail_data.size() != 3:
		status_label.text = "需要 9 张牌（影/瞬/滅 各 3 张）"
		return

	# Evaluate groups
	var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_data)
	var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_data)
	var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_data)

	# Column evaluation
	var col_evals: Array[HandEvaluator3.EvalResult] = []
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [head_data[i], mid_data[i], tail_data[i]]
		col_evals.append(HandEvaluator3.evaluate(col_cards))

	# Xi detection
	var xi_result: XiDetector.XiResult = XiDetector.detect(
		head_data, mid_data, tail_data, head_eval, mid_eval, tail_eval
	)

	# Calculate score
	var result: ScoreCalculator.ScoreResult = ScoreCalculator.calculate(
		head_data, mid_data, tail_data,
		head_eval, mid_eval, tail_eval,
		col_evals,
		_selected_ninjas,
		_star_chart_levels,
		xi_result,
		{},  # No seal lord effects
		0    # No gold
	)

	# ── Update LeftPanel ──
	score_label.text = "気 %d" % result.total_score
	target_score_label.text = "封印 %d" % result.total_score
	progress_bar.max_value = float(max(result.total_score, 1))
	progress_bar.value = float(result.total_score)

	# ── Update HandTypeRow ──
	shadow_type_label.text = CardData.get_hand_type3_name(head_eval.hand_type)
	flash_type_label.text = CardData.get_hand_type3_name(mid_eval.hand_type)
	destroy_type_label.text = CardData.get_hand_type3_name(tail_eval.hand_type)

	shadow_score_label.text = "%d×%d" % [result.head_chips, result.head_mult]
	flash_score_label.text = "%d×%d" % [result.mid_chips, result.mid_mult]
	destroy_score_label.text = "%d×%d" % [result.tail_chips, result.tail_mult]

	# ── Dun type labels ──
	head_type_label.text = shadow_type_label.text
	middle_type_label.text = flash_type_label.text
	tail_type_label.text = destroy_type_label.text

	# ── Column × Xi label ──
	var col_x_parts: Array[String] = []
	for xv: int in result.col_x_stack:
		col_x_parts.append("×%d" % xv)
	var xi_parts: Array[String] = []
	for xv: int in result.global_xi_x_stack:
		xi_parts.append("×%d" % xv)

	var col_str: String = ""
	if not col_x_parts.is_empty():
		col_str = "列: " + "".join(col_x_parts)
	var xi_str: String = ""
	if not xi_parts.is_empty():
		xi_str = "喜: " + "".join(xi_parts)
	if col_str != "" and xi_str != "":
		col_xi_label.text = col_str + " | " + xi_str
	elif col_str != "":
		col_xi_label.text = col_str
	elif xi_str != "":
		col_xi_label.text = xi_str
	else:
		col_xi_label.text = ""

	# Breakdown in status
	var col_product: int = 1
	for xv: int in result.col_x_stack:
		col_product *= xv
	var xi_product: int = 1
	for xv: int in result.global_xi_x_stack:
		xi_product *= xv

	status_label.text = "影 %d + 瞬 %d + 滅 %d = %d | 列 ×%d | 喜 ×%d | 合計 %d" % [
		result.head_score, result.mid_score, result.tail_score,
		result.head_score + result.mid_score + result.tail_score,
		col_product, xi_product, result.total_score,
	]


# ══════════════════════════════════════════
# Helper — extract PlayingCard data from Hand
# ══════════════════════════════════════════

func _get_hand_data(hand: Hand) -> Array[CardData.PlayingCard]:
	## 遍历可视化子节点而非 hand._held_cards（避免访问 Card-Framework 私有成员）
	var result: Array[CardData.PlayingCard] = []
	var cards_node: Node = hand.get_node_or_null("Cards")
	if not cards_node:
		return result
	for card: Node in cards_node.get_children():
		if card is NinKingCard:
			result.append(card.playing_card_data)
	return result


# ══════════════════════════════════════════
# LeftPanel label update (hand change, no score yet)
# ══════════════════════════════════════════

func _update_left_panel_labels() -> void:
	var head_data: Array[CardData.PlayingCard] = _get_hand_data(head_cards)
	var mid_data: Array[CardData.PlayingCard] = _get_hand_data(middle_cards)
	var tail_data: Array[CardData.PlayingCard] = _get_hand_data(tail_cards)

	if head_data.size() == 3 and mid_data.size() == 3 and tail_data.size() == 3:
		# Show live preview of hand types only
		var he: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_data)
		var me: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_data)
		var te: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_data)

		head_type_label.text = CardData.get_hand_type3_name(he.hand_type)
		middle_type_label.text = CardData.get_hand_type3_name(me.hand_type)
		tail_type_label.text = CardData.get_hand_type3_name(te.hand_type)

		shadow_type_label.text = head_type_label.text
		flash_type_label.text = middle_type_label.text
		destroy_type_label.text = tail_type_label.text
	else:
		head_type_label.text = ""
		middle_type_label.text = ""
		tail_type_label.text = ""
		shadow_type_label.text = "-"
		flash_type_label.text = "-"
		destroy_type_label.text = "-"
		shadow_score_label.text = ""
		flash_score_label.text = ""
		destroy_score_label.text = ""

	score_label.text = "気 0"
	col_xi_label.text = ""

	# Update hands count
	var total: int = head_data.size() + mid_data.size() + tail_data.size()
	status_label.text = "影 %d/3 | 瞬 %d/3 | 滅 %d/3 | 从底栏选中牌 → 点击空格放入" % [
		head_data.size(), mid_data.size(), tail_data.size()
	]


# ══════════════════════════════════════════
# Clear / Random
# ══════════════════════════════════════════

func _on_clear_pressed() -> void:
	head_cards.clear_cards()
	middle_cards.clear_cards()
	tail_cards.clear_cards()
	_current_tray_card = null
	_tray.clear_highlight()
	_update_left_panel_labels()


func _on_random_pressed() -> void:
	_on_clear_pressed()

	var shuffled: Array[CardData.PlayingCard] = _full_deck.duplicate()
	shuffled.shuffle()
	var deal: Array[CardData.PlayingCard] = shuffled.slice(0, 9)

	for i: int in range(3):
		_add_card_to_hand(head_cards, deal[i])
	for i: int in range(3, 6):
		_add_card_to_hand(middle_cards, deal[i])
	for i: int in range(6, 9):
		_add_card_to_hand(tail_cards, deal[i])


# ══════════════════════════════════════════
# Ninja selection
# ══════════════════════════════════════════

func _on_ninja_select_pressed() -> void:
	ninja_selector.open(NinjaData.ALL_NINJAS, _selected_ninjas)


func _on_ninjas_selected(selected: Array[Dictionary]) -> void:
	_selected_ninjas = selected
	_update_ninja_status()


func _on_ninja_selector_cancelled() -> void:
	pass


func _update_ninja_status() -> void:
	var count: int = _selected_ninjas.size()
	ninja_status_label.text = "已選: %d/5" % count
	_ninja_bar.refresh(_selected_ninjas, 5)


# ══════════════════════════════════════════
# Navigation
# ══════════════════════════════════════════

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ninking/ninking_launcher.tscn")
