class_name ConsumableData
extends RefCounted

## All consumable cards for NinKing (v3.1 — grilled): 符術 (12), 南斗六星 (6), 禁術 (4).
## Changes: merged 4 suit cards → 1, deleted enc_007/arc_005, modified enc_009/enc_014/arc_001/arc_003.

# ══════════════════════════════════════════
# 符術 (Fujutsu) — 12 total (was 16)
# Applied to a selected card in hand
# ══════════════════════════════════════════

const FUJUTSU_CARDS: Array[Dictionary] = [
	# ── 花色转化 (1 — merged from 4) ──
	{ "id": "enc_001", "name": "花色符", "effect": {"set_suit_choice": true}, "cost": 2,
	  "desc": "将1张牌变为指定花色（♠/♥/♦/♣ 自选）" },

	# ── 点数转化 (2) ──
	{ "id": "enc_005", "name": "晋升令", "effect": {"rank_shift": 1}, "cost": 3,
	  "desc": "将1张牌点数+1（K→A, A→2）" },
	{ "id": "enc_006", "name": "降格令", "effect": {"rank_shift": -1}, "cost": 3,
	  "desc": "将1张牌点数-1（2→A, A→K）" },

	# ── 增强 (8) ──
	{ "id": "enc_008", "name": "镀金牌", "effect": {"enhancement": 1}, "cost": 3,
	  "desc": "增强: 镀金 — 所在组计分后+$3" },
	{ "id": "enc_009", "name": "淬火牌", "effect": {"enhancement": 2}, "cost": 3,
	  "desc": "增强: 淬火 — 所在组为散牌时×2" },
	{ "id": "enc_010", "name": "玄铁牌", "effect": {"enhancement": 3}, "cost": 4,
	  "desc": "增强: 玄铁 — +50筹码, 无花色无点数" },
	{ "id": "enc_011", "name": "琉璃牌", "effect": {"enhancement": 4}, "cost": 5,
	  "desc": "增强: 琉璃 — 所在组×2, 1/4碎裂" },
	{ "id": "enc_012", "name": "强化牌", "effect": {"enhancement": 5}, "cost": 3,
	  "desc": "增强: 强化 — 所在组+30筹码" },
	{ "id": "enc_013", "name": "魔能牌", "effect": {"enhancement": 6}, "cost": 3,
	  "desc": "增强: 魔能 — 所在组+4倍率" },
	{ "id": "enc_014", "name": "混沌牌", "effect": {"enhancement": 7}, "cost": 7,
	  "desc": "增强: 混沌 — 视为所有花色" },
	{ "id": "enc_015", "name": "鸿运牌", "effect": {"enhancement": 8}, "cost": 6,
	  "desc": "增强: 鸿运 — 1/5 +20倍率, 1/15 +$20" },

	# ── 销毁 (1) ──
	{ "id": "enc_016", "name": "放逐令", "effect": {"destroy": true, "gold": 5}, "cost": 3,
	  "desc": "销毁1张牌, +$5（不可销毁至手牌 < 9张）" },
]


# ══════════════════════════════════════════
# 南斗六星 (Star Charts) — 6 total
# Upgrades hand type base chips/mult
# ══════════════════════════════════════════

const STAR_CHART_CARDS: Array[Dictionary] = [
	{ "id": "star_001", "name": "天府", "hand_type": 0, "cost": 3,
	  "desc": "散牌升级: +5筹码 +1倍率" },
	{ "id": "star_002", "name": "天梁", "hand_type": 1, "cost": 3,
	  "desc": "对子升级: +8筹码 +1倍率" },
	{ "id": "star_003", "name": "天机", "hand_type": 2, "cost": 4,
	  "desc": "顺子升级: +10筹码 +1倍率" },
	{ "id": "star_004", "name": "天同", "hand_type": 3, "cost": 4,
	  "desc": "同花升级: +10筹码 +1倍率" },
	{ "id": "star_005", "name": "天相", "hand_type": 4, "cost": 5,
	  "desc": "同花顺升级: +12筹码 +2倍率" },
	{ "id": "star_006", "name": "七杀", "hand_type": 5, "cost": 5,
	  "desc": "豹子升级: +20筹码 +2倍率" },
]


# ══════════════════════════════════════════
# 禁術 (Kinjutsu) — 4 total (was 5, deleted arc_005 铸造)
# Powerful but with cost
# ══════════════════════════════════════════

const KINJUTSU_CARDS: Array[Dictionary] = [
	{ "id": "arc_001", "name": "黑龙仪式",
	  "effect": {"force_black_or_red_xi": true},
	  "cost": 8, "desc": "本次封印全黑→×2 或 全红→×2（同时触发→×3）\n代价: -$10" },
	{ "id": "arc_002", "name": "影之献祭",
	  "effect": {"random_ninja_negative": true, "destroy_other_ninjas": true},
	  "cost": 12, "desc": "随机忍者牌获得影印(+1槽位)\n代价: 销毁其余忍者牌" },
	{ "id": "arc_003", "name": "涅槃",
	  "effect": {"destroy_hand_redraw": true},
	  "cost": 6, "desc": "销毁手牌, 每种花色抽2张+额外1张=9张\n代价: 本次封印牌面筹码-10" },
	{ "id": "arc_004", "name": "轮回眼",
	  "effect": {"skip_seal": true},
	  "cost": 15, "desc": "跳过本次封印(直接过关)\n代价: 跳过商店" },
]


# ══════════════════════════════════════════
# Query helpers
# ══════════════════════════════════════════

static func get_random_fujutsu(count: int) -> Array[Dictionary]:
	var pool: Array = FUJUTSU_CARDS.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result


static func get_random_star_charts(count: int) -> Array[Dictionary]:
	var pool: Array = STAR_CHART_CARDS.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result


static func get_random_kinjutsu(count: int) -> Array[Dictionary]:
	var pool: Array = KINJUTSU_CARDS.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result


## Get star chart for a specific hand type
static func get_star_chart_for_type(hand_type: int) -> Dictionary:
	for chart: Dictionary in STAR_CHART_CARDS:
		if chart["hand_type"] == hand_type:
			return chart
	return {}
