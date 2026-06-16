# Debug 计分测试场景

> **建立日期:** 2026-06-12 | **最后更新:** 2026-06-16 | **关联场景:** `debug_ninking_main.tscn` + `debug_controller.gd` + `debug_panel.gd`
> **风格权威:** 独立于主场景，零侵入设计。场景结构已与 `ninking_main.tscn` 对齐命名和层级。

## §1 概述

Debug 场景用于快速验证各种牌型组合下，配合忍者卡、星图卡的得分计算是否准确。从 Launch 场景右下角「DEBUG」按钮进入。界面布局与主场景保持一致，可以：

1. 从 52 张牌库中随意选择扑克放入 9 格（影/瞬/滅 各 3 张）
2. 任意选取忍者卡和星图卡，观察对计分的影响
3. 点击「討伐」触发 `ScoreCalculator.calculate()`，LeftPanel 即时显示完整计分
4. **发牌/随机/AI重排后即时预览喜信息**，左边栏 ColXiLabel 即刻更新（无需等到計分）

## §2 设计原则

| 原则 | 说明 |
|------|------|
| **零侵入** | 不引用 `UIManager`、`NinKingGameState`、`game_manager.gd` |
| **最大化复用** | `Hand.tscn` × 3、`NinKingCard`、`ScoreCalculator`、`HandEvaluator3`、`XiDetector`、`NinjaBarDisplay` 均直接从主场景复用 |
| **自管 UI** | LeftPanel 标签由 `debug_controller.gd` 手动更新，不依赖 `HandTypeLabeler`（其引用了 `NinKingGameState`） |
| **无副作用的计分** | `ScoreCalculator.calculate()` 是纯静态方法，调用不影响任何游戏状态 |

## §3 入口

Launch 场景右下角新增 Debug 按钮：

| 属性 | 值 |
|------|-----|
| 按钮名 | `DebugBtn` |
| 文本 | `DEBUG` |
| 位置 | 右下角 (offset_left=1540, offset_top=968, 300×72) |
| 颜色 | 暗红色 `#993333` |
| 行为 | `change_scene_to_file("res://scenes/ninking/debug_ninking_main.tscn")` |
| 隐藏条件 | 始终可见（开发用，无条件编译） |

**涉及修改：** `ninking_launcher.tscn`（加节点）+ `main_menu.gd`（4 行：`@onready` + 信号连接 + handler）

## §4 场景结构

