#!/usr/bin/env python3
"""
NinKing 关卡模拟 — 人格驱动版（MBTI 32 型 · 策略外置）

从 player_personality 加载人格定义（mbti_strategies.json），
模拟不同性格玩家的闯关过程。

用法:
    py tools/simulation/sim_runner_personality.py
    py tools/simulation/sim_runner_personality.py --personality "ISTJ-A"
    py tools/simulation/sim_runner_personality.py --group 感性型
    py tools/simulation/sim_runner_personality.py --all
"""
import json
import os
import sys
import random
import glob

from sim_config import (
    ALL_NINJAS, BARRIER_CONFIG, STARTING_GOLD, MAX_NINJA_SLOTS,
    INTEREST_PER_5, INTEREST_CAP,
)
from sim_engine import simulate_one_seal
from player_personality import (
    PersonalityEngine, get_all_personalities, get_personality_by_name,
    get_personalities_by_group, get_groups,
)


def calc_interest(gold):
    return min(gold // 5 * INTEREST_PER_5, INTEREST_CAP)


def simulate_run(personality):
    """
    用指定人格模拟一次完整游戏流程。

    Returns:
        list[dict]: 每封印一条记录
    """
    engine = PersonalityEngine(personality)
    gold = STARTING_GOLD
    ninjas = []
    results = []

    for barrier_idx, barrier_seals in enumerate(BARRIER_CONFIG):
        barrier = barrier_idx + 1

        for seal_idx, seal_cfg in enumerate(barrier_seals):
            ninjas_before = len(ninjas)
            target = seal_cfg["target"]

            # 打关
            seal_result = simulate_one_seal(ninjas, gold)
            score = seal_result["total_score"]
            passed = score >= target

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
                break

            # 通关奖励
            gold += seal_cfg["gold"]
            gold += calc_interest(gold)

            # 商店决策（人格驱动）
            bought_ninja, cost, _, _ = engine.shop_decision(gold, ninjas)

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
            continue
        break

    return results


def compute_statistics(scenario_runs, total_runs):
    """对每个封印汇总统计数据"""
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

    stats = []
    for key in sorted(seal_data.keys()):
        sd = seal_data[key]
        scores = sorted(sd["scores"])

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
            "p10": _percentile(scores, 10),
            "p25": _percentile(scores, 25),
            "p50": _percentile(scores, 50),
            "p75": _percentile(scores, 75),
            "p90": _percentile(scores, 90),
            "avg_trigger_rate": (sum(sd["trigger_rates"]) / len(sd["trigger_rates"])
                                 if sd["trigger_rates"] else 0),
            "avg_active_ninjas": (sum(sd["avg_active_list"]) / len(sd["avg_active_list"])
                                  if sd["avg_active_list"] else 0),
        })

    return stats


def _percentile(sorted_data, p):
    if not sorted_data:
        return 0
    n = len(sorted_data)
    k = (p / 100.0) * (n - 1)
    f = int(k)
    c = k - f
    if f + 1 < n:
        return sorted_data[f] * (1 - c) + sorted_data[f + 1] * c
    return sorted_data[f]


def batch_simulate(personalities, runs=10, output_dir=None, tag=""):
    """批量模拟多个人格"""
    all_scenarios = []

    for p in personalities:
        engine = PersonalityEngine(p)
        label = f"{p['group']}·{p['name']}"

        print(f"\n{'='*60}")
        print(f"模拟: {engine.describe()} ({tag})")
        print(f"{'='*60}")

        scenario_runs = []

        for run_idx in range(runs):
            run_result = simulate_run(p)
            scenario_runs.append(run_result)

            last = run_result[-1] if run_result else {}
            last_b = last.get("barrier", 0)
            last_st = last.get("seal_type", "?")
            status = "PASS" if last.get("passed") else "FAIL"
            print(f"  Run {run_idx+1:2d}/{runs}: {status} "
                  f"到结界{last_b}-{last_st} "
                  f"分数={last.get('score', 0):,}")

        stats = compute_statistics(scenario_runs, runs)

        scenario = {
            "personality_group": p["group"],
            "personality_name": p["name"],
            "personality_icon": p.get("group_icon", ""),
            "personality_description": p["description"],
            "runs": runs,
            "seal_stats": stats,
        }

        all_scenarios.append(scenario)

        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
            safe_name = f"{p['group']}_{p['name']}".replace("·", "_")
            fname = f"{safe_name}_{tag}.json" if tag else f"{safe_name}.json"
            fpath = os.path.join(output_dir, fname)
            with open(fpath, "w", encoding="utf-8") as f:
                json.dump(scenario, f, ensure_ascii=False, indent=2)
            print(f"  → {fpath}")

    return all_scenarios


