class_name AutoArranger
extends RefCounted

## Brute-force optimal arrangement of 9 cards into 3 groups × 3 cards.
## Enumerates C(9,3) × C(6,3) = 1680 arrangements, filters by constraint,
## scores each, returns the best.
## v3.2 — scoring values integer.

class Arrangement:
	var head: Array[CardData.PlayingCard]   # 影 (weakest)
	var mid: Array[CardData.PlayingCard]    # 瞬
	var tail: Array[CardData.PlayingCard]   # 滅 (strongest)
	var head_eval: HandEvaluator3.EvalResult
	var mid_eval: HandEvaluator3.EvalResult
	var tail_eval: HandEvaluator3.EvalResult

	func _init(h: Array, m: Array, t: Array,
			   he: HandEvaluator3.EvalResult, me: HandEvaluator3.EvalResult,
			   te: HandEvaluator3.EvalResult) -> void:
		head = _to_typed(h)
		mid = _to_typed(m)
		tail = _to_typed(t)
		head_eval = he; mid_eval = me; tail_eval = te

	func is_legal() -> bool:
		return head_eval.strength <= mid_eval.strength and mid_eval.strength <= tail_eval.strength

	static func _to_typed(arr: Array) -> Array[CardData.PlayingCard]:
		var result: Array[CardData.PlayingCard] = []
		for item in arr:
			result.append(item as CardData.PlayingCard)
		return result


## Main entry point. Returns the best legal arrangement (or null if none).
## @param cards: 9 cards in hand (Array[CardData.PlayingCard])
## @param ninja_chips_add: sum of all ninja add_chips effects
## @param ninja_mult_add: sum of all ninja add_mult effects
## @param ninja_x_mult_stack: Array of ×mult values from ninjas
## @param star_chart_levels: Dictionary[HandType3, int] — level of each hand type
## @param scoring_rules: Dictionary with optional overrides:
##     "constraint": "ascending" (default) | "none" | "equal"
##     "scoring": "all" (default) | "tail_only"
static func find_best(cards: Array[CardData.PlayingCard],
		ninja_chips_add: int = 0,
		ninja_mult_add: int = 0,
		ninja_x_mult_stack: Array = [],
		star_chart_levels: Dictionary = {},
		scoring_rules: Dictionary = {}) -> Arrangement:

	assert(cards.size() == 9, "AutoArranger requires exactly 9 cards, got %d" % cards.size())

	var constraint: String = scoring_rules.get("constraint", "ascending")

	var best_arrangement: Arrangement = null
	var best_score: float = -1.0  # float for AI-internal weight comparison

	var head_combos: Array = _combinations(cards, 3)

	for head_raw: Array in head_combos:
		var remaining_for_mid: Array = _array_diff(cards, head_raw)

		var mid_combos: Array = _combinations(remaining_for_mid, 3)

		for mid_raw: Array in mid_combos:
			var tail_raw: Array = _array_diff(remaining_for_mid, mid_raw)

			var head_typed: Array[CardData.PlayingCard] = _to_typed_arr(head_raw)
			var mid_typed: Array[CardData.PlayingCard] = _to_typed_arr(mid_raw)
			var tail_typed: Array[CardData.PlayingCard] = _to_typed_arr(tail_raw)

			var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_typed)
			var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_typed)
			var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_typed)

			match constraint:
				"none":
					pass
				"equal":
					if head_eval.hand_type != mid_eval.hand_type or mid_eval.hand_type != tail_eval.hand_type:
						continue
				_:
					if not (head_eval.strength <= mid_eval.strength and mid_eval.strength <= tail_eval.strength):
						continue

			var score: float = _fast_score(head_eval, mid_eval, tail_eval,
				head_typed, mid_typed, tail_typed,
				ninja_chips_add, ninja_mult_add, ninja_x_mult_stack,
				star_chart_levels, scoring_rules)

			if score > best_score:
				best_score = score
				best_arrangement = Arrangement.new(head_typed, mid_typed, tail_typed,
					head_eval, mid_eval, tail_eval)

	return best_arrangement


