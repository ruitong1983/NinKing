class_name ScoreCalculator
extends RefCounted

## Per-group independent scoring model for NinKing (忍者牌 × 比鸡) — v5.0.
##
## Formula:
##   group_score = (card_chips + hand_chips + ench_chips + ninja_chips)
##               × (hand_mult + ench_mult + ninja_mult)
##               × ∏(ninja_x_mult) × ∏(card_x_mult) × ∏(group_xi_x_mult)
##   col_score   = same formula, applied to vertical columns (散牌列 skipped)
##   total_raw   = Σ(head + mid + tail) + Σ(col0 + col1 + col2)
##   final       = total_raw × ∏(global_xi_x_mult)
##
## All ×mult effects are commutative — order in the stack doesn't matter.
## All values are integers.
##
## ScoreResult is defined in score_result.gd (class_name ScoreResult).
## Shared helpers in score_helpers.gd (class_name ScoreHelpers).

## Main entry: score a complete 3-group arrangement (v5.0 rows + columns additive).
##
## @param head_cards, mid_cards, tail_cards: 3 cards each
## @param head_eval, mid_eval, tail_eval: pre-computed evaluations
## @param col_evals: Array[HandEvaluator3.EvalResult] — 3 column evaluations (or empty)
## @param ninjas: Array[Dictionary] — active ninja cards with effects
## @param star_chart_levels: Dictionary[HandType3, int] — level per hand type
## @param xi_result: XiDetector.XiResult — pre-detected xi patterns
## @param seal_lord_effects: Dictionary — Seal Lord overrides
## @param gold: int — current gold, for economy-scaling ninjas
## @param xi_bonus: int — bonus added to all xi multipliers (e.g. 喜鹊 +1)
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
	gold: int = 0,
	xi_bonus: int = 0,
	xi_override: Dictionary = {}
) -> ScoreResult:

	var result: ScoreResult = ScoreResult.new()

	# ── Auto-extract xi_bonus/xi_override from ninjas (fix: callers never pass these) ──
	for ninja_p: Dictionary in ninjas:
		var eff: Dictionary = ninja_p.get("effect", {})
		xi_bonus += eff.get("xi_x_bonus", 0)
		var eff_override: Dictionary = eff.get("xi_override", {})
		for k: String in eff_override:
			if eff_override[k] > xi_override.get(k, 0):
				xi_override[k] = eff_override[k]

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

	# ── Collect per-group ninja effects (rows) ──
	var head_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
	var mid_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
	var tail_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }

	for ninja: Dictionary in ninjas:
		var effect: Dictionary = ninja.get("effect", {})
		collect_ninja_per_group(effect, head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval,
			head_ninja, mid_ninja, tail_ninja, gold)

	# ─── share_col_hand_to_rows (天下人): 非散牌列的牌型加成给三行 ───
	var share_col_hand: bool = false
	for ninja: Dictionary in ninjas:
		if ninja.get("effect", {}).get("share_col_hand_to_rows", false):
			share_col_hand = true
			break
	if share_col_hand and col_evals.size() == 3:
		var col_hand_chips: int = 0
		var col_hand_mult: int = 0
		for i: int in range(3):
			var ct: int = col_evals[i].hand_type if col_evals[i] != null else CardData.HandType3.HIGH_CARD_3
			if ct != CardData.HandType3.HIGH_CARD_3:
				col_hand_chips += CardData.get_hand_type3_leveled_chips(ct, star_chart_levels)
				col_hand_mult += CardData.get_hand_type3_leveled_mult(ct, star_chart_levels)
		head_ninja.chips += col_hand_chips
		mid_ninja.chips += col_hand_chips
		tail_ninja.chips += col_hand_chips
		head_ninja.mult += col_hand_mult
		mid_ninja.mult += col_hand_mult
		tail_ninja.mult += col_hand_mult
	# ─── share_tail_hand_to_head_mid (幻术大师): 滅牌型加成给影和瞬 ───
	var share_tail_hand: bool = false
	for ninja: Dictionary in ninjas:
		if ninja.get("effect", {}).get("share_tail_hand_to_head_mid", false):
			share_tail_hand = true
			break
	if share_tail_hand:
		var tail_hc: int = CardData.get_hand_type3_leveled_chips(tail_type, star_chart_levels)
		var tail_hm: int = CardData.get_hand_type3_leveled_mult(tail_type, star_chart_levels)
		head_ninja.chips += tail_hc
		mid_ninja.chips += tail_hc
		head_ninja.mult += tail_hm
		mid_ninja.mult += tail_hm

	# ── Compute each row's score ──
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
		result.head_card_chips = hc
		result.head_hand_chips = hh
		result.head_ench_chips = he
		result.head_ninja_chips = head_ninja.chips
		var hm: int = CardData.get_hand_type3_leveled_mult(head_type, star_chart_levels)
		var hem: int = _group_ench_mult(head_cards)
		result.head_mult = hm + hem + head_ninja.mult
		result.head_hand_mult = hm
		result.head_ench_mult = hem
		result.head_ninja_mult = head_ninja.mult
		result.head_ninja_x_stack = head_ninja.x_stack
		total_chips += result.head_chips
		total_mult += result.head_mult

	if score_mid:
		mid_score_val = _compute_group_score(
			mid_cards, mid_type, star_chart_levels, mid_ninja, hungry_ghost)
		var mc: int = _group_card_chips(mid_cards, hungry_ghost)
		var mh: int = CardData.get_hand_type3_leveled_chips(mid_type, star_chart_levels)
		var me: int = _group_ench_chips(mid_cards)
		result.mid_chips = mc + mh + me + mid_ninja.chips
		result.mid_card_chips = mc
		result.mid_hand_chips = mh
		result.mid_ench_chips = me
		result.mid_ninja_chips = mid_ninja.chips
		var mm: int = CardData.get_hand_type3_leveled_mult(mid_type, star_chart_levels)
		var mem: int = _group_ench_mult(mid_cards)
		result.mid_mult = mm + mem + mid_ninja.mult
		result.mid_hand_mult = mm
		result.mid_ench_mult = mem
		result.mid_ninja_mult = mid_ninja.mult
		result.mid_ninja_x_stack = mid_ninja.x_stack
		total_chips += result.mid_chips
		total_mult += result.mid_mult

	if score_tail:
		tail_score_val = _compute_group_score(
			tail_cards, tail_type, star_chart_levels, tail_ninja, hungry_ghost)
		var tc: int = _group_card_chips(tail_cards, hungry_ghost)
		var th: int = CardData.get_hand_type3_leveled_chips(tail_type, star_chart_levels)
		var te: int = _group_ench_chips(tail_cards)
		result.tail_chips = tc + th + te + tail_ninja.chips
		result.tail_card_chips = tc
		result.tail_hand_chips = th
		result.tail_ench_chips = te
		result.tail_ninja_chips = tail_ninja.chips
		var tm: int = CardData.get_hand_type3_leveled_mult(tail_type, star_chart_levels)
		var tem: int = _group_ench_mult(tail_cards)
		result.tail_mult = tm + tem + tail_ninja.mult
		result.tail_hand_mult = tm
		result.tail_ench_mult = tem
		result.tail_ninja_mult = tail_ninja.mult
		result.tail_ninja_x_stack = tail_ninja.x_stack
		total_chips += result.tail_chips
		total_mult += result.tail_mult

	result.head_score = head_score_val
	result.mid_score = mid_score_val
	result.tail_score = tail_score_val

	# ── v5.0: Column chip×mult scoring (independent of rows) ──
	var col_scores: Array[int] = []
	var col_total: int = 0

	if col_evals.size() == 3:
		# Build column cards from head/mid/tail
		var col_cards_array: Array[Array] = [
			[head_cards[0], mid_cards[0], tail_cards[0]],
			[head_cards[1], mid_cards[1], tail_cards[1]],
			[head_cards[2], mid_cards[2], tail_cards[2]],
		]
		var col_types: Array[CardData.HandType3] = [
			col_evals[0].hand_type,
			col_evals[1].hand_type,
			col_evals[2].hand_type,
		]
		if override_type:
			col_types = [
				CardData.HandType3.HIGH_CARD_3,
				CardData.HandType3.HIGH_CARD_3,
				CardData.HandType3.HIGH_CARD_3,
			]

		for i: int in range(3):
			if col_types[i] == CardData.HandType3.HIGH_CARD_3:
				col_scores.append(0)
			else:
				var col_ninja_eff: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
				for ninja: Dictionary in ninjas:
					var eff: Dictionary = ninja.get("effect", {})
					_collect_ninja_for_column(eff, col_types[i], col_ninja_eff, gold)
				# Pyramid effect does NOT apply to columns
				var cs: int = _compute_group_score(
					col_cards_array[i], col_types[i], star_chart_levels, col_ninja_eff, hungry_ghost)
				col_scores.append(cs)
				col_total += cs

	var total_raw: int = head_score_val + mid_score_val + tail_score_val + col_total

	# ── v5.0 Global xi ×mult ──
	result.global_xi_x_stack = _get_global_xi_x_stack(xi_result, xi_bonus, xi_override)

	# ── v5.0 Group-level xi ×mult ──
	if xi_result and xi_result.has_any():
		_apply_group_xi(result, xi_result, xi_override, xi_bonus,
			score_head, score_mid, score_tail, head_eval, mid_eval, tail_eval,
			col_scores)

	# ── v5.0 Recompute totals after xi ──
	total_raw = result.head_score + result.mid_score + result.tail_score
	col_total = 0
	for cs_val: int in col_scores:
		col_total += cs_val
	total_raw += col_total
	if tail_x2:
		total_raw *= 2
	total_raw = max(total_raw, 1)

	result.total_score = total_raw
	for x: int in result.global_xi_x_stack:
		result.total_score *= x
	result.total_score = max(result.total_score, 1)

	# Breakdown for debugging
	result.col_scores = col_scores
	result.col_total = col_total
	result.breakdown = {
		"head_score": result.head_score,
		"mid_score": result.mid_score,
		"tail_score": result.tail_score,
		"col_total": col_total,
		"col_scores": col_scores,
		"global_xi_x_stack": result.global_xi_x_stack,
	}

	return result


