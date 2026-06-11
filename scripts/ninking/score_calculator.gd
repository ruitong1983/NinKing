class_name ScoreCalculator
extends RefCounted

## Per-group independent scoring model for NinKing (忍者牌 × 比鸡) — v4.0.
##
## Formula:
##   group_score = (card_chips + hand_chips + ench_chips + ninja_chips)
##               × (hand_mult + ench_mult + ninja_mult)
##               × ∏(ninja_x_mult) × ∏(card_x_mult) × ∏(group_xi_x_mult)
##   total_raw  = Σ(head_score + mid_score + tail_score)
##   final      = total_raw × ∏(col_x_mult) × ∏(global_xi_x_mult)
##
## All ×mult effects are commutative — order in the stack doesn't matter.
## All values are integers.

class ScoreResult:
	var total_score: int = 0
	var head_score: int = 0
	var mid_score: int = 0
	var tail_score: int = 0
	var col_x_stack: Array[int] = []       # column ×mult values (2/4/8/16/32)
	var global_xi_x_stack: Array[int] = [] # global xi ×mult
	# Per-group chips and mult (base + ench + ninja, before ×stack)
	var head_chips: int = 0
	var head_mult: int = 0
	var mid_chips: int = 0
	var mid_mult: int = 0
	var tail_chips: int = 0
	var tail_mult: int = 0
	var chips_sum: int = 0                 # sum of all chips (for backward compat)
	var mult_sum: int = 0                  # sum of all base mult (for backward compat)
	var breakdown: Dictionary = {}

	func _init() -> void:
		pass


