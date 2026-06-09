class_name CardData
extends RefCounted

## Core data definitions for NinKing (忍者牌 × 忍者牌).
## 9-card hand → 3 groups × 3 cards, ascending strength constraint.
## v3.2 — all scoring values integer (float purge).

# ──────────────────────────── Enums ────────────────────────────

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }

enum Rank {
	TWO = 2, THREE = 3, FOUR = 4, FIVE = 5,
	SIX = 6, SEVEN = 7, EIGHT = 8, NINE = 9, TEN = 10,
	JACK = 11, QUEEN = 12, KING = 13, ACE = 14
}

## 3-card hand types (比鸡 standard)
enum HandType3 {
	HIGH_CARD_3 = 0,      # 散牌 / 乌龙
	ONE_PAIR_3 = 1,       # 对子
	STRAIGHT_3 = 2,       # 顺子
	FLUSH_3 = 3,          # 同花
	STRAIGHT_FLUSH_3 = 4, # 同花顺
	THREE_OF_KIND_3 = 5,  # 豹子 / 三条
}

## Card enhancement (附魔) — applied by 附魔卡
enum Enhancement {
	NONE = 0,
	GOLD = 1,      # 镀金 — +$3 when group scores
	STEEL = 2,     # 淬火 — ×2 mult if group is 散牌
	STONE = 3,     # 玄铁 — +50 chips, no suit/rank
	GLASS = 4,     # 琉璃 — ×2 mult for group, 1/4 break
	BONUS = 5,     # 强化 — +30 chips for group
	MULT = 6,      # 魔能 — +4 mult for group
	WILD = 7,      # 混沌 — counts as all suits
	LUCKY = 8,     # 鸿运 — 1/5 +20 mult; 1/15 +$20
}

## Card seal (封印) — one per card, stacks with enhancement
enum Seal {
	NONE = 0,
	RED = 1,    # 🔴 — card's chip/enhancement contribution ×2
	GOLD = 2,   # 🟡 — +$3 when played
	BLUE = 3,   # 🔵 — after group scores → gain star chart for that hand type
	PURPLE = 4, # 🟣 — when redrawn → gain one 符術卡
}

## Card edition (版本) — low-probability bonus
enum Edition {
	NONE = 0,
	FOIL = 1,       # 金印 — +50 chips
	HOLOGRAPHIC = 2,# 彩印 — +10 mult
	POLYCHROME = 3, # 极印 — ×2 mult
}

# ──────────────────────────── Constants ────────────────────────────

const SUIT_NAMES: Dictionary = {
	Suit.CLUBS: "♣",
	Suit.DIAMONDS: "♦",
	Suit.HEARTS: "♥",
	Suit.SPADES: "♠",
}

const RANK_NAMES: Dictionary = {
	Rank.TWO: "2", Rank.THREE: "3", Rank.FOUR: "4", Rank.FIVE: "5",
	Rank.SIX: "6", Rank.SEVEN: "7", Rank.EIGHT: "8", Rank.NINE: "9",
	Rank.TEN: "10", Rank.JACK: "J", Rank.QUEEN: "Q", Rank.KING: "K", Rank.ACE: "A",
}

## Single-char suit codes for SVG card filenames (e.g., "c" → clubs)
const SUIT_FILE_CHARS: Dictionary = {
	Suit.CLUBS: "c",
	Suit.DIAMONDS: "d",
	Suit.HEARTS: "h",
	Suit.SPADES: "s",
}

## Single-char rank codes for SVG card filenames (e.g., "T" → ten)
const RANK_FILE_CHARS: Dictionary = {
	Rank.TWO: "2", Rank.THREE: "3", Rank.FOUR: "4", Rank.FIVE: "5",
	Rank.SIX: "6", Rank.SEVEN: "7", Rank.EIGHT: "8", Rank.NINE: "9",
	Rank.TEN: "T", Rank.JACK: "J", Rank.QUEEN: "Q", Rank.KING: "K", Rank.ACE: "A",
}

## Chip value for each face card rank
const RANK_CHIP_VALUES: Dictionary = {
	Rank.TWO: 2, Rank.THREE: 3, Rank.FOUR: 4, Rank.FIVE: 5,
	Rank.SIX: 6, Rank.SEVEN: 7, Rank.EIGHT: 8, Rank.NINE: 9, Rank.TEN: 10,
	Rank.JACK: 10, Rank.QUEEN: 10, Rank.KING: 10, Rank.ACE: 11,
}