# ──────────────────────────── Per-group scoring ────────────────────────────

## Compute a single group's score (row or column):
## (card_chips + hand_chips + ench_chips + ninja_chips)
## × (hand_mult + ench_mult + ninja_mult)
## × ∏(ninja_x_mult) × ∏(card_x_mult)
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


# ──────────────────────────── Column ninja collection (v5.0) ────────────────────────────

## Collect ninja effects for a single column.
## Rules:
##   - Economy effects (mult_per_gold, x_per_gold) → apply to column
##   - Group condition → skip (columns don't have head/mid/tail mapping)
##   - hand_type condition (no group) → check column hand type
##   - No condition → unconditional, apply to column
static func _collect_ninja_for_column(
	effect: Dictionary,
	col_type: CardData.HandType3,
	col_ninja: Dictionary,
	gold: int
) -> void:
	# Pyramid effect — rows only, skip for columns
	if effect.get("pyramid_x3", false):
		return

	var cond: Dictionary = effect.get("condition", {})

	# Economy effects always apply (same as rows)
	_apply_economy_effects(effect, gold, col_ninja)

	# Group condition → skip columns (Q10: group doesn't map to columns)
	if cond.get("group", "") != "":
		return

	# Xi-only condition (no hand_type) → handled at global level, skip columns
	if cond.has("xi") and not cond.has("hand_type"):
		return

	# No condition → unconditional, apply to column
	if cond.is_empty():
		var chips: int = effect.get("add_chips", 0)
		var mult: int = effect.get("add_mult", 0)
		var x_mult: int = effect.get("x_mult", 1)
		var xs: Array = effect.get("x_stack", [])
		col_ninja.chips += chips
		col_ninja.mult += mult
		if x_mult > 1:
			col_ninja.x_stack.append(x_mult)
		for xv: int in xs:
			if xv > 1:
				col_ninja.x_stack.append(xv)
		return

	# hand_type condition (no group) → match column hand type
	if _col_matches_hand_type_cond(cond, col_type):
		var chips: int = effect.get("add_chips", 0)
		var mult: int = effect.get("add_mult", 0)
		var x_mult: int = effect.get("x_mult", 1)
		var xs2: Array = effect.get("x_stack", [])
		col_ninja.chips += chips
		col_ninja.mult += mult
		if x_mult > 1:
			col_ninja.x_stack.append(x_mult)
		for xv: int in xs2:
			if xv > 1:
				col_ninja.x_stack.append(xv)


