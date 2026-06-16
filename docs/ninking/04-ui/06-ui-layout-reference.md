# NinKing UI 布局参考文档

> **维护索引：** 本文档定义全部 UI 区域命名、层级结构、节点访问路径和更新接口。
> 代码中所有 `%` 引用、`@onready` 变量、信号绑定均以此文档为准。
> **风格权威：**[`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) — UI 配色/组件/特效以 16 号文档为准，本文档 §6 为速查摘要。

---

## 1. 命名约定

### 术语替换

| 旧称 | 新称 | 说明 |
|------|------|------|
| 小丑牌 (Joker) | **能力牌** (Ability) | 持续被动加成 |
| JokerContainer | **NinjaBar** | 顶部横向忍者槽 |
| JokerSlot | **NinjaSlot** | 单个忍者槽位 |
| JOKER_SLOT_SCENE | **NINJA_SLOT_SCENE** | 槽位组件场景 |

### 节点命名规则

| 前缀 | 类别 | 示例 |
|------|------|------|
| `%` 前缀 | 跨层级引用节点 (unique_name_in_owner) | `%ScoreLabel` |
| `PNL_` | 面板容器 | `PNL_MatchInfo` |
| `LBL_` | 标签文字 | `LBL_Score` |
| `BTN_` | 按钮 | `BTN_Play` |
| `BAR_` | 进度/容器条 | `BAR_Progress` |
| `GRID_` | 网格布局 | `GRID_Hand` |
| `AB_` | 能力栏相关 | `AB_Slot` |
| `OVL_` | 覆盖弹窗（**逻辑分类前缀**，非实际节点名） | `OVL_Scoring` → `ScoringOverlay` |

### 与 Figma 命名的分层

> **Figma 设计稿** 使用中文功能描述命名（详见 `08-figma-naming-convention.md`），
> 用于设计沟通和团队协作。**Godot 代码层** 使用英文前缀命名（上表），用于节点引用。
> 两者不直接映射——Figma 关注"设计师看到什么"，Godot 关注"代码如何访问"。

---

## 2. 场景树全图

> **校验依据：** `scenes/ninking/ninking_main.tscn` 实际节点结构（2026-06-16 同步）。
> `[game_manager.gd]` = 脚本绑定 ｜ `[%Name]` = unique_name_in_owner ｜ `（运行时动态加载）` = 代码创建

```
NinKingMain (Control) 1920×1080                      [game_manager.gd]
├── CardManager (CardManager)                         [card-framework 框架]
├── GameBg (TextureRect) [%GameBg]                    — 桌布背景, 结界动态 modulate
└── UIManager (Control) [%UIManager]                  [ui_manager.gd]
    │
    ├── LevelIntro (Control) [%LevelIntro]            — 封印入场水印 (view: "intro")
    │   ├── IntroOverlay (ColorRect)                  #000 80%
    │   ├── BossPortrait (TextureRect) [%BossPortrait]
    │   ├── LevelLabel (Label) [%LevelLabel]           "结界X · 修罗ノ封印" 48px
    │   └── TargetLabel (Label) [%TargetLabel]         "封印 300" 24px
    │
    ├── GameLayout (HBoxContainer) [%GameLayout]      — 游戏主界面布局 (view: "game")
    │   │
    │   ├── LeftPanel (Control) [%LeftPanel]           — 左侧 420px 信息面板
    │   │   ├── PanelBg (ColorRect) [%PanelBg]         — 全透明 (结界动态 modulate)
    │   │   │
    │   │   ├── HandTypePanel (Panel) [%HandTypePanel] — anchor_top=0 anchor_bottom=0.5
    │   │   │   └── HandTypeVBox (Control)
    │   │   │       ├── Row影 (Control)
    │   │   │       │   ├── ShadowDun (Label)          "影" 20px #588CF2
    │   │   │       │   ├── ShadowType (Label) [%ShadowType]
    │   │   │       │   ├── ShadowLv (Label) [%ShadowLv]
    │   │   │       │   └── ShadowScore (RichTextLabel) [%ShadowScore]
    │   │   │       ├── Row瞬 (Control)
    │   │   │       │   ├── FlashDun (Label)           "瞬" 20px #BFBFCB
    │   │   │       │   ├── FlashType (Label) [%FlashType]
    │   │   │       │   ├── FlashLv (Label) [%FlashLv]
    │   │   │       │   └── FlashScore (RichTextLabel) [%FlashScore]
    │   │   │       ├── Row滅 (Control)
    │   │   │       │   ├── DestroyDun (Label)         "滅" 20px #F24D4D
    │   │   │       │   ├── DestroyType (Label) [%DestroyType]
    │   │   │       │   ├── DestroyLv (Label) [%DestroyLv]
    │   │   │       │   └── DestroyScore (RichTextLabel) [%DestroyScore]
    │   │   │       ├── ColDivider (ColorRect)          — 列分割线
    │   │   │       └── ColumnBar (Control)             — 三列牌型/分数/等级
    │   │   │           ├── LeftColType (Label) [%LeftColType]
    │   │   │           ├── MidColType (Label) [%MidColType]
    │   │   │           ├── RightColType (Label) [%RightColType]
    │   │   │           ├── LeftColLabel (Label)
    │   │   │           ├── LeftColLv (Label)
    │   │   │           ├── LeftColScore (RichTextLabel)
    │   │   │           ├── MidColLabel (Label)
    │   │   │           ├── MidColLv (Label)
    │   │   │           ├── MidColScore (RichTextLabel)
    │   │   │           ├── RightColLabel (Label)
    │   │   │           ├── RightColLv (Label)
    │   │   │           └── RightColScore (RichTextLabel)
    │   │   │
    │   │   ├── ScorePanel (Panel) [%ScorePanel]       — anchor_top=0.5 anchor_bottom=0.75
    │   │   │   └── ScoreVBox (VBoxContainer)
    │   │   │       ├── ColXiLabel (Label) [%ColXiLabel] "列: x16  喜: x2" 32px
    │   │   │       ├── ScoreLabel (Label) [%ScoreLabel] "忍気 0" 48px
    │   │   │       ├── ProgressBar (ProgressBar) [%ProgressBar] 28px
    │   │   │       └── TargetScoreLabel (Label) [%TargetScoreLabel] "封印 0" 28px
    │   │   │
    │   │   ├── MatchPanel (Panel) [%MatchPanel]       — anchor_top=0.75 anchor_bottom=0.875
    │   │   │   └── MatchVBox (VBoxContainer)
    │   │   │       ├── MatchTitle (Label)              "比赛信息" 20px 金
    │   │   │       ├── HandsLabel (Label) [%HandsLabel] "討伐 X" 28px
    │   │   │       └── GoldLabel (Label) [%GoldLabel]  "$X" 28px
    │   │   │
    │   │   └── AntePanel (Panel) [%AntePanel]          — anchor_top=0.875 anchor_bottom=1.0
    │   │       └── AnteVBox (VBoxContainer)
    │   │           ├── BarrierLabel (Label) [%BarrierLabel] "结界 X/8" 28px
    │   │           └── RoundLabel (Label) [%RoundLabel]     "回合 X" 28px
    │   │
    │   ├── CenterColumn (Control) [%CenterColumn]      — 中央游戏区 (fill)
    │   │   ├── NinjaBar (Control) [%NinjaBar]           — 忍者牌栏（运行时动态加载）
    │   │   ├── HandArea (HBoxContainer) [%HandArea]    — 操作按钮区
    │   │   │   └── PlayBtn (Button) [%PlayBtn]         "討伐" 84×116
    │   │   ├── DunArea (Panel) [%DunArea]              — 三墩卡牌区 620×728
    │   │   │   ├── ColumnLabelRow (HBoxContainer)      — 列牌型标签行
    │   │   │   │   ├── Col0Label (Label) [%Col0Label]
    │   │   │   │   ├── Col1Label (Label) [%Col1Label]
    │   │   │   │   └── Col2Label (Label) [%Col2Label]
    │   │   │   ├── HeadLabel (Label) [%HeadLabel]       "影"
    │   │   │   ├── HeadTypeLabel (Label) [%HeadTypeLabel]
    │   │   │   ├── MiddleLabel (Label) [%MiddleLabel]   "瞬"
    │   │   │   ├── MiddleTypeLabel (Label) [%MiddleTypeLabel]
    │   │   │   ├── TailLabel (Label) [%TailLabel]       "滅"
    │   │   │   ├── TailTypeLabel (Label) [%TailTypeLabel]
    │   │   │   └── CardGrid (Control) [%CardGrid]       — 3×3 卡牌网格
    │   │   │       [hand_card_container.gd]
    │   │   └── AiRearrangeBtn (Button) [%AiRearrangeBtn] "陣\n形" 84×116
    │   │
    │   ├── StatusLabel (Label) [%StatusLabel]          — 约束提示 24px
    │   └── DeckBtn (Button) [%DeckBtn]                 "牌库: XX" 200×48
    │
    ├── ScoringOverlay (Control) [%ScoringOverlay]     — 计分覆盖层 (z_index:10)
    │   ├── OverlayBg (ColorRect)                      #000 70%
    │   ├── HandNameLabel (Label) [%HandNameLabel]     "高牌" 48px
    │   ├── ScoreValueLabel (Label) [%ScoreValueLabel] "+ 0" 72px 金
    │   └── ScoreBreakdown (Label) [%ScoreBreakdown]   24px 分解文字
    │
    ├── ShopOverlay (Control) [%ShopOverlay]            — 底部滑入商店（运行时动态加载 shop_panel.tscn）
    │   ⛔  LevelComplete (已删除, 2026-06-12 Phase E)
    │   ⛔  ShopPanel 详细子树 → 见 shop_panel.tscn / 07-shop-ui-design.md
    │
    ├── GameOver (Control) [%GameOver]                  — 失败弹窗 (view: "gameover")
    │   ├── OverlayBg (ColorRect)                      #000 80%
    │   ├── GameOverLabel (Label) [%GameOverLabel]     "失败" 48px 红
    │   ├── RetryButton (Button) [%RetryButton]         "重新开始"
    │   ├── BackToMenuButton (Button) [%BackToMenuButton] "返回主菜单"
    │   └── ScoreSummary (Label) [%ScoreSummary]
    │
    ├── VictoryOverlay (Control)                        — 通关弹窗 (view: "victory")
    │   ├── OverlayBg (ColorRect)                      #000 70%
    │   ├── VictoryLabel (Label)                        "忍道制霸!" 56px
    │   ├── StatsSummary (Label)
    │   └── MenuButton (Button)                         "返回主菜单"
    │
    ├── DeckViewer (Control) [%DeckViewer]              — 牌库查看器 (z_index:10)
    │   ├── ViewerBg (ColorRect) [%ViewerBg]            #000 75%
    │   └── CardPanel (Panel) 900×640
    │       ├── TitleBar (HBoxContainer)
    │       │   ├── ViewerTitle (Label)                 "牌库" 24px 金
    │       │   └── CloseBtn (Button) [%CloseBtn]       "✕"
    │       ├── CountRow (HBoxContainer)
    │       │   ├── DrawCountLabel (Label) [%DrawCountLabel] "牌堆: 0 张"
    │       │   └── DiscardCountLabel (Label) [%DiscardCountLabel] "手替札: 0 张"
    │       └── CardScroll (ScrollContainer)
    │           └── DeckCardGrid (GridContainer) [%DeckCardGrid] 13 列
    │
    ├── StatusLabel (Label) [%StatusLabel]              — 约束提示 24px
    └── DeckBtn (Button) [%DeckBtn]                     "牌库: XX" 200×48
```

---

## 3. 区域定义

### 3.1 关卡入场视图 `LevelIntro`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/LevelIntro` |
| 访问名 | `%LevelIntro` |
| 默认状态 | 隐藏 |
| 用途 | 每关开始前的 0.5 秒结界浮水印展示 (Phase C 极简化) |

**数据源：** `LevelConfig.get_level(n)` → 关卡号 + 封印值

### 3.2 游戏主视图 `GameLayout`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/GameLayout` |
| 访问名 | `%GameLayout` |
| 默认状态 | 隐藏 |
| 用途 | 游戏进行中的主操作界面 |

#### 3.3.2 状态面板 `LeftPanel`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/GameLayout/LeftPanel` |
| 访问名 | `%LeftPanel` |
| width | 480px (custom_minimum_size) |
| 背景 | `PanelBg` (ColorRect) **全透明** (保留节点供代码 barrier theme / BounceScore / toast 使用) |
| 渐隐 | `panel_edge_fade.gdshader` 挂载于 HandTypePanel + ScorePanel + MatchPanel + AntePanel |
| 用途 | 显示全部计分与状态数据 |

**布局方案 (v2026-06-16)：** LeftPanel 四面板锚定分区布局。

| 面板 | 节点 | 锚定 | 高度 |
|------|------|------|------|
| 牌型+列展示 | `HandTypePanel` | `top=0, bottom=0.4` | 40% |
| 分数/进度 | `ScorePanel` | `top=0.4, bottom=0.65` | 25% |
| 讨伐/金币 | `MatchPanel` | `top=0.65, bottom=0.85` | 20% |
| 结界/回合 | `AntePanel` | `top=0.85, bottom=1.0` | 15% |

四块互不重叠、响应式填充分区，各面板保持独立底色。

**Ink-bleed 渐隐：** 4 节点挂载 `panel_edge_fade.gdshader`, `fade_start=0.64`，右边缘渐隐。

**子区域：**

##### a. HandTypePanel (顶部 0~40%) — 三墩牌型 + 列牌型

节点路径 `UIManager/GameLayout/LeftPanel/HandTypePanel`，`bg_color #0F281F` 不透明度 0.6。

```
HandTypePanel (Panel) [%HandTypePanel]
└── HandTypeVBox (Control)
    ├── Row影 (Control)
    │   ├── ShadowDun (Label)          "影" 20px #588CF2
    │   ├── ShadowType [%ShadowType]   "对子" 20px 白 (弹性)
    │   ├── ShadowLv [%ShadowLv]       Lv badge 色阶
    │   └── ShadowScore [%ShadowScore] "37×2" RichText
    ├── Row瞬 (Control)
    │   ├── FlashDun (Label)           "瞬" 20px #BFBFCB
    │   ├── FlashType [%FlashType]     "顺子" 20px 白
    │   ├── FlashLv [%FlashLv]
    │   └── FlashScore [%FlashScore]   "50×3" RichText
    ├── Row滅 (Control)
    │   ├── DestroyDun (Label)         "滅" 20px #F24D4D
    │   ├── DestroyType [%DestroyType] "同花" 20px 白
    │   ├── DestroyLv [%DestroyLv]
    │   └── DestroyScore [%DestroyScore] "53×4" RichText
    ├── ColDivider (ColorRect)          — 分割线
    └── ColumnBar (Control)             — 三列牌型/分数
        ├── LeftColType [%LeftColType]
        ├── MidColType [%MidColType]
        ├── RightColType [%RightColType]
        └── (Left/Mid/Right ColLabel + ColLv + ColScore)
```

分数 = (卡牌筹码 + 牌型筹码) × 牌型倍率，由 `HandTypeLabeler._update_dun_types()` 实时预览。
Lv badge 色阶：Lv.1-2 `#7A7A7A` 灰 | Lv.3-4 `#588CF2` 蓝 | Lv.5-6 `#C4A843` 金。Lv.0 不显示。

##### b. ScorePanel (中部 40%~65%) — 分数/进度

| 元素 | 字号 | 颜色 | 用途 |
|------|------|------|------|
| ColXiLabel [%ColXiLabel] | 32px | 列 `#C4A843` 金 / 喜 accent | 列×累乘 + 喜预览 |
| ScoreLabel [%ScoreLabel] | 48px | `(0.941, 0.929, 0.894)` 白 | "気 N" |
| ProgressBar [%ProgressBar] | 28px | 灰底 + 金 fill | 进度条 |
| TargetScoreLabel [%TargetScoreLabel] | 28px | 灰 `#7A7A6A` | "封印 N" |

ScoreVBox 子序：`ColXiLabel → ScoreLabel → ProgressBar → TargetScoreLabel`
StyleBoxFlat: `content_margin(16,...)`，无边框、无圆角。`bg_color #0F281F` 0.6。

##### c. MatchPanel (中部 65%~85%) — 比赛信息

| 字段 | 节点 | 格式 | 字号 |
|------|------|------|------|
| 标题 | `MatchTitle` | "比赛信息" | 20px |
| 已出牌数 | `HandsLabel` [%HandsLabel] | "討伐 X" | 28px |
| 金币 | `GoldLabel` [%GoldLabel] | "$X" | 28px |

**面板颜色：** `StyleBoxFlat_match_panel` — `bg_color #4A2020` (暗红褐)。无边框、无圆角。
**渐隐：** `ShaderMaterial_match_fade` (panel_edge_fade.gdshader, `fade_start=0.64`)

##### d. AntePanel (底部 85%~100%) — 结界/回合

| 字段 | 节点 | 格式 | 字号 |
|------|------|------|------|
| 结界 | `BarrierLabel` [%BarrierLabel] | "结界 X/8" | 28px |
| 回合 | `RoundLabel` [%RoundLabel] | "回合 X" | 28px |

**面板颜色：** `StyleBoxFlat_ante_panel` — `bg_color #3D2B1A` (暗金琥珀)。无边框、无圆角。
**渐隐：** `ShaderMaterial_ante_fade` (panel_edge_fade.gdshader, `fade_start=0.64`)

#### 3.3.3 中央列 `CenterColumn`

| 属性 | 值 |
|------|-----|
| 节点 | `UIManager/GameLayout/CenterColumn` (Control) |
| 访问名 | `%CenterColumn` |
| 布局 | LeftPanel 右侧，自适应填充 |
| 子节点 | NinjaBar, HandArea, DunArea, AiRearrangeBtn (平级) |
| 注意 | StatusLabel 和 DeckBtn 不在 CenterColumn 下，直属于 UIManager |

**子区域：**

##### a. 忍者牌栏 `NinjaBar`

| 属性 | 值 |
|------|-----|
| 节点 | `UIManager/GameLayout/CenterColumn/NinjaBar` (Control) |
| 访问名 | `%NinjaBar` |
| 容器 | `NinjaBarContainer` (extends CardContainer)，运行时动态实例化 |
| 卡片类 | `NinjaInventoryCard` (extends Card)，125×175 |
| 管理节点 | `NinjaBarNode` (Node)，%NinjaBar 的子节点 |
| 行为详见 | [`02-cards/22-display-card-base-spec.md`](../02-cards/22-display-card-base-spec.md) |

##### b. 操作按钮区 `HandArea` (HBoxContainer)

| 属性 | 值 |
|------|-----|
| 节点 | `UIManager/GameLayout/CenterColumn/HandArea` [%HandArea] |
| 用途 | 存放操作按钮 (PlayBtn) |
| 子节点 | `PlayBtn` (Button) [%PlayBtn] "討伐" 84×116 |
| 注意 | DunArea 是 HandArea 的**平级兄弟节点**，非子节点 |

##### c. 三墩卡牌区 `DunArea` (Panel, 620×728)

| 属性 | 值 |
|------|-----|
| 节点 | `UIManager/GameLayout/CenterColumn/DunArea` [%DunArea] |
| 用途 | 展示 3×3 卡牌网格 + 墩标签 + 列标签 |
| 结构 | 扁平——无 DunHead/DunMiddle/DunTail 包裹层，各标签和 CardGrid 都是 DunArea 直子 |

```
DunArea (Panel) [%DunArea]
├── ColumnLabelRow (HBoxContainer)        — 列牌型标签
│   ├── Col0Label (Label) [%Col0Label]
│   ├── Col1Label (Label) [%Col1Label]
│   └── Col2Label (Label) [%Col2Label]
├── HeadLabel (Label) [%HeadLabel]         "影"
├── HeadTypeLabel (Label) [%HeadTypeLabel]
├── MiddleLabel (Label) [%MiddleLabel]     "瞬"
├── MiddleTypeLabel (Label) [%MiddleTypeLabel]
├── TailLabel (Label) [%TailLabel]         "滅"
├── TailTypeLabel (Label) [%TailTypeLabel]
└── CardGrid (Control) [%CardGrid]         — 3×3 卡牌网格, [hand_card_container.gd]
```

| 约束 | 规则 |
|------|------|
| 约束满足 | HeadType/MiddleType/TailType 三标签同时点亮为 accent 色; StatusLabel 留空 |
| 约束违规 | 违规段标签变灰 + 「×」叠印; StatusLabel 显示原因 |
| 高亮算法 | 逐对匹配 Pair1(影≤瞬) 点亮影+瞬, Pair2(瞬≤滅) 点亮瞬+滅 |

### 3.4 计分流程 (SCORING 状态)

Balatro 风内联动画（无全屏暗幕），4 个 Phase：

**Phase 1 — 三墩逐卡揭示 (渐强三幕)**
- 每墩内 3 张牌依次金闪 + COUNT_TICK 嘀声
- 节奏递降：影 0.06s/牌 → 瞬 0.09s/牌 → 滅 0.12s/牌
- 每墩揭示后爆牌型名，效果逐级升级 + 各墩专属 accent flash（蓝/金/红）
  - 影: scale_pop(1.2x) + GROUP_REVEAL
  - 瞬: scale_pop(1.4x) + GROUP_REVEAL + 微震
  - 滅: TRANS_QUAD 放大→TRANS_SPRING 稳定 + 漫画粒子 + 屏震 + hit_stop

**Phase 2 — 计分弹跳**
- BounceScore 数字弹性着陆 (~2.02s): 蓄力→暴涨→过冲回落→进度条填充→面板发光
- "+N" 从 score_label 上浮飘出 (~1.0s)
- 筹码×倍率内幕 toast 淡出

**Phase 2.5 — 定格脉冲**
- await 2.0s 确保 BounceScore 完全落地
- 分数数字慢速呼吸脉动 (1.0↔1.06, 1.2s) + 面板 barrier_color 泛光

**Phase 3 — 喜效果**（触发时）
- 粒子爆发 + hit_stop + 屏震 + 喜名称 toast + fanfare

**Phase 4 — 判定**
- 过关: 粒子庆祝 + hit_stop → finalize
- 失败: 屏震 + 红闪 → finalize
- 继续: → finalize

### 3.5-3.8 其他视图

(详见 §4 视图映射表：ScoringOverlay / LevelComplete / GameOver / VictoryOverlay / DeckViewer / ShopOverlay)

---

## 4. 视图状态切换

```
   game_manager     
   _on_state_changed
        │
        ▼
   ┌──────────┐    ┌──────────┐
   │LevelIntro│    │ GameBg   │
   │ visible=T│    │ visible=T│
   └────┬─────┘    └──────────┘
        │ 0.5s 后
        ▼
   ┌──────────┐
   │GameLayout│  ← 游戏主界面
   │ visible=T│
   └────┬─────┘
        │
   ┌────┴─────┬──────────┬──────────┬──────────┐
   ▼          ▼          ▼          ▼          ▼
Scoring  LevelComplete  GameOver  VictoryOverlay
Overlay  (封印达成)    (忍気不足)  (全结界制霸)
```

**`show_view()` 映射（`ui_manager.gd:175`）：**

| view 参数 | GameBg | LevelIntro | GameLayout | Scoring | LevelComplete | ShopOverlay | GameOver | VictoryOverlay |
|-----------|--------|------------|------------|---------|---------------|-------------|----------|----------------|
| `"intro"` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `"game"` | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `"scoring"` | ✅ | ❌ | ✅(Balatro内联) | ❌ | ❌ | ❌ | ❌ | ❌ |
| `"complete"` | ⛔ 已废弃 (Phase E) — 不再调用 | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ | ⛔ |
| `"shop"` | ✅(游戏背景可见) | ❌ | ✅(底部面板遮挡) | ❌ | ❌ | ✅(mouse_filter=STOP) | ❌ | ❌ |
| `"gameover"` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| `"victory"` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

> **注意：** `"scoring"` 状态下 GameLayout 保持可见（Balatro 风内联计分，无全屏暗幕），
> ScoringOverlay 始终隐藏——计分文字由 ResultScreenDisplay 在 scene tree 内联操作。
> **v2026-06-12 (底部滑入):** `"shop"` 视图下 GameBg + GameLayout 保持可见。
> 商店面板只覆盖屏幕底部 364~1080 区域，左边栏+顶部忍者牌栏始终可见。
> ShopOverlay 设 `mouse_filter=STOP` 防止误操作游戏区，面板无需全屏遮罩。
> `"complete"` 视图 **⛔ 已废弃 (Phase E)** — 不再调用。计分动画结束后金币飞入左面板 MatchPanel/GoldLabel，~1.5s 后自动进 Shop。

---

## 5. 更新接口速查

> **接口签名、信号定义与数据流已迁移至** [`06-tech/ui-signal-architecture.md`](../06-tech/ui-signal-architecture.md) **维护。**
> 本文档仅保留 UI 布局相关的内容。API 签名以代码层 `scripts/ninking/ui/ui_manager.gd` 为准。

---

## 6. 配色与风格速查

> **权威来源：**[`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) — 本文档 §6 为 UI 布局视角的速查摘要，以 16 号文档为准。

### 动态配色体系

> **NinKing 采用 8 属性动态配色。** 配色由 `BarrierTheme` (`scripts/ninking/barrier_theme.gd`) 集中管理，
> `game_manager._on_seal_started()` 自动切换 GameBg / PanelBg / ProgressBar / 按钮字体色。
> **不推荐硬编码色值**——请通过 `BarrierTheme.get_colors(barrier_num)` 获取当前属性对应配色。

### 8 属性配色表

| Ante | 属性 | 称谓 | bg | panel | accent |
|:----:|------|------|-----|-------|--------|
| 1 | **火** | 壱·火 | `(0.92,0.82,0.78)` 暖米 | `(0.96,0.90,0.86)` | `(0.90,0.18,0.10)` 烈焰红 |
| 2 | **水** | 弐·水 | `(0.78,0.86,0.92)` 淡蓝 | `(0.86,0.93,0.96)` | `(0.12,0.45,0.88)` 流水蓝 |
| 3 | **風** | 参·風 | `(0.80,0.90,0.82)` 淡绿 | `(0.88,0.95,0.90)` | `(0.15,0.72,0.38)` 疾风绿 |
| 4 | **雷** | 肆·雷 | `(0.94,0.90,0.78)` 暖金 | `(0.97,0.95,0.86)` | `(0.95,0.72,0.08)` 雷光金 |
| 5 | **土** | 伍·土 | `(0.88,0.82,0.75)` 暖棕 | `(0.94,0.90,0.85)` | `(0.75,0.40,0.15)` 大地琥珀 |
| 6 | **光** | 陸·光 | `(0.92,0.92,0.86)` 象牙 | `(0.97,0.97,0.92)` | `(0.90,0.78,0.15)` 光辉金 |
| 7 | **暗** | 漆·暗 | `(0.72,0.68,0.80)` 暗紫 | `(0.80,0.76,0.86)` | `(0.55,0.22,0.78)` 暗夜紫 |
| 8 | **无** | 捌·无 | `(0.82,0.82,0.84)` 银灰 | `(0.90,0.90,0.92)` | `(0.55,0.55,0.58)` 虚无灰 |

### 漫画风设计原则速查

| 原则 | 规范 |
|------|------|
| 圆角 | 6-8px（漫画不是像素） |
| 描边 | 2-3px 仿手绘描边，全局统一 `#1A1A1A` 墨色 |
| 按钮 | 三态：normal(accent底+2px描边) → hover(调亮+3px描边+scale 1.03) → pressed(调暗+下移2px) |
| 面板 | 属性 `panel` 色底 + 4px 柔和投影 |
| 三墩区分 | 影(1px虚线) / 瞬(2px实线+微glow) / 滅(3px粗描边) |
| 约束满足 | 三道标签同时点亮为 accent 色 + 集中线 |
| 约束违规 | 违规段标签变灰 + 「×」叠印 |

---

## 7. 文件索引

| 文件 | 职责 |
|------|------|
| `scenes/ninking/ninking_launcher.tscn` | 启动场景（自动跳转） |
| `scenes/ninking/ninking_main.tscn` | 主UI场景（本文档所述） |
| `scripts/ninking/ui/game_manager.gd` | 游戏流程控制 |
| `scripts/ninking/ui/ui_manager.gd` | UI显示管理（本文档 §5 所述） |
| `scripts/ninking/ui/hand_display.gd` | 手牌渲染（HandDisplay delegate） |
| `scripts/ninking/ui/hand_interaction.gd` | 交互状态机（点击/拖拽交换） |
| `scripts/ninking/ui/dun_highlighter.gd` | 三墩约束高亮 |
| `scripts/ninking/ui/ninja_bar_node.gd` | 忍者栏管理（diff 刷新/拖拽排序/详情浮层） |
| `scripts/ninking/ui/ninja_bar_container.gd` | 🆕 忍者栏 CardContainer（水平线性布局/DropZone 分区/拖拽重排） |
| `scripts/ninking/ui/ninja_inventory_card.gd` | 🆕 忍者库存卡（Card 子类 125×175/稀有度边框/名称标签） |
| `scripts/ninking/ui/result_screen_display.gd` | 结果屏幕渲染（计分/过关/失败/喜） |
| `scripts/ninking/ui/nin_king_tween.gd` | 项目级动画序列（商店入场/出场/reroll） |
| `scripts/ninking/ui/deck_viewer_controller.gd` | 牌库查看器 |
| `scripts/ninking/ui/ninking_card.gd` | 忍者卡牌显示 (Card Framework 扩展) |
| `scripts/ninking/ui/shop_ui.gd` | 商店 UI 控制 (ShopPanel) |
| `scripts/ninking/ui/ninja_inventory_card.gd` | 统一忍者卡 (忍者栏+商店, 替代旧 DisplayCardBase) |
| `scripts/ninking/ui/shop_slot.gd` | 🆕 商店展示容器 (NinjaCard + 购买UI) |
| `scripts/ninking/game_state.gd` | 游戏状态 autoload |
| `scripts/ninking/seal_controller.gd` | 出牌/封印逻辑 |
| `scripts/ninking/arrange_controller.gd` | 排列/规则收集 |
| `scripts/ninking/auto_arranger.gd` | 排列求解器 (AutoArranger) |
| `scripts/ninking/arrangement.gd` | 排列结果类 (Arrangement) |
| `scripts/ninking/hand_evaluator.gd` | 牌型评估 (HandEvaluator3) |
| `scripts/ninking/score_calculator.gd` | 计分引擎 (ScoreCalculator) |
| `scripts/ninking/score_result.gd` | 计分结果类 (ScoreResult) |
| `scripts/ninking/score_helpers.gd` | 计分/排列共享辅助函数 |
| `scripts/ninking/xi_detector.gd` | 喜检测器 |
| `scripts/ninking/barrier_config.gd` | 关卡/結界配置 |
| `scripts/ninking/barrier_theme.gd` | 8 属性亮色色板 BarrierTheme |
| `scripts/ninking/card_data.gd` | 卡牌数据定义 |
| `scripts/ninking/deck_manager.gd` | 牌库管理 |
| `scripts/ninking/ninja_data.gd` | 47 张忍者牌定义 + 图标路径 |
| `scripts/ninking/ninja_pool.gd` | 忍者牌随机抽取 |
| `scripts/ninking/ninja_scaling.gd` | 修炼成长引擎（B10 已接入 finalize_play） |
| `scripts/ninking/consumable_data.gd` | 道具卡数据 + 图标/底板路径 |
| `scripts/ninking/item_data.gd` | 物品数据 |
| `scripts/ninking/shop_manager.gd` | 商店管理 |
| `scripts/ninking/save_manager.gd` | 存档管理 |
| `scripts/ninking/card_back_generator.gd` | 卡牌背面/槽位背景程序绘制 |
| `scripts/tween/global_tweens.gd` | 全局动画管理器 autoload |
| `scripts/tween/tween_fx.gd` | TweenFX 子系统（stagger_spread 等） |
| `scripts/tween/bounce_score.gd` | 计分弹性着陆组件 |
| `scripts/tween/particle_pool.gd` | 粒子预设池 |
| `scripts/config/sound_bank.gd` | 音效常量 Bank |
| [`docs/ninking/01-gameplay/06-complete-redesign.md`](../01-gameplay/06-complete-redesign.md) | 核心玩法设计文档 |
| [`docs/ninking/06-tech/03-technical-design.md`](../06-tech/03-technical-design.md) | 技术设计文档 |
| [`docs/ninking/06-tech/ui-signal-architecture.md`](../06-tech/ui-signal-architecture.md) | UI 信号架构与数据流 |
| [`docs/ninking/04-ui/07-shop-ui-design.md`](07-shop-ui-design.md) | 商店 UI 设计文档 |
| [`docs/ninking/04-ui/10-main-ui-design.md`](10-main-ui-design.md) | 主 UI 设计文档 |
| [`docs/ninking/05-art/05-image-asset-generation-plan.md`](../05-art/05-image-asset-generation-plan.md) | 素材生成方案 |
