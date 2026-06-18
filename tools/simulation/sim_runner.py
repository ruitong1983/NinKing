#!/usr/bin/env python3
"""
NinKing 关卡模拟 — 模拟编排器
- 完整结界流程 (8关×3封印)
- 商店随机4张 + 玩家决策
- 金币追踪 + 利息
- 跨关忍者继承
"""
import json
import os

from sim_config import (
    ALL_NINJAS, BARRIER_CONFIG, STRATEGIES, BUDGET_TIERS,
    STARTING_GOLD, MAX_NINJA_SLOTS, INTEREST_PER_5, INTEREST_CAP,
    SHOP_NINJA_COUNT, SHOP_REFRESH_COST, MAX_REFRESH_PER_SHOP,
    get_random_ninjas, owned_ids, matches_strategy, pick_best_ninja,
)
from sim_engine import simulate_one_seal


def calc_interest(gold):
    """计算利息: 每$5得$1, 上限$5"""
    return min(gold // 5 * INTEREST_PER_5, INTEREST_CAP)


# ══════════════════════════════════════════
# 商店决策
# ══════════════════════════════════════════

def player_shop_decision(gold, owned_ninjas, strategy_name, budget_ratio,
                         shop_override=None):
    """
    模拟玩家在商店面对 4 张随机忍者的购买决策.

    流程:
        1. 商店随机出4张 (排除已拥有)
        2. 从4张中筛选策略匹配+买得起
        3. 如有候选 → 按优先级买最好的
        4. 如无候选且有钱 → 刷新一次, 重复筛选
        5. 还买不到 → 存钱走人

    Args:
        shop_override: 可选, 预生成的商店列表 (用于外部追踪显示)

    Returns:
        (购买的忍者 | None, 花费金币, 商店列表, 是否刷新)
    """
    available_slots = MAX_NINJA_SLOTS - len(owned_ninjas)
    if available_slots <= 0:
        return None, 0, [], False

    max_spend = int(gold * budget_ratio)
    if max_spend < 3:
        return None, 0, [], False

    exclude = owned_ids(owned_ninjas)

    # 第1次: 随机出4张(或用外部传入)
    shop_pool = shop_override if shop_override else get_random_ninjas(SHOP_NINJA_COUNT, exclude)
    candidate = _decide_purchase(shop_pool, strategy_name, max_spend)
    did_refresh = False

    # 没买到, 尝试刷新
    if candidate is None and MAX_REFRESH_PER_SHOP > 0:
        refresh_cost = SHOP_REFRESH_COST
        if gold >= max_spend + refresh_cost:
            shop_pool2 = get_random_ninjas(SHOP_NINJA_COUNT, exclude)
            candidate = _decide_purchase(shop_pool2, strategy_name, max_spend)
            did_refresh = True
            if candidate is not None:
                return candidate, candidate["cost"], shop_pool2, True
        if not did_refresh:
            return None, 0, shop_pool, False

    if candidate is None:
        return None, 0, shop_pool, False

    cost = candidate["cost"]
    if cost > max_spend:
        return None, 0, shop_pool, False

    return candidate, cost, shop_pool, did_refresh


def _decide_purchase(shop_pool, strategy_name, max_spend):
    """从店中挑选策略匹配且预算内最好的忍者"""
    candidates = [
        n for n in shop_pool
        if matches_strategy(n, strategy_name) and n["cost"] <= max_spend
    ]
    if not candidates:
        return None
    return pick_best_ninja(candidates)


# ══════════════════════════════════════════
# 单次完整游戏流程
# ══════════════════════════════════════════

def simulate_run(strategy_name, budget_ratio):
    """
    模拟一次完整游戏流程 (结界1→结界8 或 中途失败).

    Returns:
        list of dict: [
            {
                "barrier": 1, "seal": 0, "seal_type": "修羅",
                "target": 300, "score": 4500, "passed": True,
                "gold_before": 8, "gold_after": 12,
                "ninjas_before": 0, "ninjas_after": 1,
                "hands": [2000, 1500, 1000],
                "trigger_rate": 0.0,
            },
            ...
        ]
        如果中途失败, 列表在该关结束.
    """
    gold = STARTING_GOLD
    ninjas = []
    results = []

    for barrier_idx, barrier_seals in enumerate(BARRIER_CONFIG):
        barrier = barrier_idx + 1

        for seal_idx, seal_cfg in enumerate(barrier_seals):
            # ═══ 打关前状态 ═══
            ninjas_before = len(ninjas)
            target = seal_cfg["target"]

            # ═══ 打关 ═══
            seal_result = simulate_one_seal(ninjas, gold)
            score = seal_result["total_score"]
            passed = score >= target

            # ═══ 记录 ═══
            entry = {
                "barrier": barrier,
                "seal": seal_idx,
                "seal_type": seal_cfg["type"],
                "target": target,
                "score": score,
                "passed": passed,
                "gold_before": gold,
                "hands": seal_result["hands"],
                "trigger_rate": seal_result["ninja_eff_rate"],
                "avg_active_ninjas": seal_result["avg_active_ninjas"],
                "ninjas_before": ninjas_before,
                "ninja_names": [n["name"] for n in ninjas],
            }

            if not passed:
                entry["gold_after"] = gold
                entry["ninjas_after"] = len(ninjas)
                results.append(entry)
                break  # 游戏结束

            # ═══ 通关奖励 ═══
            gold += seal_cfg["gold"]
            gold += calc_interest(gold)

            # ═══ 商店 ═══
            bought_ninja, cost, _, _ = player_shop_decision(
                gold, ninjas, strategy_name, budget_ratio
            )

            if bought_ninja is not None:
                gold -= cost
                ninjas.append(bought_ninja)

            entry["gold_after"] = gold
            entry["ninjas_after"] = len(ninjas)
            entry["bought_ninja"] = bought_ninja["name"] if bought_ninja else None
            entry["bought_cost"] = cost
            entry["ninja_names"] = [n["name"] for n in ninjas]

            results.append(entry)

        else:
            continue  # seal loop completed normally → next barrier
        break  # seal loop broke (game over) → stop run

    return results


# ══════════════════════════════════════════
# 批量模拟
# ══════════════════════════════════════════

def batch_simulate(strategies=None, budget_tiers=None, runs=10, output_dir=None):
    """
    批量运行所有策略×预算×次数.

    Args:
        strategies: 策略名列表, 默认全部
        budget_tiers: 预算档位列表, 默认全部
        runs: 每场景模拟次数
        output_dir: JSON输出目录 (None=不输出)
    """
    if strategies is None:
        strategies = list(STRATEGIES.keys())
    if budget_tiers is None:
        budget_tiers = list(BUDGET_TIERS.keys())

    all_scenarios = []

    for strategy in strategies:
        for budget_name in budget_tiers:
            budget_ratio = BUDGET_TIERS[budget_name]

            print(f"\n{'='*60}")
            print(f"模拟: {strategy} / {budget_name} (预算比例={budget_ratio})")
            print(f"{'='*60}")

            scenario_runs = []

            for run_idx in range(runs):
                run_result = simulate_run(strategy, budget_ratio)
                scenario_runs.append(run_result)

                # 进度
                last_barrier = run_result[-1]["barrier"] if run_result else 0
                last_seal = run_result[-1]["seal_type"] if run_result else "?"
                is_fail = not run_result[-1]["passed"] if run_result else True
                status = "FAIL" if is_fail else "PASS"
                print(f"  Run {run_idx+1:2d}/{runs}: {status} "
                      f"到结界{last_barrier}-{last_seal} "
                      f"分数={run_result[-1]['score']:,}")

            # 按 (barrier, seal) 收集统计数据
            stats = _compute_statistics(scenario_runs, runs)

            scenario = {
                "strategy": strategy,
                "budget": budget_name,
                "budget_ratio": budget_ratio,
                "runs": runs,
                "total_seals": 24,
                "seal_stats": stats,
            }

            all_scenarios.append(scenario)

            # 输出 JSON
            if output_dir:
                os.makedirs(output_dir, exist_ok=True)
                fname = f"{strategy}_{budget_name}.json"
                fpath = os.path.join(output_dir, fname)
                with open(fpath, "w", encoding="utf-8") as f:
                    json.dump(scenario, f, ensure_ascii=False, indent=2)
                print(f"  → 输出: {fpath}")

    return all_scenarios


# ══════════════════════════════════════════
# 统计计算
# ══════════════════════════════════════════

def _compute_statistics(scenario_runs, total_runs):
    """
    对每个封印汇总 N 次运行的统计数据.

    Returns:
        list of dict, 每封印一条:
        {
            "barrier": 1, "seal": 0, "seal_type": "修羅",
            "target": 300,
            "pass_count": 8, "pass_rate": 0.8,
            "scores": [4500, 3200, ...],  # 仅通过者的分数
            "p10": ..., "p25": ..., "p50": ..., "p75": ..., "p90": ...,
            "avg_trigger_rate": 0.15,
            "avg_active_ninjas": 1.2,
        }
    """
    # 按 (barrier, seal) 收集所有 run 的数据
    seal_data = {}

    for run_result in scenario_runs:
        for entry in run_result:
            key = (entry["barrier"], entry["seal"])
            if key not in seal_data:
                seal_data[key] = {
                    "barrier": entry["barrier"],
                    "seal": entry["seal"],
                    "seal_type": entry["seal_type"],
                    "target": entry["target"],
                    "scores": [],
                    "pass_count": 0,
                    "trigger_rates": [],
                    "avg_active_list": [],
                }
            sd = seal_data[key]
            sd["scores"].append(entry["score"])
            sd["trigger_rates"].append(entry["trigger_rate"])
            sd["avg_active_list"].append(entry["avg_active_ninjas"])
            if entry["passed"]:
                sd["pass_count"] += 1

    # 计算每个封印的统计量
    stats = []
    for key in sorted(seal_data.keys()):
        sd = seal_data[key]
        scores = sd["scores"]
        scores_sorted = sorted(scores)

        stats.append({
            "barrier": sd["barrier"],
            "seal": sd["seal"],
            "seal_type": sd["seal_type"],
            "target": sd["target"],
            "pass_count": sd["pass_count"],
            "pass_rate": sd["pass_count"] / total_runs,
            "scores": scores,
            "min": min(scores),
            "max": max(scores),
            "p10": _percentile(scores_sorted, 10),
            "p25": _percentile(scores_sorted, 25),
            "p50": _percentile(scores_sorted, 50),
            "p75": _percentile(scores_sorted, 75),
            "p90": _percentile(scores_sorted, 90),
            "avg_trigger_rate": (sum(sd["trigger_rates"]) / len(sd["trigger_rates"])
                                 if sd["trigger_rates"] else 0),
            "avg_active_ninjas": (sum(sd["avg_active_list"]) / len(sd["avg_active_list"])
                                  if sd["avg_active_list"] else 0),
        })

    return stats


def _percentile(sorted_data, p):
    """计算百分位值 (线性插值)"""
    if not sorted_data:
        return 0
    n = len(sorted_data)
    k = (p / 100.0) * (n - 1)
    f = int(k)
    c = k - f
    if f + 1 < n:
        return sorted_data[f] * (1 - c) + sorted_data[f + 1] * c
    else:
        return sorted_data[f]


# ══════════════════════════════════════════
# 入口
# ══════════════════════════════════════════

if __name__ == "__main__":
    import sys

    # 默认: 跑所有策略, each 10 runs
    runs = 10
    if len(sys.argv) > 1:
        runs = int(sys.argv[1])

    output_dir = os.path.join(os.path.dirname(__file__), "..", "..",
                              "docs", "ninking", "08-testing", "data")
    output_dir = os.path.normpath(output_dir)

    print(f"NinKing 关卡模拟 v2")
    print(f"策略: {list(STRATEGIES.keys())}")
    print(f"预算档: {list(BUDGET_TIERS.keys())}")
    print(f"每场景 {runs} 次运行")
    print(f"输出: {output_dir}")
    print()

    batch_simulate(runs=runs, output_dir=output_dir)
