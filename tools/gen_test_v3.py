#!/usr/bin/env python3
"""
NinKing 忍者牌扩展测试数据生成器 v3
- 为30张计分类忍者各新增 T7/T8/T9 三组测试
- 3套全新牌组: SET_X(豹+顺+同花顺), SET_Y(三同花), SET_Z(全对子)
- 与 v2 的 T1-T6 完全区分，覆盖新牌型组合
- 输出追加到 ninja-test-extended.csv
"""
import csv, os

# ═══ 复用 v2 计分引擎 ═══

RANK_VAL = {'2':2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8,'9':9,'10':10,'J':11,'Q':12,'K':13,'A':14}
RANK_CHIP = {2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,10:10,11:10,12:10,13:10,14:11}
SUIT_TIE = {'♠':4,'♥':3,'♦':2,'♣':1}
HT_NAMES = {0:'散牌',1:'对子',2:'顺子',3:'同花',4:'同花顺',5:'豹子'}
H_CHIPS = {0:5,1:10,2:20,3:30,4:50,5:100}
H_MULT = {0:1,1:2,2:3,3:4,4:5,5:8}
COL_X = {0:1,1:2,2:4,3:8,4:16,5:32}
XI_GLOBAL = {'全黑':2,'全红':2,'全顺':2,'全同花':3,'四张':5,'全三条':4}
XI_GROUP = {'三清':2,'三顺清':3,'顺清打头':2}

def pc(s): return (s[0], RANK_VAL[s[1:]])
def cchip(c): return RANK_CHIP[c[1]]
def gchips(cs): return sum( cchip(c) for c in cs )
def is_flush(cs): return len({c[0] for c in cs}) == 1

def eval_group(cs):
    r = sorted([c[1] for c in cs])
    flush = is_flush(cs)
    straight = (r[1]==r[0]+1 and r[2]==r[1]+1) or (r[0]==2 and r[1]==3 and r[2]==14)
    rc = {}
    for v in r: rc[v]=rc.get(v,0)+1
    if 3 in rc.values(): ht=5
    elif flush and straight: ht=4
    elif flush: ht=3
    elif straight: ht=2
    elif 2 in rc.values(): ht=1
    else: ht=0
    str_val = ht*100 + r[2]*10 + r[1] + SUIT_TIE.get(cs[2][0],1)
    return ht, str_val

def eval_col(cs): return eval_group(cs)[0]

def detect_xi(h, m, t, he, me, te):
    all_c = h+m+t
    ht,mt,tt = he[0],me[0],te[0]
    xi = []
    if all(c[0] in '♠♣' for c in all_c): xi.append('全黑')
    if all(c[0] in '♥♦' for c in all_c): xi.append('全红')
    ar = sorted(c[1] for c in all_c)
    if all(ar[i]==ar[i-1]+1 for i in range(1,9)): xi.append('全顺')
    if all(c[0]==all_c[0][0] for c in all_c): xi.append('全同花')
    rc = {}
    for c in all_c: rc[c[1]]=rc.get(c[1],0)+1
    if any(v>=4 for v in rc.values()): xi.append('四张')
    if is_flush(h) and is_flush(m) and is_flush(t): xi.append('三清')
    if ht==4 and mt==4 and tt==4: xi.append('三顺清')
    if ht==4: xi.append('顺清打头')
    if all(v==3 for v in rc.values()): xi.append('全三条')
    return xi

