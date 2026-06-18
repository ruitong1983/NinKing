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
	# ── 组级基础喜 (2026-06-16) ──
	{ "name": "豹子", "x_mult": 2, "chips": 0 },
	# ── Phase E 新喜 (2026-06-16) ──
	{ "name": "昇龍", "x_mult": 3, "chips": 0 },
	{ "name": "背水", "x_mult": 4, "chips": 0 },
	{ "name": "貧打", "x_mult": 4, "chips": 0 },
	{ "name": "陣眼", "x_mult": 3, "chips": 0 },
	{ "name": "均爵", "x_mult": 3, "chips": 0 },
	{ "name": "三等", "x_mult": 5, "chips": 0 },
	# ── 2026-06-16 追加 ──
	{ "name": "满堂", "x_mult": 5, "chips": 0 },
	# ── 合系列 (行列对角匹配, 互斥) ──
	{ "name": "三合", "x_mult": 6, "chips": 0 },
	{ "name": "双合", "x_mult": 4, "chips": 0 },
	{ "name": "一合", "x_mult": 2, "chips": 0 },
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

	# 10. 豹子 — any 墩 is three-of-a-kind (组级, per-group ×2)
	if head_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3 \
			or mid_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3 \
			or tail_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3:
		result.add_xi("豹子", 2, 0)

	# ── Phase E 新喜 (2026-06-16) ──

	# 11. 昇龍 — 影<瞬<滅 牌型严格递增
	if _check_dragon_rise(head_eval, mid_eval, tail_eval):
		result.add_xi("昇龍", 3, 0)

	# 12. 背水 — 尾墩散牌 (HIGH_CARD_3)
	if _check_last_stand(tail_eval):
		result.add_xi("背水", 4, 0)

	# 13. 貧打 — 某墩精确含 2-3-5
	if _check_poor_strike(head_cards, mid_cards, tail_cards):
		result.add_xi("貧打", 4, 0)

	# 14. 陣眼 — 中心牌(9张中间)全局最小或最大(含并列)
	if _check_center_eye(all_cards, mid_cards):
		result.add_xi("陣眼", 3, 0)

	# 15. 均爵 — 每墩至少一张 J/Q/K (A不算)
	if _check_all_face(head_cards, mid_cards, tail_cards):
		result.add_xi("均爵", 3, 0)

	# 16. 三等 — 三行卡牌chip总和相等(类幻方)
	if _check_equal_chips(head_cards, mid_cards, tail_cards):
		result.add_xi("三等", 5, 0)

	# 17. 满堂 — all 3 rows + all 3 columns 均为非散牌
	if _check_full_house(head_eval, mid_eval, tail_eval, head_cards, mid_cards, tail_cards):
		result.add_xi("满堂", 5, 0)

	# ── 合系列 (互斥: 只取最高档) ──
	var diag_matches: int = _count_diag_matches(head_eval, mid_eval, tail_eval, head_cards, mid_cards, tail_cards)
	if diag_matches == 3:
		result.add_xi("三合", 6, 0)
	elif diag_matches == 2:
		result.add_xi("双合", 4, 0)
	elif diag_matches >= 1:
		result.add_xi("一合", 2, 0)

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


# ──────────── Phase E 新喜检测 (2026-06-16) ────────────

## 昇龍: 影<瞬<滅 牌型严格递增 (int 比较 HandType3 枚举值)
static func _check_dragon_rise(
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult) -> bool:
	return (int(head_eval.hand_type) < int(mid_eval.hand_type)
		and int(mid_eval.hand_type) < int(tail_eval.hand_type))


## 背水: 尾墩为散牌 (HIGH_CARD_3)
static func _check_last_stand(tail_eval: HandEvaluator3.EvalResult) -> bool:
	return tail_eval.hand_type == CardData.HandType3.HIGH_CARD_3


