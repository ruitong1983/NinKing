class_name HandEvaluator3
extends RefCounted

## Evaluates exactly 3 cards and returns the best 3-card poker hand.
## Supports Wild enhancement (counts as all suits for flush detection).
## Priority: 豹子 > 同花顺 > 同花 > 顺子 > 对子 > 散牌

class EvalResult:
	var hand_type: CardData.HandType3
	var base_chips: int
	var base_mult: int
	var strength: int                  # for constraint ordering (头 ≤ 中 ≤ 尾)

	func _init(ht: CardData.HandType3, chips: int, mult: int, str_val: int) -> void:
		hand_type = ht
		base_chips = chips
		base_mult = mult
		strength = str_val


static func evaluate(cards: Array[CardData.PlayingCard]) -> EvalResult:
	assert(cards.size() == 3, "HandEvaluator3 requires exactly 3 cards, got %d" % cards.size())

	var hand_type: CardData.HandType3 = _determine_type(cards)
	var base: Dictionary = CardData.get_hand_type3_base(hand_type)
	var strength: int = CardData.calc_hand_strength(hand_type, cards)

	return EvalResult.new(hand_type, base["chips"], base["mult"], strength)


## Fast path: return only strength value. Used by AutoArranger brute-force.
static func evaluate_strength(cards: Array[CardData.PlayingCard]) -> int:
	var hand_type: CardData.HandType3 = _determine_type(cards)
	return CardData.calc_hand_strength(hand_type, cards)


static func _determine_type(cards: Array[CardData.PlayingCard]) -> CardData.HandType3:
	var ranks: Array[int] = []
	for c: CardData.PlayingCard in cards:
		ranks.append(c.rank)
	ranks.sort()

	var is_flush: bool = _check_flush(cards)
	var is_straight: bool = _check_straight_3(ranks)
	var rank_counts: Dictionary = _count_ranks(ranks)

	# Priority order (highest → lowest)
	if _has_count(rank_counts, 3):
		return CardData.HandType3.THREE_OF_KIND_3
	if is_flush and is_straight:
		return CardData.HandType3.STRAIGHT_FLUSH_3
	if is_flush:
		return CardData.HandType3.FLUSH_3
	if is_straight:
		return CardData.HandType3.STRAIGHT_3
	if _has_count(rank_counts, 2):
		return CardData.HandType3.ONE_PAIR_3
	return CardData.HandType3.HIGH_CARD_3


# ──────────────────────────── Internal ────────────────────────────

static func _check_flush(cards: Array[CardData.PlayingCard]) -> bool:
	var base_suit: int = -1
	for c: CardData.PlayingCard in cards:
		if c.enhancement == CardData.Enhancement.WILD:
			continue
		if base_suit == -1:
			base_suit = c.suit
		elif c.suit != base_suit:
			return false
	return true


static func _check_straight_3(sorted_ranks: Array[int]) -> bool:
	# Normal straight: each rank = prev + 1
	if sorted_ranks[1] == sorted_ranks[0] + 1 and sorted_ranks[2] == sorted_ranks[1] + 1:
		return true
	# Ace-low: A-2-3 → sorted ranks [2, 3, 14]
	if sorted_ranks[0] == CardData.Rank.TWO and sorted_ranks[1] == CardData.Rank.THREE and sorted_ranks[2] == CardData.Rank.ACE:
		return true
	return false


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
