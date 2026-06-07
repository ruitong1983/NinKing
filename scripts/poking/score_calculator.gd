class_name ScoreCalculator
extends RefCounted

## Calculates final score: (card_chips + hand_chips + joker_chips) × (hand_mult + joker_mult)

class ScoreResult:
	var total_score: int
	var card_chips: int
	var hand_chips: int
	var joker_chips: int
	var hand_mult: int
	var joker_mult: int
	var final_chips: int
	var final_mult: int

	func _init() -> void:
		total_score = 0
		card_chips = 0
		hand_chips = 0
		joker_chips = 0
		hand_mult = 0
		joker_mult = 0
		final_chips = 0
		final_mult = 0


static func calculate(cards: Array, jokers: Array, used_item: Dictionary = {}) -> ScoreResult:
	var eval: HandEvaluator.EvalResult = HandEvaluator.evaluate(cards)

	var result: ScoreResult = ScoreResult.new()

	# Sum card chip values
	for c: CardData.Card in cards:
		result.card_chips += c.get_chip_value()

	result.hand_chips = eval.base_chips
	result.hand_mult = eval.base_mult

	# Apply joker effects
	for joker: Dictionary in jokers:
		var effect: Dictionary = joker.get("effect", {})
		result.joker_chips += effect.get("add_chips", 0)
		result.joker_mult += effect.get("add_mult", 0)

		# Conditional joker effects
		var cond: Dictionary = effect.get("condition", {})
		if not cond.is_empty() and _meets_condition(cond, eval.hand_type, cards):
			result.joker_chips += cond.get("add_chips", 0)
			result.joker_mult += cond.get("add_mult", 0)
			if cond.get("x_mult", 1.0) != 1.0:
				result.joker_mult = int(ceil(result.joker_mult * cond["x_mult"]))

	# Apply item effect (one-time boost before scoring)
	if not used_item.is_empty():
		var ie: Dictionary = used_item.get("effect", {})
		result.joker_chips += ie.get("add_chips", 0)
		result.joker_mult += ie.get("add_mult", 0)
		if ie.get("x_mult", 1.0) != 1.0:
			result.joker_mult = int(ceil(result.joker_mult * ie["x_mult"]))

	result.final_chips = result.card_chips + result.hand_chips + result.joker_chips
	result.final_mult = max(1, result.hand_mult + result.joker_mult)
	result.total_score = result.final_chips * result.final_mult

	return result


static func _meets_condition(cond: Dictionary, hand_type: CardData.HandType, _cards: Array) -> bool:
	var required_type: int = cond.get("hand_type", -1)
	if required_type != -1 and hand_type != required_type:
		return false
	if cond.get("contains_ace", false):
		var has_ace: bool = false
		for c: CardData.Card in _cards:
			if c.rank == CardData.Rank.ACE:
				has_ace = true
				break
		if not has_ace:
			return false
	return true


static func _get_item_effect(_item: CardData.Card) -> Dictionary:
	return {}
