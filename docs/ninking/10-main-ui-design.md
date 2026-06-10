# NinKing Main Game UI 设计方案

> **建立日期:** 2026-06-10 | **关联场景:** `ninking_main.tscn` + `ui_manager.gd`
> **风格权威:** [`16-art-direction-principles.md`](16-art-direction-principles.md) · 少年漫画风

## §1 概述

Main 场景是核心游戏界面。玩家在此查看手牌、排列三墩、出牌计分、触发商店。

```
LevelIntro (2s)
    │
    ▼
GameLayout ───────────────────────────────────────┐
│ LeftPanel (380px) │ CenterColumn (1000px+)      │
│ ┌───────────────┐ │ ┌─────────────────────────┐ │
│ │ ScoreCard     │ │ │ AbilityBar (忍者栏)     │ │
│ │ 0 x 0         │ │ ├─────────────────────────┤ │
│ │ 忍気 0        │ │ │ StatusLabel             │ │
│ │ ████░░░░ 300  │ │ ├─────────────────────────┤ │
│ ├───────────────┤ │ │ HandArea                │ │
│ │ 影: - 瞬: -   │ │ │ [討伐] [影][瞬][滅] [换牌] [陣形] │
│ │   滅: -       │ │ ├─────────────────────────┤ │
│ ├───────────────┤ │ │ DeckBtn + ColumnLabelRow │ │
│ │ 比赛信息      │ │ └─────────────────────────┘ │
│ │ 討伐 0        │ │                              │
│ │ 手替え 0      │ └──────────────────────────────┘
│ │ $0            │
│ ├───────────────┤   叠加层（按需显示/隐藏）:
│ │ 結界 1/8      │   · ScoringOverlay
│ │ 回合 1        │   · LevelComplete
│ ├───────────────┤   · GameOver
│ │ NinjaArea     │   · VictoryOverlay
│ │ (忍者槽位列表) │   · DeckViewer
│ └───────────────┘
└──────────────────────────────────────────────────┘
```

---

## §2 场景结构