static func _col_matches_hand_type_cond(cond: Dictionary, col_type: CardData.HandType3) -> bool:
	var required_type: int = cond.get("hand_type", -1)
	if required_type != -1 and int(col_type) != required_type:
		return false
	var at_most: int = cond.get("at_most_hand_type", -1)
	if at_most != -1 and int(col_type) > at_most:
		return false
	var at_least: int = cond.get("at_least_hand_type", -1)
	if at_least != -1 and int(col_type) < at_least:
		return false
	return true


# ──────────────────────────── Global xi ×mult ────────────────────────────

## Extract global xi ×mult values from xi_result triggered list.
## Global xis: 全黑(×2), 全红(×2), 全顺(×2), 全同花(×3), 四张(×5), 全三条(×4),
##             昇龍(×3), 背水(×4), 貧打(×4), 陣眼(×3), 均爵(×3), 三等(×5), 满堂(×5),
##             三合(×6), 双合(×4), 一合(×2)
## xi_bonus is added to each multiplier (e.g. 喜鹊 +1).
static func _get_global_xi_x_stack(xi_result: XiDetector.XiResult, xi_bonus: int = 0, xi_override: Dictionary = {}) -> Array[int]:
	var stack: Array[int] = []
	if not xi_result or not xi_result.has_any():
		return stack

	var xi_map: Dictionary = {}
	for i: int in XiDetector.XI_DEFINITIONS.size():
		var defn: Dictionary = XiDetector.XI_DEFINITIONS[i]
		xi_map[defn["name"]] = defn["x_mult"]

	var global_xi_names: Array[String] = ["全黑", "全红", "全顺", "全同花", "四张", "全三条",
			"昇龍", "背水", "貧打", "陣眼", "均爵", "三等", "满堂",
			"三合", "双合", "一合"]
	for name: String in xi_result.triggered:
		if name in global_xi_names:
			var x_val: int = xi_override.get(name, xi_map.get(name, 1))
			var x_with_bonus: int = x_val + xi_bonus
			if x_with_bonus > 1:
				stack.append(x_with_bonus)

	return stack