def calc(cs_h, cs_m, cs_t, ne, xi_bonus=0, xi_override=None, duplicate_hand_x2=False):
    he = eval_group(cs_h)
    me = eval_group(cs_m)
    te = eval_group(cs_t)
    hk,mk,tk = he[0],me[0],te[0]

    def gs(cs, tp, ne_g):
        cc = gchips(cs)
        chips = cc + H_CHIPS[tp] + ne_g['c']
        mult = H_MULT[tp] + ne_g['m']
        xp = 1
        for xv in ne_g['x']: xp *= xv
        return chips*mult*xp, cc, H_CHIPS[tp], chips, H_MULT[tp], mult

    hs, hcc, hhc, hct, hhm, hmt = gs(cs_h, hk, ne['h'])
    ms, mcc, mhc, mct, mhm, mmt = gs(cs_m, mk, ne['m'])
    ts, tcc, thc, tct, thm, tmt = gs(cs_t, tk, ne['t'])

    c0t = eval_col([cs_h[0],cs_m[0],cs_t[0]])
    c1t = eval_col([cs_h[1],cs_m[1],cs_t[1]])
    c2t = eval_col([cs_h[2],cs_m[2],cs_t[2]])
    col_x = []
    for ct in [c0t,c1t,c2t]:
        xv = COL_X[ct]
        if xv > 1: col_x.append(xv)
    col_str = ','.join(str(x) for x in col_x)

    xi_list = detect_xi(cs_h, cs_m, cs_t, he, me, te)
    xi_glob = [x for x in xi_list if x in XI_GLOBAL]
    xi_grp  = [x for x in xi_list if x in XI_GROUP]
    if xi_override is None: xi_override = {}

    sq = 2 + xi_bonus
    if '三清' in xi_override: sq = xi_override['三清']
    if '三清' in xi_list: hs*=sq; ms*=sq; ts*=sq
    ssq = 3 + xi_bonus
    if '三顺清' in xi_list: hs*=ssq; ms*=ssq; ts*=ssq
    shq = 2 + xi_bonus
    if '顺清打头' in xi_list: hs*=shq

    # 双头蛇: 相同牌型计分×2
    if duplicate_hand_x2:
        all_types = [hk, mk, tk, c0t, c1t, c2t]
        tc2 = {}
        for hv in all_types: tc2[hv] = tc2.get(hv, 0) + 1
        if tc2.get(hk, 0) >= 2: hs *= 2
        if tc2.get(mk, 0) >= 2: ms *= 2
        if tc2.get(tk, 0) >= 2: ts *= 2

    raw = hs + ms + ts
    final = max(raw, 1)
    for x in col_x: final *= x
    for x in xi_glob: final *= XI_GLOBAL[x] + xi_bonus

    return {
        'hs':hs,'ms':ms,'ts':ts,
        'hcc':hcc,'hhc':hhc,'hct':hct,'hhm':hhm,'hmt':hmt,
        'mcc':mcc,'mhc':mhc,'mct':mct,'mhm':mhm,'mmt':mmt,
        'tcc':tcc,'thc':thc,'tct':tct,'thm':thm,'tmt':tmt,
        'raw':raw,'col_x':col_x,'col_str':col_str,
        'xi_list':xi_list,'xi_glob':xi_glob,'final':final,
        'ht':hk,'mt':mk,'tt':tk,
        'ct0':c0t,'ct1':c1t,'ct2':c2t,
    }

HEADER = [
    'version','card_id','card_name','test_no','test_desc',
    'h1','h2','h3','m1','m2','m3','t1','t2','t3',
    'h_type','m_type','t_type','h_tc','m_tc','t_tc',
    'c0_type','c1_type','c2_type','col_str','xi_str',
    'nc_h_c','nc_h_m','nc_h_x','nc_m_c','nc_m_m','nc_m_x','nc_t_c','nc_t_m','nc_t_x',
    'h_card_chips','h_hand_chips','h_chips_total','h_hand_mult','h_mult_total','h_score',
    'm_card_chips','m_hand_chips','m_chips_total','m_hand_mult','m_mult_total','m_score',
    't_card_chips','t_hand_chips','t_chips_total','t_hand_mult','t_mult_total','t_score',
    'total_raw','col_x_prod','xi_x_prod','final_score'
]

ALL = []

def mkrow(ver, cid, cname, tno, desc, hs, ms, ts, r, ne, xi_bonus=0):
    def colp(xs): return 1 if not xs else xs[0] if len(xs)==1 else eval('*'.join(str(x) for x in xs))
    xi_prod = 1
    for x in r['xi_glob']: xi_prod *= XI_GLOBAL[x] + xi_bonus
    return {
        'version':ver,'card_id':cid,'card_name':cname,
        'test_no':tno,'test_desc':desc,
        'h1':hs[0],'h2':hs[1],'h3':hs[2],
        'm1':ms[0],'m2':ms[1],'m3':ms[2],
        't1':ts[0],'t2':ts[1],'t3':ts[2],
        'h_type':HT_NAMES[r['ht']],'m_type':HT_NAMES[r['mt']],'t_type':HT_NAMES[r['tt']],
        'h_tc':r['ht'],'m_tc':r['mt'],'t_tc':r['tt'],
        'c0_type':HT_NAMES[r['ct0']],'c1_type':HT_NAMES[r['ct1']],'c2_type':HT_NAMES[r['ct2']],
        'col_str':r['col_str'],'xi_str':','.join(r['xi_list']),
        'nc_h_c':ne['h']['c'],'nc_h_m':ne['h']['m'],
        'nc_h_x':str(ne['h']['x']).replace('[','').replace(']','').replace(', ','/'),
        'nc_m_c':ne['m']['c'],'nc_m_m':ne['m']['m'],
        'nc_m_x':str(ne['m']['x']).replace('[','').replace(']','').replace(', ','/'),
        'nc_t_c':ne['t']['c'],'nc_t_m':ne['t']['m'],
        'nc_t_x':str(ne['t']['x']).replace('[','').replace(']','').replace(', ','/'),
        'h_card_chips':r['hcc'],'h_hand_chips':r['hhc'],'h_chips_total':r['hct'],
        'h_hand_mult':r['hhm'],'h_mult_total':r['hmt'],'h_score':r['hs'],
        'm_card_chips':r['mcc'],'m_hand_chips':r['mhc'],'m_chips_total':r['mct'],
        'm_hand_mult':r['mhm'],'m_mult_total':r['mmt'],'m_score':r['ms'],
        't_card_chips':r['tcc'],'t_hand_chips':r['thc'],'t_chips_total':r['tct'],
        't_hand_mult':r['thm'],'t_mult_total':r['tmt'],'t_score':r['ts'],
        'total_raw':r['raw'],'col_x_prod':colp(r['col_x']),
        'xi_x_prod':xi_prod,'final_score':r['final'],
    }

