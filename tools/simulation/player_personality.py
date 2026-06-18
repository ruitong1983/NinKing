#!/usr/bin/env python3
"""
NinKing 模拟 — 玩家人格模型（MBTI 32 型 · 策略外置）

从 mbti_strategies.json 读取所有人格定义（32 MBTI-A/T 型 + 3 测试基线）。
策略数据不写死在代码中：修改 JSON 即可调整任何人格的决策行为。

决策引擎 PersonalityEngine 接收人格参数 → 输出每个环节的决策。
"""
import json
import os

from sim_config import (
    ALL_NINJAS, STRATEGIES, BUDGET_TIERS, MAX_NINJA_SLOTS,
    matches_strategy, pick_best_ninja, owned_ids, get_random_ninjas,
    SHOP_NINJA_COUNT, SHOP_REFRESH_COST, MAX_REFRESH_PER_SHOP,
)


# ══════════════════════════════════════════
# JSON 加载 — 单⼀数据源
# ══════════════════════════════════════════

_STRATEGY_FILE = os.path.join(os.path.dirname(__file__), "mbti_strategies.json")
_CACHE = None  # 惰性加载


def _load_raw():
    """加载 mbti_strategies.json（只加载一次，后续缓存）"""
    global _CACHE
    if _CACHE is not None:
        return _CACHE
    with open(_STRATEGY_FILE, "r", encoding="utf-8") as f:
        _CACHE = json.load(f)
    return _CACHE


def get_groups():
    """返回组索引 {组名: {icon, description}}"""
    return _load_raw()["group_index"]


def get_all_personalities():
    """
    返回所有可模拟人格的平面列表（32 MBTI-A/T 型 + 3 测试基线）。

    每条记录：
        { group, group_icon, name, description, mbti, variant, params }
    """
    raw = _load_raw()
    result = []

    for entry in raw["mbti_types"]:
        base = {
            "mbti": entry["mbti"],
            "group": entry["group"],
            "group_icon": entry["icon"],
        }
        for vk, variant in entry["variants"].items():
            result.append({
                **base,
                "variant": vk,
                "name": variant["name"],
                "description": variant["description"],
                "params": dict(variant["params"]),  # 防御性拷贝
            })

    # 测试基线
    for baseline in raw.get("test_baselines", []):
        result.append({
            "group": baseline["group"],
            "group_icon": baseline["icon"],
            "name": baseline["name"],
            "description": baseline["description"],
            "params": dict(baseline["params"]),
        })

    return result


def get_personality_by_name(name):
    """按名称（如 '纯对子·务实'）找人格"""
    for p in get_all_personalities():
        if p["name"] == name:
            return p
    return None


def get_personalities_by_group(group_name):
    """按组名筛选人格"""
    return [p for p in get_all_personalities() if p["group"] == group_name]


# ══════════════════════════════════════════
# 决策引擎
# ══════════════════════════════════════════

