#!/usr/bin/env python3
"""
NinKing 计分公式计算引擎 (v5.0)
— 纯 Python 实现，与 GDScript score_calculator.gd 1:1 对应
— 用于测试生成器 gen_test_v2.py 和 gen_multi_test.py 共用
"""

# ════════════════════════════════
# 牌值定义
# ════════════════════════════════

RANK_VAL = {'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8,'9':9,'10':10,'J':11,'Q':12,'K':13,'A':14}
RANK_CHIP = {2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,10:10,11:10,12:10,13:10,14:11}
SUIT_TIE = {'♠':4,'♥':3,'♦':2,'♣':1}
HT_NAMES = {0:'散牌',1:'对子',2:'顺子',3:'同花',4:'同花顺',5:'豹子'}
H_CHIPS = {0:5,1:10,2:20,3:30,4:50,5:100}
H_MULT = {0:1,1:2,2:3,3:4,4:5,5:8}
XI_GLOBAL = {'全黑':2,'全红':2,'全顺':2,'全同花':3,'四张':5,'全三条':4}
XI_GROUP = {'三清':2,'三顺清':3,'顺清打头':2}

CSV_HEADER = [
    'version','card_id','card_name','test_no','test_desc',
    'h1','h2','h3','m1','m2','m3','t1','t2','t3',
    'h_type','m_type','t_type','h_tc','m_tc','t_tc',
    'c0_type','c1_type','c2_type','col_str','xi_str',
    'nc_h_c','nc_h_m','nc_h_x','nc_m_c','nc_m_m','nc_m_x','nc_t_c','nc_t_m','nc_t_x',
    'h_card_chips','h_hand_chips','h_chips_total','h_hand_mult','h_mult_total','h_score',
    'm_card_chips','m_hand_chips','m_chips_total','m_hand_mult','m_mult_total','m_score',
    't_card_chips','t_hand_chips','t_chips_total','t_hand_mult','t_mult_total','t_score',
    'total_raw','col_total','xi_x_prod','final_score'
]


# ════════════════════════════════
# 基础工具
# ════════════════════════════════

def pc(s):
    """Parse card string like '♠2' → (suit, rank_value)"""
    return (s[0], RANK_VAL[s[1:]])

def cchip(c):
    return RANK_CHIP[c[1]]

def gchips(cs):
    return sum(cchip(c) for c in cs)

def is_flush(cs):
    return len({c[0] for c in cs}) == 1


# ════════════════════════════════
# 牌型评估
# ════════════════════════════════

def eval_group(cs):
    """Evaluate 3-card hand type. Returns (hand_type, str_val)."""
    r = sorted([c[1] for c in cs])
    flush = is_flush(cs)
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
    str_val = ht * 100 + r[2] * 10 + r[1] + SUIT_TIE.get(cs[2][0], 1)
    return ht, str_val

def eval_col(cs):
    return eval_group(cs)[0]


# ════════════════════════════════
# 喜检测
# ════════════════════════════════

def detect_xi(h, m, t, he, me, te):
    """Detect all xi patterns from 9-card arrangement."""
    all_c = h + m + t
    ht, mt, tt = he[0], me[0], te[0]
    xi = []
    if all(c[0] in '♠♣' for c in all_c):
        xi.append('全黑')
    if all(c[0] in '♥♦' for c in all_c):
        xi.append('全红')
    ar = sorted(c[1] for c in all_c)
    if all(ar[i] == ar[i-1] + 1 for i in range(1, 9)):
        xi.append('全顺')
    if all(c[0] == all_c[0][0] for c in all_c):
        xi.append('全同花')
    rc = {}
    for c in all_c:
        rc[c[1]] = rc.get(c[1], 0) + 1
    if any(v >= 4 for v in rc.values()):
        xi.append('四张')
    if is_flush(h) and is_flush(m) and is_flush(t):
        xi.append('三清')
    if ht == 4 and mt == 4 and tt == 4:
        xi.append('三顺清')
    if ht == 4:
        xi.append('顺清打头')
    if all(v == 3 for v in rc.values()):
        xi.append('全三条')
    return xi


# ════════════════════════════════
# 核心计分 (v5.0 列加法化)
# ════════════════════════════════

def calc(cs_h, cs_m, cs_t, ne, xi_bonus=0, xi_override=None, duplicate_hand_x2=False):
    """v5.0: 行独立计分 + 列独立计分(chips×mult) → 加法合成 → 全局喜×mult"""
    he = eval_group(cs_h)
    me = eval_group(cs_m)
    te = eval_group(cs_t)
    hk, mk, tk = he[0], me[0], te[0]

    # ── Helper: score one group (row or column) ──
    def gs(cs, tp, ne_g):
        cc = gchips(cs)
        chips = cc + H_CHIPS[tp] + ne_g['c']
        mult = H_MULT[tp] + ne_g['m']
        xp = 1
        for xv in ne_g['x']:
            xp *= xv
        return chips * mult * xp, cc, H_CHIPS[tp], chips, H_MULT[tp], mult

    # ── Row scores ──
    hs, hcc, hhc, hct, hhm, hmt = gs(cs_h, hk, ne['h'])
    ms, mcc, mhc, mct, mhm, mmt = gs(cs_m, mk, ne['m'])
    ts, tcc, thc, tct, thm, tmt = gs(cs_t, tk, ne['t'])

    # ── Column scoring (v5.0) ──
    col_cards = [
        [cs_h[0], cs_m[0], cs_t[0]],
        [cs_h[1], cs_m[1], cs_t[1]],
        [cs_h[2], cs_m[2], cs_t[2]],
    ]

    is_unconditional = (ne['h'] == ne['m'] == ne['t'])

    col_scores = []
    col_total = 0
    c_types = []

    for col_cs in col_cards:
        ct = eval_col(col_cs)
        c_types.append(ct)
        if ct == 0:
            col_scores.append(0)
        else:
            col_ne_g = {'c': 0, 'm': 0, 'x': []}
            if is_unconditional:
                col_ne_g = {'c': ne['h']['c'], 'm': ne['h']['m'], 'x': list(ne['h']['x'])}
            cs_score, _, _, _, _, _ = gs(col_cs, ct, col_ne_g)
            col_scores.append(cs_score)
            col_total += cs_score

    col_str = ','.join(str(s) for s in col_scores)

    # ── Xi detection ──
    xi_list = detect_xi(cs_h, cs_m, cs_t, he, me, te)
    xi_glob = [x for x in xi_list if x in XI_GLOBAL]
    xi_grp = [x for x in xi_list if x in XI_GROUP]
    if xi_override is None:
        xi_override = {}

    # ── Group xi applied to rows AND columns (v5.0) ──
    sq = 2 + xi_bonus
    if '三清' in xi_override:
        sq = xi_override['三清']
    if '三清' in xi_list:
        hs *= sq; ms *= sq; ts *= sq
        col_total = 0
        for j in range(3):
            col_scores[j] *= sq
            col_total += col_scores[j]

    ssq = 3 + xi_bonus
    if '三顺清' in xi_list:
        hs *= ssq; ms *= ssq; ts *= ssq
        col_total = 0
        for j in range(3):
            col_scores[j] *= ssq
            col_total += col_scores[j]

    shq = 2 + xi_bonus
    if '顺清打头' in xi_list:
        hs *= shq

    # ── 双头蛇: 相同牌型计分×2 ──
    if duplicate_hand_x2:
        all_types = [hk, mk, tk] + c_types
        type_count = {}
        for ht_val in all_types:
            type_count[ht_val] = type_count.get(ht_val, 0) + 1
        if type_count.get(hk, 0) >= 2:
            hs *= 2
        if type_count.get(mk, 0) >= 2:
            ms *= 2
        if type_count.get(tk, 0) >= 2:
            ts *= 2
        col_total = 0
        for j in range(3):
            if type_count.get(c_types[j], 0) >= 2 and col_scores[j] > 0:
                col_scores[j] *= 2
            col_total += col_scores[j]

    # ── Total raw (rows + columns) ──
    raw = hs + ms + ts + col_total

    # ── Global xi ──
    final = max(raw, 1)
    for x in xi_glob:
        final *= XI_GLOBAL[x] + xi_bonus

    # ── Global xi ×mult product ──
    xi_x_prod = 1
    for x in xi_glob:
        xi_x_prod *= XI_GLOBAL[x] + xi_bonus

    return {
        'hs': hs, 'ms': ms, 'ts': ts,
        'hcc': hcc, 'hhc': hhc, 'hct': hct, 'hhm': hhm, 'hmt': hmt,
        'h_ninja_chips': ne['h']['c'], 'h_ninja_mult': ne['h']['m'], 'h_ninja_x': ne['h']['x'],
        'mcc': mcc, 'mhc': mhc, 'mct': mct, 'mhm': mhm, 'mmt': mmt,
        'm_ninja_chips': ne['m']['c'], 'm_ninja_mult': ne['m']['m'], 'm_ninja_x': ne['m']['x'],
        'tcc': tcc, 'thc': thc, 'tct': tct, 'thm': thm, 'tmt': tmt,
        't_ninja_chips': ne['t']['c'], 't_ninja_mult': ne['t']['m'], 't_ninja_x': ne['t']['x'],
        'raw': raw, 'col_scores': col_scores, 'col_total': col_total, 'col_str': col_str,
        'xi_list': xi_list, 'xi_glob': xi_glob, 'xi_x_prod': xi_x_prod, 'final': final,
        'ht': hk, 'mt': mk, 'tt': tk,
        'ct0': c_types[0], 'ct1': c_types[1], 'ct2': c_types[2],
    }


# ════════════════════════════════
# Ninja effect builders
# ════════════════════════════════

def no_ninja():
    return {'h': {'c': 0, 'm': 0, 'x': []}, 'm': {'c': 0, 'm': 0, 'x': []}, 't': {'c': 0, 'm': 0, 'x': []}}

def ne_all(c=0, m=0, x=None):
    if x is None:
        x = []
    return {'h': {'c': c, 'm': m, 'x': x}, 'm': {'c': c, 'm': m, 'x': x}, 't': {'c': c, 'm': m, 'x': x}}

def ne_partial(**kwargs):
    base = {'h': {'c': 0, 'm': 0, 'x': []}, 'm': {'c': 0, 'm': 0, 'x': []}, 't': {'c': 0, 'm': 0, 'x': []}}
    for k, v in kwargs.items():
        g = {'c': 0, 'm': 0, 'x': []}
        g.update(v)
        base[k] = g
    return base


# ════════════════════════════════
# CSV row builder
# ════════════════════════════════

def mkrow(ver, cid, cname, tno, desc, hs, ms, ts, r, ne, xi_bonus=0):
    xi_prod = 1
    for x in r['xi_glob']:
        xi_prod *= XI_GLOBAL[x] + xi_bonus
    ne_hc = ne['h']['c']; ne_hm = ne['h']['m']; ne_hx = ne['h']['x']
    ne_mc = ne['m']['c']; ne_mm = ne['m']['m']; ne_mx = ne['m']['x']
    ne_tc = ne['t']['c']; ne_tm = ne['t']['m']; ne_tx = ne['t']['x']
    return {
        'version': ver, 'card_id': cid, 'card_name': cname,
        'test_no': tno, 'test_desc': desc,
        'h1': hs[0], 'h2': hs[1], 'h3': hs[2],
        'm1': ms[0], 'm2': ms[1], 'm3': ms[2],
        't1': ts[0], 't2': ts[1], 't3': ts[2],
        'h_type': HT_NAMES[r['ht']], 'm_type': HT_NAMES[r['mt']], 't_type': HT_NAMES[r['tt']],
        'h_tc': r['ht'], 'm_tc': r['mt'], 't_tc': r['tt'],
        'c0_type': HT_NAMES[r['ct0']], 'c1_type': HT_NAMES[r['ct1']], 'c2_type': HT_NAMES[r['ct2']],
        'col_str': r['col_str'], 'xi_str': ','.join(r['xi_list']),
        'nc_h_c': ne_hc, 'nc_h_m': ne_hm, 'nc_h_x': str(ne_hx).replace('[','').replace(']','').replace(', ','/'),
        'nc_m_c': ne_mc, 'nc_m_m': ne_mm, 'nc_m_x': str(ne_mx).replace('[','').replace(']','').replace(', ','/'),
        'nc_t_c': ne_tc, 'nc_t_m': ne_tm, 'nc_t_x': str(ne_tx).replace('[','').replace(']','').replace(', ','/'),
        'h_card_chips': r['hcc'], 'h_hand_chips': r['hhc'], 'h_chips_total': r['hct'],
        'h_hand_mult': r['hhm'], 'h_mult_total': r['hmt'], 'h_score': r['hs'],
        'm_card_chips': r['mcc'], 'm_hand_chips': r['mhc'], 'm_chips_total': r['mct'],
        'm_hand_mult': r['mhm'], 'm_mult_total': r['mmt'], 'm_score': r['ms'],
        't_card_chips': r['tcc'], 't_hand_chips': r['thc'], 't_chips_total': r['tct'],
        't_hand_mult': r['thm'], 't_mult_total': r['tmt'], 't_score': r['ts'],
        'total_raw': r['raw'], 'col_total': r['col_total'],
        'xi_x_prod': xi_prod, 'final_score': r['final'],
    }


# ════════════════════════════════
# Test case helper: baseline + with_ninja pair
# ════════════════════════════════

# ════════════════════════════════
# Payload & Expected JSON (P0 cross-validation)
# ════════════════════════════════

PAYLOAD = []  # populated by tc()

def _format_expected(case_id, cards_str, r):
    """Build expected.json entry from calc() result."""
    return {
        'id': case_id,
        'hand_types': {'head': r['ht'], 'mid': r['mt'], 'tail': r['tt']},
        'col_types': [r['ct0'], r['ct1'], r['ct2']],
        'xi_list': r['xi_list'],
        'head': {
            'card_chips': r['hcc'], 'hand_chips': r['hhc'], 'ench_chips': 0,
            'ninja_chips': r['h_ninja_chips'], 'chips_total': r['hct'],
            'hand_mult': r['hhm'], 'ench_mult': 0, 'ninja_mult': r['h_ninja_mult'],
            'mult_total': r['hmt'], 'ninja_x_stack': r['h_ninja_x'],
            'score': r['hs']
        },
        'mid': {
            'card_chips': r['mcc'], 'hand_chips': r['mhc'], 'ench_chips': 0,
            'ninja_chips': r['m_ninja_chips'], 'chips_total': r['mct'],
            'hand_mult': r['mhm'], 'ench_mult': 0, 'ninja_mult': r['m_ninja_mult'],
            'mult_total': r['mmt'], 'ninja_x_stack': r['m_ninja_x'],
            'score': r['ms']
        },
        'tail': {
            'card_chips': r['tcc'], 'hand_chips': r['thc'], 'ench_chips': 0,
            'ninja_chips': r['t_ninja_chips'], 'chips_total': r['tct'],
            'hand_mult': r['thm'], 'ench_mult': 0, 'ninja_mult': r['t_ninja_mult'],
            'mult_total': r['tmt'], 'ninja_x_stack': r['t_ninja_x'],
            'score': r['ts']
        },
        'col_scores': r['col_scores'],
        'col_total': r['col_total'],
        'total_raw': r['raw'],
        'global_xi_x_prod': r['xi_x_prod'],
        'final_score': r['final'],
    }


def write_payload_and_expected(payload_path, expected_path):
    """Generate payload.json and expected.json from accumulated PAYLOAD entries."""
    import json

    payload_cases = []
    expected_cases = []

    for entry in PAYLOAD:
        payload_cases.append({
            'id': entry['id'],
            'cards': entry['cards'],
            'ninja_ids': entry['ninja_ids'],
            'ninja_effects': entry['ninja_effects'],
            'xi_bonus': entry['xi_bonus'],
            'xi_override': entry['xi_override'],
            'gold': 0,
            'seal_lord': {},
        })

        # Re-run calc() for expected values
        h = [pc(x) for x in entry['cards']['head']]
        m = [pc(x) for x in entry['cards']['mid']]
        t = [pc(x) for x in entry['cards']['tail']]
        ne = _effects_to_ne(entry['ninja_effects'])
        r = calc(h, m, t, ne, xi_bonus=entry['xi_bonus'], xi_override=entry['xi_override'])
        expected_cases.append(_format_expected(entry['id'], entry['cards'], r))

    with open(payload_path, 'w', encoding='utf-8') as f:
        json.dump({'cases': payload_cases}, f, ensure_ascii=False, indent=2)

    with open(expected_path, 'w', encoding='utf-8') as f:
        json.dump({'cases': expected_cases}, f, ensure_ascii=False, indent=2)

    return len(payload_cases)


def _effects_to_ne(effects):
    """Convert list of ninja effect dicts to combined ne dict.
    Multiple ninjas: chips/mult are additive, x_stack entries are concatenated."""
    result = {'h': {'c': 0, 'm': 0, 'x': []}, 'm': {'c': 0, 'm': 0, 'x': []}, 't': {'c': 0, 'm': 0, 'x': []}}
    for eff in effects:
        target = eff.get('group', 'all')
        c = eff.get('chips', 0)
        m = eff.get('mult', 0)
        xs = eff.get('x_mult', [])
        groups = ['h', 'm', 't'] if target == 'all' else [target]
        for g in groups:
            result[g]['c'] += c
            result[g]['m'] += m
            result[g]['x'].extend(xs)
    return result


def ne_to_effects(ne):
    """Convert ne dict to a list of effect dicts (for payload.json)."""
    # Check if unconditional
    if ne['h'] == ne['m'] == ne['t']:
        g = ne['h']
        if g['c'] == 0 and g['m'] == 0 and len(g['x']) == 0:
            return []
        return [{'group': 'all', 'chips': g['c'], 'mult': g['m'], 'x_mult': g['x']}]
    # Per-group effects
    effects = []
    for group in ['h', 'm', 't']:
        g = ne[group]
        if g['c'] != 0 or g['m'] != 0 or len(g['x']) != 0:
            effects.append({'group': group, 'chips': g['c'], 'mult': g['m'], 'x_mult': g['x']})
    return effects


# ════════════════════════════════
# Test case helper: baseline + with_ninja pair
# ════════════════════════════════

def tc(all_rows, cid, cname, tno, desc, hs, ms, ts, ne=None, xi_bonus=0, xi_override=None, duplicate_hand_x2=False):
    """Append baseline + with_ninja rows to all_rows. Also builds PAYLOAD. Returns delta."""
    if ne is None:
        ne = no_ninja()
    h = [pc(x) for x in hs]
    m = [pc(x) for x in ms]
    t = [pc(x) for x in ts]

    # CSV rows
    r0 = calc(h, m, t, no_ninja())
    all_rows.append(mkrow('baseline', cid, cname, tno, desc + '无忍', hs, ms, ts, r0, no_ninja()))
    r1 = calc(h, m, t, ne, xi_bonus=xi_bonus, xi_override=xi_override, duplicate_hand_x2=duplicate_hand_x2)
    all_rows.append(mkrow('with_ninja', cid, cname, tno, desc, hs, ms, ts, r1, ne, xi_bonus=xi_bonus))

    # Payload entries
    cards = {'head': hs, 'mid': ms, 'tail': ts}
    PAYLOAD.append({
        'id': f'{cid}_{tno}_baseline',
        'cards': cards,
        'ninja_ids': [],
        'ninja_effects': [],
        'xi_bonus': xi_bonus,
        'xi_override': xi_override or {},
    })
    PAYLOAD.append({
        'id': f'{cid}_{tno}_with_ninja',
        'cards': cards,
        'ninja_ids': [cid],
        'ninja_effects': ne_to_effects(ne),
        'xi_bonus': xi_bonus,
        'xi_override': xi_override or {},
    })

    return r1['final'] - r0['final']
