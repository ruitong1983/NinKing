---
name: ninja-test
description: 忍者牌自动测试 — 构建、计分模拟、Delta验证、Review报告一站完成。使用 /ninja-test [参数]
---

# 忍者牌自动测试 · Skill

## 概述

自动执行忍者牌计分验证全流程：构建/更新测试用例 → Python 计分模拟 → Delta 验证 → Review 报告生成。覆盖 45 张忍者牌（约 156 测试对），输出 CSV + 控制台报告 + 可视化 HTML。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 "测试忍者" / "忍者牌测试" / "测试数据" / "run ninja test"
- 用户修改了 `ninja_data.gd` 后需要验证
- 用户修改了计分公式（card_data / score_calculator）后需要验证
- 用户说 "生成测试报告" / "review test data"
- 用户说 `/ninja-test` 或 `! python gen_test_v2.py`

## 参数说明

| 参数 | 说明 | 默认 |
|------|------|------|
| `full` | 完整流程：生成+验证+review | 默认 |
| `generate` | 仅构建测试 CSV | — |
| `review` | 仅 review 已有 CSV | — |
| `card=<id>` | 仅测试指定卡（如 `card=n_g01`） | 全量 |
| `output` | 保存 review 报告到文件 | 控制台 |

## 工作流程

```
┌──────────────────────────────────────────────────────┐
│  1. 环境准备                                          │
│     Read ninja_data.gd → 确认当前卡牌数据               │
│     Read gen_test_v2.py → 确认生成器逻辑               │
│     Read ninja-test-full.csv → 确认已有测试            │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  2. 同步生成器（如数据变更）                             │
│     对比 ninja_data.gd vs gen_test_v2.py 中的 ne 值   │
│     如有差异 → 更新 gen_test_v2.py                     │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  3. 生成测试 CSV                                      │
│     python gen_test_v2.py                             │
│     自动 Delta 验证                                    │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  4. Review 报告                                       │
│     python review_test_data.py                        │
│     Delta校验 + SD一致性 + 分类统计 + 强度排序           │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  5. 输出结果                                           │
│     Delta 验证摘要                                     │
│     Review 统计报告                                     │
│     可视化(open viewer.html)                           │
│     异常项 → 分析根因 + 修复建议                         │
└──────────────────────────────────────────────────────┘
```

## 详细执行步骤

### Step 1: 环境准备

```bash
# 检查生成器和 review 脚本
ls -la docs/ninking/testing/
ls -la tools/gen_test_v2.py tools/review_test_data.py
```

确认以下文件存在：
- `tools/gen_test_v2.py` — 测试生成器
- `tools/review_test_data.py` — Review 分析脚本
- `docs/ninking/testing/ninja-test-full.csv` — 已有测试数据
- `docs/ninking/testing/ninja-test-viewer.html` — 可视化
- `docs/ninking/testing/ninja-test-plan.md` — 测试计划
- `docs/ninking/testing/automated-formula-testing.md` — 方法论

### Step 2: 同步卡牌数据

生成器是关键的"单点真相"（source of truth），必须与 `ninja_data.gd` 保持一致。

#### 2.1 通用加成卡

检查 `gen_test_v2.py` 中 `ne_all(c=xxx, m=yyy)` 的值是否匹配 `ninja_data.gd` 的 `effect` 字段：

```python
# 通用加成 ne 映射
# n_001 +10 chips  → ne_all(c=10)
# n_002 +4 mult    → ne_all(m=4)
# n_003 +15c +2m   → ne_all(c=15, m=2)
# n_004 +20 chips  → ne_all(c=20)
# n_005 +10 mult   → ne_all(m=10)
# n_006 +30c +10m  → ne_all(c=30, m=10)
```

#### 2.2 条件触发卡

条件卡通过 `ne_partial()` 指定"触发时效果"：

```python
# n_g01 虎头: head≤对子 → +5m head
#   → ne_partial(h={'m':5})
# n_g02 龙尾: tail≥同花顺 → ×2 tail
#   → ne_partial(t={'x':[2]})
# n_g03 中流砥柱: mid +50c
#   → ne_partial(m={'c':50})
# n_g06 金字塔: strict_ascending → ×2 all
#   → ne_all(x=[2])
```

不触发测试始终使用 `no_ninja()`：

```python
tc('n_g01','虎头','T3','不触发头顺',
    [...], [...], [...],
    no_ninja())  # ← Δ=0 验证
```

#### 2.3 喜强化卡

喜鹊/两仪 通过特殊参数传递：

```python
# n_x01 喜鹊: xi_bonus=1 (每个喜×mult +1)
tc('n_x01','喜鹊','T1','三清×3', ..., no_ninja(), xi_bonus=1)

# n_x03 两仪: xi_override={'三清':3}
tc('n_x03','两仪','T1','三清触发×3', ..., no_ninja(), xi_override={'三清':3})

# n_x02 四张猎人: 条件触发 +30c / else +5c
tc(..., ne_all(c=30))  # 触发
tc(..., ne_all(c=5))   # 不触发
```

