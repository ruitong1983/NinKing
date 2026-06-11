class_name ItemData
extends RefCounted

## Defines all 10 consumable items.
## v4.0 — all ×mult values integer; add_chips/add_mult applied to all 3 groups (跟组走).

const ALL_ITEMS: Array[Dictionary] = [
	{ "id": "item_001", "name": "幸运星", "effect": {"add_chips": 25}, "cost": 2, "desc": "本回合+25筹码" },
	{ "id": "item_002", "name": "倍率药水", "effect": {"add_mult": 5}, "cost": 3, "desc": "本回合+5倍率" },
	{ "id": "item_003", "name": "双重增强", "effect": {"add_chips": 15, "add_mult": 3}, "cost": 4, "desc": "本回合+15筹码/+3倍率" },
	{ "id": "item_004", "name": "顺子变换", "effect": {"add_chips": 20, "add_mult": 2}, "cost": 3, "desc": "本回合+20筹码/+2倍率" },
	{ "id": "item_005", "name": "同花强化", "effect": {"add_chips": 10, "add_mult": 4}, "cost": 3, "desc": "本回合+10筹码/+4倍率" },
	{ "id": "item_006", "name": "Ace增幅", "effect": {"add_chips": 35}, "cost": 5, "desc": "本回合+35筹码" },
	{ "id": "item_007", "name": "王牌加护", "effect": {"add_mult": 8}, "cost": 5, "desc": "本回合+8倍率" },
	{ "id": "item_008", "name": "暴击骰子", "effect": {"x_mult": 2}, "cost": 8, "desc": "本回合×2倍率" },
	{ "id": "item_009", "name": "满堂彩", "effect": {"add_chips": 50}, "cost": 6, "desc": "本回合+50筹码" },
	{ "id": "item_010", "name": "终极药水", "effect": {"add_chips": 40, "add_mult": 10}, "cost": 10, "desc": "本回合+40筹码/+10倍率" },
]


static func get_random_items(count: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = ALL_ITEMS.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result
