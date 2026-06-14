#!/usr/bin/env python3
"""
NinKing 测试数据 Review 报告生成器

用途: 自动审查 ninja-test-full.csv 的 Delta 正确性 + 统计分布
运行: python tools/review_test_data.py
输出: 控制台 + 可选保存到 docs/ninking/testing/review-report-latest.txt
"""
import csv, sys, os
from datetime import datetime

CSV_PATH = r'E:\Code\Godot_v4.6.2-stable_win64\NinKing\docs\ninking\testing\ninja-test-full.csv'

def load_csv(path=CSV_PATH):
    rows = []
    with open(path, 'r', encoding='utf-8-sig') as f:
        for r in csv.DictReader(f):
            r['final_score'] = int(r['final_score'])
            r['col_total'] = int(r['col_total'])
            r['xi_x_prod'] = int(r['xi_x_prod'])
            rows.append(r)
    pairs = {}
    for r in rows:
        k = (r['card_id'], r['test_no'])
        if k not in pairs:
            pairs[k] = {'b': None, 'n': None, 'id': r['card_id'],
                       'name': r['card_name'], 'tno': r['test_no']}
        if r['version'] == 'baseline': pairs[k]['b'] = r
        else: pairs[k]['n'] = r
    return [p for p in pairs.values() if p['b'] and p['n']]

# 不触发测试集合（应 Delta=0）
NO_EFFECT = {
    ('n_g01','T3'),('n_g01','T5'),('n_g02','T3'),('n_g02','T6'),
    ('n_g04','T3'),('n_g04','T4'),('n_g04','T5'),('n_g05','T3'),
    ('n_g05','T6'),('n_g06','T3'),('n_x01','T3'),('n_x03','T3'),
    ('n_x06','T3'),('n_c01','T3'),('n_f01','T2'),('n_f02','T3'),
    ('n_r03','T3'),('n_s01','T3'),('n_s02','T3'),('n_s03','T3'),
    ('n_s05','T3'),('n_s06','T3'),
}

CATEGORIES = [
    ('Batch1 通用', ['n_001','n_002','n_003','n_004','n_005','n_006']),
    ('Batch2 组别', ['n_g01','n_g02','n_g03','n_g04','n_g05','n_g06']),
    ('Batch3 喜',   ['n_x01','n_x02','n_x03','n_x06']),
    ('Batch4 联动', ['n_c01','n_c02','n_f01','n_f02']),
    ('Batch5 规则', ['n_r02','n_r03','n_t05','n_l01']),
    ('Batch6 成长', ['n_s01','n_s02','n_s03','n_s05','n_s06']),
]

def fmt(n): return f'{n:,}'

def check_deltas(pairs):
    """核心检查：所有 Delta 是否正确"""
    errors = []
    for p in pairs:
        d = p['n']['final_score'] - p['b']['final_score']
        ne = (p['id'], p['tno']) in NO_EFFECT
        if ne and d != 0:
            errors.append(f'[FAIL] {p["id"]} {p["name"]} {p["tno"]}: 不触发Δ={d}')
        if not ne and d == 0:
            # 确认是否有任何效果值
            has_ne = any(int(p['n'][f'nc_{g}_{s}']) for g in ['h','m','t'] for s in ['c','m'])
            has_x = any(p['n'][f'nc_{g}_x'] not in ['','1','[]'] for g in ['h','m','t'])
            has_xi_mod = p['n']['final_score'] != p['b']['final_score']
            if has_ne or has_x or has_xi_mod:
                errors.append(f'[FAIL] {p["id"]} {p["name"]} {p["tno"]}: 触发但Δ=0')
    return errors

def check_sd(pairs):
    """SD标准牌组一致性"""
    bases = set()
    count = 0
    sd = ('♠2','♥7','♦J','♣4','♠9','♥Q','♣3','♠6','♥K')
    for p in pairs:
        cards = tuple(p['b'][h] for h in ['h1','h2','h3','m1','m2','m3','t1','t2','t3'])
        if cards == sd:
            bases.add(p['b']['final_score'])
            count += 1
    return count, bases