```
NinKingDebug (Control) [debug_controller.gd]
├── GameBg (TextureRect)                    ← table_bg.png 全屏背景
├── CardManager (CardManager)               ← Card-Framework 核心（含 NinKingCardFactory）
├── DeckBtn (Button)                        ← "牌库: 52"（右下角，仅展示）
│
├── MainVBox (VBoxContainer, full rect)
│   │
│   ├── ContentRow (HBoxContainer, stretch=1)
│   │   │
│   │   ├── LeftPanel (Control, 420px)      ← 结构复制自主场景 LeftPanel
│   │   │   ├── ScoreCard (Panel, anchor 0~0.5)
│   │   │   │   └── ScoreCardVBox
│   │   │   │       ├── ColXiLabel          ← 喜预览（实时更新：发牌/重排即显示）
│   │   │   │       ├── HandTypeRow         ← 影/瞬/滅 牌型名+分数
│   │   │   │       ├── ScoreLabel          ← "気 N"
│   │   │   │       ├── ProgressBar
│   │   │   │       └── TargetScoreLabel    ← "封印 N"
│   │   │   ├── MatchPanel (anchor 0.5~0.75)
│   │   │   │   └── MatchVBox → HandsLabel / GoldLabel
│   │   │   └── AntePanel (anchor 0.75~1.0)
│   │   │       └── AnteVBox → BarrierLabel / RoundLabel
│   │   │
│   │   ├── CenterColumn (VBoxContainer, stretch=1)
│   │   │   ├── NinjaBar (Control)          ← 已选忍者展示
│   │   │   ├── StatusLabel                 ← 操作提示
│   │   │   ├── HandArea (HBoxContainer)
│   │   │   │   ├── PlayBtn [討伐]          ← 触发计分
│   │   │   │   └── DunArea (Panel)
│   │   │   │       ├── ColumnLabelRow (HBox)  ← 列牌型标签 (Col0/Col1/Col2)
│   │   │   │       ├── CardGrid (Control, hand_card_container.gd)  ← 3×3 卡牌网格
│   │   │   │       ├── DunHead → HeadCards (Hand)   ← 影 3 格
│   │   │   │       ├── DunMiddle → MiddleCards      ← 瞬 3 格
│   │   │   │       └── DunTail → TailCards          ← 滅 3 格
│   │   │   └── AiRearrangeBtn [陣形]       ← disabled
│   │   │
│   │   └── DebugPanel (Control, 540px)
│   │       ├── PanelBg (ColorRect, full rect)
│   │       └── ScrollContainer (full rect)
│   │           └── DebugVBox (VBoxContainer)
│   │               ├── ToggleBtn [▲]       ← 折叠/展开 DebugPanel
│   │               ├── RightTitle ("DEBUG 控制")
│   │               ├── NinjaSelectBtn [🥷 忍者選択]
│   │               ├── NinjaStatusLabel ("已選: 0/5")
│   │               ├── StarTitle ("⭐ 星図レベル")
│   │               ├── StarChartContainer      ← 6 牌型等级行 + [+] 按钮
│   │               ├── ClearBtn [🗑 清空牌桌]
│   │               ├── RandomBtn [🎲 发牌]     ← 高 60px，常亮
│   │               ├── CardTrayLabel ("🃏 牌庫")
│   │               ├── CardTray (GridContainer, 13 cols) [debug_card_tray.gd]
│   │               │   └── 52 × Button (13列×4行 ♠♥♦♣)
│   │               ├── CardQueueLabel ("📋 已選隊列")
│   │               ├── CardQueueContainer (HBoxContainer)  ← 已选牌横向标签
│   │               ├── DealBtn [发牌]          ← 满 9 张亮起
│   │               └── BackBtn [← 返回]
│
└── NinjaSelector (Control, full screen, hidden) [debug_ninja_selector.gd]
    ├── SelectorBg (ColorRect, #000 70%)
    ├── SelectorPanel (PanelContainer, 1300×800)
    │   └── SelectorVBox
    │       ├── TitleRow
    │       │   ├── SelectorTitle ("选择忍者 (0/5)")
    │       │   ├── SortSpacer (Control)
    │       │   └── SortBtns
    │       │       ├── CategoryBtn [类型]  ← 按类别分组
    │       │       ├── RarityBtn [稀有度]   ← 按稀有度分组
    │       │       └── AllBtn [全部]        ← 无分组平铺
    │       ├── ScrollContainer
    │       │   └── NinjaGrid (GridContainer, 11 cols)
    │       │       ← 每组首行: [金色标题Label] + 按钮×10
    │       │       ← 同组续行: [spacer] + 按钮×N (左对齐)
    │       │       ← 全部模式: 纯按钮 11 列
    │       └── BtnRow → [开始] [取消]
```

## §4.1 主场景 ↔ Debug 场景对照

> **用途：** 修改任一场时，对照此表决定是否需要同步另一边。
> **铁律：** 完全对齐节点（§4.1.1）修改后必须双向同步。

### §4.1.1 完全对齐（修改时必须同步）

| 节点 | 主场景路径 | Debug 路径 | 备注 |
|------|-----------|-----------|------|
| CardManager | `NinKingMain/CardManager` | `NinKingDebug/CardManager` | 同 scene instance |
| GameBg | `NinKingMain/GameBg` | `NinKingDebug/GameBg` | 同 `table_bg.png` |
| LeftPanel 及全部子节点 | `UIManager/GameLayout/LeftPanel` | `MainVBox/ContentRow/LeftPanel` | 内部结构完全一致 |
| CenterColumn 及全部子节点 | `UIManager/GameLayout/CenterColumn` | `MainVBox/ContentRow/CenterColumn` | 内部结构完全一致 |
| DunArea 及全部子节点 | `.../CenterColumn/HandArea/DunArea` | `.../CenterColumn/HandArea/DunArea` | **9 个标签 + CardGrid 命名严格一致** |
| PlayBtn | `.../HandArea/PlayBtn` | `.../HandArea/PlayBtn` | 文本 `討\n伐`、unique_name |
| AiRearrangeBtn | `.../CenterColumn/AiRearrangeBtn` | `.../CenterColumn/AiRearrangeBtn` | 文本 `陣形` |
| DeckBtn | `UIManager/DeckBtn` | `NinKingDebug/DeckBtn` | 文本 `牌库: N` |
| StatusLabel | `UIManager/StatusLabel` | `MainVBox/ContentRow/CenterColumn/StatusLabel` | 提示文本 |

> ⚠️ DunArea 内部 9 个标签命名 **必须** 一一致：`HeadLabel` / `HeadTypeLabel` / `MiddleLabel` / `MiddleTypeLabel` / `TailLabel` / `TailTypeLabel` / `Col0Label` / `Col1Label` / `Col2Label` / `CardGrid`

### §4.1.2 同名不同型（功能等价，不同步结构）

