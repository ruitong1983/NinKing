# LeftPanel 重设计 — 实现规格（已实施）

> **日期:** 2026-06-09 | **来源:** grill-me 14 轮决策 | **状态:** ✅ 已实施（2026-06-11 补充 ink-bleed 渐隐 + 3 行 HandTypeRow）

---

## 已实现变更汇总

### 布局

- ✅ ScoreCard **顶对齐**（删除了 SpacerTop）
- ✅ 内容通过 `VBoxContainer` + Spacer 弹性分布
- ✅ **Ink-bleed 渐隐**：`panel_edge_fade.gdshader` 挂载于 PanelBg + ScoreCard + MatchPanel + AntePanel

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