def card_avg(pairs):
    """每卡平均Delta"""
    avgs = {}
    for p in pairs:
        if p['n']['final_score'] > p['b']['final_score']:
            d = p['n']['final_score'] - p['b']['final_score']
            cid = p['id']
            if cid not in avgs:
                avgs[cid] = {'deltas': [], 'name': p['name']}
            avgs[cid]['deltas'].append(d)
    return avgs

def main():
    pairs = load_csv()

    print('=' * 62)
    print(f'  NinKing 测试数据 Review 报告')
    print(f'  {datetime.now().strftime("%Y-%m-%d %H:%M")}  |  {len(pairs)} 测试对')
    print('=' * 62)

    # 1. Delta
    print('\n【1】Delta 正确性')
    errors = check_deltas(pairs)
    if errors:
        for e in errors: print(f'  {e}')
        print(f'\n  ❌ {len(errors)} 个异常，需修复')
    else:
        print(f'  ✅ 全部 {len(pairs)} 测试对通过')

    if not errors:
        # 2. SD
        print('\n【2】SD牌组一致性')
        count, bases = check_sd(pairs)
        ok = 313 in bases and len(bases) == 1
        print(f'  引用: {count}次 | 一致: {"✅" if ok else "❌"} | 基线: {bases}')

        # 3. 分类
        print('\n【3】分类统计')
        for cat, ids in CATEGORIES:
            deltas = [p['n']['final_score']-p['b']['final_score'] for p in pairs
                     if p['id'] in ids and p['n']['final_score']>p['b']['final_score']]
            ratios = [p['n']['final_score']/p['b']['final_score'] for p in pairs
                     if p['id'] in ids and p['n']['final_score']>p['b']['final_score']]
            if deltas:
                print(f'  {cat}:')
                print(f'    Delta {min(deltas):>10,} ~ {max(deltas):>10,}  '
                      f'均{sum(deltas)/len(deltas):>8,.0f}')
                print(f'    倍率 {min(ratios):>5.2f} ~ {max(ratios):>5.2f}  '
                      f'均{sum(ratios)/len(ratios):>.2f}')

        # 4. 纯效果
        print('\n【4】纯效果(无列/无喜干扰)')
        pure = [p for p in pairs if p['n']['col_total']==0 and p['n']['xi_x_prod']==1
                and p['n']['final_score']>p['b']['final_score']]
        pure_d = [p['n']['final_score']-p['b']['final_score'] for p in pure]
        if pure_d:
            print(f'  测试数: {len(pure)}')
            print(f'  Delta: {fmt(min(pure_d))} ~ {fmt(max(pure_d))}  '
                  f'均{fmt(int(sum(pure_d)/len(pure_d)))}')

        # 5. 排序
        print('\n【5】卡牌强度排序(纯效果均Delta)')
        avgs = card_avg(pairs)
        sorted_c = sorted(avgs.items(), key=lambda x: sum(x[1]['deltas'])/len(x[1]['deltas']))
        print('  最弱5:')
        for cid, s in sorted_c[:5]:
            avg = sum(s['deltas'])/len(s['deltas'])
            print(f'    {cid} {s["name"]}: {fmt(int(avg))}')
        print('  最强5:')
        for cid, s in sorted_c[-5:]:
            avg = sum(s['deltas'])/len(s['deltas'])
            print(f'    {cid} {s["name"]}: {fmt(int(avg))}')

    # 汇总
    print(f'\n📊 总计: {len(pairs)} 对 | 触发 {len([p for p in pairs if p["n"]["final_score"]>p["b"]["final_score"]])} '
          f'| 不触发 {len([p for p in pairs if p["n"]["final_score"]==p["b"]["final_score"]])} '
          f'| 异常 {len(errors)}')
    print(f'[{"PASS" if not errors else "FAIL"}] Review 完成')

if __name__ == '__main__':
    main()
