class_name XiDetector
extends RefCounted

## Detects 喜 (xi) patterns across all 9 cards in the 3-group arrangement.
## Each xi is independently detected. Multiple xi can trigger simultaneously.
## v3.2 — all ×mult values integer.

const XI_DEFINITIONS: Array[Dictionary] = [
	{ "name": "全黑", "x_mult": 2 },
	{ "name": "全红", "x_mult": 2 },
	{ "name": "全顺", "x_mult": 2 },
	{ "name": "全同花", "x_mult": 3 },
	{ "name": "四张", "x_mult": 5 },
	{ "name": "三清", "x_mult": 2 },
	{ "name": "三顺清", "x_mult": 3 },
	{ "name": "顺清打头", "x_mult": 2 },
	{ "name": "全三条", "x_mult": 4 },
	# ── 组级基础喜 (2026-06-16) ──
	{ "name": "豹子", "x_mult": 2 },
	# ── Phase E 新喜 (2026-06-16) ──
	{ "name": "昇龍", "x_mult": 3 },
	{ "name": "背水", "x_mult": 4 },
	{ "name": "貧打", "x_mult": 4 },
	{ "name": "陣眼", "x_mult": 3 },
	{ "name": "均爵", "x_mult": 3 },
	{ "name": "三等", "x_mult": 5 },
	# ── 2026-06-16 追加 ──
	{ "name": "满堂", "x_mult": 5 },
	# ── 合系列 (行列对角匹配, 互斥) ──
	{ "name": "三合", "x_mult": 6 },
	{ "name": "双合", "x_mult": 4 },
	{ "name": "一合", "x_mult": 2 },
	# ── 布局喜 (2026-06-19) ──
	{ "name": "四角", "x_mult": 3 },
	{ "name": "中十字", "x_mult": 4 },
	{ "name": "倒影", "x_mult": 3 },
	{ "name": "双壁", "x_mult": 3 },
	{ "name": "对影", "x_mult": 2 },
	{ "name": "连环", "x_mult": 6 },
	{ "name": "天九", "x_mult": 5 },
	{ "name": "压牌", "x_mult": 4 },
	{ "name": "至尊", "x_mult": 4 },
	{ "name": "独尊", "x_mult": 6 },
	{ "name": "廿一点", "x_mult": 4 },
	{ "name": "文武", "x_mult": 4 },
	{ "name": "一气", "x_mult": 3 },
	{ "name": "无将", "x_mult": 4 },
	{ "name": "长套", "x_mult": 5 },
	{ "name": "无忧角", "x_mult": 4 },
	{ "name": "慢打", "x_mult": 5 },
	{ "name": "四对半", "x_mult": 4 },
]


