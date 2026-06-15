class_name ScoreHelpers
extends RefCounted

## Shared helper functions for scoring and auto-arranging.
## Extracted from score_calculator.gd and auto_arranger.gd to eliminate duplication.
##
## Key difference: score_calculator includes seal ×2 (red seal), auto_arranger
## skips seal for fast estimation. Use `include_seal` parameter to control.


## Sum card base chip values in a group.
## include_seal=true: red seal ×2 is applied (scoring path).
## include_seal=false: raw chip values only (AI estimation path).
static func group_card_chips(cards: Array, hungry_ghost: bool, include_seal: bool = true) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		if hungry_ghost:
			if not (c.rank == CardData.Rank.ACE or c.rank == CardData.Rank.KING):
				continue
		var base: int = c.get_chip_value()
		if include_seal:
			base *= c.get_seal_x_chips()
		total += base
	return total


## Sum enhancement chips and edition chips from all cards in a group.
static func group_ench_chips(cards: Array) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		total += c.get_enhancement_chips()
		total += c.get_edition_chips()
	return total


## Sum enhancement mult and edition mult from all cards in a group.
static func group_ench_mult(cards: Array) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		total += c.get_enhancement_mult()
		total += c.get_edition_mult()
	return total
