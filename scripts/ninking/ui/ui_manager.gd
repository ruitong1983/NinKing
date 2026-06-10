class_name UIManager
extends Control

## Centralized UI management for NinKing (忍者牌 × 比鸡).
## Delegates to HandDisplay, HandInteraction, DeckViewerController,
## DunHighlighter, RedrawVFXHandler, ResultScreenDisplay, NinjaBarDisplay.
## All display updates go through this class — game_manager.gd only handles flow.

# ═══ Sub-views ═══
@onready var level_intro: Control = %LevelIntro
@onready var game_layout: Control = %GameLayout
@onready var game_bg: ColorRect = %GameBg
@onready var scoring_overlay: Control = %ScoringOverlay
@onready var level_complete: Control = %LevelComplete
@onready var game_over: Control = %GameOver

# ═══ Level intro ═══
@onready var intro_level_label: Label = %LevelLabel
@onready var intro_target_label: Label = %TargetLabel

# ═══ Left panel ═══
@onready var left_panel: Control = %LeftPanel
@onready var panel_bg: ColorRect = %PanelBg
@onready var chips_label: Label = %ChipsLabel
@onready var mult_label: Label = %MultLabel
@onready var shadow_type_label: Label = %ShadowType
@onready var flash_type_label: Label = %FlashType
@onready var destroy_type_label: Label = %DestroyType
@onready var score_label: Label = %ScoreLabel
@onready var target_score_label: Label = %TargetScoreLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var hands_label: Label = %HandsLabel
@onready var redraws_label: Label = %RedrawsLabel
@onready var gold_label: Label = %GoldLabel
@onready var barrier_label: Label = %BarrierLabel
@onready var round_label: Label = %RoundLabel

# ═══ Ninja bar ═══
@onready var ability_bar: HBoxContainer = %AbilityBar

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
@onready var redraw_btn: Button = %RedrawBtn

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
var redraw_vfx_handler: RedrawVFXHandler
var result_screen: ResultScreenDisplay
var ninja_bar: NinjaBarDisplay


func _ready() -> void:
	# Hand display (rendering)
	hand_display = HandDisplay.new()
	hand_display.setup(
		head_cards, middle_cards, tail_cards,
		head_type_label, middle_type_label, tail_type_label,
		col0_label, col1_label, col2_label,
		chips_label, mult_label, shadow_type_label, flash_type_label, destroy_type_label,
		play_btn, redraw_btn, status_label
	)

	# Hand interaction (swap/redraw state machine)
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

	# Redraw VFX handler (手替え animation sequence)
	redraw_vfx_handler = RedrawVFXHandler.new()
	redraw_vfx_handler.setup(
		hand_interaction,
		head_cards, middle_cards, tail_cards,
		play_btn, redraw_btn, status_label
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
	ninja_bar.setup(ability_bar)

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
	game_bg.visible = (view in ["game", "intro", "scoring"])
	level_intro.visible = (view == "intro")
	game_layout.visible = (view in ["game", "scoring"])
	# Balatro-style: no overlay dimming during scoring — inline HUD animation
	level_complete.visible = (view == "complete")
	game_over.visible = (view == "gameover")
	victory_overlay.visible = (view == "victory")


# ══════════════════════════════════════════
# Seal intro
# ══════════════════════════════════════════

func on_seal_start(barrier: int, seal_idx: int, target: int, seal_lord_name: String) -> void:
	var seal_names: Array = ["修羅ノ封印", "明王ノ封印", "夜叉ノ封印"]
	var seal_str: String = seal_names[seal_idx] if seal_idx < 3 else "?"
	intro_level_label.text = "結界%d · %s" % [barrier, seal_str]
	if seal_lord_name != "":
		intro_target_label.text = "封印 %d | 封印ノ主: %s" % [target, seal_lord_name]
	else:
		intro_target_label.text = "封印 %d" % target

	update_score(0, target)
	update_target(target)
	update_match_info(3, 2)
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


func update_match_info(plays_left: int, redraws_left: int) -> void:
	hands_label.text = "討伐 %d" % plays_left
	redraws_label.text = "手替え %d" % redraws_left


func update_target(target: int) -> void:
	target_score_label.text = "封印 %d" % target


# ══════════════════════════════════════════
# Hand display — thin wrappers to HandDisplay + HandInteraction
# ══════════════════════════════════════════

func _refresh_internal(hand: Array[CardData.PlayingCard]) -> void:
	hand_interaction.set_hand(hand)
	hand_display.refresh(hand, hand_interaction.swap_source_idx, hand_interaction.redraw_targets, hand_interaction.redraw_mode, _on_ninking_card_clicked, _on_ninking_card_dragged)
	dun_highlighter.update(NinKingGameState.current_arrangement, redraw_mode)


func refresh_hand(hand: Array[CardData.PlayingCard]) -> void:
	_refresh_internal(hand)


func refresh_groups(head_cards_arr: Array[CardData.PlayingCard], mid_cards_arr: Array[CardData.PlayingCard], tail_cards_arr: Array[CardData.PlayingCard], _constraint_ok: bool) -> void:
	var combined: Array[CardData.PlayingCard] = []
	combined.append_array(head_cards_arr)
	combined.append_array(mid_cards_arr)
	combined.append_array(tail_cards_arr)
	_refresh_internal(combined)


# ══════════════════════════════════════════
# Card interaction — delegated to HandInteraction
# ══════════════════════════════════════════

var redraw_mode: bool:
	get:
		return hand_interaction.redraw_mode if hand_interaction else false

func _on_ninking_card_clicked(idx: int) -> void:
	hand_interaction.handle_card_clicked(idx)
	_update_redraw_button_text()


func _on_ninking_card_dragged(idx: int, drop_position: Vector2) -> void:
	hand_interaction.handle_card_dragged(idx, drop_position)


func enable_redraw_mode() -> void:
	if NinKingGameState.redraws_remaining <= 0:
		return
	hand_interaction.enable_redraw_mode()
	play_btn.disabled = true
	status_label.text = "选择要替换的卡牌 (最多 3 张)"
	hand_interaction.set_cards_interactable(head_cards, middle_cards, tail_cards, false)
	_update_redraw_button_text()


func confirm_redraw() -> void:
	if hand_interaction.redraw_targets.is_empty():
		return
	if redraw_vfx_handler.is_running():
		return
	redraw_vfx_handler.execute()


func _update_redraw_button_text() -> void:
	if hand_interaction.redraw_mode:
		redraw_btn.text = "手替え(%d/3)" % hand_interaction.redraw_targets.size()


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
	update_match_info(gs.plays_remaining, gs.redraws_remaining)
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
