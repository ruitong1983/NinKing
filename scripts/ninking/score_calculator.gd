class_name ScoreCalculator
extends RefCounted

## Flat scoring model for NinKing (忍者牌 × 比鸡) — v3.2 integer scoring.
##
## Formula:
##   TotalChips = card_chips + hand_chips + ninja_add_chips + xi_chips
##   TotalMult  = hand_mult + ninja_add_mult + card_mult
##   Final      = TotalChips × TotalMult × ∏(all_x_mult)
##
## All ×mult effects are commutative — order in the stack doesn't matter.
## All values are integers. No rounding needed.

class ScoreResult:
	var total_score: int = 0
	var chips_sum: int = 0            # before ×mult
	var mult_sum: int = 0             # before ×mult
	var x_mult_product: int = 1       # product of all ×mult
	var breakdown: Dictionary = {}    # for UI display

	func _init() -> void:
		pass


## Main entry: score a complete 3-group arrangement.
##
## @param head_cards, mid_cards, tail_cards: 3 cards each
## @param head_eval, mid_eval, tail_eval: pre-computed evaluations
## @param ninjas: Array[Dictionary] — active ninja cards with effects
## @param star_chart_levels: Dictionary[HandType3, int] — level per hand type
## @param xi_result: XiDetector.XiResult — pre-detected xi patterns
## @param seal_lord_effects: Dictionary — Seal Lord overrides (e.g. "skip_head": true)
## @param gold: int — current gold, for economy-scaling ninjas (金剛力, 黄金律)
static func calculate(
	head_cards: Array, mid_cards: Array, tail_cards: Array,
	head_eval: HandEvaluator3.EvalResult,
	mid_eval: HandEvaluator3.EvalResult,
	tail_eval: HandEvaluator3.EvalResult,
	ninjas: Array = [],
	star_chart_levels: Dictionary = {},
	xi_result: XiDetector.XiResult = null,
	seal_lord_effects: Dictionary = {},
	gold: int = 0
) -> ScoreResult:

	var result: ScoreResult = ScoreResult.new()

	# Determine which groups are active (Seal Lord may disable groups)
	var score_head: bool = not seal_lord_effects.get("skip_head", false)
	var score_mid: bool = not seal_lord_effects.get("skip_mid", false)
	var score_tail: bool = not seal_lord_effects.get("skip_tail", false)

	# Apply Seal Lord "scatter_king" — all groups treated as 散牌
	var override_type: bool = seal_lord_effects.get("scatter_king", false)
	var head_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if override_type else head_eval.hand_type
	var mid_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if override_type else mid_eval.hand_type
	var tail_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if override_type else tail_eval.hand_type

	# Apply Seal Lord "hungry_ghost" — only A/K chip values count
	var hungry_ghost: bool = seal_lord_effects.get("hungry_ghost", false)

	# ═══════════════ Step 1: Card chips ═══════════════
	var card_chips: int = 0

	if score_head:
		for c: CardData.PlayingCard in head_cards:
			card_chips += _card_chips(c, hungry_ghost)
	if score_mid:
		for c: CardData.PlayingCard in mid_cards:
			card_chips += _card_chips(c, hungry_ghost)
	if score_tail:
		for c: CardData.PlayingCard in tail_cards:
			card_chips += _card_chips(c, hungry_ghost)

	result.breakdown["card_chips"] = card_chips

	# ═══════════════ Step 2: Hand base chips/mult (with star chart levels) ═══════════════
	var hand_chips: int = 0
	var hand_mult: int = 0

	if score_head:
		hand_chips += CardData.get_hand_type3_leveled_chips(head_type, star_chart_levels)
		hand_mult += CardData.get_hand_type3_leveled_mult(head_type, star_chart_levels)
	if score_mid:
		hand_chips += CardData.get_hand_type3_leveled_chips(mid_type, star_chart_levels)
		hand_mult += CardData.get_hand_type3_leveled_mult(mid_type, star_chart_levels)
	if score_tail:
		hand_chips += CardData.get_hand_type3_leveled_chips(tail_type, star_chart_levels)
		hand_mult += CardData.get_hand_type3_leveled_mult(tail_type, star_chart_levels)

	result.breakdown["hand_chips"] = hand_chips
	result.breakdown["hand_mult"] = hand_mult

	# ═══════════════ Step 3: Card enhancement/edition chips & mult ═══════════════
	var card_ench_chips: int = 0
	var card_ench_mult: int = 0

	if score_head:
		card_ench_chips += _group_ench_chips(head_cards)
		card_ench_mult += _group_ench_mult(head_cards)
	if score_mid:
		card_ench_chips += _group_ench_chips(mid_cards)
		card_ench_mult += _group_ench_mult(mid_cards)
	if score_tail:
		card_ench_chips += _group_ench_chips(tail_cards)
		card_ench_mult += _group_ench_mult(tail_cards)

	# ═══════════════ Step 4: Ninja effects ═══════════════
	var ninja_chips: int = 0
	var ninja_mult: int = 0
	var ninja_x_stack: Array[int] = []

	for ninja: Dictionary in ninjas:
		var effect: Dictionary = ninja.get("effect", {})

		# Check condition (group-targeted or hand-type condition)
		if _ninja_condition_met(effect, head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards, head_eval, mid_eval, tail_eval):
			ninja_chips += effect.get("add_chips", 0)
			ninja_mult += effect.get("add_mult", 0)
			var xm: int = effect.get("x_mult", 1)
			if xm > 1:
				ninja_x_stack.append(xm)

		# E6: 金剛力 — mult per gold step
		if effect.get("mult_per_gold", 0) > 0:
			var step: int = effect.get("mult_gold_step", 5)
			var cap: int = effect.get("mult_gold_cap", 10)
			var bonus: int = mini(gold / step, cap) * effect["mult_per_gold"]
			if bonus > 0:
				ninja_mult += bonus
				result.breakdown["golden_mult"] = result.breakdown.get("golden_mult", 0) + bonus

		# E7: 黄金律 — ×mult per gold step
		if effect.get("x_per_gold", 1) > 1:
			var step_x: int = effect.get("x_gold_step", 15)
			var cap_x: int = effect.get("x_gold_cap", 3)
			var count_x: int = mini(gold / step_x, cap_x)
			for _i: int in range(count_x):
				ninja_x_stack.append(effect["x_per_gold"])

	result.breakdown["ninja_chips"] = ninja_chips
	result.breakdown["ninja_mult"] = ninja_mult

	# ═══════════════ Step 5: Sum chips & base mult ═══════════════
	result.chips_sum = card_chips + hand_chips + card_ench_chips + ninja_chips
	result.mult_sum = hand_mult + card_ench_mult + ninja_mult

	# Add xi chips
	if xi_result and xi_result.chips_add > 0:
		result.chips_sum += xi_result.chips_add

	# Seal Lord "tail_x2" (独柱) — tail group multiplier ×2 as compensation
	var tail_x2: bool = seal_lord_effects.get("tail_x2", false)

	# ═══════════════ Step 6: Build ×mult stack ═══════════════
	var x_stack: Array[int] = []

	# Ninja ×mult
	for x: int in ninja_x_stack:
		x_stack.append(x)

	# Xi ×mult
	if xi_result:
		for x: int in xi_result.mult_x_stack:
			x_stack.append(x)

	# Card edition ×mult (Poly / 閃印)
	if score_head:
		_add_edition_x(head_cards, x_stack)
	if score_mid:
		_add_edition_x(mid_cards, x_stack)
	if score_tail:
		_add_edition_x(tail_cards, x_stack)

	# Card enhancement ×mult (Glass, Steel)
	if score_head:
		_add_ench_x(head_cards, head_type, x_stack)
	if score_mid:
		_add_ench_x(mid_cards, mid_type, x_stack)
	if score_tail:
		_add_ench_x(tail_cards, tail_type, x_stack)

	# Tail ×2 compensation (独柱 Seal Lord)
	if tail_x2:
		x_stack.append(2)

	# Apply all ×mult
	result.x_mult_product = 1
	for x: int in x_stack:
		result.x_mult_product *= x

	# Ensure minimums
	var final_chips: int = max(result.chips_sum, 1)
	var final_mult: int = max(result.mult_sum, 1)

	# ═══════════════ Final score ═══════════════
	result.total_score = final_chips * final_mult * result.x_mult_product

	result.breakdown["total_chips"] = result.chips_sum
	result.breakdown["total_mult"] = result.mult_sum
	result.breakdown["x_mult_product"] = result.x_mult_product
	result.breakdown["x_stack"] = x_stack

	return result


