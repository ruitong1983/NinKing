class_name HandInteraction
extends RefCounted

## Swap interaction state machine for the 9-card hand.
## Pure logic — no rendering. Calls HandDisplay.refresh() when visual state changes.
## v2: Single HandCardContainer, no more per-Hand iteration.
## v3: Drag-drop handled by Card Framework drop processing + HandCardContainer.move_cards() override.
##     HandInteraction only handles click-based swaps.

const SB = preload("res://scripts/config/sound_bank.gd")

var _display: RefCounted  # HandDisplay
var _current_hand: Array[CardData.PlayingCard] = []

var _on_card_clicked: Callable

var swap_source_idx: int = -1


func setup(display: RefCounted, on_card_clicked: Callable = Callable()) -> void:
	_display = display
	_on_card_clicked = on_card_clicked


## Main entry point — route a card click to swap logic.
func handle_card_clicked(idx: int) -> void:
	_handle_swap(idx)


## Set the current hand data (used when refreshing after state changes).
func set_hand(hand: Array[CardData.PlayingCard]) -> void:
	_current_hand = hand


func _refresh_display() -> void:
	if _display:
		_display.refresh(_current_hand, swap_source_idx, _on_card_clicked)


# ══════════════════════════════════════════
# Swap (入れ替え — position swap)
# ══════════════════════════════════════════

func _handle_swap(idx: int) -> void:
	if swap_source_idx == -1:
		# Select source card
		swap_source_idx = idx
		GlobalTweens.play_sfx(SB.SELECT)
		_refresh_display()
	elif swap_source_idx == idx:
		# Deselect
		swap_source_idx = -1
		_refresh_display()
	else:
		# Execute swap — reset swap_source_idx BEFORE signal emission
		# so signal handlers see clean state
		var src: int = swap_source_idx
		swap_source_idx = -1
		SealController.swap_cards(NinKingGameState, src, idx)
		GlobalTweens.play_sfx(SB.SWAP)
		_current_hand = NinKingGameState.hand
		# hand_swapped signal triggers refresh via game_manager


func set_cards_interactable(card_grid: HandCardContainer, interactable: bool) -> void:
	card_grid.set_cards_interactable(interactable)