## Suit tiebreaker for hand strength (♠ > ♥ > ♦ > ♣) — integer scaled
const SUIT_TIEBREAK: Dictionary = {
	Suit.SPADES: 4,
	Suit.HEARTS: 3,
	Suit.DIAMONDS: 2,
	Suit.CLUBS: 1,
}

## 3-card hand type display names
const HAND_TYPE3_NAMES: Dictionary = {
	HandType3.HIGH_CARD_3: "散牌",
	HandType3.ONE_PAIR_3: "对子",
	HandType3.STRAIGHT_3: "顺子",
	HandType3.FLUSH_3: "同花",
	HandType3.STRAIGHT_FLUSH_3: "同花顺",
	HandType3.THREE_OF_KIND_3: "豹子",
}

## 3-card hand type base values (chips + mult)
const HAND_TYPE3_BASE_VALUES: Dictionary = {
	HandType3.HIGH_CARD_3: {"chips": 5, "mult": 1},
	HandType3.ONE_PAIR_3: {"chips": 10, "mult": 2},
	HandType3.STRAIGHT_3: {"chips": 20, "mult": 3},
	HandType3.FLUSH_3: {"chips": 30, "mult": 4},
	HandType3.STRAIGHT_FLUSH_3: {"chips": 50, "mult": 5},
	HandType3.THREE_OF_KIND_3: {"chips": 100, "mult": 8},
}

## 3-card hand type base values for COLUMNS (vertical) — ~1.8x horizontal values
## Reduced from 2.5x (Plan C) so column optimization is rewarding but not mandatory
const COLUMN_HAND_TYPE3_BASE_VALUES: Dictionary = {
	HandType3.HIGH_CARD_3: {"chips": 0, "mult": 0},
	HandType3.ONE_PAIR_3: {"chips": 15, "mult": 4},
	HandType3.STRAIGHT_3: {"chips": 35, "mult": 7},
	HandType3.FLUSH_3: {"chips": 55, "mult": 11},
	HandType3.STRAIGHT_FLUSH_3: {"chips": 100, "mult": 22},
	HandType3.THREE_OF_KIND_3: {"chips": 180, "mult": 35},
}

## Star chart level-up increments per use
const STAR_CHART_UPGRADES: Dictionary = {
	HandType3.HIGH_CARD_3: {"chips": 5, "mult": 1},
	HandType3.ONE_PAIR_3: {"chips": 8, "mult": 1},
	HandType3.STRAIGHT_3: {"chips": 10, "mult": 1},
	HandType3.FLUSH_3: {"chips": 10, "mult": 1},
	HandType3.STRAIGHT_FLUSH_3: {"chips": 12, "mult": 2},
	HandType3.THREE_OF_KIND_3: {"chips": 20, "mult": 2},
}

# ──────────────────────────── PlayingCard Class ────────────────────────────

class PlayingCard:
	var suit: Suit
	var rank: Rank = Rank.ACE
	var enhancement: Enhancement = Enhancement.NONE
	var seal: Seal = Seal.NONE
	var edition: Edition = Edition.NONE

	func _init(s: Suit, r: Rank) -> void:
		suit = s
		rank = r

	func get_chip_value() -> int:
		return RANK_CHIP_VALUES[rank]

	func get_display_name() -> String:
		var name_str: String = SUIT_NAMES[suit] + RANK_NAMES[rank]
		if enhancement != Enhancement.NONE:
			name_str += "[" + ENHANCEMENT_SHORT_NAMES.get(enhancement, "?") + "]"
		return name_str

	func is_equal(other: PlayingCard) -> bool:
		return suit == other.suit and rank == other.rank

	func is_face() -> bool:
		return rank == Rank.JACK or rank == Rank.QUEEN or rank == Rank.KING

	func is_ace() -> bool:
		return rank == Rank.ACE

	func get_effective_suits() -> Array[Suit]:
		## Wild cards count as all suits
		if enhancement == Enhancement.WILD:
			return [Suit.CLUBS, Suit.DIAMONDS, Suit.HEARTS, Suit.SPADES]
		return [suit]

	func get_edition_chips() -> int:
		if edition == Edition.FOIL:
			return 50
		return 0

	func get_edition_mult() -> int:
		if edition == Edition.HOLOGRAPHIC:
			return 10
		return 0

	func get_edition_x_mult() -> int:
		if edition == Edition.POLYCHROME:
			return 2
		return 1

	func get_enhancement_chips() -> int:
		match enhancement:
			Enhancement.STONE:
				return 50
			Enhancement.BONUS:
				return 30
		return 0

	func get_enhancement_mult() -> int:
		if enhancement == Enhancement.MULT:
			return 4
		return 0

	func get_enhancement_x_mult(group_hand_type: HandType3) -> int:
		match enhancement:
			Enhancement.GLASS:
				return 2        # group ×2, 1/4 break
			Enhancement.STEEL:
				if group_hand_type == HandType3.HIGH_CARD_3:
					return 2   # only if group is 散牌
		return 1

	func get_seal_x_chips() -> int:
		if seal == Seal.RED:
			return 2          # card contribution ×2
		return 1

	func get_seal_gold() -> int:
		if seal == Seal.GOLD:
			return 3
		return 0

	func is_seal_blue() -> bool:
		return seal == Seal.BLUE

	func is_seal_purple() -> bool:
		return seal == Seal.PURPLE

	func is_stone_card() -> bool:
		return enhancement == Enhancement.STONE


