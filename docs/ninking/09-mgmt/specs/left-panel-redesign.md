# LeftPanel 重设计 — 实现规格（已实施）

> **日期:** 2026-06-09 | **来源:** grill-me 14 轮决策 | **状态:** ✅ 已实施（2026-06-11 补充 ink-bleed 渐隐 + 3 行 HandTypeRow）

---

## 已实现变更汇总

### 布局

- ✅ ScoreCard **顶对齐**（删除了 SpacerTop）
- ✅ 内容通过 `VBoxContainer` + Spacer 弹性分布
- ✅ **Ink-bleed 渐隐**：`panel_edge_fade.gdshader` 挂载于 PanelBg + ScoreCard + MatchPanel + AntePanel

---

## v2 变更 — 列积分 + 公式展示 (2026-06-12)

> 来源: grill-me 14 轮决策 | 关联: v5.0 计分公式 | 状态: ✅ 已实施

### 新增

- ✅ **ColumnTypeRow** — ScoreCard 内新增 3 行列（左列/中列/右列），镜像 HandTypeRow 格式
- ✅ **列行始终可见** — 排列阶段实时预览列牌型+分数+Lv 徽标，同行一致
- ✅ **ScoreLabel 公式** — 计分后显示 `"{subtotal} ×{xi} = {total} 忍気"`，永久保留
- ✅ **ColXiLabel 纯喜** — 列信息移到行区域后，ColXiLabel 只显示喜信息（排列预览+计分后保持）

### 宽度调整

| 属性 | 旧值 | 新值 |
|------|------|------|
| LeftPanel custom_minimum_size | 420 | **480** |
| ScoreCardVBox offset_left | 16 | **8** |
| ScoreCardVBox offset_right | -68 | **-24** |

### 颜色方案

| 元素 | 颜色 |
|------|------|
| 列标签（左列/中列/右列） | 灰 #A0A0A0 |
| 列牌型名 | 白 |
| 列分数 | 灰 |
| 列 Lv 徽标 | 同行规则（灰→蓝→金） |

### 计分动画序列

```
Phase 1: 逐行展牌 (影→瞬→滅) → ScoreLabel 滚到行总分
Phase 2: 逐列展列 (左列→中列→右列) → ScoreLabel 累加
Phase 3: 喜×入 → ScoreLabel 展开公式 → 粒子/shake
Phase 4: 结局 (同前)
```

### v2.1 修复 — 列积分接续 + 行分数初始空置 (2026-06-12)

> 来源: 用户反馈 | 状态: ✅ 已实施

**Bug 修复:**

| Bug | 说明 | 修复 |
|-----|------|------|
| 列积分未触发 | `col_evals` 从未计算传入 animation_handler，Phase 2 永远跳过 | `game_manager.gd:_on_play_pressed()` 新增 3 列 `HandEvaluator3.evaluate()` 计算存入 `play_data["col_evals"]` |
| 行分数计分前置 "0×0" | 计分前三行分数标签残留 "0×0"，应为空白 | 移除场景文件 6 个 `text = "0×0"` 默认值；animation_handler Phase 1 每行开始前动态设 "0×0" 再渐入终值 |

**文件变更:**

| 文件 | 变更 |
|------|------|
| `scripts/ninking/ui/game_manager.gd` | `_on_play_pressed()` 新增 col_evals 计算 (5行) |
| `scripts/ninking/ui/animation_handler.gd` | 删除开篇 "reset all to 0×0" 块；dun_score_labels/col_score_labels 声明移至 Phase 1；每行卡片动效前 `dun_score_labels[i].text = "0×0"` |
| `scenes/ninking/ninking_main.tscn` | ShadowScore/FlashScore/DestroyScore + LeftColScore/MidColScore/RightColScore 删除 `text = "0×0"` |
| `scenes/ninking/debug_ninking_main.tscn` | 同上 6 标签删除 `text = "0×0"` |
| `scripts/ninking/debug/debug_controller.gd` | `_reset_ui()` + `_update_left_panel_labels()` 所有 score label 默认 `""` 替代 `"0×0"` |

### 对应文件变更

