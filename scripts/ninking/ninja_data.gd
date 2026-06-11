class_name NinjaData
extends RefCounted

## Full ninja card pool for NinKing v3.2 (integer scoring).
## 45 active + 2 deferred = 47 defined.
## Changes from v3.1: all values integer; ×1.3→×2, ×1.5→×2, ×2.5→×3;
##   喜鹊 +0.3→+1, 忍法帖 +0.2→+1, 藏锋 scale recalculated, 清一色×3.
##
## Shop generation → NinjaPool. Scaling engine → NinjaScaling.

# ══════════════════════════════════════════
# Complete pool — 45 cards (43 active + 2 deferred)
# ══════════════════════════════════════════

const ALL_NINJAS: Array[Dictionary] = [
	# ─── 通用加成 (6) ───
	{
		"id": "n_001", "name": "手里剑",
		"effect": {"add_chips": 10},
		"cost": 3, "rarity": "common",
		"desc": "+10 筹码"
	},
	{
		"id": "n_002", "name": "苦无",
		"effect": {"add_mult": 4},
		"cost": 4, "rarity": "common",
		"desc": "+4 倍率"
	},
	{
		"id": "n_003", "name": "风魔手里剑",
		"effect": {"add_chips": 15, "add_mult": 2},
		"cost": 5, "rarity": "common",
		"desc": "+15 筹码, +2 倍率"
	},
	{
		"id": "n_004", "name": "重刃",
		"effect": {"add_chips": 20},
		"cost": 4, "rarity": "common",
		"desc": "+20 筹码"
	},
	{
		"id": "n_005", "name": "影缝",
		"effect": {"add_mult": 10},
		"cost": 8, "rarity": "uncommon",
		"desc": "+10 倍率"
	},
	{
		"id": "n_006", "name": "奥义之卷",
		"effect": {"add_chips": 30, "add_mult": 10},
		"cost": 14, "rarity": "rare",
		"desc": "+30 筹码, +10 倍率"
	},

	# ─── 组别定向 (6) ───
	{
		"id": "n_g01", "name": "虎头",
		"effect": {
			"add_mult": 5,
			"condition": {"group": "head", "at_most_hand_type": 1}
		},
		"cost": 5, "rarity": "uncommon",
		"desc": "影为散牌或对子时 +5 倍率"
	},
	{
		"id": "n_g02", "name": "龙尾",
		"effect": {
			"x_mult": 2,
			"condition": {"group": "tail", "at_least_hand_type": 4}
		},
		"cost": 12, "rarity": "rare",
		"desc": "滅为同花顺或豹子时 ×2"
	},
	{
		"id": "n_g03", "name": "中流砥柱",
		"effect": {
			"add_chips": 50,
			"condition": {"group": "mid"}
		},
		"cost": 6, "rarity": "uncommon",
		"desc": "瞬 +50 筹码"
	},
	{
		"id": "n_g04", "name": "藏锋",
		"effect": {
			"x_mult_per_head_weakness": true
		},
		"cost": 8, "rarity": "rare",
		"desc": "影越弱滅越强: 散牌×3, 对子×2, 顺子/同花×1",
		"head_weakness_scale": {
			"0": 3,
			"1": 2,
			"2": 1,
			"3": 1,
			"4": 1,
			"5": 1,
		}
	},
	{
		"id": "n_g05", "name": "双头蛇",
		"effect": {
			"add_chips": 40,
			"condition": {"group": "head_or_mid", "at_least_hand_type": 2}
		},
		"cost": 5, "rarity": "uncommon",
		"desc": "影或瞬为顺子或同花时 +40 筹码"
	},
	{
		"id": "n_g06", "name": "金字塔",
		"effect": {"x_mult": 2, "condition": {"strict_ascending_types": true}},
		"cost": 12, "rarity": "rare",
		"desc": "影<瞬<滅牌型严格递升 → ×2"
	},

	# ─── 规则变更 (2, 互斥) ───
	{
		"id": "n_r02", "name": "均衡之印",
		"effect": {"constraint_override": "equal", "equal_x_mult": 2},
		"cost": 7, "rarity": "rare",
		"desc": "三组必须同牌型，各组×2",
		"mutex_group": "rule"
	},
	{
		"id": "n_r03", "name": "独尊之印",
		"effect": {
			"x_mult": 2,
			"condition": {"group": "tail"},
			"constraint_override": "head_mid_min_pair"
		},
		"cost": 9, "rarity": "rare",
		"desc": "滅×2，影和瞬必须≥对子",
		"mutex_group": "rule"
	},

	# ─── 喜之强化 (6 — 2 deferred) ───
	{
		"id": "n_x01", "name": "喜鹊",
		"effect": {"xi_x_bonus": 1},
		"cost": 4, "rarity": "uncommon",
		"desc": "每个喜的×倍率效果 +1"
	},
	{
		"id": "n_x02", "name": "四张猎人",
		"effect": {
			"add_chips": 30, "condition": {"xi": "四张"},
			"else_chips": 5
		},
		"cost": 4, "rarity": "uncommon",
		"desc": "四张出现时 +30 筹码，否则 +5 筹码"
	},
	{
		"id": "n_x03", "name": "清一色",
		"effect": {"xi_override": {"三清": 3}},
		"cost": 7, "rarity": "rare",
		"desc": "三清时 ×3（替代默认×2）"
	},
	{
		"id": "n_x04", "name": "黑龙",
		"effect": {"x_mult": 2, "condition": {"xi": "全黑"}},
		"cost": 8, "rarity": "rare",
		"desc": "全黑触发时再 ×2",
		"deferred": true
	},
	{
		"id": "n_x05", "name": "赤凤",
		"effect": {"x_mult": 2, "condition": {"xi": "全红"}},
		"cost": 8, "rarity": "rare",
		"desc": "全红触发时再 ×2",
		"deferred": true
	},
	{
		"id": "n_x06", "name": "龙之眼",
		"effect": {"x_mult_per_extra_card": 2, "x_extra_cap": 2},
		"cost": 12, "rarity": "rare",
		"desc": "四张以上每多一张 ×2（上限2次）"
	},

	# ─── 成长修炼 (5) ───
	{
		"id": "n_s01", "name": "修行者",
		"effect": {"add_mult": 0},
		"cost": 6, "rarity": "uncommon",
		"desc": "每出牌 +1 倍率（永久累积）",
		"scaling": {"trigger": "on_play", "add_mult": 1}
	},
	{
		"id": "n_s02", "name": "三清道人",
		"effect": {"add_chips": 0},
		"cost": 7, "rarity": "uncommon",
		"desc": "每打出三清 +25 筹码（永久累积）",
		"scaling": {
			"trigger": "on_play",
			"add_chips": 25,
			"condition": {"xi": "三清"}
		}
	},
	{
		"id": "n_s03", "name": "龙脉",
		"effect": {"add_chips": 0},
		"cost": 8, "rarity": "uncommon",
		"desc": "滅为同花顺时 +30 筹码（永久累积）",
		"scaling": {
			"trigger": "on_play",
			"add_chips": 30,
			"condition": {"group": "tail", "hand_type": 4}
		}
	},
	{
		"id": "n_s05", "name": "头悬梁",
		"effect": {"add_mult": 0},
		"cost": 5, "rarity": "uncommon",
		"desc": "影为散牌时 +3 倍率；影不是散牌则重置",
		"scaling": {
			"trigger": "on_play",
			"add_mult": 3,
			"condition": {"group": "head", "hand_type": 0},
			"reset_on_fail": true
		}
	},
	{
		"id": "n_s06", "name": "尾刺骨",
		"effect": {"add_mult": 0},
		"cost": 6, "rarity": "uncommon",
		"desc": "滅为同花顺或豹子时 +5 倍率；不满足则重置",
		"scaling": {
			"trigger": "on_play",
			"add_mult": 5,
			"condition": {"group": "tail", "at_least_hand_type": 4},
			"reset_on_fail": true
		}
	},

	# ─── 经济 (6) ───
	{
		"id": "n_e01", "name": "福神",
		"effect": {"gold_per_xi": 2},
		"cost": 6, "rarity": "uncommon",
		"desc": "出牌后每触发一个喜 +$2"
	},
	{
		"id": "n_e02", "name": "金尾",
		"effect": {"gold_per_gold_card_in_tail": 3},
		"cost": 5, "rarity": "uncommon",
		"desc": "滅有镀金增强牌时 +$3/张"
	},
	{
		"id": "n_e04", "name": "利息之印",
		"effect": {"interest_cap_bonus": 5},
		"cost": 7, "rarity": "uncommon",
		"desc": "利息上限 +$5"
	},
	{
		"id": "n_e05", "name": "金剛力",
		"effect": {"mult_per_gold": 1, "mult_gold_step": 5, "mult_gold_cap": 10},
		"cost": 8, "rarity": "rare",
		"desc": "每 $5 持有 +1 倍率（上限 +10）"
	},
	{
		"id": "n_e06", "name": "黄金律",
		"effect": {"x_per_gold": 2, "x_gold_step": 15, "x_gold_cap": 3},
		"cost": 14, "rarity": "rare",
		"desc": "每 $15 持有 ×2（上限 ×3）"
	},

	# ─── 忍具 (4) ───
	{
		"id": "n_t01", "name": "分身之术",
		"effect": {"extra_plays": 1},
		"cost": 8, "rarity": "uncommon",
		"desc": "+1 出牌次数"
	},
	{
		"id": "n_t02", "name": "替身之术",
		"effect": {"extra_redraws": 1},
		"cost": 6, "rarity": "uncommon",
		"desc": "+1 手替え次数"
	},
	{
		"id": "n_t05", "name": "疾风",
		"effect": {"first_play_x2": true},
		"cost": 7, "rarity": "uncommon",
		"desc": "首回合出牌 ×2"
	},
	{
		"id": "n_t06", "name": "烟幕",
		"effect": {"death_save": true},
		"cost": 10, "rarity": "rare",
		"desc": "过关失败时保留金币回到结界开头（一局1次）"
	},

	# ─── 传说 (3) ───
	{
		"id": "n_l01", "name": "天下人",
		"effect": {
			"constraint_override": "none",
			"all_groups_x_mult": 2
		},
		"cost": 999, "rarity": "legendary",
		"desc": "排列约束解除 + 三组各×2"
	},
	{
		"id": "n_l02", "name": "幻术大师",
		"effect": {
			"all_cards_wild": true,
			"wild_coverage": 0.5,
			"wild_break_chance": 0.1
		},
		"cost": 999, "rarity": "legendary",
		"desc": "1/2手牌视为万能花色，出牌时 1/10 概率销毁 1 张"
	},
	{
		"id": "n_l03", "name": "影武者",
		"effect": {"random_group_x3": true},
		"cost": 999, "rarity": "legendary",
		"desc": "每次出牌随机 1 组获得 ×3"
	},

	# ─── 手替え激励 (2) — 新增 ───
	{
		"id": "n_d01", "name": "忍法·换",
		"effect": {"add_chips_per_redraw_this_seal": 10},
		"cost": 4, "rarity": "common",
		"desc": "每次手替え后本次封印内 +10 筹码（累计）"
	},
	{
		"id": "n_d02", "name": "赌命",
		"effect": {"extra_redraw_card": 1, "plays_minus": 1},
		"cost": 7, "rarity": "uncommon",
		"desc": "手替え上限 +1 张，但出牌次数 -1"
	},

	# ─── 跨组联动 (2) — 新增 ───
	{
		"id": "n_c01", "name": "镜像",
		"effect": {
			"x_mult": 2,
			"condition": {"head_tail_same_type": true}
		},
		"cost": 6, "rarity": "uncommon",
		"desc": "影牌型 = 滅牌型时 ×2"
	},
	{
		"id": "n_c02", "name": "铁索连环",
		"effect": {
			"add_chips": 15, "add_mult": 3,
			"condition": {"any_two_groups_same_type": true}
		},
		"cost": 8, "rarity": "rare",
		"desc": "三组中有两组牌型相同 → 各 +15 筹码 +3 倍率"
	},

	# ─── 点数/人牌 (2) — 新增 ───
	{
		"id": "n_f01", "name": "影之眷顾",
		"effect": {"add_chips_per_face": 3},
		"cost": 5, "rarity": "common",
		"desc": "手中每张 J/Q/K +3 筹码"
	},
	{
		"id": "n_f02", "name": "王牌侍从",
		"effect": {"add_mult_per_ace": 5, "ace_mult_cap": 20},
		"cost": 8, "rarity": "rare",
		"desc": "手中每张 Ace +5 倍率（上限 +20）"
	},
]