#### 2.4 跨组联动 + 点数

```python
# n_c01 镜像: head_type=tail_type → ×2 head
#   → ne_partial(h={'x':[2]})
# n_c02 铁索连环: any_two_same → 15c+3m on same groups
#   → ne_partial(h={'c':15,'m':3}, m={'c':15,'m':3})
# n_f01 影之眷顾: +3c per face → ne_all(c=计数*3)
# n_f02 王牌侍从: +5m per A(cap20) → ne_all(m=计数*5)
```

#### 2.5 成长修炼卡

效果通过 `ne_all(m=X)` 模拟假设累积值：

```python
# n_s01 修行者: 累积3次+3m
tc(..., ne_all(m=3))
tc(..., ne_all(m=6))  # 6次累积
tc(..., no_ninja())    # 未累积
```

#### 2.6 规则变更 + 传说

```python
# n_r02 均衡: same_type → ×2 all
#   → ne_all(x=[2])
# n_r03 独尊: tail×2 if head+mid≥对子
#   → ne_partial(t={'x':[2]})
# n_t05 风遁: 对子+3m (hand_type=1)
#   → ne_partial(m={'m':3}) / ne_all(m=3) / no_ninja()
# n_l01 天下人: ×2 all
#   → ne_all(x=[2])
```

### Step 3: 牌组设计

#### 标准安全牌组(SD)

```python
SD = ['♠2','♥7','♦J'], ['♣4','♠9','♥Q'], ['♣3','♠6','♥K']
# 基线: 1216 (全散牌 × 列顺×16)
```

#### 专用测试牌组

```python
# 三列豹(极限列乘×32768 + 全三条×4)
['♠3','♥7','♦J'], ['♦3','♠7','♥J'], ['♣3','♣7','♠J']

# 全♠(全同花×3 + 全黑×2 + 三清×2)
['♠2','♠5','♠9'], ['♠3','♠7','♠J'], ['♠4','♠8','♠K']

# 高强度混合(头豹+中同花顺+尾同花)
['♠J','♥J','♦J'], ['♥Q','♥K','♥A'], ['♠3','♠7','♠9']

# 四张喜(4张同点+散牌)
['♠A','♥A','♦A'], ['♣A','♠2','♥7'], ['♣3','♠6','♥9']

# 无重复检查: 同一测试内9张牌的花色+点数必须唯一
```

### Step 4: 生成 CSV

```bash
python tools/gen_test_v2.py
```

生成器会自动：
1. 用 `calc()` 计算 baseline（无忍者）得分
2. 用 `calc()` + ne 参数计算 with_ninja 得分
3. 两行配对写入 CSV
4. 输出 Delta 验证摘要

**验证标准：**
- 触发测试 → `Δ > 0` ✅
- 不触发测试 → `Δ = 0` ✅
- 同卡内 `触发Δ > 不触发Δ`

### Step 5: Review 报告

```bash
python tools/review_test_data.py
```

输出结构：

```
==============================================================
  NinKing 测试数据 Review 报告
  2026-06-12 14:30  |  156 测试对
==============================================================

【1】Delta 正确性
  ✅ 全部 156 测试对通过

【2】SD牌组一致性
  引用: 22次 | 一致: ✅ | 基线: {1216}

【3】分类统计
  Batch1 通用:
    Delta 30 ~ 60 均 42
    倍率 1.19 ~ 6.0 均 2.37
  ...

【4】纯效果(无列/无喜干扰)
  测试数: 28
  Delta: 30 ~ 520 均 135

【5】卡牌强度排序(纯效果均Delta)
  最弱5:
    n_001 手里剑: 42
    n_002 苦无: 52
    ...
  最强5:
    n_006 奥义之卷: 350
    ...

📊 总计: 156 对 | 触发 126 | 不触发 30 | 异常 0
[PASS] Review 完成
```

### Step 6: 异常处理

#### 6.1 Delta 异常

| 现象 | 可能原因 | 修复 |
|------|---------|------|
| 触发测试 Δ=0 | ne 参数与 ninja_data.gd 不一致 | 同步 ne 值 |
| 不触发测试 Δ≠0 | 牌组意外触发条件 | 检查牌型判定，换牌组 |
| 同卡 T1 < T3 | 测试牌组基线差异过大 | 统一用 SD 或类似基线 |
| 意外喜干扰 | 9张牌花色/点数分布不当 | 用混花色+断点数牌组 |

#### 6.2 生成错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `KeyError: 'm'` | ne dict 缺字段 | 用 `ne_partial()` 自动补齐 |
| 卡牌重复 | 9张牌有相同花色+点数 | 检查每张牌唯一性 |
| Unicode 乱码 | UTF-8 BOM/编码问题 | 确认 `encoding='utf-8-sig'` |

#### 6.3 根因分析模板

发现异常后执行分析流程：