| 文件 | 变更 |
|------|------|
| `scenes/ninking/ninking_main.tscn` | LeftPanel 宽度、ScoreCardVBox offset、新增 ColumnTypeRow 12 标签 |
| `scenes/ninking/debug_ninking_main.tscn` | 同步 LeftPanel 宽度、新增 ColumnTypeRow |
| `scripts/ninking/ui/ui_manager.gd` | 新增 12 个 @onready 列标签引用 |
| `scripts/ninking/ui/hand_display.gd` | setup() 签名扩展 12 参数 |
| `scripts/ninking/ui/hand_type_labeler.gd` | 新增 _update_column_rows()、ColXiLabel 简化为 xi-only、Lv hover 扩展 |
| `scripts/ninking/ui/animation_handler.gd` | Phase 重排：行→列→喜公式，移除 BounceScore，ScoreLabel 公式控制 |
| `scripts/ninking/debug/debug_controller.gd` | 新增列标签引用+更新逻辑+辅助方法 |

### 边框/圆角

- ✅ ScoreCard: **无边框、无圆角**，`content_margin_right=68`
- ✅ MatchPanel: **无边框、无圆角、无背景**，`content_margin_left=16`
- ✅ AntePanel: **无边框、无圆角、无背景**，`content_margin_left=16`

### ProgressBar

- ✅ 高度 12→**28px**
- ✅ 右端 = **312px** (= 渐隐起始点，通过 ScoreCard right_margin=68 + ScoreCardVBox layout_mode=2)
- ✅ 两端圆角 6px 保留

### HandTypeRow

- ✅ HBoxContainer(3标签横排) → **VBoxContainer(3行**，每行 HBox 含 墩名 | 牌型名 | 分数)
- ✅ 新增分数列：`%ShadowScore` / `%FlashScore` / `%DestroyScore`
- ✅ 分数预览 = (卡牌筹码 + 牌型筹码) × 牌型倍率

### 字体放大

| 标签 | 旧字号 | 新字号 |
|------|--------|--------|
| MatchTitle | 16px | **20px** |
| HandsLabel | 24px | **28px** |
| GoldLabel | 24px | **28px** |
| BarrierLabel | 24px | **28px** |
| RoundLabel | 24px | **28px** |

### 对应文件变更

| 文件 | 变更 |
|------|------|
| `scenes/ninking/ninking_main.tscn` | LeftPanel 子树重建, ScoreCard/HandTypeRow/MatchPanel/AntePanel 属性更新 |
| `scripts/ninking/ui/ui_manager.gd` | 新增 `shadow_score_label` / `flash_score_label` / `destroy_score_label` @onready 引用 |
| `scripts/ninking/ui/hand_display.gd` | `setup()` 签名新增 3 个分数标签参数 |
| `scripts/ninking/ui/hand_type_labeler.gd` | 新增分数标签成员 + `_update_dun_types()` 写入分数 |
| `scripts/ninking/ui/panel_edge_fade.gdshader` | 新增 — ink-bleed 渐隐 shader |
| `scripts/ninking/ui/game_manager.gd` | `_ready()` 挂载 fade shader |

---

## 原规格说明（保留供参考）

<details>
<summary>展开原设计稿</summary>

### 原问题

LeftPanel 380×1080，内容集中在 y=88~624（占 58%），下半部 456px 完全空白。

### 原目标

- LeftPanel 内容均匀撑满全高度
- 改用 VBoxContainer + spacer 自动布局

### 原结构

```
LeftPanel (VBoxContainer, 380×1080)
├── PanelBg (ColorRect, 全高背景)
├── Control spacer (SIZE_EXPAND)
├── ScoreCard (Panel, ~200px)
│   ├── ChipsMultContainer
│   ├── ScoreLabel (48px)
│   ├── ProgressBar (28px)
│   └── TargetScoreLabel (20px)
├── Control spacer
├── HandTypeRow (HBoxContainer, ~60px)
│   ├── ShadowType (22px, 暗蓝)
│   ├── FlashType (22px, 银灰)
│   └── DestroyType (22px, 深红)
├── Control spacer
├── MatchPanel (~160px)
│   ├── MatchTitle (18px)
│   ├── HandsLabel (24px)
│   └── GoldLabel (24px)
├── Control spacer
├── AntePanel (~110px)
│   ├── BarrierLabel (24px)
│   └── RoundLabel (24px)
└── Control spacer
```

</details>
