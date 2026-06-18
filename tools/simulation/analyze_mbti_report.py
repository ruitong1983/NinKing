#!/usr/bin/env python3
"""
NinKing MBTI 模拟分析器 — 输出结构化 JSON 报告文档。

读取 data_personality/ 下的模拟结果 JSON，运行多维分析，输出
结构化 JSON 报告文档（含 findings / suggestions / strategy_meta / economy 等）。
该 JSON 可被 render_mbti_html.py 消费生成可视化 HTML。

用法:
    python analyze_mbti_report.py                             # 输出 JSON 到 reports/
    python analyze_mbti_report.py --output data.json           # 指定输出路径
    python analyze_mbti_report.py --render                     # 输出 JSON 后自动渲染 HTML
"""
import json
import os
import sys
import glob
import subprocess
from datetime import datetime
from collections import defaultdict

# ── 常量 ──
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DATA_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..",
                 "docs", "ninking", "08-testing", "data_personality")
)
REPORTS_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..",
                 "docs", "ninking", "08-testing", "reports")
)

B8_TARGET = {8: {2: 210000}}

# ── 游戏数据（从 sim_config 提取关键常量）──
ALL_NINJAS = [
    {"id": "n_001", "name": "手里剑", "cost": 4, "hand_type": 1},
    {"id": "n_002", "name": "苦无", "cost": 5, "hand_type": 2},
    {"id": "n_003", "name": "忍刀", "cost": 7, "hand_type": 3},
    {"id": "n_004", "name": "重刃", "cost": 10, "hand_type": 4},
    {"id": "n_005", "name": "影缝", "cost": 12, "hand_type": 5},
    {"id": "n_051", "name": "并蒂", "cost": 5, "hand_type": 1},
    {"id": "n_055", "name": "流觞", "cost": 6, "hand_type": 2},
    {"id": "n_056", "name": "贯月", "cost": 10, "hand_type": 4},
    {"id": "n_057", "name": "鼎立", "cost": 13, "hand_type": 5},
    {"id": "n_104", "name": "风遁", "cost": 6, "hand_type": 1},
    {"id": "n_105", "name": "水遁", "cost": 9, "hand_type": 2},
    {"id": "n_106", "name": "土遁", "cost": 12, "hand_type": 3},
    {"id": "n_107", "name": "火遁", "cost": 14, "hand_type": 4},
    {"id": "n_108", "name": "雷遁", "cost": 16, "hand_type": 5},
    {"id": "n_110", "name": "闪光", "cost": 8, "hand_type": 1},
    {"id": "n_111", "name": "流光", "cost": 12, "hand_type": 2},
    {"id": "n_112", "name": "极光", "cost": 16, "hand_type": 3},
    {"id": "n_061", "name": "金刚力", "cost": 8},
    {"id": "n_115", "name": "黄金律", "cost": 14},
    {"id": "n_151", "name": "福神", "cost": 6},
    {"id": "n_152", "name": "利息之印", "cost": 7},
]

HAND_TYPE_NAMES = {1: "对子", 2: "顺子", 3: "同花", 4: "同花顺", 5: "豹子"}
HAND_TYPE_BASE_MULT = {1: 2, 2: 3, 3: 4, 4: 5, 5: 8}
HAND_TYPE_BASE_CHIPS = {1: 10, 2: 20, 3: 30, 4: 50, 5: 100}

# ── 辅助 ──

