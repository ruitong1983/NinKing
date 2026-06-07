class_name CardData
extends RefCounted

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }
enum Rank {
	TWO = 2, THREE = 3, FOUR = 4, FIVE = 5,
	SIX = 6, SEVEN = 7, EIGHT = 8, NINE = 9, TEN = 10,
	JACK = 11, QUEEN = 12, KING = 13, ACE = 14
}

enum HandType {
	HIGH_CARD, ONE_PAIR, TWO_PAIR, THREE_OF_A_KIND,
	STRAIGHT, FLUSH, FULL_HOUSE, FOUR_OF_A_KIND,
	STRAIGHT_FLUSH, ROYAL_FLUSH
}

const HAND_TYPE_NAMES: Dictionary = {
	HandType.HIGH_CARD: "高牌",
	HandType.ONE_PAIR: "一对",
	HandType.TWO_PAIR: "两对",
	HandType.THREE_OF_A_KIND: "三条",
	HandType.STRAIGHT: "顺子",
	HandType.FLUSH: "同花",
	HandType.FULL_HOUSE: "葫芦",
	HandType.FOUR_OF_A_KIND: "四条",
	HandType.STRAIGHT_FLUSH: "同花顺",
	HandType.ROYAL_FLUSH: "皇家同花顺",
}

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

const RANK_CHIP_VALUES: Dictionary = {
	Rank.TWO: 2, Rank.THREE: 3, Rank.FOUR: 4, Rank.FIVE: 5,
	Rank.SIX: 6, Rank.SEVEN: 7, Rank.EIGHT: 8, Rank.NINE: 9, Rank.TEN: 10,
	Rank.JACK: 10, Rank.QUEEN: 10, Rank.KING: 10, Rank.ACE: 11,
}

const HAND_BASE_VALUES: Dictionary = {
	HandType.HIGH_CARD: {"chips": 5, "mult": 1},
	HandType.ONE_PAIR: {"chips": 10, "mult": 2},
	HandType.TWO_PAIR: {"chips": 20, "mult": 2},
	HandType.THREE_OF_A_KIND: {"chips": 30, "mult": 3},
	HandType.STRAIGHT: {"chips": 30, "mult": 4},
	HandType.FLUSH: {"chips": 35, "mult": 4},
	HandType.FULL_HOUSE: {"chips": 40, "mult": 4},
	HandType.FOUR_OF_A_KIND: {"chips": 60, "mult": 7},
	HandType.STRAIGHT_FLUSH: {"chips": 80, "mult": 8},
	HandType.ROYAL_FLUSH: {"chips": 100, "mult": 8},
}

class Card:
	var suit: Suit
	var rank: Rank

	func _init(s: Suit, r: Rank) -> void:
		suit = s
		rank = r

	func get_chip_value() -> int:
		return RANK_CHIP_VALUES[rank]

	func get_display_name() -> String:
		return SUIT_NAMES[suit] + RANK_NAMES[rank]

	func is_equal(other: Card) -> bool:
		return suit == other.suit and rank == other.rank


static func create_standard_deck() -> Array[Card]:
	var deck: Array[Card] = []
	for suit: Suit in Suit.values():
		for rank: Rank in Rank.values():
			deck.append(Card.new(suit, rank))
	return deck


static func get_hand_type_name(ht: HandType) -> String:
	return HAND_TYPE_NAMES.get(ht, "未知")


static func get_hand_base(ht: HandType) -> Dictionary:
	return HAND_BASE_VALUES[ht]