def print_summary(all_scenarios):
    """打印汇总"""
    print(f"\n\n{'='*60}")
    print("人格模拟汇总")
    print(f"{'='*60}")
    for sc in all_scenarios:
        stats = sc["seal_stats"]
        b8_pass = sum(1 for s in stats if s["barrier"] == 8 and s["seal"] == 2 and s["pass_count"] > 0)
        max_barrier = max((s["barrier"] for s in stats if s["pass_count"] > 0), default=0)
        avg_trigger = sum(s["avg_trigger_rate"] for s in stats) / len(stats) if stats else 0
        icon = sc.get("personality_icon", "")
        name = f"{sc['personality_group']}·{sc['personality_name']}"
        print(f"  {icon} {name:20s} | B8通关: {b8_pass}/{sc['runs']} | "
              f"最高结界: B{max_barrier} | 触发率: {avg_trigger:.0%}")


# ══════════════════════════════════════════
# 入口
# ══════════════════════════════════════════

def main():
    import argparse

    parser = argparse.ArgumentParser(description="NinKing 人格驱动模拟")
    parser.add_argument("--all", action="store_true", help="跑所有35种人格 (32 MBTI-A/T + 3 测试基线)")
    parser.add_argument("--group", type=str, help="指定人格组 (稳妥型/理财型/赌狗型/灵活型/收集型/感性型/混沌型)")
    parser.add_argument("--personality", type=str, help="指定亚型名称 (如 '纯对子·务实' 或 'ISTJ-A')")
    parser.add_argument("--runs", type=int, default=10, help="每场景模拟次数 (默认10)")
    parser.add_argument("--tag", type=str, default="", help="输出文件标签")
    parser.add_argument("--clean", action="store_true", help="运行前清空 data_personality/ 旧数据")
    parser.add_argument("--report", action="store_true", help="模拟完成后自动生成 HTML 报告")
    args = parser.parse_args()

    output_dir = os.path.normpath(
        os.path.join(os.path.dirname(__file__), "..", "..",
                     "docs", "ninking", "08-testing", "data_personality")
    )

    if args.personality:
        p = get_personality_by_name(args.personality)
        if not p:
            print(f"未找到亚型: {args.personality}")
            print(f"可选: {[p['name'] for p in get_all_personalities()]}")
            return
        personalities = [p]
    elif args.group:
        groups = get_groups()
        if args.group not in groups:
            print(f"未找到人格组: {args.group}")
            print(f"可选: {list(groups.keys())}")
            return
        personalities = get_personalities_by_group(args.group)
    elif args.all:
        personalities = get_all_personalities()
    else:
        # 默认：跑一个代表性人格
        personalities = [get_personality_by_name("纯对子·务实")]

    # --clean: 清空旧数据
    if args.clean:
        old_files = glob.glob(os.path.join(output_dir, "*.json"))
        if old_files:
            print(f"清理 {len(old_files)} 个旧数据文件...")
            for f in old_files:
                os.remove(f)
        else:
            print("无旧数据需要清理")

    print(f"NinKing 人格模拟 v2 (MBTI 32型 · 策略外置)")
    print(f"人格数: {len(personalities)}")
    print(f"每场景 {args.runs} 次运行")
    print(f"输出: {output_dir}")
    print()

    results = batch_simulate(personalities, runs=args.runs,
                              output_dir=output_dir, tag=args.tag)
    print_summary(results)

    # --report: 自动生成 HTML 报告
    if args.report:
        try:
            from generate_mbti_report import generate_report
            report_path = generate_report(output_dir)
            if report_path:
                print(f"\n📊 报告已生成: {report_path}")
                import webbrowser
                webbrowser.open(f"file://{os.path.abspath(report_path)}")
        except ImportError as e:
            print(f"\n⚠️ 报告生成器未找到: {e}")
            print("   请确保 generate_mbti_report.py / analyze_mbti_report.py 在同一目录下")


if __name__ == "__main__":
    main()