def load_personality_params():
    """加载 mbti_strategies.json 中各人格的策略参数"""
    strategies_path = os.path.join(SCRIPT_DIR, "mbti_strategies.json")
    if not os.path.isfile(strategies_path):
        return {}
    with open(strategies_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    mapping = {}
    for mbti_type in data.get("mbti_types", []):
        for vk, variant in mbti_type.get("variants", {}).items():
            pname = variant.get("name", "")
            params = variant.get("params", {})
            mapping[pname] = {
                "strategy_lock": params.get("strategy_lock"),
                "budget_ratio": params.get("budget_ratio", 0.5),
                "refresh_behavior": params.get("refresh_behavior", "never"),
                "group": mbti_type.get("group", ""),
            }

    for bl in data.get("test_baselines", []):
        mapping[bl.get("name", "")] = {
            "strategy_lock": bl.get("params", {}).get("strategy_lock"),
            "budget_ratio": bl.get("params", {}).get("budget_ratio", 0.5),
            "refresh_behavior": bl.get("params", {}).get("refresh_behavior", "never"),
            "group": "混沌型",
        }
    return mapping


# ── 数据加载 ──

def load_results(data_dir):
    """加载 data_personality/ 下所有 JSON 结果"""
    files = sorted(glob.glob(os.path.join(data_dir, "*.json")))
    if not files:
        print(f"⚠️  目录中没有 JSON 文件: {data_dir}")
        return []
    results = []
    for f in files:
        with open(f, "r", encoding="utf-8") as fh:
            d = json.load(fh)
        stats = d.get("seal_stats", [])
        runs = d["runs"]

        b8_stats = [s for s in stats if s["barrier"] == 8 and s["seal"] == 2]
        b8_pass_rate = round(b8_stats[0]["pass_rate"] * 100, 1) if b8_stats else 0
        b8_p50 = b8_stats[0]["p50"] if b8_stats else 0
        b8_min = b8_stats[0]["min"] if b8_stats else 0
        b8_max = b8_stats[0]["max"] if b8_stats else 0

        max_barrier = max((s["barrier"] for s in stats if s["pass_count"] > 0), default=0)
        avg_trigger = round(
            sum(s["avg_trigger_rate"] for s in stats) / len(stats) * 100, 1
        ) if stats else 0
        avg_active = round(
            sum(s["avg_active_ninjas"] for s in stats) / len(stats), 1
        ) if stats else 0
        seal_count = len(stats)

        barrier_pass = {}
        for b in range(1, 9):
            b_stats = [s for s in stats if s["barrier"] == b]
            if b_stats:
                b_pass = min(100.0, max(s["pass_rate"] * 100 for s in b_stats))
                barrier_pass[str(b)] = round(b_pass, 1)
            else:
                barrier_pass[str(b)] = 0

        results.append({
            "group": d["personality_group"],
            "name": d["personality_name"],
            "icon": d.get("personality_icon", ""),
            "runs": runs,
            "b8_pass_rate": b8_pass_rate,
            "b8_p50": b8_p50,
            "b8_min": b8_min,
            "b8_max": b8_max,
            "max_barrier": max_barrier,
            "avg_trigger": avg_trigger,
            "avg_active": avg_active,
            "seal_count": seal_count,
            "barrier_pass": barrier_pass,
            "description": d.get("personality_description", ""),
        })

    return results


# ── 分析函数 ──

def analyze_balance(results):
    """分析平衡性，返回按严重程度排序的发现列表"""
    findings = []

    groups = defaultdict(list)
    for r in results:
        groups[r["group"]].append(r)

    for gname, items in sorted(groups.items()):
        icon = items[0]["icon"]
        avg_b8 = sum(i["b8_pass_rate"] for i in items) / len(items)
        b8_wins = sum(1 for i in items if i["b8_pass_rate"] > 0)
        max_b = max(i["max_barrier"] for i in items)
        best = max(items, key=lambda i: i["b8_pass_rate"])
        worst = min(items, key=lambda i: i["b8_pass_rate"])

        if avg_b8 >= 30:
            rating, severity = "🟢", "normal"
        elif avg_b8 >= 10:
            rating, severity = "🟡", "warning"
        elif avg_b8 > 0:
            rating, severity = "🟠", "weak"
        else:
            rating, severity = "🔴", "critical"

        findings.append({
            "group": gname, "icon": icon, "avg_b8": round(avg_b8, 1),
            "b8_wins": b8_wins, "total": len(items), "max_barrier": max_b,
            "best_name": best["name"], "best_rate": best["b8_pass_rate"],
            "worst_name": worst["name"], "worst_rate": worst["b8_pass_rate"],
            "rating": rating, "severity": severity,
        })

    for r in sorted(results, key=lambda r: -r["b8_pass_rate"]):
        if r["b8_pass_rate"] >= 50:
            findings.append({
                "type": "individual", "rating": "🟣", "severity": "op",
                "msg": f"{r['icon']} {r['name']} B8通关率 {r['b8_pass_rate']}% — 可能超模",
            })

    for r in sorted(results, key=lambda r: r["b8_pass_rate"]):
        if r["b8_pass_rate"] == 0 and r["max_barrier"] <= 2:
            findings.append({
                "type": "individual", "rating": "🔴", "severity": "critical",
                "msg": f"{r['icon']} {r['name']} 从未突破B2 — 严重过弱",
            })

    return findings


def analyze_inflation(results):
    """分析数值膨胀"""
    b8_scores = [r for r in results if r["b8_p50"] > 0]
    if not b8_scores:
        return None

    b8_min = min(r["b8_p50"] for r in b8_scores)
    b8_max = max(r["b8_p50"] for r in b8_scores)
    b8_avg = sum(r["b8_p50"] for r in b8_scores) / len(b8_scores)
    target = B8_TARGET[8][2]

    inflations = []
    for r in b8_scores:
        ratio = r["b8_p50"] / target if target > 0 else 0
        if ratio < 10:
            level = "正常"
        elif ratio < 100:
            level = "关注"
        elif ratio < 1000:
            level = "明显膨胀"
        else:
            level = "严重膨胀"
        inflations.append({**r, "ratio": round(ratio, 1), "level": level})

    inflations.sort(key=lambda x: -x["ratio"])

    return {
        "target": target, "min_score": b8_min, "max_score": b8_max,
        "avg_score": round(b8_avg),
        "gap_ratio": round(b8_max / b8_min, 1) if b8_min > 0 else float('inf'),
        "count": len(b8_scores), "details": inflations,
    }


def analyze_barrier_dropoff(results):
    """检测结界过渡滑坡（通过率骤降 >=50% 的点）"""
    n = len(results)
    if n == 0:
        return []

    barrier_rates = {b: [] for b in range(1, 9)}
    for r in results:
        for b in range(1, 9):
            barrier_rates[b].append(r["barrier_pass"].get(str(b), 0))

    avg_rates = {}
    for b in range(1, 9):
        vals = [v for v in barrier_rates[b] if v > 0]
        avg_rates[b] = round(sum(vals) / len(vals), 1) if vals else 0

    threshold_suggestions = {
        2: "B1→B2 通过率滑坡 {drop}%，建议 B2-修罗目标从 40K→35K，或 B1 夜叉→B2 修罗过渡提高金币奖励",
        3: "B2→B3 通过率滑坡 {drop}%，建议 B3-修罗目标从 60K→50K",
        4: "B3→B4 通过率滑坡 {drop}%，建议 B4 三封印目标各下调 10K",
        5: "B4→B5 通过率滑坡 {drop}%，建议 B5-修罗目标从 150K→130K",
        6: "B5→B6 通过率滑坡 {drop}%，建议 B6+ 奖励递增（如修罗 5g/明王 8g/夜叉 12g）",
        7: "B6→B7 通过率滑坡 {drop}%，建议检查 B7 阈值是否过高",
        8: "B7→B8 通过率滑坡 {drop}%，B8 终局可接受较大滑坡，但至少保留一条路线可达",
    }

    dropoffs = []
    for b in range(2, 9):
        prev, curr = avg_rates[b - 1], avg_rates[b]
        drop_pct = round((prev - curr) / prev * 100, 1) if prev > 0 else 0
        if drop_pct >= 50:
            tpl = threshold_suggestions.get(b, "通过率滑坡 {drop}%，需关注")
            dropoffs.append({
                "stage": f"B{b-1}→B{b}", "prev_rate": prev, "curr_rate": curr,
                "drop_pct": drop_pct,
                "suggestion": tpl.format(drop=drop_pct),
            })
    return dropoffs


def analyze_strategy_meta(results, params_map):
    """
    按 strategy_lock + 人格组 分组统计 B8 率。
    返回两个维度的数据：纯流派分析 + 人格组对比。
    """
    pure_strategy = defaultdict(list)
    group_perf = defaultdict(list)

    for r in results:
        pinfo = params_map.get(r["name"], {})
        locks = pinfo.get("strategy_lock")
        pgroup = pinfo.get("group", r["group"])
        group_perf[pgroup].append(r)
        if locks is not None and len(locks) == 1:
            pure_strategy[locks[0]].append(r)

    ht_cards = defaultdict(list)
    for n in ALL_NINJAS:
        ht = n.get("hand_type")
        if ht:
            ht_cards[ht].append(n)

    meta = []

    # 纯流派
    for sname in ["对子流", "顺子流", "同花流", "同花顺流", "豹子流"]:
        items = pure_strategy.get(sname)
        if not items:
            continue
        b8_rates = [i["b8_pass_rate"] for i in items]
        avg_b8 = round(sum(b8_rates) / len(b8_rates), 1)
        b8_wins = sum(1 for v in b8_rates if v > 0)
        max_b = max(i["max_barrier"] for i in items)

        ht_val = {"对子流": 1, "顺子流": 2, "同花流": 3, "同花顺流": 4, "豹子流": 5}[sname]
        key_cards = ht_cards.get(ht_val, [])
        min_cost = min(c["cost"] for c in key_cards) if key_cards else 0
        max_cost = max(c["cost"] for c in key_cards) if key_cards else 0

        meta.append({
            "sgroup": f"纯{sname}", "count": len(items),
            "avg_b8": avg_b8, "b8_wins": b8_wins, "max_barrier": max_b,
            "base_mult": HAND_TYPE_BASE_MULT[ht_val],
            "base_chips": HAND_TYPE_BASE_CHIPS[ht_val],
            "min_cost": min_cost, "max_cost": max_cost, "type": "strategy_lock",
        })

    # 人格组对比
    GAME_STRATEGY_MAP = {
        "稳妥型": "低牌型构筑（对子/顺子为主）",
        "理财型": "经济引擎流", "赌狗型": "高牌型构筑（同花顺/豹子）",
        "灵活型": "灵活切换流", "收集型": "填坑覆盖流",
        "感性型": "情感驱动流", "混沌型": "基线随机",
    }
    for gname in ["稳妥型", "理财型", "赌狗型", "灵活型", "收集型", "感性型", "混沌型"]:
        items = group_perf.get(gname)
        if not items:
            continue
        b8_rates = [i["b8_pass_rate"] for i in items]
        avg_b8 = round(sum(b8_rates) / len(b8_rates), 1)
        b8_wins = sum(1 for v in b8_rates if v > 0)
        max_b = max(i["max_barrier"] for i in items)
        icon = items[0]["icon"]

        meta.append({
            "sgroup": gname, "icon": icon, "count": len(items),
            "avg_b8": avg_b8, "b8_wins": b8_wins, "max_barrier": max_b,
            "game_strategy": GAME_STRATEGY_MAP.get(gname, ""),
            "type": "personality_group",
            "members": [
                {"name": i["name"], "b8_pass_rate": i["b8_pass_rate"],
                 "max_barrier": i["max_barrier"]}
                for i in sorted(items, key=lambda x: -x["b8_pass_rate"])
            ],
        })

    return meta


def analyze_economy_balance(results, params_map):
    """按 budget_ratio 分档对比 B8 率"""
    bands = {"低消费 (<0.5)": [], "中消费 (0.5-0.75)": [], "高消费 (≥0.75)": []}

    for r in results:
        pinfo = params_map.get(r["name"], {})
        br = pinfo.get("budget_ratio", 0.5)
        if br < 0.5:
            band = "低消费 (<0.5)"
        elif br < 0.75:
            band = "中消费 (0.5-0.75)"
        else:
            band = "高消费 (≥0.75)"
        bands[band].append(r)

    economy = []
    for band_name, items in bands.items():
        if not items:
            continue
        b8_rates = [i["b8_pass_rate"] for i in items]
        triggers = [i["avg_trigger"] for i in items]
        avg_b8 = round(sum(b8_rates) / len(b8_rates), 1)
        avg_trig = round(sum(triggers) / len(triggers), 1) if triggers else 0
        max_b = max(i["max_barrier"] for i in items)

        economy.append({
            "band": band_name, "count": len(items),
            "avg_b8": avg_b8, "avg_trigger": avg_trig, "max_barrier": max_b,
            "items": [
                {"name": i["name"], "b8_pass_rate": i["b8_pass_rate"],
                 "max_barrier": i["max_barrier"]}
                for i in sorted(items, key=lambda x: -x["b8_pass_rate"])
            ],
        })

    return economy


# ── 建议生成 ──

def categorize_suggestion(target, suggestion, priority, category, evidence, source):
    return {
        "target": target, "suggestion": suggestion, "priority": priority,
        "category": category, "evidence": evidence, "source": source,
    }


def generate_suggestions(findings, inflation, barrier_dropoffs, strategy_meta, economy_analysis):
    """生成分类整理的游戏机制调整建议"""
    suggestions = []

    # ── 🔧 机制 — 流派平衡 ──
    for sm in strategy_meta:
        if sm.get("type") != "strategy_lock":
            continue
        sname = sm["sgroup"]
        if sm["count"] < 2:
            continue
        if sm["avg_b8"] == 0 and sm["max_barrier"] <= 3:
            if "纯豹子流" in sname:
                suggestions.append(categorize_suggestion(
                    "豹子流严重过弱",
                    "提高豹子基础手牌倍率 8→12，或降低关键忍者费用（影缝 12→8、鼎立 13→9、雷遁 16→12）",
                    "high", "机制",
                    f"豹子流派 {sm['count']} 个亚型平均 B8 率 0%，最高仅到 B{sm['max_barrier']}，"
                    f"核心卡费用区间 {sm['min_cost']}~{sm['max_cost']}g",
                    "analyze_strategy_meta"))
            elif "纯同花顺流" in sname:
                suggestions.append(categorize_suggestion(
                    "同花顺流难以成行",
                    "提高同花顺基础倍率 5→6，或降低核心卡费用（重刃 10→7、贯月 10→7、火遁 14→12）",
                    "high", "机制",
                    f"同花顺流派 {sm['count']} 个亚型平均 B8 率 {sm['avg_b8']}%，核心卡 {sm['min_cost']}~{sm['max_cost']}g",
                    "analyze_strategy_meta"))
            elif "纯同花流" in sname:
                suggestions.append(categorize_suggestion(
                    "同花流派偏弱", "提高同花基础倍率 4→5，或降低忍刀 7→5、震荡 8→6、土遁 12→10",
                    "medium", "机制", f"同花流平均 B8 率 {sm['avg_b8']}%", "analyze_strategy_meta"))
            elif "纯顺子流" in sname:
                suggestions.append(categorize_suggestion(
                    "顺子流派偏弱", "提高顺子基础倍率 3→4，或降低水遁 9→7、流光 12→10",
                    "medium", "机制", f"顺子流平均 B8 率 {sm['avg_b8']}%", "analyze_strategy_meta"))

    for sm in strategy_meta:
        if sm.get("type") != "strategy_lock":
            continue
        if "纯对子流" in sm["sgroup"] and sm["avg_b8"] >= 15:
            suggestions.append(categorize_suggestion(
                "对子流过于强势",
                f"关注对子流主导环境：纯对子锁定型平均 B8 率 {sm['avg_b8']}%。"
                "可考虑降低并蒂(+2 mult)到 +1、风遁(x2)改为 x1.5、或提高核心卡费用（手里剑 4→5、并蒂 5→6）",
                "medium", "机制",
                f"对子流 {sm['count']} 型平均 B8 {sm['avg_b8']}%，核心卡 {sm['min_cost']}~{sm['max_cost']}g",
                "analyze_strategy_meta"))

    # 人格组建议
    for sm in strategy_meta:
        if sm.get("type") != "personality_group":
            continue
        gname = sm["sgroup"]
        if gname == "赌狗型" and sm["avg_b8"] < 10:
            suggestions.append(categorize_suggestion(
                "赌狗型整体过弱",
                f"赌狗型 {sm['count']} 亚型平均 B8 率仅 {sm['avg_b8']}%。"
                "建议降低高牌型忍者费用，或增强「倍率X·组定向」忍者的适用性",
                "high", "机制",
                f"赌狗型仅 {sm['b8_wins']} 型有 B8 记录，最高 B{sm['max_barrier']}",
                "analyze_strategy_meta"))
        if gname == "理财型" and sm["avg_b8"] < 15:
            suggestions.append(categorize_suggestion(
                "理财型纯经济路线收益不足",
                f"理财型 {sm['count']} 亚型平均 B8 率 {sm['avg_b8']}%。"
                "建议增加经济→战力转化类忍者，或提高利息上限",
                "medium", "机制",
                f"理财型最高 B{sm['max_barrier']}，利息上限 5g/轮",
                "analyze_strategy_meta"))
        if gname == "稳妥型" and sm["avg_b8"] >= 20:
            suggestions.append(categorize_suggestion(
                "稳妥型整体过强",
                f"稳妥型 {sm['count']} 亚型平均 B8 率 {sm['avg_b8']}%。"
                "低牌型构筑明显优于高牌型路线，高稀有度路线设计需加强",
                "medium", "机制",
                f"稳妥型 {sm['b8_wins']}/{sm['count']} 亚型有 B8 记录",
                "analyze_strategy_meta"))

    # ── ⚖️ 数值 — 卡牌效果 ──
    suggestions.append(categorize_suggestion(
        "金刚力 vs 黄金律 性价比失衡",
        "金刚力(8g)需 50 金满 10 mult，黄金律(14g) 45 金即 x8。"
        "建议金刚力 cap 从 10 降到 5（每 3 金+1 mult），或改为无上限线性增长",
        "medium", "数值",
        "金刚力(cost=8, 每5金+1全行列mult, cap=10); 黄金律(cost=14, 每15金x2, cap=x8)",
        "analyze_economy_balance"))

    suggestions.append(categorize_suggestion(
        "喜鹊(4g)性价比过高",
        "喜鹊仅需 4g 就让全局喜倍率+1，配合三清(x2+1=x3)或全同花(x3+1=x4)效果显著。"
        "建议喜鹊费用 4→6，或改为每触发 2 个喜才 +1",
        "medium", "数值",
        "喜鹊是第 2 便宜的忍者(4g)，无触发条件，全局性效果", "sim_config"))

    suggestions.append(categorize_suggestion(
        "Phase E 喜倍率偏高",
        "三等(x5)、满堂(x5)、背水(x4)、贫打(x4) 等喜配合全同花(x3)+喜鹊(+1)形成 x4~x6 叠加。"
        "建议三等从 x5 降为 x4，满堂从 x5 降为 x4",
        "medium", "数值",
        "三等+全同花+喜鹊叠加可达 ×20 以上", "analyze_inflation"))

    # ── 💰 价格 — 忍者费用 ──
    high_cost_cards = [n for n in ALL_NINJAS if n["cost"] >= 14]
    hc_names = "、".join(f"「{c['name']}」({c['cost']}g)" for c in high_cost_cards)
    suggestions.append(categorize_suggestion(
        "高稀有度构筑路线总成本过高",
        f"当前核心卡最高费用：{hc_names}。初始金币仅 8g，利息上限 5g/轮。"
        "玩家在 B6 前几乎不可能累积足够金币购买 14g+ 忍者。"
        "建议降低豹子/同花顺路线关键卡费用 2~4g，或 B5+ 结界奖励递增",
        "high", "价格",
        "最贵卡牌：雷遁 16g、龙之眼 18g、极光 16g、鼎立 13g、收官 14g、火遁 14g、黄金律 14g",
        "analyze_strategy_meta"))

    # ── 🎁 奖励 — 结界奖励/利息 ──
    suggestions.append(categorize_suggestion(
        "结界奖励不随关数递增",
        "B1-B8 奖励完全相同：修罗 3g/明王 5g/夜叉 8g。后期缺乏经济追赶机制。"
        "建议 B5+ 递增：B5-B6 修罗 5g/明王 8g/夜叉 12g，B7-B8 修罗 8g/明王 12g/夜叉 18g",
        "high", "奖励",
        "当前奖励恒定为 3/5/8g，利息上限 5g/轮", "analyze_economy_balance"))

    suggestions.append(categorize_suggestion(
        "利息上限限制经济型玩法",
        "利息上限 5g/轮，持有 25g 后不再增长。利息之印(7g)提至 10g 但回收周期长。"
        "建议利息上限从 5→8（默认），持有 40g 饱和",
        "medium", "奖励",
        "INTEREST_CAP=5, INTEREST_PER_5=1。利息之印提升至 10g", "sim_config"))

    # ── 🎯 阈值 — 结界过渡 ──
    for dd in barrier_dropoffs:
        suggestions.append(categorize_suggestion(
            f"结界过渡过陡：{dd['stage']}",
            dd["suggestion"], "low", "阈值",
            f"通过率从 {dd['prev_rate']}% 降至 {dd['curr_rate']}%，滑坡 {dd['drop_pct']}%",
            "analyze_barrier_dropoff"))

    # ── 从 findings 补充 ──
    for f in findings:
        if f.get("severity") == "critical" and f.get("type") == "individual":
            name_part = f["msg"].split(" ")[1] if len(f["msg"].split()) > 1 else f["msg"]
            suggestions.append(categorize_suggestion(
                f"{name_part} 严重过弱",
                "检查该人格的 strategy_lock 是否锁定了过弱的牌型，或 budget_ratio 是否过低",
                "medium", "机制", f["msg"], "analyze_balance"))
        elif f.get("severity") == "op":
            suggestions.append(categorize_suggestion(
                f"{f['msg'].split(' ')[1] if len(f['msg'].split()) > 1 else '某型'} 可能过强",
                "关注该人格的策略组合是否无意中优化了某个强力构筑，需考虑 nerf",
                "low", "机制", f["msg"], "analyze_balance"))

    if inflation and inflation["gap_ratio"] > 100:
        suggestions.append(categorize_suggestion(
            f"得分差距过大（最高/最低={inflation['gap_ratio']}x）",
            "检查是否因「全同花(x3)+喜鹊(+1)+三等(x5)」叠加导致极端分数。"
            "建议全同花 x3→x2，或限制同花喜与 Phase E 喜的叠加",
            "high", "数值",
            f"B8 P50 得分范围 {inflation['min_score']:,} ~ {inflation['max_score']:,}",
            "analyze_inflation"))

    suggestions.append(categorize_suggestion(
        "B1-B3 前期体验保障",
        "确保 B1 ≥ 80%、B2 ≥ 50%、B3 ≥ 30% 通过率。"
        "混沌型(全随机基线)三型均 0% 通过 B2，说明基础散牌(5 chips×1 mult)分数太低",
        "low", "阈值",
        "混沌型三型全部在 B2 前失败", "generate_suggestions"))

    priority_order = {"high": 0, "medium": 1, "low": 2}
    suggestions.sort(key=lambda s: priority_order.get(s["priority"], 99))
    return suggestions


def extract_at_pairs(results):
    """从结果中提取 A/T 配对数据"""
    at_pairs = {}
    for r in results:
        name = r["name"]
        parts = name.rsplit("·", 1)
        if len(parts) == 2 and parts[1] in (
                "务实", "求稳", "笃定", "谨慎", "高效", "焦虑", "稳健", "操心",
                "远见", "疑虑", "笃行", "游移", "铁律", "心慌",
                "自信", "焦躁", "专注", "燃烧", "洒脱", "疯狂",
                "从容", "急切", "敏捷", "贪婪",
                "坚定", "焦虑", "从容", "操心", "自在", "纠结", "乐天", "狂热"):
            prefix = parts[0]
            if prefix not in at_pairs:
                at_pairs[prefix] = {}
            variant = "T" if parts[1] in (
                "求稳", "谨慎", "焦虑", "操心", "疑虑", "游移", "心慌",
                "焦躁", "燃烧", "疯狂", "急切", "贪婪", "纠结", "狂热") else "A"
            at_pairs[prefix][variant] = r

    at_rows = []
    for prefix, pair in sorted(at_pairs.items()):
        a, t = pair.get("A"), pair.get("T")
        if a and t:
            diff = round(t["b8_pass_rate"] - a["b8_pass_rate"], 1)
            at_rows.append({
                "name": prefix, "icon": a["icon"],
                "a_b8": a["b8_pass_rate"], "t_b8": t["b8_pass_rate"],
                "diff": diff, "a_trig": a["avg_trigger"], "t_trig": t["avg_trigger"],
            })
    return at_rows


# ── 报告数据生成 ──

def generate_report_data(data_dir=None):
    """
    运行全部分析，返回结构化报告字典。

    Args:
        data_dir: 数据目录（默认 data_personality）

    Returns:
        结构化 dict，可直接序列化为 JSON
    """
    if data_dir is None:
        data_dir = DEFAULT_DATA_DIR
    if not os.path.isdir(data_dir):
        print(f"❌ 数据目录不存在: {data_dir}")
        return None

    now = datetime.now()
    timestamp = now.strftime("%Y-%m-%d %H:%M:%S")
    timestamp_file = now.strftime("%Y%m%d_%H%M%S")

    print(f"📊 NinKing MBTI 数据分析器")
    print(f"   数据源: {data_dir}")
    print(f"   时间戳: {timestamp}")

    results = load_results(data_dir)
    if not results:
        print("❌ 无模拟数据，请先运行 sim_runner_personality.py")
        return None
    print(f"   加载 {len(results)} 型模拟结果")

    params_map = load_personality_params()
    print(f"   加载 {len(params_map)} 型策略参数")

    findings = analyze_balance(results)
    inflation = analyze_inflation(results)
    barrier_dropoffs = analyze_barrier_dropoff(results)
    strategy_meta = analyze_strategy_meta(results, params_map)
    economy = analyze_economy_balance(results, params_map)
    suggestions = generate_suggestions(findings, inflation, barrier_dropoffs, strategy_meta, economy)
    at_pairs = extract_at_pairs(results)

    print(f"   发现 {len(findings)} 条平衡性问题, {len(barrier_dropoffs)} 处结界过渡陡峭")
    print(f"   策略分组: {len(strategy_meta)} 组, 经济分档: {len(economy)} 档")
    print(f"   生成 {len(suggestions)} 条游戏机制调整建议")

    return {
        "meta": {
            "timestamp": timestamp,
            "timestamp_file": timestamp_file,
            "num_types": len(results),
            "runs_per_type": results[0]["runs"] if results else 0,
        },
        "results": results,
        "findings": findings,
        "inflation": inflation,
        "barrier_dropoffs": barrier_dropoffs,
        "strategy_meta": strategy_meta,
        "economy_analysis": economy,
        "suggestions": suggestions,
        "at_pairs": at_pairs,
    }


def save_report_json(report_data, output_path=None):
    """将结构化报告数据保存为 JSON 文件"""
    if output_path is None:
        os.makedirs(REPORTS_DIR, exist_ok=True)
        ts = report_data["meta"]["timestamp_file"]
        output_path = os.path.join(REPORTS_DIR, f"mbti_report_data_{ts}.json")

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(report_data, f, ensure_ascii=False, indent=2)

    print(f"✅ 报告数据已保存: {output_path}")
    print(f"   大小: {os.path.getsize(output_path):,} bytes")
    return output_path


# ── CLI ──

def main():
    import argparse
    parser = argparse.ArgumentParser(description="NinKing MBTI 模拟数据分析器")
    parser.add_argument("--input", type=str, default=None,
                        help=f"数据目录（默认: {DEFAULT_DATA_DIR}）")
    parser.add_argument("--output", type=str, default=None,
                        help="JSON 报告输出路径（默认: reports/mbti_report_data_*.json）")
    parser.add_argument("--render", action="store_true",
                        help="输出 JSON 后自动调用 render_mbti_html.py 生成 HTML")
    args = parser.parse_args()

    report_data = generate_report_data(args.input)
    if report_data is None:
        sys.exit(1)

    json_path = save_report_json(report_data, args.output)

    if args.render:
        render_script = os.path.join(SCRIPT_DIR, "render_mbti_html.py")
        if os.path.isfile(render_script):
            print(f"   → 自动调用 render_mbti_html.py 渲染 HTML...")
            subprocess.run([sys.executable, render_script, "--input", json_path])
        else:
            print(f"   ⚠️  render_mbti_html.py 未找到: {render_script}")

    return json_path


if __name__ == "__main__":
    main()
