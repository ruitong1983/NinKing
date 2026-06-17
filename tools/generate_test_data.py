#!/usr/bin/env python3
"""
NinKing 忍者牌测试数据批量生成器
产出: docs/ninking/testing/ninja-test-all.csv (UTF-8 BOM)
"""

import csv
import os

# ══════════════════════════════════════════
# 基础定义 - 匹配 CardData.gd
# ══════════════════════════════════════════

RANK_VALUES = {
    '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14
}
RANK_CHIPS = {2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,10:10,11:10,12:10,13:10,14:11}
SUITS = ['♠','♥','♦','♣']
SUIT_TIE = {'♠':4, '♥':3, '♦':2, '♣':1}

HAND_TYPES = {
    0: '散牌', 1: '对子', 2: '顺子', 3: '同花', 4: '同花顺', 5: '豹子'
}
HAND_CHIPS = {0:5, 1:10, 2:20, 3:30, 4:50, 5:100}
HAND_MULT = {0:1, 1:2, 2:3, 3:4, 4:5, 5:8}
COL_X_MULT = {0:1, 1:2, 2:4, 3:8, 4:16, 5:32}

XI_GLOBAL_NAMES = ['全黑', '全红', '全顺', '全同花', '四张', '全三条']

# ══════════════════════════════════════════
# 工具函数
# ══════════════════════════════════════════

def parse_card(s):
    """'♠A' → (suit, rank_int, rank_name)"""
    s = s.strip()
    suit = s[0]
    rank_str = s[1:]
    rank = RANK_VALUES[rank_str]
    return (suit, rank, rank_str)

def card_chips(card):
    _, rank, _ = card
    return RANK_CHIPS[rank]

def group_card_chips(cards):
    return sum(card_chips(c) for c in cards)

def is_flush(cards):
    s1, s2, s3 = cards[0][0], cards[1][0], cards[2][0]
    return s1 == s2 == s3

def is_straight(ranks):
    r = sorted(ranks)
    if r[1] == r[0]+1 and r[2] == r[1]+1:
        return True
    if r[0] == 2 and r[1] == 3 and r[2] == 14:
        return True
    return False

def count_ranks(ranks):
    c = {}
    for r in ranks:
        c[r] = c.get(r,0)+1
    return c

def evaluate_group(cards):
    """返回 (hand_type_code, hand_strength)"""
    ranked = sorted(cards, key=lambda c: c[1])
    ranks = [c[1] for c in ranked]
    suits = [c[0] for c in cards]
    flush = is_flush(cards)
    straight = is_straight(ranks)
    rcounts = count_ranks(ranks)

    if 3 in rcounts.values():
        ht = 5  # 豹子
    elif flush and straight:
        ht = 4  # 同花顺
    elif flush:
        ht = 3  # 同花
    elif straight:
        ht = 2  # 顺子
    elif 2 in rcounts.values():
        ht = 1  # 对子
    else:
        ht = 0  # 散牌

    # strength = hand_type * 100 + high_rank * 10 + mid_rank + suit_tiebreak
    high_suit = suits[-1]
    str_val = ht * 100 + ranks[2] * 10 + ranks[1] + SUIT_TIE.get(high_suit, 1)
    return ht, str_val

def evaluate_column(cards):
    """3张垂直牌(c0,c1,c2)"""
    return evaluate_group(cards)[0]

def detect_xi(head, mid, tail, he, me, te):
    """返回 triggered xi names list"""
    all_c = head + mid + tail
    ht, mt, tt = he[0], me[0], te[0]
    triggered = []

    # 全黑
    if all(c[0] in '♠♣' for c in all_c):
        triggered.append('全黑')
    # 全红
    if all(c[0] in '♥♦' for c in all_c):
        triggered.append('全红')
    # 全顺
    all_ranks = sorted(c[1] for c in all_c)
    is_dragon = all(all_ranks[i] == all_ranks[i-1]+1 for i in range(1,9))
    is_bicycle = sorted(all_ranks[:6]+[all_ranks[6]-13,all_ranks[7]-13,all_ranks[8]-13])
    # Simple check: 9 consecutive includes wrap-around(A-2 case)
    if is_dragon:
        triggered.append('全顺')
    # 全同花
    if all(c[0] == all_c[0][0] for c in all_c):
        triggered.append('全同花')
    # 四张
    rank_counts = {}
    for c in all_c:
        rank_counts[c[1]] = rank_counts.get(c[1],0)+1
    if any(v >= 4 for v in rank_counts.values()):
        triggered.append('四张')
    # 三清
    if is_flush(head) and is_flush(mid) and is_flush(tail):
        triggered.append('三清')
    # 三顺清
    if me[0] == 4 and te[0] == 4:
        if he[0] == 4:
            triggered.append('三顺清')
        # else not all 3
    # 顺清打头
    if ht == 4:
        triggered.append('顺清打头')
    # 全三条
    if all(v == 3 for v in rank_counts.values()):
        triggered.append('全三条')
    return triggered

