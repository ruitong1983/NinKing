class_name NinjaScaling
extends RefCounted

## Scaling ninja engine — processes growth effects on ninja cards.
## Extracted from NinjaData. Modifies ninja `effect` values in-place.
## Called from SealController.finalize_play() (B10).
##
## Active scaling ninjas: n_s01(修行者, 暂缓). Deleted: n_s02-n_s04.
##   天华/王座已重设计为 n_110 閃光 / n_111 流光（倍率X·列传行）。


## Process scaling ninja effects after each play.
## Modifies ninja effect values in-place.
static func process_scaling(ninjas: Array[Dictionary], trigger_type: String,
		context: Dictionary = {}) -> void:
	for ninja: Dictionary in ninjas:
		var scaling: Dictionary = ninja.get("scaling", {})
		if scaling.is_empty():
			continue
		if scaling.get("trigger", "") != trigger_type:
			continue

		var cond: Dictionary = scaling.get("condition", {})
		if not cond.is_empty():
			if not _check_scaling_cond(cond, context):
				if scaling.get("reset_on_fail", false):
					_reset_scaling(ninja, scaling)
				continue

		# Apply growth
		var add_chips: int = scaling.get("add_chips", 0)
		var add_mult: int = scaling.get("add_mult", 0)
		var cap: int = scaling.get("cap", 999999)

		if add_chips > 0:
			var current: int = ninja["effect"].get("add_chips", 0)
			ninja["effect"]["add_chips"] = min(current + add_chips, cap)
		if add_mult > 0:
			var current: int = ninja["effect"].get("add_mult", 0)
			ninja["effect"]["add_mult"] = min(current + add_mult, cap)

		var x_growth: int = scaling.get("x_mult_growth", 0)
		if x_growth > 0:
			var current_x: int = ninja["effect"].get("x_mult", 1)
			var x_cap: int = scaling.get("x_cap", 999)
			ninja["effect"]["x_mult"] = min(current_x + x_growth, x_cap)


static func _reset_scaling(ninja: Dictionary, scaling: Dictionary) -> void:
	if scaling.get("add_chips", 0) > 0:
		ninja["effect"]["add_chips"] = 0
	if scaling.get("add_mult", 0) > 0:
		ninja["effect"]["add_mult"] = 0


static func _check_scaling_cond(cond: Dictionary, context: Dictionary) -> bool:
	# Xi-based condition
	if cond.has("xi"):
		var triggered_xis: Array = context.get("triggered_xis", [])
		return triggered_xis.has(cond["xi"])

	# Group + hand type condition
	var group: String = cond.get("group", "")
	var required_type: int = cond.get("hand_type", -1)
	var at_least: int = cond.get("at_least_hand_type", -1)

	if group != "":
		var actual_type: int = context.get(group + "_type", -1)
		if required_type != -1 and actual_type != required_type:
			return false
		if at_least != -1 and actual_type < at_least:
			return false
		return true

	if required_type != -1:
		return false
	if at_least != -1:
		return false
	return true
