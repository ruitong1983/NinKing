# NinKing Main Game UI 设计方案

> **建立日期:** 2026-06-10 | **最后同步:** 2026-06-23 | **关联场景:** `ninking_main.tscn` (比鸡模式) + `ninking_clean_main.tscn` (消除模式) + `ui_manager.gd`
> **风格权威:** [`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) · 治愈漫画风（旧少年漫画方向已于 2026-06-23 废弃）
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
│ │ 结界 1/8      │   · ShopOverlay (内嵌商店, GameLayout 保持可见)
│ │ 回合 1        │   · LevelComplete
│ │               │   · GameOver
│ └───────────────┘   · VictoryOverlay
│                     · DeckViewer
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
    │   │   │       ├── ColXiLabel (32px 喜accent, autowrap, 自然高度)
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
    │       ├── HandArea (HBox 1138×728) ← 操作按钮区（空闲中）
    │       ├── PlayBtn (160×56)    ← 「討伐」28px 手牌区左侧
    │       ├── DunArea (Panel 620×728)
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
    │       ├── AiRearrangeBtn (200×48) ← 「陣形」24px 底栏居中
    │       ├── DeckBtn (200×48)        ← "牌库: 52"
    │       └── ColumnLabelRow (HBox)   ← 列分标签 (Col0/Col1/Col2)
    │
    ├── ScoringOverlay (Control)        ← ⛔ 未使用 (Balatro 风内联动画)
    │   ├── OverlayBg (ColorRect)
    │   ├── HandNameLabel
    │   ├── ScoreValueLabel
    │   └── ScoreBreakdown
    │
    ├── ShopOverlay (Control)           ← 内嵌商店覆盖层 (Phase C, GameLayout 保持可见)
    │   └── ShopPanel (1000×650 居中)    ← 通过 ui_manager 动态实例化
    │
    ├── LevelComplete (Control)         ← 过关覆盖层
    ├── GameOver (Control) [%GameOver]           ← 失败覆盖层
    │   ├── OverlayBg (ColorRect)               ← #000 80%, 全屏
    │   ├── ContentPanel (Panel) 520x360 居中    → Kenney 暖米卡牌面板 (KUI2)
    │   │   ├── GameOverLabel [%GameOverLabel]  → "失败" 48px 深红 #C0392B, 居中
    │   │   ├── ScoreSummary [%ScoreSummary]    → "战绩: 结界 X · 忍気 Y" 26px 深褐 #3D2B1A, 居中
    │   │   ├── RetryButton [%RetryButton]      → "重新开始" 24px (manga 样式)
    │   │   └── BackToMenuButton [%BackToMenuButton] → "返回主菜单" 20px flat
    │   │   ⚡ pop_in 入场: scale 0.75→1.0 + 淡入 0.2s
    │   │
    │   ├── VictoryOverlay (Control) 全屏        ← 通关覆盖层
    │   │   ├── OverlayBg (ColorRect)           ← #000 70%, 全屏
    │   │   ├── ContentPanel (Panel) 520x320 居中 → Kenney 暖米卡牌面板 (KUI2)
    │   │   │   ├── VictoryLabel                → "忍道制霸!" 48px 金色 #D4A843, 居中
    │   │   │   ├── StatsSummary                → "通关! 全结界制霸 · 忍気 N" 26px 深褐 #3D2B1A
    │   │   │   └── MenuButton                 → "返回主菜单" 24px flat (manga 样式)
    │   │   │   ⚡ pop_in 入场: scale 0.75→1.0 + 淡入 0.2s
    │   │
    └── DeckViewer (Control)                    ← 牌库查看器
```

---

## §3 LeftPanel — 左侧信息面板

### 3.1 布局

- 宽度 `420px`，`size_flags_horizontal = 0`（固定宽度）
- **四面板锚定布局 (2026-06-22)：** 四面板直属于 `LeftPanel`，全部 `layout_mode=1`（锚定）
  - HandTypePanel: `anchor_top=0`, `anchor_bottom=0.3` → 顶部 30%
  - ScorePanel: `anchor_top=0.3`, `anchor_bottom=0.7` → 中部 40%
  - MatchPanel: `anchor_top=0.7`, `anchor_bottom=0.9` → 中部 20%
  - AntePanel: `anchor_top=0.9`, `anchor_bottom=1.0` → 底部 10%
- 四块互不重叠、响应式填充分区
- PanelBg 全透明，左侧面板区域透出 `table_bg` 牌桌纹理
- **右侧全高度 ink-bleed 渐隐**（`panel_edge_fade.gdshader`，`fade_start=0.64`)
- 面板使用 Kenney 暖纸风纹理（`panel_beige`/`panel_beigeLight`），`texture_filter=1`（NEAREST）
- 各 VBox 容器统一 `offset_left=24`、`offset_top=10`、`offset_bottom=-10` 留出内边距
- 文字色统一深褐 `Color(0.24, 0.18, 0.11)`，特殊标注除外