# ──────────────────────────── Helpers ────────────────────────────

static func _card_chips(c: CardData.PlayingCard, hungry_ghost: bool) -> int:
	if hungry_ghost:
		if not (c.rank == CardData.Rank.ACE or c.rank == CardData.Rank.KING):
			return 0
	var base: int = c.get_chip_value()
	# Red seal doubles card contribution
	base *= c.get_seal_x_chips()
	return base


# ── hand chips/mult helpers moved to CardData.get_hand_type3_leveled_*() ──


static func _group_ench_chips(cards: Array) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		total += c.get_enhancement_chips()
		total += c.get_edition_chips()
	return total


static func _group_ench_mult(cards: Array) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		total += c.get_enhancement_mult()
		total += c.get_edition_mult()
	return total


static func _add_edition_x(cards: Array, stack: Array[int]) -> void:
	for c: CardData.PlayingCard in cards:
		var x: int = c.get_edition_x_mult()
		if x > 1:
			stack.append(x)


static func _add_ench_x(cards: Array, group_type: CardData.HandType3, stack: Array[int]) -> void:
	for c: CardData.PlayingCard in cards:
		var x: int = c.get_enhancement_x_mult(group_type)
		if x > 1:
			stack.append(x)


## Check if a ninja's condition is met.
## Conditions can target specific hand types, group positions, etc.
## Economy-scaling effects (mult_per_gold, x_per_gold) have no condition.
static func _ninja_condition_met(effect: Dictionary,
		head_type: CardData.HandType3, mid_type: CardData.HandType3, tail_type: CardData.HandType3,
		_head_cards: Array, _mid_cards: Array, _tail_cards: Array,
		_head_eval: HandEvaluator3.EvalResult, _mid_eval: HandEvaluator3.EvalResult, _tail_eval: HandEvaluator3.EvalResult) -> bool:

	var cond: Dictionary = effect.get("condition", {})
	if cond.is_empty():
		return true  # no condition = always active

	# Check group position target
	var group: String = cond.get("group", "")
	match group:
		"head":
			return _check_cond_for_type(cond, head_type)
		"mid":
			return _check_cond_for_type(cond, mid_type)
		"tail":
			return _check_cond_for_type(cond, tail_type)
		_:
			# Global or any group
			return (_check_cond_for_type(cond, head_type)
				or _check_cond_for_type(cond, mid_type)
				or _check_cond_for_type(cond, tail_type))


static func _check_cond_for_type(cond: Dictionary, hand_type: CardData.HandType3) -> bool:
	# Hand type requirement
	var required_type: int = cond.get("hand_type", -1)
	if required_type != -1 and int(hand_type) != required_type:
		return false
	# "at_most_hand_type" — hand type ≤ value (for 虎头, 藏锋 etc.)
	var at_most: int = cond.get("at_most_hand_type", -1)
	if at_most != -1 and int(hand_type) > at_most:
		return false
	# "at_least_hand_type" — hand type ≥ value (for 龙尾 etc.)
	var at_least: int = cond.get("at_least_hand_type", -1)
	if at_least != -1 and int(hand_type) < at_least:
		return false
	return true