# ═══ Icon mapping — DEPRECATED: use AssetRegistry ═══
# ⚠️ 路径和函数已迁移到 scripts/ninking/asset_registry.gd
# 保留此 stub 为向后兼容，新代码请直接调用 AssetRegistry.get_icon_path()。

static func get_icon_path(ninja_id: String, effect: Dictionary = {}) -> String:
	return AssetRegistry.get_icon_path(ninja_id, effect)


static func _get_effect_subtype_suffix(ninja_id: String, effect: Dictionary) -> String:
	return AssetRegistry._get_effect_subtype_suffix(ninja_id, effect)



## Starter set for Phase A testing (updated v3.2)
const STARTER_IDS: Array[String] = [
	"n_001", "n_002", "n_g01", "n_g02", "n_r02",
	"n_x01", "n_s01", "n_s06", "n_e01", "n_t02",
]


## Look up a ninja by ID. Returns empty dict if not found.
static func get_by_id(id: String) -> Dictionary:
	for ninja: Dictionary in ALL_NINJAS:
		if ninja["id"] == id:
			return ninja
	return {}


## Build starter set from STARTER_IDS.
static func get_starter_ninjas() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in STARTER_IDS:
		var ninja: Dictionary = get_by_id(id)
		if not ninja.is_empty():
			result.append(ninja)
	return result