def no_ninja():
    return {'h':{'c':0,'m':0,'x':[]},'m':{'c':0,'m':0,'x':[]},'t':{'c':0,'m':0,'x':[]}}

def ne_all(c=0,m=0,x=None):
    if x is None: x=[]
    return {'h':{'c':c,'m':m,'x':x},'m':{'c':c,'m':m,'x':x},'t':{'c':c,'m':m,'x':x}}

def ne_partial(**kwargs):
    base = {'h':{'c':0,'m':0,'x':[]},'m':{'c':0,'m':0,'x':[]},'t':{'c':0,'m':0,'x':[]}}
    for k,v in kwargs.items():
        g = {'c':0,'m':0,'x':[]}
        g.update(v)
        base[k] = g
    return base

def tc(cid, cname, tno, desc, hs, ms, ts, ne=None, xi_bonus=0, xi_override=None, duplicate_hand_x2=False):
    if ne is None: ne = no_ninja()
    h = [pc(x) for x in hs]
    m = [pc(x) for x in ms]
    t = [pc(x) for x in ts]
    r0 = calc(h,m,t,no_ninja())
    ALL.append(mkrow('baseline',cid,cname,tno,desc+'无忍',hs,ms,ts,r0,no_ninja()))
    r1 = calc(h,m,t,ne, xi_bonus=xi_bonus, xi_override=xi_override, duplicate_hand_x2=duplicate_hand_x2)
    ALL.append(mkrow('with_ninja',cid,cname,tno,desc,hs,ms,ts,r1,ne, xi_bonus=xi_bonus))
    return r1['final'] - r0['final']


# ════════════════════════════════════════
# 三套全新牌组（与 v2 的 T1-T6 完全无重叠）
# ════════════════════════════════════════

# SET_X — 头豹(5) + 中顺(2) + 尾同花顺(4)
# 列: 散/同花♥×8/散 → 列乘8
# 点数: JJJ|567|QKA → 全唯一 ✅ 无四张/全顺 ✅
# 花色: ♠♠/♥♥♥♥/♦♦/♣ → 混 ✅ 无喜 ✅
# 基线: 12472
SET_X = (['♠J','♥J','♦J'], ['♠5','♥6','♣7'], ['♥Q','♥K','♥A'])

# SET_Y — 三组同花(3/3/3) ♠♠♠/♥♥♥/♣♣♣
# 列: 顺×4 / 顺×4 / 散 → 列乘16
# 点数: 2,5,9/3,6,K/4,7,Q → 全唯一 ✅
# 喜: 三清×2 + 全黑×2 → 基线: 38656
SET_Y = (['♠2','♠5','♠9'], ['♥3','♥6','♥K'], ['♣4','♣7','♣Q'])

# SET_Z — 三组对子(1/1/1) [2][3][A]
# 列: 同花♠×8 / 同花♥×8 / 顺×4 → 列乘256
# 点数: 2×3/J/3×3/Q/A×3/K → 全唯一 ✅
# 无喜 ✅ 基线: 49664
SET_Z = (['♠2','♥2','♣J'], ['♠3','♥3','♦Q'], ['♠A','♥A','♦K'])

# SET_W — 头同花♠+中同花♠+尾同花♣ (三清+全黑)
# 列: 顺×4 / 散 / 散 → 列乘4
# 点数: 2,5,9/3,7,J/4,8,Q → 全唯一 ✅
# 喜: 三清×2 + 全黑×2 → 基线: 9600
SET_W = (['♠2','♠5','♠9'], ['♠3','♠7','♠J'], ['♣4','♣8','♣Q'])

