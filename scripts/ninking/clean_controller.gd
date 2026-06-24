class_name CleanController
extends RefCounted

## Clean (elimination) mode controller — 3x3 grid swap-and-match gameplay.
## 4 match types: THREE_OF_KIND / STRAIGHT_FLUSH / FLUSH / STRAIGHT.

const ROWS: int = 3
const COLS: int = 3

const GameRunLogger = preload("res://scripts/ninking/logging/game_logger.gd")

# ──────────────────────────── Grid helpers ────────────────────────────

static func grid_idx(row: int, col: int) -> int:
	return row * COLS + col


static func row_col(idx: int) -> Vector2i:
	return Vector2i(idx % COLS, int(float(idx) / float(COLS)))


static func is_adjacent(idx1: int, idx2: int) -> bool:
	var p1: Vector2i = row_col(idx1)
	var p2: Vector2i = row_col(idx2)
	return abs(p1.x - p2.x) + abs(p1.y - p2.y) == 1


# ──────────────────────────── Match detection ────────────────────────────

## Returns Array[Dictionary] — each entry has:
##   type, index, positions, hand_type (int), cards, score (int)
static func detect_matches(hand: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if hand.size() < 9:
		return result
	for r in range(ROWS):
		var cards = [hand[grid_idx(r, 0)], hand[grid_idx(r, 1)], hand[grid_idx(r, 2)]]
		if cards[0] == null or cards[1] == null or cards[2] == null:
			continue
		var line = _classify_line(cards)
		if not line.is_empty():
			line["type"] = "row"
			line["index"] = r
			line["positions"] = [grid_idx(r, 0), grid_idx(r, 1), grid_idx(r, 2)]
			result.append(line)
	for c in range(COLS):
		var cards = [hand[grid_idx(0, c)], hand[grid_idx(1, c)], hand[grid_idx(2, c)]]
		if cards[0] == null or cards[1] == null or cards[2] == null:
			continue
		var line = _classify_line(cards)
		if not line.is_empty():
			line["type"] = "col"
			line["index"] = c
			line["positions"] = [grid_idx(0, c), grid_idx(1, c), grid_idx(2, c)]
			result.append(line)
	return result


static func has_any_match(hand: Array) -> bool:
	return not detect_matches(hand).is_empty()


## Priority: THREE_OF_KIND(5) → STRAIGHT_FLUSH(4) → FLUSH(3) → STRAIGHT(2)
static func _classify_line(cards: Array) -> Dictionary:
	var ranks: Array[int] = [int(cards[0].rank), int(cards[1].rank), int(cards[2].rank)]
	var suits: Array[int] = [int(cards[0].suit), int(cards[1].suit), int(cards[2].suit)]

	# THREE_OF_KIND (豹子)
	if ranks[0] == ranks[1] and ranks[1] == ranks[2]:
		return _make_match(5, cards)

	var same_suit: bool = suits[0] == suits[1] and suits[1] == suits[2]
	var straight: bool = _is_straight(ranks)

	# STRAIGHT_FLUSH (同花顺)
	if same_suit and straight:
		return _make_match(4, cards)
	# FLUSH (同花)
	if same_suit:
		return _make_match(3, cards)
	# STRAIGHT (顺子)
	if straight:
		return _make_match(2, cards)
	return {}


static func _is_straight(ranks: Array[int]) -> bool:
	var s = ranks.duplicate()
	s.sort()
	return s[0] + 1 == s[1] and s[1] + 1 == s[2]


static func _make_match(hand_type: int, cards: Array) -> Dictionary:
	var chips: int = 0
	for c in cards:
		chips += _chip_value(c.rank)
	var mults: Dictionary = {2: 3, 3: 4, 4: 5, 5: 8}
	var score: int = chips * mults.get(hand_type, 1)
	return {"hand_type": hand_type, "cards": cards, "score": score}


static func _chip_value(rank: int) -> int:
	match rank:
		11, 12, 13:
			return 10
		14:
			return 11
		_:
			return rank


# ──────────────────────────── Chain wave ────────────────────────────

## Returned dict: {matches, chain_level, wave_score, remove_positions, hand_type}
static func prepare_chain_wave(gs, current_chain_level: int = 0) -> Dictionary:
	var matches: Array[Dictionary] = detect_matches(gs.hand)
	if matches.is_empty():
		return {}
	var chain_level: int = maxi(current_chain_level, 0) + 1
	var wave_score: int = _score_matches(matches, chain_level)
	var seen: Array[int] = []
	for m in matches:
		for pos in m["positions"]:
			if not seen.has(pos):
				seen.append(pos)
	return {
		"matches": matches,
		"chain_level": chain_level,
		"wave_score": wave_score,
		"remove_positions": seen,
		"hand_type": matches[0]["hand_type"] if not matches.is_empty() else 0,
	}


## Step 1: Remove matched cards — set positions to null, discard to deck.
## Leaves nulls in hand (no gravity, no draw). Call gravity_and_draw() next.
static func remove_matches(gs, wave_data: Dictionary) -> void:
	var positions: Array[int] = wave_data.get("remove_positions", [])
	if positions.is_empty():
		return
	positions.sort()
	positions.reverse()
	var discarded: Array[CardData.PlayingCard] = []
	for pos in positions:
		var card = gs.hand[pos]
		if card != null:
			discarded.append(card)
		gs.hand[pos] = null
	if not discarded.is_empty():
		gs.deck_manager.discard(discarded)


## Step 2: Gravity + draw new cards to fill null positions.
## Compact non-null cards to bottom of each column, draw new cards for top slots.
static func gravity_and_draw(gs) -> void:
	for col in range(COLS):
		var col_cards: Array[CardData.PlayingCard] = []
		for r in range(ROWS - 1, -1, -1):
			var card = gs.hand[grid_idx(r, col)]
			if card != null:
				col_cards.append(card)
		var write_row: int = ROWS - 1
		for card in col_cards:
			gs.hand[grid_idx(write_row, col)] = card
			write_row -= 1
		var empty_count: int = write_row + 1
		if empty_count > 0:
			var new_cards: Array = gs.deck_manager.draw(empty_count)
			var fill_row: int = write_row
			for nc in new_cards:
				gs.hand[grid_idx(fill_row, col)] = nc
				fill_row -= 1
		# If deck ran out, remaining nulls stay as-is (detect_matches skips null lines)


## Convenience: remove + gravity+draw in one call (used externally if needed).
static func apply_chain_wave(gs, wave_data: Dictionary) -> void:
	remove_matches(gs, wave_data)
	gravity_and_draw(gs)


# ──────────────────────────── Swap + finalize ────────────────────────────

## Perform a swap between any two positions in the 3x3 grid.
## v2026-06-24: Adjacent constraint removed — free swap anywhere in 9-grid.
static func do_swap(gs, src_idx: int, tgt_idx: int) -> bool:
	if gs.current_state != NinKingGameState.State.PLAYING:
		return false
	if gs.swaps_remaining <= 0:
		return false
	if src_idx < 0 or src_idx >= gs.hand.size() or tgt_idx < 0 or tgt_idx >= gs.hand.size():
		return false
	if gs.hand[src_idx] == null or gs.hand[tgt_idx] == null:
		return false
	var temp = gs.hand[src_idx]
	gs.hand[src_idx] = gs.hand[tgt_idx]
	gs.hand[tgt_idx] = temp
	gs.hand_swapped.emit(src_idx, tgt_idx)
	GameRunLogger.on_card_swapped(src_idx, tgt_idx, gs.hand)
	return true


static func finalize_swap(gs, _chain_results: Array, total_score: int) -> void:
	gs.swaps_remaining -= 1
	gs.current_score += total_score
	gs.emit_score_updated()
	gs.emit_swaps_changed()
	gs.hand_updated.emit(gs.hand)
	if gs.current_score >= gs.target_score:
		_complete_seal(gs)
	elif gs.swaps_remaining <= 0:
		gs._transition_to(NinKingGameState.State.GAME_OVER)
	else:
		gs._transition_to(NinKingGameState.State.PLAYING)


# ──────────────────────────── Scoring ────────────────────────────

## Σ(match_score) × chain_level, where match_score = Σ(chip) × hand_type_mult
static func _score_matches(matches: Array[Dictionary], chain_level: int) -> int:
	var total: int = 0
	for m in matches:
		total += m.get("score", 0)
	return total * chain_level


# ──────────────────────────── Seal completion ────────────────────────────

static func _complete_seal(gs) -> void:
	var seal_cfg: Dictionary = BarrierConfig.get_seal(gs.barrier_num, gs.seal_idx)
	gs.gold += seal_cfg.get("gold", 0)
	gs.gold_changed.emit(gs.gold)
	var interest: int = mini(
		floori(float(gs.gold) / float(ConfigManager.interest_divisor)),
		ConfigManager.interest_cap
	)
	gs.gold += interest
	gs.gold_changed.emit(gs.gold)
	gs.seal_idx += 1
	if gs.seal_idx >= BarrierConfig.get_seals_per_barrier():
		gs.seal_idx = 0
		gs.barrier_num += 1
	if gs.barrier_num > BarrierConfig.get_total_barriers():
		gs._transition_to(NinKingGameState.State.VICTORY)
		return
	gs._transition_to(NinKingGameState.State.SEAL_COMPLETE)
