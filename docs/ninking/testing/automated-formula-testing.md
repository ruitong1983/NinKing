# 自动计分公式测试方法论

> **目标:** 每次数值/机制变更后，自动验证计分公式的正确性
> **频率:** 每日构建测试数据 → Review → 修复
> **核心工具:** `tools/gen_test_v2.py` + `ninja-test-full.csv` + `ninja-test-viewer.html`

---

## 1. 测试架构总览

```
┌──────────────────────────────────────────────────────┐
│                   Game Data                           │
│  ninja_data.gd / card_data.gd / scoring_formula.gd   │
└──────────────┬───────────────────────────────────────┘
               │ 效果值 / 条件 / 机制
               ▼
┌──────────────────────────────────────────────────────┐
│              gen_test_v2.py (生成器)                   │
│                                                      │
│  calc() ← 纯Python实现，与GDScript公式逻辑1:1对应      │
│  tc()   ← 每张卡的测试用例定义                         │
│  mkrow()→ CSV行输出                                  │
└──────────────┬───────────────────────────────────────┘
               │ CSV (312行)
               ▼
┌──────────────────────────────────────────────────────┐
│              验证层                                    │
│                                                      │
│  1. Delta验证 ← 生成器内置，触发/不触发检测             │
│  2. Review报告 ← python分析脚本                        │
│  3. Debug场景 ← Godot运行时对比 CSV 预测值              │
└──────────────────────────────────────────────────────┘
```

---

## 2. 每日工作流程

### 2.1 流程总图

```
   ┌──────────────┐
   │ 修改卡牌数据  │ ← ninja_data.gd / 公式调整
   └──────┬───────┘
          ▼
   ┌──────────────┐
   │ 同步生成器    │ ← 更新 gen_test_v2.py 中的 ne/条件/测试用例
   └──────┬───────┘
          ▼
   ┌──────────────┐
   │ 重生成CSV     │ ← python gen_test_v2.py
   └──────┬───────┘
          ▼
   ┌──────────────┐
   │ Delta验证     │ ← 生成器自动检查
   └──────┬───────┘
          ▼
   ┌──────────────┐
   │ Review报告    │ ← 分析异常 / 分布 / 一致性
   └──────┬───────┘
          ▼
   ┌──────────────┐
   │ Debug验证     │ ← 可选：Godot运行时对账
   └──────┬───────┘
          ▼
   ┌──────────────┐
   │ 文档同步      │ ← 更新测试计划.md + viewer.html
   └──────────────┘
```

### 2.2 步骤详解

#### Step 1: 同步卡牌数据

修改 `ninja_data.gd` 后，将变更同步到 `gen_test_v2.py`：

| 变更类型 | 同步动作 | 示例 |
|---------|---------|------|
| 效果值调整 | 更新 `tc()` 中 `ne` 的 c/m/x 值 | `+10c → +15c` |
| 条件逻辑变更 | 更新测试用例牌组设计 | 触发条件从"头≤对子"改为"头≤顺子" |
| 新增卡牌 | 按模板添加 `tc()` 调用 | 见 §3 |
| 删除/废弃卡牌 | 删除对应 `tc()` + 标记文档 | |

#### Step 2: 设计测试用例原则

每张卡最少 **5 组测试**（3 基础 + 2 扩展）：

| 测试号 | 类型 | 目的 | 设计要点 |
|:-----:|------|------|---------|
| **T1** | 主要激活 | 验证效果正常触发 | 典型触发场景，低牌型（避喜） |
| **T2** | 边界/补充 | 验证另一触发路径 | 不同牌型/不同条件满足方式 |
| **T3** | 不触发(可选) | 验证条件检测正确 | 条件不满足时 Delta=0 |
| **T4** | 新路径/高强度 | 验证高牌型下效果 | 豹/同花顺/同花混搭 |
| **T5** | 喜联动/高列乘 | 验证喜系统叠加 | 全♠牌组 / 三列豹 |