def get_col_evals(head, mid, tail):
    col0 = [head[0], mid[0], tail[0]]
    col1 = [head[1], mid[1], tail[1]]
    col2 = [head[2], mid[2], tail[2]]
    return [evaluate_column(col0), evaluate_column(col1), evaluate_column(col2)]

# ══════════════════════════════════════════
# 计分引擎
# ══════════════════════════════════════════

def calc_score(head_cards, mid_cards, tail_cards, ninja_effects=None, star_chart=None):
    """
    ninja_effects: {
        'h': {'chips':0, 'mult':0, 'x':[]},
        'm': {...},
        't': {...}
    }
    """
    if ninja_effects is None:
        ninja_effects = {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}}
    if star_chart is None:
        star_chart = {}

    he = evaluate_group(head_cards)
    me = evaluate_group(mid_cards)
    te = evaluate_group(tail_cards)
    ht, mt, tt = he[0], me[0], te[0]

    # Per-group score
    def group_score(cards, ht_code, ne):
        cc = group_card_chips(cards)
        hc = HAND_CHIPS[ht_code]
        hm = HAND_MULT[ht_code]
        chips = cc + hc + ne['chips']
        mult = hm + ne['mult']
        x_prod = 1
        for x in ne['x']:
            x_prod *= x
        return chips * mult * x_prod, cc, hc, hm, chips, mult

    hs, hcc, hhc, hhm, hct, hmt = group_score(head_cards, ht, ninja_effects['h'])
    ms, mcc, mhc, mhm, mct, mmt = group_score(mid_cards, mt, ninja_effects['m'])
    ts, tcc, thc, thm, tct, tmt = group_score(tail_cards, tt, ninja_effects['t'])

    total_raw = hs + ms + ts

    # Column ×mult
    col_evals = get_col_evals(head_cards, mid_cards, tail_cards)  # returns ht codes (not tuples)
    # Actually let me fix this - get_col_evals was returning column hand type codes
    col0_cards = [head_cards[0], mid_cards[0], tail_cards[0]]
    col1_cards = [head_cards[1], mid_cards[1], tail_cards[1]]
    col2_cards = [head_cards[2], mid_cards[2], tail_cards[2]]
    col_types = [evaluate_column(col0_cards), evaluate_column(col1_cards), evaluate_column(col2_cards)]

    col_x_prod = 1
    col_str_parts = []
    for ct in col_types:
        x = COL_X_MULT[ct]
        if x > 1:
            col_x_prod *= x
            col_str_parts.append(str(x))
    col_str = ','.join(col_str_parts)

    # Xi detection
    xi_triggered = detect_xi(head_cards, mid_cards, tail_cards, he, me, te)
    xi_x_prod = 1
    xi_global_x = {'全黑':2, '全红':2, '全顺':2, '全同花':3, '四张':5, '全三条':4}
    for xi in xi_triggered:
        if xi in xi_global_x:
            xi_x_prod *= xi_global_x[xi]

    # Group-level xi (三清, 三顺清, 顺清打头) affect per-group score
    # These are applied to total_raw before column/global xi
    if '三清' in xi_triggered:
        hs *= 2; ms *= 2; ts *= 2
    if '三顺清' in xi_triggered:
        hs *= 3; ms *= 3; ts *= 3
    if '顺清打头' in xi_triggered and ht == 4:  # 顺清打头 only applies to head
        hs *= 2

    total_raw = hs + ms + ts

    final = max(total_raw, 1)
    for x in col_str_parts:
        final *= int(x)
    for xi in xi_triggered:
        if xi in xi_global_x:
            final *= xi_global_x[xi]

    return {
        'h_score': hs, 'm_score': ms, 't_score': ts,
        'h_cc': hcc, 'h_hc': hhc, 'h_ct': hct, 'h_hm': hhm, 'h_mt': hmt,
        'm_cc': mcc, 'm_hc': mhc, 'm_ct': mct, 'm_hm': mhm, 'm_mt': mmt,
        't_cc': tcc, 't_hc': thc, 't_ct': tct, 't_hm': thm, 't_mt': tmt,
        'total_raw': total_raw,
        'col_x_prod': col_x_prod,
        'col_str': col_str,
        'xi_x_prod': xi_x_prod,
        'xi_triggered': ','.join(xi_triggered),
        'final': final,
        'h_type': ht, 'm_type': mt, 't_type': tt,
        'col_types': col_types,
    }


