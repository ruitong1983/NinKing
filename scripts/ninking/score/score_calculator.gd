class_name ScoreCalculator
extends RefCounted

## Per-group independent scoring orchestrator for NinKing (忍者牌 × 比鸡) — v5.0.
##
## Thin orchestrator that composes Submodules:
##   - ScoreEffectCollector  — route ninja effects to rows/columns
##   - ScoreGroupComputer    — per-group chips × mult computation
##   - ScoreXiHandler        — global/group xi ×mult + 双头蛇
##   - ScoreHelpers          — low-level card value helpers
##   - ScoreResult           — result data class
##
## Formula:
##   group_score = (card_chips + hand_chips + ench_chips + ninja_chips)
##               × (hand_mult + ench_mult + ninja_mult)
##               × ∏(ninja_x_mult) × ∏(card_x_mult) × ∏(group_xi_x_mult)
##   total_raw   = Σ(head + mid + tail) + Σ(col0 + col1 + col2)
##   final       = total_raw × ∏(global_xi_x_mult)


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

	# ── Auto-extract xi_bonus/xi_override/xi_max_mult from ninjas (fix: callers never pass these) ──
	var xi_max_mult: bool = false
	for ninja_p: Dictionary in ninjas:
		var eff: Dictionary = ninja_p.get("effect", {})
		xi_bonus += eff.get("xi_x_bonus", 0)
		var eff_override: Dictionary = eff.get("xi_override", {})
		for k: String in eff_override:
			if eff_override[k] > xi_override.get(k, 0):
				xi_override[k] = eff_override[k]
			if eff.get("xi_max_mult_stack", false):
				xi_max_mult = true

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
		ScoreEffectCollector.collect_ninja_per_group(effect, head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval,
			head_ninja, mid_ninja, tail_ninja, gold, xi_result)

	# ─── Cross-group bonuses ───
	var flags: Dictionary = _detect_cross_group_flags(ninjas)
	_apply_cross_group_bonuses(flags, head_ninja, mid_ninja, tail_ninja,
		head_type, mid_type, tail_type, col_evals, star_chart_levels)

	# ─── 独尊之印: 前两行不计分，只对第三行计分×3 ───
	if flags.get("tail_only_x3", false):
		score_head = false
		score_mid = false

	# ── Compute each row's score ──
	var head_score_val: int = 0
	var mid_score_val: int = 0
	var tail_score_val: int = 0

	if score_head:
		head_score_val = ScoreGroupComputer.compute_group_score(
			head_cards, head_type, star_chart_levels, head_ninja, hungry_ghost)
		ScoreGroupComputer.row_score(result, "head",
			head_cards, head_type, star_chart_levels, head_ninja, hungry_ghost)

	if score_mid:
		mid_score_val = ScoreGroupComputer.compute_group_score(
			mid_cards, mid_type, star_chart_levels, mid_ninja, hungry_ghost)
		ScoreGroupComputer.row_score(result, "mid",
			mid_cards, mid_type, star_chart_levels, mid_ninja, hungry_ghost)

	if score_tail:
		tail_score_val = ScoreGroupComputer.compute_group_score(
			tail_cards, tail_type, star_chart_levels, tail_ninja, hungry_ghost)
		ScoreGroupComputer.row_score(result, "tail",
			tail_cards, tail_type, star_chart_levels, tail_ninja, hungry_ghost)

	# ─── 独尊之印: 尾行×3 ───
	if flags.get("tail_only_x3", false):
		tail_score_val *= 3
		result.tail_score *= 3

	result.head_score = head_score_val
	result.mid_score = mid_score_val
	result.tail_score = tail_score_val

	# ── v5.0: Column chip×mult scoring (independent of rows) ──
	var col_scores: Array[int] = []
	var col_total: int = 0
	var total_raw: int = 0

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
					ScoreEffectCollector._collect_ninja_for_column(eff, col_types[i], col_ninja_eff, gold, xi_result)
				# 均衡之印 applies to columns too
				if flags.eq_active:
					col_ninja_eff.chips += flags.eq_chips
				var cs: int = ScoreGroupComputer.compute_group_score(
					col_cards_array[i], col_types[i], star_chart_levels, col_ninja_eff, hungry_ghost)
				col_scores.append(cs)
				col_total += cs

	# ── v5.0 Global xi ×mult ──
	result.global_xi_x_stack = ScoreXiHandler.get_global_xi_x_stack(xi_result, xi_bonus, xi_override, xi_max_mult)

	# ── v5.0 Group-level xi ×mult ──
	if xi_result and xi_result.has_any():
		ScoreXiHandler.apply_group_xi(result, xi_result, xi_override, xi_bonus,
			score_head, score_mid, score_tail, head_eval, mid_eval, tail_eval,
			col_scores)

	# ── v5.0 Recompute totals after xi ──
	total_raw = result.head_score + result.mid_score + result.tail_score
	col_total = 0
	for cs_val: int in col_scores:
		col_total += cs_val
	total_raw += col_total

	# ── 双头蛇: 行+列 相同牌型计分×2 ──
	if flags.duplicate_hand_x2:
		ScoreXiHandler.apply_duplicate_hand_x2(result, head_type, mid_type, tail_type,
			col_evals, override_type, col_scores)
		total_raw = result.head_score + result.mid_score + result.tail_score
		col_total = 0
		for cs_val2: int in col_scores:
			col_total += cs_val2
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


