class_name XiDetector
extends RefCounted

## Detects 喜 (xi) patterns across all 9 cards in the 3-group arrangement.
## Each xi is independently detected. Multiple xi can trigger simultaneously.
## v3.2 — all ×mult and chips values integer.

const XI_DEFINITIONS: Array[Dictionary] = [
	{ "name": "全黑", "x_mult": 2, "chips": 0 },
	{ "name": "全红", "x_mult": 2, "chips": 0 },
	{ "name": "全顺", "x_mult": 2, "chips": 0 },
	{ "name": "全同花", "x_mult": 3, "chips": 0 },
	{ "name": "四张", "x_mult": 5, "chips": 0 },
	{ "name": "三清", "x_mult": 2, "chips": 0 },
	{ "name": "三顺清", "x_mult": 3, "chips": 0 },
	{ "name": "顺清打头", "x_mult": 2, "chips": 0 },
	{ "name": "全三条", "x_mult": 4, "chips": 0 },
]


class XiResult:
	var triggered: Array[String] = []   # names of triggered xi
	var chips_add: int = 0              # total chips added by xi
	var mult_x_stack: Array[int] = []   # ×mult stack from xi (for flat formula)

	func _init() -> void:
		pass

	func add_xi(name: String, x_mult: int, chips: int) -> void:
		triggered.append(name)
		if chips > 0:
			chips_add += chips
		if x_mult > 1:
			mult_x_stack.append(x_mult)

	func has_any() -> bool:
		return not triggered.is_empty()


## Detect all xi for the given 9 cards arranged in 3 groups.
static func detect(head_cards: Array, mid_cards: Array, tail_cards: Array,
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult) -> XiResult:

	var all_cards: Array = head_cards + mid_cards + tail_cards
	assert(all_cards.size() == 9, "XiDetector requires exactly 9 cards total")

	var result: XiResult = XiResult.new()

	# 1. 全黑 — all ♠/♣
	if _check_all_black(all_cards):
		result.add_xi("全黑", 2, 0)

	# 2. 全红 — all ♥/♦
	if _check_all_red(all_cards):
		result.add_xi("全红", 2, 0)

	# 3. 全顺 — 9 cards form a continuous sequence
	if _check_dragon(all_cards):
		result.add_xi("全顺", 2, 0)

	# 4. 全同花 — all 9 same suit (covers 全黑/全红 when higher)
	if _check_all_same_suit(all_cards):
		result.add_xi("全同花", 3, 0)

	# 5. 四张 — 4+ cards of same rank
	if _check_four_of_kind(all_cards):
		result.add_xi("四张", 1, 50)

	# 6. 三清 — all 3 groups are flush
	if _check_three_flush(head_eval, mid_eval, tail_eval):
		result.add_xi("三清", 2, 0)

	# 7. 三顺清 — all 3 groups are straight flush
	if _check_three_straight_flush(head_eval, mid_eval, tail_eval):
		result.add_xi("三顺清", 3, 0)

	# 8. 顺清打头 — head group is straight flush
	if head_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3:
		result.add_xi("顺清打头", 2, 0)

	# 9. 全三条 — 9 cards form 3 three-of-a-kinds
	if _check_all_triples(all_cards):
		result.add_xi("全三条", 4, 0)

	return result


# ──────────────────────────── Detectors ────────────────────────────

static func _check_all_black(cards: Array) -> bool:
	for c: CardData.PlayingCard in cards:
		if c.suit != CardData.Suit.SPADES and c.suit != CardData.Suit.CLUBS:
			return false
	return true


static func _check_all_red(cards: Array) -> bool:
	for c: CardData.PlayingCard in cards:
		if c.suit != CardData.Suit.HEARTS and c.suit != CardData.Suit.DIAMONDS:
			return false
	return true


static func _check_dragon(cards: Array) -> bool:
	# 9-card consecutive sequence (like 2-3-4-5-6-7-8-9-10 or A-2-3...8-9)
	var ranks: Array[int] = []
	for c: CardData.PlayingCard in cards:
		ranks.append(c.rank)
	ranks.sort()

	# Check normal dragon: each rank = previous + 1
	var is_dragon: bool = true
	for i: int in range(1, ranks.size()):
		if ranks[i] != ranks[i - 1] + 1:
			is_dragon = false
			break
	if is_dragon:
		return true

	# Ace-low dragon: A-2-3-4-5-6-7-8-9
	# Sorted: [2,3,4,5,6,7,8,9,14]
	var ace_low: bool = true
	var expected: int = CardData.Rank.TWO
	for i: int in range(0, ranks.size() - 1):
		if ranks[i] != expected:
			ace_low = false
			break
		expected += 1
	if ace_low and ranks[8] == CardData.Rank.ACE:
		return true

	return false


static func _check_all_same_suit(cards: Array) -> bool:
	# Wild cards match anything
	var base_suit: int = -1
	for c: CardData.PlayingCard in cards:
		if c.enhancement == CardData.Enhancement.WILD:
			continue
		if base_suit == -1:
			base_suit = c.suit
		elif c.suit != base_suit:
			return false
	return true


static func _check_four_of_kind(cards: Array) -> bool:
	var rank_counts: Dictionary = {}
	for c: CardData.PlayingCard in cards:
		rank_counts[c.rank] = rank_counts.get(c.rank, 0) + 1
	for count: int in rank_counts.values():
		if count >= 4:
			return true
	return false


static func _check_three_flush(head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult) -> bool:

	return (head_eval.hand_type == CardData.HandType3.FLUSH_3
		or head_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3) \
		and (mid_eval.hand_type == CardData.HandType3.FLUSH_3
		or mid_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3) \
		and (tail_eval.hand_type == CardData.HandType3.FLUSH_3
		or tail_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3)


static func _check_three_straight_flush(head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult) -> bool:

	return head_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3 \
		and mid_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3 \
		and tail_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3


static func _check_all_triples(cards: Array) -> bool:
	# 9 cards form exactly 3 three-of-a-kind groups
	# Requires 3 distinct ranks, each appearing exactly 3 times
	var rank_counts: Dictionary = {}
	for c: CardData.PlayingCard in cards:
		rank_counts[c.rank] = rank_counts.get(c.rank, 0) + 1

	if rank_counts.size() != 3:
		return false

	for count: int in rank_counts.values():
		if count != 3:
			return false

	return true
