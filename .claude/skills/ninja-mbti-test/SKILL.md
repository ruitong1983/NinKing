---
name: ninja-mbti-test
description: 模拟玩家性格测试 — 一键清理旧数据、跑 32 型 MBTI-A/T 模拟、生成时间戳 HTML 报告（含首页结论/平衡性/膨胀分析/调整建议）
---

# 模拟玩家性格测试 · Skill

## 概述

自动执行 NinKing MBTI 32 型 + 3 基线模拟测试全流程：
1. 清理旧数据 → 2. 全量模拟（35 型 × N 次）→ 3. 生成时间戳 HTML 报告（首页=结论摘要+平衡性+膨胀警告+调整建议）→ 4. 打开报告

每次生成独立的 `mbti_report_YYYYMMDD_HHMMSS.html`，不覆盖历史报告。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 **"模拟玩家性格测试"** / **"跑MBTI模拟"** / **"性格模拟测试"**
- 用户说 **"生成性格测试报告"** / **"更新模拟报告"**
- 用户说 `/ninja-mbti-test` 或 `! python sim_runner_personality.py --all...`
- 用户修改了 `mbti_strategies.json` 后需要验证整体平衡性

## 参数说明

| 参数 | 说明 | 默认 |
|------|------|------|
| `runs=<N>` | 每型模拟次数 | 10 |
| `quick` | 快速模式（每个类型跑 3 次代替 10 次） | — |
| `group=<组名>` | 只跑指定组（如 `group=稳妥型`） | 全 35 型 |
| `personality=<名称>` | 只跑指定类型（如 `personality=ISTJ-A`） | — |
| `no-report` | 只模拟不生成 HTML 报告 | — |

## 工作流程

```
┌──────────────────────────────────────────────────────┐
│  1. 清理旧数据                                        │
│     rm data_personality/*.json                        │
│     （确保只有本次模拟的新数据）                          │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  2. 全量模拟                                          │
│     sim_runner_personality.py --all --runs N --clean  │
│     N=10 标准 / N=3 快速                              │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  3. 分析生成报告文档（JSON）                            │
│     analyze_mbti_report.py                           │
│     输出 → reports/mbti_report_data_TIMESTAMP.json   │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  4. 渲染 HTML 可视化报告                               │
│     render_mbti_html.py --input <JSON>               │
│     输出 → reports/mbti_report_TIMESTAMP.html        │
└──────────────────┬───────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────┐
│  4. 打开报告                                          │
│     浏览器打开最新 HTML                                │
└──────────────────────────────────────────────────────┘
```

## 详细执行步骤

### Step 1: 确认环境

```bash
# 确认关键文件存在
ls tools/simulation/sim_runner_personality.py    # 模拟器
ls tools/simulation/analyze_mbti_report.py       # 分析器（输出 JSON）
ls tools/simulation/render_mbti_html.py          # HTML 渲染器
ls tools/simulation/mbti_strategies.json         # 策略数据源
ls docs/ninking/08-testing/reports/              # 报告输出目录
```

### Step 2: 清理旧数据

```bash
rm -f docs/ninking/08-testing/data_personality/*.json
```

或者使用 `--clean` 标志（已集成在 `sim_runner_personality.py` 中）：

```bash
python tools/simulation/sim_runner_personality.py --all --runs 10 --clean
```

### Step 3: 运行模拟

```bash
cd tools/simulation

# 标准全量（35型 × 10次 ≈ 3-5分钟）
python sim_runner_personality.py --all --runs 10

# 快速验证（35型 × 3次 ≈ 1分钟）
python sim_runner_personality.py --all --runs 3

# 只跑某个组
python sim_runner_personality.py --group 感性型 --runs 10
```

> ⚠️ `--clean` 会在运行前清空 `data_personality/`，确保没有旧数据干扰。

### Step 4: 分析生成报告文档（JSON）

```bash
# 分析模拟数据，输出结构化 JSON 报告文档
python analyze_mbti_report.py
```

