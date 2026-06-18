#!/usr/bin/env python3
"""
NinKing 关卡模拟 — 参数与数据配置
忍者牌全量数据、策略定义、优先级分类、关卡配置
"""
import random

# ══════════════════════════════════════════
# 游戏常量
# ══════════════════════════════════════════

STARTING_GOLD = 8
MAX_NINJA_SLOTS = 5
INTEREST_PER_5 = 1        # 每$5得$1
INTEREST_CAP = 5           # 利息上限
SHOP_NINJA_COUNT = 4       # 商店展示忍者数
SHOP_REFRESH_COST = 3      # 刷新费用(基准), 递进 +1/次
MAX_REFRESH_PER_SHOP = 1   # 模拟中最多刷新次数

# ══════════════════════════════════════════
# 结界配置 (代码值)
# ══════════════════════════════════════════

BARRIER_CONFIG = [
    # barrier 1 (v5.2 — 30% reduction)
    [{"type": "修羅", "target": 10500,  "gold": 3},
     {"type": "明王", "target": 17500,  "gold": 5},
     {"type": "夜叉", "target": 28000,  "gold": 8}],
    # barrier 2
    [{"type": "修羅", "target": 28000,  "gold": 3},
     {"type": "明王", "target": 42000,  "gold": 5},
     {"type": "夜叉", "target": 56000,  "gold": 8}],
    # barrier 3
    [{"type": "修羅", "target": 42000,  "gold": 3},
     {"type": "明王", "target": 70000,  "gold": 5},
     {"type": "夜叉", "target": 105000, "gold": 8}],
    # barrier 4
    [{"type": "修羅", "target": 70000,  "gold": 3},
     {"type": "明王", "target": 105000, "gold": 5},
     {"type": "夜叉", "target": 140000, "gold": 8}],
    # barrier 5
    [{"type": "修羅", "target": 105000, "gold": 3},
     {"type": "明王", "target": 140000, "gold": 5},
     {"type": "夜叉", "target": 210000, "gold": 8}],
    # barrier 6
    [{"type": "修羅", "target": 140000, "gold": 3},
     {"type": "明王", "target": 210000, "gold": 5},
     {"type": "夜叉", "target": 280000, "gold": 8}],
    # barrier 7
    [{"type": "修羅", "target": 210000, "gold": 3},
     {"type": "明王", "target": 280000, "gold": 5},
     {"type": "夜叉", "target": 350000, "gold": 8}],
    # barrier 8
    [{"type": "修羅", "target": 280000, "gold": 3},
     {"type": "明王", "target": 350000, "gold": 5},
     {"type": "夜叉", "target": 455000, "gold": 8}],
]

# ══════════════════════════════════════════
# 策略定义
# ══════════════════════════════════════════

STRATEGIES = {
    "对子流": {"hand_type": 1, "name_cn": "对子"},
    "顺子流": {"hand_type": 2, "name_cn": "顺子"},
    "同花流": {"hand_type": 3, "name_cn": "同花"},
    "同花顺流": {"hand_type": 4, "name_cn": "同花顺"},
    "豹子流": {"hand_type": 5, "name_cn": "豹子"},
}

BUDGET_TIERS = {
    "extreme": 0.8,
    "conservative": 0.4,
}

# ══════════════════════════════════════════
# 忍者优先级分类
# ══════════════════════════════════════════

def classify_priority(effect):
    """根据effect判断忍者优先级数值(越高越优先购买)"""
    # 倍率X - 全行
    if effect.get("x_mult_to_rows", 0) > 1:
        return 10
    # 倍率X - 牌型条件
    if effect.get("x_mult", 1) > 1 and "hand_type" in effect.get("condition", {}):
        return 9
    # 倍率X - 组定向
    if effect.get("x_mult", 1) > 1 and "group" in effect.get("condition", {}):
        return 8
    # 倍率X - 经济转化
    if effect.get("x_per_gold", 0) > 1:
        return 7
    # 倍率+ - 列条件→全行
    if effect.get("add_mult_to_rows", 0) > 0:
        return 6
    # 倍率+ - 经济转化
    if effect.get("mult_per_gold", 0) > 0:
        return 5
    # 倍率+ - 牌型条件
    if effect.get("add_mult", 0) > 0 and "hand_type" in effect.get("condition", {}):
        return 4
    # 筹码 - 列条件→全行
    if effect.get("add_chips_to_rows", 0) > 0:
        return 3
    # 倍率+ - 组定向
    if effect.get("add_mult", 0) > 0 and "group" in effect.get("condition", {}):
        return 2
    # 筹码 - 牌型条件
    if effect.get("add_chips", 0) > 0 and "hand_type" in effect.get("condition", {}):
        return 1
    # 筹码 - 组定向
    if effect.get("add_chips", 0) > 0 and "group" in effect.get("condition", {}):
        return 1
    # 经济类(喜鹊/福神/利息之印)
    if effect.get("xi_x_bonus", 0) > 0:
        return 7  # 喜鹊提升喜倍率, 优先级放高点
    return 0

