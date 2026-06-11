class_name UIManager
extends Control

## Centralized UI management for NinKing (忍者牌 × 比鸡).
## Delegates to HandDisplay, HandInteraction, DeckViewerController,
## DunHighlighter, ResultScreenDisplay, NinjaBarDisplay.
## All display updates go through this class — game_manager.gd only handles flow.

# ═══ Sub-views ═══
@onready var level_intro: Control = %LevelIntro
@onready var game_layout: Control = %GameLayout
@onready var game_bg: TextureRect = %GameBg
@onready var scoring_overlay: Control = %ScoringOverlay
@onready var level_complete: Control = %LevelComplete
@onready var game_over: Control = %GameOver
@onready var shop_overlay: Control = %ShopOverlay  # Phase C 🏪

# ═══ Level intro ═══
@onready var intro_level_label: Label = %LevelLabel
@onready var intro_target_label: Label = %TargetLabel
@onready var boss_portrait: TextureRect = %BossPortrait

# Boss portrait texture mapping (name -> res path)
const BOSS_PORTRAITS: Dictionary = {
	"断尾": "res://assets/images/boss/boss_broken_tail.png",
	"无头": "res://assets/images/boss/boss_headless.png",
	"独柱": "res://assets/images/boss/boss_lone_pillar.png",
	"反目": "res://assets/images/boss/boss_mirror.png",
	"封印师": "res://assets/images/boss/boss_sealer.png",
	"散牌王": "res://assets/images/boss/boss_chaos.png",
	"饿鬼": "res://assets/images/boss/boss_devourer.png",
	"喜之克星": "res://assets/images/boss/boss_curse.png",
	"终焉": "res://assets/images/boss/boss_countdown.png",
}

# ═══ Left panel ═══
@onready var left_panel: Control = %LeftPanel
@onready var panel_bg: ColorRect = %PanelBg
@onready var score_card: Panel = %ScoreCard
@onready var col_xi_label: Label = %ColXiLabel
@onready var shadow_type_label: Label = %ShadowType
@onready var flash_type_label: Label = %FlashType
@onready var destroy_type_label: Label = %DestroyType
@onready var shadow_score_label: Label = %ShadowScore
@onready var flash_score_label: Label = %FlashScore
@onready var destroy_score_label: Label = %DestroyScore
@onready var score_label: Label = %ScoreLabel
@onready var target_score_label: Label = %TargetScoreLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var hands_label: Label = %HandsLabel
@onready var gold_label: Label = %GoldLabel
@onready var barrier_label: Label = %BarrierLabel
@onready var round_label: Label = %RoundLabel

# ═══ Ninja bar ═══
@onready var ninja_bar_container: HBoxContainer = %NinjaBar

# ═══ Center ═══
@onready var status_label: Label = %StatusLabel
@onready var deck_btn: Button = %DeckBtn
@onready var hand_area: HBoxContainer = %HandArea
@onready var dun_head: Panel = %DunHead
@onready var dun_middle: Panel = %DunMiddle
@onready var dun_tail: Panel = %DunTail
@onready var head_cards: Hand = %HeadCards
@onready var middle_cards: Hand = %MiddleCards
@onready var tail_cards: Hand = %TailCards
@onready var head_label: Label = %HeadLabel
@onready var middle_label: Label = %MiddleLabel
@onready var tail_label: Label = %TailLabel
@onready var head_type_label: Label = %HeadTypeLabel
@onready var middle_type_label: Label = %MiddleTypeLabel
@onready var tail_type_label: Label = %TailTypeLabel
@onready var play_btn: Button = %PlayBtn

# ═══ Column labels ═══
@onready var col0_label: Label = %Col0Label
@onready var col1_label: Label = %Col1Label
@onready var col2_label: Label = %Col2Label

# ═══ AI rearrange ═══
@onready var ai_rearrange_btn: Button = %AiRearrangeBtn

# ═══ Scoring overlay ═══
@onready var hand_name_label: Label = %HandNameLabel
@onready var score_value_label: Label = %ScoreValueLabel
@onready var score_breakdown: Label = %ScoreBreakdown

# ═══ Level complete ═══
@onready var complete_label: Label = %CompleteLabel
@onready var reward_label: Label = %RewardLabel
@onready var to_shop_button: Button = %ToShopButton

