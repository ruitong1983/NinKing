class_name HandTypeLabeler
extends RefCounted

## Updates all hand-type text labels + Lv badges.
##
## Lv badges show star chart level per hand type with color tiers:
##   Lv.1-2 gray | Lv.3-4 blue | Lv.5-6 gold
## Hover over Lv badge shows detail tooltip (hand type name + level + chips/mult).
## Phase 1 scoring animation also flashes the Lv badge via animation_handler.

var _head_type_label: Label
var _mid_type_label: Label
var _tail_type_label: Label
var _col_xi_label: Label
var _shadow_type_label: Label
var _flash_type_label: Label
var _destroy_type_label: Label
var _shadow_score_label: Label
var _flash_score_label: Label
var _destroy_score_label: Label
var _shadow_lv_label: Label
var _flash_lv_label: Label
var _destroy_lv_label: Label
var _col0_label: Label
var _col1_label: Label
var _col2_label: Label
var _play_btn: Button

# Lv badge color tiers (matches ScoreCard existing palette)
const LV_COLORS: Dictionary = {
	1: Color("#7A7A7A"),  # Lv.1-2: gray (TargetScoreLabel)
	2: Color("#7A7A7A"),
	3: Color("#588CF2"),  # Lv.3-4: blue (ShadowDun)
	4: Color("#588CF2"),
	5: Color("#C4A843"),  # Lv.5-6: gold (ColXiLabel / ScoreCard accent)
	6: Color("#C4A843"),
}

# Current hand types per row (updated every label refresh)
var _current_head_ht: int = -1
var _current_mid_ht: int = -1
var _current_tail_ht: int = -1

# Hover tooltip
var _active_tooltip: Control = null
var _pending_hover_row: int = -1


func setup(
	head_type: Label,
	mid_type: Label,
	tail_type: Label,
	col0: Label,
	col1: Label,
	col2: Label,
	col_xi: Label,
	shadow_type: Label,
	flash_type: Label,
	destroy_type: Label,
	shadow_score: Label,
	flash_score: Label,
	destroy_score: Label,
	shadow_lv: Label,
	flash_lv: Label,
	destroy_lv: Label,
	play: Button,
) -> void:
	_head_type_label = head_type
	_mid_type_label = mid_type
	_tail_type_label = tail_type
	_col0_label = col0
	_col1_label = col1
	_col2_label = col2
	_col_xi_label = col_xi
	_shadow_type_label = shadow_type
	_flash_type_label = flash_type
	_destroy_type_label = destroy_type
	_shadow_score_label = shadow_score
	_flash_score_label = flash_score
	_destroy_score_label = destroy_score
	_shadow_lv_label = shadow_lv
	_flash_lv_label = flash_lv
	_destroy_lv_label = destroy_lv
	_play_btn = play

	# Wire hover signals for Lv badges (one-time setup)
	_setup_lv_hover(shadow_lv, 0)
	_setup_lv_hover(flash_lv, 1)
	_setup_lv_hover(destroy_lv, 2)


## Clear all labels to default state.
func reset_labels() -> void:
	_head_type_label.text = ""
	_mid_type_label.text = ""
	_tail_type_label.text = ""
	_col_xi_label.text = ""
	_shadow_type_label.text = "-"
	_flash_type_label.text = "-"
	_destroy_type_label.text = "-"
	_shadow_score_label.text = ""
	_flash_score_label.text = ""
	_destroy_score_label.text = ""
	_shadow_lv_label.text = ""
	_shadow_lv_label.visible = false
	_flash_lv_label.text = ""
	_flash_lv_label.visible = false
	_destroy_lv_label.text = ""
	_destroy_lv_label.visible = false
	_col0_label.text = ""
	_col0_label.visible = false
	_col1_label.text = ""
	_col1_label.visible = false
	_col2_label.text = ""
	_col2_label.visible = false


## Update all labels for the current 9-card hand.
func update_all(hand: Array[CardData.PlayingCard]) -> void:
	if hand.size() < 9:
		return
	_update_dun_types(hand)
	_update_column_types(hand)
	_update_col_xi_preview(hand)


# ══════════════════════════════════════════
# Dun type labels — 影 / 瞬 / 滅
# ══════════════════════════════════════════