## Main entry: score a complete 3-group arrangement (v4.0 per-group model).
##
## @param head_cards, mid_cards, tail_cards: 3 cards each
## @param head_eval, mid_eval, tail_eval: pre-computed evaluations
## @param col_evals: Array[HandEvaluator3.EvalResult] — 3 column evaluations (or empty)
## @param ninjas: Array[Dictionary] — active ninja cards with effects
## @param star_chart_levels: Dictionary[HandType3, int] — level per hand type
## @param xi_result: XiDetector.XiResult — pre-detected xi patterns
## @param seal_lord_effects: Dictionary — Seal Lord overrides
## @param gold: int — current gold, for economy-scaling ninjas
static func calculate(
	head_cards: Array, mid_cards: Array, tail_cards: Array,
	head_eval: HandEvaluator3.EvalResult,
	mid_eval: HandEvaluator3.EvalResult,
	tail_eval: HandEvaluator3.EvalResult,
	col_evals: Array = [],
	ninjas: Array = [],
	star_chart_levels: Dictionary = {},
	xi_result: XiDetector.XiResult = null,
	seal_lord_effects: Dictionary = {},
	gold: int = 0
) -> ScoreResult:

	var result: ScoreResult = ScoreResult.new()

	# ── Seal Lord overrides ──
	var score_head: bool = not seal_lord_effects.get("skip_head", false)
	var score_mid: bool = not seal_lord_effects.get("skip_mid", false)
	var score_tail: bool = not seal_lord_effects.get("skip_tail", false)
	var override_type: bool = seal_lord_effects.get("scatter_king", false)
	var hungry_ghost: bool = seal_lord_effects.get("hungry_ghost", false)
	var tail_x2: bool = seal_lord_effects.get("tail_x2", false)

	var head_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if override_type else head_eval.hand_type
	var mid_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if override_type else mid_eval.hand_type
	var tail_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3 if override_type else tail_eval.hand_type

	# ── Collect per-group ninja effects ──
	var head_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
	var mid_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
	var tail_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }

	for ninja: Dictionary in ninjas:
		var effect: Dictionary = ninja.get("effect", {})
		collect_ninja_per_group(effect, head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval,
			head_ninja, mid_ninja, tail_ninja, gold)

	# ── Compute each group's score ──
	var head_score_val: int = 0
	var mid_score_val: int = 0
	var tail_score_val: int = 0
	var total_chips: int = 0
	var total_mult: int = 0

	if score_head:
		head_score_val = _compute_group_score(
			head_cards, head_type, star_chart_levels, head_ninja, hungry_ghost)
		var hc: int = _group_card_chips(head_cards, hungry_ghost)
		var hh: int = CardData.get_hand_type3_leveled_chips(head_type, star_chart_levels)
		var he: int = _group_ench_chips(head_cards)
		result.head_chips = hc + hh + he + head_ninja.chips
		var hm: int = CardData.get_hand_type3_leveled_mult(head_type, star_chart_levels)
		var hem: int = _group_ench_mult(head_cards)
		result.head_mult = hm + hem + head_ninja.mult
		total_chips += result.head_chips
		total_mult += result.head_mult

	if score_mid:
		mid_score_val = _compute_group_score(
			mid_cards, mid_type, star_chart_levels, mid_ninja, hungry_ghost)
		var mc: int = _group_card_chips(mid_cards, hungry_ghost)
		var mh: int = CardData.get_hand_type3_leveled_chips(mid_type, star_chart_levels)
		var me: int = _group_ench_chips(mid_cards)
		result.mid_chips = mc + mh + me + mid_ninja.chips
		var mm: int = CardData.get_hand_type3_leveled_mult(mid_type, star_chart_levels)
		var mem: int = _group_ench_mult(mid_cards)
		result.mid_mult = mm + mem + mid_ninja.mult
		total_chips += result.mid_chips
		total_mult += result.mid_mult

	if score_tail:
		tail_score_val = _compute_group_score(
			tail_cards, tail_type, star_chart_levels, tail_ninja, hungry_ghost)
		var tc: int = _group_card_chips(tail_cards, hungry_ghost)
		var th: int = CardData.get_hand_type3_leveled_chips(tail_type, star_chart_levels)
		var te: int = _group_ench_chips(tail_cards)
		result.tail_chips = tc + th + te + tail_ninja.chips
		var tm: int = CardData.get_hand_type3_leveled_mult(tail_type, star_chart_levels)
		var tem: int = _group_ench_mult(tail_cards)
		result.tail_mult = tm + tem + tail_ninja.mult
		total_chips += result.tail_chips
		total_mult += result.tail_mult

	result.head_score = head_score_val
	result.mid_score = mid_score_val
	result.tail_score = tail_score_val

	# ── Total raw sum ──
	var total_raw: int = head_score_val + mid_score_val + tail_score_val

	# ── Column ×mult ──
	result.col_x_stack = _get_col_x_stack(col_evals)

	# ── Tail ×2 compensation (独柱 Seal Lord) ──
	if tail_x2:
		result.col_x_stack.append(2)

	# ── Global xi ×mult (from xi_result triggered list) ──
	result.global_xi_x_stack = _get_global_xi_x_stack(xi_result)

	# ── Group-level xi ×mult (三清/三顺清/顺清打头) — already handled in _compute_group_score ──
	# These are injected via group_xi_stack passed to _compute_group_score.
	# We reconnect by re-checking xi_result triggered for our group scores:
	if xi_result and xi_result.has_any():
		if "三清" in xi_result.triggered:
			if score_head: head_score_val = _apply_group_xi_to_score(head_score_val, 2)
			if score_mid:  mid_score_val  = _apply_group_xi_to_score(mid_score_val, 2)
			if score_tail: tail_score_val = _apply_group_xi_to_score(tail_score_val, 2)
		if "三顺清" in xi_result.triggered:
			if score_head: head_score_val = _apply_group_xi_to_score(head_score_val, 3)
			if score_mid:  mid_score_val  = _apply_group_xi_to_score(mid_score_val, 3)
			if score_tail: tail_score_val = _apply_group_xi_to_score(tail_score_val, 3)
		if "顺清打头" in xi_result.triggered and score_head:
			head_score_val = _apply_group_xi_to_score(head_score_val, 2)

	# Recompute total_raw with group xi applied
	total_raw = head_score_val + mid_score_val + tail_score_val
	result.head_score = head_score_val
	result.mid_score = mid_score_val
	result.tail_score = tail_score_val

	# ── Ensure minimums ──
	total_raw = max(total_raw, 1)

	# ── Compute final score ──
	result.total_score = total_raw
	for x: int in result.col_x_stack:
		result.total_score *= x
	for x: int in result.global_xi_x_stack:
		result.total_score *= x

	# Ensure minimum
	result.total_score = max(result.total_score, 1)

	# ── Breakdown ──
	result.chips_sum = total_chips
	result.mult_sum = total_mult
	result.breakdown["head_score"] = head_score_val
	result.breakdown["mid_score"] = mid_score_val
	result.breakdown["tail_score"] = tail_score_val
	result.breakdown["col_x_stack"] = result.col_x_stack
	result.breakdown["global_xi_x_stack"] = result.global_xi_x_stack

	return result