# SET_V2 — 四张3(头豹+中散+尾散)
# 列: 对子×2 / 散 / 散 → 列乘2
# 喜: 四张×5 → 基线: 9290
SET_V2 = (['♠3','♥3','♦3'], ['♣3','♠5','♥7'], ['♣9','♠J','♥K'])

# SET_U2 — 头豹(5)+中同花(3)+尾同花顺♦(4)
# 列: 散/散/散 → 列乘1
# 无喜 ✅ 基线: 1636
SET_U2 = (['♠10','♥10','♦10'], ['♠3','♠7','♠9'], ['♦J','♦Q','♦K'])

# SET_ACE — 头对A(1)+中散(0)+尾散(0) (2张Ace)
# 列: 散/散/散 → 列乘1
# 无喜 ✅ 基线: 133
SET_ACE = (['♠A','♥A','♠5'], ['♠7','♥9','♣J'], ['♣3','♦Q','♦K'])

# SET_P — 头散(0)+中豹(5)+尾同花顺(4) (低-高-高)
# 列: 散 / 同花♥×8 / 散 → 列乘8
# 无喜 ✅ 基线: 10416
SET_P = (['♠2','♥5','♦9'], ['♠J','♥J','♦J'], ['♥Q','♥K','♥A'])

# SET_Q — 头顺(2)+中对(1)+尾散(0) (散混搭)
# 列: 顺×4 / 散 / 散 → 列乘4
# 无喜 ✅ 基线: 1308
SET_Q = (['♠2','♥3','♣4'], ['♠5','♥5','♦9'], ['♣7','♠10','♥K'])

# SET_R — 头豹+中豹+尾豹(三列豹+全三条, 非三列豹排布)
# 列: 散/散/散 → 列乘1
# 喜: 全三条×4 → 基线: 1956
SET_R = (['♠3','♥3','♦3'], ['♠7','♥7','♦7'], ['♠J','♥J','♦J'])

print('=== 忍者牌扩展测试 v3 生成 ===')
print(f'套牌: X(12472) Y(38656) Z(49664) W(9600) V(11120) U(10024) P(10416) Q(1308) R(1956)')

total_delta = 0

# ══════════════════════════════════════════════════
# T7-T9 扩展测试 — 每卡3组，共30卡×3=90测试对=180行
# ══════════════════════════════════════════════════

# ==================== Batch 1: 通用加成 (6 cards) ====================

# n_001 手里剑 +10 chips
total_delta += tc('n_001','手里剑','T7','豹+顺+同花顺+8列+10c', *SET_X, ne_all(c=10))
total_delta += tc('n_001','手里剑','T8','三同花+列16+三清+全黑+10c', *SET_Y, ne_all(c=10))
total_delta += tc('n_001','手里剑','T9','全对子+256列+10c', *SET_Z, ne_all(c=10))

# n_002 苦无 +4 mult
total_delta += tc('n_002','苦无','T7','豹+顺+同花顺+8列+4m', *SET_X, ne_all(m=4))
total_delta += tc('n_002','苦无','T8','三同花+列16+三清+全黑+4m', *SET_Y, ne_all(m=4))
total_delta += tc('n_002','苦无','T9','全对子+256列+4m', *SET_Z, ne_all(m=4))

# n_003 忍刀 +15c +2m
total_delta += tc('n_003','忍刀','T7','豹+顺+同花顺+8列+15c+2m', *SET_X, ne_all(c=15,m=2))
total_delta += tc('n_003','忍刀','T8','三同花+列16+三清+全黑+15c+2m', *SET_Y, ne_all(c=15,m=2))
total_delta += tc('n_003','忍刀','T9','全对子+256列+15c+2m', *SET_Z, ne_all(c=15,m=2))

# n_004 重刃 +20 chips
total_delta += tc('n_004','重刃','T7','豹+顺+同花顺+8列+20c', *SET_X, ne_all(c=20))
total_delta += tc('n_004','重刃','T8','三同花+列16+三清+全黑+20c', *SET_Y, ne_all(c=20))
total_delta += tc('n_004','重刃','T9','全对子+256列+20c', *SET_Z, ne_all(c=20))

