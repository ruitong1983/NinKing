@tool
class_name HandCardContainer
extends CardContainer
## 3-row x 3-column flat grid container for the main playing hand.
## Fixed mapping: _held_cards[0..2]->row0, [3..5]->row1, [6..8]->row2.
## All swaps go through game_state; this container mirrors game_state order.
## v3: Vertical spacing is now dynamic (like horizontal) — 9 cards distribute
## evenly in whatever CardGrid size, giving a natural 3:5-ish fit.

signal layout_changed

const ROWS: int = 3
const COLS: int = 3
const CARD_W: float = 125.0
const CARD_H: float = 175.0
const ROW_0_Y_MIN: float = 34.0  # minimum top offset for row 0


func _card_can_be_added(_cards: Array) -> bool:
	# If all cards are already in this container (same-container reorder),
	# skip the capacity check — the card count won't change.
	var all_contained: bool = true
	for c in _cards:
		if not _held_cards.has(c):
			all_contained = false
			break
	if all_contained:
		return true
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
	var container_h: float = size.y

	# Horizontal — even distribution
	var h_excess: float = maxf(container_w - COLS * CARD_W, 0.0)
	var h_margin: float = h_excess / float(COLS + 1)
	var spacing: float = CARD_W + h_margin

	# Vertical — even distribution (same pattern as horizontal)
	var v_excess: float = maxf(container_h - ROWS * CARD_H, 0.0)
	var v_margin: float = v_excess / float(ROWS + 1)
	var row_h: float = CARD_H + v_margin
	var row_0_y: float = maxf(ROW_0_Y_MIN, v_margin)

	for i: int in range(count):
		var card := _held_cards[i]
		if card.current_state == DraggableObject.DraggableState.HOLDING:
			continue
		var target := _card_local_pos(i, container_w, spacing, row_0_y, row_h)
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
			var row_bottom: float = row_0_y + r * row_h + CARD_H
			var next_row_top: float = row_0_y + (r + 1) * row_h
			hp.append(global_position.y + (row_bottom + next_row_top) / 2.0)
		drop_zone.set_horizontal_partitions(hp)

	layout_changed.emit()


func _update_card_states() -> void:
	for card: Card in _held_cards:
		card.show_front = true
		card.can_be_interacted_with = true


func _col_center_x(col: int, container_w: float, spacing: float) -> float:
	return container_w / 2.0 + (col - 1) * spacing


func _card_local_pos(
	idx: int,
	container_w: float = 0.0,
	spacing: float = 0.0,
	row_0_y: float = ROW_0_Y_MIN,
	row_h: float = -1.0
) -> Vector2:
	if container_w == 0.0:
		container_w = size.x
		var h_excess: float = maxf(container_w - COLS * CARD_W, 0.0)
		var h_margin: float = h_excess / float(COLS + 1)
		spacing = CARD_W + h_margin
	if row_h < 0.0:
		var container_h: float = size.y
		var v_excess: float = maxf(container_h - ROWS * CARD_H, 0.0)
		var v_margin: float = v_excess / float(ROWS + 1)
		row_h = CARD_H + v_margin
		row_0_y = maxf(ROW_0_Y_MIN, v_margin)
	# row index via float division (intentional truncation)
	var row: int = floori(float(idx) / COLS)
	var col: int = idx % COLS
	return Vector2(
		_col_center_x(col, container_w, spacing) - CARD_W / 2.0,
		row_0_y + row * row_h
	)


func get_partition_index() -> int:
	if drop_zone == null:
		return -1
	var col := drop_zone.get_vertical_layers()
	var row := drop_zone.get_horizontal_layers()
	if col < 0 or row < 0:
		return -1
	return row * COLS + clampi(col, 0, COLS - 1)


## Override: intercept same-container single-card drops to perform a swap
## + sync game state via SealController.swap_cards().
func move_cards(cards: Array, index: int = -1, with_history: bool = true) -> bool:
	if cards.size() == 1 and _held_cards.has(cards[0]) and index >= 0:
		var src_idx: int = _held_cards.find(cards[0])
		index = clampi(index, 0, _held_cards.size() - 1)
		if src_idx == index:
			return true  # Same slot — no-op
		SealController.swap_cards(NinKingGameState, src_idx, index)
		# If not in PLAYING state (e.g. debug menu), swap_cards won't
		# emit hand_swapped → swap_two_cards won't fire via signal.
		# Call it directly to ensure visual swap.
		if NinKingGameState.current_state != NinKingGameState.State.PLAYING:
			swap_two_cards(src_idx, index)
		return true
	return super.move_cards(cards, index, with_history)


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
