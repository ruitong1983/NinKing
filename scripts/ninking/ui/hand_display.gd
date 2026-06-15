class_name HandDisplay
extends RefCounted

## Renders the 9-card 3-group (比鸡) hand display — card placement and layout only.
## Label updates delegated to HandTypeLabeler.
## v2: Single HandCardContainer replaces 3 Hand nodes.

var _card_grid: HandCardContainer
var _status_label: Label

var _labeler: HandTypeLabeler
var _current_hand: Array[CardData.PlayingCard] = []


func setup(
	card_grid: HandCardContainer,
	head_type: Label, mid_type: Label, tail_type: Label,
	col0: Label, col1: Label, col2: Label, col_xi: Label,
	shadow_type: Label, flash_type: Label, destroy_type: Label,
	shadow_score: RichTextLabel, flash_score: RichTextLabel, destroy_score: RichTextLabel,
	shadow_lv: Label, flash_lv: Label, destroy_lv: Label,
	left_col_label: Label, mid_col_label: Label, right_col_label: Label,
	left_col_type: Label, mid_col_type: Label, right_col_type: Label,
	left_col_score: RichTextLabel, mid_col_score: RichTextLabel, right_col_score: RichTextLabel,
	left_col_lv: Label, mid_col_lv: Label, right_col_lv: Label,
	play: Button, status: Label
) -> void:
	assert(card_grid != null, "HandDisplay.setup: card_grid must not be null")
	_card_grid = card_grid
	_status_label = status

	_labeler = HandTypeLabeler.new()
	_card_grid.layout_changed.connect(_labeler.update_from_signal)
	_labeler.setup(
		head_type, mid_type, tail_type,
		col0, col1, col2, col_xi,
		shadow_type, flash_type, destroy_type,
		shadow_score, flash_score, destroy_score,
		shadow_lv, flash_lv, destroy_lv,
		left_col_label, mid_col_label, right_col_label,
		left_col_type, mid_col_type, right_col_type,
		left_col_score, mid_col_score, right_col_score,
		left_col_lv, mid_col_lv, right_col_lv,
		play
	)




func _clear_all() -> void:
	if _card_grid != null:
		_card_grid.clear_cards()


func _add_card(card_data: CardData.PlayingCard, idx: int,
		swap_idx: int,
		on_card_clicked: Callable = Callable(),
		on_card_dragged: Callable = Callable()) -> void:
	var pc: NinKingCard = NinKingCard.new()
	pc.card_size = Vector2(125, 175)
	pc.name = "CardBtn_%d" % idx
	pc.playing_card_data = card_data
	pc.card_index = idx
	if on_card_clicked.is_valid() and not pc.ninking_card_clicked.is_connected(on_card_clicked):
		pc.ninking_card_clicked.connect(on_card_clicked)
	if on_card_dragged.is_valid() and not pc.ninking_card_dragged.is_connected(on_card_dragged):
		pc.ninking_card_dragged.connect(on_card_dragged)
	if idx == swap_idx:
		pc.set_visual_state(NinKingCard.VisualState.SWAP_SOURCE)
	_card_grid.add_card(pc)
	pc.update_display()
	GlobalTweens.pop_in(pc, 0.25)


func refresh(hand: Array[CardData.PlayingCard], swap_idx: int, on_card_clicked: Callable = Callable(), on_card_dragged: Callable = Callable()) -> void:
	_current_hand = hand
	_clear_all()
	if hand.size() < 9:
		_labeler.reset_labels()
		return
	for i: int in range(9):
		_add_card(hand[i], i, swap_idx, on_card_clicked, on_card_dragged)
	if _card_grid and _card_grid.is_inside_tree():
		var timer := _card_grid.get_tree().create_timer(0.3)
		timer.timeout.connect(_fixup_layout, CONNECT_ONE_SHOT)


## Find target card index from a global drop position.
## Returns { "target_idx": int } or empty dict if outside grid.
func find_drop_target(global_pos: Vector2) -> Dictionary:
	var idx := _card_grid.grid_index_at(global_pos)
	if idx < 0 or idx >= _current_hand.size():
		return {}
	return {"target_idx": idx}


func update_labels(hand: Array[CardData.PlayingCard]) -> void:
	if _labeler:
		_labeler.update_all(hand)


func clear() -> void:
	_clear_all()
	_current_hand.clear()


func _fixup_layout() -> void:
	if not is_instance_valid(_card_grid):
		return
	_card_grid.update_card_ui()
