# NinKing Main Game UI 设计方案

> **建立日期:** 2026-06-10 | **最后同步:** 2026-06-11 | **关联场景:** `ninking_main.tscn` + `ui_manager.gd`
> **风格权威:** [`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) · 少年漫画风
## §1 概述

Main 场景是核心游戏界面。玩家在此查看手牌、排列三墩、出牌计分、触发商店。

```
LevelIntro (0.5s)
    │
    ▼
GameLayout ───────────────────────────────────────┐
│ LeftPanel (420px) │ CenterColumn (1000px+)      │
│ ┌───────────────┐ │ ┌─────────────────────────┐ │
│ │ ScoreCard     │ │ │ NinjaBar (忍者栏)      │ │
│ │ 0 x 0         │ │ ├─────────────────────────┤ │
│ │ 忍気 0        │ │ │ StatusLabel             │ │
│ │ ████░░░░ 300  │ │ ├─────────────────────────┤ │
│ ├───────────────┤ │ │ HandArea                │ │
│ │ 影  对子 37×2 Lv.2 │ │ [討伐] [影][瞬][滅] [陣形] │
│ │ 瞬  对子 37×2 Lv.4 │ │
│ │ 滅  同花 53×4 Lv.1 │ │
│ ├───────────────┤ │ └─────────────────────────┘ │
│ │ 比赛信息      │ │                              │
│ │ 討伐 3        │ └──────────────────────────────┘
│ │ $0            │
│ ├───────────────┤   叠加层（按需显示/隐藏）:
│ │ 结界 1/8      │   · LevelComplete
│ │ 回合 1        │   · GameOver
│ │               │   · VictoryOverlay
│ └───────────────┘   · DeckViewer
└──────────────────────────────────────────────────┘
```

---

## §2 场景结构

```
NinKingMain (Control) [game_manager.gd]
├── CardManager (CardManager)           ← Card-Framework 核心
├── GameBg (TextureRect)                ← 动态背景 (结界配色)
│
└── UIManager (Control) [ui_manager.gd]
    │
    ├── LevelIntro (Control)            ← 关卡入场覆盖层
    │   ├── IntroOverlay (ColorRect)    ← 黑底 80% 不透明
    │   ├── LevelLabel (Label)          ← "结界X · 修罗ノ封印" 48px 金色
    │   └── TargetLabel (Label)         ← "封印 300" 24px
    │
    ├── GameLayout (HBoxContainer)      ← 主游戏布局 (默认隐藏)
    │   │
    │   ├── LeftPanel (Control)         ← 左侧信息面板 420px ★ 本节重点
    │   │   ├── PanelBg (ColorRect)     ← 全透明 (保留节点供代码引用)
    │   │   │
    │   │   ├── ScoreCard (Panel)       ← 得分卡, anchor_top=0, anchor_bottom=0.5 (上半 1/2)
    │   │   │   └── ScoreCardVBox       ← anchors full rect (layout_mode=1)
    │   │   │       ├── ColXiLabel (32px 列金/喜accent)
    │   │   │       ├── HandTypeRow (VBoxContainer)    ← 合入 ScoreCardVBox
    │   │   │       │   ├── Row影 → ShadowDun/ShadowType/ShadowScore/%ShadowLv
    │   │   │       │   ├── Row瞬 → FlashDun/FlashType/FlashScore/%FlashLv
    │   │   │       │   └── Row滅 → DestroyDun/DestroyType/DestroyScore/%DestroyLv
    │   │   │       ├── ScoreLabel (48px "忍気 N")
    │   │   │       ├── ProgressBar (28px, 右端止于 312px 渐隐起始)
    │   │   │       └── TargetScoreLabel (28px "封印 N")
    │   │   │
    │   │   ├── MatchPanel (Panel)      — 直属于 LeftPanel, anchor_top=0.5, anchor_bottom=0.75 (无圆角无边框, 挂 fade)
    │   │   │   └── MatchVBox
    │   │   │       ├── MatchTitle (20px "比赛信息")
    │   │   │       ├── HandsLabel (28px "討伐 N")
    │   │   │       └── GoldLabel (28px "$N")
    │   │   │
    │   │   └── AntePanel (Panel)       — 直属于 LeftPanel, anchor_top=0.75, anchor_bottom=1.0 (无圆角无边框, 挂 fade)
    │   │       └── AnteVBox
    │   │           ├── BarrierLabel (28px "结界 N/M")
    │   │           └── RoundLabel (28px "回合 N")
    │   │
    │   └── CenterColumn (VBoxContainer)
    │       ├── NinjaBar (Control)     ← 忍者牌栏容器
│       │   ├── NinjaBarContainer (CardContainer)  ← 水平线性布局 / DropZone 分区 / 拖拽重排
│       │   │   └── NinjaInventoryCard ×N (Card, 125×175)  ← 差值刷新 / stagger pop-in / zoom-in 详情
│       │   └── NinjaBarNode (Node) ← 生命周期管理
    │       ├── StatusLabel (24px 绿)   ← "影 <= 瞬 <= 滅 -- 可以出牌"
    │       ├── HandArea (HBox 1138×728)
    │       │   ├── PlayBtn (84×116)    ← 「討伐」
    │       │   ├── DunArea (Panel 620×728)
    │       │   │   ├── DunHead (Panel 620×224)
    │       │   │   │   ├── HeadLabel   ← "影"
    │       │   │   │   ├── HeadTypeLabel ← 牌型名
    │       │   │   │   └── HeadCards (Hand) ← 3 张
    │       │   │   ├── DunMiddle (Panel 620×224)
    │       │   │   │   ├── MiddleLabel  ← "瞬"
    │       │   │   │   ├── MiddleTypeLabel
    │       │   │   │   └── MiddleCards (Hand)
    │       │   │   └── DunTail (Panel 620×224)
    │       │   │       ├── TailLabel    ← "滅"
    │       │   │       ├── TailTypeLabel
    │       │   │       └── TailCards (Hand)
    │       │   └── AiRearrangeBtn (84×116) ← 「陣形」
    │       ├── DeckBtn (200×48)        ← "牌库: 52"
    │       └── ColumnLabelRow (HBox)   ← 列分标签 (Col0/Col1/Col2)
    │
    ├── ScoringOverlay (Control)        ← ⛔ 未使用 (Balatro 风内联动画)
    │   ├── OverlayBg (ColorRect)
    │   ├── HandNameLabel
    │   ├── ScoreValueLabel
    │   └── ScoreBreakdown
    │
    ├── LevelComplete (Control)         ← 过关覆盖层
    ├── GameOver (Control) [%GameOver]       ← 失败覆盖层
    │   ├── OverlayBg (ColorRect)           ← #000 80%
    │   ├── GameOverLabel [%GameOverLabel]  ← "失败" 48px 红
    │   ├── RetryButton [%RetryButton]      ← "重新开始" (flat)
    │   ├── BackToMenuButton [%BackToMenuButton] ← "返回主菜单"
    │   └── ScoreSummary [%ScoreSummary]    ← 战绩摘要 Label
    ├── VictoryOverlay (Control)        ← 通关覆盖层
    └── DeckViewer (Control)            ← 牌库查看器
```

---

## §3 LeftPanel — 左侧信息面板

### 3.1 布局

- 宽度 `420px`，`size_flags_horizontal = 0`（固定宽度）
- **三块锚定布局 (2026-06-11)：** 移除旧 `ContentVBox`，三面板直属于 `LeftPanel`，全部 `layout_mode=1`（锚定）
  - ScoreCard: `anchor_top=0`, `anchor_bottom=0.5` → 上半 1/2
  - MatchPanel: `anchor_top=0.5`, `anchor_bottom=0.75` → 中间 1/4
  - AntePanel: `anchor_top=0.75`, `anchor_bottom=1.0` → 底部 1/4
- 三块互不重叠、响应式填充分区
- PanelBg 全透明，左侧面板区域透出 `table_bg` 牌桌纹理
- **右侧全高度 ink-bleed 渐隐**（`panel_edge_fade.gdshader`，`fade_start=0.64`，渐隐范围加大）
- ScoreCardVBox 使用 `layout_mode=1` + `anchors_preset=15`（VBoxContainer 自动排列子项）

### 3.2 ScoreCard (310px)

| 元素 | 字号 | 颜色 | 用途 |
|------|------|------|------|
| ColXiLabel | 32px | 列#C4A843金 / 喜accent | 列×累乘 + 喜预览 |
| ScoreLabel | 48px | `(0.941, 0.929, 0.894)` 白 | "気 N" |
| ProgressBar | 28px | 灰底+金 fill, 圆角 6px | 进度条 |
| TargetScoreLabel | **28px** | `(0.478, 0.478, 0.416)` 灰 | "封印 N" |

StyleBox: `content_margin(16,16,68,16)`，`bg_color #0F281F` 不透明度 0.6。**无边框、无圆角。**
ScoreCardVBox 子序：`ColXiLabel → HandTypeRow → ScoreLabel → ProgressBar → TargetScoreLabel`

### 3.3 HandTypeRow (合入 ScoreCardVBox 内)

VBoxContainer 含 3 行，每行 HBoxContainer 对应一墩：

```
影  对子  37×2  Lv.2
瞬  顺子  50×3  Lv.4
滅  同花  53×4  Lv.1
```

每行布局：墩名(40px R) | 牌型名(弹性 L) | 分数(70px R) | Lv badge(弹性 L)

墩名颜色：影 `#588CF2` / 瞬 `#BFBFCB` / 滅 `#F24D4D`
牌型名：白色 `#F0EDE4`
分数颜色：同该行墩名
Lv badge 色阶：Lv.1-2 `#7A7A7A` 灰 | Lv.3-4 `#588CF2` 蓝 | Lv.5-6 `#C4A843` 金。Lv.0 隐藏。
鼠标悬浮 Lv badge 弹出浮层（牌型名+等级+筹码/倍率），计分 Phase 1 跟随分数 GOLD flash。

**数据源：** `NinKingGameState.star_chart_levels`（`{ HandType3: int }`）→ `CardData.get_hand_type3_leveled_chips/mult()`。

由 `HandTypeLabeler._update_dun_types()` 实时更新。Lv hover tooltip 由同文件 `_show_lv_tooltip()` 实现。

### 3.4 MatchPanel (中间 1/4) — 直属于 LeftPanel

**面板颜色：** 全透明（无 StyleBoxFlat）。无圆角、无边框。
**渐隐：** `ShaderMaterial_match_fade` (panel_edge_fade.gdshader)
**锚定：** `anchor_top=0.5`, `anchor_bottom=0.75`（ScoreCard 底部 → AntePanel 顶部）

| 字段 | text 示例 | 字号 |
|------|----------|------|
| MatchTitle | "比赛信息" | 20px |
| HandsLabel | "討伐 2" | 28px |
| GoldLabel | "$12" | 28px |

### 3.5 AntePanel (底部 1/4) — 直属于 LeftPanel

**面板颜色：** 全透明（无 StyleBoxFlat）。无圆角、无边框。
**渐隐：** `ShaderMaterial_ante_fade` (panel_edge_fade.gdshader)
**锚定：** `anchor_top=0.75`, `anchor_bottom=1.0` (LeftPanel 底部 1/4)

| 字段 | text 示例 | 字号 |
|------|----------|------|
| BarrierLabel | "结界 3/8" | 28px |
| RoundLabel | "回合 1" | 28px |

---

## §4 CenterColumn — 中央游戏区

(未变更，略，参见 `06-ui-layout-reference.md`)

## §5-§8

(未变更，略)
