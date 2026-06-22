class_name UIManager
extends Control

## Centralized UI management for NinKing (忍者牌 比鸡).
## Delegates to HandDisplay, DeckViewerController,
## DunHighlighter, ResultScreenDisplay, NinjaBarNode (preloaded).
## All display updates go through this class game_manager.gd only handles flow.
## NinjaBarNode loaded dynamically (avoids editor cache conflicts).


# ═══ Sub-views ═══
@onready var level_intro: Control = %LevelIntro
@onready var game_layout: Control = %GameLayout
@onready var game_bg: TextureRect = %GameBg
@onready var scoring_overlay: Control = %ScoringOverlay
@onready var game_over: Control = %GameOver
@onready var shop_overlay: Control = %ShopOverlay  # Phase C 🏪
@onready var settlement_overlay: SettlementCard = %SettlementOverlay  # Phase E 🎴

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

# Preloaded boss portrait textures (loaded once at class load time)
static var _boss_texture_cache: Dictionary = {}
static var _boss_cache_ready: bool = false

static func _ensure_boss_cache() -> void:
	if _boss_cache_ready:
		return
	for boss_name: String in BOSS_PORTRAITS:
		_boss_texture_cache[boss_name] = load(BOSS_PORTRAITS[boss_name])
	_boss_cache_ready = true

# ═══ Left panel ═══
@onready var left_panel: Control = %LeftPanel
@onready var panel_bg: ColorRect = %PanelBg
@onready var col_xi_label: Label = %ColXiLabel

func update_xi_display(text: String) -> void:
	col_xi_label.text = text
	col_xi_label.visible = (text != "" and text != "喜: -")
	# Label is inside ScoreVBox; VBox handles height adjustment automatically


@onready var shadow_type_label: Label = %ShadowType
@onready var flash_type_label: Label = %FlashType
@onready var destroy_type_label: Label = %DestroyType
@onready var shadow_score_label: RichTextLabel = %ShadowScore
@onready var flash_score_label: RichTextLabel = %FlashScore
@onready var destroy_score_label: RichTextLabel = %DestroyScore
@onready var shadow_lv_label: Label = %ShadowLv
@onready var flash_lv_label: Label = %FlashLv
@onready var destroy_lv_label: Label = %DestroyLv

# ═══ Column row labels ═══
@onready var left_col_label: Label = %LeftColLabel
@onready var left_col_type: Label = %LeftColType
@onready var left_col_score: RichTextLabel = %LeftColScore
@onready var left_col_lv: Label = %LeftColLv
@onready var mid_col_label: Label = %MidColLabel
@onready var mid_col_type: Label = %MidColType
@onready var mid_col_score: RichTextLabel = %MidColScore
@onready var mid_col_lv: Label = %MidColLv
@onready var right_col_label: Label = %RightColLabel
@onready var right_col_type: Label = %RightColType
@onready var right_col_score: RichTextLabel = %RightColScore
@onready var right_col_lv: Label = %RightColLv

@onready var score_label: Label = %ScoreLabel
@onready var target_score_label: Label = %TargetScoreLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var hands_label: Label = %HandsLabel
@onready var gold_label: Label = %GoldLabel
@onready var barrier_label: Label = %BarrierLabel
@onready var round_label: Label = %RoundLabel

# ═══ Ninja bar ═══
@onready var ninja_bar_wrapper: Control = %NinjaBar

# ═══ Center ═══
@onready var status_label: Label = %StatusLabel
@onready var deck_btn: Button = %DeckBtn
@onready var hand_area: HBoxContainer = %HandArea
@onready var card_grid: HandCardContainer = %CardGrid
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

var deck_viewer_ctrl: DeckViewerController
var dun_highlighter: DunHighlighter
var result_screen: ResultScreenDisplay
var ninja_bar: NinjaBarNode