# ──────────────────────────── Phase H: Effect consolidation ────────────────────────────

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
	var xi_max_mult_flag: bool = false
	var tools: Dictionary = {}
	var share_col_hand_to_rows: bool = false
	var share_tail_hand_to_head_mid: bool = false
	var summary_duplicate_hand_x2: bool = false
	var summary_eq_chips: int = 0
	var summary_tail_only_x3: bool = false

	for ninja: Dictionary in ninjas:
		var effect: Dictionary = ninja.get("effect", {})

		# 10) Detect 天下人 share_col_hand_to_rows
		if effect.get("share_col_hand_to_rows", false):
			share_col_hand_to_rows = true
		# 11) Detect 幻术大师 share_tail_hand_to_head_mid
		if effect.get("share_tail_hand_to_head_mid", false):
			share_tail_hand_to_head_mid = true
		# 12) Detect 双头蛇 duplicate_hand_x2
		if effect.get("duplicate_hand_x2", false):
			summary_duplicate_hand_x2 = true
		# 13) Detect 均衡之印 all_non_scatter_add_chips
		var ec: int = effect.get("all_non_scatter_add_chips", 0)
		if ec > 0:
			summary_eq_chips = max(summary_eq_chips, ec)
		# 14) Detect 独尊之印 tail_only_x3
		if effect.get("tail_only_x3", false):
			summary_tail_only_x3 = true

		# 1) Row effects
		ScoreEffectCollector.collect_ninja_per_group(effect,
			head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval,
			per_group.head, per_group.mid, per_group.tail,
			gold, xi_result)

		# 2) Column effects
		var col_count: int = col_evals.size()
		for ci: int in range(col_summary.size()):
			if ci < col_count:
				var ct: int = col_evals[ci].hand_type if col_evals[ci] != null else CardData.HandType3.HIGH_CARD_3
				ScoreEffectCollector._collect_ninja_for_column(effect, ct, col_summary[ci], gold, xi_result)

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

		# 6) Xi bonuses & 龙之眼
		xi_bonus_val += effect.get("xi_x_bonus", 0)
		if effect.get("xi_max_mult_stack", false):
			xi_max_mult_flag = true
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
				var groups: Array[String] = ScoreEffectCollector.ninja_affected_groups(effect,
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
		"xi_max_mult": xi_max_mult_flag,
		"tools": tools,
		"share_col_hand_to_rows": share_col_hand_to_rows,
		"share_tail_hand_to_head_mid": share_tail_hand_to_head_mid,
		"duplicate_hand_x2": summary_duplicate_hand_x2,
		"all_non_scatter_add_chips": summary_eq_chips,
		"tail_only_x3": summary_tail_only_x3,
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
	var xi_max_mult: bool = summary.get("xi_max_mult", false)

	var score_head: bool = not seal_lord_effects.get("skip_head", false)
	var score_mid: bool = not seal_lord_effects.get("skip_mid", false)
	var score_tail: bool = not seal_lord_effects.get("skip_tail", false)
	var override_type: bool = seal_lord_effects.get("scatter_king", false)
	var hungry_ghost: bool = seal_lord_effects.get("hungry_ghost", false)
	var tail_x2: bool = seal_lord_effects.get("tail_x2", false)

	var head_type: int = CardData.HandType3.HIGH_CARD_3 if override_type else head_eval.hand_type
	var mid_type: int = CardData.HandType3.HIGH_CARD_3 if override_type else mid_eval.hand_type
	var tail_type: int = CardData.HandType3.HIGH_CARD_3 if override_type else tail_eval.hand_type

	# ─── Cross-group bonuses (from pre-computed summary) ───
	_apply_cross_group_bonuses(summary, head_ninja, mid_ninja, tail_ninja,
		head_type, mid_type, tail_type, col_evals, star_chart_levels)

	# ─── 独尊之印: 前两行不计分，只对第三行计分×3 ───
	var summary_tail_only_x3: bool = summary.get("tail_only_x3", false)
	if summary_tail_only_x3:
		score_head = false
		score_mid = false

	# ── Compute each row ──
	if score_head:
		ScoreGroupComputer.row_score(result, "head", head_cards, head_type, star_chart_levels, head_ninja, hungry_ghost)
	if score_mid:
		ScoreGroupComputer.row_score(result, "mid", mid_cards, mid_type, star_chart_levels, mid_ninja, hungry_ghost)
	if score_tail:
		ScoreGroupComputer.row_score(result, "tail", tail_cards, tail_type, star_chart_levels, tail_ninja, hungry_ghost)
	if summary_tail_only_x3:
		result.tail_score *= 3

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
			var col_ninja_eff: Dictionary = col_summary[i] if i < col_summary.size() else {"chips": 0, "mult": 0, "x_stack": []}
			# 均衡之印 applies to columns too
			var eq_chips: int = summary.get("all_non_scatter_add_chips", 0)
			if eq_chips > 0 and head_type > CardData.HandType3.HIGH_CARD_3 \
				and mid_type > CardData.HandType3.HIGH_CARD_3 \
				and tail_type > CardData.HandType3.HIGH_CARD_3:
				col_ninja_eff.chips += eq_chips
			var cs: int = ScoreGroupComputer.compute_group_score(
				col_cards_array[i], ct, star_chart_levels,
				col_ninja_eff, hungry_ghost)
			col_scores.append(cs)
			col_total += cs

	var total_raw: int = result.head_score + result.mid_score + result.tail_score + col_total

	# ── Global xi ×mult ──
	result.global_xi_x_stack = ScoreXiHandler.get_global_xi_x_stack(xi_result, xi_bonus, xi_override, xi_max_mult)

	# ── Group-level xi ──
	if xi_result and xi_result.has_any():
		ScoreXiHandler.apply_group_xi(result, xi_result, xi_override, xi_bonus,
			score_head, score_mid, score_tail, head_eval, mid_eval, tail_eval,
			col_scores)

	# ── Recompute totals after xi ──
	total_raw = result.head_score + result.mid_score + result.tail_score
	col_total = 0
	for cs_val: int in col_scores:
		col_total += cs_val
	total_raw += col_total

	# ── 双头蛇: 行+列 相同牌型计分×2 ──
	if summary.get("duplicate_hand_x2", false):
		ScoreXiHandler.apply_duplicate_hand_x2(result, head_type, mid_type, tail_type,
			col_evals, override_type, col_scores)
		total_raw = result.head_score + result.mid_score + result.tail_score
		col_total = 0
		for cs_val2: int in col_scores:
			col_total += cs_val2
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


# ──────────────────────────── Cross-group bonuses (shared) ────────────────────────────

## Detect cross-group effect flags from raw ninjas array.
## Used by calculate() path (one-pass, no pre-computed summary).
static func _detect_cross_group_flags(ninjas: Array) -> Dictionary:
	var eq_chips: int = 0
	var share_col_hand: bool = false
	var share_tail_hand: bool = false
	var dup_hand_x2: bool = false
	var tail_only_x3: bool = false

	for ninja: Dictionary in ninjas:
		var eff: Dictionary = ninja.get("effect", {})
		var ec: int = eff.get("all_non_scatter_add_chips", 0)
		if ec > eq_chips:
			eq_chips = ec
		if eff.get("share_col_hand_to_rows", false):
			share_col_hand = true
		if eff.get("share_tail_hand_to_head_mid", false):
			share_tail_hand = true
		if eff.get("duplicate_hand_x2", false):
			dup_hand_x2 = true
			if eff.get("tail_only_x3", false):
				tail_only_x3 = true

	return {
		"eq_chips": eq_chips,
		"eq_active": eq_chips > 0,
		"share_col_hand_to_rows": share_col_hand,
		"share_tail_hand_to_head_mid": share_tail_hand,
		"duplicate_hand_x2": dup_hand_x2,
		"tail_only_x3": tail_only_x3,
	}


## Apply cross-group bonuses (均衡之印/天下人/幻术大师) to per-group accumulators.
## `flags` is either a raw flags dict (from _detect_cross_group_flags) or
## a summary dict (from analyze_effects). Both contain the same keys.
##
## NOTE: 均衡之印 was previously MISSING in the calculate_with_summary path.
## This shared method fixes that bug — both paths now apply it consistently.
static func _apply_cross_group_bonuses(
	flags: Dictionary,
	head_ninja: Dictionary, mid_ninja: Dictionary, tail_ninja: Dictionary,
	head_type: int, mid_type: int, tail_type: int,
	col_evals: Array,
	star_chart_levels: Dictionary
) -> void:
	# ─── 均衡之印: 三行非散排时所有行列组 +50 筹码 ───
	var eq_chips: int = flags.get("all_non_scatter_add_chips", flags.get("eq_chips", 0))
	var eq_active: bool = eq_chips > 0 \
		and head_type > CardData.HandType3.HIGH_CARD_3 \
		and mid_type > CardData.HandType3.HIGH_CARD_3 \
		and tail_type > CardData.HandType3.HIGH_CARD_3
	if eq_active:
		head_ninja.chips += eq_chips
		mid_ninja.chips += eq_chips
		tail_ninja.chips += eq_chips

	# ─── 天下人: 非散牌列的牌型加成给三行 ───
	if flags.get("share_col_hand_to_rows", false) and col_evals.size() == 3:
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
	if flags.get("share_tail_hand_to_head_mid", false):
		var tail_hc: int = CardData.get_hand_type3_leveled_chips(tail_type, star_chart_levels)
		var tail_hm: int = CardData.get_hand_type3_leveled_mult(tail_type, star_chart_levels)
		head_ninja.chips += tail_hc
		mid_ninja.chips += tail_hc
		head_ninja.mult += tail_hm
		mid_ninja.mult += tail_hm