# ══════════════════════════════════════════
# 牌组工具
# ══════════════════════════════════════════

def card_str(suit, rank_name):
    return suit + rank_name

def make_cards(head, mid, tail):
    """Parse string tuples into card tuples"""
    h = [parse_card(c) for c in head]
    m = [parse_card(c) for c in mid]
    t = [parse_card(c) for c in tail]
    return h, m, t

def format_cards(cards):
    return ' '.join(c[0]+str(RANK_VALUES[c[1]] if c[1]>=11 else str(c[1]) if c[1]<=10 else '')
                    for c in cards)
# Actually, simpler: just pass the input strings through

# ══════════════════════════════════════════
# 测试用例定义 - 每张忍者的 cards + effects
# ══════════════════════════════════════════

def ninja_chips_effect(val):
    return {'h':{'chips':val,'mult':0,'x':[]}, 'm':{'chips':val,'mult':0,'x':[]}, 't':{'chips':val,'mult':0,'x':[]}}

def ninja_mult_effect(val):
    return {'h':{'chips':0,'mult':val,'x':[]}, 'm':{'chips':0,'mult':val,'x':[]}, 't':{'chips':0,'mult':val,'x':[]}}

def ninja_head_mult_effect(val):
    return {'h':{'chips':0,'mult':val,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}}

def ninja_tail_x_effect(val):
    return {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[val]}}


# ══════════════════════════════════════════
# CSV 输出
# ══════════════════════════════════════════

CSV_HEADER = [
    'version','card_id','card_name','test_no','test_desc',
    'h1','h2','h3','m1','m2','m3','t1','t2','t3',
    'h_type','m_type','t_type','h_tc','m_tc','t_tc',
    'c0_type','c1_type','c2_type','col_str','xi_str','triggered',
    'nc_h_c','nc_h_m','nc_h_x','nc_m_c','nc_m_m','nc_m_x','nc_t_c','nc_t_m','nc_t_x',
    'h_card_chips','h_hand_chips','h_chips_total','h_hand_mult','h_mult_total','h_score',
    'm_card_chips','m_hand_chips','m_chips_total','m_hand_mult','m_mult_total','m_score',
    't_card_chips','t_hand_chips','t_chips_total','t_hand_mult','t_mult_total','t_score',
    'total_raw','col_x_prod','xi_x_prod','final_score'
]

HT_NAMES = {0:'散牌',1:'对子',2:'顺子',3:'同花',4:'同花顺',5:'豹子'}