```
NinKingMain (Control) [game_manager.gd]
├── CardManager (CardManager)           ← Card-Framework 核心
├── GameBg (ColorRect)                  ← 动态背景 (結界配色)
│
└── UIManager (Control) [ui_manager.gd]
    │
    ├── LevelIntro (Control)            ← 关卡入场覆盖层
    │   ├── IntroOverlay (ColorRect)    ← 黑底 80% 不透明
    │   ├── LevelLabel (Label)          ← "第 N 关" 48px 金色
    │   └── TargetLabel (Label)         ← "封印 300" 24px
    │
    ├── GameLayout (HBoxContainer)      ← 主游戏布局 (默认隐藏)
    │   │
    │   ├── LeftPanel (Control)         ← 左侧信息面板 380px
    │   │   ├── PanelBg (ColorRect)     ← 暗绿底
    │   │   └── ContentVBox            ← 内容垂直排列
    │   │       ├── SpacerTop           ← 弹性顶部间距
    │   │       ├── ScoreCard (Panel)   ← 得分卡片 220px
    │   │       │   └── ScoreCardVBox
    │   │       │       ├── ChipsMultContainer (HBox)
    │   │       │       │   ├── ChipsLabel (48px 金色)
    │   │       │       │   ├── MultSign (48px "x", 灰色)
    │   │       │       │   └── MultLabel (48px 红色)
    │   │       │       ├── ScoreLabel (48px "忍気 N")
    │   │       │       ├── ProgressBar (28px)
    │   │       │       └── TargetScoreLabel (24px "封印 N")
    │   │       ├── Spacer2
    │   │       ├── HandTypeRow (HBox 44px)
    │   │       │   ├── ShadowType (24px 蓝 "影: -")    ← 约束状态：亮=满足，灰=违规
    │   │       │   ├── FlashType (24px 灰 "瞬: -")    ← 约束状态 + outline 递进
    │   │       │   └── DestroyType (24px 红 "滅: -")  ← 约束状态 (见 §3.3)
    │   │       ├── Spacer3
    │   │       ├── MatchPanel (Panel 160px)
    │   │       │   └── MatchVBox
    │   │       │       ├── MatchTitle (16px "比赛信息")
    │   │       │       ├── HandsLabel (24px "討伐 N")
    │   │       │       ├── RedrawsLabel (24px "手替え N")
    │   │       │       └── GoldLabel (24px 金色 "$N")
    │   │       ├── Spacer4
    │   │       ├── AntePanel (Panel)
    │   │       │   └── AnteVBox
    │   │       │       ├── BarrierLabel (24px "結界 N/M")
    │   │       │       └── RoundLabel (24px "回合 N")
    │   │       └── SpacerBottom
    │   │
    │   └── CenterColumn (VBoxContainer)
    │       ├── AbilityBar (HBox)       ← 忍者牌槽位行
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
    │       │   ├── RedrawBtn (84×116)  ← 「换牌」
    │       │   └── AiRearrangeBtn (84×116) ← 「陣形」
    │       ├── DeckBtn (200×48)        ← "牌库: 52"
    │       └── ColumnLabelRow (HBox)   ← 列分标签 (Col0/Col1/Col2)
    │
    ├── ScoringOverlay (Control)        ← ⛔ 计分时不再显示 (Balatro 风内联动画)
    │   ├── OverlayBg (ColorRect)       ← 保留场景节点，view=scoring 不触发 visible
    │   ├── HandNameLabel               ← 未使用（改用 HeadTypeLabel 等原位标签）
    │   ├── ScoreValueLabel             ← 未使用（改用 _float_score_gain 从 score_label 飘起）
    │   └── ScoreBreakdown              ← 未使用（改用 _show_breakdown_toast 左侧栏提示）
    │
    ├── LevelComplete (Control)         ← 过关覆盖层
    │   ├── OverlayBg
    │   ├── CompleteLabel (48px 金色)    ← "过关!"
    │   ├── RewardLabel
    │   └── ToShopButton
    │
    ├── GameOver (Control)              ← 失败覆盖层
    │   ├── OverlayBg (ColorRect)
    │   ├── GameOverLabel               ← "忍気不足" / "封印失败"
    │   ├── ScoreSummary (Label)        ← 战绩摘要 "結界 3 · 忍気 380"
    │   ├── RetryButton                 ← "重试"
    │   └── MenuButton                  ← "返回主菜单"
    │
    ├── VictoryOverlay (Control)        ← 通关覆盖层（独立于 GameOver）
    │   ├── OverlayBg (ColorRect)
    │   ├── VictoryLabel (48px 金)      ← "忍道制霸!"
    │   ├── StatsSummary (Label)        ← 通关统计
    │   └── MenuButton                  ← "返回主菜单"
    │
    └── DeckViewer (Control)            ← 牌库查看器（详见 06-ui-layout-reference.md §3.7）
        ├── ViewerBg (ColorRect)
        └── CardPanel (Panel)
            ├── TitleBar → ViewerTitle + CloseBtn
            ├── CountRow → DrawCountLabel + DiscardCountLabel
            └── CardScroll → CardGrid
```

---

## §3 LeftPanel — 左侧信息面板

### 3.1 布局

宽度 `380px`，`size_flags_horizontal = 0`（固定宽度不拉伸）。

内容通过 `VBoxContainer` 垂直排列，Spacer 弹性元素占据富余空间。

### 3.2 ScoreCard (220px)

| 元素 | 字号 | 颜色 | 用途 |
|------|------|------|------|
| ChipsLabel | 48px | `(0.831, 0.659, 0.263)` 金 | 筹码和 |
| MultSign | 48px | `(0.478, 0.478, 0.416)` 灰 | "x" |
| MultLabel | 48px | `(0.878, 0.251, 0.251)` 红 | 倍率和 |
| ScoreLabel | 48px | `(0.941, 0.929, 0.894)` 白 | "忍気 N" |
| ProgressBar | 28px | 灰底+金 fill | 进度条 |
| TargetScoreLabel | 24px | 灰 | "封印 N" |

StyleBox: `content_margin 16px`，`bg_color (0.059, 0.157, 0.133, 0.6)` 暗绿半透明，`border 2px 金色`。

### 3.3 牌型信息行 (HandTypeRow)

HandTypeRow 显示 **三墩约束状态**，而非牌型分数。牌型名在 DunArea 内的 `HeadTypeLabel/MiddleTypeLabel/TailTypeLabel` 显示。

