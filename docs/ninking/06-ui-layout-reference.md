# NinKing UI 布局参考文档

> **维护索引：** 本文档定义全部 UI 区域命名、层级结构、节点访问路径和更新接口。
> 代码中所有 `%` 引用、`@onready` 变量、信号绑定均以此文档为准。
> **风格权威：**[`16-art-direction-principles.md`](16-art-direction-principles.md) — UI 配色/组件/特效以 16 号文档为准，本文档 §6 为速查摘要。

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

> **校验依据：** `scenes/ninking/ninking_main.tscn` 实际节点结构（2026-06-11 最终同步）。
> 旧版文档中 `MainArea`/`StatusPanel`/`ActionBar`/`DiscardBtn`/`SwapBtn` 等节点不存在，已删除。

```
NinKingMain (Control) 1920×1080                [game_manager.gd]
├── CardManager (CardManager)                  [card-manager 框架]
├── GameBg (TextureRect) [%GameBg]             — 桌布背景 table_bg.png, 结界主题动态 modulate
└── UIManager (Control) [%UIManager]           [ui_manager.gd]
    │
    ├── LevelIntro (Control) [%LevelIntro]     — 封印入场水印 (view: "intro")
    │   ├── IntroOverlay (ColorRect)            #000 80%
    │   ├── BossPortrait (TextureRect) [%BossPortrait]
    │   ├── LevelLabel [%LevelLabel]            "结界X · 修罗ノ封印" 48px
    │   └── TargetLabel [%TargetLabel]          "封印 300" 24px
    │
    │   │   ├── ScoreCard (Panel)           — 得分卡, anchor_top=0, anchor_bottom=0.5 (上半 1/2)
    │   │   │   └── ScoreCardVBox           — anchors full rect (layout_mode=1)
    │   │   │       ├── ColXiLabel (32px 列金/喜accent)
    │   │   │       ├── HandTypeRow (VBoxContainer)    — 合入 ScoreCardVBox
    │   │   │       │   ├── Row影 → ShadowDun/ShadowType/ShadowScore/%ShadowLv
    │   │   │       │   ├── Row瞬 → FlashDun/FlashType/FlashScore/%FlashLv
    │   │   │       │   └── Row滅 → DestroyDun/DestroyType/DestroyScore/%DestroyLv
    │   │   │       ├── ScoreLabel (48px "忍気 N")
    │   │   │       ├── ColXiLabel [%ColXiLabel]   "列: x16  喜: x2" 32px 金
    │   │   │       ├── HandTypeRow (VBoxContainer)
    │   │   │       │   ├── Row影 (HBoxContainer, separation=8)
    │   │   │       │   │   ├── ShadowDun (Label 40px R)  "影" 20px 蓝 #588CF2
    │   │   │       │   │   ├── ShadowType [%ShadowType]  "对子" 20px 白 (弹性)
    │   │   │       │   │   └── ShadowScore [%ShadowScore] "37×2" 20px 蓝 70px R
    │   │   │       │   ├── Row瞬 (HBoxContainer, separation=8)
    │   │   │       │   │   ├── FlashDun (Label 40px R)   "瞬" 20px 银灰 #BFBFCB
    │   │   │       │   │   ├── FlashType [%FlashType]    "顺子" 20px 白 (弹性)
    │   │   │       │   │   └── FlashScore [%FlashScore]   "50×3" 20px 银灰 70px R
    │   │   │       │   └── Row滅 (HBoxContainer, separation=8)
    │   │   │       │       ├── DestroyDun (Label 40px R) "滅" 20px 红 #F24D4D
    │   │   │       │       ├── DestroyType [%DestroyType] "同花" 20px 白 (弹性)
    │   │   │       │       └── DestroyScore [%DestroyScore] "53×4" 20px 红 70px R
    │   │   │       ├── ScoreLabel [%ScoreLabel]     "忍気 0" 48px
    │   │   │       ├── ProgressBar [%ProgressBar]   封印进度条 28px (右端=312px=渐隐起始)
    │   │   │       └── TargetScoreLabel [%TargetScoreLabel] "封印 300" 28px
    │   │   │
    │   │   ├── MatchPanel (Panel)             — anchor_top=0.5, anchor_bottom=0.75 (中间 1/4, 无圆角, 无边框, 挂 fade)
    │   │   │   └── MatchVBox                  — anchors full, separation=10
    │   │   │       ├── MatchTitle             "比赛信息" 20px 金 #C4A843
    │   │   │       ├── HandsLabel [%HandsLabel] "討伐 X" 28px
    │   │   │       └── GoldLabel [%GoldLabel]    "$X" 28px
    │   │   │
    │   │   └── AntePanel (Panel)              — anchor_top=0.75, anchor_bottom=1.0 (底部 1/4, 无圆角, 无边框, 挂 fade)
    │   │       └── AnteVBox                   — anchors full, separation=10
    │   │           ├── BarrierLabel [%BarrierLabel] "结界 X/8" 28px
    │   │           └── RoundLabel [%RoundLabel]     "回合 X" 28px
    │   │
    │   └── CenterColumn (VBoxContainer)          — 中央区域 (fill)
    │       ├── NinjaBar (HBoxContainer) [%NinjaBar]  — 忍者牌栏 5 槽
    │       ├── StatusLabel [%StatusLabel]        — 约束提示 24px
    │       ├── HandArea (HBoxContainer) [%HandArea] 1138×728
    │       │   ├── PlayBtn [%PlayBtn]            "討伐" 84×116
    │       │   ├── DunArea (Panel) 620×728       — 三墩容器
    │       │   │   ├── DunHead (Panel) [%DunHead] — 影 (hand[0-2])
    │       │   │   │   ├── HeadLabel [%HeadLabel]
    │       │   │   │   ├── HeadTypeLabel [%HeadTypeLabel]
    │       │   │   │   └── HeadCards (Hand) [%HeadCards]
    │       │   │   ├── DunMiddle (Panel) [%DunMiddle] — 瞬 (hand[3-5])
    │       │   │   │   ├── MiddleLabel [%MiddleLabel]
    │       │   │   │   ├── MiddleTypeLabel [%MiddleTypeLabel]
    │       │   │   │   └── MiddleCards (Hand) [%MiddleCards]
    │       │   │   ├── DunTail (Panel) [%DunTail] — 滅 (hand[6-8])
    │       │   │   │   ├── TailLabel [%TailLabel]
    │       │   │   │   ├── TailTypeLabel [%TailTypeLabel]
    │       │   │   │   └── TailCards (Hand) [%TailCards]
    │       │   │   └── ColumnLabelRow (HBoxContainer) — 列牌型标签 (A9)
    │       │   │       ├── Col0Label [%Col0Label]
    │       │   │       ├── Col1Label [%Col1Label]
    │       │   │       └── Col2Label [%Col2Label]
    │       │   └── AiRearrangeBtn [%AiRearrangeBtn] "陣\n形" 84×116
    │       └── DeckBtn [%DeckBtn]               "牌库: XX" 200×48
    │
    ├── ScoringOverlay (Control) [%ScoringOverlay] — 计分覆盖层 (z_index:10, 场景保留兼容)
    │   ├── OverlayBg (ColorRect)                #000 70%
    │   ├── HandNameLabel [%HandNameLabel]       "高牌" 48px
    │   ├── ScoreValueLabel [%ScoreValueLabel]   "+ 0" 72px 金
    │   └── ScoreBreakdown [%ScoreBreakdown]     24px 分解文字
    │   ⛔ LevelComplete (已删除, 2026-06-12 Phase E)
    │      Phase E 移除: 计分动画结束后金币飞入左面板, ~1.5s 自动进 Shop
    │
    ├── ShopOverlay (Control) [%ShopOverlay]    — 底部滑入商店 (view: "shop", mouse_filter=STOP)
    │   │ ⚠️ shop 状态下 GameLayout + GameBg 保持可见 (左边栏 + 顶部忍者牌)
    │   │    面板只覆盖底部 364~1080 区域, ShopOverlay 用 STOP 拦截区域外点击
    │   └── 运行时: add_child(load("shop_panel.tscn").instantiate())
    │       └── ShopPanel (Control) — 右下角锚定, 800×716, x:880 y:364, [shop_ui.gd]
    │           ├── Overlay (ColorRect)                BarrierTheme.panel 纯色 ← 非透明遮罩
    │           ├── TopBorder (ColorRect)              800×3, #1A1A1A 墨色分割线
    │           ├── TitleBar (ColorRect)                800×40  #1E1E33 100%
    │           ├── ShopSubtitle (Label)                "萬屋！" 32px 左对齐 x:24
    │           ├── GoldLabel [%GoldLabel]              "$0" 20px 纯文字, x:610
    │           ├── RerollBtn [%RerollBtn]              "入替 $3" 97×28, x:685 y:6
    │           ├── AbilityGrid (GridContainer)         680×380 2列 h_sep:20, x:24-704 y:58-438
    │           │   └── [ShopSlot × 4]                  横排 330×190 忍者卡
    │           ├── Separator (ColorRect)               680×1 y:458, #000 15%
    │           ├── ItemColumn (GridContainer)          680×190 2列 h_sep:20, x:24-704 y:469-659
    │           │   └── [ShopSlot × 2]                  横排 330×190 星图卡
    │           ├── BottomBar (ColorRect)               800×40 y:676, #1E1E33 100%
    │           └── ContinueBtn [%ContinueBtn]          "討伐へ ▶" 180×32 居中
    │
    │       ⛔ NextLevelHint (已删除, 零高度)
    │       ⛔ B5 EnchantTargetSelector (已删除, 无信号连接)
    │
    ├── GameOver (Control) [%GameOver]           — 失败弹窗 (view: "gameover")
    │   ├── OverlayBg #000 80%
    │   ├── GameOverLabel [%GameOverLabel]       "失败" 48px 红
    │   ├── ScoreSummary [%ScoreSummary]
    │   ├── RetryButton [%RetryButton]           "重新开始"
    │   └── BackToMenuButton [%BackToMenuButton] "返回主菜单"
    │
    ├── VictoryOverlay (Control)                 — 通关弹窗 (view: "victory")
    │   ├── OverlayBg #000 70%
    │   ├── VictoryLabel                         "忍道制霸!" 56px
    │   ├── StatsSummary
    │   └── MenuButton                           "返回主菜单"
    │
    └── DeckViewer (Control) [%DeckViewer]       — 牌库查看器 (z_index:10)
        ├── ViewerBg (ColorRect) [%ViewerBg]     — 遮罩背景 #000 75%
        └── CardPanel (Panel) 900×640
            ├── TitleBar (HBoxContainer)          — 标题栏
            │   ├── ViewerTitle (Label) "牌库" 24px 金
            │   └── CloseBtn [%CloseBtn] "✕" (flat)
            ├── CountRow (HBoxContainer)
            │   ├── DrawCountLabel [%DrawCountLabel]    "牌堆: 0 张"
            │   └── DiscardCountLabel [%DiscardCountLabel] "手替札: 0 张"
            ├── CardScroll (ScrollContainer)
            │   └── CardGrid [%CardGrid] (GridContainer, 13列, 动态 NinKingCard)
            └── (CardPanel 边界)
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
| 宽度 | 420px |
| 背景 | `PanelBg` (ColorRect) **全透明** (保留节点供代码 barrier theme / BounceScore / toast 使用) |
| 渐隐 | `panel_edge_fade.gdshader` 挂载于 PanelBg + ScoreCard + MatchPanel + AntePanel |
| 用途 | 显示全部计分与状态数据 |

**布局方案 (2026-06-11 重构)：** LeftPanel 三面板锚定分区布局。
- **ContentVBox 已移除**，ScoreCard / MatchPanel / AntePanel 均为 LeftPanel 直接子节点，全部 `layout_mode=1`（锚定）
- **ScoreCard**: `anchor_top=0`, `anchor_bottom=0.5` → 上半 1/2（深绿半透明底，去金边）
- **MatchPanel**: `anchor_top=0.5`, `anchor_bottom=0.75` → 中间 1/4（暗红褐底，去金边）
- **AntePanel**: `anchor_top=0.75`, `anchor_bottom=1.0` → 底部 1/4（暗金琥珀底，去金边）
- 三块互不重叠、响应式填充分区，各面板保持独立底色

**Ink-bleed 渐隐：** `game_manager._ready()` 对 4 节点挂载 canvas_item shader,
`fade_start=0.64`，右边缘渐隐范围加大（从 64% 处开始），更深地融入背景。

**子区域：**

##### a. ScoreCard (上半 1/2) — 含 HandTypeRow

ScoreCardVBox 以 `layout_mode=1` 锚定，`offset_left=16, offset_right=-68`（左16px内边距，右边止于渐隐起始 269px = 420×64%），VBoxContainer 自动排列子项。

| 元素 | 字号 | 颜色 | 用途 |
|------|------|------|------|
| ColXiLabel | 32px | 列 `#C4A843` 金 / 喜 accent | 列×累乘 + 喜预览 (v4.0 替换 CMC) |
| HandTypeRow | — | — | **三墩牌型+分数 (已合入 ScoreCardVBox)** |
| ScoreLabel | 48px | `(0.941, 0.929, 0.894)` 白 | "気 N" |
| ProgressBar | 28px | 灰底 + 金 fill | 进度条, 两端圆角 6px |
| TargetScoreLabel | **28px** | 灰 `#7A7A6A` | "封印 N" |

