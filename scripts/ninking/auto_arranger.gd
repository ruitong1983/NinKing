class_name AutoArranger
extends RefCounted

## Brute-force optimal arrangement of 9 cards into 3 groups × 3 cards.
## Enumerates C(9,3) × C(6,3) = 1680 arrangements, filters by constraint,
## scores each, returns the best.
## v5.0 — per-group scoring model (跟组走), rows-only (列不计入AI评分).
##
## Arrangement class is defined in arrangement.gd (class_name Arrangement).
## Shared helpers in score_helpers.gd (class_name ScoreHelpers).


## Main entry point. Returns the best legal arrangement (or null if none).
## @param cards: 9 cards in hand
## @param head_ninja: {chips, mult, x_stack} — effects for 影
## @param mid_ninja: {chips, mult, x_stack} — effects for 瞬
## @param tail_ninja: {chips, mult, x_stack} — effects for 滅
## @param star_chart_levels: Dictionary[HandType3, int] — level of each hand type
## @param scoring_rules: Dictionary with optional overrides
static func find_best(cards: Array[CardData.PlayingCard],
		head_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] },
		mid_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] },
		tail_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] },
		star_chart_levels: Dictionary = {},
		scoring_rules: Dictionary = {}) -> Arrangement:

		assert(cards.size() == 9, "AutoArranger requires exactly 9 cards, got %d" % cards.size())

		var constraint: String = scoring_rules.get("constraint", "ascending")

		var best_arrangement: Arrangement = null
		var best_score: float = -1.0

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
					"descending":
						if not (head_eval.strength >= mid_eval.strength and mid_eval.strength >= tail_eval.strength):
							continue
					_:  # "ascending" and unknown values default to ascending
						if not (head_eval.strength <= mid_eval.strength and mid_eval.strength <= tail_eval.strength):
							continue

				var score: float = _fast_score(head_eval, mid_eval, tail_eval,
					head_typed, mid_typed, tail_typed,
					head_ninja, mid_ninja, tail_ninja,
					star_chart_levels, scoring_rules)

				if score > best_score:
					best_score = score
					best_arrangement = Arrangement.new(head_typed, mid_typed, tail_typed,
						head_eval, mid_eval, tail_eval)

		return best_arrangement


## Fast score estimation (v5.0 — rows only, no columns).
## Uses the independent-group scoring formula:
##   group_score = (card_chips + hand_chips + ench_chips + ninja_chips)
##               × (hand_mult + ench_mult + ninja_mult)
##               × ∏(ninja_x_mult) × ∏(card_x_mult)
## Score = head_score + mid_score + tail_score (columns are NOT considered
## in AI ranking — they are scored post-hoc by ScoreCalculator).
## No xi detection here — that's done separately after arrangement.
## Returns float for AI-internal comparison precision.
static func _fast_score(head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult,
		head_cards: Array[CardData.PlayingCard], mid_cards: Array[CardData.PlayingCard], tail_cards: Array[CardData.PlayingCard],
		head_ninja: Dictionary, mid_ninja: Dictionary, tail_ninja: Dictionary,
		star_chart_levels: Dictionary,
		rules: Dictionary) -> float:

	var scoring: String = rules.get("scoring", "all")
	var scatter_king: bool = rules.get("scatter_king", false)
	var hungry_ghost: bool = rules.get("hungry_ghost", false)
	var balance_groups: bool = rules.get("balance_groups", false)

	# ── Card chips ──
	var head_card: int = _group_card_chips(head_cards, hungry_ghost)
	var mid_card: int = _group_card_chips(mid_cards, hungry_ghost)
	var tail_card: int = _group_card_chips(tail_cards, hungry_ghost)

	# ── Hand type (with scatter_king override) ──
	var head_ht: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if scatter_king else head_eval.hand_type
	var mid_ht: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if scatter_king else mid_eval.hand_type
	var tail_ht: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if scatter_king else tail_eval.hand_type

	# ── Hand base chips/mult (with star chart levels) ──
	var head_hand_chips: int = CardData.get_hand_type3_leveled_chips(head_ht, star_chart_levels)
	var head_hand_mult: int = CardData.get_hand_type3_leveled_mult(head_ht, star_chart_levels)
	var mid_hand_chips: int = CardData.get_hand_type3_leveled_chips(mid_ht, star_chart_levels)
	var mid_hand_mult: int = CardData.get_hand_type3_leveled_mult(mid_ht, star_chart_levels)
	var tail_hand_chips: int = CardData.get_hand_type3_leveled_chips(tail_ht, star_chart_levels)
	var tail_hand_mult: int = CardData.get_hand_type3_leveled_mult(tail_ht, star_chart_levels)

	# ── Per-group scoring (v4.0 per-group model) ──
	var head_score: float = _per_group_score(
		head_card, head_hand_chips, head_hand_mult,
		head_ninja, head_cards, head_ht)
	var mid_score: float = _per_group_score(
		mid_card, mid_hand_chips, mid_hand_mult,
		mid_ninja, mid_cards, mid_ht)
	var tail_score: float = _per_group_score(
		tail_card, tail_hand_chips, tail_hand_mult,
		tail_ninja, tail_cards, tail_ht)

	# ── Score aggregation (rows only, no columns) ──
	var base_score: float = head_score + mid_score + tail_score

	if scoring == "tail_only":
		base_score = tail_score

	# ── Balance penalty (封印师: penalize uneven groups) ──
	if balance_groups:
		# Use simplified per-group score (no ninja x_stack which can distort)
		var hs: float = float(max(head_card + head_hand_chips, 1) * max(head_hand_mult, 1))
		var ms: float = float(max(mid_card + mid_hand_chips, 1) * max(mid_hand_mult, 1))
		var ts: float = float(max(tail_card + tail_hand_chips, 1) * max(tail_hand_mult, 1))
		var variance: float = abs(hs - ms) + abs(ms - ts) + abs(hs - ts)
		base_score -= variance * 0.3

	return max(base_score, 1.0)


## Compute a single group's per-group score:
## (card_chips + hand_chips + ench_chips + ninja_chips)
## × (hand_mult + ench_mult + ninja_mult)
## × ∏(ninja_x_mult) × ∏(card_x_mult)
static func _per_group_score(
	card_chips: int, hand_chips: int, hand_mult: int,
	ninja: Dictionary, cards: Array[CardData.PlayingCard],
	hand_type: CardData.HandType3
) -> float:
	var chips: int = card_chips + hand_chips + _group_ench_chips(cards) + ninja.get("chips", 0)
	var mult: int = hand_mult + _group_ench_mult(cards) + ninja.get("mult", 0)

	# ×mult stack
	var x_product: int = 1
	for x: int in ninja.get("x_stack", []):
		x_product *= x
	# Card ×mult
	for c: CardData.PlayingCard in cards:
		var x_edition: int = c.get_edition_x_mult()
		if x_edition > 1:
			x_product *= x_edition
		var x_ench: int = c.get_enhancement_x_mult(hand_type)
		if x_ench > 1:
			x_product *= x_ench

	return float(max(chips, 1) * max(mult, 1) * x_product)


## Delegated to ScoreHelpers (kept as private wrapper for backward compat).
## include_seal=false — AI estimation path (no seal ×2).
static func _group_card_chips(cards: Array[CardData.PlayingCard], hungry_ghost: bool) -> int:
	return ScoreHelpers.group_card_chips(cards, hungry_ghost, false)


static func _group_ench_chips(cards: Array) -> int:
	return ScoreHelpers.group_ench_chips(cards)


static func _group_ench_mult(cards: Array) -> int:
	return ScoreHelpers.group_ench_mult(cards)


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