## 貧打: 某墩精确包含 2-3-5 (rank 值, 不计花色)
static func _check_poor_strike(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var groups: Array[Array] = [head_cards, mid_cards, tail_cards]
	for group: Array in groups:
		var ranks: Array[int] = []
		for c: CardData.PlayingCard in group:
			ranks.append(c.rank)
		ranks.sort()
		if ranks.size() == 3 \
				and ranks[0] == CardData.Rank.TWO \
				and ranks[1] == CardData.Rank.THREE \
				and ranks[2] == CardData.Rank.FIVE:
			return true
	return false


## 陣眼: 中心牌(瞬墩中间张)为全局最小或最大(含并列)
static func _check_center_eye(all_cards: Array, mid_cards: Array) -> bool:
	var center_rank: int = mid_cards[1].rank
	var min_rank: int = center_rank
	var max_rank: int = center_rank
	for c: CardData.PlayingCard in all_cards:
		if c.rank < min_rank:
			min_rank = c.rank
		if c.rank > max_rank:
			max_rank = c.rank
	return center_rank == min_rank or center_rank == max_rank


## 均爵: 每墩至少一张 J/Q/K (Aces 不算人头牌)
static func _check_all_face(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var face_ranks: Array[int] = [CardData.Rank.JACK, CardData.Rank.QUEEN, CardData.Rank.KING]
	for group: Array in [head_cards, mid_cards, tail_cards]:
		var has_face: bool = false
		for c: CardData.PlayingCard in group:
			if c.rank in face_ranks:
				has_face = true
				break
		if not has_face:
			return false
	return true


## 三等: 三行卡牌 chip 值总和相等 (类幻方/数独)
static func _check_equal_chips(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var head_sum: int = 0
	var mid_sum: int = 0
	var tail_sum: int = 0
	for c: CardData.PlayingCard in head_cards:
		head_sum += c.get_chip_value()
	for c: CardData.PlayingCard in mid_cards:
		mid_sum += c.get_chip_value()
	for c: CardData.PlayingCard in tail_cards:
		tail_sum += c.get_chip_value()
	return head_sum == mid_sum and mid_sum == tail_sum


## 满堂: 3行+3列全部非散牌 (≥ ONE_PAIR_3)
static func _check_full_house(
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult,
		head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	# Check rows
	if head_eval.hand_type == CardData.HandType3.HIGH_CARD_3 \
			or mid_eval.hand_type == CardData.HandType3.HIGH_CARD_3 \
			or tail_eval.hand_type == CardData.HandType3.HIGH_CARD_3:
		return false
	# Check columns
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
				head_cards[i] as CardData.PlayingCard,
				mid_cards[i] as CardData.PlayingCard,
				tail_cards[i] as CardData.PlayingCard]
		var col_eval = HandEvaluator3.evaluate(col_cards)
		if col_eval.hand_type == CardData.HandType3.HIGH_CARD_3:
			return false
	return true


## 合系列: 每行匹配任意列计数 (0-3)
## 每行只要其牌型出现在任一列中即计 1, 非对角匹配也算
## 散牌行不计入 (散牌配散牌不算巧妙匹配)
static func _count_diag_matches(
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult,
		head_cards: Array, mid_cards: Array, tail_cards: Array) -> int:
	var count: int = 0
	var col_evals: Array = []
	for i: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
				head_cards[i] as CardData.PlayingCard,
				mid_cards[i] as CardData.PlayingCard,
				tail_cards[i] as CardData.PlayingCard]
		col_evals.append(HandEvaluator3.evaluate(col_cards))
	var row_types: Array[int] = [int(head_eval.hand_type), int(mid_eval.hand_type), int(tail_eval.hand_type)]
	for row_type: int in row_types:
		# 散牌不计入"合"——散牌配散牌不算巧妙匹配
		if row_type == int(CardData.HandType3.HIGH_CARD_3):
			continue
		for ce in col_evals:
			if row_type == int(ce.hand_type):
				count += 1
				break
	return count


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