| 对比项 | 主场景 | Debug 场景 | 原因 |
|--------|--------|-----------|------|
| 根节点 | `NinKingMain` (Control + `game_manager.gd`) | `NinKingDebug` (Control + `debug_controller.gd`) | 主依赖状态机，Debug 自管 UI |
| 外层容器 | `UIManager` (Control + `ui_manager.gd`) | `MainVBox` (VBoxContainer) | Debug 不需要 overlay 管理 |
| 内容行 | `GameLayout` (HBoxContainer) | `ContentRow` (HBoxContainer) | 功能相同；Debug 多一个右侧 DebugPanel |
| 牌型标签更新 | `HandTypeLabeler` 监听 `layout_changed` | `debug_controller._preview_dun_labels()` 手动调用 | Debug 不依赖 `NinKingGameState` |
| 计分按钮 | `PlayBtn`  → `game_manager._on_play()` | `PlayBtn` → `debug_controller._on_play_pressed()` | 主走状态机，Debug 直接调 `ScoreCalculator` |

### §4.1.3 独占节点（仅一边有，不同步）

| 节点 | 所在场景 | 说明 |
|------|---------|------|
| UIManager 下所有 overlay | 主场景 | LevelIntro / ScoringOverlay / GameOver / VictoryOverlay / DeckViewer / ShopOverlay |
| DebugPanel + ScrollContainer + DebugVBox | Debug | 右侧调试控制面板（卡牌托盘/星图/忍者选择） |
| DebugBtn (Launcher) | 主场景 Launcher | 进入 Debug 的入口按钮 |
| NinjaSelector | Debug | 忍者选择弹窗 |
| ToggleBtn | Debug | DebugPanel 折叠按钮 |

### §4.1.4 修改决策速查

```
改了主场景 DunArea 的标签/布局/主题?
  → 必须同步到 Debug 场景 (DunArea 节点完全对齐)

改了主场景 LeftPanel 内部?
  → 必须同步到 Debug 场景 (LeftPanel 结构完全对齐)

改了主场景 CenterColumn 的 HandArea / 按钮?
  → 必须同步到 Debug 场景

改了 UIManager / GameLayout 的结构?
  → Debug 不需同步 (§4.1.2 同名不同型)

改了主场景的 overlay / 动画 / 状态机?
  → Debug 不需同步 (§4.1.3 独占)
```

## §5 交互流程

### 5.1 选牌队列 + 发牌

```
点击右侧牌库卡牌 → 加入选牌队列（再次点击同一张→从队列移除）
    → 队列横向展示在 CardTray 下方（白底标签，红/黑花色文字）
    → 满 9 张 →「发牌」按钮亮起
    → 点击「发牌」→ 9 张牌按队列顺序填入 影/瞬/滅（每行 3 张）
    → 发牌后队列不清空，可反复调整顺序后重新发牌
    → 发牌后 _preview_dun_labels() 自动触发，左边栏牌型+喜即刻更新
```

### 5.2 即时预览

```
发牌 / 随机发牌 / AI 重排后
    → _preview_dun_labels() 自动触发
    → HandEvaluator3.evaluate() × 3（三墩评估）
    → HandEvaluator3.evaluate() × 3（三列评估）
    → XiDetector.detect()（喜检测）
    → 更新左边栏：HandTypeRow（影/瞬/滅牌型+等级） / ColumnBar（三列牌型） / ColXiLabel（喜预览）
    ← 喜信息在排好牌的瞬间即可见，无需等到計分
```

### 5.3 计分触发

```
点击 [討伐] 按钮
    → 从 3 个 Hand 提取 card_data（9 张）
    → HandEvaluator3.evaluate() × 3（三墩评估）
    → HandEvaluator3.evaluate() × 3（三列评估）
    → XiDetector.detect()（喜检测）
    → ScoreCalculator.calculate(...)（完整计分）
    → 计分动画 → 更新 LeftPanel：ScoreLabel / ProgressBar / ColXiLabel（最终结果）
```

### 5.4 忍者选择

```
点击 [🥷 忍者選択]
    → 显示 NinjaSelector 覆盖层
    → Grid 列出所有 47 张忍者（NinjaData.ALL_NINJAS），11 列
    → 排序模式: [类型] 按类别分组 / [稀有度] 按稀有度分组 / [全部] 无分组
    → 分组模式每组首行: 金色标题 Label + 按钮（同组续行左对齐）
    → 左键切换选中态，最多 5 个
    → 右键弹出 CardDetailPopup 查看卡牌详情
    → [开始] → 关闭弹窗 → 更新 NinjaBar + NinjaStatusLabel
```

### 5.5 星图等级