# ──────────────────────────── Per-group scoring ────────────────────────────

## Compute a single group's score:
## (card_chips + hand_chips + ench_chips + ninja_chips)
## × (hand_mult + ench_mult + ninja_mult)
## × ∏(ninja_x_mult) × ∏(card_x_mult)
##
## Group-level xi ×mult is NOT included here — it's applied separately after
## per-group scores to avoid needing xi_result inside this function.
static func _compute_group_score(
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
static func _apply_group_xi_to_score(score: int, x_mult: int) -> int:
	return score * x_mult


# ──────────────────────────── Column ×mult ────────────────────────────

## Build column ×mult stack from column evaluations.
## 散牌(×1=skip), 对子(×2), 顺子(×4), 同花(×8), 同花顺(×16), 豹子(×32)
static func _get_col_x_stack(col_evals: Array) -> Array[int]:
	var stack: Array[int] = []
	if col_evals.size() != 3:
		return stack
	for eval_result in col_evals:
		var x: int = _col_type_to_x_mult(eval_result.hand_type)
		if x > 1:
			stack.append(x)
	return stack


static func _col_type_to_x_mult(ht: CardData.HandType3) -> int:
	match ht:
		CardData.HandType3.THREE_OF_KIND_3:
			return 32
		CardData.HandType3.STRAIGHT_FLUSH_3:
			return 16
		CardData.HandType3.FLUSH_3:
			return 8
		CardData.HandType3.STRAIGHT_3:
			return 4
		CardData.HandType3.ONE_PAIR_3:
			return 2
		_:
			return 1


# ──────────────────────────── Global xi ×mult ────────────────────────────

## Extract global xi ×mult values from xi_result triggered list.
## Global xis: 全黑(×2), 全红(×2), 全顺(×2), 全同花(×3), 四张(×5), 全三条(×4)
static func _get_global_xi_x_stack(xi_result: XiDetector.XiResult) -> Array[int]:
	var stack: Array[int] = []
	if not xi_result or not xi_result.has_any():
		return stack

	var xi_map: Dictionary = {}
	for i: int in XiDetector.XI_DEFINITIONS.size():
		var defn: Dictionary = XiDetector.XI_DEFINITIONS[i]
		xi_map[defn["name"]] = defn["x_mult"]

	# Only global xis are extracted here
	var global_xi_names: Array[String] = ["全黑", "全红", "全顺", "全同花", "四张", "全三条"]
	for name: String in xi_result.triggered:
		if name in global_xi_names:
			var x_val: int = xi_map.get(name, 1)
			if x_val > 1:
				stack.append(x_val)

	return stack


# ──────────────────────────── Ninja per-group collection ────────────────────────────

## Evaluate a single ninja effect and distribute to the correct group(s).
static func collect_ninja_per_group(
	effect: Dictionary,
	head_type: CardData.HandType3, mid_type: CardData.HandType3, tail_type: CardData.HandType3,
	_head_cards: Array, _mid_cards: Array, _tail_cards: Array,
	_head_eval: HandEvaluator3.EvalResult, _mid_eval: HandEvaluator3.EvalResult, _tail_eval: HandEvaluator3.EvalResult,
	head_ninja: Dictionary, mid_ninja: Dictionary, tail_ninja: Dictionary,
	gold: int
) -> void:
	var groups: Array[String] = ninja_affected_groups(effect,
		head_type, mid_type, tail_type,
		_head_cards, _mid_cards, _tail_cards,
		_head_eval, _mid_eval, _tail_eval)

	var chips: int = effect.get("add_chips", 0)
	var mult: int = effect.get("add_mult", 0)
	var x_mult: int = effect.get("x_mult", 1)

	# Economy effects (金剛力, 黄金律) always apply to ALL groups
	var has_economy: bool = false
	if effect.get("mult_per_gold", 0) > 0:
		has_economy = true
		var step: int = effect.get("mult_gold_step", 5)
		var cap: int = effect.get("mult_gold_cap", 10)
		@warning_ignore("integer_division")
		var bonus: int = mini(gold / step, cap) * effect["mult_per_gold"]
		if bonus > 0:
			head_ninja.mult += bonus
			mid_ninja.mult += bonus
			tail_ninja.mult += bonus

	if effect.get("x_per_gold", 1) > 1:
		has_economy = true
		var step_x: int = effect.get("x_gold_step", 15)
		var cap_x: int = effect.get("x_gold_cap", 3)
		@warning_ignore("integer_division")
		var count_x: int = mini(gold / step_x, cap_x)
		for _i: int in range(count_x):
			var x_val: int = effect["x_per_gold"]
			head_ninja.x_stack.append(x_val)
			mid_ninja.x_stack.append(x_val)
			tail_ninja.x_stack.append(x_val)

	# Apply chips/mult/x_mult to affected groups
	for group_name: String in groups:
		var target: Dictionary
		match group_name:
			"head":
				target = head_ninja
			"mid":
				target = mid_ninja
			_:
				target = tail_ninja

		target.chips += chips
		target.mult += mult
		if x_mult > 1:
			target.x_stack.append(x_mult)

	# If this ninja has no group condition and no economy, it applies to ALL groups
	if groups.is_empty() and not has_economy and (chips > 0 or mult > 0 or x_mult > 1):
		head_ninja.chips += chips
		mid_ninja.chips += chips
		tail_ninja.chips += chips
		head_ninja.mult += mult
		mid_ninja.mult += mult
		tail_ninja.mult += mult
		if x_mult > 1:
			head_ninja.x_stack.append(x_mult)
			mid_ninja.x_stack.append(x_mult)
			tail_ninja.x_stack.append(x_mult)


## Determine which groups a ninja's condition targets.
## Returns ["head"], ["mid"], ["tail"], or [] for all groups.
static func ninja_affected_groups(
	effect: Dictionary,
	head_type: CardData.HandType3, mid_type: CardData.HandType3, tail_type: CardData.HandType3,
	_head_cards: Array, _mid_cards: Array, _tail_cards: Array,
	_head_eval: HandEvaluator3.EvalResult, _mid_eval: HandEvaluator3.EvalResult, _tail_eval: HandEvaluator3.EvalResult
) -> Array[String]:
	var cond: Dictionary = effect.get("condition", {})
	if cond.is_empty():
		return []  # empty = all groups (handled by caller)

	var group: String = cond.get("group", "")
	if group != "":
		# Single-group condition
		if _check_cond_for_type(cond, head_type) and group == "head":
			return ["head"]
		if _check_cond_for_type(cond, mid_type) and group == "mid":
			return ["mid"]
		if _check_cond_for_type(cond, tail_type) and group == "tail":
			return ["tail"]
		return []

	# No specific group — check which groups satisfy the condition
	var result: Array[String] = []
	if _check_cond_for_type(cond, head_type):
		result.append("head")
	if _check_cond_for_type(cond, mid_type):
		result.append("mid")
	if _check_cond_for_type(cond, tail_type):
		result.append("tail")

	# Special: some conditions reference xi (global) — don't match groups
	if cond.has("xi") and not cond.has("hand_type"):
		result.clear()

	return result


static func _check_cond_for_type(cond: Dictionary, hand_type: CardData.HandType3) -> bool:
	var required_type: int = cond.get("hand_type", -1)
	if required_type != -1 and int(hand_type) != required_type:
		return false
	var at_most: int = cond.get("at_most_hand_type", -1)
	if at_most != -1 and int(hand_type) > at_most:
		return false
	var at_least: int = cond.get("at_least_hand_type", -1)
	if at_least != -1 and int(hand_type) < at_least:
		return false
	# "strict_ascending_types" — all 3 groups must form strict ascending hand types
	if cond.get("strict_ascending_types", false):
		# This is checked per-ninja at a higher level; skip group-level check here
		pass
	return true


# ──────────────────────────── Helpers ────────────────────────────

static func _group_card_chips(cards: Array, hungry_ghost: bool) -> int:
	var total: int = 0
	for c: CardData.PlayingCard in cards:
		if hungry_ghost:
			if not (c.rank == CardData.Rank.ACE or c.rank == CardData.Rank.KING):
				continue
		var base: int = c.get_chip_value()
		base *= c.get_seal_x_chips()
		total += base
	return total


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
