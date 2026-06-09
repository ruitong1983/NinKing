class_name UIManager
extends Node

## Centralized UI management for NinKing (忍者牌 × 比鸡).
## Delegates hand rendering to HandDisplay and interaction to HandInteraction.
## All display updates go through this class — game_manager.gd only handles flow.

# ═══ Sub-views ═══
@onready var main_menu: Control = %MainMenu
@onready var level_intro: Control = %LevelIntro
@onready var game_layout: Control = %GameLayout
@onready var game_bg: ColorRect = %GameBg
@onready var scoring_overlay: Control = %ScoringOverlay
@onready var level_complete: Control = %LevelComplete
@onready var game_over: Control = %GameOver

# ═══ Menu ═══
@onready var start_button: Button = %StartButton
@onready var deck_label: Label = %DeckLabel

# ═══ Level intro ═══
@onready var intro_level_label: Label = %LevelLabel
@onready var intro_target_label: Label = %TargetLabel

# ═══ Left panel ═══
@onready var left_panel: Control = %LeftPanel
@onready var panel_bg: ColorRect = %PanelBg
@onready var chips_label: Label = %ChipsLabel
@onready var mult_label: Label = %MultLabel
@onready var dun_type_row: Label = %HandTypeLabel
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

# ═══ Scoring overlay ═══
@onready var hand_name_label: Label = %HandNameLabel
@onready var score_value_label: Label = %ScoreValueLabel
@onready var score_breakdown: Label = %ScoreBreakdown

# ═══ Level complete ═══
@onready var complete_label: Label = %CompleteLabel
@onready var reward_label: Label = %RewardLabel
@onready var to_shop_button: Button = %ToShopButton

# ═══ Game over / Victory ═══
@onready var retry_button: Button = %RetryButton

# ═══ Delegates ═══
var hand_display: RefCounted  # HandDisplay
var hand_interaction: RefCounted  # HandInteraction
var deck_viewer_ctrl: DeckViewerController

const ABILITY_SLOT_SCENE: PackedScene = preload("res://scenes/ninking/ability_slot.tscn")


func _ready() -> void:
	# Set up hand display (rendering)
	hand_display = HandDisplay.new()
	hand_display.setup(
		head_cards, middle_cards, tail_cards,
		head_type_label, middle_type_label, tail_type_label,
		chips_label, mult_label, dun_type_row,
		play_btn, redraw_btn, status_label
	)

	# Set up hand interaction (swap/redraw state machine)
	hand_interaction = HandInteraction.new()
	hand_interaction.setup(hand_display)

	# Deck viewer
	deck_viewer_ctrl = DeckViewerController.new()
	deck_viewer_ctrl.setup(
		%DeckBtn, %DeckViewer, %CloseBtn,
		%DrawCountLabel, %DiscardCountLabel,
		%CardGrid, %ViewerBg
	)

	# ── Three-Dun title progressive outline (V20) ──
	# 影 (head): subtle shadow → 瞬 (middle): standard → 滅 (tail): bold glow
	head_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.3))
	head_label.add_theme_font_size_override("font_outline_size", 1)
	middle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	middle_label.add_theme_font_size_override("font_outline_size", 2)
	tail_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	tail_label.add_theme_font_size_override("font_outline_size", 3)


# ══════════════════════════════════════════
# View switching
# ══════════════════════════════════════════

func show_view(view: String) -> void:
	main_menu.visible = (view == "menu")
	game_bg.visible = (view in ["game", "intro", "scoring"])
	level_intro.visible = (view == "intro")
	game_layout.visible = (view in ["game", "scoring"])
	scoring_overlay.visible = (view == "scoring")
	level_complete.visible = (view == "complete")
	game_over.visible = (view in ["gameover", "victory"])


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
	hands_label.text = "出牌 %d" % plays_left
	redraws_label.text = "手替え %d" % redraws_left


func update_target(target: int) -> void:
	target_score_label.text = "封印 %d" % target


# ══════════════════════════════════════════
# Hand display — thin wrappers to HandDisplay + HandInteraction
# ══════════════════════════════════════════

func refresh_hand(hand: Array[CardData.PlayingCard]) -> void:
	hand_interaction.set_hand(hand)
	hand_display.refresh(hand, hand_interaction.swap_source_idx, hand_interaction.redraw_targets, hand_interaction.redraw_mode, _on_ninking_card_clicked, _on_ninking_card_dragged)


func refresh_groups(head_cards_arr: Array[CardData.PlayingCard], mid_cards_arr: Array[CardData.PlayingCard], tail_cards_arr: Array[CardData.PlayingCard], _constraint_ok: bool) -> void:
	var combined: Array[CardData.PlayingCard] = []
	combined.append_array(head_cards_arr)
	combined.append_array(mid_cards_arr)
	combined.append_array(tail_cards_arr)
	hand_interaction.set_hand(combined)
	hand_display.refresh(combined, hand_interaction.swap_source_idx, hand_interaction.redraw_targets, hand_interaction.redraw_mode, _on_ninking_card_clicked, _on_ninking_card_dragged)