# ──────────────────────────── Ninja per-group collection (rows) ────────────────────────────

## Apply a single ninja's effect to row ninja accumulators.
## Handles: chips, mult, x_mult, x_stack, economy, pair_even_chips.
## Group-targeted effects are determined by ninja_affected_groups().
static func collect_ninja_per_group(
	effect: Dictionary,
	head_type: CardData.HandType3, mid_type: CardData.HandType3, tail_type: CardData.HandType3,
	head_cards: Array, mid_cards: Array, tail_cards: Array,
	head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult, tail_eval: HandEvaluator3.EvalResult,
	head_ninja: Dictionary, mid_ninja: Dictionary, tail_ninja: Dictionary,
	gold: int
) -> void:
	var groups: Array[String] = ninja_affected_groups(effect,
		head_type, mid_type, tail_type,
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval)

	var chips: int = effect.get("add_chips", 0)
	var mult: int = effect.get("add_mult", 0)
	var x_mult: int = effect.get("x_mult", 1)
	var x_stack: Array = effect.get("x_stack", [])

# Economy effects always apply to ALL groups
	var has_economy := _apply_economy_effects(effect, gold, head_ninja)
	has_economy = _apply_economy_effects(effect, gold, mid_ninja) or has_economy
	has_economy = _apply_economy_effects(effect, gold, tail_ninja) or has_economy

	# Apply chips/mult/x_mult/x_stack to affected groups
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
		for xv: int in x_stack:
			if xv > 1:
				target.x_stack.append(xv)

	# ─── pair_even_chips: count even number cards (2/4/6/8/10) in PAIR groups ───
	var pair_even: int = effect.get("pair_even_chips", 0)
	if pair_even > 0:
		for group_name: String in groups:
			var cards_arr: Array
			match group_name:
				"head":
					cards_arr = head_cards
				"mid":
					cards_arr = mid_cards
				_:
					cards_arr = tail_cards
			var even_count: int = 0
			for card: CardData.PlayingCard in cards_arr:
				if card.rank >= 2 and card.rank <= 10 and card.rank % 2 == 0:
					even_count += 1
			var target_p: Dictionary
			match group_name:
				"head":
					target_p = head_ninja
				"mid":
					target_p = mid_ninja
				_:
					target_p = tail_ninja
			target_p.chips += pair_even * even_count