class XiResult:
	var triggered: Array[String] = []   # names of triggered xi
	var mult_x_stack: Array[int] = []   # ×mult stack from xi (for flat formula)

	func _init() -> void:
		pass

	func add_xi(name: String, x_mult: int) -> void:
		triggered.append(name)
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
		result.add_xi("全黑", 2)

	# 2. 全红 — all ♥/♦
	if _check_all_red(all_cards):
		result.add_xi("全红", 2)

	# 3. 全顺 — 9 cards form a continuous sequence
	if _check_dragon(all_cards):
		result.add_xi("全顺", 2)

	# 4. 全同花 — all 9 same suit (covers 全黑/全红 when higher)
	if _check_all_same_suit(all_cards):
		result.add_xi("全同花", 3)

	# 5. 四张 — 4+ cards of same rank
	if _check_four_of_kind(all_cards):
		result.add_xi("四张", 5)

	# 6. 三清 — all 3 groups are flush
	if _check_three_flush(head_eval, mid_eval, tail_eval):
		result.add_xi("三清", 2)

	# 7. 三顺清 — all 3 groups are straight flush
	if _check_three_straight_flush(head_eval, mid_eval, tail_eval):
		result.add_xi("三顺清", 3)

	# 8. 顺清打头 — head group is straight flush
	if head_eval.hand_type == CardData.HandType3.STRAIGHT_FLUSH_3:
		result.add_xi("顺清打头", 2)

	# 9. 全三条 — 9 cards form 3 three-of-a-kinds
	if _check_all_triples(all_cards):
		result.add_xi("全三条", 4)

	# 10. 豹子 — any 墩 is three-of-a-kind (组级, per-group ×2)
	if head_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3 \
			or mid_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3 \
			or tail_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3:
		result.add_xi("豹子", 2)

	# ── Phase E 新喜 (2026-06-16) ──

	# 11. 昇龍 — 影<瞬<滅 牌型严格递增
	if _check_dragon_rise(head_eval, mid_eval, tail_eval):
		result.add_xi("昇龍", 3)

	# 12. 背水 — 尾墩散牌 (HIGH_CARD_3)
	if _check_last_stand(tail_eval):
		result.add_xi("背水", 4)

	# 13. 貧打 — 某墩精确含 2-3-5
	if _check_poor_strike(head_cards, mid_cards, tail_cards):
		result.add_xi("貧打", 4)

	# 14. 陣眼 — 中心牌(9张中间)全局最小或最大(含并列)
	if _check_center_eye(all_cards, mid_cards):
		result.add_xi("陣眼", 3)

	# 15. 均爵 — 每墩至少一张 J/Q/K (A不算)
	if _check_all_face(head_cards, mid_cards, tail_cards):
		result.add_xi("均爵", 3)

	# 16. 三等 — 三行卡牌chip总和相等(类幻方)
	if _check_equal_chips(head_cards, mid_cards, tail_cards):
		result.add_xi("三等", 5)

	# ── 预计算列牌型 (供 _check_full_house / _count_diag_matches / _check_double_wall 共享) ──
	var col_evals: Array[HandEvaluator3.EvalResult] = []
	for ci: int in range(3):
		var col_cards: Array[CardData.PlayingCard] = [
			head_cards[ci] as CardData.PlayingCard,
			mid_cards[ci] as CardData.PlayingCard,
			tail_cards[ci] as CardData.PlayingCard]
		col_evals.append(HandEvaluator3.evaluate(col_cards))

	# 17. 满堂 — all 3 rows + all 3 columns 均为非散牌
	if _check_full_house(head_eval, mid_eval, tail_eval, col_evals):
		result.add_xi("满堂", 5)

	# 18. 四角 — 4 角 (head[0],head[2],tail[0],tail[2]) 同色 (全红或全黑)
	if _check_four_corners(head_cards, tail_cards):
		result.add_xi("四角", 3)

	# 19. 中十字 — 十字区 5 张 (mid行 + 中列) 同色
	if _check_center_cross(head_cards, mid_cards, tail_cards):
		result.add_xi("中十字", 4)

	# 20. 倒影 — 上行与下行对应位置同色 (head[i] 与 tail[i] 同色系)
	if _check_reflection(head_cards, tail_cards):
		result.add_xi("倒影", 3)

	# 21. 双壁 — 左列与右列牌型相同且非散牌
	if _check_double_wall(col_evals):
		result.add_xi("双壁", 3)

	# 22. 对影 — 左列与右列对应位置同色 (col[0][i] 与 col[2][i] 同色系)
	if _check_side_mirror(head_cards, mid_cards, tail_cards):
		result.add_xi("对影", 2)

	# 23. 连环 — 3×3 棋盘交错色 (正交相邻全异色)
	if _check_chain(head_cards, mid_cards, tail_cards):
		result.add_xi("连环", 6)

	# ── 合系列 (互斥: 只取最高档) ──

	# 24. 廿一点 — 任意一行 chips 总和恰好 21 (A=11)
	if _check_blackjack(head_cards, mid_cards, tail_cards):
		result.add_xi("廿一点", 4)

	# 25. 天九 — 影+滅=瞬 chip 和 (天地人三才, 牌九至尊)
	if _check_tian_jiu(head_cards, mid_cards, tail_cards):
		result.add_xi("天九", 5)

	# 26. 压牌 — rank 区间严格分层 (影max < 瞬min 且 瞬max < 滅min)
	if _check_pressure(head_cards, mid_cards, tail_cards):
		result.add_xi("压牌", 4)

	# 27. 至尊 — 某行同时含 2 和 A (牌九至尊宝: 最小最大同炉)
	if _check_zhi_zun(head_cards, mid_cards, tail_cards):
		result.add_xi("至尊", 4)

	# 28. 独尊 — 影行 chip 和 > 瞬行 + 滅行 chip 和 (逆约束独行)
	if _check_du_zun(head_cards, mid_cards, tail_cards):
		result.add_xi("独尊", 6)

	# 29. 文武 — 三行中同时存在豹子(文)和散牌(武) (牌九文武精神)
	if _check_wen_wu(head_eval, mid_eval, tail_eval):
		result.add_xi("文武", 4)

	# 30. 一气 — 任意一行 chip 总和为 10 的倍数 (10/20/30, 牛牛"有牛")
	if _check_yi_qi(head_cards, mid_cards, tail_cards):
		result.add_xi("一气", 3)

	# 31. 无将 — 四色均衡, 每门≥2张 (唯一分布 3-2-2-2, 桥牌最高叫品)
	if _check_no_trump(all_cards):
		result.add_xi("无将", 4)

	# 32. 长套 — 某花色≥6张, 其余三门各1张 (唯一分布 6-1-1-1, 桥牌长套)
	if _check_long_suit(all_cards):
		result.add_xi("长套", 5)

	# 33. 无忧角 — 任一 2×2 子方格内 4 张全同色 (围棋守角定式)
	if _check_safe_corner(head_cards, mid_cards, tail_cards):
		result.add_xi("无忧角", 4)

	# 34. 慢打 — 影=散牌(示弱) + 滅=豹子(收网) (德扑慢打战术)
	if _check_slow_play(head_eval, tail_eval):
		result.add_xi("慢打", 5)

	# 35. 四对半 — 4×2+1×1 rank distribution (十三张报到压缩版, 2-2-2-2-1)
	if _check_four_pairs_half(all_cards):
		result.add_xi("四对半", 4)

	# ── 合系列 (互斥: 只取最高档) ──
	var diag_matches: int = _count_diag_matches(head_eval, mid_eval, tail_eval, col_evals)
	if diag_matches == 3:
		result.add_xi("三合", 6)
	elif diag_matches == 2:
		result.add_xi("双合", 4)
	elif diag_matches >= 1:
		result.add_xi("一合", 2)

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


