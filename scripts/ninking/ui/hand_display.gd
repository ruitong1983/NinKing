class_name HandDisplay
extends RefCounted

## Renders the 9-card 3-group (比鸡) hand display.
## Pure rendering — no interaction state machine.

var _head_hand: Hand
var _mid_hand: Hand
var _tail_hand: Hand
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
var _status_label: Label
var _col0_label: Label
var _col1_label: Label
var _col2_label: Label

var _current_hand: Array[CardData.PlayingCard] = []


func setup(
	head: Hand, mid: Hand, tail: Hand,
	head_type: Label, mid_type: Label, tail_type: Label,
	col0: Label, col1: Label, col2: Label,
	chips: Label, mult: Label, shadow_type: Label, flash_type: Label, destroy_type: Label,
	play: Button, redraw: Button, status: Label
) -> void:
	assert(head != null, "HandDisplay.setup: head must not be null")
	assert(mid != null, "HandDisplay.setup: mid must not be null")
	assert(tail != null, "HandDisplay.setup: tail must not be null")
	assert(head_type != null, "HandDisplay.setup: head_type must not be null")
	assert(mid_type != null, "HandDisplay.setup: mid_type must not be null")
	assert(tail_type != null, "HandDisplay.setup: tail_type must not be null")
	assert(chips != null, "HandDisplay.setup: chips must not be null")
	assert(mult != null, "HandDisplay.setup: mult must not be null")
	assert(shadow_type != null, "HandDisplay.setup: shadow_type must not be null")
	assert(flash_type != null, "HandDisplay.setup: flash_type must not be null")
	assert(destroy_type != null, "HandDisplay.setup: destroy_type must not be null")
	assert(play != null, "HandDisplay.setup: play must not be null")
	assert(redraw != null, "HandDisplay.setup: redraw must not be null")
	assert(status != null, "HandDisplay.setup: status must not be null")
	_head_hand = head
	_mid_hand = mid
	_tail_hand = tail
	_head_type_label = head_type
	_mid_type_label = mid_type
	_tail_type_label = tail_type
	_chips_label = chips
	_mult_label = mult
	_shadow_type_label = shadow_type
	_flash_type_label = flash_type
	_destroy_type_label = destroy_type
	_play_btn = play
	_redraw_btn = redraw
	_status_label = status
	_col0_label = col0
	_col1_label = col1
	_col2_label = col2


func _clear_all() -> void:
	if _head_hand != null:
		_head_hand.clear_cards()
	if _mid_hand != null:
		_mid_hand.clear_cards()
	if _tail_hand != null:
		_tail_hand.clear_cards()


func _reset_labels() -> void:
	if _head_type_label != null:
		_head_type_label.text = ""
	if _mid_type_label != null:
		_mid_type_label.text = ""
	if _tail_type_label != null:
		_tail_type_label.text = ""
	if _chips_label != null:
		_chips_label.text = ""
	if _mult_label != null:
		_mult_label.text = ""
	if _shadow_type_label != null:
		_shadow_type_label.text = "影: -"
	if _flash_type_label != null:
		_flash_type_label.text = "瞬: -"
	if _destroy_type_label != null:
		_destroy_type_label.text = "滅: -"
	if _col0_label != null:
		_col0_label.text = ""
		_col0_label.visible = false
	if _col1_label != null:
		_col1_label.text = ""
		_col1_label.visible = false
	if _col2_label != null:
		_col2_label.text = ""
		_col2_label.visible = false


func _update_dun_type_labels() -> void:
	if _current_hand.size() < 9:
		return
	var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(_current_hand.slice(0, 3))
	var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(_current_hand.slice(3, 6))
	var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(_current_hand.slice(6, 9))
	var head_name: String = CardData.get_hand_type3_name(head_eval.hand_type)
	var mid_name: String = CardData.get_hand_type3_name(mid_eval.hand_type)
	var tail_name: String = CardData.get_hand_type3_name(tail_eval.hand_type)
	_head_type_label.text = head_name
	_mid_type_label.text = mid_name
	_tail_type_label.text = tail_name
	if _shadow_type_label != null:
		_shadow_type_label.text = "影: " + head_name
	if _flash_type_label != null:
		_flash_type_label.text = "瞬: " + mid_name
	if _destroy_type_label != null:
		_destroy_type_label.text = "滅: " + tail_name