#### Step 3: 工具函数速查

```python
# 三组相同效果
ne_all(c=10, m=0, x=[])     # 全组 +10 chips
ne_all(x=[2])               # 全组 ×2

# 部分组有效果（缺省归零）
ne_partial(h={'m':5})                # 仅头组 +5 mult
ne_partial(t={'x':[2]})              # 仅尾组 ×2
ne_partial(h={'c':15,'m':3}, m={'c':15,'m':3})  # 头中两组

# 无效果
no_ninja()  # 用于不触发测试

# 特殊参数
xi_bonus=1        # 喜鹊：每喜×mult +1
xi_override={'三清': 3}  # 清一色：三清×3
```

#### Step 4: 重生成 CSV

```bash
python tools/gen_test_v2.py
```

生成器会自动进行 Delta 验证，输出格式：

```
n_001 手里剑 T1: final 296→416 Δ=120 [OK]
n_g01 虎头 T3: final 179712→179712 Δ=0 [OK] 不触发
```

**检查重点：**
- `[OK]` = Delta 符合预期
- 触发测试（T1/T2/T4/T5）必须有 Δ>0
- 不触发测试（T3/no_ninja）必须有 Δ=0

#### Step 5: Review 报告

运行分析脚本生成 Review：

```bash
# 完整报告
python tools/review_test_data.py

# 或用内联分析
python -c "见 §5 模板"
```

#### Step 6: Debug 场景验证（可选）

在 Godot 中加载 `ninking_debug.tscn`，手动输入测试牌组，对比 CSV 预测值。

---

## 3. 新增卡牌的测试模板

### 3.1 卡牌数据结构

```python
# 一张卡 5-6 组测试
# 无条件类 (通用加成)
total_delta += tc('n_xxx','卡牌名','T1','主测试说明',
    ['♠2','♥7','♦J'],   # 头组3张
    ['♣4','♠9','♥Q'],   # 中组3张
    ['♣3','♠6','♥K'],   # 尾组3张
    ne_all(c=10))        # 效果

# 条件触发类
tc('n_xxx','卡牌名','T1','触发说明',
    ['♠2','♥5','♦9'], ['♣4','♠7','♥10'], ['♦J','♦Q','♦K'],
    ne_partial(t={'x':[2]}))  # 仅尾组×2

tc('n_xxx','卡牌名','T3','不触发说明',
    ['♠2','♥7','♦J'], ['♣4','♠9','♥Q'], ['♣3','♠6','♥K'],
    no_ninja())  # 不触发
```

### 3.2 牌组设计避坑指南

| 要避免的坑 | 原因 | 正确做法 |
|-----------|------|---------|
| 9 张牌有重复 | 同一副牌不能有相同花色+点数 | 用 `check_no_dup()` 验证 |
| 意外触发全同花 | 9 张同花色 → 喜干扰 | 混用花色或用 `全♠` 有意图 |
| 意外触发全顺 | 9 张连续点数 → 喜干扰 | 在点数组中留断点 |
| 意外触发四张 | 4 张同点数 → 喜干扰 | 控制最多3张同点数 |
| 列顺下的高基线 | 列顺×16 放大基数 | 区分"纯效果"和"复合效果" |

### 3.3 标准"安全牌组" (SD)

```python
# 无喜干扰、列顺×16 的标准牌组
SD = ['♠2','♥7','♦J'], ['♣4','♠9','♥Q'], ['♣3','♠6','♥K']
# 特点：全散牌，列0顺×4，列1散，列2顺×4 → 基线 1216
# 适用于：成长卡/通用卡的基线对比
```

### 3.4 专用测试牌组