ScoreCardVBox 子序：`ColXiLabel → HandTypeRow → ScoreLabel → ProgressBar → TargetScoreLabel`
旧 CMC (ChipsLabel/MultSign/MultLabel) 已替换为 ColXiLabel。
StyleBoxFlat: `content_margin(16,16,16,16)`，无边框、无圆角。`bg_color #0F281F` 不透明度 0.6。
内容宽度由 ScoreCardVBox 的 `offset_right=-68` 约束至渐隐起始。

##### b. HandTypeRow (VBoxContainer 含 3 行) — 位于 ScoreCardVBox 内

每行为 HBoxContainer，展示对应墩的牌型名 + 分数预览 + Lv badge（星图等级）：

| 行 | 墩名 (40px R) | 牌型名 (弹性 L) | 分数 (70px R) | Lv badge (弹性 L) |
|----|-------------|--------------|--------------|------------------|
| 影 | `ShadowDun` "影" #588CF2 | `%ShadowType` "对子" 白 | `%ShadowScore` "37×2" #588CF2 | `%ShadowLv` "Lv.2" 色阶 |
| 瞬 | `FlashDun` "瞬" #BFBFCB | `%FlashType` "顺子" 白 | `%FlashScore` "50×3" #BFBFCB | `%FlashLv` "Lv.4" 色阶 |
| 滅 | `DestroyDun` "滅" #F24D4D | `%DestroyType` "同花" 白 | `%DestroyScore` "53×4" #F24D4D | `%DestroyLv` "Lv.1" 色阶 |