# If this ninja has no group condition and no economy, it applies to ALL groups
	var has_x_stack: bool = false
	for xv: int in x_stack:
		if xv > 1:
			has_x_stack = true
			break
	if groups.is_empty() and not has_economy and (chips > 0 or mult > 0 or x_mult > 1 or has_x_stack):
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
		for xv: int in x_stack:
			if xv > 1:
				head_ninja.x_stack.append(xv)
				mid_ninja.x_stack.append(xv)
				tail_ninja.x_stack.append(xv)

	# ─── pyramid_x3: per-group ×3 based on ascending hand types ───
	if effect.get("pyramid_x3", false):
		# 影：无条件×3（金字塔基底）
		head_ninja.x_stack.append(3)
		# 瞬：牌型 > 影 → ×3
		if int(mid_type) > int(head_type):
			mid_ninja.x_stack.append(3)
		# 滅：牌型 > 瞬 → ×3
		if int(tail_type) > int(mid_type):
			tail_ninja.x_stack.append(3)


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
		# Multi-group condition: head_or_mid
		if group == "head_or_mid":
			var hm_result: Array[String] = []
			if _check_cond_for_type(cond, head_type):
				hm_result.append("head")
			if _check_cond_for_type(cond, mid_type):
				hm_result.append("mid")
			return hm_result

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
	return true


# ──────────────────────────── Effect consolidation (Phase H) ────────────────────────────