# n_005 影缝 +10 mult
total_delta += tc('n_005','影缝','T7','豹+顺+同花顺+8列+10m', *SET_X, ne_all(m=10))
total_delta += tc('n_005','影缝','T8','三同花+列16+三清+全黑+10m', *SET_Y, ne_all(m=10))
total_delta += tc('n_005','影缝','T9','全对子+256列+10m', *SET_Z, ne_all(m=10))

# n_006 奥义之卷 +30c +10m
total_delta += tc('n_006','奥义之卷','T7','豹+顺+同花顺+8列+30c+10m', *SET_X, ne_all(c=30,m=10))
total_delta += tc('n_006','奥义之卷','T8','三同花+列16+三清+全黑+30c+10m', *SET_Y, ne_all(c=30,m=10))
total_delta += tc('n_006','奥义之卷','T9','全对子+256列+30c+10m', *SET_Z, ne_all(c=30,m=10))


# ==================== Batch 2: 组别定向 (6 cards) ====================

# n_g01 虎头 head≤对子→+5m head
total_delta += tc('n_g01','虎头','T7','头对触发+5m[Z]', *SET_Z, ne_partial(h={'m':5}))  # head对子(1)≤1 ✅
total_delta += tc('n_g01','虎头','T8','头豹不触发[X]', *SET_X, no_ninja())               # head豹(5)>1 ❌
total_delta += tc('n_g01','虎头','T9','头散触发+5m[P]', *SET_P, ne_partial(h={'m':5}))   # head散(0)≤1 ✅

# n_g02 龙尾 tail≥同花顺→×2 tail
total_delta += tc('n_g02','龙尾','T7','尾同花顺触发×2[X]', *SET_X, ne_partial(t={'x':[2]}))  # tail同花顺(4)≥4 ✅
total_delta += tc('n_g02','龙尾','T8','尾同花不触发[Y]', *SET_Y, no_ninja())                  # tail同花(3)<4 ❌
total_delta += tc('n_g02','龙尾','T9','尾对子不触发[Z]', *SET_Z, no_ninja())                  # tail对子(1)<4 ❌

# n_g03 中流砥柱 mid+50c (无条件)
total_delta += tc('n_g03','中流砥柱','T7','中顺+50c[X]', *SET_X, ne_partial(m={'c':50}))
total_delta += tc('n_g03','中流砥柱','T8','中同花+50c[Y]', *SET_Y, ne_partial(m={'c':50}))
total_delta += tc('n_g03','中流砥柱','T9','中对子+50c[Z]', *SET_Z, ne_partial(m={'c':50}))

# n_g04 藏锋 +2出牌次数（无计分影响，所有测试δ=0）
total_delta += tc('n_g04','藏锋','T7','无条件+2出牌[X]', *SET_X, no_ninja())
total_delta += tc('n_g04','藏锋','T8','无条件+2出牌[Z]', *SET_Z, no_ninja())
total_delta += tc('n_g04','藏锋','T9','无条件+2出牌[W]', *SET_W, no_ninja())

# n_g05 双头蛇 行+列相同牌型计分×2
total_delta += tc('n_g05','双头蛇','T7','豹+顺+同花顺(皆不同)[X]', *SET_X, no_ninja(), duplicate_hand_x2=True)  # 牌型全不同→无加倍
total_delta += tc('n_g05','双头蛇','T8','对+对+对(全对)[Z]', *SET_Z, no_ninja(), duplicate_hand_x2=True)       # 三行全对→行×4
total_delta += tc('n_g05','双头蛇','T9','同花+同花+同花(全同花)[W]', *SET_W, no_ninja(), duplicate_hand_x2=True)  # 三行全同花→行×4

# n_g06 金字塔 strict_ascending→×2
total_delta += tc('n_g06','金字塔','T7','头散<中顺<尾同花顺×2', *SET_P, ne_all(x=[2]))  # 0<2<4 ✅
total_delta += tc('n_g06','金字塔','T8','头豹>中顺不触发[X]', *SET_X, no_ninja())         # 5>2<4 ❌
total_delta += tc('n_g06','金字塔','T9','头对=中对不触发[Z]', *SET_Z, no_ninja())         # 1=1 ❌


# ==================== Batch 3: 喜强化 (4 cards) ====================

# n_x01 喜鹊 每喜×mult +1
total_delta += tc('n_x01','喜鹊','T7','三清+全黑+1[X_喜W]', *SET_W, no_ninja(), xi_bonus=1)   # 三清×3+全黑×3
total_delta += tc('n_x01','喜鹊','T8','四张+1[V2]', *SET_V2, no_ninja(), xi_bonus=1)            # 四张×6
total_delta += tc('n_x01','喜鹊','T9','三清+全黑+1[Y大列]', *SET_Y, no_ninja(), xi_bonus=1)   # 三清×3+全黑×3+列16

