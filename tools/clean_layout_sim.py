#!/usr/bin/env python3
"""
CL14 — 消除模式 3×3 网格蒙特卡洛模拟

模拟目标:
  1. 初始布局有效性概率 (9张无三连的概率)
  2. CleanLayoutGenerator 20次重试成功率
  3. 单次相邻交换的期望得分分布 (无忍者)
  4. 连锁波次分布
  5. 每封印(5 swaps)期望总分 → CL16 target 基线

作者:
  用法: python clean_layout_sim.py [--trials N] [--seeds N]

输出:
  - 初始布局统计
  - 单 swap 统计 (含波次明细)
  - 每封印(5 swaps) 统计
  - 推荐封印 target 值
"""
import random
import math
import sys
from collections import Counter
from dataclasses import dataclass, field
from typing import List, Tuple, Optional

# ══════════════════════════════════════════
# 常量
# ══════════════════════════════════════════

ROWS = 3
COLS = 3
GRID_SIZE = ROWS * COLS  # 9

# 标准 52 张牌
SUITS = ['♠', '♥', '♦', '♣']
RANKS = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]  # 11=J, 12=Q, 13=K, 14=A
RANK_NAMES = {2:"2",3:"3",4:"4",5:"5",6:"6",7:"7",8:"8",9:"9",10:"10",11:"J",12:"Q",13:"K",14:"A"}

# 规则常量
MAX_CHAIN = 10                # 硬编码连锁上限
SWAPS_PER_SEAL = 5            # clean_swaps_per_seal
CHAIN_MULT_CAP = 4            # chain_level 上限(倍率不再增长)

# ══════════════════════════════════════════
# 模拟引擎
# ══════════════════════════════════════════

def create_deck() -> List[Tuple[int, int]]:
    """生成标准 52 张牌, 每张为 (suit_index, rank_value)"""
    deck = []
    for s in range(4):
        for r in RANKS:
            deck.append((s, r))
    return deck


def grid_idx(row: int, col: int) -> int:
    return row * COLS + col