static func _card_is_red(c: CardData.PlayingCard) -> bool:
	return c.suit == CardData.Suit.HEARTS or c.suit == CardData.Suit.DIAMONDS


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


static func _group_chip_sum(group: Array) -> int:
	var s: int = 0
	for c: CardData.PlayingCard in group:
		s += c.get_chip_value()
	return s


## 三等: 三行卡牌 chip 值总和相等 (类幻方/数独)
static func _check_equal_chips(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	return _group_chip_sum(head_cards) == _group_chip_sum(mid_cards) \
		and _group_chip_sum(mid_cards) == _group_chip_sum(tail_cards)


## 满堂: 3行+3列全部非散牌 (≥ ONE_PAIR_3)
static func _check_full_house(
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult,
		col_evals: Array) -> bool:
	# Check rows
	if head_eval.hand_type == CardData.HandType3.HIGH_CARD_3 \
			or mid_eval.hand_type == CardData.HandType3.HIGH_CARD_3 \
			or tail_eval.hand_type == CardData.HandType3.HIGH_CARD_3:
		return false
	# Check columns (pre-computed)
	for ce in col_evals:
		if ce.hand_type == CardData.HandType3.HIGH_CARD_3:
			return false
	return true


## 合系列: 每行匹配任意列计数 (0-3)
## 每行只要其牌型出现在任一列中即计 1, 非对角匹配也算
## 散牌行不计入 (散牌配散牌不算巧妙匹配)
static func _count_diag_matches(
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult,
		col_evals: Array) -> int:
	var count: int = 0
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


# ──────────── 布局喜 (2026-06-19) ────────────

## 四角: 4 角 (head[0],head[2],tail[0],tail[2]) 同色 — 全红或全黑
static func _check_four_corners(head_cards: Array, tail_cards: Array) -> bool:
	var corners: Array[CardData.PlayingCard] = [
		head_cards[0] as CardData.PlayingCard,
		head_cards[2] as CardData.PlayingCard,
		tail_cards[0] as CardData.PlayingCard,
		tail_cards[2] as CardData.PlayingCard,
	]
	return _check_all_red(corners) or _check_all_black(corners)


## 中十字: 十字区 5 张 (mid行 + 中列, 中心点共用) 同色
static func _check_center_cross(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var cross: Array[CardData.PlayingCard] = [
		head_cards[1] as CardData.PlayingCard,
		mid_cards[0] as CardData.PlayingCard,
		mid_cards[1] as CardData.PlayingCard,
		mid_cards[2] as CardData.PlayingCard,
		tail_cards[1] as CardData.PlayingCard,
	]
	return _check_all_red(cross) or _check_all_black(cross)


## 倒影: 上行与下行对应位置同色 (head[i] 与 tail[i] 同色系)
static func _check_reflection(head_cards: Array, tail_cards: Array) -> bool:
	for i: int in range(3):
		var h_is_red: bool = _card_is_red(head_cards[i] as CardData.PlayingCard)
		var t_is_red: bool = _card_is_red(tail_cards[i] as CardData.PlayingCard)
		if h_is_red != t_is_red:
			return false
	return true


## 双壁: 左列与右列牌型相同且非散牌 (HIGH_CARD_3)
static func _check_double_wall(col_evals: Array) -> bool:
	var left_eval: HandEvaluator3.EvalResult = col_evals[0] as HandEvaluator3.EvalResult
	var right_eval: HandEvaluator3.EvalResult = col_evals[2] as HandEvaluator3.EvalResult
	if left_eval.hand_type == CardData.HandType3.HIGH_CARD_3:
		return false
	return left_eval.hand_type == right_eval.hand_type


## 对影: 左列与右列对应位置同色 (col[0][i] 与 col[2][i] 同色系)
static func _check_side_mirror(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var rows: Array[Array] = [head_cards, mid_cards, tail_cards]
	for row: Array in rows:
		var l_is_red: bool = _card_is_red(row[0] as CardData.PlayingCard)
		var r_is_red: bool = _card_is_red(row[2] as CardData.PlayingCard)
		if l_is_red != r_is_red:
			return false
	return true


## 连环: 3×3 正交相邻全异色 (棋盘交错, 12条邻边全异色)
static func _check_chain(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var rows: Array = [head_cards, mid_cards, tail_cards]
	# horizontal adjacencies: 3 rows × 2 edges = 6
	for r: int in range(3):
		var row: Array = rows[r]
		var r0 := row[0] as CardData.PlayingCard
		var r1 := row[1] as CardData.PlayingCard
		var r2 := row[2] as CardData.PlayingCard
		if _card_is_red(r0) == _card_is_red(r1) or _card_is_red(r1) == _card_is_red(r2):
			return false
	# vertical adjacencies: 3 cols × 2 edges = 6
	for c: int in range(3):
		var c0 := head_cards[c] as CardData.PlayingCard
		var c1 := mid_cards[c] as CardData.PlayingCard
		var c2 := tail_cards[c] as CardData.PlayingCard
		if _card_is_red(c0) == _card_is_red(c1) or _card_is_red(c1) == _card_is_red(c2):
			return false
	return true


## 廿一点: 任意一行 chip 总和恰好 21 (A=11, J/Q/K=10)
static func _check_blackjack(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	for group: Array in [head_cards, mid_cards, tail_cards]:
		if _group_chip_sum(group) == 21:
			return true
	return false


## 天九: 影+滅=瞬 chip 总和 (天地人三才, Σ影+Σ滅=Σ瞬)
static func _check_tian_jiu(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	return _group_chip_sum(head_cards) + _group_chip_sum(tail_cards) == _group_chip_sum(mid_cards)


## 压牌: rank 区间严格分层 (影max < 瞬min 且 瞬max < 滅min)
static func _check_pressure(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var h_max: int = 0
	var m_min: int = 99
	var m_max: int = 0
	var t_min: int = 99
	for c: CardData.PlayingCard in head_cards:
		if c.rank > h_max: h_max = c.rank
	for c: CardData.PlayingCard in mid_cards:
		if c.rank < m_min: m_min = c.rank
		if c.rank > m_max: m_max = c.rank
	for c: CardData.PlayingCard in tail_cards:
		if c.rank < t_min: t_min = c.rank
	return h_max < m_min and m_max < t_min


## 至尊: 某行同时含 rank 2 和 rank A (牌九至尊宝: 最小最大同炉)
static func _check_zhi_zun(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	for group: Array in [head_cards, mid_cards, tail_cards]:
		var has_two: bool = false
		var has_ace: bool = false
		for c: CardData.PlayingCard in group:
			if c.rank == CardData.Rank.TWO: has_two = true
			if c.rank == CardData.Rank.ACE: has_ace = true
		if has_two and has_ace:
			return true
	return false

## 独尊: 影行 chip 和 > 瞬行 + 滅行 chip 和 (逆约束: 最弱者独撑)
static func _check_du_zun(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	return _group_chip_sum(head_cards) > _group_chip_sum(mid_cards) + _group_chip_sum(tail_cards)

## 一气: 任意一行 chip 总和为 10 的倍数 (10/20/30, 牛牛"有牛")
static func _check_yi_qi(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	for group: Array in [head_cards, mid_cards, tail_cards]:
		if _group_chip_sum(group) % 10 == 0:
			return true
	return false

## 无将: 四种花色各≥2张, 牌力均衡 (桥牌最高叫品 No Trump)
static func _check_no_trump(cards: Array) -> bool:
	var suit_counts: Dictionary = {}
	for c: CardData.PlayingCard in cards:
		suit_counts[c.suit] = suit_counts.get(c.suit, 0) + 1
	if suit_counts.size() < 4:
		return false
	for count: int in suit_counts.values():
		if count < 2:
			return false
	return true

## 长套: 某花色≥6张, 其余三门各1张 (唯一分布 6-1-1-1, 桥牌长套)
static func _check_long_suit(cards: Array) -> bool:
	var suit_counts: Dictionary = {}
	for c: CardData.PlayingCard in cards:
		suit_counts[c.suit] = suit_counts.get(c.suit, 0) + 1
	if suit_counts.size() != 4:
		return false
	var has_six: bool = false
	var has_one: int = 0
	for count: int in suit_counts.values():
		if count >= 6:
			has_six = true
		elif count == 1:
			has_one += 1
	return has_six and has_one == 3

## 无忧角: 任一 2×2 子方格内 4 张全同色 (围棋守角定式)
static func _check_safe_corner(head_cards: Array, mid_cards: Array, tail_cards: Array) -> bool:
	var subgrids: Array[Array] = [
		[head_cards[0], head_cards[1], mid_cards[0], mid_cards[1]],
		[head_cards[1], head_cards[2], mid_cards[1], mid_cards[2]],
		[mid_cards[0], mid_cards[1], tail_cards[0], tail_cards[1]],
		[mid_cards[1], mid_cards[2], tail_cards[1], tail_cards[2]],
	]
	for sg: Array in subgrids:
		if _check_all_red(sg) or _check_all_black(sg):
			return true
	return false

## 慢打: 影=散牌(示弱) + 滅=豹子(收网) (德扑慢打战术)
static func _check_slow_play(
		head_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult) -> bool:
	return head_eval.hand_type == CardData.HandType3.HIGH_CARD_3 \
		and tail_eval.hand_type == CardData.HandType3.THREE_OF_KIND_3


## 四对半: 4×2+1×1 unique rank distribution (十三张报到压缩版, 2-2-2-2-1)
static func _check_four_pairs_half(cards: Array) -> bool:
	var rank_counts: Dictionary = {}
	for c: CardData.PlayingCard in cards:
		rank_counts[c.rank] = rank_counts.get(c.rank, 0) + 1
	if rank_counts.size() != 5:
		return false
	var pairs: int = 0
	var singles: int = 0
	for count: int in rank_counts.values():
		if count == 2:
			pairs += 1
		elif count == 1:
			singles += 1
		else:
			return false
	return pairs == 4 and singles == 1


## 文武: 三行中同时存在豹子(文)和散牌(武) — 牌型之巅与牌型之底同炉
static func _check_wen_wu(
		head_eval: HandEvaluator3.EvalResult,
		mid_eval: HandEvaluator3.EvalResult,
		tail_eval: HandEvaluator3.EvalResult) -> bool:
	var has_baozi: bool = false
	var has_sanpai: bool = false
	for eval: HandEvaluator3.EvalResult in [head_eval, mid_eval, tail_eval]:
		if eval.hand_type == CardData.HandType3.THREE_OF_KIND_3:
			has_baozi = true
		if eval.hand_type == CardData.HandType3.HIGH_CARD_3:
			has_sanpai = true
	return has_baozi and has_sanpai