```python
# 三列豹牌组（极限列乘验证）
['♠3','♥7','♦J'], ['♦3','♠7','♥J'], ['♣3','♣7','♠J']
# 3个点数各3张 → 三列都豹×32 + 全三条×4 → 放大×131072

# 全♠牌组（喜叠加验证）
['♠2','♠5','♠9'], ['♠3','♠7','♠J'], ['♠4','♠8','♠K']
# 全♠ → 全同花×3 + 全黑×2 + 三清×2

# 高强度混合牌组（高牌型验证）
['♠J','♥J','♦J'], ['♥Q','♥K','♥A'], ['♠3','♠7','♠9']
# 头豹(5) + 中同花顺(4) + 尾同花(3)
```

---

## 4. Review 检查清单

每次审查必须逐项确认：

### 4.1 Delta 正确性

```
□ 所有触发测试 Δ > 0
□ 所有不触发测试 Δ = 0
□ 无得分降低的测试（Δ < 0）
□ 同卡内 T1 > T3（触发 > 不触发）
```

### 4.2 数据一致性

```
□ SD 牌组基线得分均为 1216（全散+列顺×16）
□ 相同牌组在不同卡之间基线一致
□ 同卡同名测试 desc 一致
```

### 4.3 公式边界

```
□ 最高分 < 2^31（INT32 不溢出）
□ 最低分 > 0（无归零）
□ 列乘/喜乘复合后得分合理（无意外爆炸）
```

### 4.4 覆盖率

```
□ 每卡 ≥ 5 组测试（3基础+2扩展）
□ 覆盖率 ≥ 80%（不可测卡需注明原因）
□ 新修改的卡优先覆盖
```

---

## 5. Review 分析脚本模板

### 5.1 快捷分析

```python
# 每次修改后运行
python -c "
import csv
rows = []
with open('docs/ninking/testing/ninja-test-full.csv','r',encoding='utf-8-sig') as f:
    for r in csv.DictReader(f):
        r['final_score'] = int(r['final_score'])
        rows.append(r)
pairs = {}
for r in rows:
    k = (r['card_id'],r['test_no'])
    if k not in pairs: pairs[k] = {'b':None,'n':None,'id':r['card_id'],'name':r['card_name'],'tno':r['test_no']}
    if r['version']=='baseline': pairs[k]['b']=r
    else: pairs[k]['n']=r

# 1. 异常检测
no_effect = {('n_g01','T3'),('n_g01','T5'),('n_g02','T3'),('n_g02','T6'),
             ('n_g04','T3'),('n_g04','T4'),('n_g04','T5'),('n_g05','T3'),
             ('n_g05','T6'),('n_g06','T3'),('n_x01','T3'),('n_x03','T3'),
             ('n_x06','T3'),('n_c01','T3'),('n_f01','T2'),('n_f02','T3'),
             ('n_r03','T3'),('n_s01','T3'),('n_s02','T3'),('n_s03','T3'),
             ('n_s05','T3'),('n_s06','T3')}
errors = []
for p in pairs.values():
    if not p['b'] or not p['n']: continue
    d = p['n']['final_score']-p['b']['final_score']
    ne = (p['id'],p['tno']) in no_effect
    if ne and d!=0: errors.append(f'[FAIL] {p[\"id\"]} {p[\"name\"]} {p[\"tno\"]}: 不触发Δ={d}')
    if not ne and d==0: errors.append(f'[FAIL] {p[\"id\"]} {p[\"name\"]} {p[\"tno\"]}: 触发Δ=0')
print(f'共{len(pairs)}测试对, 异常{len(errors)}' if errors else f'共{len(pairs)}测试对, 全部正确')
for e in errors: print(e)
"
```

### 5.2 完整报告（保存为 `tools/review_test_data.py`）

