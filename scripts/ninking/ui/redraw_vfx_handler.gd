class_name RedrawVFXHandler
extends RefCounted

## Runs the redraw visual effect sequence for 手替え.
## Fade out discarded cards → burst dust particles → confirm redraw → restore UI.
## Extracted from UIManager to keep file under 300 lines.

var _hand_interaction: RefCounted  # HandInteraction
var _head_cards: Hand
var _middle_cards: Hand
var _tail_cards: Hand
var _play_btn: Button
var _redraw_btn: Button
var _status_label: Label

var _is_running: bool = false


func setup(
	hand_interaction: RefCounted,
	head_cards: Hand,
	middle_cards: Hand,
	tail_cards: Hand,
	play_btn: Button,
	redraw_btn: Button,
	status_label: Label,
) -> void:
	_hand_interaction = hand_interaction
	_head_cards = head_cards
	_middle_cards = middle_cards
	_tail_cards = tail_cards
	_play_btn = play_btn
	_redraw_btn = redraw_btn
	_status_label = status_label


func is_running() -> bool:
	return _is_running


## Execute the full redraw VFX sequence. Guards against double-trigger.
## Returns when all animations complete.
func execute() -> void:
	if _is_running:
		return
	_is_running = true

	var targets: Array[int] = _hand_interaction.redraw_targets.duplicate()

	# Phase 1: fade out + dust burst on each discarded card
	for idx: int in targets:
		var card_node: Node = _get_card_node_at_index(idx)
		if card_node:
			GlobalTweens.fade_out(card_node, 0.15)
			GlobalTweens.burst_particles(card_node.global_position + card_node.size * 0.5, "dust")

	await _head_cards.get_tree().create_timer(0.18).timeout

	# Phase 2: execute the actual redraw and restore UI
	_hand_interaction.confirm_redraw()
	_play_btn.disabled = false
	_redraw_btn.text = "手\n替"
	_status_label.text = ""
	_hand_interaction.set_cards_interactable(_head_cards, _middle_cards, _tail_cards, true)
	_is_running = false


## Find the card Node at a given 0-based index in the 9-card hand.
## 0-2=head, 3-5=mid, 6-8=tail.
func _get_card_node_at_index(idx: int) -> Node:
	var hand: Hand
	var local_idx: int
	if idx < 3:
		hand = _head_cards
		local_idx = idx
	elif idx < 6:
		hand = _middle_cards
		local_idx = idx - 3
	else:
		hand = _tail_cards
		local_idx = idx - 6
	var cards_node: Node = hand.get_node_or_null("Cards")
	if cards_node and local_idx < cards_node.get_child_count():
		return cards_node.get_child(local_idx)
	return null
