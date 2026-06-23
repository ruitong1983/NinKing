class_name HandTypeLabeler
extends RefCounted

## Updates all hand-type text labels + score formulas.
##
## v5: ColXiLabel changed from RichTextLabel to Label, only xi names (no xN).


var _head_type_label: Label
var _mid_type_label: Label
var _tail_type_label: Label
var _col_xi_label: Label
var _shadow_type_label: Label
var _flash_type_label: Label
var _destroy_type_label: Label
var _shadow_score_label: RichTextLabel
var _flash_score_label: RichTextLabel
var _destroy_score_label: RichTextLabel
var _shadow_lv_label: Label
var _flash_lv_label: Label
var _destroy_lv_label: Label
var _col0_label: Label
var _col1_label: Label
var _col2_label: Label
var _play_btn: Button

# Column row labels (v2)
var _left_col_label: Label
var _mid_col_label: Label
var _right_col_label: Label
var _left_col_type: Label
var _mid_col_type: Label
var _right_col_type: Label
var _left_col_score: RichTextLabel
var _mid_col_score: RichTextLabel
var _right_col_score: RichTextLabel
var _left_col_lv: Label
var _mid_col_lv: Label
var _right_col_lv: Label

# Lv color tiers -- darkened for contrast on panel_beigeLight
const LV_COLORS: Dictionary = {
	1: Color("#5C5C5C"),  # Lv.1-2: 深灰 (~5.5:1)
	2: Color("#5C5C5C"),
	3: Color("#3A6FD8"),  # Lv.3-4: 深蓝 (~5.0:1)
	4: Color("#3A6FD8"),
	5: Color("#9A8230"),  # Lv.5-6: 暗金 (~4.5:1)
	6: Color("#9A8230"),
}

# Current hand types per row (updated every label refresh)
var _current_head_ht: int = -1
var _current_mid_ht: int = -1
var _current_tail_ht: int = -1

# Current column hand types (v2)
var _current_left_col_ht: int = -1
var _current_mid_col_ht: int = -1
var _current_right_col_ht: int = -1

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
	shadow_score: RichTextLabel,
	flash_score: RichTextLabel,
	destroy_score: RichTextLabel,
	shadow_lv: Label,
	flash_lv: Label,
	destroy_lv: Label,
	left_col_label: Label,
	mid_col_label: Label,
	right_col_label: Label,
	left_col_type: Label,
	mid_col_type: Label,
	right_col_type: Label,
	left_col_score: RichTextLabel,
	mid_col_score: RichTextLabel,
	right_col_score: RichTextLabel,
	left_col_lv: Label,
	mid_col_lv: Label,
	right_col_lv: Label,
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
	_left_col_label = left_col_label
	_mid_col_label = mid_col_label
	_right_col_label = right_col_label
	_left_col_type = left_col_type
	_mid_col_type = mid_col_type
	_right_col_type = right_col_type
	_left_col_score = left_col_score
	_mid_col_score = mid_col_score
	_right_col_score = right_col_score
	_left_col_lv = left_col_lv
	_mid_col_lv = mid_col_lv
	_right_col_lv = right_col_lv
	_play_btn = play

	# Wire hover signals for formula labels (dun rows) / type labels (column rows)
	_setup_score_hover(shadow_score, 0)
	_setup_score_hover(flash_score, 1)
	_setup_score_hover(destroy_score, 2)
	_setup_score_hover(left_col_type, 3)
	_setup_score_hover(mid_col_type, 4)
	_setup_score_hover(right_col_type, 5)