def make_row(ver, cid, cname, tno, desc, head_strs, mid_strs, tail_strs, result, ne, triggered):
    row = {
        'version': ver, 'card_id': cid, 'card_name': cname,
        'test_no': tno, 'test_desc': desc,
        'h1': head_strs[0], 'h2': head_strs[1], 'h3': head_strs[2],
        'm1': mid_strs[0], 'm2': mid_strs[1], 'm3': mid_strs[2],
        't1': tail_strs[0], 't2': tail_strs[1], 't3': tail_strs[2],
        'h_type': HT_NAMES[result['h_type']], 'm_type': HT_NAMES[result['m_type']], 't_type': HT_NAMES[result['t_type']],
        'h_tc': result['h_type'], 'm_tc': result['m_type'], 't_tc': result['t_type'],
        'c0_type': HT_NAMES[result['col_types'][0]], 'c1_type': HT_NAMES[result['col_types'][1]], 'c2_type': HT_NAMES[result['col_types'][2]],
        'col_str': result['col_str'], 'xi_str': result['xi_triggered'],
        'triggered': 'true' if triggered else 'false',
        'nc_h_c': ne['h']['chips'], 'nc_h_m': ne['h']['mult'], 'nc_h_x': ','.join(str(x) for x in ne['h']['x']) if ne['h']['x'] else '1',
        'nc_m_c': ne['m']['chips'], 'nc_m_m': ne['m']['mult'], 'nc_m_x': ','.join(str(x) for x in ne['m']['x']) if ne['m']['x'] else '1',
        'nc_t_c': ne['t']['chips'], 'nc_t_m': ne['t']['mult'], 'nc_t_x': ','.join(str(x) for x in ne['t']['x']) if ne['t']['x'] else '1',
        'h_card_chips': result['h_cc'], 'h_hand_chips': result['h_hc'], 'h_chips_total': result['h_ct'],
        'h_hand_mult': result['h_hm'], 'h_mult_total': result['h_mt'], 'h_score': result['h_score'],
        'm_card_chips': result['m_cc'], 'm_hand_chips': result['m_hc'], 'm_chips_total': result['m_ct'],
        'm_hand_mult': result['m_hm'], 'm_mult_total': result['m_mt'], 'm_score': result['m_score'],
        't_card_chips': result['t_cc'], 't_hand_chips': result['t_hc'], 't_chips_total': result['t_ct'],
        't_hand_mult': result['t_hm'], 't_mult_total': result['t_mt'], 't_score': result['t_score'],
        'total_raw': result['total_raw'], 'col_x_prod': result['col_x_prod'],
        'xi_x_prod': result['xi_x_prod'], 'final_score': result['final'],
    }
    return row


# ══════════════════════════════════════════
# 生成全部测试数据
# ══════════════════════════════════════════

ROWS = []

def add_baseline_and_ninja(cid, cname, tno, desc, head_strs, mid_strs, tail_strs, ne, triggered=True):
    h,m,t = make_cards(head_strs, mid_strs, tail_strs)

    # No ninja baseline
    ne_none = {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}}
    r0 = calc_score(h,m,t)
    ROWS.append(make_row('baseline', cid, cname, tno, desc+'无忍', head_strs, mid_strs, tail_strs, r0, ne_none, False))

    # With ninja
    r1 = calc_score(h,m,t, ne)
    ROWS.append(make_row('with_ninja', cid, cname, tno, desc, head_strs, mid_strs, tail_strs, r1, ne, triggered))
    delta = r1['final'] - r0['final']
    if delta != 0:
        ROWS.append(make_row('comment', cid, cname, tno, f'Δ={delta}', head_strs, mid_strs, tail_strs, r1, ne, triggered))


# ══════════════════════════════════════════
# 测试牌组设计
# ══════════════════════════════════════════

# ===== Batch 1: 无条件通用 (n_001~n_006) =====

# n_001 手里剑 +10chips — 使用样稿已确认数据
add_baseline_and_ninja('n_001','手里剑','T1','全散牌列同花16+10chips',
    ['♣5','♠3','♥9'], ['♦6','♣4','♥10'], ['♣2','♦A','♥8'],
    ninja_chips_effect(10))

add_baseline_and_ninja('n_001','手里剑','T2','头散中散尾豹无列分+10chips',
    ['♥5','♦9','♠A'], ['♣4','♠7','♥10'], ['♠J','♥Q','♦K'],
    ninja_chips_effect(10))

# n_002 苦无 +4mult
add_baseline_and_ninja('n_002','苦无','T1','全散牌无列+4mult',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    ninja_mult_effect(4))

add_baseline_and_ninja('n_002','苦无','T2','头豹中顺尾豹列混+4mult',
    ['♠J','♥J','♦J'], ['♠5','♥6','♣7'], ['♠Q','♥Q','♦Q'],
    ninja_mult_effect(4))