def row_col(idx: int) -> Tuple[int, int]:
    return (idx // COLS, idx % COLS)


def is_adjacent(idx1: int, idx2: int) -> bool:
    r1, c1 = row_col(idx1)
    r2, c2 = row_col(idx2)
    return abs(r1 - r2) + abs(c1 - c2) == 1


def all_adjacent_pairs() -> List[Tuple[int, int]]:
    """返回 3×3 网格中所有 12 个相邻对"""
    pairs = []
    for idx in range(GRID_SIZE):
        r, c = row_col(idx)
        # 右邻 (col+1)
        if c + 1 < COLS:
            pairs.append((idx, grid_idx(r, c + 1)))
        # 下邻 (row+1)
        if r + 1 < ROWS:
            pairs.append((idx, grid_idx(r + 1, c)))
    return pairs


ADJACENT_PAIRS = all_adjacent_pairs()


def detect_matches(grid: List[Optional[Tuple[int,int]]]) -> List[dict]:
    """检测 3×3 网格中所有行/列三连匹配。

    返回 list of dicts, 每个 dict:
      {'type': 'row'|'col', 'index': int, 'positions': list[int], 'rank': int}
    """
    result = []
    if len(grid) < GRID_SIZE:
        return result

    # 行检测
    for r in range(ROWS):
        i0 = grid_idx(r, 0)
        i1 = grid_idx(r, 1)
        i2 = grid_idx(r, 2)
        c0, c1, c2 = grid[i0], grid[i1], grid[i2]
        if c0 is None or c1 is None or c2 is None:
            continue
        if c0[1] == c1[1] == c2[1]:
            result.append({'type': 'row', 'index': r,
                           'positions': [i0, i1, i2], 'rank': c0[1]})

    # 列检测
    for c in range(COLS):
        i0 = grid_idx(0, c)
        i1 = grid_idx(1, c)
        i2 = grid_idx(2, c)
        c0, c1, c2 = grid[i0], grid[i1], grid[i2]
        if c0 is None or c1 is None or c2 is None:
            continue
        if c0[1] == c1[1] == c2[1]:
            result.append({'type': 'col', 'index': c,
                           'positions': [i0, i1, i2], 'rank': c0[1]})

    return result


def is_valid_layout(grid: List[Optional[Tuple[int,int]]]) -> bool:
    """验证 3×3 网格无三连 (无预消除)"""
    return len(detect_matches(grid)) == 0


def chain_multiplier(chain_level: int) -> float:
    """连锁倍率: 1.0 → 1.5 → 2.0 → 2.5 (上限)"""
    level = min(chain_level, CHAIN_MULT_CAP)
    return 1.0 + (level - 1) * 0.5


def score_wave(matches: List[dict], chain_level: int) -> int:
    """计算一波消除得分: Σ(rank×10) × chain_mult"""
    raw = sum(m['rank'] * 10 for m in matches)
    cm = chain_multiplier(chain_level)
    return int(raw * cm)


def apply_chain_wave(grid: List[Optional[Tuple[int,int]]],
                     deck: List[Tuple[int,int]],
                     discard: List[Tuple[int,int]]) -> Tuple[List[dict], int]:
    """执行一波消除: 检测 → 移除 → 重力 → 补牌。

    Args:
        grid: 当前 3×3 网格 (会被修改)
        deck: 牌组 (draw 时从末尾弹出)
        discard: 弃牌堆 (被移除的牌加入此列表)

    Returns:
        (matches, wave_score): (检测到的匹配, 本波得分)
        若无匹配则返回 ([], 0)
    """
    matches = detect_matches(grid)
    if not matches:
        return [], 0

    # 收集唯一位置
    positions_to_remove = set()
    for m in matches:
        positions_to_remove.update(m['positions'])

    # 移除匹配牌 → 弃牌堆
    for pos in sorted(positions_to_remove, reverse=True):
        card = grid[pos]
        if card is not None:
            discard.append(card)
        grid[pos] = None

    # 重力下落: 每列从下往上收集 > 从下往上填入
    for c in range(COLS):
        column_cards = []
        for r in range(ROWS - 1, -1, -1):
            card = grid[grid_idx(r, c)]
            if card is not None:
                column_cards.append(card)

        # 从底部往上填
        write_row = ROWS - 1
        for card in column_cards:
            grid[grid_idx(write_row, c)] = card
            write_row -= 1

        # 顶部空位补新牌
        empty_count = write_row + 1
        for fill_row in range(write_row, -1, -1):
            if deck:
                new_card = deck.pop()
                grid[grid_idx(fill_row, c)] = new_card
            else:
                grid[grid_idx(fill_row, c)] = None

    return matches, 0  # 分数需要 chain_level, 在外层计算


def simulate_one_swap(grid: List[Optional[Tuple[int,int]]],
                      deck: List[Tuple[int,int]],
                      discard: List[Tuple[int,int]],
                      src: int, tgt: int) -> dict:
    """模拟一次相邻交换 + 完整连锁消除。

    Args:
        grid: 当前网格 (会被修改)
        deck: 牌组 (draw 时修改)
        discard: 弃牌堆
        src, tgt: 交换位置

    Returns:
        dict: {score, chain_len, wave_scores, wasted, matches_per_wave}
    """
    # 执行交换
    grid[src], grid[tgt] = grid[tgt], grid[src]

    # 第一波检测
    first_matches = detect_matches(grid)
    if not first_matches:
        return {'score': 0, 'chain_len': 0, 'wave_scores': [],
                'wasted': True, 'matches_per_wave': []}

    wave_scores = []
    matches_per_wave = []
    chain_level = 0

    while True:
        matches = detect_matches(grid)
        if not matches:
            break

        chain_level += 1

        # 收集唯一移除位置
        remove_pos = set()
        for m in matches:
            remove_pos.update(m['positions'])

        # 算分
        ws = score_wave(matches, chain_level)
        wave_scores.append(ws)
        matches_per_wave.append(len(matches))

        # 移除匹配牌
        for pos in sorted(remove_pos, reverse=True):
            card = grid[pos]
            if card is not None:
                discard.append(card)
            grid[pos] = None

        # 重力下落 + 补牌
        for c in range(COLS):
            column_cards = []
            for r in range(ROWS - 1, -1, -1):
                card = grid[grid_idx(r, c)]
                if card is not None:
                    column_cards.append(card)

            write_row = ROWS - 1
            for card in column_cards:
                grid[grid_idx(write_row, c)] = card
                write_row -= 1

            empty_count = write_row + 1
            for fill_row in range(write_row, -1, -1):
                if deck:
                    grid[grid_idx(fill_row, c)] = deck.pop()
                else:
                    grid[grid_idx(fill_row, c)] = None

        # 连锁上限
        if chain_level >= MAX_CHAIN:
            break

    return {
        'score': sum(wave_scores),
        'chain_len': chain_level,
        'wave_scores': wave_scores,
        'wasted': False,
        'matches_per_wave': matches_per_wave,
    }


# ══════════════════════════════════════════
# 初始布局模拟
# ══════════════════════════════════════════

def simulate_initial_layout(trials: int = 100000) -> dict:
    """模拟随机 9 张牌放入 3×3 网格的无三连概率."""
    valid_count = 0
    rank_dist = Counter()
    retry_needed = Counter()  # 每次有效布局前失败几次

    for _ in range(trials):
        deck = create_deck()
        random.shuffle(deck)
        drawn = deck[:9]
        grid = drawn[:]  # row-major

        # 记录 rank 分布
        for card in grid:
            rank_dist[card[1]] += 1

        if is_valid_layout(grid):
            valid_count += 1

    p_valid = valid_count / trials
    return {
        'trials': trials,
        'valid_count': valid_count,
        'p_valid': p_valid,
        'p_invalid': 1.0 - p_valid,
    }


def simulate_retry_strategy(trials: int = 100000) -> dict:
    """模拟 CleanLayoutGenerator 的 20 次重试策略成功率.

    Godot 实现每次 draw(9) → 检测 → 无效则 discard 重来.
    """
    success_count = 0
    fail_count = 0
    retries_used = Counter()

    for _ in range(trials):
        deck = create_deck()
        random.shuffle(deck)
        # 复制一份 deck 用于多次尝试
        # 每次尝试消耗 9 张(抽出来) → 不成功的放回 discard
        # 为简化: 每次尝试从新洗牌的小样本模拟
        success = False
        for attempt in range(20):
            # 从一副完整牌中抽 9 张 (模拟 discard+draw fresh)
            deck_copy = create_deck()
            random.shuffle(deck_copy)
            drawn = deck_copy[:9]
            if is_valid_layout(drawn):
                success_count += 1
                retries_used[attempt] += 1
                success = True
                break
        if not success:
            fail_count += 1

    return {
        'trials': trials,
        'success_rate': success_count / trials,
        'fail_rate': fail_count / trials,
        'retry_distribution': dict(retries_used),
        'avg_retries': sum(k * v for k, v in retries_used.items()) / max(success_count, 1),
    }


# ══════════════════════════════════════════
# 单 swap 模拟 (从有效布局出发)
# ══════════════════════════════════════════

def simulate_swaps(trials: int = 50000) -> dict:
    """从有效布局出发, 枚举所有 12 种相邻交换, 执行最高分交换.

    每次模拟：
      1. 生成有效初始布局
      2. 枚举 12 个相邻交换 → 对有匹配的交换, 执行 chain 计分
      3. 选择最高分的交换 (作为"最优玩家"策略)
      4. 记录本次 swap 所有统计

    Returns:
        best_swap: 最佳交换的统计 (玩家会选择的最佳)
        all_valid: 所有有效交换的聚合 (数据参考)
        wasted_pct: 无效交换比例 (12个中多少个没匹配)
    """
    best_results = {'scores': [], 'chain_lens': [], 'wave_counts': []}
    all_valid_results = {'scores': [], 'chain_lens': [], 'wave_counts': []}
    total_swaps_considered = 0
    wasted_swaps = 0

    for t in range(trials):
        if t > 0 and t % 10000 == 0:
            print(f"  swap sim: {t}/{trials}")

        # 生成有效初始布局
        deck = create_deck()
        random.shuffle(deck)
        drawn = deck[:9]
        if not is_valid_layout(drawn):
            # 重试一次
            for _ in range(20):
                deck2 = create_deck()
                random.shuffle(deck2)
                drawn = deck2[:9]
                if is_valid_layout(drawn):
                    break
            else:
                continue  # 20次都失败 → 跳过

        # 对每种相邻交换, 模拟得分
        best_score = -1
        best_chain = 0
        best_waves = []

        for src, tgt in ADJACENT_PAIRS:
            # 深拷贝网格和牌组
            grid_copy = list(drawn)
            deck_copy = list(deck[9:])  # 剩余牌
            random.shuffle(deck_copy)   # 模拟牌组随机顺序
            discard_copy = []

            result = simulate_one_swap(grid_copy, deck_copy, discard_copy,
                                        src, tgt)
            total_swaps_considered += 1

            if result['wasted']:
                wasted_swaps += 1
            else:
                s = result['score']
                cl = result['chain_len']
                wc = len(result['wave_scores'])
                all_valid_results['scores'].append(s)
                all_valid_results['chain_lens'].append(cl)
                all_valid_results['wave_counts'].append(wc)

                if s > best_score:
                    best_score = s
                    best_chain = cl
                    best_waves = result['wave_scores']

        if best_score > 0:
            best_results['scores'].append(best_score)
            best_results['chain_lens'].append(best_chain)
            best_results['wave_counts'].append(len(best_waves))

    return {
        'best': {
            'count': len(best_results['scores']),
            'scores': best_results['scores'],
            'chain_lens': best_results['chain_lens'],
            'wave_counts': best_results['wave_counts'],
        },
        'all_valid': {
            'count': len(all_valid_results['scores']),
            'scores': all_valid_results['scores'],
            'chain_lens': all_valid_results['chain_lens'],
            'wave_counts': all_valid_results['wave_counts'],
        },
        'total_considered': total_swaps_considered,
        'wasted_count': wasted_swaps,
        'wasted_pct': wasted_swaps / max(total_swaps_considered, 1) * 100,
    }


# ══════════════════════════════════════════
# 每封印模拟 (5次连续swap)
# ══════════════════════════════════════════

def simulate_one_seal(initial_grid: List[Optional[Tuple[int,int]]],
                      deck: List[Tuple[int,int]],
                      strategy: str = 'greedy') -> dict:
    """模拟一整个封印的 5 次交换 (无忍者/无经济).

    strategy:
      'greedy' — 每次选择最高分的相邻交换
      'random' — 随机选一个有效交换
    """
    grid = list(initial_grid)
    deck_remaining = list(deck)
    random.shuffle(deck_remaining)
    discard = []
    swap_log = []
    total_score = 0

    for swap_num in range(SWAPS_PER_SEAL):
        best_score = -1
        best_result = None
        best_src_tgt = None

        for src, tgt in ADJACENT_PAIRS:
            g_copy = list(grid)
            d_copy = list(deck_remaining)
            random.shuffle(d_copy)
            di_copy = list(discard)

            result = simulate_one_swap(g_copy, d_copy, di_copy, src, tgt)

            if strategy == 'greedy':
                if result['score'] > best_score:
                    best_score = result['score']
                    best_result = result
                    best_src_tgt = (src, tgt)

        if best_result is None or best_result['wasted']:
            # 无可得分交换 → 随机找一个交换
            for src, tgt in ADJACENT_PAIRS:
                grid[src], grid[tgt] = grid[tgt], grid[src]
                swap_log.append({
                    'swap': swap_num, 'score': 0, 'chain_len': 0,
                    'wasted': True, 'wave_scores': [],
                    'src': src, 'tgt': tgt,
                })
                break
            continue

        # 执行最佳交换 (直接在真实 grid 上重做一次)
        src, tgt = best_src_tgt
        result = simulate_one_swap(grid, deck_remaining, discard, src, tgt)
        total_score += result['score']
        swap_log.append({
            'swap': swap_num,
            'score': result['score'],
            'chain_len': result['chain_len'],
            'wave_scores': result['wave_scores'],
            'wasted': False,
            'src': src,
            'tgt': tgt,
        })

    return {
        'total_score': total_score,
        'swap_log': swap_log,
        'final_grid': grid,
    }


def simulate_many_seals(trials: int = 20000) -> dict:
    """模拟多轮完整封印."""
    scores = []
    chain_lens_per_swap = []
    scores_per_swap = []
    wasted_swap_count = 0
    total_swaps = 0
    chain_wave_count = Counter()

    for t in range(trials):
        if t > 0 and t % 5000 == 0:
            print(f"  seal sim: {t}/{trials}")

        # 生成有效初始布局
        deck_full = create_deck()
        random.shuffle(deck_full)
        drawn = deck_full[:9]
        retries = 0
        while not is_valid_layout(drawn) and retries < 20:
            deck_full = create_deck()
            random.shuffle(deck_full)
            drawn = deck_full[:9]
            retries += 1
        if retries >= 20:
            continue

        remaining = deck_full[9:]
        random.shuffle(remaining)

        result = simulate_one_seal(drawn, remaining, 'greedy')
        scores.append(result['total_score'])

        for sl in result['swap_log']:
            total_swaps += 1
            scores_per_swap.append(sl['score'])
            chain_lens_per_swap.append(sl['chain_len'])
            if sl['wasted']:
                wasted_swap_count += 1
            for i, ws in enumerate(sl['wave_scores']):
                chain_wave_count[i] += 1

    scores.sort()
    scores_per_swap.sort()

    def percentile(data, p):
        if not data:
            return 0
        idx = int(len(data) * p / 100)
        return data[min(idx, len(data) - 1)]

    return {
        'trials': len(scores),
        'seal_scores': {
            'count': len(scores),
            'min': min(scores) if scores else 0,
            'max': max(scores) if scores else 0,
            'avg': sum(scores) / max(len(scores), 1),
            'median': percentile(scores, 50),
            'p10': percentile(scores, 10),
            'p25': percentile(scores, 25),
            'p75': percentile(scores, 75),
            'p90': percentile(scores, 90),
        },
        'per_swap': {
            'count': len(scores_per_swap),
            'avg': sum(scores_per_swap) / max(len(scores_per_swap), 1),
            'median': percentile(scores_per_swap, 50),
            'p10': percentile(scores_per_swap, 10),
            'p90': percentile(scores_per_swap, 90),
            'wasted_pct': wasted_swap_count / max(total_swaps, 1) * 100,
        },
        'chain': {
            'avg_len': sum(chain_lens_per_swap) / max(len(chain_lens_per_swap), 1),
            'wave_distribution': {str(k): v for k, v in sorted(chain_wave_count.items())},
        },
    }


# ══════════════════════════════════════════
# 输出格式化
# ══════════════════════════════════════════

def fmt_pct(v: float) -> str:
    return f"{v * 100:.2f}%"


def fmt_num(v: float) -> str:
    return f"{v:,.1f}"


def print_report(init_result: dict, retry_result: dict,
                 swap_result: dict, seal_result: dict) -> None:
    """输出完整模拟报告."""
    print("=" * 65)
    print("  CL14 消除模式蒙特卡洛模拟报告")
    print("=" * 65)
    print()

    # ── 初始布局 ──
    print("─" * 65)
    print("  一、初始布局有效性")
    print("─" * 65)
    if init_result:
        p = init_result['p_valid']
        print(f"    试验次数:       {init_result['trials']:,}")
        print(f"    有效布局:       {init_result['valid_count']:,}")
        print(f"    有效概率:       {fmt_pct(p)}")
        print(f"    无效概率:       {fmt_pct(p)} (即 init 有三连)")
        # 反向
        print(f"    无效概率(直接): {fmt_pct(1.0 - p)}")
        print(f"    平均每 {1/max(p, 0.001):.1f} 次抽牌有 1 次有效")
        print()

    if retry_result:
        sr = retry_result['success_rate']
        fr = retry_result['fail_rate']
        print(f"  20 次重试成功率: {fmt_pct(sr)}")
        print(f"  20 次重试失败率: {fmt_pct(fr)}")
        print(f"  失败时最多接受任意布局 (当前 Godot impl)")
        if retry_result['avg_retries'] > 0:
            print(f"  平均重试次数:    {retry_result['avg_retries']:.2f}")
        print()

    # ── 单次 swap ──
    print("─" * 65)
    print("  二、单次相邻交换统计 (无忍者)")
    print("─" * 65)
    if swap_result:
        b = swap_result['best']
        av = swap_result['all_valid']

        def describe_swap_stats(label: str, d: dict) -> None:
            scores = d['scores']
            if not scores:
                print(f"    {label}: 无数据")
                return
            scores.sort()
            p10 = scores[int(len(scores) * 0.1)]
            p50 = scores[int(len(scores) * 0.5)]
            p90 = scores[int(len(scores) * 0.9)]
            avg = sum(scores) / len(scores)
            chains = d['chain_lens']
            avg_chain = sum(chains) / len(chains) if chains else 0
            waves = d['wave_counts']
            avg_waves = sum(waves) / len(waves) if waves else 0

            print(f"    [{label}] 样本: {len(scores):,}")
            print(f"      得分: avg={avg:.0f}  P10={p10}  P50={p50}  P90={p90}")
            print(f"      平均连锁波次: {avg_waves:.2f}")
            print(f"      平均 chain_len: {avg_chain:.2f}")
            print()

        print(f"    总考察交换数: {swap_result['total_considered']:,}")
        print(f"    无效交换占比:  {swap_result['wasted_pct']:.1f}% (交换后无三连)")
        print()
        describe_swap_stats("最佳交换 (玩家选择)", b)
        describe_swap_stats("全部有效交换", av)

    # ── 每封印 ──
    print("─" * 65)
    print("  三、每封印 5 次交换模拟 (greedy 策略)")
    print("─" * 65)
    if seal_result:
        ss = seal_result['seal_scores']
        ps = seal_result['per_swap']
        ch = seal_result['chain']

        print(f"    模拟封印数:    {ss['count']:,}")
        print(f"    ── 封印总分 ──")
        print(f"      avg = {ss['avg']:>8.0f}")
        print(f"      P10 = {ss['p10']:>8.0f}")
        print(f"      P25 = {ss['p25']:>8.0f}")
        print(f"      P50(中位数) = {ss['median']:>8.0f}")
        print(f"      P75 = {ss['p75']:>8.0f}")
        print(f"      P90 = {ss['p90']:>8.0f}")
        print(f"      min = {ss['min']:>8.0f}")
        print(f"      max = {ss['max']:>8.0f}")
        print()
        print(f"    ── 单次 swap ──")
        print(f"      avg 得分 = {ps['avg']:>8.0f}")
        print(f"      P10 = {ps['p10']:>8.0f}")
        print(f"      P50 = {ps['median']:>8.0f}")
        print(f"      P90 = {ps['p90']:>8.0f}")
        print(f"      无效swap占比 = {ps['wasted_pct']:.1f}%")
        print()
        print(f"    ── 连锁波次 ──")
        print(f"      平均 chain_len = {ch['avg_len']:.2f}")
        print(f"      波次分布 (波次索引 → 触发次数):")
        for k, v in sorted(ch['wave_distribution'].items(),
                           key=lambda x: int(x[0])):
            pct = v / max(ps['count'], 1) * 100
            print(f"        波次 {int(k)+1}: {v} 次 ({pct:.1f}%)")

    print()
    print("─" * 65)
    print("  四、CL16 推荐封印 target 基线 (基于 avg, 无忍者)")
    print("─" * 65)
    if seal_result:
        avg_seal = ss['avg']
        p10_seal = ss['p10']
        p50_seal = ss['median']
        p90_seal = ss['p90']

        # 推荐 target: P50 附近, 略低于 P50 保证 50%+ 通关率
        # 序(初关): P50 附近, 让大部分玩家能过
        # 破(二关): P50~P75 之间
        # 急(三关): P75~P90 之间
        # 结界 3-8: 每结界 ×1.5~1.6 增长
        base_p50 = max(p50_seal, 100)  # 防止 0

        print(f"    裸打基线 (无忍者, greedy 策略):")
        print(f"      avg={avg_seal:.0f}  P50={p50_seal}  P10={p10_seal}  P90={p90_seal}")
        print()

        # 按设计文档的 extrapolation 公式推算 24 个 target
        growth = 1.6  # 每结界增长系数
        # 壱·序 = 基准 P50
        targets = []
        seal_names = ['序', '破', '急']
        for barrier in range(8):
            for si, sn in enumerate(seal_names):
                # 壱·序 取 P50; 壱·破取 avg; 壱·急取 P75 附近
                if barrier == 0 and si == 0:
                    raw = base_p50
                elif barrier == 0 and si == 1:
                    raw = (base_p50 + avg_seal) / 2  # P50 和 avg 之间
                elif barrier == 0 and si == 2:
                    raw = avg_seal * 1.3
                else:
                    raw = targets[-1][1] * growth

                # 取整到 50
                target = int(round(raw / 50) * 50)
                targets.append(((barrier + 1, sn), target))

        print(f"    结界增长系数: ×{growth} / 封印")
        print(f"    建议 target 表 (取整到 50):")
        print(f"    ┌────────┬─────────┬─────────┬─────────┐")
        print(f"    │ 結界   │ 序      │ 破      │ 急      │")
        print(f"    ├────────┼─────────┼─────────┼─────────┤")
        for b in range(8):
            row = targets[b * 3:(b + 1) * 3]
            barrier_nums = ['壱', '弐', '参', '肆', '伍', '陸', '漆', '捌']
            vals = [f"{t[1]:>7}" for t in row]
            print(f"    │ {barrier_nums[b]}      │ {vals[0]} │ {vals[1]} │ {vals[2]} │")
        print(f"    └────────┴─────────┴─────────┴─────────┘")
        print()
        print(f"    ⚠️  说明:")
        print(f"    - 以上为无忍者裸打基线, 实际玩家有忍者加成后 target 可上调")
        print(f"    - 若平均 2 个有效忍者贡献 +30% 得分 → target ×1.3")
        print(f"    - CL15 经济审计完成后, target 需结合忍者因素重新校准")
        print(f"    - 当前值未考虑封印主效果干扰 (如 scatter_king 排除 K)")

    print("=" * 65)


# ══════════════════════════════════════════
# 主入口
# ══════════════════════════════════════════

def main():
    trials_init = 200000
    trials_swap = 50000
    trials_seal = 20000

    # 解析命令行参数
    args = sys.argv[1:]
    for i, arg in enumerate(args):
        if arg == '--trials' and i + 1 < len(args):
            trials_swap = int(args[i + 1])
            trials_seal = max(1000, trials_swap // 2)
        if arg == '--seeds' and i + 1 < len(args):
            trials_init = int(args[i + 1])

    print(f"参数: init_trials={trials_init:,}  swap_trials={trials_swap:,}  seal_trials={trials_seal:,}")
    print()

    # Phase 1: 初始布局
    print("[Phase 1/3] 初始布局概率模拟...")
    init_result = simulate_initial_layout(trials_init)
    print(f"  有效概率: {fmt_pct(init_result['p_valid'])}")
    print()

    # Phase 1b: 重试策略
    print("[Phase 1b] 20 次重试策略模拟...")
    retry_result = simulate_retry_strategy(min(trials_init, 50000))
    print(f"  成功率: {fmt_pct(retry_result['success_rate'])}")
    print()

    # Phase 2: 单次 swap
    print("[Phase 2/3] 单次交换模拟...")
    swap_result = simulate_swaps(trials_swap)
    b = swap_result['best']
    if b['scores']:
        print(f"  最佳交换: avg={sum(b['scores'])/len(b['scores']):.0f}  N={len(b['scores']):,}")
    print()

    # Phase 3: 每封印
    print("[Phase 3/3] 每封印模拟...")
    seal_result = simulate_many_seals(trials_seal)
    print(f"  完成: {seal_result['seal_scores']['count']:,} 封印")
    print()

    # 输出报告
    print("\n" * 2)
    print_report(init_result, retry_result, swap_result, seal_result)


if __name__ == '__main__':
    main()