```python
#!/usr/bin/env python3
"""
NinKing 测试数据 Review 报告生成器
用例: python tools/review_test_data.py
"""
import csv, statistics, sys

def load_csv(path='docs/ninking/testing/ninja-test-full.csv'):
    """加载CSV并配成(baseline, with_ninja)对"""
    rows = []
    with open(path, 'r', encoding='utf-8-sig') as f:
        for r in csv.DictReader(f):
            r['final_score'] = int(r['final_score'])
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

def check_deltas(pairs, no_effect_set):
    """检查所有Delta正确性"""
    errors = []
    for p in pairs:
        d = p['n']['final_score'] - p['b']['final_score']
        ne = (p['id'], p['tno']) in no_effect_set
        if ne and d != 0:
            errors.append(f'[FAIL] {p["id"]} {p["name"]} {p["tno"]}: 不触发但有Δ={d}')
        if not ne and d == 0:
            errors.append(f'[FAIL] {p["id"]} {p["name"]} {p["tno"]}: 触发但Δ=0')
    return errors

def check_sd_consistency(pairs):
    """检查SD标准牌组基线一致性"""
    bases = set()
    count = 0
    sd = ('♠2','♥7','♦J','♣4','♠9','♥Q','♣3','♠6','♥K')
    for p in pairs:
        cards = tuple(p['b'][h] for h in ['h1','h2','h3','m1','m2','m3','t1','t2','t3'])
        if cards == sd:
            bases.add(p['b']['final_score'])
            count += 1
    return count, bases

def category_stats(pairs, ids):
    """计算指定卡组的统计"""
    deltas = []
    ratios = []
    for p in pairs:
        if p['id'] in ids and p['n']['final_score'] > p['b']['final_score']:
            d = p['n']['final_score'] - p['b']['final_score']
            r = p['n']['final_score'] / p['b']['final_score']
            deltas.append(d)
            ratios.append(r)
    return deltas, ratios

def card_averages(pairs):
    """计算每卡平均Delta"""
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
    
    no_effect_set = {
        ('n_g01','T3'),('n_g01','T5'),('n_g02','T3'),('n_g02','T6'),
        ('n_g04','T3'),('n_g04','T4'),('n_g04','T5'),('n_g05','T3'),
        ('n_g05','T6'),('n_g06','T3'),('n_x01','T3'),('n_x03','T3'),
        ('n_x06','T3'),('n_c01','T3'),('n_f01','T2'),('n_f02','T3'),
        ('n_r03','T3'),('n_s01','T3'),('n_s02','T3'),('n_s03','T3'),
        ('n_s05','T3'),('n_s06','T3'),
    }
    
    cats = [
        ('Batch1 通用', ['n_001','n_002','n_003','n_004','n_005','n_006']),
        ('Batch2 组别', ['n_g01','n_g02','n_g03','n_g04','n_g05','n_g06']),
        ('Batch3 喜',   ['n_x01','n_x02','n_x03','n_x06']),
        ('Batch4 联动', ['n_c01','n_c02','n_f01','n_f02']),
        ('Batch5 规则', ['n_r02','n_r03','n_t05','n_l01']),
        ('Batch6 成长', ['n_s01','n_s02','n_s03','n_s05','n_s06']),
    ]
    
    print('=' * 60)
    print('  NinKing 测试数据 Review 报告')
    print('  生成时间: ' + __import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M'))
    print('=' * 60)
    
    # 1. Delta验证
    print('\n--- 1. Delta正确性 ---')
    errors = check_deltas(pairs, no_effect_set)
    if errors:
        for e in errors: print('  ' + e)
        sys.exit(1)
    else:
        print(f'  [PASS] {len(pairs)} 测试对, 0 异常')
    
    # 2. SD一致性
    print('\n--- 2. SD牌组一致性 ---')
    count, bases = check_sd_consistency(pairs)
    ok = 1216 in bases and len(bases) == 1
    print(f'  SD引用: {count}次, 基线一致: {ok} ({bases})')
    
    # 3. 分类统计
    print('\n--- 3. 分类Delta分布 ---')
    for cat, ids in cats:
        deltas, ratios = category_stats(pairs, ids)
        if deltas:
            print(f'  {cat}:')
            print(f'    Delta: {min(deltas):,} ~ {max(deltas):,} (avg={sum(deltas)/len(deltas):,.0f})')
            print(f'    倍率: {min(ratios):.2f} ~ {max(ratios):.2f} (avg={sum(ratios)/len(ratios):.2f})')
    
    # 4. 纯效果分析
    print('\n--- 4. 纯效果(无列/无喜) ---')
    pure = [p for p in pairs if p['n']['col_x_prod'] == '1'
            and p['n']['xi_x_prod'] == '1' and p['n']['final_score'] > p['b']['final_score']]
    pure_d = [p['n']['final_score'] - p['b']['final_score'] for p in pure]
    if pure_d:
        print(f'  测试数: {len(pure)}')
        print(f'  Delta: {min(pure_d):,} ~ {max(pure_d):,} (avg={sum(pure_d)/len(pure_d):,.0f})')
    
    # 5. 最强/最弱
    print('\n--- 5. 最强/最弱卡(纯效果) ---')
    avgs = card_averages(pairs)
    sorted_cards = sorted(avgs.items(), key=lambda x: sum(x[1]['deltas'])/len(x[1]['deltas']))
    print('  Top5 最弱:')
    for cid, s in sorted_cards[:5]:
        avg = sum(s['deltas']) / len(s['deltas'])
        print(f'    {cid} {s["name"]}: avg={avg:,.0f}')
    print('  Top5 最强:')
    for cid, s in sorted_cards[-5:]:
        avg = sum(s['deltas']) / len(s['deltas'])
        print(f'    {cid} {s["name"]}: avg={avg:,.0f}')
    
    print(f'\n[OK] Review 完成')

if __name__ == '__main__':
    main()
```