# n_003 忍刀 +15chips +2mult
add_baseline_and_ninja('n_003','忍刀','T1','全散牌无列+15c+2m',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    {'h':{'chips':15,'mult':2,'x':[]}, 'm':{'chips':15,'mult':2,'x':[]}, 't':{'chips':15,'mult':2,'x':[]}})

add_baseline_and_ninja('n_003','忍刀','T2','头散中顺尾豹列混+15c+2m',
    ['♠2','♥5','♦9'], ['♠5','♥6','♣7'], ['♠J','♥Q','♦K'],
    {'h':{'chips':15,'mult':2,'x':[]}, 'm':{'chips':15,'mult':2,'x':[]}, 't':{'chips':15,'mult':2,'x':[]}})

# n_004 重刃 +20chips
add_baseline_and_ninja('n_004','重刃','T1','全散牌无列+20chips',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    ninja_chips_effect(20))

add_baseline_and_ninja('n_004','重刃','T2','头豹中顺尾散列豹32+20chips',
    ['♠J','♥J','♦J'], ['♠5','♥6','♣7'], ['♣3','♠6','♥8'],
    ninja_chips_effect(20))

# n_005 影缝 +10mult
add_baseline_and_ninja('n_005','影缝','T1','全散牌无列+10mult',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    ninja_mult_effect(10))

add_baseline_and_ninja('n_005','影缝','T2','头豹中顺尾豹列混+10mult',
    ['♠J','♥J','♦J'], ['♠5','♥6','♣7'], ['♠Q','♥Q','♦Q'],
    ninja_mult_effect(10))

# n_006 奥义之卷 +30chips +10mult
add_baseline_and_ninja('n_006','奥义之卷','T1','全散牌无列+30c+10m',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    {'h':{'chips':30,'mult':10,'x':[]}, 'm':{'chips':30,'mult':10,'x':[]}, 't':{'chips':30,'mult':10,'x':[]}})

add_baseline_and_ninja('n_006','奥义之卷','T2','头豹中散尾顺列豹32+30c+10m',
    ['♠J','♥J','♦J'], ['♣4','♠7','♥10'], ['♠A','♥K','♦Q'],
    {'h':{'chips':30,'mult':10,'x':[]}, 'm':{'chips':30,'mult':10,'x':[]}, 't':{'chips':30,'mult':10,'x':[]}})


# ===== Batch 2: 组别定向 (n_g01~n_g06) =====

# n_g01 虎头 — head ≤ 对子 → +5 mult head
# T1: 头散牌触发 (done in sample)
add_baseline_and_ninja('n_g01','虎头','T1','触发头散牌0小于等于对子1加5mult头',
    ['♠9','♥10','♣Q'], ['♠8','♥8','♣J'], ['♦J','♦Q','♦K'],
    ninja_head_mult_effect(5))

# T2: 头对子边界触发
add_baseline_and_ninja('n_g01','虎头','T2','边界触发头对子1等于对子1',
    ['♠2','♥2','♣5'], ['♠4','♥4','♣8'], ['♦J','♦Q','♦K'],
    ninja_head_mult_effect(5))

