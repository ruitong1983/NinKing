class_name ArrangeController
extends RefCounted

## Auto-arrangement and scoring rule collection extracted from NinKingGameState.
## All methods are static and take the game state autoload as first parameter.
## Does NOT emit signals — the caller (game_state.gd) handles that.


## Compute the best 3-group arrangement for the current hand.
## Updates gs.hand and gs.current_arrangement in-place.
static func auto_arrange(gs: Node) -> void:
	if gs.hand.size() != 9:
		return

	var rules: Dictionary = get_scoring_rules(gs)

	var ninja_chips: int = sum_ninja_effect(gs, "add_chips")
	var ninja_mult: int = sum_ninja_effect(gs, "add_mult")
	var ninja_x_stack: Array = collect_ninja_effect(gs, "x_mult", 1)

	gs.current_arrangement = AutoArranger.find_best(
		gs.hand,
		ninja_chips, ninja_mult, ninja_x_stack,
		gs.star_chart_levels,
		rules
	)

	if gs.current_arrangement:
		gs.hand.clear()
		gs.hand.append_array(gs.current_arrangement.head)
		gs.hand.append_array(gs.current_arrangement.mid)
		gs.hand.append_array(gs.current_arrangement.tail)


## Collect scoring rules from Seal Lord effects and ninja rule cards.
static func get_scoring_rules(gs: Node) -> Dictionary:
	var rules: Dictionary = {}

	if gs.current_seal_lord_effects.has("constraint"):
		rules["constraint"] = gs.current_seal_lord_effects["constraint"]

	if gs.current_seal_lord_effects.get("skip_head", false) and gs.current_seal_lord_effects.get("skip_mid", false):
		rules["scoring"] = "tail_only"
	elif gs.current_seal_lord_effects.get("skip_head", false):
		rules["deprioritize_head"] = true
	elif gs.current_seal_lord_effects.get("skip_tail", false):
		rules["deprioritize_tail"] = true

	if gs.current_seal_lord_effects.get("lowest_group_zero", false):
		rules["balance_groups"] = true
	if gs.current_seal_lord_effects.get("scatter_king", false):
		rules["scatter_king"] = true
	if gs.current_seal_lord_effects.get("hungry_ghost", false):
		rules["hungry_ghost"] = true

	for ninja: Dictionary in gs.owned_ninjas:
		var effect: Dictionary = ninja.get("effect", {})
		if effect.get("constraint_override", "") != "":
			rules["constraint"] = effect["constraint_override"]
		if effect.get("scoring_override", "") != "":
			rules["scoring"] = effect["scoring_override"]

	return rules


## Sum a numeric ninja effect across all owned ninjas.
static func sum_ninja_effect(gs: Node, key: String, default: int = 0) -> int:
	var total: int = 0
	for ninja: Dictionary in gs.owned_ninjas:
		var effect: Dictionary = ninja.get("effect", {})
		total += int(effect.get(key, default))
	return total


## Collect ninja effects that exceed a threshold (for ×mult stacks).
static func collect_ninja_effect(gs: Node, key: String, threshold: int = 0) -> Array:
	var stack: Array = []
	for ninja: Dictionary in gs.owned_ninjas:
		var effect: Dictionary = ninja.get("effect", {})
		var val: int = int(effect.get(key, 1))
		if val > threshold:
			stack.append(val)
	return stack
