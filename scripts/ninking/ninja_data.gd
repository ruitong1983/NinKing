class_name NinjaData
extends RefCounted

## Full ninja card pool for NinKing v3.2 (integer scoring).
## 43 active + 2 deferred = 45 defined.
## Tags (7 types): 筹码 / 倍率+ / 倍率X / 经济 / 操控 / 成长 / 特殊
##   - 筹码: add_chips 系
##   - 倍率+: add_mult 系
##   - 倍率X: x_mult / ×倍 系
##   - 经济: 金币产出 / 钱→数值转化
##   - 操控: 出牌/首击×2/死亡保底
##   - 成长: 累积型（含重置风险）
##   - 特殊: 规则变更 / 传说 / 条件时间窗口
## Changes from v3.2: category:String → tags:Array[String] (multi-tag)
##
## Shop generation → NinjaPool. Scaling engine → NinjaScaling.

# ══════════════════════════════════════════
# Complete pool — 43 cards (43 active)
# ══════════════════════════════════════════

const ALL_NINJAS: Array[Dictionary] = [
	# ─── 通用加成 (6) ───
	{
		"id": "n_001", "tags": ["筹码"], "name": "手里剑",
		"effect": {"add_chips": 10},
		"cost": 3, "rarity": "common",
		"desc": "+10 筹码"
	},
	{
		"id": "n_002", "tags": ["倍率+"], "name": "苦无",
		"effect": {"add_mult": 4},
		"cost": 4, "rarity": "common",
		"desc": "+4 倍率"
	},
	{
		"id": "n_003", "tags": ["筹码", "倍率+"], "name": "忍刀",
		"effect": {"add_chips": 15, "add_mult": 2},
		"cost": 5, "rarity": "common",
		"desc": "+15 筹码, +2 倍率"
	},
	{
		"id": "n_004", "tags": ["筹码"], "name": "重刃",
		"effect": {"add_chips": 20},
		"cost": 4, "rarity": "common",
		"desc": "+20 筹码"
	},
	{
		"id": "n_005", "tags": ["倍率+"], "name": "影缝",
		"effect": {"add_mult": 10},
		"cost": 8, "rarity": "uncommon",
		"desc": "+10 倍率"
	},
	{
		"id": "n_006", "tags": ["筹码", "倍率+"], "name": "奥义之卷",
		"effect": {"add_chips": 30, "add_mult": 10},
		"cost": 14, "rarity": "rare",
		"desc": "+30筹码 +10倍率"
	},

	# ─── 组别定向 (10) ───
	{
		"id": "n_g01", "tags": ["倍率+"], "name": "虎头",
		"effect": {
			"add_mult": 5,
			"condition": {"group": "head", "at_most_hand_type": 1}
		},
		"cost": 5, "rarity": "uncommon",
		"desc": "影为散牌或对子时 +5 倍率"
	},
	{
		"id": "n_g02", "tags": ["倍率X"], "name": "龙尾",
		"effect": {
			"x_mult": 2,
			"condition": {"group": "tail", "at_least_hand_type": 4}
		},
		"cost": 12, "rarity": "rare",
		"desc": "滅为同花顺或豹子时 ×2"
	},
	{
		"id": "n_g03", "tags": ["筹码"], "name": "中流砥柱",
		"effect": {
			"add_chips": 50,
			"condition": {"group": "mid"}
		},
		"cost": 6, "rarity": "uncommon",
		"desc": "瞬 +50 筹码"
	},
	{
		"id": "n_g04", "tags": ["操控"], "name": "藏锋",
		"effect": {
			"extra_plays": 2
		},
		"cost": 10, "rarity": "rare",
		"desc": "+2 出牌次数"
	},
	{
		"id": "n_g05", "tags": ["倍率X"], "name": "双头蛇",
		"effect": {
			"duplicate_hand_x2": true
		},
		"cost": 8, "rarity": "rare",
		"desc": "行+列同牌型计分×2"
	},
	{
		"id": "n_g06", "tags": ["倍率X"], "name": "金字塔",
		"effect": {"pyramid_x3": true},
		"cost": 10, "rarity": "rare",
		"desc": "各组牌型高于前组时该组×3（影无条件）"
	},
	{
		"id": "n_g07", "tags": ["倍率X"], "name": "三清道人",
		"effect": {
			"x_mult": 2,
			"condition": {"hand_type": 3}
		},
		"cost": 7, "rarity": "uncommon",
		"desc": "同花组计分×2"
	},
	{
		"id": "n_g08", "tags": ["倍率X"], "name": "龙脉",
		"effect": {
			"x_mult": 2,
			"condition": {"hand_type": 2}
		},
		"cost": 8, "rarity": "uncommon",
		"desc": "顺子组计分×2"
	},
	{
		"id": "n_s05", "tags": ["倍率X"], "name": "天华",
		"effect": {"x_mult": 4, "condition": {"hand_type": 4}},
		"cost": 11, "rarity": "rare",
		"desc": "同花顺组计分×4"
	},
	{
		"id": "n_s06", "tags": ["倍率X"], "name": "王座",
		"effect": {"x_mult": 5, "condition": {"hand_type": 5}},
		"cost": 12, "rarity": "rare",
		"desc": "豹子组计分×5"
	},

	# ─── 规则变更 (2, 互斥) ───
	{
		"id": "n_r02", "tags": ["筹码", "特殊"], "name": "均衡之印",
		"effect": {"all_non_scatter_add_chips": 50},
		"cost": 7, "rarity": "rare",
		"desc": "三行非散排时所有行列组 +50 筹码",
	},
	{
		"id": "n_r03", "tags": ["倍率X", "特殊"], "name": "独尊之印",
		"effect": {"tail_only_x3": true},
		"cost": 9, "rarity": "rare",
		"desc": "前两行不计分，只对第三行计分×3",
	},

	# ─── 喜之强化 (6 — 2 deferred) ───
	{
		"id": "n_x01", "tags": ["倍率X"], "name": "喜鹊",
		"effect": {"xi_x_bonus": 1},
		"cost": 4, "rarity": "uncommon",
		"desc": "每个喜的×倍率效果 +1"
	},
	{
		"id": "n_x02", "tags": ["筹码"], "name": "四张猎人",
		"effect": {
			"add_chips": 50, "condition": {"xi": "四张"}
		},
		"cost": 6, "rarity": "uncommon",
		"desc": "四张出现时所有行列组 +50 筹码"
	},
	{
		"id": "n_x03", "tags": ["倍率X"], "name": "两仪",
		"effect": {"x_mult": 5, "condition": {"has_2_and_ace": true}},
		"cost": 6, "rarity": "uncommon",
		"desc": "手牌中有 2 和 A 时全局×5"
	},
	{
		"id": "n_x06", "tags": ["倍率X"], "name": "龙之眼",
		"effect": {"xi_max_mult_stack": true},
		"cost": 18, "rarity": "rare",
		"desc": "多个喜触发时全部按最高喜倍率结算"
	},

	# ─── 成长修炼 (0) — 已迁移 ───

	# ─── 经济 (5 — n_e03 俭约已删除) ───
	{
		"id": "n_e01", "tags": ["经济"], "name": "福神",
		"effect": {"gold_per_xi": 2},
		"cost": 6, "rarity": "uncommon",
		"desc": "出牌后每触发一个喜 +$2"
	},
	{
		"id": "n_e02", "tags": ["倍率X"], "name": "金尾",
		"effect": {"x_mult": 2, "condition": {"group": "tail"}},
		"cost": 6, "rarity": "uncommon",
		"desc": "滅组计分×2"
	},
	{
		"id": "n_e04", "tags": ["经济"], "name": "利息之印",
		"effect": {"interest_cap_bonus": 5},
		"cost": 7, "rarity": "uncommon",
		"desc": "利息上限 +$5"
	},
	{
		"id": "n_e05", "tags": ["倍率+", "经济"], "name": "金剛力",
		"effect": {"mult_per_gold": 1, "mult_gold_step": 5, "mult_gold_cap": 10},
		"cost": 8, "rarity": "rare",
		"desc": "每持有$5 +1倍率（上限+10）"
	},
	{
		"id": "n_e06", "tags": ["倍率X", "经济"], "name": "黄金律",
		"effect": {"x_per_gold": 2, "x_gold_step": 15, "x_gold_cap": 3},
		"cost": 14, "rarity": "rare",
		"desc": "每$15持有×2（最多触发3次）"
	},

	# ─── 忍法 (4) ───
	{
		"id": "n_t01", "tags": ["倍率+"], "name": "火遁",
		"effect": {"add_mult": 8, "condition": {"hand_type": 4}},
		"cost": 8, "rarity": "uncommon",
		"desc": "同花顺组+8 倍率"
	},
	{
		"id": "n_t02", "tags": ["倍率+"], "name": "水遁",
		"effect": {"add_mult": 5, "condition": {"hand_type": 2}},
		"cost": 6, "rarity": "uncommon",
		"desc": "顺子组+5 倍率"
	},
	{
		"id": "n_t05", "tags": ["倍率+"], "name": "风遁",
		"effect": {"add_mult": 3, "condition": {"hand_type": 1}},
		"cost": 7, "rarity": "uncommon",
		"desc": "对子组+3 倍率"
	},
	{
		"id": "n_t06", "tags": ["倍率+"], "name": "土遁",
		"effect": {"add_mult": 5, "condition": {"hand_type": 3}},
		"cost": 10, "rarity": "rare",
		"desc": "同花组+5 倍率"
	},

	# ─── 传说 (3) ───
	{
		"id": "n_l01", "tags": ["特殊"], "name": "天下人",
		"effect": {
			"share_col_hand_to_rows": true
		},
		"cost": 999, "rarity": "legendary",
		"desc": "非散牌列的牌型加成分摊到三行"
	},
	{
		"id": "n_l02", "tags": ["特殊"], "name": "幻术大师",
		"effect": {
			"only_one_play": true,
			"share_tail_hand_to_head_mid": true
		},
		"cost": 999, "rarity": "legendary",
		"desc": "仅1次出牌，滅的牌型加成（筹码+倍率）分摊到影和瞬"
	},
	{
		"id": "n_l03", "tags": ["特殊"], "name": "影武者",
		"effect": {"random_group_x3": true},
		"cost": 999, "rarity": "legendary",
		"desc": "每次出牌随机 1 组获得 ×3"
	},

	# ─── 组别定向 (1) — 成双 ───
	{
		"id": "n_d01", "tags": ["筹码"], "name": "成双",
		"effect": {
			"pair_even_chips": 8,
			"condition": {"hand_type": 1}
		},
		"cost": 4, "rarity": "common",
		"desc": "对子牌型时，组内每张偶数数字牌 +8 筹码"
	},
	{
		"id": "n_t07", "tags": ["操控", "倍率X"], "name": "赌命",
		"effect": {"extra_plays": -1, "x_mult": 2},
		"cost": 7, "rarity": "uncommon",
		"desc": "出牌次数-1，三行三列均×2"
	},

	# ─── 跨组联动 (2) ───
	{
		"id": "n_c01", "tags": ["倍率X"], "name": "镜像",
		"effect": {
			"x_mult": 2,
			"condition": {"head_tail_same_type": true}
		},
		"cost": 6, "rarity": "uncommon",
		"desc": "影牌型 = 滅牌型时 ×2"
	},
	{
		"id": "n_c02", "tags": ["筹码", "倍率+"], "name": "铁索连环",
		"effect": {
			"add_chips": 15, "add_mult": 3,
			"condition": {"any_two_groups_same_type": true}
		},
		"cost": 6, "rarity": "uncommon",
		"desc": "两组同牌型→全组+15筹码+3倍率"
	},

	# ─── 点数/人牌 (3) ───
	{
		"id": "n_f01", "tags": ["筹码"], "name": "影之眷顾",
		"effect": {"add_chips_per_face": 3},
		"cost": 5, "rarity": "common",
		"desc": "手中每张 J/Q/K +3 筹码"
	},
	{
		"id": "n_f02", "tags": ["倍率+"], "name": "王牌侍从",
		"effect": {"add_mult_per_ace": 5, "ace_mult_cap": 20},
		"cost": 5, "rarity": "uncommon",
		"desc": "手中每张 Ace +5 倍率（上限 +20）"
	},
	{
		"id": "n_f03", "tags": ["筹码", "倍率+"], "name": "独行者",
		"effect": {"ace_chips": 30, "ace_mult": 3, "condition": {"group_has_ace": true}},
		"cost": 6, "rarity": "uncommon",
		"desc": "组内含 A 时该组 +30筹码 +3倍率"
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
	"n_x01", "n_s06", "n_e01", "n_t02",
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