---

## 6. 数据流与依赖关系

```
ninja_data.gd        ← 效果值和条件定义的唯一来源
  │
  ▼
gen_test_v2.py       ← 人工维护，同步 ninja_data.gd 变更
  │
  ├──► ninja-test-full.csv    ← 输出：312行测试数据
  │       │
  │       ├──► ninja-test-viewer.html  ← 可视化浏览
  │       │
  │       └──► review_test_data.py     ← Review报告
  │
  └──► Python控制台输出 ← Delta验证结果
```

### 6.1 文件结构

```
docs/ninking/testing/
├── ninja-test-full.csv              ← 测试数据（版本控制）
├── ninja-test-viewer.html           ← 可视化（双击打开）
├── ninja-test-plan.md               ← 测试计划文档
└── automated-formula-testing.md     ← 本文件（方法论）

tools/
├── gen_test_v2.py                   ← 测试生成器
└── review_test_data.py              ← Review分析脚本
```

### 6.2 版本控制策略

| 文件 | 是否入版本库 | 更新时机 |
|------|:----------:|---------|
| `gen_test_v2.py` | ✅ | 卡牌数据/公式变更时 |
| `ninja-test-full.csv` | ✅ | 每次生成后 |
| `ninja-test-plan.md` | ✅ | 测试架构变更时 |
| `ninja-test-viewer.html` | ✅ | CSV更新后同步 |
| `automated-formula-testing.md` | ✅ | 少修改，作为基准 |

---

## 7. 故障排除

### 7.1 常见生成错误

| 错误信息 | 原因 | 修复 |
|---------|------|------|
| `KeyError: 'm'` | ne dict 缺少组键 | 用 `ne_partial()` 代替裸 dict |
| `KeyError: 'c'` | 组内缺 c/m/x 字段 | `ne_partial` 自动补齐 |
| 意外触发某喜 | 牌组设计不当 | 检查花色和点数分布 |
| 卡牌重复 | 9 张中有相同(花色+点数) | 检查每张牌唯一性 |

### 7.2 Review 误报处理

```
Delta 验证出现 [ERROR] 但实际正确的情况：
1. xi_bonus/xi_override 导致 delta → 验证应使用 d != 0 判断
2. T3 标签含有效果测试 → 需匹配 no_effect_set，而非仅靠标签
3. 列×喜复合乘导致极高 delta → 属正常放大，检查公式即可
```