## Update per-dun type names, base score preview, and Lv badges.
func _update_dun_types(hand: Array[CardData.PlayingCard]) -> void:
	var head_cards := hand.slice(0, 3)
	var mid_cards := hand.slice(3, 6)
	var tail_cards := hand.slice(6, 9)
	var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_cards)
	var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_cards)
	var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_cards)
	var head_name: String = CardData.get_hand_type3_name(head_eval.hand_type)
	var mid_name: String = CardData.get_hand_type3_name(mid_eval.hand_type)
	var tail_name: String = CardData.get_hand_type3_name(tail_eval.hand_type)
	_head_type_label.text = head_name
	_mid_type_label.text = mid_name
	_tail_type_label.text = tail_name

	# Store current hand types for hover tooltip lookup
	_current_head_ht = head_eval.hand_type
	_current_mid_ht = mid_eval.hand_type
	_current_tail_ht = tail_eval.hand_type

	# Per-dun score preview: (card_chips + hand_chips) × hand_mult
	var levels: Dictionary = NinKingGameState.star_chart_levels
	var head_chips: int = CardData.get_hand_type3_leveled_chips(head_eval.hand_type, levels)
	var mid_chips: int = CardData.get_hand_type3_leveled_chips(mid_eval.hand_type, levels)
	var tail_chips: int = CardData.get_hand_type3_leveled_chips(tail_eval.hand_type, levels)
	var head_mult: int = CardData.get_hand_type3_leveled_mult(head_eval.hand_type, levels)
	var mid_mult: int = CardData.get_hand_type3_leveled_mult(mid_eval.hand_type, levels)
	var tail_mult: int = CardData.get_hand_type3_leveled_mult(tail_eval.hand_type, levels)
	var head_card_chips := 0
	var mid_card_chips := 0
	var tail_card_chips := 0
	for c: CardData.PlayingCard in head_cards:
		head_card_chips += c.get_chip_value()
	for c: CardData.PlayingCard in mid_cards:
		mid_card_chips += c.get_chip_value()
	for c: CardData.PlayingCard in tail_cards:
		tail_card_chips += c.get_chip_value()

	# Row 1: 影
	_shadow_type_label.text = head_name
	_shadow_score_label.text = "%d×%d" % [head_card_chips + head_chips, head_mult]
	_update_lv_badge(_shadow_lv_label, _current_head_ht, levels)

	# Row 2: 瞬
	_flash_type_label.text = mid_name
	_flash_score_label.text = "%d×%d" % [mid_card_chips + mid_chips, mid_mult]
	_update_lv_badge(_flash_lv_label, _current_mid_ht, levels)

	# Row 3: 滅
	_destroy_type_label.text = tail_name
	_destroy_score_label.text = "%d×%d" % [tail_card_chips + tail_chips, tail_mult]
	_update_lv_badge(_destroy_lv_label, _current_tail_ht, levels)


## Update a single Lv badge label: text, color tier, and visibility.
func _update_lv_badge(lv_label: Label, hand_type: int, levels: Dictionary) -> void:
	var lvl: int = levels.get(hand_type, 0)
	if lvl <= 0:
		lv_label.text = ""
		lv_label.visible = false
		return

	lv_label.text = "Lv.%d" % lvl
	lv_label.visible = true
	var color: Color = LV_COLORS.get(lvl, Color(0.7, 0.7, 0.7))
	lv_label.add_theme_color_override("font_color", color)


# ══════════════════════════════════════════
# Lv badge hover tooltip
# ══════════════════════════════════════════

## Wire hover signals for one Lv badge (called once per badge in setup).
func _setup_lv_hover(lv_label: Label, row_idx: int) -> void:
	lv_label.mouse_entered.connect(_on_lv_hover_enter.bind(row_idx))
	lv_label.mouse_exited.connect(_on_lv_hover_exit)


func _on_lv_hover_enter(row_idx: int) -> void:
	_dismiss_tooltip()
	_pending_hover_row = row_idx
	# Small delay to prevent flicker when crossing between elements
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var tw: SceneTreeTimer = tree.create_timer(0.15)
	tw.timeout.connect(_on_hover_delay_ended.bind(row_idx), CONNECT_ONE_SHOT)


func _on_lv_hover_exit() -> void:
	_pending_hover_row = -1
	_dismiss_tooltip()


func _on_hover_delay_ended(row_idx: int) -> void:
	if _pending_hover_row != row_idx:
		return
	_pending_hover_row = -1
	_show_lv_tooltip(row_idx)