分数 = (卡牌筹码 + 牌型筹码) × 牌型倍率，由 `HandTypeLabeler._update_dun_types()` 实时预览。
Lv badge 色阶：Lv.1-2 `#7A7A7A` 灰 | Lv.3-4 `#588CF2` 蓝 | Lv.5-6 `#C4A843` 金。Lv.0 不显示。鼠标悬浮 badge 弹出浮层显示牌型名+等级+筹码/倍率。计分 Phase 1 揭示时跟随分数 GOLD flash。

##### c. MatchPanel (中间 1/4) — 直属于 LeftPanel

| 字段 | 节点 | 格式 | 字号 |
|------|------|------|------|
| 标题 | `MatchTitle` | "比赛信息" | 20px |
| 已出牌数 | `HandsLabel` [%HandsLabel] | "討伐 X" | 28px |
| 金币 | `GoldLabel` [%GoldLabel] | "$X" | 28px |

**面板颜色：** `StyleBoxFlat_match_panel` — `bg_color #4A2020` (暗红褐)。无边框、无圆角。
**渐隐：** `ShaderMaterial_match_fade` (panel_edge_fade.gdshader, `fade_start=0.64`)
**锚定：** `anchor_top=0.5`, `anchor_bottom=0.75`（中间 1/4, 夹于 ScoreCard 与 AntePanel 之间）