# n_x02 四张猎人 +30c(四张) else +5c
total_delta += tc('n_x02','四张猎人','T7','三清无四张+5c[W]', *SET_W, ne_all(c=5))          # 无四张→+5c
total_delta += tc('n_x02','四张猎人','T8','四张触发+30c[V2]', *SET_V2, ne_all(c=30))          # 四张→+30c
total_delta += tc('n_x02','四张猎人','T9','全对子无四张+5c[Z]', *SET_Z, ne_all(c=5))        # 无四张→+5c

# n_x03 清一色 三清×3
total_delta += tc('n_x03','清一色','T7','三清+全黑×3[W]', *SET_W, no_ninja(), xi_override={'三清':3})
total_delta += tc('n_x03','清一色','T8','三清+全黑+大列×3[Y]', *SET_Y, no_ninja(), xi_override={'三清':3})
total_delta += tc('n_x03','清一色','T9','无三清不触发[X]', *SET_X, no_ninja(), xi_override={'三清':3})

# n_x06 龙之眼 每多一张四张×2(上限2次)
total_delta += tc('n_x06','龙之眼','T7','单套四张×2[V2]', *SET_V2, ne_all(x=[2]))
total_delta += tc('n_x06','龙之眼','T8','三组豹全三条×2[R]', *SET_R, ne_all(x=[2]))
# 龙之眼: 三组都是豹子(5), 但全三条×4喜触发. 龙之眼×2 叠加
total_delta += tc('n_x06','龙之眼','T9','无四张不触发[Z]', *SET_Z, no_ninja())


# ==================== Batch 4: 跨组联动+点数 (5 cards) ====================

# n_c01 镜像 head_type=tail_type→×2 head
total_delta += tc('n_c01','镜像','T7','头尾对子触发×2[Z]', *SET_Z, ne_partial(h={'x':[2]}))       # head对(1)=tail对(1) ✅
total_delta += tc('n_c01','镜像','T8','头豹≠尾同花顺不触发[X]', *SET_X, no_ninja())              # 5≠4 ❌
total_delta += tc('n_c01','镜像','T9','头尾同花触发×2[W]', *SET_W, ne_partial(h={'x':[2]}))      # head同花(3)=tail同花(3) ✅

# n_c02 铁索连环 any_two_same→全组+15c+3m
total_delta += tc('n_c02','铁索连环','T7','三项全对+15c+3m[Z]', *SET_Z, ne_all(c=15,m=3))           # 三对→全同 ✅
total_delta += tc('n_c02','铁索连环','T8','三项全同花+15c+3m[Y]', *SET_Y, ne_all(c=15,m=3))        # 三同花→全同 ✅
total_delta += tc('n_c02','铁索连环','T9','三项全异不触发[X]', *SET_X, no_ninja())                 # 5≠2≠4 ❌

# n_f01 影之眷顾 +3c per J/Q/K
total_delta += tc('n_f01','影之眷顾','T7','5张人牌+15c[X]', *SET_X, ne_all(c=15))    # ♠J♥J♦J♥Q♥K=5张
total_delta += tc('n_f01','影之眷顾','T8','2张人牌+6c[Z]', *SET_Z, ne_all(c=6))     # ♣J♦Q=2张
total_delta += tc('n_f01','影之眷顾','T9','0张人牌+0c[P]', *SET_P, no_ninja())       # 没人牌

# n_f02 王牌侍从 +5m per Ace(cap20)
total_delta += tc('n_f02','王牌侍从','T7','2A+10m[ACE]', *SET_ACE, ne_all(m=10))      # 2张A→+10m
total_delta += tc('n_f02','王牌侍从','T8','2A+10m[Z]', *SET_Z, ne_all(m=10))          # ♠A♥A=2张
total_delta += tc('n_f02','王牌侍从','T9','0A+0m[Q]', *SET_Q, no_ninja())             # 无A


# ==================== Batch 5: 规则变更+传说+风遁 (4 cards) ====================

# n_r02 均衡之印 三组同牌型→×2
total_delta += tc('n_r02','均衡之印','T7','三组对子×2[Z]', *SET_Z, ne_all(x=[2]))       # 三对→同型 ✅
total_delta += tc('n_r02','均衡之印','T8','三组同花×2[Y]', *SET_Y, ne_all(x=[2]))       # 三同花→同型 ✅
total_delta += tc('n_r02','均衡之印','T9','豹≠顺≠同花顺不触发[X]', *SET_X, no_ninja()) # 5≠2≠4 ❌

