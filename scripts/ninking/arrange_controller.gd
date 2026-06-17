class_name ArrangeController
extends RefCounted

## Auto-arrangement and scoring rule collection extracted from NinKingGameState.
## All methods are static and take the game state autoload as first parameter.
## Does NOT emit signals — the caller (game_state.gd) handles that.
## v4.0 — per-group ninja effects.


## Compute the best 3-group arrangement for the current hand.
## Updates gs.hand and gs.current_arrangement in-place.
static func auto_arrange(gs: Node) -> void:
	if gs.hand.size() != 9:
		return

	var rules: Dictionary = get_scoring_rules(gs)

	# Pre-compute per-group ninja effects
	var per_group: Dictionary = _compute_per_group_ninja_effects(gs)

	gs.current_arrangement = AutoArranger.find_best(
		gs.hand,
		per_group.head_ninja, per_group.mid_ninja, per_group.tail_ninja,
		gs.star_chart_levels,
		rules
	)

	if gs.current_arrangement:
		gs.hand.clear()
		gs.hand.append_array(gs.current_arrangement.head)
		gs.hand.append_array(gs.current_arrangement.mid)
		gs.hand.append_array(gs.current_arrangement.tail)


## Pre-compute per-group ninja effects for AI arrangement ranking.
## Returns { head_ninja: {}, mid_ninja: {}, tail_ninja: {} }
## Head group state is not needed here — conditions checked via hand type only.
static func _compute_per_group_ninja_effects(gs: Node) -> Dictionary:
	var head_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
	var mid_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }
	var tail_ninja: Dictionary = { "chips": 0, "mult": 0, "x_stack": [] }

	if gs.owned_ninjas.is_empty():
		return { "head_ninja": head_ninja, "mid_ninja": mid_ninja, "tail_ninja": tail_ninja }

	# Use current arrangement's hand types for condition checking
	var head_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3
	var mid_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3
	var tail_type: CardData.HandType3 = CardData.HandType3.HIGH_CARD_3
	if gs.current_arrangement:
		head_type = gs.current_arrangement.head_eval.hand_type
		mid_type = gs.current_arrangement.mid_eval.hand_type
		tail_type = gs.current_arrangement.tail_eval.hand_type

	var head_cards: Array = []
	var mid_cards: Array = []
	var tail_cards: Array = []
	if gs.current_arrangement:
		head_cards = gs.current_arrangement.head
		mid_cards = gs.current_arrangement.mid
		tail_cards = gs.current_arrangement.tail
	else:
		head_cards = gs.hand.slice(0, 3)
		mid_cards = gs.hand.slice(3, 6)
		tail_cards = gs.hand.slice(6, 9)

	# Re-evaluate for condition checking
	var head_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(head_cards)
	var mid_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(mid_cards)
	var tail_eval: HandEvaluator3.EvalResult = HandEvaluator3.evaluate(tail_cards)

	# Dummy result structs — ScoreCalculator.ninja_affected_groups only needs hand types
	for ninja: Dictionary in gs.owned_ninjas:
		var effect: Dictionary = ninja.get("effect", {})
		ScoreEffectCollector.collect_ninja_per_group(
			effect,
			head_type, mid_type, tail_type,
			head_cards, mid_cards, tail_cards,
			head_eval, mid_eval, tail_eval,
			head_ninja, mid_ninja, tail_ninja,
			gs.gold
		)

	return {
		"head_ninja": head_ninja,
		"mid_ninja": mid_ninja,
		"tail_ninja": tail_ninja,
	}


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