# ═══ Game over ═══
@onready var game_over_label: Label = %GameOverLabel
@onready var score_summary: Label = %ScoreSummary
@onready var retry_button: Button = %RetryButton
@onready var back_to_menu_button: Button = %BackToMenuButton

# ═══ Victory overlay ═══
@onready var victory_overlay: Control = $VictoryOverlay
@onready var victory_label: Label = $VictoryOverlay/VictoryLabel
@onready var victory_stats_summary: Label = $VictoryOverlay/StatsSummary
@onready var victory_menu_button: Button = $VictoryOverlay/MenuButton

# ═══ Delegates ═══
var hand_display: RefCounted  # HandDisplay
var hand_interaction: RefCounted  # HandInteraction
var deck_viewer_ctrl: DeckViewerController
var dun_highlighter: DunHighlighter
var result_screen: ResultScreenDisplay
var ninja_bar: NinjaBarDisplay


func _ready() -> void:
	# Hand display (rendering)
	hand_display = HandDisplay.new()
	hand_display.setup(
		head_cards, middle_cards, tail_cards,
		head_type_label, middle_type_label, tail_type_label,
		col0_label, col1_label, col2_label, col_xi_label,
		shadow_type_label, flash_type_label, destroy_type_label,
		shadow_score_label, flash_score_label, destroy_score_label,
		play_btn, status_label
	)

	# Hand interaction (swap state machine)
	hand_interaction = HandInteraction.new()
	hand_interaction.setup(hand_display)

	# Deck viewer
	deck_viewer_ctrl = DeckViewerController.new()
	deck_viewer_ctrl.setup(
		%DeckBtn, %DeckViewer, %CloseBtn,
		%DrawCountLabel, %DiscardCountLabel,
		%CardGrid, %ViewerBg
	)

	# Dun highlighter (constraint visualization + card flash)
	dun_highlighter = DunHighlighter.new()
	dun_highlighter.setup(
		head_label, middle_label, tail_label, status_label,
		head_cards, middle_cards, tail_cards
	)

	# Result screen display (scoring / complete / victory / gameover / xi)
	result_screen = ResultScreenDisplay.new()
	result_screen.setup(
		reward_label, complete_label,
		victory_label, victory_stats_summary,
		game_over_label, score_summary,
		hand_name_label, score_value_label, score_breakdown
	)

	# Ninja bar display
	ninja_bar = NinjaBarDisplay.new()
	ninja_bar.setup(ninja_bar_container)

	# ── Three-Dun title progressive outline (V20) ──
	head_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.3))
	head_label.add_theme_constant_override("font_outline_size", 1)
	middle_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
	middle_label.add_theme_constant_override("font_outline_size", 2)
	tail_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	tail_label.add_theme_constant_override("font_outline_size", 3)

	status_label.text = ""


# ══════════════════════════════════════════
# View switching
# ══════════════════════════════════════════

func show_view(view: String) -> void:
	game_bg.visible = (view in ["game", "intro", "scoring", "complete"])
	level_intro.visible = (view == "intro")
	game_layout.visible = (view in ["game", "scoring"])
	# Balatro-style: no overlay dimming during scoring — inline HUD animation
	level_complete.visible = (view == "complete")
	shop_overlay.visible = (view == "shop")
	game_over.visible = (view == "gameover")
	victory_overlay.visible = (view == "victory")


# ══════════════════════════════════════════
# Shop overlay (Phase C)
# ══════════════════════════════════════════

var _current_shop_panel: Control = null

func get_current_shop_panel() -> Control:
	return _current_shop_panel


func show_shop(shop_mgr: ShopManager, gold: int, colors: Dictionary) -> void:
	## Create and show shop_panel instance inside ShopOverlay.
	## Also triggers panel entrance animation.
	if _current_shop_panel != null and is_instance_valid(_current_shop_panel):
		_current_shop_panel.queue_free()
		_current_shop_panel = null

	var panel_scene := preload("res://scenes/ninking/shop_panel.tscn")
	var panel := panel_scene.instantiate()
	shop_overlay.add_child(panel)

	_current_shop_panel = panel
	panel.init(shop_mgr, gold, colors)

	# Wire signals to game_manager (emitted via UIManager for relay)
	panel.purchase_requested.connect(_on_shop_purchase_requested)
	panel.item_purchase_requested.connect(_on_shop_item_purchase_requested)
	panel.enchant_purchase_requested.connect(_on_shop_enchant_purchase_requested)

	panel.reroll_requested.connect(_on_shop_reroll_requested)
	panel.continue_requested.connect(_on_shop_continue_requested)

	show_view("shop")
	panel.play_entrance_animation()