func _update_column_type_labels() -> void:
	if _current_hand.size() < 9:
		return
	var col_labels: Array[Label] = [_col0_label, _col1_label, _col2_label]
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
			_current_hand[i],
			_current_hand[i + 3],
			_current_hand[i + 6]
		]
		var eval_result: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(col_cards)
		var lbl: Label = col_labels[i]
		if int(eval_result.hand_type) >= int(CardData.HandType3.ONE_PAIR_3):
			lbl.text = CardData.get_hand_type3_name(eval_result.hand_type)
			lbl.visible = true
		else:
			lbl.text = ""
			lbl.visible = false


func _update_action_buttons(p_redraw_mode: bool) -> void:
	if p_redraw_mode:
		_play_btn.disabled = true
		_redraw_btn.text = "手替え確認"
	else:
		_play_btn.disabled = false
		_redraw_btn.text = "手替え"


func _update_score_preview() -> void:
	if _current_hand.size() < 9:
		return
	if not NinKingGameState.current_arrangement:
		return
	var head_cards: Array = _current_hand.slice(0, 3)
	var mid_cards: Array = _current_hand.slice(3, 6)
	var tail_cards: Array = _current_hand.slice(6, 9)
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


## Find which hand container and card index corresponds to a global drop position.
## Returns { "hand": Hand, "hand_offset": int, "target_idx": int } or empty dict if outside all hands.
## hand_offset: 0=head, 3=mid, 6=tail — used to compute absolute index in 9-card hand.
func find_drop_target(global_pos: Vector2) -> Dictionary:
	for pair in [{h = _head_hand, off = 0}, {h = _mid_hand, off = 3}, {h = _tail_hand, off = 6}]:
		var hand: Hand = pair.h
		var rect: Rect2 = hand.get_global_rect()
		if rect.has_point(global_pos):
			# Find which card in this hand is closest to the drop point
			var best_idx: int = -1
			var best_dist: float = INF
			var cards_node: Node = hand.get_node_or_null("Cards")
			if cards_node:
				for i: int in range(cards_node.get_child_count()):
					var child: Node = cards_node.get_child(i)
					if child is Card:
						var d: float = child.global_position.distance_squared_to(global_pos)
						if d < best_dist:
							best_dist = d
							best_idx = i
			return {"hand": hand, "hand_offset": pair.off, "target_idx": pair.off + max(best_idx, 0)}
	return {}


func _add_card(hand: Hand, card_data: CardData.PlayingCard, idx: int,
		swap_idx: int, redraw_idxs: Array[int],
		on_card_clicked: Callable = Callable(),
		on_card_dragged: Callable = Callable()) -> void:
	var pc: NinKingCard = NinKingCard.new()
	pc.card_size = Vector2(140, 196)
	pc.name = "CardBtn_%d" % idx
	pc.playing_card_data = card_data
	pc.card_index = idx
	if on_card_clicked.is_valid() and not pc.ninking_card_clicked.is_connected(on_card_clicked):
		pc.ninking_card_clicked.connect(on_card_clicked)
	if on_card_dragged.is_valid() and not pc.ninking_card_dragged.is_connected(on_card_dragged):
		pc.ninking_card_dragged.connect(on_card_dragged)
	if idx == swap_idx:
		pc.set_visual_state(NinKingCard.VisualState.SWAP_SOURCE)
	elif idx in redraw_idxs:
		pc.set_visual_state(NinKingCard.VisualState.REDRAW_TARGET)
	hand.add_card(pc)
	pc.update_display()
	GlobalTweens.pop_in(pc, 0.25)


func refresh(hand: Array[CardData.PlayingCard], swap_idx: int, redraw_idxs: Array[int], redraw_mode: bool, on_card_clicked: Callable = Callable(), on_card_dragged: Callable = Callable()) -> void:
	_current_hand = hand
	_clear_all()
	if hand.size() < 9:
		_reset_labels()
		return
	for i: int in range(3):
		_add_card(_head_hand, hand[i], i, swap_idx, redraw_idxs, on_card_clicked, on_card_dragged)
	for i: int in range(3, 6):
		_add_card(_mid_hand, hand[i], i, swap_idx, redraw_idxs, on_card_clicked, on_card_dragged)
	for i: int in range(6, 9):
		_add_card(_tail_hand, hand[i], i, swap_idx, redraw_idxs, on_card_clicked, on_card_dragged)
	_update_dun_type_labels()
	_update_column_type_labels()
	_update_action_buttons(redraw_mode)
	_update_score_preview()


func add_card_to_hand(target: Hand, card_data: CardData.PlayingCard, idx: int,
		swap_idx: int = -1, redraw_idxs: Array[int] = []) -> void:
	_add_card(target, card_data, idx, swap_idx, redraw_idxs)


func clear() -> void:
	_clear_all()
	_current_hand.clear()
