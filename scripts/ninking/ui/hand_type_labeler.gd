class_name HandTypeLabeler
extends RefCounted

## Updates all hand-type text labels: dun types (影/瞬/滅), column types,
## and column+xi preview in ScoreCard.
## Delegated from HandDisplay — keeps label logic separate from card layout.

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
var _col0_label: Label
var _col1_label: Label
var _col2_label: Label
var _play_btn: Button


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
	_play_btn = play


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

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

## Update per-dun type names and base score preview (card_chips + hand_chips) × hand_mult.
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
	# Row 2: 瞬
	_flash_type_label.text = mid_name
	_flash_score_label.text = "%d×%d" % [mid_card_chips + mid_chips, mid_mult]
	# Row 3: 滅
	_destroy_type_label.text = tail_name
	_destroy_score_label.text = "%d×%d" % [tail_card_chips + tail_chips, tail_mult]


# ══════════════════════════════════════════
# Column type labels — A9 列牌型名 (DunArea 下方)
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
# Column + Xi preview — top of ScoreCard (v4.0)
# ══════════════════════════════════════════

## Update top preview: 列: ×N  喜: 名×N  (or 列: ×N  喜: -).
## Computes column ×mult product and global xi detection from the full 9-card hand.
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
				# Only show global xi in preview (group-level xi too complex for top line)
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
