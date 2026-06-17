class_name ScoreXiHandler
extends RefCounted

## Xi (喜) ×mult handling and duplicate-hand ×2 (双头蛇).
## Extracted from score_calculator.gd to reduce file size.
##
## Responsibilities:
##   - _get_global_xi_x_stack: extract global xi ×mult values
##   - _apply_group_xi: apply group-level xi (三清/三顺清/顺清打头/豹子)
##   - _apply_duplicate_hand_x2: double groups where hand type appears ≥2


## Extract global xi ×mult values from xi_result triggered list.
## Global xis: 全黑(×2), 全红(×2), 全顺(×2), 全同花(×3), 四张(×5), 全三条(×4),
##             昇龍(×3), 背水(×4), 貧打(×4), 陣眼(×3), 均爵(×3), 三等(×5), 满堂(×5),
##             三合(×6), 双合(×4), 一合(×2)
## xi_bonus is added to each multiplier (e.g. 喜鹊 +1).
static func get_global_xi_x_stack(xi_result: XiDetector.XiResult, xi_bonus: int = 0, xi_override: Dictionary = {}) -> Array[int]:
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


## Apply group-level xi multipliers to the result.
static func apply_group_xi(
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


## Check if any ninja has the duplicate_hand_x2 effect.
static func has_duplicate_hand_x2(ninjas: Array) -> bool:
	for ninja: Dictionary in ninjas:
		if ninja.get("effect", {}).get("duplicate_hand_x2", false):
			return true
	return false


## Apply ×2 to groups whose hand type appears ≥2 across all 6 groups (3 rows + 3 columns).
static func apply_duplicate_hand_x2(
	result: ScoreResult,
	head_type: int, mid_type: int, tail_type: int,
	col_evals: Array,
	override_type: bool,
	col_scores: Array
) -> void:
	# Gather all 6 hand types
	var all_types: Array[int] = [head_type, mid_type, tail_type]
	var col_types_actual: Array[int] = []
	if col_evals.size() == 3:
		for i: int in range(3):
			var ct: int = CardData.HandType3.HIGH_CARD_3 if override_type else col_evals[i].hand_type
			col_types_actual.append(ct)
			all_types.append(ct)

	# Count occurrences
	var type_count: Dictionary = {}
	for ht: int in all_types:
		type_count[ht] = type_count.get(ht, 0) + 1

	# 行翻倍
	if type_count.get(head_type, 0) >= 2:
		result.head_score *= 2
	if type_count.get(mid_type, 0) >= 2:
		result.mid_score *= 2
	if type_count.get(tail_type, 0) >= 2:
		result.tail_score *= 2

	# 列翻倍
	for i: int in range(col_types_actual.size()):
		var ct: int = col_types_actual[i]
		if type_count.get(ct, 0) >= 2 and col_scores[i] > 0:
			col_scores[i] *= 2