class PersonalityEngine:
    """
    玩家人格决策引擎。
    接受人格参数 → 输出每个环节的决策。
    """

    def __init__(self, personality):
        self.p = personality
        self.params = personality["params"]
        self._locked_strategy = None  # 直觉流/随机开局时锁定
        self._batch_buffer = []  # 批发商积攒缓冲区

    # ── 策略决策 ──

    def pick_strategy(self, owned_ninjas=None, shop_pool=None):
        """决定当前使用的策略"""
        lock = self.params["strategy_lock"]

        # 无锁 → 灵活型逻辑
        if lock is None:
            pick_method = self.params.get("_pick_strategy", "owned_ninjas")
            return self._flexible_strategy(pick_method, owned_ninjas, shop_pool)

        # 多策略 + 纯度 < 1 → 按纯度概率切
        if len(lock) > 1 and self.params["strategy_purity"] < 1.0:
            import random
            if random.random() > self.params["strategy_purity"]:
                # 切换到其他策略
                other = [s for s in lock if s != lock[0]]
                if other:
                    return random.choice(other)

        return lock[0]

    def _flexible_strategy(self, method, owned_ninjas, shop_pool):
        """灵活型策略选择"""
        import random
        all_strategies = list(STRATEGIES.keys())

        # 直觉流：开局随机锁定
        if method == "random_start":
            if self._locked_strategy is None:
                self._locked_strategy = random.choice(all_strategies)
            return self._locked_strategy

        # 机会主义者：看商店前2张忍者的方向
        if method == "shop_first_two" and shop_pool:
            matches = {s: 0 for s in all_strategies}
            for ninja in shop_pool[:2]:
                for s in all_strategies:
                    if matches_strategy(ninja, s):
                        matches[s] += 1
            best = max(matches, key=matches.get)
            if matches[best] > 0:
                return best
            return random.choice(all_strategies)

        # 实用主义者：看已拥有的忍者
        if method == "owned_ninjas" and owned_ninjas:
            matches = {s: 0 for s in all_strategies}
            for ninja in owned_ninjas:
                for s in all_strategies:
                    if matches_strategy(ninja, s):
                        matches[s] += 1
            best = max(matches, key=matches.get)
            if matches[best] > 0:
                return best
            return random.choice(all_strategies)

        # 兜底: 随机
        return random.choice(all_strategies)

    # ── 预算决策 ──

    def calc_budget(self, gold):
        """计算最大可花费金币"""
        ratio = self.params["budget_ratio"]
        if ratio < 0:  # 混沌型随机
            import random
            ratio = random.choice([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
        return int(gold * ratio) if ratio > 0 else 0

    # ── 刷新决策 ──

    def should_refresh(self, gold, already_bought, shop_pool=None, strategy_name=None):
        """决定是否刷新商店"""
        behavior = self.params["refresh_behavior"]
        if behavior == "never":
            return False
        if behavior == "random":
            import random
            return random.random() < 0.3

        # 预算够才考虑刷新
        budget = self.calc_budget(gold)
        refresh_cost = SHOP_REFRESH_COST
        if budget < refresh_cost:
            return False

        if behavior == "core_missing" and strategy_name:
            # 检查当前商店是否有核心忍者
            has_core = any(
                matches_strategy(n, strategy_name)
                for n in shop_pool or []
            )
            return not has_core and not already_bought

        if behavior == "occasional":
            return not already_bought

        if behavior == "aggressive":
            return True

        if behavior == "all_in":
            return budget >= refresh_cost

        return False

    # ── 购买决策 ──

    def pick_from_shop(self, shop_pool, strategy_name, max_spend, owned_ninjas, gold):
        """从商店中挑选一张忍者购买"""
        # 混沌型
        if self.params.get("_random_decisions"):
            import random
            affordable = [n for n in shop_pool if n["cost"] <= max_spend]
            return random.choice(affordable) if affordable else None

        if self.params.get("_reverse_decisions"):
            # 选最差的：优先度高→低反过来
            affordable = [n for n in shop_pool if n["cost"] <= max_spend]
            if not affordable:
                return None
            sorted_aff = sorted(affordable,
                                key=lambda n: self._priority(n.get("effect", {})))
            return sorted_aff[0] if sorted_aff else None

        # 经济偏好
        economy_pref = self.params["economy_preference"]
        if economy_pref == "only_economy":
            econ = self._filter_economy(shop_pool, max_spend)
            if econ:
                return pick_best_ninja(econ)
            return None  # 守财奴没经济忍者就不买

        if economy_pref == "prefer":
            econ = self._filter_economy(shop_pool, max_spend)
            if econ and len(econ) >= len(shop_pool) // 2:
                return pick_best_ninja(econ)

        # 填坑策略
        fill = self.params["fill_slots"]
        available = MAX_NINJA_SLOTS - len(owned_ninjas)

        if fill == "immediate" and available > 0:
            # 先买最便宜的填坑
            affordable = sorted(
                [n for n in shop_pool if n["cost"] <= max_spend],
                key=lambda n: n["cost"]
            )
            if affordable:
                return affordable[0]

        if fill == "picky":
            # 只买预算内最好的(不看坑位)
            candidates = [
                n for n in shop_pool
                if matches_strategy(n, strategy_name) and n["cost"] <= max_spend
            ]
            if candidates:
                return pick_best_ninja(candidates)
            return None

        # 默认：买策略匹配且预算内最好的
        candidates = [
            n for n in shop_pool
            if matches_strategy(n, strategy_name) and n["cost"] <= max_spend
        ]
        if candidates:
            return pick_best_ninja(candidates)
        return None

    # ── 商店流程 ──

    def shop_decision(self, gold, owned_ninjas, shop_override=None):
        """
        完整的商店决策流程。
        替代原 player_shop_decision()。
        """
        if self.params.get("_skip_shop"):
            return None, 0, [], False

        available = MAX_NINJA_SLOTS - len(owned_ninjas)
        max_spend = self.calc_budget(gold)

        if max_spend < 3:
            return None, 0, [], False

        exclude = owned_ids(owned_ninjas)
        shop_pool = shop_override if shop_override else get_random_ninjas(SHOP_NINJA_COUNT, exclude)

        strategy_name = self.pick_strategy(owned_ninjas, shop_pool)

        # 第1次购买
        bought = self.pick_from_shop(shop_pool, strategy_name, max_spend, owned_ninjas, gold)
        did_refresh = False

        if bought is not None:
            return bought, bought["cost"], shop_pool, False

        # 刷新
        if self.should_refresh(gold, False, shop_pool, strategy_name):
            refresh_cost = SHOP_REFRESH_COST
            if gold >= max_spend + refresh_cost:
                shop_pool2 = get_random_ninjas(SHOP_NINJA_COUNT, exclude)
                bought2 = self.pick_from_shop(shop_pool2, strategy_name, max_spend, owned_ninjas, gold)
                did_refresh = True
                if bought2 is not None:
                    return bought2, bought2["cost"], shop_pool2, True

        return None, 0, shop_pool, did_refresh

    # ── 辅助方法 ──

    def _priority(self, effect):
        """简化版优先级评分"""
        from sim_config import classify_priority
        return classify_priority(effect)

    def _filter_economy(self, shop_pool, max_spend):
        """过滤出经济类忍者"""
        econ_ids = ["n_061", "n_113", "n_114", "n_115", "n_151", "n_152"]
        econ_names = ["金剛力", "喜鹊", "龙之眼", "黄金律", "福神", "利息之印"]
        return [
            n for n in shop_pool
            if n["cost"] <= max_spend and
            (n["id"] in econ_ids or n["name"] in econ_names)
        ]

    def describe(self):
        """返回人格描述字符串（用于日志/报告）"""
        return f"{self.p['group_icon']} {self.p['group']}·{self.p['name']}"
