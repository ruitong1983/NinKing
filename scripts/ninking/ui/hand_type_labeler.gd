class_name HandTypeLabeler
extends RefCounted

## Updates all hand-type text labels: dun types (影/瞬/滅), column types,
## score preview (chips × mult), and action button states.
## Extracted from HandDisplay to keep each file focused.

var _head_type_label: Label
var _mid_type_label: Label
var _tail_type_label: Label
var _chips_label: Label
var _mult_label: Label
var _shadow_type_label: Label
var _flash_type_label: Label
var _destroy_type_label: Label
var _play_btn: Button
var _redraw_btn: Button
var _col0_label: Label
var _col1_label: Label
var _col2_label: Label


func setup(
	head_type: Label,
	mid_type: Label,
	tail_type: Label,
	col0: Label,
	col1: Label,
	col2: Label,
	chips: Label,
	mult: Label,
	shadow_type: Label,
	flash_type: Label,
	destroy_type: Label,
	play: Button,
	redraw: Button,
) -> void:
	_head_type_label = head_type
	_mid_type_label = mid_type
	_tail_type_label = tail_type
	_col0_label = col0
	_col1_label = col1
	_col2_label = col2
	_chips_label = chips
	_mult_label = mult
	_shadow_type_label = shadow_type
	_flash_type_label = flash_type
	_destroy_type_label = destroy_type
	_play_btn = play
	_redraw_btn = redraw


# ══════════════════════════════════════════
# Public API
# ══════════════════════════════════════════

## Clear all labels to default state.
func reset_labels() -> void:
	_head_type_label.text = ""
	_mid_type_label.text = ""
	_tail_type_label.text = ""
	_chips_label.text = ""
	_mult_label.text = ""
	_shadow_type_label.text = "影: -"
	_flash_type_label.text = "瞬: -"
	_destroy_type_label.text = "滅: -"
	_col0_label.text = ""
	_col0_label.visible = false
	_col1_label.text = ""
	_col1_label.visible = false
	_col2_label.text = ""
	_col2_label.visible = false


## Update all labels for the current 9-card hand.
func update_all(hand: Array[CardData.PlayingCard], redraw_mode: bool) -> void:
	if hand.size() < 9:
		return
	_update_dun_types(hand)
	_update_column_types(hand)
	_update_action_buttons(redraw_mode)
	_update_score_preview(hand)


# ══════════════════════════════════════════
# Dun type labels — 影 / 瞬 / 滅
# ══════════════════════════════════════════

func _update_dun_types(hand: Array[CardData.PlayingCard]) -> void:
	var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(hand.slice(0, 3))
	var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(hand.slice(3, 6))
	var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(hand.slice(6, 9))
	var head_name: String = CardData.get_hand_type3_name(head_eval.hand_type)
	var mid_name: String = CardData.get_hand_type3_name(mid_eval.hand_type)
	var tail_name: String = CardData.get_hand_type3_name(tail_eval.hand_type)
	_head_type_label.text = head_name
	_mid_type_label.text = mid_name
	_tail_type_label.text = tail_name
	_shadow_type_label.text = "影: " + head_name
	_flash_type_label.text = "瞬: " + mid_name
	_destroy_type_label.text = "滅: " + tail_name


# ══════════════════════════════════════════
# Column type labels — A9 列分
# ══════════════════════════════════════════

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
# Action buttons
# ══════════════════════════════════════════

func _update_action_buttons(p_redraw_mode: bool) -> void:
	if p_redraw_mode:
		_play_btn.disabled = true
		_redraw_btn.text = "手替え確認"
	else:
		_play_btn.disabled = false
		_redraw_btn.text = "手替え"


# ══════════════════════════════════════════
# Score preview — chips × mult
# ══════════════════════════════════════════

func _update_score_preview(hand: Array[CardData.PlayingCard]) -> void:
	if not NinKingGameState.current_arrangement:
		return
	var head_cards: Array = hand.slice(0, 3)
	var mid_cards: Array = hand.slice(3, 6)
	var tail_cards: Array = hand.slice(6, 9)
	var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_cards)
	var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_cards)
	var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_cards)
	var result: ScoreCalculator.ScoreResult = ScoreCalculator.calculate(
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval,
		[],
		NinKingGameState.owned_ninjas, NinKingGameState.star_chart_levels,
		null, {},
		NinKingGameState.gold
	)
	_chips_label.text = str(result.chips_sum)
	_mult_label.text = str(result.mult_sum)