func hide_shop() -> void:
	## Close shop panel with exit animation, then clean up.
	if _current_shop_panel == null or not is_instance_valid(_current_shop_panel):
		shop_overlay.visible = false
		return

	var panel := _current_shop_panel
	var all_cards: Array = []
	if panel.has_method("get_all_cards"):
		all_cards = panel.get_all_cards()

	await NinKingTween.play_shop_exit({
		overlay = panel.overlay,
		panel = panel,
		all_cards = all_cards,
	})

	if is_instance_valid(panel):
		panel.queue_free()
	_current_shop_panel = null
	shop_overlay.visible = false


func is_shop_open() -> bool:
	return _current_shop_panel != null and is_instance_valid(_current_shop_panel) and shop_overlay.visible


func shop_panel_update_gold(gold: int) -> void:
	## Update gold on the active shop panel (called by game_manager after purchase/reroll).
	if _current_shop_panel != null and is_instance_valid(_current_shop_panel):
		_current_shop_panel.update_gold(gold)


func shop_panel_update_reroll_cost(cost: int) -> void:
	## B4: Update reroll cost display on the active shop panel.
	if _current_shop_panel != null and is_instance_valid(_current_shop_panel):
		_current_shop_panel.update_reroll_cost(cost)


func shop_panel_refresh_stock() -> void:
	## Refresh stock on the active shop panel (called by game_manager after reroll).
	if _current_shop_panel != null and is_instance_valid(_current_shop_panel):
		_current_shop_panel.refresh_stock()


## B6: Mark a specific item card as purchased in the shop panel (greys out + disables).
func shop_panel_mark_item_purchased(item_id: String) -> void:
	if _current_shop_panel != null and is_instance_valid(_current_shop_panel):
		_current_shop_panel.mark_item_purchased(item_id)


## B5: Open enchant target selector on the active shop panel.
## `on_card_selected` receives (card_index: int).
func shop_panel_start_enchant_targeting(hand: Array, on_card_selected: Callable) -> void:
	if _current_shop_panel != null and is_instance_valid(_current_shop_panel):
		_current_shop_panel.start_enchant_targeting(hand, on_card_selected)


# 🏪 Shop signal relay — game_manager connects to these
signal shop_purchase_requested(ability_data: Dictionary)
signal shop_item_purchase_requested(item_data: Dictionary)
signal shop_enchant_purchase_requested(item_data: Dictionary)  # B5
signal shop_reroll_requested()
signal shop_continue_requested()

func _on_shop_purchase_requested(data: Dictionary) -> void:
	shop_purchase_requested.emit(data)

func _on_shop_item_purchase_requested(data: Dictionary) -> void:
	shop_item_purchase_requested.emit(data)

func _on_shop_enchant_purchase_requested(data: Dictionary) -> void:
	shop_enchant_purchase_requested.emit(data)

func _on_shop_reroll_requested() -> void:
	shop_reroll_requested.emit()

func _on_shop_continue_requested() -> void:
	shop_continue_requested.emit()


# ══════════════════════════════════════════
# Seal intro
# ══════════════════════════════════════════

func on_seal_start(barrier: int, seal_idx: int, target: int, seal_lord_name: String) -> void:
	var seal_names: Array = ["修羅ノ封印", "明王ノ封印", "夜叉ノ封印"]
	var seal_str: String = seal_names[seal_idx] if seal_idx < 3 else "?"
	intro_level_label.text = "結界%d · %s" % [barrier, seal_str]
	if seal_lord_name != "":
		intro_target_label.text = "封印 %d | 封印ノ主: %s" % [target, seal_lord_name]
		if BOSS_PORTRAITS.has(seal_lord_name):
			boss_portrait.texture = load(BOSS_PORTRAITS[seal_lord_name])
			boss_portrait.visible = true
	else:
		intro_target_label.text = "封印 %d" % target
		boss_portrait.visible = false

	update_score(0, target)
	update_target(target)
	update_match_info(3)
	update_gold(NinKingGameState.gold)


# ══════════════════════════════════════════
# Left panel
# ══════════════════════════════════════════

