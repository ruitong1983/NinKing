class_name CleanLayoutGenerator
extends RefCounted

## Clean mode initial layout generator.
## Peeks 9 cards (no consumption), verifies no matches across 4 hand types,
## shuffles deck on failure — no retry limit, zero deck contamination.

const ROWS: int = 3
const COLS: int = 3

static func grid_idx(row: int, col: int) -> int:
	return row * COLS + col


## Generate a valid clean-mode starting layout.
## Returns 9 cards guaranteed to have no row/col matches.
static func generate(deck_manager) -> Array:
	while true:
		var grid = deck_manager.peek(9)
		if grid.size() < 9:
			push_warning("CleanLayoutGenerator: deck ran out, got %d cards" % grid.size())
			return deck_manager.draw(grid.size())
		if _is_valid(grid):
			return deck_manager.draw(9)
		deck_manager.shuffle()
	return []  # Should never reach here


static func _is_valid(grid: Array) -> bool:
	if grid.size() < 9:
		return false
	return CleanController.detect_matches(grid).is_empty()