# ══════════════════════════════════════════
# 全量忍者牌数据 (39张)
# ══════════════════════════════════════════

ALL_NINJAS = [
    # ── 筹码 · 牌型条件 (001-005) ──
    {"id": "n_001", "name": "手里剑", "cost": 4, "rarity": "common",
     "effect": {"add_chips": 10, "condition": {"hand_type": 1}}},
    {"id": "n_002", "name": "苦无", "cost": 5, "rarity": "uncommon",
     "effect": {"add_chips": 20, "condition": {"hand_type": 2}}},
    {"id": "n_003", "name": "忍刀", "cost": 7, "rarity": "uncommon",
     "effect": {"add_chips": 30, "condition": {"hand_type": 3}}},
    {"id": "n_004", "name": "重刃", "cost": 10, "rarity": "rare",
     "effect": {"add_chips": 40, "condition": {"hand_type": 4}}},
    {"id": "n_005", "name": "影缝", "cost": 12, "rarity": "rare",
     "effect": {"add_chips": 50, "condition": {"hand_type": 5}}},

    # ── 筹码 · 组定向 (006-008) ──
    {"id": "n_006", "name": "蓄勢", "cost": 4, "rarity": "common",
     "effect": {"add_chips": 10, "condition": {"group": "head"}}},
    {"id": "n_007", "name": "積力", "cost": 5, "rarity": "uncommon",
     "effect": {"add_chips": 20, "condition": {"group": "mid"}}},
    {"id": "n_008", "name": "満貫", "cost": 7, "rarity": "rare",
     "effect": {"add_chips": 30, "condition": {"group": "tail"}}},

    # ── 筹码 · 列传行 (009-011) ──
    {"id": "n_009", "name": "微波", "cost": 5, "rarity": "uncommon",
     "effect": {"add_chips_to_rows": 20, "condition": {"col_hand_type": 1}}},
    {"id": "n_010", "name": "席卷", "cost": 6, "rarity": "uncommon",
     "effect": {"add_chips_to_rows": 30, "condition": {"col_hand_type": 2}}},
    {"id": "n_011", "name": "震荡", "cost": 8, "rarity": "uncommon",
     "effect": {"add_chips_to_rows": 40, "condition": {"col_hand_type": 3}}},

    # ── 倍率+ · 牌型条件 (051) ──
    {"id": "n_051", "name": "并蒂", "cost": 5, "rarity": "common",
     "effect": {"add_mult": 2, "condition": {"hand_type": 1}}},

    # ── 倍率+ · 组定向 (052-054) ──
    {"id": "n_052", "name": "先阵", "cost": 4, "rarity": "common",
     "effect": {"add_mult": 2, "condition": {"group": "head"}}},
    {"id": "n_053", "name": "中坚", "cost": 5, "rarity": "uncommon",
     "effect": {"add_mult": 3, "condition": {"group": "mid"}}},
    {"id": "n_054", "name": "大将", "cost": 7, "rarity": "rare",
     "effect": {"add_mult": 4, "condition": {"group": "tail"}}},

    # ── 倍率+ · 牌型条件进阶 (055-057) ──
    {"id": "n_055", "name": "流觞", "cost": 6, "rarity": "uncommon",
     "effect": {"add_mult": 3, "condition": {"hand_type": 2}}},
    {"id": "n_056", "name": "贯月", "cost": 10, "rarity": "rare",
     "effect": {"add_mult": 5, "condition": {"hand_type": 4}}},
    {"id": "n_057", "name": "鼎立", "cost": 13, "rarity": "rare",
     "effect": {"add_mult": 6, "condition": {"hand_type": 5}}},

    # ── 倍率+ · 列传行 (058-060) ──
    {"id": "n_058", "name": "律動", "cost": 5, "rarity": "uncommon",
     "effect": {"add_mult_to_rows": 3, "condition": {"col_hand_type": 1}}},
    {"id": "n_059", "name": "共鳴", "cost": 7, "rarity": "uncommon",
     "effect": {"add_mult_to_rows": 4, "condition": {"col_hand_type": 2}}},
    {"id": "n_060", "name": "響震", "cost": 10, "rarity": "rare",
     "effect": {"add_mult_to_rows": 5, "condition": {"col_hand_type": 3}}},

    # ── 倍率+ · 经济转化 (061) ──
    {"id": "n_061", "name": "金剛力", "cost": 8, "rarity": "rare",
     "effect": {"mult_per_gold": 1, "mult_gold_step": 5, "mult_gold_cap": 10}},

    # ── 倍率X · 组定向 (101-103) ──
    {"id": "n_101", "name": "开局", "cost": 7, "rarity": "rare",
     "effect": {"x_mult": 2, "condition": {"group": "head"}}},
    {"id": "n_102", "name": "中盘", "cost": 10, "rarity": "rare",
     "effect": {"x_mult": 3, "condition": {"group": "mid"}}},
    {"id": "n_103", "name": "收官", "cost": 14, "rarity": "rare",
     "effect": {"x_mult": 4, "condition": {"group": "tail"}}},

    # ── 倍率X · 牌型条件 (104-108 五遁) ──
    {"id": "n_104", "name": "风遁", "cost": 6, "rarity": "uncommon",
     "effect": {"x_mult": 2, "condition": {"hand_type": 1}}},
    {"id": "n_105", "name": "水遁", "cost": 9, "rarity": "rare",
     "effect": {"x_mult": 3, "condition": {"hand_type": 2}}},
    {"id": "n_106", "name": "土遁", "cost": 12, "rarity": "rare",
     "effect": {"x_mult": 4, "condition": {"hand_type": 3}}},
    {"id": "n_107", "name": "火遁", "cost": 14, "rarity": "rare",
     "effect": {"x_mult": 5, "condition": {"hand_type": 4}}},
    {"id": "n_108", "name": "雷遁", "cost": 16, "rarity": "rare",
     "effect": {"x_mult": 6, "condition": {"hand_type": 5}}},

    # ── 倍率X · 滅组 (109) ──
    {"id": "n_109", "name": "金尾", "cost": 6, "rarity": "uncommon",
     "effect": {"x_mult": 2, "condition": {"group": "tail"}}},

    # ── 倍率X · 列传行 (110-112) ──
    {"id": "n_110", "name": "閃光", "cost": 8, "rarity": "rare",
     "effect": {"x_mult_to_rows": 2, "condition": {"col_hand_type": 1}}},
    {"id": "n_111", "name": "流光", "cost": 12, "rarity": "rare",
     "effect": {"x_mult_to_rows": 3, "condition": {"col_hand_type": 2}}},
    {"id": "n_112", "name": "極光", "cost": 16, "rarity": "rare",
     "effect": {"x_mult_to_rows": 4, "condition": {"col_hand_type": 3}}},

    # ── 倍率X · 喜之强化 (113-114) ──
    {"id": "n_113", "name": "喜鹊", "cost": 4, "rarity": "uncommon",
     "effect": {"xi_x_bonus": 1}},
    {"id": "n_114", "name": "龙之眼", "cost": 18, "rarity": "rare",
     "effect": {"xi_max_mult_stack": True}},

    # ── 倍率X · 经济转化 (115) ──
    {"id": "n_115", "name": "黄金律", "cost": 14, "rarity": "rare",
     "effect": {"x_per_gold": 2, "x_gold_step": 15, "x_gold_cap": 3}},

    # ── 经济 (151-152) ──
    {"id": "n_151", "name": "福神", "cost": 6, "rarity": "uncommon",
     "effect": {"gold_per_xi": 2}},
    {"id": "n_152", "name": "利息之印", "cost": 7, "rarity": "uncommon",
     "effect": {"interest_cap_bonus": 5}},
]