## Build and show the tooltip for a given row's hand type.
func _show_lv_tooltip(row_idx: int) -> void:
	var hand_type: int
	var lv_label: Label
	match row_idx:
		0:
			hand_type = _current_head_ht
			lv_label = _shadow_lv_label
		1:
			hand_type = _current_mid_ht
			lv_label = _flash_lv_label
		_:
			hand_type = _current_tail_ht
			lv_label = _destroy_lv_label

	if hand_type < 0 or not is_instance_valid(lv_label):
		return

	var levels: Dictionary = NinKingGameState.star_chart_levels
	var lvl: int = levels.get(hand_type, 0)
	if lvl <= 0:
		return

	var ht_name: String = CardData.get_hand_type3_name(hand_type as CardData.HandType3)
	var total_chips: int = CardData.get_hand_type3_leveled_chips(hand_type, levels)
	var total_mult: int = CardData.get_hand_type3_leveled_mult(hand_type, levels)
	var tier_color: Color = LV_COLORS.get(lvl, Color(0.8, 0.8, 0.8))

	# ── Build tooltip Control ──
	var tooltip := Control.new()
	tooltip.name = "LvTooltip"
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Panel background
	var panel_bg := Panel.new()
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	bg_style.set_corner_radius_all(4)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = tier_color
	bg_style.border_color.a = 0.4
	panel_bg.add_theme_stylebox_override("panel", bg_style)
	panel_bg.size = Vector2(180, 52)
	tooltip.add_child(panel_bg)

	# Title: "对子 Lv.2"
	var title := Label.new()
	title.text = "%s  Lv.%d" % [ht_name, lvl]
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", tier_color)
	title.position = Vector2(10, 6)
	title.size = Vector2(160, 20)
	tooltip.add_child(title)

	# Stats: "筹码 26  倍率 4"
	var stats := Label.new()
	stats.text = "筹码 %d  倍率 %d" % [total_chips, total_mult]
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.85, 0.85, 0.80))
	stats.position = Vector2(10, 28)
	stats.size = Vector2(160, 20)
	tooltip.add_child(stats)

	tooltip.size = Vector2(180, 52)

	# ── Position above-and-right of the badge ──
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	var vp_size: Vector2 = scene_tree.root.get_visible_rect().size
	var pos: Vector2 = Vector2(
		min(lv_label.global_position.x + 8, vp_size.x - tooltip.size.x - 8),
		max(lv_label.global_position.y - tooltip.size.y - 6, 4)
	)
	tooltip.global_position = pos

	# Add to scene tree
	var scene_root: Node = lv_label.get_tree().current_scene
	if scene_root != null:
		scene_root.add_child(tooltip)
	_active_tooltip = tooltip


func _dismiss_tooltip() -> void:
	if _active_tooltip != null and is_instance_valid(_active_tooltip):
		_active_tooltip.queue_free()
	_active_tooltip = null


# ══════════════════════════════════════════
# Column type labels — A9 列牌型名
# ══════════════════════════════════════════

## Update column type name labels below each column in DunArea.
func _update_column_types(hand: Array[CardData.PlayingCard]) -> void:
	var col_labels: Array[Label] = [_col0_label, _col1_label, _col2_label]
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
			hand[i],
			hand[i + 3],
			hand[i + 6]
		]
		var eval_result: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(col_cards)
		var lbl: Label = col_labels[i]
		if int(eval_result.hand_type) >= int(CardData.HandType3.ONE_PAIR_3):
			lbl.text = CardData.get_hand_type3_name(eval_result.hand_type)
			lbl.visible = true
		else:
			lbl.text = ""
			lbl.visible = false


# ══════════════════════════════════════════
# Column + Xi preview
# ══════════════════════════════════════════

## Update top preview: 列: ×N  喜: 名×N  (or 列: ×N  喜: -).
func _update_col_xi_preview(hand: Array[CardData.PlayingCard]) -> void:
	if hand.size() < 9:
		if _col_xi_label and is_instance_valid(_col_xi_label):
			_col_xi_label.text = ""
		return

	# ── Column ×mult preview ──
	var col_x_product: int = 1
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
			hand[i],
			hand[i + 3],
			hand[i + 6]
		]
		var col_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(col_cards)
		var x_val: int = CardData.COL_X_MULT_VALUES.get(col_eval.hand_type, 1)
		if x_val > 1:
			col_x_product *= x_val

	# ── Xi preview ──
	var xi_text: String = "-"
	if NinKingGameState.current_arrangement != null:
		var xi_hc: Array = hand.slice(0, 3)
		var xi_mc: Array = hand.slice(3, 6)
		var xi_tc: Array = hand.slice(6, 9)
		var xi_he = HandEvaluator3.evaluate(xi_hc)
		var xi_me = HandEvaluator3.evaluate(xi_mc)
		var xi_te = HandEvaluator3.evaluate(xi_tc)
		var xi_result: XiDetector.XiResult = XiDetector.detect(xi_hc, xi_mc, xi_tc, xi_he, xi_me, xi_te)
		if xi_result != null and xi_result.has_any():
			var xi_parts: Array[String] = []
			for xi_name: String in xi_result.triggered:
				var is_global: bool = xi_name in ["全黑", "全红", "全顺", "全同花", "四张", "全三条"]
				if is_global:
					var x_val: int = 1
					for defn: Dictionary in XiDetector.XI_DEFINITIONS:
						if defn["name"] == xi_name:
							x_val = defn["x_mult"]
							break
					xi_parts.append("%s×%d" % [xi_name, x_val])
			if xi_parts.size() > 0:
				xi_text = "  ".join(xi_parts)

	# ── Format ──
	var col_str: String = "列: ×%d" % col_x_product if col_x_product > 1 else ""
	if col_str == "":
		if xi_text == "-":
			_col_xi_label.text = ""
			return
		else:
			_col_xi_label.text = xi_text
			return

	_col_xi_label.text = "%s  喜: %s" % [col_str, xi_text]
