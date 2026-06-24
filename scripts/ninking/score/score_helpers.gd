class_name ScoreHelpers
extends RefCounted

## Shared helper functions for scoring and auto-arranging.
## Extracted from score_calculator.gd and auto_arranger.gd to eliminate duplication.
##
## Key difference: score_calculator includes seal ×2 (red seal), auto_arranger
## skips seal for fast estimation. Use `include_seal` parameter to control.
##
## NOTE: See ScoreGroupComputer for the alternative low-level card helpers
## that intentionally exclude edition chips/mult and seal ×2 (AI estimation path).


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


## Apply economy effects (金剛力: mult_per_gold, 黄金律: x_per_gold).
## CL20: Shared between ScoreEffectCollector._apply_economy_effects() and
## ScoreCalculator.calculate_clean() to eliminate code duplication.
##
## Returns {earned_mult: int, earned_x: Array[int]} — caller applies to
## their own accumulator structure.
static func apply_economy_effects(effect: Dictionary, gold: int) -> Dictionary:
	var result: Dictionary = {
		earned_mult = 0,
		earned_x = [],
	}

	# mult_per_gold (金剛力)
	var mult_step: int = effect.get("mult_per_gold", 0)
	if mult_step > 0:
		var step: int = maxi(effect.get("mult_gold_step", 5), 1)  # CL21: guard div-by-zero
		var cap: int = effect.get("mult_gold_cap", 0)
		var earned: int = floori(float(gold) / float(step)) * mult_step
		if cap > 0:
			earned = mini(earned, cap)
		result.earned_mult = earned

	# x_per_gold (黄金律)
	var x_step: int = effect.get("x_per_gold", 0)
	if x_step > 1:
		var step_g: int = maxi(effect.get("x_gold_step", 15), 1)  # CL21: guard div-by-zero
		var cap_x: int = effect.get("x_gold_cap", 0)
		var count: int = floori(float(gold) / float(step_g))
		if cap_x > 0:
			count = mini(count, cap_x)
		for _i: int in range(count):
			result.earned_x.append(x_step)

	return result
