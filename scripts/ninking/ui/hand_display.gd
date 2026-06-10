class_name HandDisplay
extends RefCounted

## Renders the 9-card 3-group (比鸡) hand display — card placement and layout only.
## Label updates delegated to HandTypeLabeler.

var _head_hand: Hand
var _mid_hand: Hand
var _tail_hand: Hand
var _status_label: Label  # reserved, currently unused

var _labeler: HandTypeLabeler
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
	_head_hand = head
	_mid_hand = mid
	_tail_hand = tail
	_status_label = status

	_labeler = HandTypeLabeler.new()
	_labeler.setup(
		head_type, mid_type, tail_type,
		col0, col1, col2,
		chips, mult, shadow_type, flash_type, destroy_type,
		play, redraw
	)


func _clear_all() -> void:
	if _head_hand != null:
		_head_hand.clear_cards()
	if _mid_hand != null:
		_mid_hand.clear_cards()
	if _tail_hand != null:
		_tail_hand.clear_cards()


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
		_labeler.reset_labels()
		return
	for i: int in range(3):
		_add_card(_head_hand, hand[i], i, swap_idx, redraw_idxs, on_card_clicked, on_card_dragged)
	for i: int in range(3, 6):
		_add_card(_mid_hand, hand[i], i, swap_idx, redraw_idxs, on_card_clicked, on_card_dragged)
	for i: int in range(6, 9):
		_add_card(_tail_hand, hand[i], i, swap_idx, redraw_idxs, on_card_clicked, on_card_dragged)
	_labeler.update_all(hand, redraw_mode)

	# Card Framework move-tween race fix: rapid sequential add_card cycles
	# (kill→move→kill→deferred reapply) leave cards at intermediate positions.
	# We fix this in two stages:
	#   1. Timer fires → update_card_ui() (fixes child order, z-index, states)
	#      → force card positions (overrides stale tween targets)
	#   2. force positions once more after a short delay to catch any straggler
	#      tweens that may have been queued after our first pass.
	if _head_hand and _head_hand.is_inside_tree():
		var timer := _head_hand.get_tree().create_timer(0.3)
		timer.timeout.connect(_fixup_layout.bind(_head_hand, _mid_hand, _tail_hand), CONNECT_ONE_SHOT)


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


func add_card_to_hand(target: Hand, card_data: CardData.PlayingCard, idx: int,
		swap_idx: int = -1, redraw_idxs: Array[int] = []) -> void:
	_add_card(target, card_data, idx, swap_idx, redraw_idxs)


func clear() -> void:
	_clear_all()
	_current_hand.clear()


# ══════════════════════════════════════════
# Card Framework tween race fix
# ══════════════════════════════════════════

func _fixup_layout(head: Hand, mid: Hand, tail: Hand) -> void:
	for hand: Hand in [head, mid, tail]:
		if not is_instance_valid(hand):
			continue
		hand.update_card_ui()
		_force_card_positions(hand)


func _force_card_positions(hand: Hand) -> void:
	# Iterate by _held_cards order (matching _compute_pose indices),
	# NOT by Cards child order — the two may differ before _reorder.
	var held_cards: Array = hand.get("_held_cards")
	if held_cards == null or held_cards.is_empty():
		return
	var card_count: int = held_cards.size()
	var _w: float = 140.0  # NinKing card width
	var spacing: float = float(hand.max_hand_spread) / float(card_count + 1)
	var anchor: float = (hand.max_hand_spread + _w) / 2.0
	for i: int in range(card_count):
		var card: Card = held_cards[i]
		var target: Vector2 = hand.global_position
		target.x += (i + 1) * spacing - anchor
		# Flat curves → no rotation, no vertical offset.
		card.global_position = target
		card.rotation = 0.0
