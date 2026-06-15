class_name DeckManager
extends RefCounted

## Manages the draw pile and discard pile for a run.

var draw_pile: Array[CardData.PlayingCard] = []
var discard_pile: Array[CardData.PlayingCard] = []


func _init() -> void:
	reset()


func reset() -> void:
	draw_pile = CardData.create_standard_deck()
	discard_pile.clear()
	shuffle()


func shuffle() -> void:
	draw_pile.shuffle()
	# deck_shuffled signal removed — orphaned (no listeners)


func draw(count: int) -> Array[CardData.PlayingCard]:
	var drawn: Array[CardData.PlayingCard] = []
	for _i: int in range(count):
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		drawn.append(draw_pile.pop_back())
	return drawn


func discard(cards: Array[CardData.PlayingCard]) -> void:
	for c: CardData.PlayingCard in cards:
		discard_pile.append(c)


func _reshuffle_discard() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle()


func cards_remaining() -> int:
	return draw_pile.size()


func get_state() -> Dictionary:
	return {
		"draw_count": draw_pile.size(),
		"discard_count": discard_pile.size(),
	}


func restore_state(_state: Dictionary) -> void:
	# Full deck state restore not needed for MVP; just reset
	reset()
