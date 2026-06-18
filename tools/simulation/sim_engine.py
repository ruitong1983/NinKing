#!/usr/bin/env python3
"""
NinKing 关卡模拟 — 扩展计分引擎
- 牌评估 & 喜检测 (含 Phase E)
- 完整忍者效果路由 (条件/组/列/经济)
- 排列枚举 & 最优选择
- 单关 3 手模拟
"""
import random
import math
from itertools import combinations

# ══════════════════════════════════════════
# 牌值定义
# ══════════════════════════════════════════

RANK_VAL = {'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8,'9':9,'10':10,'J':11,'Q':12,'K':13,'A':14}
RANK_CHIP = {2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,10:10,11:10,12:10,13:10,14:11}
H_CHIPS = {0:0, 1:10, 2:20, 3:30, 4:50, 5:100}
H_MULT = {0:1, 1:2, 2:3, 3:4, 4:5, 5:8}
# 手牌类型名称
HT_NAMES = {0:'散牌',1:'对子',2:'顺子',3:'同花',4:'同花顺',5:'豹子'}

# 喜定义
XI_GLOBAL = {  # 全局喜: 最终分数乘积
    '全黑': 2, '全红': 2, '全顺': 2, '全同花': 3, '四张': 5, '全三条': 4,
}
XI_GROUP_MULT = {  # 组级喜: 倍率乘算
    '三清': 2, '三顺清': 3, '顺清打头': 2, '豹子': 2,
}
XI_PHASE_E = {  # Phase E 喜
    '昇龍': 3, '背水': 4, '貧打': 4, '陣眼': 3, '均爵': 3, '三等': 5, '满堂': 5,
}
XI_HE = {  # 合系列 (互斥)
    '三合': 6, '双合': 4, '一合': 2,
}

SUIT_SYMBOLS = {'S':'♠','H':'♥','D':'♦','C':'♣'}
SUIT_VALS = {'♠':0,'♥':1,'♦':2,'♣':3}

# ══════════════════════════════════════════
# 牌工具
# ══════════════════════════════════════════

def create_standard_deck():
    """生成标准52张牌, 每张牌为 (suit_symbol, rank_int)"""
    suits = ['♠','♥','♦','♣']
    ranks = [2,3,4,5,6,7,8,9,10,11,12,13,14]
    deck = []
    for s in suits:
        for r in ranks:
            deck.append((s, r))
    return deck

def card_chip(card):
    return RANK_CHIP[card[1]]

def group_chips(cards):
    return sum(card_chip(c) for c in cards)

def is_flush(cards):
    return len({c[0] for c in cards}) == 1

# ══════════════════════════════════════════
# 牌型评估
# ══════════════════════════════════════════

def eval_group(cards):
    """评估3张牌, 返回 (hand_type, strength)"""
    r = sorted([c[1] for c in cards])
    flush = is_flush(cards)
    straight = (r[1]==r[0]+1 and r[2]==r[1]+1) or (r[0]==2 and r[1]==3 and r[2]==14)
    rc = {}
    for v in r:
        rc[v] = rc.get(v, 0) + 1
    if 3 in rc.values():
        ht = 5
    elif flush and straight:
        ht = 4
    elif flush:
        ht = 3
    elif straight:
        ht = 2
    elif 2 in rc.values():
        ht = 1
    else:
        ht = 0
    # strength = 牌型×100 + 最高牌×10 + 次高牌 + 花色tie
    str_val = ht * 100 + r[2] * 10 + r[1] + SUIT_VALS.get(cards[2][0], 0)
    return ht, str_val

def eval_group_fast(cards):
    """简化的牌型评估, 只返回 hand_type (用于快速筛选)"""
    r = sorted([c[1] for c in cards])
    flush = is_flush(cards)
    straight = (r[1]==r[0]+1 and r[2]==r[1]+1) or (r[0]==2 and r[1]==3 and r[2]==14)
    rc = {}
    for v in r:
        rc[v] = rc.get(v, 0) + 1
    if 3 in rc.values():
        return 5
    elif flush and straight:
        return 4
    elif flush:
        return 3
    elif straight:
        return 2
    elif 2 in rc.values():
        return 1
    return 0

def eval_column(cards):
    """列评估, 同 eval_group"""
    return eval_group_fast(cards)

# ══════════════════════════════════════════
# 全量喜检测 (含 Phase E + 合系列)
# ══════════════════════════════════════════

def detect_xi(head, mid, tail, he, me, te):
    """检测所有喜, 返回触发喜名称列表"""
    all_c = head + mid + tail
    ht, mt, tt = he[0], me[0], te[0]
    xi = []

    # 全黑
    if all(c[0] in ('♠','♣') for c in all_c):
        xi.append('全黑')
    # 全红
    if all(c[0] in ('♥','♦') for c in all_c):
        xi.append('全红')
    # 全顺
    ar = sorted(c[1] for c in all_c)
    if all(ar[i] == ar[i-1] + 1 for i in range(1, 9)):
        xi.append('全顺')
    elif ar == [2,3,4,5,6,7,8,9,14]:  # A-2-3-4-5-6-7-8-9 (A=14 low)
        xi.append('全顺')
    # 全同花
    if all(c[0] == all_c[0][0] for c in all_c):
        xi.append('全同花')
    # 四张 (4+张同点数)
    rc = {}
    for c in all_c:
        rc[c[1]] = rc.get(c[1], 0) + 1
    if any(v >= 4 for v in rc.values()):
        xi.append('四张')
    # 三清
    if is_flush(head) and is_flush(mid) and is_flush(tail):
        xi.append('三清')
    # 三顺清
    if ht == 4 and mt == 4 and tt == 4:
        xi.append('三顺清')
    # 顺清打头
    if ht == 4:
        xi.append('顺清打头')
    # 全三条
    if all(v == 3 for v in rc.values()):
        xi.append('全三条')

    # 豹子 (任意组为豹子)
    if ht == 5 or mt == 5 or tt == 5:
        xi.append('豹子')

    # ── Phase E 喜 ──

    # 昇龍: 影<瞬<滅 牌型严格递增
    if ht < mt < tt:
        xi.append('昇龍')

    # 背水: 尾组为散牌
    if tt == 0:
        xi.append('背水')

    # 貧打: 某组精确包含 2-3-5
    for g in (head, mid, tail):
        ranks = sorted(c[1] for c in g)
        if ranks == [2, 3, 5]:
            xi.append('貧打')
            break

    # 陣眼: 瞬组中间张(第5张)为全局最小或最大
    center = mid[1][1]  # mid[1] = 中间牌
    all_ranks = [c[1] for c in all_c]
    if center == min(all_ranks) or center == max(all_ranks):
        xi.append('陣眼')

    # 均爵: 每组至少一张 J/Q/K
    face_ranks = {11, 12, 13}
    if (any(c[1] in face_ranks for c in head)
            and any(c[1] in face_ranks for c in mid)
            and any(c[1] in face_ranks for c in tail)):
        xi.append('均爵')

    # 三等: 三行卡牌筹码和相等
    hs = sum(card_chip(c) for c in head)
    ms = sum(card_chip(c) for c in mid)
    ts = sum(card_chip(c) for c in tail)
    if hs == ms == ts:
        xi.append('三等')

    # 满堂: 3行+3列全部非散牌 (≥ 对子)
    if all(ht > 0 for ht in (he[0], me[0], te[0])):
        cols_ok = True
        for i in range(3):
            col_cards = [head[i], mid[i], tail[i]]
            if eval_group_fast(col_cards) == 0:
                cols_ok = False
                break
        if cols_ok:
            xi.append('满堂')

    # ── 合系列 (互斥, 取最高档) ──
    col_evals = []
    for i in range(3):
        col_cards = [head[i], mid[i], tail[i]]
        col_evals.append(eval_group_fast(col_cards))

    row_types = [ht, mt, tt]
    match_count = 0
    for row_ht in row_types:
        if row_ht == 0:
            continue  # 散牌不计
        if row_ht in col_evals:
            match_count += 1

    if match_count == 3:
        xi.append('三合')
    elif match_count == 2:
        xi.append('双合')
    elif match_count >= 1:
        xi.append('一合')

    return xi

# ══════════════════════════════════════════
# 忍者效果路由
# ══════════════════════════════════════════

def _check_cond(cond, hand_type):
    """检查条件是否匹配"""
    required = cond.get("hand_type", -1)
    if required != -1 and hand_type != required:
        return False
    at_most = cond.get("at_most_hand_type", -1)
    if at_most != -1 and hand_type > at_most:
        return False
    at_least = cond.get("at_least_hand_type", -1)
    if at_least != -1 and hand_type < at_least:
        return False
    return True


def _affected_groups(effect, head_type, mid_type, tail_type):
    """返回受影响的组列表 ['head','mid','tail']"""
    cond = effect.get("condition", {})
    if not cond:
        return []  # 空 = 所有组

    group = cond.get("group", "")

    # 组定向
    if group == "head":
        return ["head"] if _check_cond(cond, head_type) else []
    if group == "mid":
        return ["mid"] if _check_cond(cond, mid_type) else []
    if group == "tail":
        return ["tail"] if _check_cond(cond, tail_type) else []
    if group == "head_or_mid":
        result = []
        if _check_cond(cond, head_type):
            result.append("head")
        if _check_cond(cond, mid_type):
            result.append("mid")
        return result

    # 牌型条件 (无特定组)
    result = []
    if _check_cond(cond, head_type):
        result.append("head")
    if _check_cond(cond, mid_type):
        result.append("mid")
    if _check_cond(cond, tail_type):
        result.append("tail")
    return result


def _apply_economy(effect, gold, target):
    """经济效果: 金剛力/黄金律"""
    applied = False

    mult_step = effect.get("mult_per_gold", 0)
    if mult_step > 0:
        step = effect.get("mult_gold_step", 5)
        cap = effect.get("mult_gold_cap", 0)
        earned = (gold // step) * mult_step
        if cap > 0:
            earned = min(earned, cap)
        if earned > 0:
            target["mult"] += earned
            applied = True

    x_step = effect.get("x_per_gold", 0)
    if x_step > 1:
        step_g = effect.get("x_gold_step", 15)
        cap_x = effect.get("x_gold_cap", 0)
        count = gold // step_g
        if cap_x > 0:
            count = min(count, cap_x)
        for _ in range(count):
            target["x_stack"].append(x_step)
        if count > 0:
            applied = True

    return applied


def _col_matches_cond(cond, col_type):
    """检查列条件是否匹配"""
    required = cond.get("col_hand_type", -1)
    if required != -1 and col_type != required:
        return False
    return True


def route_ninja_effects(owned_ninjas, head_cards, mid_cards, tail_cards,
                        head_type, mid_type, tail_type,
                        col_types, gold):
    """
    将忍者效果路由到行/列累加器.

    Returns:
        row: {'head': {'chips':0,'mult':0,'x_stack':[]}, 'mid': ..., 'tail': ...}
        col: [{'chips':0,'mult':0,'x_stack':[]}, ...]
        xi_bonus: int (喜鹊效果)
        xi_max_stack: bool (龙之眼)
    """
    row = {
        "head": {"chips": 0, "mult": 0, "x_stack": []},
        "mid": {"chips": 0, "mult": 0, "x_stack": []},
        "tail": {"chips": 0, "mult": 0, "x_stack": []},
    }
    col = [
        {"chips": 0, "mult": 0, "x_stack": []},
        {"chips": 0, "mult": 0, "x_stack": []},
        {"chips": 0, "mult": 0, "x_stack": []},
    ]
    xi_bonus = 0
    xi_max_stack = False
    all_cards = head_cards + mid_cards + tail_cards

    for ninja in owned_ninjas:
        eff = ninja.get("effect", {})

        # ── 喜鹊/龙之眼 (全局, 不计入行/列) ──
        if eff.get("xi_x_bonus", 0) > 0:
            xi_bonus += eff["xi_x_bonus"]
            continue
        if eff.get("xi_max_mult_stack", False):
            xi_max_stack = True
            continue

        # ── has_2_and_ace: 9张同时有2和A → ×5 ──
        if eff.get("condition", {}).get("has_2_and_ace", False):
            has_two = any(c[1] == 2 for c in all_cards)
            has_ace = any(c[1] == 14 for c in all_cards)
            if has_two and has_ace:
                xv = eff.get("x_mult", 1)
                if xv > 1:
                    for g in ("head", "mid", "tail"):
                        row[g]["x_stack"].append(xv)
                    for c in col:
                        c["x_stack"].append(xv)
            continue

        # ── pyramid_x3: 牌型递增×3 ──
        if eff.get("pyramid_x3", False):
            row["head"]["x_stack"].append(3)
            if int(mid_type) > int(head_type):
                row["mid"]["x_stack"].append(3)
            if int(tail_type) > int(mid_type):
                row["tail"]["x_stack"].append(3)
            continue

        # ── 经济效果 (对所有组生效) ──
        econ_applied = False
        for g in ("head", "mid", "tail"):
            if _apply_economy(eff, gold, row[g]):
                econ_applied = True
        for c in col:
            _apply_economy(eff, gold, c)

        chips = eff.get("add_chips", 0)
        mult = eff.get("add_mult", 0)
        x_mult = eff.get("x_mult", 1)
        x_stack = eff.get("x_stack", [])
        cond = eff.get("condition", {})

        # ── col_hand_type 条件 (列条件→全行) ──
        col_ht = cond.get("col_hand_type", -1)
        if col_ht != -1:
            # 检查是否有任何一列匹配
            any_col_match = any(_col_matches_cond(cond, ct) for ct in col_types)
            if not any_col_match:
                continue

            # 全行生效
            apply_chips = eff.get("add_chips_to_rows", 0)
            apply_mult = eff.get("add_mult_to_rows", 0)
            apply_x_mult = eff.get("x_mult_to_rows", 1)

            for g in ("head", "mid", "tail"):
                if apply_chips > 0:
                    row[g]["chips"] += apply_chips
                if apply_mult > 0:
                    row[g]["mult"] += apply_mult
                if apply_x_mult > 1:
                    row[g]["x_stack"].append(apply_x_mult)
            continue

        # ── 组定向 / 牌型条件 → 行 ──
        groups = _affected_groups(eff, head_type, mid_type, tail_type)

        # 有group/hand_type条件但没匹配 → 跳过
        has_cond = bool(cond.get("hand_type", -1) != -1
                        or cond.get("group", "") != ""
                        or cond.get("at_least_hand_type", -1) != -1
                        or cond.get("at_most_hand_type", -1) != -1)
        if has_cond and not groups:
            continue

        # 应用到匹配的行
        for g in groups:
            target = row[g]
            target["chips"] += chips
            target["mult"] += mult
            if x_mult > 1:
                target["x_stack"].append(x_mult)
            for xv in x_stack:
                if xv > 1:
                    target["x_stack"].append(xv)

        # 无条件(无条件无group) → 应用到所有行+列
        if not groups and not has_cond and not econ_applied:
            for g in ("head", "mid", "tail"):
                row[g]["chips"] += chips
                row[g]["mult"] += mult
                if x_mult > 1:
                    row[g]["x_stack"].append(x_mult)
                for xv in x_stack:
                    if xv > 1:
                        row[g]["x_stack"].append(xv)
            # 列也应用
            for c in col:
                c["chips"] += chips
                c["mult"] += mult
                if x_mult > 1:
                    c["x_stack"].append(x_mult)
                for xv in x_stack:
                    if xv > 1:
                        c["x_stack"].append(xv)

    # ── 处理列忍者效果 ──
    # (无条件已经在上面处理了, 这里处理条件忍者对列的影响)
    for ninja in owned_ninjas:
        eff = ninja.get("effect", {})
        cond = eff.get("condition", {})

        # 跳过已有条件处理的
        if not cond:
            continue
        if cond.get("col_hand_type", -1) != -1:
            continue

        # group条件 → 跳过列
        if cond.get("group", "") != "":
            continue

        chips = eff.get("add_chips", 0)
        mult = eff.get("add_mult", 0)
        x_mult = eff.get("x_mult", 1)
        x_stack = eff.get("x_stack", [])

        # hand_type条件 → 按列牌型匹配
        if cond.get("hand_type", -1) != -1:
            for i, ct in enumerate(col_types):
                if _check_cond(cond, ct):
                    col[i]["chips"] += chips
                    col[i]["mult"] += mult
                    if x_mult > 1:
                        col[i]["x_stack"].append(x_mult)
                    for xv in x_stack:
                        if xv > 1:
                            col[i]["x_stack"].append(xv)

    return row, col, xi_bonus, xi_max_stack


# ══════════════════════════════════════════
# 核心计分
# ══════════════════════════════════════════

def _score_group(cards, hand_type, ne):
    """计算一组的得分 (chips × mult × x_prod)"""
    cc = group_chips(cards)
    chips = cc + H_CHIPS[hand_type] + ne["chips"]
    mult = H_MULT[hand_type] + ne["mult"]
    xp = 1
    for xv in ne["x_stack"]:
        xp *= xv
    return chips * mult * xp


def calc_full(head_cards, mid_cards, tail_cards, owned_ninjas, gold):
    """
    完整计分 (含忍者效果路由/喜检测/行列加法).

    Returns dict with keys:
        total_raw, final_score, xi_list, xi_x_prod,
        row_scores, col_scores, col_total,
        ninja_triggered: 实际生效的忍者数
    """
    # 评估
    he = eval_group(head_cards)
    me = eval_group(mid_cards)
    te = eval_group(tail_cards)
    hk, mk, tk = he[0], me[0], te[0]

    # 列评估
    col_cards = [
        [head_cards[0], mid_cards[0], tail_cards[0]],
        [head_cards[1], mid_cards[1], tail_cards[1]],
        [head_cards[2], mid_cards[2], tail_cards[2]],
    ]
    col_types = [eval_column(cc) for cc in col_cards]

    # 忍者效果路由
    row_ne, col_ne, xi_bonus, xi_max_stack = route_ninja_effects(
        owned_ninjas, head_cards, mid_cards, tail_cards,
        hk, mk, tk, col_types, gold
    )

    # 行计分
    hs = _score_group(head_cards, hk, row_ne["head"])
    ms = _score_group(mid_cards, mk, row_ne["mid"])
    ts = _score_group(tail_cards, tk, row_ne["tail"])
    row_total = hs + ms + ts

    # 列计分
    col_scores = []
    col_total = 0
    for i in range(3):
        ct = col_types[i]
        if ct == 0:
            col_scores.append(0)
        else:
            cs = _score_group(col_cards[i], ct, col_ne[i])
            col_scores.append(cs)
            col_total += cs

    # 喜检测
    xi_list = detect_xi(head_cards, mid_cards, tail_cards, he, me, te)

    # ── 组级喜: 行+列 ×倍率 ──
    # 三清: 所有行×2, 列×2
    if '三清' in xi_list:
        mult = 2 + xi_bonus
        hs *= mult; ms *= mult; ts *= mult
        col_total = 0
        for i in range(3):
            col_scores[i] *= mult
            col_total += col_scores[i]
    # 三顺清: 所有行×3, 列×3
    if '三顺清' in xi_list:
        mult = 3 + xi_bonus
        hs *= mult; ms *= mult; ts *= mult
        col_total = 0
        for i in range(3):
            col_scores[i] *= mult
            col_total += col_scores[i]
    # 顺清打头: 头组×2
    if '顺清打头' in xi_list:
        mult = 2 + xi_bonus
        hs *= mult

    # 原始总分 (行+列)
    raw_total = hs + ms + ts + col_total

    # ── 全局喜: 最终乘积 ──
    final = max(raw_total, 1)
    xi_glob = [x for x in xi_list if x in XI_GLOBAL]
    xi_glob_phase_e = [x for x in xi_list if x in XI_PHASE_E]
    xi_he_triggered = [x for x in xi_list if x in XI_HE]

    # 全局喜乘积
    xi_x_prod = 1
    if xi_max_stack and xi_glob:
        # 龙之眼: 所有喜按最高倍率
        max_mult = max(XI_GLOBAL[x] + xi_bonus for x in xi_glob)
        xi_x_prod = max_mult
        final *= max_mult
    else:
        for x in xi_glob:
            xm = XI_GLOBAL[x] + xi_bonus
            xi_x_prod *= xm
            final *= xm

    # Phase E 全局喜
    for x in xi_glob_phase_e:
        xm = XI_PHASE_E[x] + xi_bonus
        xi_x_prod *= xm
        final *= xm

    # 合系列 (互斥, 取最高档)
    for x in xi_he_triggered:
        xm = XI_HE[x] + xi_bonus
        xi_x_prod *= xm
        final *= xm

    # 统计实际生效的忍者数
    ninja_triggered = 0
    for ninja in owned_ninjas:
        eff = ninja.get("effect", {})
        cond = eff.get("condition", {})
        # 无条件/经济/列条件 → 总是生效
        if not cond:
            ninja_triggered += 1
        elif cond.get("col_hand_type", -1) != -1:
            if any(_col_matches_cond(cond, ct) for ct in col_types):
                ninja_triggered += 1
        elif cond.get("hand_type", -1) != -1 or cond.get("group", "") != "":
            groups = _affected_groups(eff, hk, mk, tk)
            if groups:
                ninja_triggered += 1
        elif eff.get("mult_per_gold", 0) > 0 or eff.get("x_per_gold", 0) > 0:
            ninja_triggered += 1
        elif eff.get("xi_x_bonus", 0) > 0:
            if xi_list:
                ninja_triggered += 1
        else:
            ninja_triggered += 1

    return {
        "row_scores": (hs, ms, ts),
        "row_total": hs + ms + ts,
        "col_scores": col_scores,
        "col_total": col_total,
        "total_raw": raw_total,
        "final_score": final,
        "xi_list": xi_list,
        "xi_x_prod": xi_x_prod,
        "hand_types": (hk, mk, tk),
        "col_types": col_types,
        "ninja_triggered": ninja_triggered,
        "row_ne": row_ne,
        "col_ne": col_ne,
    }


# ══════════════════════════════════════════
# 排列枚举 & 最优选择
# ══════════════════════════════════════════

def _combinations_of(items, k):
    """C(items, k) 返回所有组合列表"""
    return list(combinations(items, k))


def _array_diff(all_items, subset):
    """all_items 减去 subset 的剩余元素"""
    result = list(all_items)
    for item in subset:
        result.remove(item)
    return result


def find_best_arrangement(cards, owned_ninjas, gold):
    """
    枚举 C(9,3)×C(6,3)=1680 种排列, 找最优合法排列.
    优化: 先用 fast_score 筛 top10, 再精确计分.
    """
    best_score = -1
    best_result = None

    head_combos = _combinations_of(cards, 3)
    for hc in head_combos:
        rem1 = _array_diff(cards, hc)
        mid_combos = _combinations_of(rem1, 3)
        for mc in mid_combos:
            tc = _array_diff(rem1, mc)

            # 快速评估
            hd = list(hc)
            md = list(mc)
            td = list(tc)
            he = eval_group(hd)
            me = eval_group(md)
            te = eval_group(td)

            # 约束: head ≤ mid ≤ tail
            if not (he[1] <= me[1] <= te[1]):
                continue

            # 精确计分
            result = calc_full(hd, md, td, owned_ninjas, gold)
            score = result["final_score"]

            if score > best_score:
                best_score = score
                best_result = {
                    "head": hd, "mid": md, "tail": td,
                    "head_eval": he, "mid_eval": me, "tail_eval": te,
                    "score": score,
                    "result": result,
                }

    return best_result


# ══════════════════════════════════════════
# 单关模拟 (3 手)
# ══════════════════════════════════════════

def simulate_one_seal(owned_ninjas, gold):
    """
    模拟一关的 3 次出牌.

    流程:
        1. 从52张洗牌 → 抽9 → 最优排列计分
        2. 弃9张 → 剩43张抽9 → 最优排列计分
        3. 弃9张 → 剩34张抽9 → 最优排列计分
        4. 总分 = 3手累加

    Returns:
        dict: {total_score, hands: [score_per_hand],
               arrangements: [...], ninja_eff_rate}
    """
    deck = create_standard_deck()
    random.shuffle(deck)

    hand_scores = []
    hand_details = []
    total_triggered = 0

    for hand_idx in range(3):
        hand_cards = deck[:9]
        deck = deck[9:]

        best = find_best_arrangement(hand_cards, owned_ninjas, gold)
        if best is None:
            # 没有合法排列 (理论上不应该发生)
            hand_scores.append(0)
            hand_details.append(None)
            continue

        hand_scores.append(best["score"])
        hand_details.append(best)
        total_triggered += best["result"]["ninja_triggered"]

    total_score = sum(hand_scores)

    # 忍者效率
    total_ninjas = len(owned_ninjas)
    max_possible = total_ninjas * 3  # 3 hands
    trigger_rate = total_triggered / max_possible if max_possible > 0 else 0

    return {
        "total_score": total_score,
        "hands": hand_scores,
        "hand_details": hand_details,
        "ninja_eff_rate": trigger_rate,
        "avg_active_ninjas": total_triggered / 3 if total_ninjas > 0 else 0,
    }


# ══════════════════════════════════════════
# 快速测试入口
# ══════════════════════════════════════════

if __name__ == "__main__":
    # 测试: 无忍者, 1关
    result = simulate_one_seal([], 8)
    print(f"无忍者: 总分={result['total_score']}, 每手={result['hands']}")
    print(f"  忍者效率: {result['ninja_eff_rate']:.1%}")
