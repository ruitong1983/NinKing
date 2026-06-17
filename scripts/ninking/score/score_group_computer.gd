class_name ScoreGroupComputer
extends RefCounted

## Per-group score computation: chips × mult × x_stack.
## Extracted from score_calculator.gd to reduce file size.
##
## Formula:
##   group_score = (card_chips + hand_chips + ench_chips + ninja_chips)
##               × (hand_mult + ench_mult + ninja_mult)
##               × ∏(ninja_x_mult) × ∏(card_x_mult)
##
## NOTE: Low-level card helpers here differ from ScoreHelpers — they do NOT
## include edition chips/mult or seal ×2. These differences match the existing
## score_calculator behavior and changing them would alter scoring results.
## See ScoreHelpers for the alternative (seal-aware, edition-inclusive) versions.


## Compute a single group's score (row or column):
## (card_chips + hand_chips + ench_chips + ninja_chips)
## × (hand_mult + ench_mult + ninja_mult)
## × ∏(ninja_x_mult) × ∏(card_x_mult)
static func compute_group_score(
	cards: Array,
	hand_type: CardData.HandType3,
	star_chart_levels: Dictionary,
	ninja_effects: Dictionary,
	hungry_ghost: bool
) -> int:
	var card_chips: int = _group_card_chips(cards, hungry_ghost)
	var hand_chips: int = CardData.get_hand_type3_leveled_chips(hand_type, star_chart_levels)
	var ench_chips: int = _group_ench_chips(cards)

	var chips: int = card_chips + hand_chips + ench_chips + ninja_effects.chips

	var hand_mult: int = CardData.get_hand_type3_leveled_mult(hand_type, star_chart_levels)
	var ench_mult: int = _group_ench_mult(cards)
	var mult: int = hand_mult + ench_mult + ninja_effects.mult

	# ×mult stack
	var x_product: int = 1
	for x: int in ninja_effects.x_stack:
		x_product *= x
	# Card ×mult (琉璃, 淬火, 极印)
	for c: CardData.PlayingCard in cards:
		var x_edition: int = c.get_edition_x_mult()
		if x_edition > 1:
			x_product *= x_edition
		var x_ench: int = c.get_enhancement_x_mult(hand_type)
		if x_ench > 1:
			x_product *= x_ench

	return max(chips, 1) * max(mult, 1) * x_product


## Apply group-level xi ×mult by multiplying the score.
static func apply_group_xi_to_score(score: int, x_mult: int) -> int:
	return score * x_mult


## Score a single row (head/mid/tail) and fill breakdown fields in result.
static func row_score(
	result: ScoreResult,
	group: String,
	cards: Array,
	hand_type: int,
	star_chart_levels: Dictionary,
	ninja_eff: Dictionary,
	hungry_ghost: bool
) -> void:
	var card_chips: int = _group_card_chips(cards, hungry_ghost)
	var hand_chips: int = CardData.get_hand_type3_leveled_chips(hand_type, star_chart_levels)
	var ench_chips: int = _group_ench_chips(cards)
	var total_chips: int = card_chips + hand_chips + ench_chips + ninja_eff.chips

	var hand_mult: int = CardData.get_hand_type3_leveled_mult(hand_type, star_chart_levels)
	var ench_mult: int = _group_ench_mult(cards)
	var total_mult: int = hand_mult + ench_mult + ninja_eff.mult

	var x_product: int = 1
	for xv: int in ninja_eff.x_stack:
		x_product *= xv
	for c: CardData.PlayingCard in cards:
		var x_edition: int = c.get_edition_x_mult()
		if x_edition > 1:
			x_product *= x_edition
		var x_ench: int = c.get_enhancement_x_mult(hand_type)
		if x_ench > 1:
			x_product *= x_ench

	var score_val: int = max(total_chips, 1) * max(total_mult, 1) * x_product

	match group:
		"head":
			result.head_score = score_val
			result.head_chips = total_chips
			result.head_card_chips = card_chips
			result.head_hand_chips = hand_chips
			result.head_ench_chips = ench_chips
			result.head_ninja_chips = ninja_eff.chips
			result.head_mult = total_mult
			result.head_hand_mult = hand_mult
			result.head_ench_mult = ench_mult
			result.head_ninja_mult = ninja_eff.mult
			result.head_ninja_x_stack = ninja_eff.x_stack.duplicate()
		"mid":
			result.mid_score = score_val
			result.mid_chips = total_chips
			result.mid_card_chips = card_chips
			result.mid_hand_chips = hand_chips
			result.mid_ench_chips = ench_chips
			result.mid_ninja_chips = ninja_eff.chips
			result.mid_mult = total_mult
			result.mid_hand_mult = hand_mult
			result.mid_ench_mult = ench_mult
			result.mid_ninja_mult = ninja_eff.mult
			result.mid_ninja_x_stack = ninja_eff.x_stack.duplicate()
		"tail":
			result.tail_score = score_val
			result.tail_chips = total_chips
			result.tail_card_chips = card_chips
			result.tail_hand_chips = hand_chips
			result.tail_ench_chips = ench_chips
			result.tail_ninja_chips = ninja_eff.chips
			result.tail_mult = total_mult
			result.tail_hand_mult = hand_mult
			result.tail_ench_mult = ench_mult
			result.tail_ninja_mult = ninja_eff.mult
			result.tail_ninja_x_stack = ninja_eff.x_stack.duplicate()


# ──────────────────────────── Low-level card helpers ────────────────────────────
# NOTE: These match original score_calculator behavior (no edition chips/mult,
# no seal ×2). ScoreHelpers has alternative versions with edition+seal support.

static func _group_card_chips(cards: Array, hungry_ghost: bool) -> int:
	var total: int = 0
	for card: CardData.PlayingCard in cards:
		total += card.get_chip_value()
	return total


static func _group_ench_chips(cards: Array) -> int:
	var total: int = 0
	for card: CardData.PlayingCard in cards:
		total += card.get_enhancement_chips()
	return total


static func _group_ench_mult(cards: Array) -> int:
	var total: int = 0
	for card: CardData.PlayingCard in cards:
		total += card.get_enhancement_mult()
	return total
