class_name NinjaData
extends RefCounted

## Full ninja card pool for NinKing v3.2 (integer scoring).
## 39 active cards, reorganized by tag groups (2026-06-17):
##   筹码 001-050 / 倍率+ 051-100 / 倍率X 101-150 / 经济 151-200
## Removed: n_006 成双, n_013 铁索连环
## Tags (7 types): 筹码 / 倍率+ / 倍率X / 经济 / 操控 / 成长 / 特殊
##
## Shop generation → NinjaPool. Scaling engine → NinjaScaling.

# ══════════════════════════════════════════
# Tag 1: 筹码 (11) — n_001 ~ n_050
# ══════════════════════════════════════════

const ALL_NINJAS: Array[Dictionary] = [
	# ─── 筹码 · 牌型条件 → 行+列 ───
	{
		"id": "n_001", "tags": ["筹码"], "name": "手里剑",
		"effect": {"add_chips": 10, "condition": {"hand_type": 1}},
		"cost": 4, "rarity": "common",
		"desc": "对子组（行+列）+10筹码"
	},
	{
		"id": "n_002", "tags": ["筹码"], "name": "苦无",
		"effect": {"add_chips": 20, "condition": {"hand_type": 2}},
		"cost": 5, "rarity": "uncommon",
		"desc": "顺子组（行+列）+20筹码"
	},
	{
		"id": "n_003", "tags": ["筹码"], "name": "忍刀",
		"effect": {"add_chips": 30, "condition": {"hand_type": 3}},
		"cost": 7, "rarity": "uncommon",
		"desc": "同花组（行+列）+30筹码"
	},
	{
		"id": "n_004", "tags": ["筹码"], "name": "重刃",
		"effect": {"add_chips": 40, "condition": {"hand_type": 4}},
		"cost": 10, "rarity": "rare",
		"desc": "同花顺组（行+列）+40筹码"
	},
	{
		"id": "n_005", "tags": ["筹码"], "name": "影缝",
		"effect": {"add_chips": 50, "condition": {"hand_type": 5}},
		"cost": 12, "rarity": "rare",
		"desc": "豹子组（行+列）+50筹码"
	},

	# ─── 筹码 · 组别定向 ───
	{
		"id": "n_006", "tags": ["筹码"], "name": "蓄勢",
		"effect": {"add_chips": 10, "condition": {"group": "head"}},
		"cost": 4, "rarity": "common",
		"desc": "影行 +10筹码"
	},
	{
		"id": "n_007", "tags": ["筹码"], "name": "積力",
		"effect": {"add_chips": 20, "condition": {"group": "mid"}},
		"cost": 5, "rarity": "uncommon",
		"desc": "瞬行 +20筹码"
	},
	{
		"id": "n_008", "tags": ["筹码"], "name": "満貫",
		"effect": {"add_chips": 30, "condition": {"group": "tail"}},
		"cost": 7, "rarity": "rare",
		"desc": "滅行 +30筹码"
	},

	# ─── 筹码 · 列传行（列条件→全行）───
	{
		"id": "n_009", "tags": ["筹码"], "name": "微波",
		"effect": {"add_chips_to_rows": 20, "condition": {"col_hand_type": 1}},
		"cost": 5, "rarity": "uncommon",
		"desc": "任一列有对子时，全行 +20 筹码"
	},
	{
		"id": "n_010", "tags": ["筹码"], "name": "席卷",
		"effect": {"add_chips_to_rows": 30, "condition": {"col_hand_type": 2}},
		"cost": 6, "rarity": "uncommon",
		"desc": "任一列有顺子时，全行 +30 筹码"
	},
	{
		"id": "n_011", "tags": ["筹码"], "name": "震荡",
		"effect": {"add_chips_to_rows": 40, "condition": {"col_hand_type": 3}},
		"cost": 8, "rarity": "uncommon",
		"desc": "任一列有同花时，全行 +40 筹码"
	},

	# ══════════════════════════════════════════
	# Tag 2: 倍率+ (11) — n_051 ~ n_100
	# ══════════════════════════════════════════

	# ─── 倍率+ · 牌型条件 → 行+列 ───
	{
		"id": "n_051", "tags": ["倍率+"], "name": "并蒂",
		"effect": {"add_mult": 2, "condition": {"hand_type": 1}},
		"cost": 5, "rarity": "common",
		"desc": "对子组（行+列）+2倍率"
	},

	# ─── 倍率+ · 组别定向 ───
	{
		"id": "n_052", "tags": ["倍率+"], "name": "先阵",
		"effect": {"add_mult": 2, "condition": {"group": "head"}},
		"cost": 4, "rarity": "common",
		"desc": "影行 +2倍率"
	},
	{
		"id": "n_053", "tags": ["倍率+"], "name": "中坚",
		"effect": {"add_mult": 3, "condition": {"group": "mid"}},
		"cost": 5, "rarity": "uncommon",
		"desc": "瞬行 +3倍率"
	},
	{
		"id": "n_054", "tags": ["倍率+"], "name": "大将",
		"effect": {"add_mult": 4, "condition": {"group": "tail"}},
		"cost": 7, "rarity": "rare",
		"desc": "滅行 +4倍率"
	},

	# ─── 倍率+ · 牌型条件 → 行+列（进阶）───
	{
		"id": "n_055", "tags": ["倍率+"], "name": "流觞",
		"effect": {"add_mult": 3, "condition": {"hand_type": 2}},
		"cost": 6, "rarity": "uncommon",
		"desc": "顺子组（行+列）+3倍率"
	},
	{
		"id": "n_056", "tags": ["倍率+"], "name": "贯月",
		"effect": {"add_mult": 5, "condition": {"hand_type": 4}},
		"cost": 10, "rarity": "rare",
		"desc": "同花顺组（行+列）+5倍率"
	},
	{
		"id": "n_057", "tags": ["倍率+"], "name": "鼎立",
		"effect": {"add_mult": 6, "condition": {"hand_type": 5}},
		"cost": 13, "rarity": "rare",
		"desc": "豹子组（行+列）+6倍率"
	},

	# ─── 倍率+ · 列传行（列条件→全行）───
	{
		"id": "n_058", "tags": ["倍率+"], "name": "律動",
		"effect": {"add_mult_to_rows": 3, "condition": {"col_hand_type": 1}},
		"cost": 5, "rarity": "uncommon",
		"desc": "任一列有对子时，全行 +3 倍率"
	},
	{
		"id": "n_059", "tags": ["倍率+"], "name": "共鳴",
		"effect": {"add_mult_to_rows": 4, "condition": {"col_hand_type": 2}},
		"cost": 7, "rarity": "uncommon",
		"desc": "任一列有顺子时，全行 +4 倍率"
	},
	{
		"id": "n_060", "tags": ["倍率+"], "name": "響震",
		"effect": {"add_mult_to_rows": 5, "condition": {"col_hand_type": 3}},
		"cost": 10, "rarity": "rare",
		"desc": "任一列有同花时，全行 +5 倍率"
	},

	# ─── 倍率+ · 经济转化 ───
	{
		"id": "n_061", "tags": ["倍率+", "经济"], "name": "金剛力",
		"effect": {"mult_per_gold": 1, "mult_gold_step": 5, "mult_gold_cap": 10},
		"cost": 8, "rarity": "rare",
		"desc": "每持有$5 +1倍率（上限+10）"
	},

	# ══════════════════════════════════════════
	# Tag 3: 倍率X (15) — n_101 ~ n_150
	# ══════════════════════════════════════════

	# ─── 倍率X · 组别定向 ───
	{
		"id": "n_101", "tags": ["倍率X"], "name": "开局",
		"effect": {"x_mult": 2, "condition": {"group": "head"}},
		"cost": 7, "rarity": "rare",
		"desc": "影行 ×2"
	},
	{
		"id": "n_102", "tags": ["倍率X"], "name": "中盘",
		"effect": {"x_mult": 3, "condition": {"group": "mid"}},
		"cost": 10, "rarity": "rare",
		"desc": "瞬行 ×3"
	},
	{
		"id": "n_103", "tags": ["倍率X"], "name": "收官",
		"effect": {"x_mult": 4, "condition": {"group": "tail"}},
		"cost": 14, "rarity": "rare",
		"desc": "滅行 ×4"
	},

	# ─── 倍率X · 牌型条件 → 行+列（五遁）───
	{
		"id": "n_104", "tags": ["倍率X"], "name": "风遁",
		"effect": {"x_mult": 2, "condition": {"hand_type": 1}},
		"cost": 6, "rarity": "uncommon",
		"desc": "对子组（行+列）×2"
	},
	{
		"id": "n_105", "tags": ["倍率X"], "name": "水遁",
		"effect": {"x_mult": 3, "condition": {"hand_type": 2}},
		"cost": 9, "rarity": "rare",
		"desc": "顺子组（行+列）×3"
	},
	{
		"id": "n_106", "tags": ["倍率X"], "name": "土遁",
		"effect": {"x_mult": 4, "condition": {"hand_type": 3}},
		"cost": 12, "rarity": "rare",
		"desc": "同花组（行+列）×4"
	},
	{
		"id": "n_107", "tags": ["倍率X"], "name": "火遁",
		"effect": {"x_mult": 5, "condition": {"hand_type": 4}},
		"cost": 14, "rarity": "rare",
		"desc": "同花顺组（行+列）×5"
	},
	{
		"id": "n_108", "tags": ["倍率X"], "name": "雷遁",
		"effect": {"x_mult": 6, "condition": {"hand_type": 5}},
		"cost": 16, "rarity": "rare",
		"desc": "豹子组（行+列）×6"
	},

	# ─── 倍率X · 滅组 ───
	{
		"id": "n_109", "tags": ["倍率X"], "name": "金尾",
		"effect": {"x_mult": 2, "condition": {"group": "tail"}},
		"cost": 6, "rarity": "uncommon",
		"desc": "滅组计分×2"
	},

	# ─── 倍率X · 列传行（列条件→全行）───
	{
		"id": "n_110", "tags": ["倍率X"], "name": "閃光",
		"effect": {"x_mult_to_rows": 2, "condition": {"col_hand_type": 1}},
		"cost": 8, "rarity": "rare",
		"desc": "任一列有对子时，全行 ×2"
	},
	{
		"id": "n_111", "tags": ["倍率X"], "name": "流光",
		"effect": {"x_mult_to_rows": 3, "condition": {"col_hand_type": 2}},
		"cost": 12, "rarity": "rare",
		"desc": "任一列有顺子时，全行 ×3"
	},
	{
		"id": "n_112", "tags": ["倍率X"], "name": "極光",
		"effect": {"x_mult_to_rows": 4, "condition": {"col_hand_type": 3}},
		"cost": 16, "rarity": "rare",
		"desc": "任一列有同花时，全行 ×4"
	},

	# ─── 倍率X · 喜之强化 ───
	{
		"id": "n_113", "tags": ["倍率X"], "name": "喜鹊",
		"effect": {"xi_x_bonus": 1},
		"cost": 4, "rarity": "uncommon",
		"desc": "每个喜的×倍率效果 +1"
	},
	{
		"id": "n_114", "tags": ["倍率X"], "name": "龙之眼",
		"effect": {"xi_max_mult_stack": true},
		"cost": 18, "rarity": "rare",
		"desc": "多个喜触发时全部按最高喜倍率结算"
	},

	# ─── 倍率X · 经济转化 ───
	{
		"id": "n_115", "tags": ["倍率X", "经济"], "name": "黄金律",
		"effect": {"x_per_gold": 2, "x_gold_step": 15, "x_gold_cap": 3},
		"cost": 14, "rarity": "rare",
		"desc": "每$15持有×2（最多触发3次）"
	},

	# ══════════════════════════════════════════
	# Tag 4: 经济 (2) — n_151 ~ n_200
	# ══════════════════════════════════════════

	{
		"id": "n_151", "tags": ["经济"], "name": "福神",
		"effect": {"gold_per_xi": 2},
		"cost": 6, "rarity": "uncommon",
		"desc": "出牌后每触发一个喜 +$2"
	},
	{
		"id": "n_152", "tags": ["经济"], "name": "利息之印",
		"effect": {"interest_cap_bonus": 5},
		"cost": 7, "rarity": "uncommon",
		"desc": "利息上限 +$5"
	},
]


# ═══ Icon mapping — DEPRECATED: use AssetRegistry ═══
# ⚠️ 路径和函数已迁移到 scripts/ninking/asset_registry.gd
# 保留此 stub 为向后兼容，新代码请直接调用 AssetRegistry.get_icon_path()。

static func get_icon_path(ninja_id: String, effect: Dictionary = {}) -> String:
	return AssetRegistry.get_icon_path(ninja_id, effect)


static func _get_effect_subtype_suffix(ninja_id: String, effect: Dictionary) -> String:
	return AssetRegistry._get_effect_subtype_suffix(ninja_id, effect)



## Starter set for Phase A testing
const STARTER_IDS: Array[String] = [
	"n_001", "n_002", "n_052", "n_054", "n_059",
	"n_105", "n_111", "n_113", "n_151",
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