## Fast score estimation (no xi detection — that's done separately after).
## Returns float for AI comparison precision.
static func _fast_score(head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult,
		head_cards: Array[CardData.PlayingCard], mid_cards: Array[CardData.PlayingCard], tail_cards: Array[CardData.PlayingCard],
		ninja_chips_add: int, ninja_mult_add: int,
		ninja_x_mult: Array, star_chart_levels: Dictionary,
		rules: Dictionary) -> float:

	var scoring: String = rules.get("scoring", "all")
	var scatter_king: bool = rules.get("scatter_king", false)
	var hungry_ghost: bool = rules.get("hungry_ghost", false)
	var balance_groups: bool = rules.get("balance_groups", false)

	# ── Card chips ──
	var head_card: int = _group_card_chips(head_cards, hungry_ghost)
	var mid_card: int = _group_card_chips(mid_cards, hungry_ghost)
	var tail_card: int = _group_card_chips(tail_cards, hungry_ghost)

	# ── Hand base chips/mult (with star chart upgrades) ──
	var head_ht: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if scatter_king else head_eval.hand_type
	var mid_ht: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if scatter_king else mid_eval.hand_type
	var tail_ht: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if scatter_king else tail_eval.hand_type

	var head_hand_chips: int = CardData.get_hand_type3_leveled_chips(head_ht, star_chart_levels)
	var head_hand_mult: int = CardData.get_hand_type3_leveled_mult(head_ht, star_chart_levels)
	var mid_hand_chips: int = CardData.get_hand_type3_leveled_chips(mid_ht, star_chart_levels)
	var mid_hand_mult: int = CardData.get_hand_type3_leveled_mult(mid_ht, star_chart_levels)
	var tail_hand_chips: int = CardData.get_hand_type3_leveled_chips(tail_ht, star_chart_levels)
	var tail_hand_mult: int = CardData.get_hand_type3_leveled_mult(tail_ht, star_chart_levels)

	# ── Per-group scores (before ninja bonuses) ──
	var head_raw: int = (head_card + head_hand_chips) * max(head_hand_mult, 1)
	var mid_raw: int = (mid_card + mid_hand_chips) * max(mid_hand_mult, 1)
	var tail_raw: int = (tail_card + tail_hand_chips) * max(tail_hand_mult, 1)

	# ── Ninja bonuses (applied to total, not per-group) ──
	var total_chips: int = 0
	if scoring != "tail_only":
		total_chips += head_card + mid_card + head_hand_chips + mid_hand_chips
	total_chips += tail_card + tail_hand_chips + ninja_chips_add

	var total_mult: int = 0
	if scoring != "tail_only":
		total_mult += head_hand_mult + mid_hand_mult
	total_mult += tail_hand_mult + ninja_mult_add

	for x: int in ninja_x_mult:
		total_mult *= x

	var base_score: float = float(max(total_chips, 1) * max(total_mult, 1))

	# ── Balance penalty (封印师: penalize uneven groups) ──
	if balance_groups:
		var variance: float = abs(head_raw - mid_raw) + abs(mid_raw - tail_raw) + abs(head_raw - tail_raw)
		base_score -= variance * 0.3

	return max(base_score, 1.0)


## Card chips for a group, with optional hungry_ghost filter (only A/K count).
static func _group_card_chips(cards: Array[CardData.PlayingCard], hungry_ghost: bool) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		if hungry_ghost:
			if c.rank == CardData.Rank.ACE or c.rank == CardData.Rank.KING:
				total += c.get_chip_value()
		else:
			total += c.get_chip_value()
	return total


# ──────────────────────────── Combinatorics ────────────────────────────

static func _combinations(items: Array, k: int) -> Array:
	var result: Array = []
	_combine(items, k, 0, [], result)
	return result


static func _combine(items: Array, k: int, start: int, current: Array, result: Array) -> void:
	if current.size() == k:
		result.append(current.duplicate())
		return
	for i: int in range(start, items.size()):
		current.append(items[i])
		_combine(items, k, i + 1, current, result)
		current.pop_back()


static func _array_diff(all_items: Array, subset: Array) -> Array:
	var result: Array = []
	for item in all_items:
		var found: bool = false
		for sub in subset:
			if (item as CardData.PlayingCard).is_equal(sub as CardData.PlayingCard):
				found = true
				break
		if not found:
			result.append(item)
	return result


static func _to_typed_arr(arr: Array) -> Array[CardData.PlayingCard]:
	var result: Array[CardData.PlayingCard] = []
	for item in arr:
		result.append(item as CardData.PlayingCard)
	return result