func _ready() -> void:
	# Hand display (rendering)
	hand_display = HandDisplay.new()
	hand_display.setup(
		card_grid,
		head_type_label, middle_type_label, tail_type_label,
		col0_label, col1_label, col2_label, col_xi_label,
		shadow_type_label, flash_type_label, destroy_type_label,
		shadow_score_label, flash_score_label, destroy_score_label,
		shadow_lv_label, flash_lv_label, destroy_lv_label,
		left_col_label, mid_col_label, right_col_label,
		left_col_type, mid_col_type, right_col_type,
		left_col_score, mid_col_score, right_col_score,
		left_col_lv, mid_col_lv, right_col_lv,
		play_btn, status_label
	)

	# Deck viewer
	deck_viewer_ctrl = DeckViewerController.new()
	deck_viewer_ctrl.setup(
		%DeckBtn, %DeckViewer, %CloseBtn,
		%DrawCountLabel,
		%DeckCardGrid, %ViewerBg
	)

	# Dun highlighter (constraint visualization + card flash)
	dun_highlighter = DunHighlighter.new()
	dun_highlighter.setup(
		head_label, middle_label, tail_label, status_label,
		card_grid
	)

	# Result screen display (scoring / victory / gameover / xi)
	result_screen = ResultScreenDisplay.new()
	result_screen.setup(
		victory_label, victory_stats_summary,
		game_over_label, score_summary,
		hand_name_label, score_value_label, score_breakdown
	)

	# Ninja bar  CardContainer + manager Node
	var bar_container := NinjaBarContainer.new()
	ninja_bar_wrapper.add_child(bar_container)
	ninja_bar = NinjaBarNode.new()
	ninja_bar.set_container(bar_container)
	ninja_bar_wrapper.add_child(ninja_bar)

	# ── Three-Dun title progressive outline (V20) ──
	head_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.3))
	head_label.add_theme_constant_override("font_outline_size", 1)
	middle_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
	middle_label.add_theme_constant_override("font_outline_size", 2)
	tail_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	tail_label.add_theme_constant_override("font_outline_size", 3)

	status_label.text = ""

	# ── ColXiLabel autowrap (inside ScoreVBox, VBox handles layout) ──
	col_xi_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# ══════════════════════════════════════════
# View switching
# ══════════════════════════════════════════

func show_view(view: String) -> void:
	game_bg.visible = (view in ["game", "intro", "scoring", "shop", "settlement"])
	level_intro.visible = (view == "intro")
	game_layout.visible = (view in ["game", "scoring"])
	shop_overlay.visible = (view == "shop")
	game_over.visible = (view == "gameover")
	victory_overlay.visible = (view == "victory")
	settlement_overlay.visible = (view == "settlement")
	# CardGrid is a sibling of UIManager at z_index=10, so it renders above
	# all UIManager children. Hide during overlay views so cards don't block
	# clicks to buttons (e.g. RetryButton on GameOver screen).
	card_grid.visible = (view in ["game", "scoring"])


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
	panel.reroll_requested.connect(_on_shop_reroll_requested)
	panel.continue_requested.connect(_on_shop_continue_requested)

	show_view("shop")
	MusicManager.play_shop_bgm()
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


# 🏪 Shop signal relay  game_manager connects to these
signal shop_purchase_requested(ability_data: Dictionary)
signal shop_item_purchase_requested(item_data: Dictionary)
signal shop_reroll_requested()
signal shop_continue_requested()

func _on_shop_purchase_requested(data: Dictionary) -> void:
	shop_purchase_requested.emit(data)

func _on_shop_item_purchase_requested(data: Dictionary) -> void:
	shop_item_purchase_requested.emit(data)

func _on_shop_reroll_requested() -> void:
	shop_reroll_requested.emit()

func _on_shop_continue_requested() -> void:
	shop_continue_requested.emit()


# ══════════════════════════════════════════
# Seal intro
# ══════════════════════════════════════════

func on_seal_start(barrier: int, seal_idx: int, target: int, seal_lord_name: String) -> void:
	clear_score_formula()
	var seal_names: Array = ["修羅ノ封印", "明王ノ封印", "夜叉ノ封印"]
	var seal_str: String = seal_names[seal_idx] if seal_idx < 3 else "?"
	intro_level_label.text = "結界%d · %s" % [barrier, seal_str]
	if seal_lord_name != "":
		intro_target_label.text = "封印 %d | 封印ノ主: %s" % [target, seal_lord_name]
		if BOSS_PORTRAITS.has(seal_lord_name):
			_ensure_boss_cache()
			boss_portrait.texture = _boss_texture_cache[seal_lord_name]
			boss_portrait.visible = true
	else:
		intro_target_label.text = "封印 %d" % target
		boss_portrait.visible = false

	update_score(0, target)
	update_target(target)
	update_match_info(3)
	update_gold(NinKingGameState.gold)