# ══════════════════════════════════════════
# 忍者池工具
# ══════════════════════════════════════════

def get_random_ninjas(count, exclude_ids=None):
    """从全池随机取N张, 排除已拥有"""
    if exclude_ids is None:
        exclude_ids = []
    pool = [n for n in ALL_NINJAS if n["id"] not in exclude_ids]
    random.shuffle(pool)
    return pool[:count]


def owned_ids(ninjas):
    """提取已拥有忍者的ID列表"""
    return [n["id"] for n in ninjas]


def strategy_to_hand_type(strategy_name):
    """策略名→牌型枚举值"""
    s = STRATEGIES.get(strategy_name)
    return s["hand_type"] if s else -1


def matches_strategy(ninja, strategy_name):
    """检查一张忍者是否匹配当前构筑方向"""
    effect = ninja.get("effect", {})
    cond = effect.get("condition", {})
    ht = cond.get("hand_type", -1)
    target_ht = strategy_to_hand_type(strategy_name)

    # 直接牌型匹配
    if ht == target_ht:
        return True

    # 列牌型匹配
    col_ht = cond.get("col_hand_type", -1)
    if col_ht == target_ht:
        return True

    # 组定向忍者 — 任何方向都可用
    if cond.get("group", "") in ("head", "mid", "tail", "head_or_mid"):
        return True

    # 无条件忍者 — 任何方向都可用
    if not cond:
        return True

    # 经济转化忍者 — 任何方向都可用
    if effect.get("mult_per_gold", 0) > 0 or effect.get("x_per_gold", 0) > 0:
        return True

    # 喜鹊/龙之眼/福神/利息之印 — 任何方向都可用
    if effect.get("xi_x_bonus", 0) > 0:
        return True
    if effect.get("xi_max_mult_stack", False):
        return True
    if effect.get("gold_per_xi", 0) > 0:
        return True
    if effect.get("interest_cap_bonus", 0) > 0:
        return True

    return False


def pick_best_ninja(candidates):
    """按优先级+价格选出最好的忍者"""
    candidates.sort(key=lambda n: (-classify_priority(n.get("effect", {})), -n["cost"]))
    return candidates[0]
