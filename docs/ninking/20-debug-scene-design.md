# Debug 计分测试场景

> **建立日期:** 2026-06-12 | **关联场景:** `ninking_debug.tscn` + `debug_controller.gd`
> **风格权威:** 独立于主场景，零侵入设计

## §1 概述

Debug 场景用于快速验证各种牌型组合下，配合忍者卡、星图卡的得分计算是否准确。从 Launch 场景右下角「DEBUG」按钮进入。界面布局与主场景保持一致，可以：

1. 从 52 张牌库中随意选择扑克放入 9 格（影/瞬/滅 各 3 张）
2. 任意选取忍者卡和星图卡，观察对计分的影响
3. 点击「討伐」触发 `ScoreCalculator.calculate()`，LeftPanel 即时显示完整计分

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
| 行为 | `change_scene_to_file("res://scenes/ninking/ninking_debug.tscn")` |
| 隐藏条件 | 始终可见（开发用，无条件编译） |

**涉及修改：** `ninking_launcher.tscn`（加节点）+ `main_menu.gd`（4 行：`@onready` + 信号连接 + handler）

## §4 场景结构

```
NinKingDebug (Control) [debug_controller.gd]
├── GameBg (TextureRect)                    ← table_bg.png 全屏背景
├── CardManager (CardManager)               ← Card-Framework 核心（含 NinKingCardFactory）
│
├── MainVBox (VBoxContainer, full rect)
│   │
│   ├── ContentRow (HBoxContainer, stretch=1)
│   │   │
│   │   ├── LeftPanel (Control, 420px)      ← 结构复制自主场景 LeftPanel
│   │   │   ├── ScoreCard (Panel, anchor 0~0.5)
│   │   │   │   └── ScoreCardVBox
│   │   │   │       ├── ColXiLabel          ← 列×累乘 + 喜预览
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
│   │   │   ├── NinjaBar (HBoxContainer)    ← 已选忍者展示
│   │   │   ├── StatusLabel                 ← 操作提示
│   │   │   ├── HandArea (HBoxContainer)
│   │   │   │   ├── PlayBtn [討伐]          ← 触发计分
│   │   │   │   ├── DunArea (Panel)
│   │   │   │   │   ├── DunHead → HeadCards (Hand)   ← 影 3 格
│   │   │   │   │   ├── DunMiddle → MiddleCards      ← 瞬 3 格
│   │   │   │   │   └── DunTail → TailCards          ← 滅 3 格
│   │   │   │   └── AiRearrangeBtn [陣形]   ← disabled
│   │   │   └── DeckBtn                    ← "牌库: 52"（仅展示）
│   │   │
│   │   └── RightPanel (Control, 420px)
│   │       └── RightVBox (VBoxContainer)
│   │           ├── RightTitle ("DEBUG 控制")
│   │           ├── NinjaSelectBtn [🥷 忍者選択]
│   │           ├── NinjaStatusLabel ("已選: 0/5")
│   │           ├── StarTitle ("⭐ 星図レベル")
│   │           ├── StarChartContainer      ← 6 牌型等级行 + [+] 按钮
│   │           ├── ClearBtn [🗑 清空牌桌]
│   │           ├── RandomBtn [🎲 随机发牌]
│   │           └── BackBtn [← 返回]
│   │
│   └── BottomTray (Control, h~160, x=420)
│       └── CardTray [debug_card_tray.gd]
│           └── CardGrid (GridContainer, 13 cols)
│               └── 52 × Button [♠A][♠2]...[♦K] ← 底栏牌库
│
└── NinjaSelector (Control, full screen, hidden) [debug_ninja_selector.gd]
    ├── SelectorBg (ColorRect, #000 70%)
    ├── SelectorPanel (PanelContainer, 1300×800, centered)
    │   └── SelectorVBox
    │       ├── SelectorTitle ("选择忍者 (0/5)")
    │       ├── ScrollContainer
    │       │   └── NinjaGrid (GridContainer, 5 cols) ← 忍者名多选
    │       └── BtnRow → [确认] [取消]
```

## §5 交互流程

### 5.1 卡牌放置

```
点击底栏牌库卡牌 → 高亮 (modulate.yellow)
    → 点击 9 格空格 → NinKingCard 实例化 → 添加到对应 Hand
    → 或右键点击 9 格已有牌 → 移除该牌
    → 或左键点击已有牌（有高亮牌时）→ 替换
```

### 5.2 计分触发

```
点击 [討伐] 按钮
    → 从 3 个 Hand 提取 card_data（9 张）
    → HandEvaluator3.evaluate() × 3（三墩评估）
    → HandEvaluator3.evaluate() × 3（三列评估）
    → XiDetector.detect()（喜检测）
    → ScoreCalculator.calculate(...)（完整计分）
    → 更新 LeftPanel：ScoreLabel / HandTypeRow / ColXiLabel / ProgressBar
```

### 5.3 忍者选择

```
点击 [🥷 忍者選択]
    → 显示 NinjaSelector 覆盖层
    → Grid 列出所有 47 张忍者（NinjaData.ALL_NINJAS）
    → 点击切换选中态，最多 5 个
    → [确认] → 关闭弹窗 → 更新 NinjaBar + NinjaStatusLabel
```

### 5.4 星图等级

```
点击 [⭐ 牌型名 Lv.N] 旁的 [+]
    → 该牌型等级 +1
    → 计分时自动传递给 ScoreCalculator（star_chart_levels 参数）
```

### 5.5 其他操作

| 按钮 | 行为 |
|------|------|
| 🗑 清空牌桌 | 清空 3 个 Hand，重置 LeftPanel 显示 |
| 🎲 随机发牌 | 从 52 张洗牌取 9 张填入影/瞬/滅 |
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
| `ninking_debug.tscn` | `scenes/ninking/` | Debug 场景 |
| `debug_controller.gd` | `scripts/ninking/debug/` | 主控制器 |
| `debug_card_tray.gd` | `scripts/ninking/debug/` | 底栏卡牌托盘 |
| `debug_ninja_selector.gd` | `scripts/ninking/debug/` | 忍者选择弹窗 |
| `main_menu.gd` | `scripts/ninking/ui/` | +4 行 Debug 按钮接线 |
| `ninking_launcher.tscn` | `scenes/ninking/` | + DebugBtn 节点 |

## §8 已知限制

| # | 限制 | 说明 |
|---|------|------|
| 1 | 无拖拽放置 | 底栏卡牌暂仅支持点击→点空格放入，不支持拖拽到 Hand（Card-Framework 拖拽事件与 Debug 控制器交互未对接）|
| 2 | 无列牌型标签 | 列评估已计入计分，但 `ColumnLabelRow`（Col0/Col1/Col2 标签）未包含在场景中 |
| 3 | 无 Boss 效果 | `seal_lord_effects` 传空字典，不计 Boss 封印特殊规则 |
| 4 | 阵形按钮禁用 | AI 重排不适用于 Debug 手动手牌场景 |
| 5 | 无计分动画 | 点击討伐后直接写 Label，无 BounceScore 弹跳动画 |
