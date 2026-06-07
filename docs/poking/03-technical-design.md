# Poking 技术设计文档

## 技术栈

- **引擎**: Godot 4.6.2
- **语言**: GDScript 2.0（纯脚本，无 C++ 扩展）
- **渲染**: GL Compatibility (纯 2D)
- **分辨率**: 1920×1080

---

## 状态机

```
                    ┌─────────────┐
                    │  MAIN_MENU  │
                    └──────┬──────┘
                           │ start_new_run()
                    ┌──────▼──────┐
                    │ LEVEL_INTRO │ ← 显示关卡目标，2秒后自动跳转
                    └──────┬──────┘
                           │ auto-transition (2s)
                    ┌──────▼──────┐
              ┌─────│   PLAYING   │◄──────────────┐
              │     └──────┬──────┘               │
              │            │ complete_level()     │
              │     ┌──────▼──────┐               │
              │     │LEVEL_COMPLETE│              │
              │     └──────┬──────┘               │
              │            │ go_to_shop()         │
              │     ┌──────▼──────┐               │
              │     │    SHOP     │               │
              │     └──────┬──────┘               │
              │            │ continue_from_shop() │
              │            │ next_level()         │
              │            └──────────────────────┘
              │
              │     ┌──────▼──────┐
              └─────│  GAME_OVER  │ ← swaps_remaining=0 且 score<target
                    └──────┬──────┘
                           │ change_scene → MAIN_MENU
                    ┌──────▼──────┐
                    │  MAIN_MENU  │
                    └─────────────┘
```

### 状态枚举

```gdscript
enum State {
    MAIN_MENU,
    LEVEL_INTRO,
    PLAYING,
    SCORING,
    LEVEL_COMPLETE,
    SHOP,
    GAME_OVER,
}
```

---

## Autoload 清单

| Autoload | 脚本路径 | 职责 |
|---|---|---|
| ConfigManager | `scripts/config/config_manager.gd` | 配置管理 |
| MusicManager | `scripts/system/music_manager.gd` | 音乐播放 |
| ToastManager | `scripts/ui/toast_manager.gd` | 轻提示 |
| LeaderboardManager | `scripts/system/leaderboard_manager.gd` | 排行榜 |
| GlobalTweens | `scripts/tween/global_tweens.gd` | 动效入口 |
| TweenFX | `scripts/tween/tween_fx.gd` | 动效函数库 |
| RangeHighlighter | `scripts/system/range_highlighter.gd` | 范围高亮 |
| **PokingGameState** | `scripts/poking/game_state.gd` | **游戏状态机（核心）** |
| MCPGameBridge | `addons/godot_mcp/game_bridge/mcp_game_bridge.gd` | MCP 桥接 |
| MCPScreenshot | `addons/godot_mcp/mcp_screenshot_service.gd` | MCP 截图 |
| MCPInputService | `addons/godot_mcp/mcp_input_service.gd` | MCP 输入 |
| MCPGameInspector | `addons/godot_mcp/mcp_game_inspector_service.gd` | MCP 检视 |

---

## 场景树

```
res://
├── scenes/poking/
│   ├── poking_launcher.tscn       ← 入口场景 (主菜单)
│   ├── poking_main.tscn           ← 主游戏场景
│   ├── shop.tscn                  ← 商店场景
│   ├── card_button.tscn           ← 手牌按钮组件
│   └── joker_slot.tscn            ← 小丑牌槽位组件
```

### poking_launcher.tscn

```
Launcher (Control) [main_menu.gd]
├── Background (ColorRect)
└── CenterContainer
    └── VBoxContainer
        ├── Title (Label) "POKING"
        ├── Subtitle (Label) "扑克牌型计分闯关"
        ├── Spacer (Control)
        ├── DeckLabel (Label) "牌组: 经典牌组"
        ├── Spacer (Control)
        └── StartButton (Button) "开始游戏"
```

### poking_main.tscn

```
PokingMain (Control) [game_manager.gd]
├── GameBg (TextureRect, 桌布背景)
├── MainMenu (Control) — 主菜单视图
│   ├── MenuBg / MenuBgOverlay
│   ├── TitleLabel / SubtitleLabel
│   ├── StartButton / DeckLabel
│   └── VersionLabel
├── LevelIntro (Control) — 关卡入场视图
│   ├── IntroOverlay
│   ├── LevelLabel / TargetLabel
├── GameLayout (VBoxContainer) — 游戏主视图
│   ├── JokerContainer (HBoxContainer) — 小丑牌栏 (无背景)
│   └── MainArea (HBoxContainer)
│       ├── LeftPanel (Control, 250px) — 左侧信息面板
│       │   ├── ChipsLabel / MultSignLabel / MultLabel  (0 × 0)
│       │   ├── HandTypeLabel (牌型预览)
│       │   ├── ScoreLabel / TargetScoreLabel / ProgressBar
│       │   ├── MatchInfoPanel (红棕) — HandsLabel / DiscardsLabel / GoldLabel
│       │   └── OptionsPanel (金棕) — AnteLabel / RoundLabel
│       └── CenterColumn (VBoxContainer)
│           ├── StatusLabel
│           ├── CenterSpacer (弹性空间)
│           ├── ActionBar (HBoxContainer, 选中卡牌后显示)
│           │   ├── PlayButton "出牌"
│           │   └── SwapBtn "换牌"
│           └── CardsGrid (HBoxContainer) — 手牌单排
├── ScoringOverlay (Control) — 计分弹窗
│   └── ScorePopup (HandNameLabel / ScoreValueLabel / ScoreBreakdown)
├── LevelComplete (Control) — 过关弹窗
│   └── CompleteLabel / RewardLabel / ToShopButton
└── GameOver (Control) — 失败弹窗
    └── GameOverLabel / RetryButton
```