| 元素 | 颜色 | 约束逻辑 |
|------|------|---------|
| ShadowType "影: -" | `(0.35, 0.55, 0.95)` 蓝 | **Pair1 (影≤瞬) 满足 → 点亮为属性accent色**；违规 → 灰化+「×」叠印 |
| FlashType "瞬: -" | `(0.75, 0.75, 0.8)` 灰 | **Pair1 或 Pair2 满足 → 点亮**；两边都不满足 → 灰化 |
| DestroyType "滅: -" | `(0.95, 0.3, 0.3)` 红 | **Pair2 (瞬≤滅) 满足 → 点亮为属性accent色**；违规 → 灰化+「×」叠印 |

V20 outline 递进：`font_outline_size` 影(1px) < 瞬(2px) < 滅(3px)。

约束满足时 StatusLabel 留空；违规时显示错误原因（"影勢過強"/"滅力不足"/"重排三道"）。

### 3.4 比赛信息 (MatchPanel, 160px)

| 字段 | text 示例 |
|------|----------|
| HandsLabel | "討伐 2" — 剩余出牌次数 |
| RedrawsLabel | "手替え 3" — 剩余换牌次数 |
| GoldLabel | "$12" — 当前金币 |

### 3.5 结界信息 (AntePanel)

弹性高度，内容由 BarrierLabel + RoundLabel 组成。

| 字段 | text 示例 |
|------|----------|
| BarrierLabel | "結界 3/8" |
| RoundLabel | "回合 1" |

---

## §4 CenterColumn — 中央游戏区

### 4.1 AbilityBar

`HBoxContainer`，`separation 24px`，居中。动态生成 `AbilitySlot` 实例，每槽 `100×140`。

### 4.2 StatusLabel

24px 绿色 `(0.251, 0.753, 0.251)`，居中。状态文本由 `hand_interaction.gd` 管理：
- `"影 <= 瞬 <= 滅 -- 可以出牌"` — 合法排列
- `"影 > 瞬！调整手牌顺序"` — 非法排列
- `"选择要替换的卡牌 (最多 N 张)"` — 换牌模式

### 4.3 HandArea — 手牌+三墩区

```
┌──┬──────────────────────────┬──┬──┐
│討│  ┌────────────────────┐  │换│陣│
│伐│  │ 影: 散牌           │  │牌│形│
│  │  │ [K♠] [Q♠] [J♠]   │  │  │  │
│  │  ├────────────────────┤  │  │  │
│  │  │ 瞬: 对子           │  │  │  │
│  │  │ [3♥] [3♦] [A♣]   │  │  │  │
│  │  ├────────────────────┤  │  │  │
│  │  │ 滅: 同花           │  │  │  │
│  │  │ [7♣] [5♣] [2♣]   │  │  │  │
│  │  └────────────────────┘  │  │  │
└──┴──────────────────────────┴──┴──┘
 84    620×728 (DunArea)         84 84
```

| 元素 | 尺寸 | 说明 |
|------|------|------|
| PlayBtn | 84×116 | 「討伐」红色渐变三态 |
| DunArea | 620×728 | 三墩容器 (Panel + v_margin 20px) |
| DunHead | 620×224 | 影墩 sub_panel |
| DunMiddle | 620×224 | 瞬墩 sub_panel |
| DunTail | 620×224 | 滅墩 sub_panel |
| RedrawBtn | 84×116 | 「换牌」蓝色渐变三态 |
| AiRearrangeBtn | 84×116 | 「陣形」AI 自动重排 |

三墩间距 `8px`。每墩内含 `Hand` 节点 (3 张，max_hand_spread 600)，`swap_only_on_reorder = true`。

### 4.4 按钮

| 按钮 | text | 背景色 | 字体色 | disabled 条件 |
|------|------|--------|--------|-------------|
| PlayBtn | `討伐` | 红底 `(0.88,0.25,0.25)` | 白 `(1,1,1)` | 牌序不合法 |
| RedrawBtn | `换牌` | 蓝底 `(0.25,0.50,0.82)` | 白 `(1,1,1)` | 无换牌次数 |
| AiRearrangeBtn | `陣形` | 默认 button_normal | accent 色 (BarrierTheme) | 空闲 (换牌模式启用) |
| DeckBtn | `牌库: N` | 默认 panel 色 | 金 `(0.83,0.66,0.26)` | — |