## Clear all labels to default state.
func reset_labels() -> void:
	_head_type_label.text = ""
	_mid_type_label.text = ""
	_tail_type_label.text = ""
	_col_xi_label.text = "-"
	_col_xi_label.visible = false
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
	# Column rows — only type labels shown when hand type exists
	_left_col_label.visible = false
	_left_col_type.text = ""
	_left_col_type.visible = false
	_left_col_score.visible = false
	_left_col_lv.visible = false
	_mid_col_label.visible = false
	_mid_col_type.text = ""
	_mid_col_type.visible = false
	_mid_col_score.visible = false
	_mid_col_lv.visible = false
	_right_col_label.visible = false
	_right_col_type.text = ""
	_right_col_type.visible = false
	_right_col_score.visible = false
	_right_col_lv.visible = false
	_col0_label.text = ""
	_col0_label.visible = true
	_col1_label.text = ""
	_col1_label.visible = true
	_col2_label.text = ""
	_col2_label.visible = true


## Update all labels for the current 9-card hand.

## Signal handler for card_grid.layout_changed — reads hand from game_state.
func update_from_signal() -> void:
	update_all(NinKingGameState.hand)

func update_all(hand: Array[CardData.PlayingCard]) -> void:
	if hand.size() < 9:
		return
	_update_dun_types(hand)
	_update_column_rows(hand)
	_update_column_types(hand)
	_update_col_xi_preview(hand)


# ══════════════════════════════════════════
# Dun type labels — 影 / 瞬 / 滅
# ══════════════════════════════════════════

## Update per-dun type names and score formula: "牌型 × Lv = 筹码".
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

	# Star chart levels
	var levels: Dictionary = NinKingGameState.star_chart_levels

	# Row 1: 影
	_shadow_type_label.text = head_name
	_write_dun_formula(_shadow_score_label, head_eval.hand_type, levels)

	# Row 2: 瞬
	_flash_type_label.text = mid_name
	_write_dun_formula(_flash_score_label, mid_eval.hand_type, levels)

	# Row 3: 滅
	_destroy_type_label.text = tail_name
	_write_dun_formula(_destroy_score_label, tail_eval.hand_type, levels)


## Write "牌型 × Lv = 筹码" formula to a RichTextLabel using bbcode color.
func _write_dun_formula(score_label: RichTextLabel, hand_type: int, levels: Dictionary) -> void:
	var lvl: int = levels.get(hand_type, 0)
	if lvl <= 0:
		score_label.text = ""
		return
	var type_name: String = CardData.get_hand_type3_name(hand_type as CardData.HandType3)
	var chips: int = CardData.get_hand_type3_leveled_chips(hand_type, levels)
	var color: Color = LV_COLORS.get(lvl, Color(0.7, 0.7, 0.7))
	var color_hex: String = "#%02x%02x%02x" % [int(color.r * 255), int(color.g * 255), int(color.b * 255)]
	score_label.text = "[color=%s]%s × %d = %d[/color]" % [color_hex, type_name, lvl, chips]


# ══════════════════════════════════════════
# Column type rows — 左列 / 中列 / 右列 (v4: types only, no scores / Lv)
# ══════════════════════════════════════════

## Update per-column hand type labels only. Hides labels with no hand type (HIGH_CARD_3).
func _update_column_rows(hand: Array[CardData.PlayingCard]) -> void:
	var col_labels: Array[Label] = [_left_col_type, _mid_col_type, _right_col_type]

	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
			hand[i],
			hand[i + 3],
			hand[i + 6]
		]
		var eval_result: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(col_cards)
		var ht: int = eval_result.hand_type

		# Store current hand type for hover tooltip lookup
		match i:
			0: _current_left_col_ht = ht
			1: _current_mid_col_ht = ht
			2: _current_right_col_ht = ht

		if ht == CardData.HandType3.HIGH_CARD_3:
			col_labels[i].text = ""
			col_labels[i].visible = false
		else:
			col_labels[i].text = CardData.get_hand_type3_name(ht)
			col_labels[i].visible = true


# ══════════════════════════════════════════
# Hover tooltip (on formula / type labels)
# ══════════════════════════════════════════