# T3: 头顺子不触发
add_baseline_and_ninja('n_g01','虎头','T3','不触发头顺子2大于对子1',
    ['♠2','♥3','♣4'], ['♠5','♥6','♣7'], ['♠J','♥Q','♣K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

# n_g02 龙尾 — tail ≥ 同花顺(4) → ×2 tail
# T1: 尾同花顺触发
add_baseline_and_ninja('n_g02','龙尾','T1','触发尾同花顺4大于等于4尾乘2',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♦J','♦Q','♦K'],
    ninja_tail_x_effect(2))

# T2: 尾豹子触发
add_baseline_and_ninja('n_g02','龙尾','T2','触发尾豹子5大于等于4尾乘2',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♥J','♠J','♦J'],
    ninja_tail_x_effect(2))

# T3: 尾同花不触发
add_baseline_and_ninja('n_g02','龙尾','T3','不触发尾同花3小于4',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♥3','♥6','♥9'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

# n_g03 中流砥柱 — +50 chips mid (targets mid group, always active)
add_baseline_and_ninja('n_g03','中流砥柱','T1','中组+50chips全散牌',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':50,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

add_baseline_and_ninja('n_g03','中流砥柱','T2','中组+50chips头散中同花尾顺',
    ['♠2','♥5','♦9'], ['♠3','♥6','♠8'], ['♠7','♥9','♠A'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':50,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

# n_g04 藏锋 — 头越弱尾越强(散×3 对×2 其余×1)
# Effect: 头散牌→尾×3, 头对子→尾×2
# This needs special handling in the effects dict
add_baseline_and_ninja('n_g04','藏锋','T1','头散牌尾乘3',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♦J','♦Q','♦K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[3]}})

add_baseline_and_ninja('n_g04','藏锋','T2','头对子尾乘2',
    ['♠2','♥2','♣8'], ['♠3','♥6','♦9'], ['♠J','♥Q','♦K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[2]}})

add_baseline_and_ninja('n_g04','藏锋','T3','头顺子尾不变乘1即不触发',
    ['♠2','♥3','♣4'], ['♠5','♥6','♣7'], ['♠J','♥Q','♦K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

# n_g05 双头蛇 — head or mid ≥ 顺子(2) → +40 chips
# If either head or mid is ≥ straight, +40 chips to that group
# Simplified: +40 chips to mid if mid is straight
add_baseline_and_ninja('n_g05','双头蛇','T1','中顺子触发加40chips',
    ['♠2','♥5','♦9'], ['♠5','♥6','♣7'], ['♠J','♥Q','♦K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':40,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

add_baseline_and_ninja('n_g05','双头蛇','T2','头顺子触发加40chips',
    ['♠2','♥3','♣4'], ['♠6','♥8','♦10'], ['♠J','♥Q','♦K'],
    {'h':{'chips':40,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

add_baseline_and_ninja('n_g05','双头蛇','T3','头散中散不触发',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♠J','♥Q','♦K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

# n_g06 金字塔 — strict ascending: 头<中<尾牌型 → ×2
# Need 头牌型 < 中牌型 < 尾牌型: e.g. 散(0)<对子(1)<顺(2)
add_baseline_and_ninja('n_g06','金字塔','T1','严格递增散对子顺触发乘2',
    ['♠2','♥5','♦9'], ['♠3','♥3','♣8'], ['♠J','♥Q','♦K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})
# Wait, 金字塔 is ×2 to all groups, not just tail. It's a global ×2.
# Let me re-check: n_g06 effect is {"x_mult": 2, "condition": {"strict_ascending_types": true}}
# When strict_ascending_types is true, ALL groups get ×2.
# Actually, looking at the code: ninja_affected_groups checks strict_ascending_types separately.
# In collect_ninja_per_group: if strict_ascending is true AND all 3 groups satisfy it, then x_mult=2 applied to all.

# For now, let me just use all_groups ×2 when condition met
n_g06_all = {'h':{'chips':0,'mult':0,'x':[2]}, 'm':{'chips':0,'mult':0,'x':[2]}, 't':{'chips':0,'mult':0,'x':[2]}}

add_baseline_and_ninja('n_g06','金字塔','T1','触发散对对子顺严格递增全组乘2',
    ['♠2','♥5','♦9'], ['♠3','♥3','♣8'], ['♠J','♥Q','♦K'],
    n_g06_all)

add_baseline_and_ninja('n_g06','金字塔','T2','触发散对子同花严格递增',
    ['♠2','♥5','♦9'], ['♠3','♥3','♣8'], ['♠6','♥8','♠A'],
    n_g06_all)

add_baseline_and_ninja('n_g06','金字塔','T3','不触发等同牌型散散散',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♣3','♠6','♥8'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[]}})

# n_r02 均衡之印 — 三组同牌型×2 + 约束改为三组同型
# T1: 三组全部同花(flush=3), ×2 all groups
add_baseline_and_ninja('n_r02','均衡之印','T1','触发三组同花flush全组乘2',
    ['♠2','♠5','♠8'], ['♥3','♥6','♥9'], ['♦4','♦7','♦10'],
    {'h':{'chips':0,'mult':0,'x':[2]}, 'm':{'chips':0,'mult':0,'x':[2]}, 't':{'chips':0,'mult':0,'x':[2]}})

# T2: 三组全部对子
add_baseline_and_ninja('n_r02','均衡之印','T2','触发三组对子全组乘2',
    ['♠2','♥2','♣9'], ['♠3','♦3','♥10'], ['♠J','♥J','♣8'],
    {'h':{'chips':0,'mult':0,'x':[2]}, 'm':{'chips':0,'mult':0,'x':[2]}, 't':{'chips':0,'mult':0,'x':[2]}})

# T3: 三组豹子(三条)
add_baseline_and_ninja('n_r02','均衡之印','T3','触发三组豹子全组乘2',
    ['♠2','♥2','♦2'], ['♠5','♥5','♦5'], ['♠J','♥J','♦J'],
    {'h':{'chips':0,'mult':0,'x':[2]}, 'm':{'chips':0,'mult':0,'x':[2]}, 't':{'chips':0,'mult':0,'x':[2]}})

# n_r03 独尊之印 — 灭×2, 头中≥对子
# T1: 三组全对子, 灭(最强)×2
add_baseline_and_ninja('n_r03','独尊之印','T1','灭乘2头中对子约束满足',
    ['♠2','♥2','♣5'], ['♠3','♦3','♥8'], ['♠J','♥J','♦Q'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[2]}})

# T2: 头散牌中豹尾同花顺, 乘2 only on tail
add_baseline_and_ninja('n_r03','独尊之印','T2','头散中豹尾同花顺尾乘2',
    ['♠2','♥5','♦9'], ['♠5','♥5','♦5'], ['♥J','♥Q','♥K'],
    {'h':{'chips':0,'mult':0,'x':[]}, 'm':{'chips':0,'mult':0,'x':[]}, 't':{'chips':0,'mult':0,'x':[2]}})

# n_t01 火遁 — hand_type=4→+8m (改造: +1出牌→同花顺+倍率)
# T1: 三组同花顺，全部+8m
add_baseline_and_ninja('n_t01','火遁','T1','三组同花顺全+8m',
    ['♠2','♠3','♠4'], ['♠5','♠6','♠7'], ['♠8','♠9','♠10'],
    {'h':{'chips':0,'mult':8,'x':[]}, 'm':{'chips':0,'mult':8,'x':[]}, 't':{'chips':0,'mult':8,'x':[]}})

# n_t05 风遁 — hand_type=1→+3m (改造: 首回合×2→对子+倍率)
# T1: 三组对子，全部+3m
add_baseline_and_ninja('n_t05','风遁','T1','三组对子全+3m',
    ['♠2','♥2','♦5'], ['♠3','♥3','♦7'], ['♠J','♥J','♦9'],
    {'h':{'chips':0,'mult':3,'x':[]}, 'm':{'chips':0,'mult':3,'x':[]}, 't':{'chips':0,'mult':3,'x':[]}})

# n_t06 土遁 — hand_type=3→+5m (改造: 死亡回溯→同花+倍率)
# T1: 三组同花，全部+5m
add_baseline_and_ninja('n_t06','土遁','T1','三组同花全+5m',
    ['♠2','♠5','♠9'], ['♠3','♠7','♠J'], ['♠4','♠8','♠K'],
    {'h':{'chips':0,'mult':5,'x':[]}, 'm':{'chips':0,'mult':5,'x':[]}, 't':{'chips':0,'mult':5,'x':[]}})


# ══════════════════════════════════════════
# 输出 CSV (UTF-8 BOM)
# ══════════════════════════════════════════

OUTPUT = r'E:\01 Code\Godot_v4.6.2\NinKing\docs\ninking\testing\ninja-test-full.csv'

with open(OUTPUT, 'w', newline='', encoding='utf-8-sig') as f:
    writer = csv.DictWriter(f, fieldnames=CSV_HEADER)
    writer.writeheader()
    for row in ROWS:
        # Skip comment rows for clean CSV
        if row['version'] == 'comment':
            continue
        writer.writerow(row)

print(f'Generated {len([r for r in ROWS if r["version"]!="comment"])} rows → {OUTPUT}')

# 验证摘要
print('\n=== 验证摘要 ===')
for r in ROWS:
    if r['version'] == 'comment':
        print(f"  {r['card_id']} {r['card_name']} {r['test_no']}: {r['test_desc']}")