## Single-pass analysis of all ninja effects. Returns Dictionary with pre-computed
## effects for all downstream consumers. Call once per play, then pass the result.
##
## Lifecycle: Valid only between prepare_play() and finalize_play(). After
## finalize_play(), scaling mutations make the summary stale — discard and re-analyze.
static func analyze_effects(
	head_cards: Array,
	mid_cards: Array,
	tail_cards: Array,
	head_eval,
	mid_eval,
	tail_eval,
	col_evals: Array,
	ninjas: Array,
	gold: int,
	xi_result = null
) -> Dictionary:

	var head_type: int = CardData.HandType3.HIGH_CARD_3
	var mid_type: int = CardData.HandType3.HIGH_CARD_3
	var tail_type: int = CardData.HandType3.HIGH_CARD_3
	if head_eval != null: head_type = head_eval.hand_type
	if mid_eval != null: mid_type = mid_eval.hand_type
	if tail_eval != null: tail_type = tail_eval.hand_type

	var per_group: Dictionary = {
		"head": {"chips": 0, "mult": 0, "x_stack": []},
		"mid": {"chips": 0, "mult": 0, "x_stack": []},
		"tail": {"chips": 0, "mult": 0, "x_stack": []},
	}
	var col_summary: Array = [
		{"chips": 0, "mult": 0, "x_stack": []},
		{"chips": 0, "mult": 0, "x_stack": []},
		{"chips": 0, "mult": 0, "x_stack": []},
	]

	var anim_contribs: Array = []
	var gold_on_play: int = 0
	var interest_cap: int = 0
	var constraint_override: String = ""
	var scoring_override: String = ""
	var scaling_ninjas: Array = []
	var xi_bonus_val: int = 0
	var xi_override_val: Dictionary = {}
	var tools: Dictionary = {}
	var share_col_hand_to_rows: bool = false
	var share_tail_hand_to_head_mid: bool = false

	for ninja: Dictionary in ninjas:
		var effect: Dictionary = ninja.get("effect", {})

		# 10) Detect 天下人 share_col_hand_to_rows
		if effect.get("share_col_hand_to_rows", false):
			share_col_hand_to_rows = true
		# 11) Detect 幻术大师 share_tail_hand_to_head_mid
		if effect.get("share_tail_hand_to_head_mid", false):
			share_tail_hand_to_head_mid = true

		# 1) Row effects
		collect_ninja_per_group(effect,
			head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval,
			per_group.head, per_group.mid, per_group.tail,
			gold)

		# 2) Column effects
		var col_count: int = col_evals.size()
		for ci: int in range(col_summary.size()):
			if ci < col_count:
				var ct: int = col_evals[ci].hand_type if col_evals[ci] != null else CardData.HandType3.HIGH_CARD_3
				_collect_ninja_for_column(effect, ct, col_summary[ci], gold)

		# 3) Economy gold from play
		if effect.get("gold_per_xi", 0) > 0:
			if xi_result != null and xi_result.has_any():
				gold_on_play += xi_result.triggered.size() * effect["gold_per_xi"]
		# 4) Interest cap
		if effect.get("interest_cap_bonus", 0) > 0:
			interest_cap += effect["interest_cap_bonus"]

		# 5) Rule overrides
		var co: String = effect.get("constraint_override", "")
		if co != "":
			constraint_override = co
		var so: String = effect.get("scoring_override", "")
		if so != "":
			scoring_override = so

		# 6) Xi bonuses
		xi_bonus_val += effect.get("xi_x_bonus", 0)
		var eff_xi_ov: Dictionary = effect.get("xi_override", {})
		for k: String in eff_xi_ov:
			if eff_xi_ov[k] > xi_override_val.get(k, 0):
				xi_override_val[k] = eff_xi_ov[k]

		# 7) Scaling (hold references for NinjaScaling)
		if ninja.has("scaling") and not ninja["scaling"].is_empty():
			scaling_ninjas.append(ninja)

		# 8) Animation contributions
		var chips: int = effect.get("add_chips", 0)
		var mult: int = effect.get("add_mult", 0)
		var has_raw: bool = chips > 0 or mult > 0
		var has_economy_anim: bool = effect.get("mult_per_gold", 0) > 0 or effect.get("x_per_gold", 1) > 1
		if has_raw or has_economy_anim:
			var xi_cond: String = effect.get("condition", {}).get("xi", "")
			if xi_cond == "" or (xi_result != null and xi_result.has_any() and xi_cond in xi_result.triggered):
				var groups: Array[String] = ninja_affected_groups(effect,
					head_type, mid_type, tail_type,
					head_cards, mid_cards, tail_cards,
					head_eval, mid_eval, tail_eval)
				var row_indices: Array[int] = []
				for g: String in groups:
					match g:
						"head": row_indices.append(0)
						"mid": row_indices.append(1)
						"tail": row_indices.append(2)
				if groups.is_empty():
					row_indices = [0, 1, 2]
				anim_contribs.append({
					"id": ninja.get("id", ""),
					"chips": chips,
					"mult": mult,
					"groups": row_indices,
					"is_economy": not has_raw and has_economy_anim,
				})

		# 9) Tool effects (currently unprocessed)
		var ep: int = effect.get("extra_plays", 0)
		if ep != 0:
			tools["extra_plays"] = tools.get("extra_plays", 0) + ep
		var er: int = effect.get("extra_redraws", 0)
		if er > 0:
			tools["extra_redraws"] = tools.get("extra_redraws", 0) + er
		if effect.get("first_play_x2", false):
			tools["first_play_x2"] = true
		if effect.get("death_save", false):
			tools["death_save"] = true

	return {
		"per_group": per_group,
		"col": col_summary,
		"anim_contribs": anim_contribs,
		"gold_on_play": gold_on_play,
		"interest_cap_bonus": interest_cap,
		"constraint_override": constraint_override,
		"scoring_override": scoring_override,
		"scaling_ninjas": scaling_ninjas,
		"xi_bonus": xi_bonus_val,
		"xi_override": xi_override_val,
		"tools": tools,
		"share_col_hand_to_rows": share_col_hand_to_rows,
		"share_tail_hand_to_head_mid": share_tail_hand_to_head_mid,
	}


