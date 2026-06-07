class_name JokerData
extends RefCounted

## Defines all 30 jokers and their effects.

enum TriggerType {
	ALWAYS,           # Always apply effect
	ON_HAND_TYPE,     # Triggers on specific hand type
	ON_FACE_CARD,     # Triggers when face cards played
	ON_ACE,           # Triggers when Ace played
	ON_SUIT,          # Triggers on specific suit
}

const ALL_JOKERS: Array[Dictionary] = [
	# === 通用加成 ===
	{ "id": "joker_001", "name": "幸运筹码", "effect": { "add_chips": 10 }, "cost": 3 },
	{ "id": "joker_002", "name": "加倍小丑", "effect": { "add_mult": 4 }, "cost": 4 },
	{ "id": "joker_003", "name": "贪婪小丑", "effect": { "add_chips": 15, "add_mult": 2 }, "cost": 5 },
	{ "id": "joker_004", "name": "稳重加分", "effect": { "add_chips": 20 }, "cost": 4 },

	# === 牌型触发 ===
	{ "id": "joker_005", "name": "对子专家", "effect": { "add_chips": 15, "condition": { "hand_type": CardData.HandType.ONE_PAIR } }, "cost": 4 },
	{ "id": "joker_006", "name": "两对大师", "effect": { "add_chips": 25, "condition": { "hand_type": CardData.HandType.TWO_PAIR } }, "cost": 5 },
	{ "id": "joker_007", "name": "三条狂热", "effect": { "add_mult": 6, "condition": { "hand_type": CardData.HandType.THREE_OF_A_KIND } }, "cost": 6 },
	{ "id": "joker_008", "name": "顺子达人", "effect": { "add_chips": 30, "add_mult": 3, "condition": { "hand_type": CardData.HandType.STRAIGHT } }, "cost": 7 },
	{ "id": "joker_009", "name": "同花使者", "effect": { "add_chips": 15, "add_mult": 4, "condition": { "hand_type": CardData.HandType.FLUSH } }, "cost": 7 },
	{ "id": "joker_010", "name": "葫芦工匠", "effect": { "add_chips": 40, "condition": { "hand_type": CardData.HandType.FULL_HOUSE } }, "cost": 8 },
	{ "id": "joker_011", "name": "四条猎手", "effect": { "x_mult": 1.5, "condition": { "hand_type": CardData.HandType.FOUR_OF_A_KIND } }, "cost": 10 },
	{ "id": "joker_012", "name": "同花顺神", "effect": { "add_chips": 50, "add_mult": 5, "condition": { "hand_type": CardData.HandType.STRAIGHT_FLUSH } }, "cost": 12 },
	{ "id": "joker_013", "name": "皇家礼炮", "effect": { "x_mult": 2.0, "condition": { "hand_type": CardData.HandType.ROYAL_FLUSH } }, "cost": 15 },

	# === 人牌触发 ===
	{ "id": "joker_014", "name": "笑脸", "effect": { "add_mult": 5, "condition": { "contains_face": true } }, "cost": 5 },
	{ "id": "joker_015", "name": "王室加成", "effect": { "add_chips": 25, "condition": { "contains_face": true } }, "cost": 5 },

	# === Ace 触发 ===
	{ "id": "joker_016", "name": "王牌之力", "effect": { "add_mult": 6, "condition": { "contains_ace": true } }, "cost": 6 },
	{ "id": "joker_017", "name": "王牌筹码", "effect": { "add_chips": 30, "condition": { "contains_ace": true } }, "cost": 5 },

	# === 倍率增强 ===
	{ "id": "joker_018", "name": "倍数翻倍", "effect": { "add_mult": 10 }, "cost": 8 },
	{ "id": "joker_019", "name": "超级加倍", "effect": { "x_mult": 1.5 }, "cost": 10 },
	{ "id": "joker_020", "name": "指数增长", "effect": { "x_mult": 2.0 }, "cost": 15 },

	# === 混合效果 ===
	{ "id": "joker_021", "name": "平衡之道", "effect": { "add_chips": 12, "add_mult": 3 }, "cost": 6 },
	{ "id": "joker_022", "name": "万能牌", "effect": { "add_chips": 30, "add_mult": 10 }, "cost": 14 },
	{ "id": "joker_023", "name": "新手运", "effect": { "add_chips": 8, "add_mult": 1 }, "cost": 1 },
	{ "id": "joker_024", "name": "老千", "effect": { "add_chips": 10, "add_mult": 5 }, "cost": 7 },
	{ "id": "joker_025", "name": "赌徒直觉", "effect": { "add_chips": 5, "add_mult": 8 }, "cost": 7 },

	# === 组合加成 ===
	{ "id": "joker_026", "name": "同花底牌", "effect": { "add_chips": 10, "add_mult": 2, "condition": { "hand_type": CardData.HandType.FLUSH } }, "cost": 5 },
	{ "id": "joker_027", "name": "顺子底牌", "effect": { "add_chips": 12, "add_mult": 2, "condition": { "hand_type": CardData.HandType.STRAIGHT } }, "cost": 5 },
	{ "id": "joker_028", "name": "高牌救星", "effect": { "add_chips": 20, "add_mult": 3, "condition": { "hand_type": CardData.HandType.HIGH_CARD } }, "cost": 6 },
	{ "id": "joker_029", "name": "一对救星", "effect": { "add_chips": 18, "add_mult": 3, "condition": { "hand_type": CardData.HandType.ONE_PAIR } }, "cost": 5 },
	{ "id": "joker_030", "name": "终极王牌", "effect": { "add_chips": 50, "add_mult": 15 }, "cost": 18 },
]


static func get_random_jokers(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = ALL_JOKERS.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result