输出文件：`docs/ninking/08-testing/reports/mbti_report_data_YYYYMMDD_HHMMSS.json`

JSON 报告文档是可读、可复用的结构化数据，包含 findings / suggestions / strategy_meta 等。

### Step 5: 渲染 HTML 可视化报告

```bash
# 读取 JSON 报告文档，渲染为可视化 HTML
python render_mbti_html.py --input reports/mbti_report_data_*.json
```

输出文件：`docs/ninking/08-testing/reports/mbti_report_YYYYMMDD_HHMMSS.html`

```bash
# 一键完成（分析 JSON + 自动渲染 HTML）
python analyze_mbti_report.py --render
```

> 如果先跑了 `--clean` 再模拟，此时 `data_personality/` 只有最新数据。

### Step 6: 一键流程（组合命令）

```bash
cd tools/simulation

# 方式一：模拟→分析→渲染（兼容入口，保持旧调用方式）
python sim_runner_personality.py --all --runs 10 --clean --report

# 方式二：仅分析 JSON → 渲染 HTML（已有模拟数据时）
python analyze_mbti_report.py --render
```

> `sim_runner_personality.py --report` 自动调用 `generate_mbti_report.py`（兼容入口），后者委派给 analyze_mbti_report.py 分析数据 → render_mbti_html.py 渲染 HTML → 打开浏览器。

### Step 7: 阅读报告

双击 `docs/ninking/08-testing/reports/mbti_report_*.html` 在浏览器打开。

报告结构：
| 区域 | 内容 |
|:----|:------|
| 📊 **总览** | 平均B8通过率、最佳/最差、触发率、测试规模 |
| ⚠️ **关键发现** | 各组评级（🟢正常/🟡关注/🟠偏弱/🔴调整/🟣超模）+ 个体极端值 |
| 📈 **膨胀分析** | B8得分范围、膨胀系数排名 |
| 🔧 **调整建议** | 具体策略参数修改建议（高/中/低优先级） |
| ⚖️ **A/T对比** | 每组 Assertive 与 Turbulent 变体的表现差异 |
| 📋 **各组明细** | 折叠面板，查看每型的B8率/结界/触发率 |

## 历史报告管理

`reports/` 目录下的 HTML 按时间戳命名，永不覆盖：

```
reports/
├── mbti_report_20260618_120000.html
├── mbti_report_20260618_143000.html
├── mbti_report_20260618_150230.html
└── ...
```

如需清理旧报告，手动删除即可。

## 报告解读 — 颜色标记

| 状态 | B8通关率 | 含义 |
|:----:|:--------:|:-----|
| 🟢 正常 | ≥20% | 该类型具备合理通关能力 |
| 🟡 关注 | 10%~20% | 偏弱但可观察 |
| 🟠 偏弱 | 0.1%~10% | 明显弱，建议调整 |
| 🔴 调整 | 0% | 从未通关，必须调整 |
| 🟣 超模 | ≥50% | 可能过强，需关注 |

## 快速命令

```bash
# 标准完整流程（模拟→分析→渲染）
cd tools/simulation && python sim_runner_personality.py --all --runs 10 --clean --report

# 快速验证（3次）
cd tools/simulation && python sim_runner_personality.py --all --runs 3 --clean --report

# 仅重新分析+渲染（已有模拟数据，不重跑）
cd tools/simulation && python analyze_mbti_report.py --render

# 分步：先分析为 JSON 报告文档
cd tools/simulation && python analyze_mbti_report.py

# 再单独渲染 HTML（可用不同输出路径）
cd tools/simulation && python render_mbti_html.py
```

## 注意事项

1. **确保 `mbti_strategies.json` 是最新的** — 修改策略后必须重新模拟才能反映变化
2. **每次 `--all` 之前最好 `--clean`** — 避免旧数据污染统计分析
3. **HTML 报告是自包含的** — 内嵌所有数据，可离线分享
4. **35 型 = 32 MBTI-A/T + 3 基线** — 不再包含旧版无变体类型