# ══════════════════════════════════════════
# Left panel  formula display
# ══════════════════════════════════════════

var _score_subtotal: int = 0
var _score_xi: int = 0


func set_score_formula(subtotal: int, xi_val: int) -> void:
	_score_subtotal = subtotal
	_score_xi = xi_val
	_refresh_score_label()


func clear_score_formula() -> void:
	_score_subtotal = 0
	_score_xi = 0
	_refresh_score_label()


func _refresh_score_label() -> void:
	if _score_xi > 1:
		var displayed_total: int = _score_subtotal * _score_xi
		score_label.text = "%d x %d = %d" % [_score_subtotal, _score_xi, displayed_total]
	else:
		score_label.text = "%d" % _score_subtotal


func update_score(current: int, target: int) -> void:
	# If formula hasn't been set by animation yet, init subtotal from current score
	if _score_subtotal == 0 and _score_xi == 0:
		_score_subtotal = current
	_refresh_score_label()
	progress_bar.max_value = float(target)
	progress_bar.value = float(current)


func update_gold(amount: int) -> void:
	gold_label.text = "$%d" % amount


func update_match_info(plays_left: int) -> void:
	hands_label.text = "討伐 %d" % plays_left


func update_target(target: int) -> void:
	target_score_label.text = "封印 %d" % target


# ══════════════════════════════════════════
# Hand display  thin wrappers to HandDisplay
# ══════════════════════════════════════════

func _refresh_internal(hand: Array[CardData.PlayingCard]) -> void:
	hand_display.refresh(hand)
	hand_display.update_labels(hand)
	dun_highlighter.update(NinKingGameState.current_arrangement, NinKingGameState.current_seal_lord_effects.get("constraint", "ascending"))
	play_btn.disabled = not NinKingGameState.is_constraint_satisfied()


func refresh_hand(hand: Array[CardData.PlayingCard]) -> void:
	_refresh_internal(hand)


## Called after two cards swap  animate in-place, no full rebuild.
func on_cards_swapped(src: int, tgt: int) -> void:
	card_grid.swap_two_cards(src, tgt)
	hand_display.update_labels(NinKingGameState.hand)
	dun_highlighter.update(NinKingGameState.current_arrangement, NinKingGameState.current_seal_lord_effects.get("constraint", "ascending"))
	play_btn.disabled = not NinKingGameState.is_constraint_satisfied()


# ══════════════════════════════════════════
# Ninja bar  delegated to NinjaBarDisplay
# ══════════════════════════════════════════

func refresh_ninjas(owned_ninjas: Array, max_slots: int, use_dissolve: bool = false) -> void:
	ninja_bar.refresh(owned_ninjas, max_slots, use_dissolve)


func pulse_ninja_bar() -> void:
	ninja_bar.pulse_cards()


# ══════════════════════════════════════════
# Result screens  delegated to ResultScreenDisplay
# ══════════════════════════════════════════

func set_victory(barrier: int, score: int) -> void:
	result_screen.set_victory(barrier, score)


func show_game_over(reason: String, barrier: int, score: int) -> void:
	result_screen.show_game_over(reason, barrier, score)


func show_xi_popup(xis: Array[String]) -> void:
	result_screen.show_xi_popup(xis)


func show_scoring_result(head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult, tail_eval: HandEvaluator3.EvalResult, total_score: int) -> void:
	result_screen.show_scoring_result(head_eval, mid_eval, tail_eval, total_score)


# ══════════════════════════════════════════
# Card flash  delegated to DunHighlighter
# ══════════════════════════════════════════

func flash_all_hand_cards() -> void:
	dun_highlighter.flash_all_hands()


func flash_row(row: int) -> void:
	dun_highlighter.flash_row(row)


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
		deck_viewer_ctrl.update_deck_count(dm.draw_pile.size())


# ══════════════════════════════════════════
# Deck display  delegated to DeckViewerController
# ══════════════════════════════════════════

func update_deck_count(draw_count: int) -> void:
	deck_viewer_ctrl.update_deck_count(draw_count)