## Calculate score using a pre-computed ninja effects summary.
## Skips the ninja iteration loops (already done in analyze_effects()).
static func calculate_with_summary(
	head_cards: Array,
	mid_cards: Array,
	tail_cards: Array,
	head_eval,
	mid_eval,
	tail_eval,
	col_evals: Array,
	summary: Dictionary,
	star_chart_levels: Dictionary = {},
	xi_result = null,
	seal_lord_effects: Dictionary = {},
) -> ScoreResult:

	var result: ScoreResult = ScoreResult.new()

	var per_group: Dictionary = summary.get("per_group", {})
	var head_ninja: Dictionary = per_group.get("head", {"chips": 0, "mult": 0, "x_stack": []})
	var mid_ninja: Dictionary = per_group.get("mid", {"chips": 0, "mult": 0, "x_stack": []})
	var tail_ninja: Dictionary = per_group.get("tail", {"chips": 0, "mult": 0, "x_stack": []})
	var col_summary: Array = summary.get("col", [{}, {}, {}])
	var xi_bonus: int = summary.get("xi_bonus", 0)
	var xi_override: Dictionary = summary.get("xi_override", {})

	var score_head: bool = not seal_lord_effects.get("skip_head", false)
	var score_mid: bool = not seal_lord_effects.get("skip_mid", false)
	var score_tail: bool = not seal_lord_effects.get("skip_tail", false)
	var override_type: bool = seal_lord_effects.get("scatter_king", false)
	var hungry_ghost: bool = seal_lord_effects.get("hungry_ghost", false)
	var tail_x2: bool = seal_lord_effects.get("tail_x2", false)

	var head_type: int = CardData.HandType3.HIGH_CARD_3 if override_type else head_eval.hand_type
	var mid_type: int = CardData.HandType3.HIGH_CARD_3 if override_type else mid_eval.hand_type
	var tail_type: int = CardData.HandType3.HIGH_CARD_3 if override_type else tail_eval.hand_type

	# ─── 天下人: 非散牌列的牌型加成给三行 ───
	if summary.get("share_col_hand_to_rows", false) and col_evals.size() == 3:
		var col_hand_chips: int = 0
		var col_hand_mult: int = 0
		for i: int in range(3):
			var ct: int = col_evals[i].hand_type if col_evals[i] != null else CardData.HandType3.HIGH_CARD_3
			if ct != CardData.HandType3.HIGH_CARD_3:
				col_hand_chips += CardData.get_hand_type3_leveled_chips(ct, star_chart_levels)
				col_hand_mult += CardData.get_hand_type3_leveled_mult(ct, star_chart_levels)
		head_ninja.chips += col_hand_chips
		mid_ninja.chips += col_hand_chips
		tail_ninja.chips += col_hand_chips
		head_ninja.mult += col_hand_mult
		mid_ninja.mult += col_hand_mult
		tail_ninja.mult += col_hand_mult
	# ─── 幻术大师: 滅牌型加成给影和瞬 ───
	if summary.get("share_tail_hand_to_head_mid", false):
		var tail_hc: int = CardData.get_hand_type3_leveled_chips(tail_type, star_chart_levels)
		var tail_hm: int = CardData.get_hand_type3_leveled_mult(tail_type, star_chart_levels)
		head_ninja.chips += tail_hc
		mid_ninja.chips += tail_hc
		head_ninja.mult += tail_hm
		mid_ninja.mult += tail_hm

	# ── Compute each row ──
	if score_head:
		_row_score(result, "head", head_cards, head_type, star_chart_levels, head_ninja, hungry_ghost)
	if score_mid:
		_row_score(result, "mid", mid_cards, mid_type, star_chart_levels, mid_ninja, hungry_ghost)
	if score_tail:
		_row_score(result, "tail", tail_cards, tail_type, star_chart_levels, tail_ninja, hungry_ghost)

	# ── Column scoring ──
	var col_scores: Array[int] = []
	var col_total: int = 0
	if col_evals.size() == 3:
		var col_cards_array: Array[Array] = [
			[head_cards[0], mid_cards[0], tail_cards[0]],
			[head_cards[1], mid_cards[1], tail_cards[1]],
			[head_cards[2], mid_cards[2], tail_cards[2]],
		]
		for i: int in range(3):
			var ct: int = col_evals[i].hand_type
			if ct == CardData.HandType3.HIGH_CARD_3:
				col_scores.append(0)
				continue
			var cs: int = _compute_group_score(
				col_cards_array[i], ct, star_chart_levels,
				col_summary[i] if i < col_summary.size() else {"chips": 0, "mult": 0, "x_stack": []},
				hungry_ghost)
			col_scores.append(cs)
			col_total += cs

	var total_raw: int = result.head_score + result.mid_score + result.tail_score + col_total

	# ── Global xi ×mult ──
	result.global_xi_x_stack = _get_global_xi_x_stack(xi_result, xi_bonus, xi_override)

	# ── Group-level xi ──
	if xi_result and xi_result.has_any():
		_apply_group_xi(result, xi_result, xi_override, xi_bonus,
			score_head, score_mid, score_tail, head_eval, mid_eval, tail_eval,
			col_scores)

	# ── Recompute totals after xi ──
	total_raw = result.head_score + result.mid_score + result.tail_score
	col_total = 0
	for cs_val: int in col_scores:
		col_total += cs_val
	total_raw += col_total
	if tail_x2:
		total_raw *= 2
	total_raw = max(total_raw, 1)

	result.total_score = total_raw
	for x: int in result.global_xi_x_stack:
		result.total_score *= x
	result.total_score = max(result.total_score, 1)

	result.col_scores = col_scores
	result.col_total = col_total
	result.breakdown = {
		"head_score": result.head_score,
		"mid_score": result.mid_score,
		"tail_score": result.tail_score,
		"col_total": col_total,
		"col_scores": col_scores,
		"global_xi_x_stack": result.global_xi_x_stack,
	}

	return result


