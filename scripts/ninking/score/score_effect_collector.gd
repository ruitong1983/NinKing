class_name ScoreEffectCollector
extends RefCounted

## Ninja effect routing: distribute effects to rows/columns based on conditions.
## Extracted from score_calculator.gd to reduce file size and improve maintainability.
##
## Responsibilities:
##   - collect_ninja_per_group() — route a single effect to head/mid/tail accumulators
##   - ninja_affected_groups() — determine which groups match a ninja's condition
##   - _collect_ninja_for_column() — route an effect to a single column accumulator
##   - _apply_economy_effects() — gold-scaling effects (金刚力, 黄金律)


## Apply a single ninja's effect to row ninja accumulators.
## Handles: chips, mult, x_mult, x_stack, economy, pair_even_chips.
## Group-targeted effects are determined by ninja_affected_groups().
static func collect_ninja_per_group(
	effect: Dictionary,
	head_type: CardData.HandType3, mid_type: CardData.HandType3, tail_type: CardData.HandType3,
	head_cards: Array, mid_cards: Array, tail_cards: Array,
	head_eval: HandEvaluator3.EvalResult, mid_eval: HandEvaluator3.EvalResult, tail_eval: HandEvaluator3.EvalResult,
	head_ninja: Dictionary, mid_ninja: Dictionary, tail_ninja: Dictionary,
	gold: int,
	xi_result = null
) -> void:
	var groups: Array[String] = ninja_affected_groups(effect,
		head_type, mid_type, tail_type,
		head_cards, mid_cards, tail_cards,
		head_eval, mid_eval, tail_eval)

	var _c_cond: Dictionary = effect.get("condition", {})

	# Xi-only condition: check xi_result before applying
	var cond_xi: String = _c_cond.get("xi", "")
	if cond_xi != "" and not _c_cond.has("hand_type") and not _c_cond.has("group"):
		if xi_result == null or not xi_result.has_any() or cond_xi not in xi_result.triggered:
			return  # Xi not triggered — skip effect entirely
		# Xi triggered — groups is empty (from ninja_affected_groups), fallback below will apply to all rows

	# ── has_2_and_ace: global condition — 9 cards contain both rank 2 and Ace → ×5 ──
	if _c_cond.get("has_2_and_ace", false):
		var has_two: bool = false
		var has_ace: bool = false
		for c: CardData.PlayingCard in head_cards + mid_cards + tail_cards:
			if c.rank == CardData.Rank.TWO: has_two = true
			if c.rank == CardData.Rank.ACE: has_ace = true
		if has_two and has_ace:
			var xv: int = effect.get("x_mult", 1)
			if xv > 1:
				head_ninja.x_stack.append(xv)
				mid_ninja.x_stack.append(xv)
				tail_ninja.x_stack.append(xv)
		return


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

		# ─── group_has_ace: per-group Ace bonus (独行者) ───
		var cond_g: Dictionary = _c_cond
		if cond_g.get("group_has_ace", false):
			var ace_chips: int = effect.get("ace_chips", 0)
			var ace_mult: int = effect.get("ace_mult", 0)
			if ace_chips > 0 or ace_mult > 0:
				for gn: String in groups:
					var cards_arr: Array
					match gn:
						"head":
							cards_arr = head_cards
						"mid":
							cards_arr = mid_cards
						_:
							cards_arr = tail_cards
					var has_ace: bool = false
					for card: CardData.PlayingCard in cards_arr:
						if card.rank == CardData.Rank.ACE:
							has_ace = true
							break
					if not has_ace:
						continue
					var target_a: Dictionary
					match gn:
						"head":
							target_a = head_ninja
						"mid":
							target_a = mid_ninja
						_:
							target_a = tail_ninja
					target_a.chips += ace_chips
					target_a.mult += ace_mult

# If a hand_type or group condition exists but didn't match → skip entirely
	if groups.is_empty() and has_any_condition(_c_cond):
		return
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


## Returns true if the condition targets specific groups/hand-types.
## Used by callers to distinguish "no condition" (apply all) from "condition no match" (skip).
static func has_any_condition(cond: Dictionary) -> bool:
	return cond.has("hand_type") or cond.has("group") or cond.has("at_least_hand_type") or cond.has("at_most_hand_type")




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
	gold: int,
	xi_result = null
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

	# Xi-only condition (no hand_type) → check xi_result and apply chips to column
	if cond.has("xi") and not cond.has("hand_type") and not cond.has("group"):
		var cond_xi_col: String = cond.get("xi", "")
		if cond_xi_col == "":
			return
		if xi_result == null or not xi_result.has_any() or cond_xi_col not in xi_result.triggered:
			return  # Xi not triggered — skip
		# Xi triggered — apply chips to this column
		var xi_chips_col: int = effect.get("add_chips", 0)
		if xi_chips_col > 0:
			col_ninja.chips += xi_chips_col
		var xi_mult_col: int = effect.get("add_mult", 0)
		if xi_mult_col > 0:
			col_ninja.mult += xi_mult_col
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


## Apply gold-scaling effects (金剛力, 黄金律) to a group.
## These are unconditional — they apply to ANY group (row or column).
## CL20: Delegates to ScoreHelpers.apply_economy_effects() to eliminate
## code duplication with ScoreCalculator.calculate_clean().
static func _apply_economy_effects(effect: Dictionary, gold: int, target: Dictionary) -> bool:
	var eco: Dictionary = ScoreHelpers.apply_economy_effects(effect, gold)
	var applied: bool = false
	if eco.earned_mult > 0:
		target.mult += eco.earned_mult
		applied = true
	if not eco.earned_x.is_empty():
		for xv: int in eco.earned_x:
			target.x_stack.append(xv)
		applied = true
	return applied
