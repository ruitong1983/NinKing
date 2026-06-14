@tool
class_name HandCardContainer
extends CardContainer
## 3-row x 3-column flat grid container for the main playing hand.
## Fixed mapping: _held_cards[0..2]->row0, [3..5]->row1, [6..8]->row2.
## All swaps go through game_state; this container mirrors game_state order.

signal layout_changed

const ROWS: int = 3
const COLS: int = 3
const CARD_W: float = 140.0
const CARD_H: float = 196.0
const ROW_H: float = 224.0
const ROW_0_Y: float = 34.0  # card top-y of row 0 (matches old DunHead offset)


func _card_can_be_added(_cards: Array) -> bool:
	return _held_cards.size() + _cards.size() <= ROWS * COLS


func _update_target_positions() -> void:
	var count := _held_cards.size()
	if count == 0:
		if drop_zone:
			drop_zone.set_sensor_size_flexibly(Vector2.ZERO, Vector2.ZERO)
			drop_zone.set_vertical_partitions([])
			drop_zone.set_horizontal_partitions([])
		return

	var container_w: float = size.x
	var spread: float = clampf(container_w - 20.0, 0.0, 600.0)
	var spacing: float = spread / float(COLS + 1)

	for i: int in range(count):
		var card := _held_cards[i]
		if card.current_state == DraggableObject.DraggableState.HOLDING:
			continue
		var target := _card_local_pos(i, container_w, spacing)
		card.move(global_position + target, 0.0)

	if drop_zone:
		drop_zone.set_sensor_size_flexibly(size, Vector2.ZERO)

		var vp: Array[float] = []
		for c: int in range(COLS - 1):
			var left_center := _col_center_x(c, container_w, spacing)
			var right_center := _col_center_x(c + 1, container_w, spacing)
			vp.append(global_position.x + (left_center + right_center) / 2.0)
		drop_zone.set_vertical_partitions(vp)

		var hp: Array[float] = []
		for r: int in range(ROWS - 1):
			var row_bottom: float = ROW_0_Y + r * ROW_H + CARD_H
			var next_row_top: float = ROW_0_Y + (r + 1) * ROW_H
			hp.append(global_position.y + (row_bottom + next_row_top) / 2.0)
		drop_zone.set_horizontal_partitions(hp)

	layout_changed.emit()


func _update_card_states() -> void:
	for card: Card in _held_cards:
		card.show_front = true
		card.can_be_interacted_with = true


func _col_center_x(col: int, container_w: float, spacing: float) -> float:
	return container_w / 2.0 + (col - 1) * spacing


func _card_local_pos(idx: int, container_w: float = 0.0, spacing: float = 0.0) -> Vector2:
	if container_w == 0.0:
		container_w = size.x
		var spread := clampf(container_w - 20.0, 0.0, 600.0)
		spacing = spread / float(COLS + 1)
	@warning_ignore("integer_division")
	var row: int = idx / COLS
	var col: int = idx % COLS
	return Vector2(_col_center_x(col, container_w, spacing) - CARD_W / 2.0, ROW_0_Y + row * ROW_H)


func get_partition_index() -> int:
	if drop_zone == null:
		return -1
	var col := drop_zone.get_vertical_layers()
	var row := drop_zone.get_horizontal_layers()
	if col < 0 or row < 0:
		return -1
	return row * COLS + clampi(col, 0, COLS - 1)


func get_target_pose_for(card: Card) -> Dictionary:
	var idx := _held_cards.find(card)
	if idx < 0:
		return {}
	var pos := _card_local_pos(idx)
	return {"position": global_position + pos, "rotation": 0.0}


func set_cards_interactable(interactable: bool) -> void:
	for card: Card in _held_cards:
		if card is NinKingCard:
			card.can_be_interacted_with = interactable


func get_row_cards(row: int) -> Array[Card]:
	var result: Array[Card] = []
	var start := row * COLS
	var end := mini(start + COLS, _held_cards.size())
	for i: int in range(start, end):
		if is_instance_valid(_held_cards[i]):
			result.append(_held_cards[i])
	return result


func get_row_card_indices(row: int) -> Array[int]:
	var result: Array[int] = []
	var start := row * COLS
	var end := mini(start + COLS, _held_cards.size())
	for i: int in range(start, end):
		result.append(i)
	return result


func grid_index_at(global_pos: Vector2) -> int:
	if drop_zone == null:
		return -1
	var col := 0
	for p: float in drop_zone.vertical_partition:
		if global_pos.x >= p:
			col += 1
		else:
			break
	var row := 0
	for p: float in drop_zone.horizontal_partition:
		if global_pos.y >= p:
			row += 1
		else:
			break
	col = clampi(col, 0, COLS - 1)
	row = clampi(row, 0, ROWS - 1)
	return row * COLS + col


func swap_two_cards(src_idx: int, tgt_idx: int) -> void:
	if src_idx < 0 or tgt_idx < 0 or src_idx >= _held_cards.size() or tgt_idx >= _held_cards.size():
		return
	if src_idx == tgt_idx:
		return

	var src_card: Card = _held_cards[src_idx]
	var tgt_card: Card = _held_cards[tgt_idx]

	_held_cards[src_idx] = tgt_card
	_held_cards[tgt_idx] = src_card

	cards_node.move_child(tgt_card, src_idx)
	cards_node.move_child(src_card, tgt_idx)

	src_card.card_index = tgt_idx
	tgt_card.card_index = src_idx

	var src_target := global_position + _card_local_pos(src_idx)
	var tgt_target := global_position + _card_local_pos(tgt_idx)
	tgt_card.move(src_target, 0.0)
	src_card.move(tgt_target, 0.0)