## Score a single row (head/mid/tail) and fill breakdown fields in result.
static func _row_score(
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


# ──────────────────────────── Chip and mult helper ────────────────────────────

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


# ──────────────────────────── Economy effects ────────────────────────────

## Apply gold-scaling effects (金剛力, 黄金律) to a group.
## These are unconditional — they apply to ANY group (row or column).
static func _apply_economy_effects(effect: Dictionary, gold: int, target: Dictionary) -> bool:
	var applied: bool = false
	var mult_step: int = effect.get("mult_per_gold", 0)
	if mult_step > 0:
		var step: int = effect.get("mult_gold_step", 5)
		var cap: int = effect.get("mult_gold_cap", 0)
		var earned: int = floori(float(gold) / float(step)) * mult_step
		if cap > 0:
			earned = mini(earned, cap)
		if earned > 0:
			target.mult += earned
			applied = true

	var x_step: int = effect.get("x_per_gold", 0)
	if x_step > 1:
		var step_g: int = effect.get("x_gold_step", 15)
		var cap_x: int = effect.get("x_gold_cap", 0)
		var count: int = floori(float(gold) / float(step_g))
		if cap_x > 0:
			count = mini(count, cap_x)
		for _i: int in range(count):
			target.x_stack.append(x_step)
		if count > 0:
			applied = true

	return applied


# ──────────────────────────── Group-level xi ×mult ────────────────────────────

static func _apply_group_xi(
	result: ScoreResult,
	xi_result,
	xi_override: Dictionary,
	xi_bonus: int,
	score_head: bool, score_mid: bool, score_tail: bool,
	head_eval, mid_eval, tail_eval,
	col_scores: Array
) -> void:
	for xi_name: String in xi_result.triggered:
		var x_val: int = xi_override.get(xi_name, 0)
		if x_val == 0:
			for defn: Dictionary in XiDetector.XI_DEFINITIONS:
				if defn["name"] == xi_name:
					x_val = defn["x_mult"]
					break
		x_val += xi_bonus
		if x_val <= 1:
			continue

		match xi_name:
			"三清":
				if score_head:
					_apply_group_xi_to_group(result, "head", x_val)
				if score_mid:
					_apply_group_xi_to_group(result, "mid", x_val)
				if score_tail:
					_apply_group_xi_to_group(result, "tail", x_val)
			"三顺清":
				if score_head:
					_apply_group_xi_to_group(result, "head", x_val)
				if score_mid:
					_apply_group_xi_to_group(result, "mid", x_val)
				if score_tail:
					_apply_group_xi_to_group(result, "tail", x_val)
			"顺清打头":
				if score_head:
					_apply_group_xi_to_group(result, "head", x_val)
			"豹子":
				for g: String in ["head", "mid", "tail"]:
					var ev = {"head": head_eval, "mid": mid_eval, "tail": tail_eval}[g]
					if ev != null and ev.hand_type == CardData.HandType3.THREE_OF_KIND_3:
						_apply_group_xi_to_group(result, g, x_val)


static func _apply_group_xi_to_group(result: ScoreResult, group: String, x_mult: int) -> void:
	match group:
		"head":
			result.head_score *= x_mult
		"mid":
			result.mid_score *= x_mult
		"tail":
			result.tail_score *= x_mult