func update_score(current: int, target: int) -> void:
	score_label.text = "忍気 %d" % current
	progress_bar.max_value = float(target)
	progress_bar.value = float(current)


func update_gold(amount: int) -> void:
	gold_label.text = "$%d" % amount


func update_match_info(plays_left: int) -> void:
	hands_label.text = "討伐 %d" % plays_left


func update_target(target: int) -> void:
	target_score_label.text = "封印 %d" % target


# ══════════════════════════════════════════
# Hand display — thin wrappers to HandDisplay + HandInteraction
# ══════════════════════════════════════════

func _refresh_internal(hand: Array[CardData.PlayingCard]) -> void:
	hand_interaction.set_hand(hand)
	hand_display.refresh(hand, hand_interaction.swap_source_idx, _on_ninking_card_clicked, _on_ninking_card_dragged)
	dun_highlighter.update(NinKingGameState.current_arrangement)
	play_btn.disabled = not NinKingGameState.is_constraint_satisfied()


func refresh_hand(hand: Array[CardData.PlayingCard]) -> void:
	_refresh_internal(hand)


func refresh_groups(head_cards_arr: Array[CardData.PlayingCard], mid_cards_arr: Array[CardData.PlayingCard], tail_cards_arr: Array[CardData.PlayingCard], constraint_ok: bool) -> void:
	var combined: Array[CardData.PlayingCard] = []
	combined.append_array(head_cards_arr)
	combined.append_array(mid_cards_arr)
	combined.append_array(tail_cards_arr)
	_refresh_internal(combined)
	play_btn.disabled = not constraint_ok  # B10: 约束不满足时禁止出牌


# ══════════════════════════════════════════
# Card interaction — delegated to HandInteraction
# ══════════════════════════════════════════

func _on_ninking_card_clicked(idx: int) -> void:
	hand_interaction.handle_card_clicked(idx)


func _on_ninking_card_dragged(idx: int, drop_position: Vector2) -> void:
	hand_interaction.handle_card_dragged(idx, drop_position)


# ══════════════════════════════════════════
# Ninja bar — delegated to NinjaBarDisplay
# ══════════════════════════════════════════

func refresh_ninjas(owned_ninjas: Array, max_slots: int) -> void:
	ninja_bar.refresh(owned_ninjas, max_slots)


# ══════════════════════════════════════════
# Result screens — delegated to ResultScreenDisplay
# ══════════════════════════════════════════

func set_level_complete(gold_reward: int) -> void:
	result_screen.set_level_complete(gold_reward)


func set_victory(barrier: int, score: int) -> void:
	result_screen.set_victory(barrier, score)


func show_game_over(reason: String, barrier: int, score: int) -> void:
	result_screen.show_game_over(reason, barrier, score)


func show_xi_popup(xis: Array[String]) -> void:
	result_screen.show_xi_popup(xis)


func show_scoring_result(head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult, tail_eval: HandEvaluator3.EvalResult, total_score: int) -> void:
	result_screen.show_scoring_result(head_eval, mid_eval, tail_eval, total_score)


# ══════════════════════════════════════════
# Card flash — delegated to DunHighlighter
# ══════════════════════════════════════════

func flash_all_hand_cards() -> void:
	dun_highlighter.flash_all_hands()


func flash_hand(hand: Hand) -> void:
	dun_highlighter.flash_hand(hand)


# ══════════════════════════════════════════
# Restore UI state (after scene reload)
# ══════════════════════════════════════════

func restore_ui_state() -> void:
	var gs: NinKingGameState = NinKingGameState
	on_seal_start(gs.barrier_num, gs.seal_idx, int(gs.target_score), gs.current_seal_lord_name)
	update_score(int(gs.current_score), int(gs.target_score))
	update_match_info(gs.plays_remaining)
	update_gold(gs.gold)
	refresh_hand(gs.hand)
	refresh_ninjas(gs.owned_ninjas, gs.max_ninja_slots)
	var dm: DeckManager = NinKingGameState.deck_manager
	if dm != null:
		deck_viewer_ctrl.update_deck_count(dm.draw_pile.size(), dm.discard_pile.size())


# ══════════════════════════════════════════
# Deck display — delegated to DeckViewerController
# ══════════════════════════════════════════

func update_deck_count(draw_count: int, discard_count: int) -> void:
	deck_viewer_ctrl.update_deck_count(draw_count, discard_count)