# n_r03 独尊之印 tail×2 if head+mid≥对子
total_delta += tc('n_r03','独尊之印','T7','头中对中触发×2尾[Z]', *SET_Z, ne_partial(t={'x':[2]}))  # head对+mid对 ✅
total_delta += tc('n_r03','独尊之印','T8','头豹+中顺触发×2尾[X]', *SET_X, ne_partial(t={'x':[2]})) # head豹+mid顺 ✅
total_delta += tc('n_r03','独尊之印','T9','头同花+中同花触发×2尾[W]', *SET_W, ne_partial(t={'x':[2]})) # head同花+mid同花 ✅

# n_t05 风遁 hand_type=1→+3m (改造: 首回合×2→对子+倍率)
total_delta += tc('n_t05','风遁','T7','豹+顺+同花顺不触发[X]', *SET_X, no_ninja())    # none is 对子(1)
total_delta += tc('n_t05','风遁','T8','三同花不触发[Y]', *SET_Y, no_ninja())           # all 同花(3) ❌
total_delta += tc('n_t05','风遁','T9','全对子+3m[Z]', *SET_Z, ne_all(m=3))              # all 对子(1) ✅

# n_t02 水遁 hand_type=2→+5m (改造: 原手替え→顺子+倍率)
total_delta += tc('n_t02','水遁','T7','中顺+5m[X]', *SET_X, ne_partial(m={'m':5}))    # mid顺(2) ✅
total_delta += tc('n_t02','水遁','T8','三同花不触发[Y]', *SET_Y, no_ninja())           # 全同花(3) ❌
total_delta += tc('n_t02','水遁','T9','全对子不触发[Z]', *SET_Z, no_ninja())           # 全对子(1) ❌

# n_l01 天下人 ×2 all (all trigger)
total_delta += tc('n_l01','天下人','T7','豹+顺+同花顺×2[X]', *SET_X, ne_all(x=[2]))
total_delta += tc('n_l01','天下人','T8','三同花+喜×2[Y]', *SET_Y, ne_all(x=[2]))
total_delta += tc('n_l01','天下人','T9','全对子×2[Z]', *SET_Z, ne_all(x=[2]))

# n_g07 三清道人 hand_type=3→×2 (extended)
total_delta += tc('n_g07','三清道人','T7','同花组×2+全黑[W]', *SET_W, ne_all(x=[2]))
total_delta += tc('n_g07','三清道人','T8','顺子组不触[Q]', *SET_Q, no_ninja())
total_delta += tc('n_g07','三清道人','T9','全对子不触[Z]', *SET_Z, no_ninja())

# n_g08 龙脉 hand_type=2→×2 (extended)
total_delta += tc('n_g08','龙脉','T7','三组顺子+全黑',
    ['♠2','♠3','♠4'], ['♠5','♠6','♠7'], ['♠8','♠9','♠10'], ne_all(x=[2]))
total_delta += tc('n_g08','龙脉','T8','同花组不触[W]', *SET_W, no_ninja())
total_delta += tc('n_g08','龙脉','T9','全对子不触[Z]', *SET_Z, no_ninja())


# ==================== Batch 6: 成长修炼 (5 cards) ====================

# n_s01 修行者 +1m/play (累积模拟)
total_delta += tc('n_s01','修行者','T7','累积5次+5m[X]', *SET_X, ne_all(m=5))
total_delta += tc('n_s01','修行者','T8','累积8次+8m[Y]', *SET_Y, ne_all(m=8))
total_delta += tc('n_s01','修行者','T9','累积12次+12m[Z]', *SET_Z, ne_all(m=12))

# n_s02 三清道人 +25c/三清play (累积模拟)
total_delta += tc('n_s02','三清道人','T7','三清累积5次+125c[W]', *SET_W, ne_all(c=125))
total_delta += tc('n_s02','三清道人','T8','三清累积10次+250c[Y]', *SET_Y, ne_all(c=250))
total_delta += tc('n_s02','三清道人','T9','无三清未累积[X]', *SET_X, no_ninja())

# n_s03 龙脉 +30c/尾同花顺play (累积模拟)
total_delta += tc('n_s03','龙脉','T7','尾同花顺累积5次+150c[X]', *SET_X, ne_all(c=150))
total_delta += tc('n_s03','龙脉','T8','尾同花顺累积8次+240c[U2]', *SET_U2, ne_all(c=240))
total_delta += tc('n_s03','龙脉','T9','尾对子未累积[Z]', *SET_Z, no_ninja())

