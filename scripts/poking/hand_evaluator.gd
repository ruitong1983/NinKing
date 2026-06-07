class_name HandEvaluator
extends RefCounted

## Evaluates 5 cards and returns the best poker hand.

class EvalResult:
	var hand_type: CardData.HandType
	var base_chips: int
	var base_mult: int

	func _init(ht: CardData.HandType, chips: int, mult: int) -> void:
		hand_type = ht
		base_chips = chips
		base_mult = mult


static func evaluate(cards: Array) -> EvalResult:
	assert(cards.size() == 5, "HandEvaluator requires exactly 5 cards")

	var ranks: Array[int] = []
	var suits: Array[int] = []
	for c: CardData.Card in cards:
		ranks.append(c.rank)
		suits.append(c.suit)

	ranks.sort()
	var is_flush: bool = _check_flush(suits)
	var is_straight: bool = _check_straight(ranks)
	var rank_counts: Dictionary = _count_ranks(ranks)

	# Royal Flush
	if is_flush and is_straight and ranks[0] == CardData.Rank.TEN and ranks[4] == CardData.Rank.ACE:
		return _make_result(CardData.HandType.ROYAL_FLUSH)

	# Straight Flush
	if is_flush and is_straight:
		return _make_result(CardData.HandType.STRAIGHT_FLUSH)

	# Four of a Kind
	if _has_count(rank_counts, 4):
		return _make_result(CardData.HandType.FOUR_OF_A_KIND)

	# Full House
	if _has_count(rank_counts, 3) and _has_count(rank_counts, 2):
		return _make_result(CardData.HandType.FULL_HOUSE)

	# Flush
	if is_flush:
		return _make_result(CardData.HandType.FLUSH)

	# Straight
	if is_straight:
		return _make_result(CardData.HandType.STRAIGHT)

	# Three of a Kind
	if _has_count(rank_counts, 3):
		return _make_result(CardData.HandType.THREE_OF_A_KIND)

	# Two Pair
	if _count_pairs(rank_counts) == 2:
		return _make_result(CardData.HandType.TWO_PAIR)

	# One Pair
	if _has_count(rank_counts, 2):
		return _make_result(CardData.HandType.ONE_PAIR)

	# High Card
	return _make_result(CardData.HandType.HIGH_CARD)


static func _make_result(ht: CardData.HandType) -> EvalResult:
	var base: Dictionary = CardData.get_hand_base(ht)
	return EvalResult.new(ht, base["chips"], base["mult"])


static func _check_flush(suits: Array[int]) -> bool:
	for i: int in range(1, suits.size()):
		if suits[i] != suits[0]:
			return false
	return true


static func _check_straight(sorted_ranks: Array[int]) -> bool:
	for i: int in range(1, sorted_ranks.size()):
		if sorted_ranks[i] != sorted_ranks[i - 1] + 1:
			return false
	return true


static func _count_ranks(ranks: Array[int]) -> Dictionary:
	var counts: Dictionary = {}
	for r: int in ranks:
		counts[r] = counts.get(r, 0) + 1
	return counts


static func _has_count(counts: Dictionary, target: int) -> bool:
	for v: int in counts.values():
		if v == target:
			return true
	return false


static func _count_pairs(counts: Dictionary) -> int:
	var pairs: int = 0
	for v: int in counts.values():
		if v == 2:
			pairs += 1
	return pairs