# ══════════════════════════════════════════
# Card interaction — delegated to HandInteraction
# ══════════════════════════════════════════

## Expose redraw_mode for game_manager.gd to check before play/redraw toggle.
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
	status_label.text = "点击1~3张要手替え的牌，再点确认"
	hand_interaction.set_cards_interactable(head_cards, middle_cards, tail_cards, false)
	_update_redraw_button_text()


func confirm_redraw() -> void:
	if hand_interaction.redraw_targets.is_empty():
		return
	if _redraw_vfx_guard:
		return
	_redraw_vfx_guard = true
	_run_redraw_with_vfx()

var _redraw_vfx_guard: bool = false

## Animate discarded cards out (fade_out + smoke dust) → redraw → new cards pop in.
func _run_redraw_with_vfx() -> void:
	var targets: Array[int] = hand_interaction.redraw_targets.duplicate()

	for idx: int in targets:
		var card_node: Node = _get_card_node_at_index(idx)
		if card_node:
			GlobalTweens.fade_out(card_node, 0.15)
			GlobalTweens.burst_particles(card_node.global_position + card_node.size * 0.5, "dust")

	await get_tree().create_timer(0.18).timeout

	hand_interaction.confirm_redraw()
	play_btn.disabled = false
	redraw_btn.text = "手\n替"
	status_label.text = ""
	hand_interaction.set_cards_interactable(head_cards, middle_cards, tail_cards, true)
	_redraw_vfx_guard = false

func _get_card_node_at_index(idx: int) -> Node:
	var hand: Hand
	var local_idx: int
	if idx < 3:
		hand = head_cards
		local_idx = idx
	elif idx < 6:
		hand = middle_cards
		local_idx = idx - 3
	else:
		hand = tail_cards
		local_idx = idx - 6
	var cards_node: Node = hand.get_node_or_null("Cards")
	if cards_node and local_idx < cards_node.get_child_count():
		return cards_node.get_child(local_idx)
	return null


func _update_redraw_button_text() -> void:
	if hand_interaction.redraw_mode:
		redraw_btn.text = "手替え(%d/3)" % hand_interaction.redraw_targets.size()


# ══════════════════════════════════════════
# Ninja bar
# ══════════════════════════════════════════

func refresh_ninjas(owned_ninjas: Array, max_slots: int) -> void:
	for child: Node in ability_bar.get_children():
		child.queue_free()
	for ninja: Dictionary in owned_ninjas:
		var slot: Panel = ABILITY_SLOT_SCENE.instantiate()
		var label: Label = slot.get_node_or_null("Label")
		if label != null:
			label.text = ninja["name"]
		ability_bar.add_child(slot)
	var empty: int = max_slots - owned_ninjas.size()
	for _i: int in range(empty):
		var slot: Panel = ABILITY_SLOT_SCENE.instantiate()
		var label: Label = slot.get_node_or_null("Label")
		if label != null:
			label.text = "空"
		ability_bar.add_child(slot)


# ══════════════════════════════════════════
# Seal complete
# ══════════════════════════════════════════

func set_level_complete(gold_reward: int) -> void:
	reward_label.text = "+%d 金币" % gold_reward


# ══════════════════════════════════════════
# Xi popup
# ══════════════════════════════════════════

func show_xi_popup(xis: Array[String]) -> void:
	var text: String = "喜触发: " + ", ".join(xis)
	score_breakdown.text = text


# ══════════════════════════════════════════
# Card flash — A7 group reveal
# ══════════════════════════════════════════

func flash_all_hand_cards() -> void:
	_flash_hand(head_cards)
	_flash_hand(middle_cards)
	_flash_hand(tail_cards)


func _flash_hand(hand: Hand) -> void:
	var cards_node: Node = hand.get_node_or_null("Cards")
	if cards_node == null:
		return
	for card_node: Node in cards_node.get_children():
		if card_node is CanvasItem:
			GlobalTweens.color_flash(card_node, Color(1.0, 0.843, 0.0, 1.0), 0.1)


# ══════════════════════════════════════════
# Scoring result
# ══════════════════════════════════════════

func show_scoring_result(head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult, tail_eval: HandEvaluator3.EvalResult, total_score: int) -> void:
	var text: String = "影: %s | 瞬: %s | 滅: %s" % [
		CardData.get_hand_type3_name(head_eval.hand_type),
		CardData.get_hand_type3_name(mid_eval.hand_type),
		CardData.get_hand_type3_name(tail_eval.hand_type)
	]
	hand_name_label.text = text
	score_value_label.text = "+ %d" % total_score
	score_breakdown.text = ""


# ══════════════════════════════════════════
# Restore UI state (after scene reload)
# ══════════════════════════════════════════

func restore_ui_state() -> void:
	var gs = NinKingGameState
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
# Deck display (delegated to DeckViewerController)
# ══════════════════════════════════════════

func update_deck_count(draw_count: int, discard_count: int) -> void:
	deck_viewer_ctrl.update_deck_count(draw_count, discard_count)