##### d. AntePanel (底部 1/4) — 直属于 LeftPanel

| 字段 | 节点 | 格式 | 字号 |
|------|------|------|------|
| 结界 | `BarrierLabel` [%BarrierLabel] | "结界 X/8" | 28px |
| 回合 | `RoundLabel` [%RoundLabel] | "回合 X" | 28px |

**面板颜色：** `StyleBoxFlat_ante_panel` — `bg_color #3D2B1A` (暗金琥珀)。无边框、无圆角。
**渐隐：** `ShaderMaterial_ante_fade` (panel_edge_fade.gdshader, `fade_start=0.64`)
**锚定：** `anchor_top=0.75`, `anchor_bottom=1.0`（底部 1/4, LeftPanel 下半段）

#### 3.3.3 中央列 `CenterColumn`

| 属性 | 值 |
|------|-----|
| 位置 | LeftPanel 右侧，自适应填充 |

**子区域：**

##### a. 忍者牌栏 `NinjaBar`

| 属性 | 值 |
|------|-----|
| 节点 | `UIManager/GameLayout/CenterColumn/NinjaBar` |
| 访问名 | `%NinjaBar` |
| 容器 | `NinjaBarContainer` (extends CardContainer)，运行时动态实例化，挂载于 %NinjaBar 下 |
| 卡片类 | `NinjaInventoryCard` (extends Card)，125×175 固定尺寸 (5:7 对齐标准扑克) |
| 管理节点 | `NinjaBarNode` (Node)，%NinjaBar 的子节点，不参与布局 |
| 卡片 | 动态显示拥有的忍者牌，无空槽占位（Balatro 风） |
| 入场 | 刷新时 staggger pop-in（80ms 间隔，`GlobalTweens.pop_in`，pivot_offset 居中） |
| 移除 | 淡出+缩小（0.2s），其余卡自动重排 |
| 间距 | 弹性压缩 8~24px，居中排列，slot_width=125 固定 |
| 悬停 | DraggableObject hover → scale 1.15，上浮 -6px |
| 点击 | 左键 → Balatro 风 zoom-in 详情（全屏遮罩+卡面 4x+名+desc） |
| 拖拽 | Card-Framework 状态机驱动，DropZone 竖直分区检测落点，支持任意距离拖拽重排（check_card_can_be_dropped + get_partition_index 双重写绕过传感器限制） |
| 排序持久化 | `reorder_requested` 信号 → `NinjaBarNode._on_reorder_requested()` → `owned_ninjas` 数组顺序保存 |
| 刷新 | `NinjaBarNode.refresh(owned_ninjas, max_slots)` — 差值更新 |