> **⚠️ accent 覆盖例外**: `game_manager._on_seal_started()` 只对**中性背景按钮**（AiRearrangeBtn + overlay 按钮）应用 BarrierTheme accent 字体色。PlayBtn/RedrawBtn/DeckBtn 已在场景中预设独立配色（红底白字/蓝底白字/金文字），代码**不覆盖**其字体色，防止同色不可读。

### 4.5 ColumnLabelRow

三列标签 `Col0Label / Col1Label / Col2Label`，默认 `visible = false`。当列分触发（同花顺/豹子等）时显示列牌型名称。

---

## §5 配色原则

### 5.1 动态配色 (V19 + V25)

`BarrierTheme.get_colors(barrier_num)` 返回当前结界配色，应用于：
- `GameBg.color` — 背景底色
- `PanelBg.color` — 左面板底色
- `ProgressBar` fill — 进度条（当前固定金色）
- 中性背景按钮字体色 — `AiRearrangeBtn` + overlay 按钮（`ToShopButton`/`RetryButton`/`BackToMenuButton`/`VictoryMenuButton`）使用 `c.accent` 覆盖字体色
- **PlayBtn/RedrawBtn/DeckBtn 不参与 accent 字体覆盖** — 它们在场景中已预设独立配色（见 §4.4）

### 5.2 固定色

| 用途 | 颜色 | 位置 |
|------|------|------|
| 主要文字 | `(0.941, 0.929, 0.894)` 白 | ScoreLabel, HandsLabel, etc. |
| 强调金 | `(0.831, 0.659, 0.263)` | ChipsLabel, 标题, 边框 |
| 倍率红 | `(0.878, 0.251, 0.251)` | MultLabel |
| 状态绿 | `(0.251, 0.753, 0.251)` | StatusLabel |
| 灰色 | `(0.478, 0.478, 0.416)` | 次要信息 |

---

## §6 交互流

```
SEAL_INTRO (LevelIntro visible)
  │  await 2.0s
  │  → GameLayout visible = true
  │  → PLAYING state
  ▼
PLAYING
  ├── 卡牌拖拽 → HandInteraction._on_card_dragged()
  │    → 跨墩交换 → HandDisplay.refresh()
  │    → 检查排序合法性 → StatusLabel 更新
  │
  ├── [陣形] → AI auto-rearrange
  │
  ├── [换牌] → REDRAW 状态
  │    → 选择卡牌 → [手替え確認] → HandDisplay.refresh()
  │
  └── [討伐] → SCORING 状态
       → Balatro 风内联计分（无全屏暗幕）：
         ① 三墩牌型在 HeadTypeLabel 等原位 scale_pop 揭示
         ② 左侧栏 BounceScore 分数弹性着陆 (~1.2s)
         ③ "+N" 从 score_label 上浮飘出
         ④ 筹码×倍率内幕 toast 淡出
       → 判定
          ├── 过关 (封印达成) → LevelComplete 显示 → [商店] → shop.tscn
          ├── 失败 (忍気不足) → GameOver 显示 → [重试/返回主菜单]
          └── 通关 (全8結界制霸) → VictoryOverlay 显示 → [返回主菜单]
```

---

## §7 字体 (C10)

| 层级 | 字体 | 字号 |
|------|------|------|
| 主要数字 (Chips/Mult/Score) | SourceHanSansSC-Heavy | 48px |
| 按钮文字 | SourceHanSansSC-Heavy | 24px |
| 标签 | SourceHanSansSC-Heavy | 24px |
| 次要标签 | SourceHanSansSC-Heavy | 16px |

全局 `manga_theme.tres` 默认字体 = `SourceHanSansSC-Heavy`。

---

## §8 待实现

| # | 内容 | 优先级 |
|---|------|--------|
| 1 | V25 八属性亮色 BarrierTheme 重写 → 动态配色更新 | P0 ✅ |
| 2 | V28 UI 漫画风 StyleBox 重写（三态按钮/面板/三墩边框） | P0 ✅ |
| 3 | V26 漫画粒子替换（shuriken/sakura → manga_burst/ink） | P1 |
| 4 | V29 文档场景树与实际 .tscn 对齐 | P1 |
| 5 | V15 屏风转场 (当前硬切 change_scene) | P3 |
| 6 | VictoryOverlay 独立覆盖层实现 — 通关庆祝 + 统计 + 返回主菜单 | P1 |
| 7 | GameOver 补充 ScoreSummary + MenuButton 节点 | P2 |