```
点击 [⭐ 牌型名 Lv.N] 旁的 [+]
    → 该牌型等级 +1
    → 计分时自动传递给 ScoreCalculator（star_chart_levels 参数）

鼠标悬停到牌型名标签
    → 弹出 tooltip 面板（深色背景 + 等级色边框）
    → 显示：牌型名 + 等级 + 当前筹码/倍率 + 每级加成
    → 移开鼠标自动消失
    → 等级色：Lv.0 灰 → Lv.1-2 暗灰 → Lv.3-4 蓝 → Lv.5-6 金 → Lv.7+ 紫
```

> ⚠️ 实现细节：Label 必须显式设置 `mouse_filter = Control.MOUSE_FILTER_STOP`，否则嵌套在 VBoxContainer → HBoxContainer 中时 `mouse_entered` 信号不会可靠触发。

### 5.6 其他操作

| 按钮 | 行为 |
|------|------|
| 发牌 | 将队列中 9 张牌按序填入手牌区（仅满 9 张可用） |
| 🎲 发牌 | 从 52 张洗牌取 9 张填入影/瞬/滅（高 60px，常亮） |
| 🗑 清空牌桌 | 清空 3 个 Hand + 队列，重置 LeftPanel 显示 |
| ← 返回 | `change_scene_to_file("ninking_launcher.tscn")` |

## §6 复用资产清单

| 资产 | 来源 | 复用方式 |
|------|------|----------|
| `Hand.tscn` | `addons/card-framework/` | scene instance × 3 |
| `NinKingCard` | `ninking_card.gd` | `NinKingCard.new()` |
| `ScoreCalculator` | `score_calculator.gd` | `ScoreCalculator.calculate()` 静态调用 |
| `HandEvaluator3` | `hand_evaluator.gd` | `HandEvaluator3.evaluate()` 静态调用 |
| `XiDetector` | `xi_detector.gd` | `XiDetector.detect()` 静态调用 |
| `NinjaBarDisplay` | `ninja_bar_display.gd` | `NinjaBarDisplay.new()` + `.setup()` |
| `CardManager` | `card_manager.tscn` | scene instance |
| `NinKingCardFactory` | `ninking_card_factory.tscn` | scene instance（通过 CardManager export 加载）|
| `CardData` | `card_data.gd` | `CardData.create_standard_deck()` / PlayingCard |
| `NinjaData` | `ninja_data.gd` | `NinjaData.ALL_NINJAS` |
| `manga_theme.tres` | `assets/themes/` | theme 资源 |

## §7 文件清单

| 文件 | 路径 | 说明 |
|------|------|------|
| `debug_ninking_main.tscn` | `scenes/ninking/` | Debug 场景 |
| `debug_controller.gd` | `scripts/ninking/debug/` | 主控制器 |
| `debug_card_tray.gd` | `scripts/ninking/debug/` | 右侧卡牌托盘 (GridContainer, 13列) |
| `debug_panel.gd` | `scripts/ninking/debug/` | DebugPanel 折叠/展开控制 |
| `debug_ninja_selector.gd` | `scripts/ninking/debug/` | 忍者选择弹窗 |
| `main_menu.gd` | `scripts/ninking/ui/` | +4 行 Debug 按钮接线 |
| `ninking_launcher.tscn` | `scenes/ninking/` | + DebugBtn 节点 |

## §8 已知限制

| # | 限制 | 说明 |
|---|------|------|
| 1 | 无拖拽放置 | 仅支持点击牌库→队列→发牌，不支持拖拽到 Hand |
| 2 | ~~无列牌型标签~~ | ✅ 已修复 — `ColumnLabelRow` 已加入 DunArea（与主场景对齐） |
| 3 | 无 Boss 效果 | `seal_lord_effects` 传空字典，不计 Boss 封印特殊规则 |
| 4 | 阵形按钮禁用 | AI 重排不适用于 Debug 手动手牌场景 |
| 5 | 无计分动画 | 点击討伐后直接写 Label，无 BounceScore 弹跳动画 |

## §9 素材替换注意事项

> ⚠️ 用外部工具替换图片/音频等导入资源后，Godot 的 `.import` 缓存会因哈希不匹配而标记 `valid=false`，场景引用失效。

**正确流程：**
1. 在 Godot 编辑器的 FileSystem dock 中直接拖入新文件覆盖旧文件
2. Godot 自动更新 `.import`、重新导入、维持 UID 不变

**如已出现"缺少依赖项"错误，手动修复步骤：**
1. 删除该资源的 `.import` 文件和 `.godot/imported/` 中对应缓存文件
2. 删除 `.godot/editor/filesystem_cache10`（强制重建索引）
3. 重启/Reload Project，Godot 自动生成新 `.import`（新 UID）
4. **关键：** 用新 UID 更新所有引用该场景/资源文件中的 `uid://` 引用

> 详细修复步骤 → `docs/ninking/90-troubleshooting.md` §1