##### b. 手牌区 `HandArea` (HBoxContainer, 1138×728)

| 属性 | 值 |
|------|-----|
| 组件场景 | `res://scenes/ninking/ninking_card.tscn` (NinKingCard) |
| 卡牌数 | **9** (3×3 三组) |
| 单牌尺寸 | 90×130 |
| 交互 | 点击两张牌互换（蓝高亮=交换源）；换牌模式（红高亮=标记丢弃） |
| 约束 | 影牌力 ≤ 瞬牌力 ≤ 滅牌力 |
| 约束满足 | 三道标签同时点亮为属性 accent 色 + 集中线从标签向卡牌汇聚，StatusLabel 留空 |
| 约束违规 | 违规段标签变灰 + 小「×」叠印（漫画错误标记）；StatusLabel 显示原因 |
| 高亮算法 | 逐对匹配：Pair1(影≤瞬) 点亮影+瞬，Pair2(瞬≤滅) 点亮瞬+滅。全满足=全亮可討伐 |

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

> **校验依据：** `scripts/ninking/ui/ui_manager.gd` 实际 API（2026-06-11 代码扫描）。
> `[` 方括号 `]` 内为可选参数，`→` 为返回类型。类型按 Godot 4 GDScript 实际标注。

### UIManager 公开方法（`ui_manager.gd`）

