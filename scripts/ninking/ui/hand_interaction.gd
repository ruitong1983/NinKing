class_name HandInteraction
extends RefCounted

## Swap/redraw interaction state machine for the 9-card hand.
## Pure logic — no rendering. Calls HandDisplay.refresh() when visual state changes.
## Extracted from UIManager to allow reuse and independent testing.

var _display: RefCounted  # HandDisplay
var _current_hand: Array[CardData.PlayingCard] = []

var swap_source_idx: int = -1
var redraw_mode: bool = false
var redraw_targets: Array[int] = []


func setup(display: RefCounted) -> void:
	_display = display


## Main entry point — route a card click to swap or redraw logic.
func handle_card_clicked(idx: int) -> void:
	if redraw_mode:
		_toggle_redraw(idx)
	else:
		_handle_swap(idx)


## Set the current hand data (used when refreshing after state changes).
func set_hand(hand: Array[CardData.PlayingCard]) -> void:
	_current_hand = hand


func _refresh_display() -> void:
	if _display:
		_display.refresh(_current_hand, swap_source_idx, redraw_targets, redraw_mode)


# ══════════════════════════════════════════
# Swap (入れ替え — position swap)
# ══════════════════════════════════════════

func _handle_swap(idx: int) -> void:
	if swap_source_idx == -1:
		swap_source_idx = idx
		_refresh_display()
	elif swap_source_idx == idx:
		swap_source_idx = -1
		_refresh_display()
	else:
		SealController.swap_cards(NinKingGameState, swap_source_idx, idx)
		swap_source_idx = -1
		_current_hand = NinKingGameState.hand
		_refresh_display()


# ══════════════════════════════════════════
# Drag-drop swap (cross-group)
# ══════════════════════════════════════════

## Handle a drag-drop from one card to another position (possibly across groups).
## Called by UIManager when NinKingCard emits ninking_card_dragged.
func handle_card_dragged(src_idx: int, drop_position: Vector2) -> void:
	var target: Dictionary = _display.find_drop_target(drop_position)
	if target.is_empty():
		return
	var tgt_idx: int = target["target_idx"]
	if tgt_idx < 0 or tgt_idx >= _current_hand.size() or tgt_idx == src_idx:
		return
	SealController.swap_cards(NinKingGameState, src_idx, tgt_idx)
	swap_source_idx = -1
	_current_hand = NinKingGameState.hand
	_refresh_display()


# ══════════════════════════════════════════
# Redraw (手替え — discard and redraw)
# ══════════════════════════════════════════

func _toggle_redraw(idx: int) -> void:
	if idx in redraw_targets:
		redraw_targets.erase(idx)
	else:
		if redraw_targets.size() >= 3:
			return
		redraw_targets.append(idx)
	_refresh_display()


func enable_redraw_mode() -> void:
	if NinKingGameState.redraws_remaining <= 0:
		return
	redraw_mode = true
	redraw_targets.clear()
	swap_source_idx = -1
	_refresh_display()


func confirm_redraw() -> void:
	if redraw_targets.is_empty():
		return
	SealController.execute_redraw(NinKingGameState, redraw_targets)
	redraw_mode = false
	redraw_targets.clear()
	swap_source_idx = -1
	_current_hand = NinKingGameState.hand
	_refresh_display()


## Set interactable state on all cards across the 3 hand containers.
func set_cards_interactable(head: Hand, mid: Hand, tail: Hand, interactable: bool) -> void:
	_set_hand_interactable(head, interactable)
	_set_hand_interactable(mid, interactable)
	_set_hand_interactable(tail, interactable)


func _set_hand_interactable(hand: Hand, interactable: bool) -> void:
	var cards_node: Node = hand.get_node_or_null("Cards")
	if cards_node == null:
		return
	for card_node: Node in cards_node.get_children():
		if card_node is NinKingCard:
			card_node.can_be_interacted_with = interactable