### 3.2 ScorePanel (中部 40%) — 喜/分数/进度

`panel_beigeLight` 纹理。使用 VBoxSpacer 实现底部锚定：ColXiLabel 居顶部自然高度，VBoxSpacer 撑满中间，ScoreLabel/ProgressBar/TargetScoreLabel 固定在底部。

| 元素 | 字号 | 颜色 | 用途 |
|------|------|------|------|
| ColXiLabel | 40px | `#D93333` 喜红 | 喜名称列表，autowrap 自动换行，自然高度不撑开 |
| ScoreLabel | 48px | `#3D2B1A` 深褐 | "気 N" |
| ProgressBar | 28px | 灰底+金 fill, 圆角 6px | 进度条 |
| TargetScoreLabel | **28px** | `#3D2B1A` 深褐 | "封印 N" |

ScoreVBox 子序：`ColXiLabel → VBoxSpacer → ScoreLabel → ProgressBar → TargetScoreLabel`
ColXiLabel 不可见时（喜为空）`ui_manager.gd` 自动隐藏，VBoxSpacer 自适应调整。

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
Lv badge 色阶：Lv.1-2 `#5C5C5C` 深灰 | Lv.3-4 `#3A6FD8` 深蓝 | Lv.5-6 `#9A8230` 暗金（2026-06-23 加深，在米色面板上保证对比度）。Lv.0 隐藏。
鼠标悬浮 Lv badge 弹出浮层（牌型名+等级+筹码/倍率），计分 Phase 1 跟随分数 GOLD flash。

**数据源：** `NinKingGameState.star_chart_levels`（`{ HandType3: int }`）→ `CardData.get_hand_type3_leveled_chips/mult()`。

由 `HandTypeLabeler._update_dun_types()` 实时更新。Lv hover tooltip 由同文件 `_show_lv_tooltip()` 实现。

### 3.4 MatchPanel (中部 20%) — 直属于 LeftPanel

`panel_beige` 纹理。标题和金币在暖米色面板上使用加深色保证可读性。
**渐隐：** `ShaderMaterial_match_fade` (panel_edge_fade.gdshader)
**锚定：** `anchor_top=0.7`, `anchor_bottom=0.9`

| 字段 | text 示例 | 字号 | 颜色 |
|------|----------|------|------|
| MatchTitle | "比赛信息" | 20px | `#66471E` 暖铜褐 |
| HandsLabel | "討伐 2" | 28px | `#3D2B1A` 深褐 |
| GoldLabel | "$12" | 48px | `#B8852E` 暗金 |

### 3.5 AntePanel (底部 10%) — 直属于 LeftPanel

`panel_beige` 纹理。
**渐隐：** `ShaderMaterial_ante_fade` (panel_edge_fade.gdshader)
**锚定：** `anchor_top=0.9`, `anchor_bottom=1.0` (LeftPanel 底部 10%)

| 字段 | text 示例 | 字号 | 颜色 |
|------|----------|------|------|
| BarrierLabel | "结界 3/8" | 28px | `#3D2B1A` 深褐 |
| RoundLabel | "回合 1" | 28px | `#3D2B1A` 深褐 |

| 字段 | text 示例 | 字号 |
|------|----------|------|
| BarrierLabel | "结界 3/8" | 28px |
| RoundLabel | "回合 1" | 28px |

---

## §4 CenterColumn — 中央游戏区

(未变更，略，参见 `06-ui-layout-reference.md`)

## §5-§8

(未变更，略)
