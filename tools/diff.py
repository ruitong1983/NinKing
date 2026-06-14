#!/usr/bin/env python3
"""
NinKing 测试数据 Python↔GDScript 交叉验证对比引擎

用法:
  python tools/diff.py [expected.json] [actual.json]

对比 expected.json（Python calc_engine 生成）与 actual.json（Godot test_runner.gd 输出）
逐字段报告差异，精确定位公式分歧所在。
"""

import json, sys, os


def load_cases(path):
    """Load {id: case_dict} from a JSON file."""
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return {c['id']: c for c in data['cases']}


def compare_groups(label, exp_grp, act_grp, case_id, diffs):
    """Compare a single group (head/mid/tail) field by field."""
    for field in ['card_chips', 'hand_chips', 'ench_chips', 'ninja_chips', 'chips_total',
                   'hand_mult', 'ench_mult', 'ninja_mult', 'mult_total', 'score']:
        ev = exp_grp.get(field)
        av = act_grp.get(field)
        if ev != av:
            diffs.append({
                'case': case_id,
                'field': f'{label}.{field}',
                'expected': ev,
                'actual': av,
                'delta': (av - ev) if isinstance(ev, int) and isinstance(av, int) else None,
            })

    # ninja_x_stack
    ex = list(exp_grp.get('ninja_x_stack', []))
    ax = list(act_grp.get('ninja_x_stack', []))
    if ex != ax:
        diffs.append({
            'case': case_id,
            'field': f'{label}.ninja_x_stack',
            'expected': ex,
            'actual': ax,
            'delta': None,
        })


def compare(expected_path, actual_path):
    """Main comparison. Returns (diffs, stats)."""
    exp_cases = load_cases(expected_path)
    act_cases = load_cases(actual_path)

    diffs = []
    matched = 0
    missing_in_actual = 0

    for case_id, exp in exp_cases.items():
        if case_id not in act_cases:
            missing_in_actual += 1
            diffs.append({'case': case_id, 'field': '**MISSING**',
                          'expected': 'present', 'actual': 'not found', 'delta': None})
            continue

        act = act_cases[case_id]

        # ── Hand types ──
        for g in ['head', 'mid', 'tail']:
            ev = exp['hand_types'].get(g)
            av = act['hand_types'].get(g)
            if ev != av:
                diffs.append({
                    'case': case_id,
                    'field': f'hand_types.{g}',
                    'expected': ev, 'actual': av,
                    'delta': (av - ev) if isinstance(ev, int) else None,
                })

        # ── Column types ──
        for i in range(3):
            ev = exp['col_types'][i]
            av = act['col_types'][i] if i < len(act.get('col_types', [])) else None
            if ev != av:
                diffs.append({
                    'case': case_id,
                    'field': f'col_types[{i}]',
                    'expected': ev, 'actual': av,
                    'delta': (av - ev) if isinstance(ev, int) and isinstance(av, int) else None,
                })

        # ── Per-group breakdown ──
        for g in ['head', 'mid', 'tail']:
            compare_groups(g, exp.get(g, {}), act.get(g, {}), case_id, diffs)

        # ── Column scores ──
        for i in range(3):
            ev = exp['col_scores'][i]
            av = act['col_scores'][i] if i < len(act.get('col_scores', [])) else None
            if ev != av:
                diffs.append({
                    'case': case_id,
                    'field': f'col_scores[{i}]',
                    'expected': ev, 'actual': av,
                    'delta': (av - ev) if isinstance(ev, int) and isinstance(av, int) else None,
                })

        # ── Top-level fields ──
        for field in ['col_total', 'total_raw', 'global_xi_x_prod', 'final_score']:
            ev = exp.get(field)
            av = act.get(field)
            if ev != av:
                diffs.append({
                    'case': case_id,
                    'field': field,
                    'expected': ev, 'actual': av,
                    'delta': (av - ev) if isinstance(ev, int) and isinstance(av, int) else None,
                })

        # ── xi_list ──
        ex_xi = sorted(exp.get('xi_list', []))
        ax_xi = sorted(act.get('xi_list', []))
        if ex_xi != ax_xi:
            diffs.append({
                'case': case_id,
                'field': 'xi_list',
                'expected': ex_xi, 'actual': ax_xi,
                'delta': None,
            })

        matched += 1

    # Summary
    total_diffs = len(diffs)
    field_diffs = len(set(d['field'] for d in diffs if not d['field'].startswith('**')))

    return {
        'diffs': diffs,
        'total_cases': len(exp_cases),
        'matched': matched,
        'missing_in_actual': missing_in_actual,
        'total_diffs': total_diffs,
        'unique_fields_affected': field_diffs,
    }


def print_report(stats):
    """Print a formatted report."""
    diffs = stats['diffs']

    print('=' * 72)
    print('  NinKing Python ↔ Godot 交叉验证报告')
    print('=' * 72)
    print(f'  总用例: {stats["total_cases"]}')
    print(f'  匹配成功: {stats["matched"]}')
    print(f'  Godot侧缺失: {stats["missing_in_actual"]}')
    print(f'  差异条目: {stats["total_diffs"]}')
    print(f'  涉及字段: {stats["unique_fields_affected"]}')

    if not diffs:
        print('\n  ✅ 全部一致 — Python calc_engine 与 GDScript score_calculator 输出完全相同')
        return

    # Group by field
    by_field = {}
    by_case = {}
    for d in diffs:
        f = d['field']
        if f not in by_field:
            by_field[f] = []
        by_field[f].append(d)
        cid = d['case']
        if cid not in by_case:
            by_case[cid] = []
        by_case[cid].append(d)

    # Per-field summary
    print('\n' + '-' * 72)
    print('  按字段分组:')
    for field, items in sorted(by_field.items()):
        print(f'\n  [{field}] — {len(items)} 处差异:')
        for item in items[:5]:
            d_str = f'Δ={item["delta"]}' if item['delta'] is not None else ''
            print(f'    {item["case"]}: expected={item["expected"]} actual={item["actual"]} {d_str}')
        if len(items) > 5:
            print(f'    ... 还有 {len(items)-5} 处')

    # Cases with most diffs
    print('\n' + '-' * 72)
    print('  差异最多的用例:')
    top_cases = sorted(by_case.items(), key=lambda x: -len(x[1]))[:10]
    for cid, items in top_cases:
        print(f'    {cid}: {len(items)} 字段不一致')

    print(f'\n  [{"PASS" if not diffs else "FAIL"}] 交叉验证{"通过" if not diffs else "发现差异"}')


def main():
    if len(sys.argv) >= 3:
        expected_path = sys.argv[1]
        actual_path = sys.argv[2]
    else:
        base = r'E:\Code\Godot_v4.6.2-stable_win64\NinKing\docs\ninking\testing'
        expected_path = os.path.join(base, 'expected.json')
        actual_path = os.path.join(base, 'actual.json')

    if not os.path.exists(actual_path):
        print(f'[INFO] actual.json 尚未生成: {actual_path}')
        print(f'       请先在 Godot debug 场景中运行 test_runner.gd')
        print(f'       输出保存到 {actual_path}')
        print()
        # Still validate expected.json exists
        if os.path.exists(expected_path):
            with open(expected_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            print(f'  expected.json: {len(data["cases"])} 个用例已就绪，等待 Godot 侧数据')
        return

    stats = compare(expected_path, actual_path)
    print_report(stats)


if __name__ == '__main__':
    main()