const ENHANCEMENT_SHORT_NAMES: Dictionary = {
	Enhancement.GOLD: "金",
	Enhancement.STEEL: "钢",
	Enhancement.STONE: "石",
	Enhancement.GLASS: "璃",
	Enhancement.BONUS: "强",
	Enhancement.MULT: "魔",
	Enhancement.WILD: "混",
	Enhancement.LUCKY: "运",
}

# ──────────────────────────── Static Methods ────────────────────────────

static func create_standard_deck() -> Array[PlayingCard]:
	var deck: Array[PlayingCard] = []
	for suit: Suit in Suit.values():
		for rank: Rank in Rank.values():
			deck.append(PlayingCard.new(suit, rank))
	return deck

static func get_hand_type3_name(ht: HandType3) -> String:
	return HAND_TYPE3_NAMES.get(ht, "未知")

static func get_hand_type3_base(ht: HandType3) -> Dictionary:
	return HAND_TYPE3_BASE_VALUES.get(ht, {"chips": 0, "mult": 0})

static func get_star_chart_upgrade(ht: HandType3) -> Dictionary:
	return STAR_CHART_UPGRADES.get(ht, {"chips": 0, "mult": 0})


## Leveled hand type values (base + upgrade × level). Used by scoring and auto-arranger.
static func get_hand_type3_leveled_chips(ht: HandType3, levels: Dictionary) -> int:
	var base: Dictionary = get_hand_type3_base(ht)
	var upgrade: Dictionary = get_star_chart_upgrade(ht)
	var lvl: int = levels.get(ht, 0)
	return base["chips"] + upgrade["chips"] * lvl


static func get_hand_type3_leveled_mult(ht: HandType3, levels: Dictionary) -> int:
	var base: Dictionary = get_hand_type3_base(ht)
	var upgrade: Dictionary = get_star_chart_upgrade(ht)
	var lvl: int = levels.get(ht, 0)
	return base["mult"] + upgrade["mult"] * lvl


static func get_hand_type3_column_leveled_chips(ht: HandType3, levels: Dictionary) -> int:
	var base: Dictionary = COLUMN_HAND_TYPE3_BASE_VALUES.get(ht, {"chips": 0, "mult": 0})
	var upgrade: Dictionary = get_star_chart_upgrade(ht)
	var lvl: int = levels.get(ht, 0)
	return base["chips"] + upgrade["chips"] * lvl


static func get_hand_type3_column_leveled_mult(ht: HandType3, levels: Dictionary) -> int:
	var base: Dictionary = COLUMN_HAND_TYPE3_BASE_VALUES.get(ht, {"chips": 0, "mult": 0})
	var upgrade: Dictionary = get_star_chart_upgrade(ht)
	var lvl: int = levels.get(ht, 0)
	return base["mult"] + upgrade["mult"] * lvl


## Calculate hand strength for 3-card group (used for constraint: 头 ≤ 中 ≤ 尾)
## Formula: hand_type × 100 + high_rank × 10 + mid_rank + suit_tiebreak (int)
static func calc_hand_strength(ht: HandType3, cards: Array[PlayingCard]) -> int:
	var type_val: int = int(ht)
	var ranks: Array[int] = []
	var high_suit: Suit = Suit.CLUBS

	for c: PlayingCard in cards:
		ranks.append(c.rank)

	ranks.sort()
	# High card and mid card
	var high: int = ranks[2]
	var mid: int = ranks[1]

	# Find suit of high card for tiebreaker
	for c: PlayingCard in cards:
		if c.rank == high:
			high_suit = c.suit
			break

	var strength: int = type_val * 100 + high * 10 + mid + SUIT_TIEBREAK[high_suit]
	return strength


## Check if 3 cards form ascending strength: a ≤ b ≤ c
static func check_strength_order(a_str: int, b_str: int, c_str: int) -> bool:
	return a_str <= b_str and b_str <= c_str
