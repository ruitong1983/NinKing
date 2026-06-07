class_name UIManager
extends Node

## Centralized UI management for PokingMain.
## All display updates go through this class — game_manager.gd only handles flow.

# ── Sub-views ──
@onready var main_menu: Control = %MainMenu
@onready var level_intro: Control = %LevelIntro
@onready var game_layout: VBoxContainer = %GameLayout
@onready var game_bg: TextureRect = %GameBg
@onready var scoring_overlay: Control = %ScoringOverlay
@onready var level_complete: Control = %LevelComplete
@onready var game_over: Control = %GameOver

# ── Menu ──
@onready var start_button: Button = %StartButton
@onready var deck_label: Label = %DeckLabel

# ── Level intro ──
@onready var intro_level_label: Label = %LevelLabel
@onready var intro_target_label: Label = %TargetLabel

# ── Left panel ──
@onready var hand_type_label: Label = %HandTypeLabel
@onready var chips_label: Label = %ChipsLabel
@onready var mult_label: Label = %MultLabel
@onready var score_label: Label = %ScoreLabel
@onready var target_score_label: Label = %TargetScoreLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var hands_label: Label = %HandsLabel
@onready var discards_label: Label = %DiscardsLabel
@onready var gold_label: Label = %GoldLabel
@onready var ante_label: Label = %AnteLabel
@onready var round_label: Label = %RoundLabel

# ── Joker bar ──
@onready var joker_container: HBoxContainer = %JokerContainer

# ── Center ──
@onready var status_label: Label = %StatusLabel
@onready var action_bar: HBoxContainer = %ActionBar
@onready var play_button: Button = %PlayButton
@onready var swap_btn: Button = %SwapBtn
@onready var cards_grid: HBoxContainer = %CardsGrid

# ── Scoring overlay ──
@onready var hand_name_label: Label = %HandNameLabel
@onready var score_value_label: Label = %ScoreValueLabel
@onready var score_breakdown: Label = %ScoreBreakdown

# ── Level complete ──
@onready var complete_label: Label = %CompleteLabel
@onready var reward_label: Label = %RewardLabel
@onready var to_shop_button: Button = %ToShopButton

# ── Game over ──
@onready var retry_button: Button = %RetryButton

const CARD_BUTTON_SCENE: PackedScene = preload("res://scenes/poking/card_button.tscn")
const JOKER_SLOT_SCENE: PackedScene = preload("res://scenes/poking/joker_slot.tscn")

var selected_indices: Array[int] = []
var _current_hand: Array = []


# ── View switching ──

func show_view(view: String) -> void:
	main_menu.visible = (view == "menu")
	game_bg.visible = (view == "game" or view == "intro" or view == "scoring")
	level_intro.visible = (view == "intro")
	game_layout.visible = (view == "game")
	scoring_overlay.visible = (view == "scoring")
	level_complete.visible = (view == "complete")
	game_over.visible = (view == "gameover")


# ── Intro ──

func set_intro(level_num: int, target: int) -> void:
	intro_level_label.text = "第 %d 关" % level_num
	intro_target_label.text = "目标: %d 分" % target


# ── Left panel info ──

func update_score(current: int, target: int) -> void:
	score_label.text = "回合得分: %d" % current
	progress_bar.max_value = float(target)
	progress_bar.value = float(current)


func update_gold(amount: int) -> void:
	gold_label.text = "$%d" % amount


func update_match_info(swaps_remaining: int, level_num: int) -> void:
	hands_label.text = "出牌 %d" % (5 - swaps_remaining)
	discards_label.text = "弃牌 0"
	round_label.text = "回合 %d" % level_num


func update_ante(level_num: int) -> void:
	ante_label.text = "底注 %d/8" % level_num


func update_target(target: int) -> void:
	target_score_label.text = "目标: %d" % target


# ── Hand type preview ──

func update_hand_type_preview(hand: Array, indices: Array[int]) -> void:
	if indices.size() != 5:
		hand_type_label.text = ""
		chips_label.text = "0"
		mult_label.text = "0"
		return

	var preview_cards: Array[CardData.Card] = []
	for i: int in indices:
		preview_cards.append(hand[i])

	var eval: HandEvaluator.EvalResult = HandEvaluator.evaluate(preview_cards)
	hand_type_label.text = CardData.get_hand_type_name(eval.hand_type)
	chips_label.text = str(eval.base_chips)
	mult_label.text = str(eval.base_mult)


func clear_hand_type_preview() -> void:
	hand_type_label.text = ""
	chips_label.text = "0"
	mult_label.text = "0"


# ── Level complete / game over ──

func set_level_complete(gold_reward: int) -> void:
	reward_label.text = "+%d 金币" % gold_reward


# ── Action bar ──

func update_action_bar() -> void:
	var has: bool = not selected_indices.is_empty()
	action_bar.visible = has
	play_button.disabled = (selected_indices.size() != 5)


func hide_action_bar() -> void:
	action_bar.visible = false


# ── Selection ──

func clear_selection() -> void:
	selected_indices.clear()
	action_bar.visible = false
	clear_hand_type_preview()


func toggle_card_selection(idx: int, btn: Button) -> void:
	if idx in selected_indices:
		selected_indices.erase(idx)
		btn.modulate = Color.WHITE
	else:
		if selected_indices.size() >= 5:
			return
		selected_indices.append(idx)
		btn.modulate = Color(1.0, 0.5, 0.5)
	update_action_bar()
	update_hand_type_preview(_current_hand, selected_indices)


# ── Hand (cards) ──

func refresh_hand(hand: Array) -> void:
	_current_hand = hand
	for child: Node in cards_grid.get_children():
		child.queue_free()

	for i: int in range(hand.size()):
		var card: CardData.Card = hand[i]
		var btn: Button = CARD_BUTTON_SCENE.instantiate()
		btn.text = card.get_display_name()
		btn.name = "CardBtn_%d" % i
		btn.custom_minimum_size = Vector2(90, 130)

		if i in selected_indices:
			btn.modulate = Color(1.0, 0.5, 0.5)

		var card_idx: int = i
		btn.pressed.connect(func(): toggle_card_selection(card_idx, btn))

		cards_grid.add_child(btn)


# ── Jokers ──

func refresh_jokers(owned_jokers: Array, max_slots: int) -> void:
	for child: Node in joker_container.get_children():
		child.queue_free()

	for joker: Dictionary in owned_jokers:
		var slot: Panel = JOKER_SLOT_SCENE.instantiate()
		var label: Label = slot.get_node_or_null("Label")
		if label != null:
			label.text = joker["name"]
		joker_container.add_child(slot)

	var empty: int = max_slots - owned_jokers.size()
	for _i: int in range(empty):
		var slot: Panel = JOKER_SLOT_SCENE.instantiate()
		var label: Label = slot.get_node_or_null("Label")
		if label != null:
			label.text = "空"
		joker_container.add_child(slot)


# ── Restore full state ──

func restore_ui_state() -> void:
	var gs = PokingGameState
	set_intro(gs.level, gs.target_score)
	update_score(gs.current_score, gs.target_score)
	update_target(gs.target_score)
	update_match_info(gs.swaps_remaining, gs.level)
	update_gold(gs.gold)
	update_ante(gs.level)
	refresh_hand(gs.hand)
	refresh_jokers(gs.owned_jokers, gs.max_joker_slots)


# ── Level start ──

func on_level_start(level_num: int, target: int) -> void:
	set_intro(level_num, target)
	update_score(0, target)
	update_target(target)
	update_match_info(5, level_num)
	update_gold(PokingGameState.gold)
	update_ante(level_num)
	clear_hand_type_preview()