```python
# 1. 定位异常卡+测试对
print(f"异常: {card_id} {test_no}")

# 2. 查看牌组
print(f"头: {h1}{h2}{h3} 中: {m1}{m2}{m3} 尾: {t1}{t2}{t3}")

# 3. 手动 eval_group 验证牌型
from gen_test_v2 import eval_group
print(eval_group([('♠',2),('♥',3),('♦',4)]))  # 示例

# 4. 对比 ne 参数与 ninja_data.gd
print(f"ne used: {ne}")

# 5. 检查是否有意外牌型/喜触发
```

### Step 7: 可视化

双击 `docs/ninking/testing/ninja-test-viewer.html` 打开浏览器查看：

- 卡牌选择器过滤
- 测试类型（T1-T6）过滤
- 纯效果 / 喜联动 / 高列乘 分组
- baseline vs with_ninja 条形对比
- Delta 数值 + 百分比

HTML 文件为纯静态，双击即可用，无需服务器。

---

## 计分计算引擎 (calc 函数)

生成器的 `calc()` 是纯 Python 实现的计分公式，与 GDScript 版本 1:1 对应。

### 公式

```
组得分 = (牌面筹码 + 牌型筹码 + 忍者筹码) × (牌型倍率 + 忍者倍率) × ∏(组内×stack)

原始总分 = Σ 组得分

最终分 = 原始总分 × ∏(列×mult) × ∏(全局喜×mult)
```

### 牌型表

| 码 | 牌型 | chips | mult | 列×mult |
|:---:|------|:----:|:----:|:-------:|
| 0 | 散牌 | 5 | 1 | 1 |
| 1 | 对子 | 10 | 2 | 2 |
| 2 | 顺子 | 20 | 3 | 4 |
| 3 | 同花 | 30 | 4 | 8 |
| 4 | 同花顺 | 50 | 5 | 16 |
| 5 | 豹子 | 100 | 8 | 32 |

### 喜×mult 表

| 喜 | 类型 | 基数 | 喜鹊+1 |
|----|:----:|:----:|:------:|
| 三清 | 组级 | ×2 | ×3 |
| 三顺清 | 组级 | ×3 | ×4 |
| 顺清打头 | 组级(仅头) | ×2 | ×3 |
| 全黑 | 全局 | ×2 | ×3 |
| 全红 | 全局 | ×2 | ×3 |
| 全顺 | 全局 | ×2 | ×3 |
| 全同花 | 全局 | ×3 | ×4 |
| 四张 | 全局 | ×5 | ×6 |
| 全三条 | 全局 | ×4 | ×5 |

---

## 快速命令

```bash
# 完整流程
python tools/gen_test_v2.py && python tools/review_test_data.py

# 仅 Delta 验证
python -c "
import csv
rows = list(csv.DictReader(open(r'docs/ninking/testing/ninja-test-full.csv','r',encoding='utf-8-sig')))
pairs = {}
for r in rows:
    k=(r['card_id'],r['test_no'])
    if k not in pairs: pairs[k]={}
    pairs[k][r['version']]=int(r['final_score'])
errors=0
for k,v in pairs.items():
    d=v['with_ninja']-v['baseline']
    if d==0: print(f'{k[0]} {k[1]}: Δ=0 [WARN]'); errors+=1
print(f'Total: {len(pairs)} pairs, {errors} zero-delta')
"

# 查看覆盖率
python -c "
import csv
r=[x for x in csv.DictReader(open(r'docs/ninking/testing/ninja-test-full.csv','r',encoding='utf-8-sig'))]
cards=set(x['card_id'] for x in r)
print(f'覆盖卡牌: {len(cards)}')
for c in sorted(cards):
    t=[x['test_no'] for x in r if x['card_id']==c and x['version']=='with_ninja']
    print(f'  {c}: {len(t)} 测试')
"

# 查看视图
start docs/ninking/testing/ninja-test-viewer.html
```

---

## 注意事项

1. **生成器 + CSV 均为版本控制** — 修改计分公式时，必须同步更新 `gen_test_v2.py` 再提交
2. **不测试经济卡** — n_e01~n_e06 不计分，需手动验证
3. **不测试随机传说** — n_l02 幻术大师 / n_l03 影武者 有随机性，框架外
4. **skill 不覆盖 Godot 运行时** — 仅负责 Python 计分模拟验证
5. **SD 基线 1216** — 所有 SD 牌组测试对基线必须一致，否则是 bug

## 覆盖清单

| 类别 | 总数 | 已测 | 不可测 |
|:----:|:----:|:----:|:------:|
| 通用加成 | 6 | 6 (5组/卡) | — |
| 组别定向 | 6 | 6 (6组/卡) | — |
| 喜之强化 | 4 | 4 (6组/卡) | — |
| 跨组联动 | 2 | 2 (6组/卡) | — |
| 点数/人牌 | 2 | 2 (5组/卡) | — |
| 规则变更 | 2 | 2 (5组/卡) | — |
| 传说 | 3 | 1 (4组/卡) | 2 (随机) |
| 风遁 | 1 | 1 (4组/卡) | — |
| 成长修炼 | 5 | 5 (6组/卡) | — |
| 经济类 | 6 | — | 6 (不计分) |
| **合计** | **30+6** | **30卡(156对)** | **6** |
