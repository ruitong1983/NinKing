@tool
class_name NinjaBarContainer
extends CardContainer
## Horizontal linear card container for the ninja inventory bar.
##
## Reuses CardContainer's card management pipeline, DropZone with vertical
## partitions for insert-position detection, and undo history.
## Overrides the three virtual methods with flat, no-curve layout logic.
##
## Emits reorder_requested(from, to) when a ninja card is dragged to a new
## position within this container so NinjaBarNode can persist to GameState.

signal reorder_requested(from_index: int, to_index: int)

const SLOT_WIDTH: float = 125.0
const SPACING_MIN: int = 8
const SPACING_MAX: int = 24


func _ready() -> void:
	super._ready()
	anchor_right = 1.0
	anchor_bottom = 1.0
	custom_minimum_size = Vector2(0, 195)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_card_ui()


# ════════════════════════════════════════════════════════════════
#  CardContainer overrides
# ════════════════════════════════════════════════════════════════

func _card_can_be_added(_cards: Array) -> bool:
	return true


func check_card_can_be_dropped(cards: Array) -> bool:
	if cards.size() == 1 and _held_cards.has(cards[0]):
		return true
	return super.check_card_can_be_dropped(cards)


func get_partition_index() -> int:
	if drop_zone == null:
		return -1
	var partitions: Array = drop_zone.vertical_partition
	if partitions.is_empty():
		return -1
	var mouse_x: float = get_global_mouse_position().x
	var idx := 0
	for p: float in partitions:
		if mouse_x >= p:
			idx += 1
		else:
			break
	return idx


func _update_target_positions() -> void:
	var count := _held_cards.size()
	if count == 0:
		if drop_zone:
			drop_zone.set_sensor_size_flexibly(Vector2.ZERO, Vector2.ZERO)
			drop_zone.set_vertical_partitions([])
		return

	var container_w: float = size.x
	var sep: float = 0.0
	if count > 1:
		sep = (container_w - count * SLOT_WIDTH) / (count - 1)
		sep = clampf(sep, SPACING_MIN, SPACING_MAX)

	var total_w: float = count * SLOT_WIDTH + (count - 1) * sep
	var start_x: float = (container_w - total_w) / 2.0

	if drop_zone:
		var vp_rect := get_viewport_rect()
		drop_zone.set_sensor_size_flexibly(vp_rect.size, -global_position)

	var partitions: Array[float] = []
	for i: int in range(count):
		var card := _held_cards[i]
		var card_origin_x: float = start_x + i * (SLOT_WIDTH + sep)
		var global_x: float = global_position.x + card_origin_x + SLOT_WIDTH / 2.0
		partitions.append(global_x)

		# Skip cards being actively dragged — their position is managed by the
		# drag system. Calling move() would force HOLDING → MOVING state change
		# and break the drag interaction, causing visual overlap.
		if card.current_state == DraggableObject.DraggableState.HOLDING:
			continue

		var target_pos := Vector2(global_position.x + card_origin_x, global_position.y + (size.y - card.card_size.y) / 2.0)
		card.move(target_pos, 0)

	if drop_zone:
		drop_zone.set_vertical_partitions(partitions)


func _update_card_states() -> void:
	for card: Card in _held_cards:
		card.show_front = true
		card.can_be_interacted_with = true


func move_cards(cards: Array, index: int = -1, with_history: bool = true) -> bool:
	if cards.size() == 1 and _held_cards.has(cards[0]):
		var card: Card = cards[0]
		var from_idx: int = _held_cards.find(card)
		if index >= 0 and index <= _held_cards.size() and from_idx != index:
			# Removing the card shifts higher indices left by one.
			if from_idx < index:
				index -= 1
			var ok := super.move_cards(cards, index, with_history)
			if ok:
				var to_idx: int = _held_cards.find(card)
				if to_idx >= 0 and from_idx != to_idx:
					reorder_requested.emit(from_idx, to_idx)
			return ok
	return super.move_cards(cards, index, with_history)