### shop.tscn

```
Shop (Control) [shop_ui.gd]
├── Background (ColorRect)
├── Title (Label) "商店"
├── ShopGoldLabel "金币: 0"
├── ScrollContainer
│   └── VBoxContainer
│       ├── JokerSection "--- 小丑牌 ---"
│       ├── JokerShopContainer
│       ├── ItemSection "--- 道具卡 ---"
│       └── ItemShopContainer
└── ContinueButton "继续闯关"
```

---

## 信号架构

### PokingGameState 信号

| 信号 | 参数 | 触发时机 |
|---|---|---|
| `state_changed` | `new_state: State` | 状态切换 |
| `score_updated` | `current: int, target: int` | 计分后 |
| `swap_used` | `used: int, remaining: int` | 每次换牌后 |
| `gold_changed` | `amount: int` | 金币变化 |
| `hand_updated` | `hand: Array` | 手牌变化 |
| `level_started` | `level: int, target: int` | 关卡开始 |

### 数据流

```
玩家点击手牌 → GameManager → PokingGameState.execute_swap()
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              DeckManager      HandEvaluator   ScoreCalculator
              .discard()       .evaluate()     .calculate()
              .draw()              │               │
                    │              ▼               ▼
                    │         EvalResult      ScoreResult
                    │              │               │
                    └──────────────┴───────────────┘
                                    │
                                    ▼
                          PokingGameState
                          .score_updated.emit()
                          .hand_updated.emit()
                          .swap_used.emit()
                                    │
                                    ▼
                              GameManager
                              ._refresh_hand()
                              ._refresh_jokers()
```

---

## 存档格式 (JSON)

```json
{
    "level": 3,
    "gold": 25,
    "owned_jokers": [
        {
            "id": "joker_001",
            "name": "幸运筹码",
            "effect": { "add_chips": 10 },
            "cost": 3
        }
    ],
    "owned_items": [
        {
            "id": "item_008",
            "name": "暴击骰子",
            "effect": { "x_mult": 1.5 },
            "cost": 8,
            "desc": "本回合×1.5倍率"
        }
    ]
}
```

存档路径: `user://poking_save.json`

---

## 目录结构

```
res://
├── scenes/poking/          # 场景文件
├── scripts/
│   ├── poking/             # Poking 核心逻辑 (10 脚本)
│   │   ├── ui/             # Poking UI (3 脚本)
│   │   ├── card_data.gd
│   │   ├── deck_manager.gd
│   │   ├── hand_evaluator.gd
│   │   ├── score_calculator.gd
│   │   ├── game_state.gd
│   │   ├── level_config.gd
│   │   ├── joker_data.gd
│   │   ├── item_data.gd
│   │   ├── shop_manager.gd
│   │   └── save_manager.gd
│   ├── system/             # 系统工具 (4 脚本, 源自 FanKing)
│   ├── tween/              # 动效框架 (8 脚本, 源自 FanKing)
│   ├── config/             # 配置 (2 脚本, 源自 FanKing)
│   └── ui/                 # 通用 UI (1 脚本, 源自 FanKing)
├── assets/
│   ├── images/ui/          # UI 素材
│   ├── audio/              # 音频素材
│   └── themes/             # 主题
├── shaders/                # 着色器
├── docs/poking/            # 设计文档
├── memory/                 # 需求池
└── tests/                  # 测试
```

---

## 核心类图

```
CardData (RefCounted)
├── enum Suit, Rank, HandType
├── class Card (suit, rank, chip_value)
├── const: HAND_BASE_VALUES, RANK_CHIP_VALUES
└── static: create_standard_deck()

HandEvaluator (RefCounted)
├── class EvalResult (hand_type, base_chips, base_mult)
└── static: evaluate(cards: Array[Card]) → EvalResult

ScoreCalculator (RefCounted)
├── class ScoreResult (total, chips, mult, breakdown)
└── static: calculate(cards, jokers, used_item) → ScoreResult

DeckManager (RefCounted)
├── draw_pile, discard_pile
├── draw(count) → Array[Card]
├── discard(cards)
└── reset(), shuffle()

PokingGameState (Node, Autoload)
├── current_state, level, score, gold, hand
├── execute_swap(swap_indices, fill_indices)
├── buy_joker() / buy_item()
└── Signals: state_changed, score_updated, etc.

JokerData (RefCounted)
└── ALL_JOKERS: Array[Dictionary]
    └── get_random_jokers(count)

ItemData (RefCounted)
└── ALL_ITEMS: Array[Dictionary]
    └── get_random_items(count)

LevelConfig (RefCounted)
├── LEVELS: Array[Dictionary]
└── get_level(n) → Dictionary

ShopManager (RefCounted)
├── available_jokers, available_items
└── generate_stock()

SaveManager (RefCounted)
└── save() / load() / has_save() / delete_save()
```