## Wire hover signals for one score/type label (called once per label in setup).
func _setup_score_hover(target: Control, row_idx: int) -> void:
	target.mouse_entered.connect(_on_lv_hover_enter.bind(row_idx))
	target.mouse_exited.connect(_on_lv_hover_exit)


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
	var anchor: Control
	match row_idx:
		0:
			hand_type = _current_head_ht
			anchor = _shadow_score_label
		1:
			hand_type = _current_mid_ht
			anchor = _flash_score_label
		2:
			hand_type = _current_tail_ht
			anchor = _destroy_score_label
		3:
			hand_type = _current_left_col_ht
			anchor = _left_col_type
		4:
			hand_type = _current_mid_col_ht
			anchor = _mid_col_type
		_:
			hand_type = _current_right_col_ht
			anchor = _right_col_type

	if hand_type < 0 or not is_instance_valid(anchor):
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

	# Panel background (shared style via CardVisualComposer)
	var panel_bg := Panel.new()
	panel_bg.add_theme_stylebox_override("panel", CardVisualComposer.create_tooltip_stylebox(tier_color))
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

	# ── Position above-and-right of the anchor ──
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	var vp_size: Vector2 = scene_tree.root.get_visible_rect().size
	var pos: Vector2 = Vector2(
		min(anchor.global_position.x + 8, vp_size.x - tooltip.size.x - 8),
		max(anchor.global_position.y - tooltip.size.y - 6, 4)
	)
	tooltip.global_position = pos

	# Add to scene tree
	var scene_root: Node = anchor.get_tree().current_scene
	if scene_root != null:
		scene_root.add_child(tooltip)
	_active_tooltip = tooltip


func _dismiss_tooltip() -> void:
	if _active_tooltip != null and is_instance_valid(_active_tooltip):
		_active_tooltip.queue_free()
	_active_tooltip = null


# ══════════════════════════════════════════
# Column type labels — A9 列牌型名 (center DunArea)
# ══════════════════════════════════════════

## Update column type name labels below each column in DunArea.
## Labels stay visible (empty text for HIGH_CARD_3) to preserve
## HBoxContainer column alignment when some columns have no hand type.
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
		lbl.visible = true
		if int(eval_result.hand_type) >= int(CardData.HandType3.ONE_PAIR_3):
			lbl.text = CardData.get_hand_type3_name(eval_result.hand_type)
		else:
			lbl.text = ""


# ══════════════════════════════════════════
# ColXiLabel — xi preview (v5: Label, names only, no xN)
# ══════════════════════════════════════════

## Update top preview: "名1  名2  名3" (Label auto-wraps to multi-row, no "喜:" prefix).
func _update_col_xi_preview(hand: Array[CardData.PlayingCard]) -> void:
	if hand.size() < 9:
		if _col_xi_label and is_instance_valid(_col_xi_label):
			_col_xi_label.text = "-"
			_col_xi_label.visible = false
		return

	if NinKingGameState.current_arrangement == null:
		if _col_xi_label and is_instance_valid(_col_xi_label):
			_col_xi_label.text = "-"
			_col_xi_label.visible = false
		return

	var xi_hc: Array = hand.slice(0, 3)
	var xi_mc: Array = hand.slice(3, 6)
	var xi_tc: Array = hand.slice(6, 9)
	var xi_he = HandEvaluator3.evaluate(xi_hc)
	var xi_me = HandEvaluator3.evaluate(xi_mc)
	var xi_te = HandEvaluator3.evaluate(xi_tc)
	var xi_result: XiDetector.XiResult = XiDetector.detect(xi_hc, xi_mc, xi_tc, xi_he, xi_me, xi_te)

	var xi_parts: Array[String] = []
	if xi_result != null and xi_result.has_any():
		for xi_name: String in xi_result.triggered:
			xi_parts.append(xi_name)

	if xi_parts.size() > 0:
		_col_xi_label.text = ScoreXiHandler.build_xi_display_text(xi_parts)
		_col_xi_label.visible = true
	elif _col_xi_label and is_instance_valid(_col_xi_label):
		_col_xi_label.text = "-"
		_col_xi_label.visible = false