```gdscript
# ── 视图 ──
func show_view(view: String) -> void
  # "intro"|"game"|"scoring"|"complete"|"shop"|"gameover"|"victory"

# ── 结界入场 ──
func on_seal_start(barrier: int, seal_idx: int, target: int, seal_lord_name: String) -> void
  # 设 boss_portrait 纹理+visible；设 LevelLabel/TargetLabel 文字；重置分数/討伐/金币显示

# ── 计分面板 ──
func update_score(current: int, target: int) -> void
  # ScoreLabel "忍気 N" + ProgressBar max_value/value
func update_gold(amount: int) -> void
  # GoldLabel "$N"
func update_match_info(plays_left: int) -> void
  # HandsLabel "討伐 N"
func update_target(target: int) -> void
  # TargetScoreLabel "封印 N"

# ── 手牌 ──
func refresh_hand(hand: Array[CardData.PlayingCard]) -> void
  # 完全刷新 9 张手牌（委托 HandDisplay + HandInteraction + DunHighlighter）
func refresh_groups(
  head_cards_arr: Array[CardData.PlayingCard],
  mid_cards_arr: Array[CardData.PlayingCard],
  tail_cards_arr: Array[CardData.PlayingCard],
  constraint_ok: bool
) -> void
  # 分组刷新，直接设 play_btn.disabled = not constraint_ok

# ── 忍者栏 ──
func refresh_ninjas(owned_ninjas: Array, max_slots: int) -> void
  # 委托 NinjaBarNode.refresh()（差值更新 + stagger pop-in）。
  # max_slots 保留以兼容调用方；无空槽占位（Balatro 风）。
  # 详见 NinjaBarNode: add_ninja() / remove_ninja() / move_ninja()。

# ── 计分结果 ──
func show_scoring_result(
  head_eval: HandEvaluator3.EvalResult,
  mid_eval: HandEvaluator3.EvalResult,
  tail_eval: HandEvaluator3.EvalResult,
  total_score: int
) -> void
func set_victory(barrier: int, score: int) -> void
func show_game_over(reason: String, barrier: int, score: int) -> void
func show_xi_popup(xis: Array[String]) -> void

# ── 闪效 ──
func flash_all_hand_cards() -> void
func flash_hand(hand: Hand) -> void

# ── 牌库查看器 ──
func update_deck_count(draw_count: int, discard_count: int) -> void
func restore_ui_state() -> void
  # 场景重载后恢复全部 UI（调用 on_seal_start + update_score/match_info/gold + refresh_hand/ninjas + deck 统计）

# ── 🏪 商店 (Phase C) ──
func show_shop(shop_mgr: ShopManager, gold: int, colors: Dictionary) -> void
  # 创建 shop_panel 实例 + 连线信号 + show_view("shop") + 入场动画
func hide_shop() -> void
  # play_shop_exit → queue_free → 隐藏
func is_shop_open() -> bool
  # _current_shop_panel != null 且 is_instance_valid 且 visible
func shop_panel_update_gold(gold: int) -> void
func shop_panel_update_reroll_cost(cost: int) -> void  # B4
func shop_panel_refresh_stock() -> void
func shop_panel_mark_item_purchased(item_id: String) -> void  # B6: 标记星图卡为已购
func get_current_shop_panel() -> Control
```

### UIManager 信号（`ui_manager.gd:260-263`）

```gdscript
# 🏪 商店 — game_manager 连接这些信号
signal shop_purchase_requested(ability_data: Dictionary)
signal shop_item_purchase_requested(item_data: Dictionary)
signal shop_reroll_requested()
signal shop_continue_requested()
```

### 数据流

```
NinKingGameState (autoload)
  │
  ├── signal state_changed(new_state: State)
  │   └── game_manager._on_state_changed()
  ├── signal score_updated(current_score: int, target_score: int)
  │   └── game_manager._on_score_updated()
  ├── signal plays_changed(remaining: int)
  │   └── game_manager._on_plays_changed()
  ├── signal gold_changed(amount: int)
  │   └── game_manager._on_gold_changed()
  ├── signal hand_updated(hand: Array)
  │   └── game_manager._on_hand_updated()
  ├── signal arrangement_changed(arrangement: Arrangement)
  │   └── game_manager._on_arrangement_changed()
  ├── signal seal_started(barrier: int, seal_idx: int, target: int, seal_lord_name: String)
  │   └── game_manager._on_seal_started()
  └── signal xi_triggered(xis: Array[String])
      └── game_manager._on_xi_triggered()
            │
            └── 全部委托给 UIManager 对应方法
```

> **已删除的旧 API：** `swap_used`（信号不存在）、`level_started`（改名为 `seal_started`）、
> `update_seal_info()` / `show_upgrade_option()` / `on_shop_exit()`（代码中不存在）。

---

## 6. 配色与风格速查

> **权威来源：**[`16-art-direction-principles.md`](16-art-direction-principles.md) — 本文档 §6 为 UI 布局视角的速查摘要，以 16 号文档为准。

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
| `docs/ninking/01-game-design.md` | 游戏设计文档 |
| `docs/ninking/03-technical-design.md` | 技术设计文档 |
| `docs/ninking/05-image-asset-generation-plan.md` | 素材生成方案 |
| `docs/ninking/06-ui-layout-reference.md` | **本文档** |
| `docs/ninking/07-shop-ui-design.md` | 商店 UI 设计文档 |
| `docs/ninking/10-main-ui-design.md` | 主 UI 设计文档 |