# n_s05 天华 hand_type=4→×4 (extended)
total_delta += tc('n_s05','天华','T7','尾同花顺×4[P]', *SET_P, ne_partial(t={'x':[4]}))
total_delta += tc('n_s05','天华','T8','全对子不触[Z]', *SET_Z, no_ninja())
total_delta += tc('n_s05','天华','T9','三组同花顺+全黑[Y]',
    ['♠J','♠Q','♠K'], ['♠10','♠A','♠2'], ['♠3','♠4','♠5'], ne_all(x=[4]))

# n_s06 王座 hand_type=5→×5 (extended)
total_delta += tc('n_s06','王座','T7','头豹×5[X]', *SET_X, ne_partial(h={'x':[5]}))
total_delta += tc('n_s06','王座','T8','全对子不触[Z]', *SET_Z, no_ninja())
total_delta += tc('n_s06','王座','T9','三组豹子+全三条[V2]',
    ['♠J','♥J','♦J'], ['♠3','♥3','♦3'], ['♣5','♥5','♦5'], ne_all(x=[5]))


# ════════════════════════════════════════
# 输出扩展 CSV
# ════════════════════════════════════════

OUT = r'E:\01 Code\Godot_v4.6.2\NinKing\docs\ninking\testing\ninja-test-extended.csv'
with open(OUT, 'w', newline='', encoding='utf-8-sig') as f:
    w = csv.DictWriter(f, fieldnames=HEADER)
    w.writeheader()
    for row in ALL:
        w.writerow(row)

n = len(ALL)
pairs = n // 2
print(f'\n[OK] 生成 {n} 行 ({pairs} 测试对) → {OUT}')
print(f'累加Delta: {total_delta}')

# Delta 验证
print('\n=== Delta 验证 ===')
errors = []
for i in range(0, len(ALL), 2):
    r = ALL[i]
    r2 = ALL[i+1]
    d = r2['final_score'] - r['final_score']
    cid = r['card_id']; name = r['card_name']; tno = r['test_no']

    has_ne = any(int(r2[f'nc_{g}_{s}']) != 0 for g in ['h','m','t'] for s in ['c','m'])
    has_x = any(r2[f'nc_{g}_x'] not in ['','1','[]'] for g in ['h','m','t'])
    has_xi_mod = (r2['xi_x_prod'] != r['xi_x_prod'])
    effect = has_ne or has_x or has_xi_mod or (d != 0)

    # 不触发集（应Δ=0）
    no_effect = {
        ('n_g01','T8'),('n_g02','T8'),('n_g02','T9'),
        ('n_g04','T7'),('n_g04','T8'),('n_g04','T9'),
        ('n_g05','T7'),
        ('n_g06','T8'),('n_g06','T9'),
        ('n_x03','T9'),
        ('n_x06','T9'),
        ('n_c01','T8'),('n_c02','T9'),
        ('n_f01','T9'),('n_f02','T9'),
        ('n_r02','T9'),
        ('n_s02','T9'),('n_s03','T9'),
    }

    ne = (cid, tno) in no_effect

    if ne and d != 0:
        errors.append(f'[{cid} {name} {tno}] 不触发但Δ={d}')
        print(f'  {cid} {name} {tno}: {r["final_score"]}→{r2["final_score"]} Δ={d} [ERROR] 应有Δ=0')
    elif not ne and d == 0 and effect:
        errors.append(f'[{cid} {name} {tno}] 触发但Δ=0')
        print(f'  {cid} {name} {tno}: {r["final_score"]}→{r2["final_score"]} Δ=0 [ERROR] 应有Δ>0')
    elif not ne and d == 0 and not effect:
        print(f'  {cid} {name} {tno}: Δ=0 [OK] 有效果但为0')
    else:
        status = f'Δ={d}' if effect else '不触发Δ=0'
        print(f'  {cid} {name} {tno}: {r["final_score"]}→{r2["final_score"]} {status} [OK]')

# n_g01 T9 检查: SET_P head是否散牌
h9 = [pc(x) for x in SET_P[0]]
ht9 = eval_group(h9)[0]
ht_name9 = HT_NAMES[ht9]
print(f'\n  [T9检查] n_g01 SET_P head牌型={ht_name9}({ht9}) → {"触发" if ht9<=1 else "不触"}')

print(f'\n{"="*50}')
if errors:
    print(f'[ERROR] {len(errors)} Delta异常:')
    for e in errors: print(f'  - {e}')
else:
    print(f'[PASS] 全部 {pairs} 测试对通过')
print(f'总计: {pairs} 对 | 文件: {OUT}')
