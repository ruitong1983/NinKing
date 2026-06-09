# NinKing 技术设计文档

## 技术栈

- **引擎**: Godot 4.6.2
- **语言**: GDScript 2.0（纯脚本，无 C++ 扩展）
- **渲染**: GL Compatibility (纯 2D)
- **分辨率**: 1920×1080
- **玩法**: 比鸡 9张牌三墩 + 小丑牌 Roguelike

---

## 字体 & 主题

### 像素字体

| 字体 | 用途 | 网格 | 文件 |
|------|------|------|------|
| Press Start 2P (OFL) | 英文/数字/扑克牌面 | 8px 倍数 (8,16,24,32,40,48,56,64,72) | `assets/fonts/press_start_2p.ttf` |
| 凤凰点阵体 12px (CC0) | 中文 UI (CJK 回退) | 12px 倍数 (12,24,36,48,60,72) | `assets/fonts/vonwaon_bitmap_12px.ttf` |
| 凤凰点阵体 16px (CC0) | 备用较大中文 | 16px 倍数 | `assets/fonts/vonwaon_bitmap_16px.ttf` |

**导入设置 (像素字体):** 抗锯齿=关, 子像素定位=关, Mipmap=关, 嵌入位图=保留(凤凰)

**回退链:** Press Start 2P → 凤凰点阵体 12px (CJK fallback)

**字号选择规则:**
- 纯英文/数字标签 → 8 的倍数即可
- 含中文标签 → **必须用 24 / 48 / 72** (两字体网格交集)
- 牌面角标 → 24px (CORNER_FONT_SZ), 中央花色 → 56px (CENTER_FONT_SZ)

### 全局主题

**`assets/themes/pixel_theme.tres`** — 挂载在 `ninking_main.tscn` 根节点 `NinKingMain`

- `default_font` = Press Start 2P (font_size=16)
- 合并了原 `button_theme.tres` 的 Button/Panel/PanelContainer 样式
- 原 `button_theme.tres` 已废弃删除

### UI 字号速查 (ninking_main.tscn)

| 类别 | 节点 | 字号 | 网格 |
|------|------|------|------|
| 标题 | TitleLabel "N I N K I N G" | 72 | 交集 ✓ |
| 中文标签 | SubtitleLabel, DeckLabel, StatusLabel 等 | 24 | 交集 ✓ |
| 中文大号 | LevelLabel, CompleteLabel, GameOverLabel, HandNameLabel | 48 | 交集 ✓ |
| 分数 | ChipsLabel, MultLabel | 48 | 交集 ✓ |
| 分数弹出 | ScoreValueLabel | 72 | 交集 ✓ |
| 按钮 | StartButton, PlayBtn, DiscardBtn 等 | 24 | 交集 ✓ |
| 牌面 | CORNER_FONT_SZ / CENTER_FONT_SZ | 24 / 56 | PS2P ✓ |
| 特殊 | MultSign ("×"), VersionLabel, TitleBar | 40 / 16 / 24 | PS2P ✓ |

---

## 状态机

```
                    ┌─────────────┐
                    │  MAIN_MENU  │
                    └──────┬──────┘
                           │ start_new_run() / continue_run()
                    ┌──────▼──────┐
                    │ SEAL_INTRO  │ ← 显示封印目标 + 封印ノ主，2秒后自动跳转
                    └──────┬──────┘
                           │ auto-transition (2s)
                    ┌──────▼──────┐
              ┌─────│   PLAYING   │◄──────────────────┐
              │     └──┬──┬──┬───┘                   │
              │        │  │  │                       │
              │  swap  │  │  execute_play()          │
              │  cards │  │  (出牌3次)              │
              │        │  │  execute_redraw()         │
              │        │  │  (手替え2次)             │
              │        │  └──────────┐               │
              │        │             ▼               │
              │        │         SCORING             │
              │        │     (动画 → 判定)          │
              │        │             │               │
              │        │    ┌────────┴──────┐        │
              │        │    ▼               ▼        │
              │        │ SEAL_           GAME_        │
              │        │ COMPLETE        OVER         │
              │        │    │                         │
              │        │    ▼                         │
              │        │   SHOP                       │
              │        │    │                         │
              │        │    ▼                         │
              │        │ continue_from_shop() ────────┘
              │        │
              │        ▼
              │     VICTORY
              │
              └────── 死亡后 → MAIN_MENU（存档已删除）
```

### 状态枚举

```gdscript
enum State {
    MAIN_MENU,
    SEAL_INTRO,      # 封印入场（2秒倒计时）
    PLAYING,         # 手牌操作（出牌/换牌/交换）
    SCORING,         # 计分动画播放中
    SEAL_COMPLETE,   # 封印达成 → 萬屋
    SHOP,            # 商店（独立场景）
    GAME_OVER,       # 永久死亡 → 记录战绩 + 删档
    VICTORY,         # 通关 → 记录战绩 + 删档
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
| **NinKingGameState** | `scripts/ninking/game_state.gd` | **游戏状态机（核心）** |
| MCPGameBridge | `addons/godot_mcp/game_bridge/mcp_game_bridge.gd` | MCP 桥接 |
| MCPScreenshot | `addons/godot_mcp/mcp_screenshot_service.gd` | MCP 截图 |
| MCPInputService | `addons/godot_mcp/mcp_input_service.gd` | MCP 输入 |
| MCPGameInspector | `addons/godot_mcp/mcp_game_inspector_service.gd` | MCP 检视 |

---

## 场景树

```
res://
├── scenes/ninking/
│   ├── ninking_launcher.tscn       ← 入口场景 (主菜单)
│   ├── ninking_main.tscn           ← 主游戏场景
│   ├── shop.tscn                  ← 商店场景
│   ├── card_button.tscn           ← 手牌按钮组件
│   └── joker_slot.tscn            ← 小丑牌槽位组件
```

### ninking_launcher.tscn

```
Launcher (Control) [main_menu.gd]
├── Background (ColorRect)
└── CenterContainer
    └── VBoxContainer
        ├── Title (Label) "NINKING"
        ├── Subtitle (Label) "扑克牌型计分闯关"
        ├── Spacer (Control)
        ├── DeckLabel (Label) "牌组: 经典牌组"
        ├── Spacer (Control)
        └── StartButton (Button) "开始游戏"
```

### ninking_main.tscn

```
NinKingMain (Control) [game_manager.gd]
├── CardManager (Control) [card_manager.gd] — 卡牌框架核心
├── GameBg (ColorRect) — 桌布背景 (1920×1080, #1A3A32)
└── UIManager (Node) [ui_manager.gd] — UI 总控
    ├── MainMenu (Control) — 主菜单视图
    │   ├── LaunchBg / MenuBgOverlay
    │   ├── TitleLabel / SubtitleLabel
    │   ├── DeckLabel / StartButton
    │   └── VersionLabel
    ├── LevelIntro (Control) — 关卡入场视图
    │   ├── IntroOverlay / LevelLabel / TargetLabel
    ├── GameLayout (HBoxContainer) — 游戏主视图
    │   ├── LeftPanel (Control) — 左侧信息面板
    │   │   ├── PanelBg (ColorRect)
    │   │   ├── ChipsMultContainer — ChipsLabel / MultSign / MultLabel
    │   │   ├── HandTypeLabel / ScoreLabel / TargetScoreLabel / ProgressBar
    │   │   ├── MatchPanel — HandsLabel / DiscardsLabel / GoldLabel
    │   │   └── AntePanel — AnteLabel / RoundLabel
    │   └── CenterColumn (VBoxContainer) — 中央区域
    │       ├── AbilityBar (HBoxContainer) — 能力牌栏 (5槽位, 无背景条)
    │       ├── StatusLabel — 状态提示 (✅/⚠ 约束状态)
    │       ├── HandArea (HBoxContainer, 1138×728) — 操作+三组区
    │       │   ├── PlayBtn "出
牌" (84×116)
    │       │   ├── DunArea (Panel, 620×728, StyleBoxFlat 12px margin)
    │       │   │   ├── DunHead (Panel, 620×224) — 影
    │       │   │   │   ├── HeadLabel "影" (12,96) 40×28 20px金色
    │       │   │   │   ├── HeadTypeLabel "散牌" (510,100) 14px金色
    │       │   │   │   └── HeadCards (Hand, max_hand_spread=600, swap_only=true)
    │       │   │   ├── DunMiddle (Panel, 620×224) — 瞬 (8px gap)
    │       │   │   │   ├── MiddleLabel / MiddleTypeLabel / MiddleCards
    │       │   │   └── DunTail (Panel, 620×224) — 滅 (8px gap)
    │       │   │       ├── TailLabel / TailTypeLabel / TailCards
    │       │   └── DiscardBtn "换
牌" (84×116)
    │       └── DeckBtn "🎴 牌库"
    ├── ScoringOverlay (Control) — 计分弹窗
    │   └── HandNameLabel / ScoreValueLabel / ScoreBreakdown
    ├── LevelComplete (Control) — 过关弹窗
    │   └── CompleteLabel / RewardLabel / ToShopButton
    ├── GameOver (Control) — 失败弹窗
    │   └── GameOverLabel / RetryButton
    └── DeckViewer (Control) — 牌库查看器
        ├── ViewerBg / CardPanel
        └── CardGrid (剩余牌面网格)
```

### 墩面板布局 (Figma 对齐)

每个墩面板 620×224，内部元素位置：

| 元素 | 位置 | 尺寸 | 字体 |
|------|------|------|------|
| 墩名 Label | (12, 96) | 40×28 | 20px 金色 |
| 牌型 Label | (510, 100) | 86×21 | 14px 金色 |
| Hand (3张牌) | (282, 12) | spread=600 | — |

牌间距 10px (card_spacing=150, max_hand_spread=600):
```
Card0 @x=62  Card1 @x=212  Card2 @x=362
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

### NinKingGameState 信号

| 信号 | 参数 | 触发时机 |
|---|---|---|
| `state_changed` | `new_state: State` | 状态切换 |
| `score_updated` | `current: int, target: int` | 计分后 |
| `plays_changed` | `remaining: int` | 出牌次数变化 |
| `redraws_changed` | `remaining: int` | 手替え次数变化 |
| `gold_changed` | `amount: int` | 金币变化 |
| `hand_updated` | `hand: Array` | 手牌变化 (9张, 已排序) |
| `arrangement_changed` | `arrangement: Arrangement` | AI 重排后（头/中/尾 分组变化）|
| `seal_started` | `barrier: int, seal_idx: int, target: int, seal_lord_name: String` | 封印开始 |
| `xi_triggered` | `xis: Array[String]` | 喜触发（全黑/全红等）|

### 数据流

```
玩家点击手牌 → GameManager → NinKingGameState.execute_swap()
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
                          NinKingGameState
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

## 存档系统 (SaveManager)

### 双存档模型

| 存档类型 | 路径 | 生命周期 |
|---------|------|---------|
| **Run Save** (checkpoint) | `user://ninking_run_save.json` | 封印开始时写入；死亡/通关时删除 |
| **Progress Save** (永久) | `user://ninking_progress.json` | 永久保留 |

### Run Save 格式 (checkpoint)

```json
{
    "barrier_num": 2,
    "seal_idx": 1,
    "current_score": 450,
    "target_score": 1200,
    "plays_remaining": 2,
    "redraws_remaining": 1,
    "gold": 15,
    "owned_ninjas": [
        {
            "id": "n_x01",
            "name": "喜鹊",
            "effect": { "xi_x_bonus": 1 },
            "cost": 4
        }
    ],
    "owned_items": [
        {
            "id": "enc_009",
            "name": "淬火牌",
            "effect": { "enhancement": 2 },
            "cost": 3
        }
    ],
    "star_chart_levels": { "0": 1, "1": 0, "2": 0, "3": 0, "4": 0, "5": 0 },
    "current_seal_lord_name": "无头骑士",
    "current_seal_lord_effects": { "skip_head": true }
}
```

### Progress Save 格式 (永久)

```json
{
    "unlocked_decks": ["standard", "night", "sun"],
    "deck_best_barriers": { "standard": 3 },
    "total_runs": 12,
    "total_wins": 2
}
```

### 存档 API (`SaveManager`)

| 方法 | 说明 |
|------|------|
| `save_run(state)` | 写入 checkpoint |
| `load_run()` → Dictionary | 读取 checkpoint（不存在返回 {}） |
| `delete_run()` | 删除 checkpoint |
| `has_run_save()` → bool | checkpoint 是否存在 |
| `build_run_data(gs)` → Dictionary | 从当前 game_state 构建存档数据 |
| `load_progress()` → Dictionary | 读取永久进度 |
| `save_progress(data)` | 写入永久进度 |
| `record_run_result(deck, barrier, won)` | 记录一局结果（总局数+1，胜场+1，更新最高結界） |

### 永久死亡流程

```
封印开始时 → save_run() checkpoint
    ...
    ├─ 死亡 (GAME_OVER) → record_run_result("standard", barrier, false)
    │                      delete_run()
    │                      回主菜单 → 只能"新游戏"
    │
    ├─ 通关 (VICTORY)   → record_run_result("standard", barrier, true)
    │                      delete_run()
    │                      回主菜单
    │
    └─ 中途退出          → checkpoint 保留
                          下次启动 → continue_run() 从当前封印开头续玩
```

---

## 目录结构

```
res://
├── scenes/ninking/          # 场景文件
├── scripts/
│   ├── ninking/             # NinKing 核心逻辑 (10 脚本)
│   │   ├── ui/             # NinKing UI (7 脚本: ninking_card.gd, ninking_card_factory.gd, game_manager.gd, ui_manager.gd, deck_viewer_controller.gd, hand_display.gd, hand_interaction.gd)
│   │   ├── card_data.gd
│   │   ├── deck_manager.gd
│   │   ├── hand_evaluator.gd
│   │   ├── score_calculator.gd
│   │   ├── game_state.gd
│   │   ├── ninja_data.gd
│   │   ├── consumable_data.gd
│   │   ├── barrier_config.gd
│   │   ├── seal_controller.gd
│   │   ├── shop_manager.gd
│   │   ├── xi_detector.gd           ← 新增: 喜检测器
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
├── docs/ninking/            # 设计文档
├── memory/                 # 需求池
└── tests/                  # 测试
```

---

## 核心类图

```
NinKingCard (extends Card) — 牌面渲染 (276 行)
├── _create_face_structure() — FrontFace/BackFace/TextureRect 节点树
├── _generate_card_texture() — 程序绘制圆角牌面 (140×196, 8px圆角, #FAF8F2底+1px #333边框+底部阴影)
├── _create_labels() — 角标+中央花色Label (24px角标, 56px中央, 36×48角标框)
├── _update_display_label() — 刷新牌面文字 (安全调用: _ready()前自动跳过)
├── set_visual_state(VisualState) — SWAP_SOURCE(蓝) / REDRAW_TARGET(红) / NORMAL
├── 左上角标: 点数
花色 (8,6), 48px高, 24px字号
├── 中央花色: 56px 居中, Press Start 2P@56px
├── 右下角标: 180° 旋转镜像 (pivot_offset居中, rotation=PI, 位置96,142)
├── signal ninking_card_clicked(index) — 点击 (super释放后发射)
└── signal ninking_card_dragged(index, drop_position) — 拖拽

NinKingCardFactory (extends CardFactory) — 框架合约占位 (create_card() 返回 null, 实际创建由 HandDisplay 负责)

HandDisplay (extends RefCounted) — 手牌渲染器 (159 行)
├── setup(head,mid,tail, labels×6, buttons×2, status) — 注入节点引用 (12 asserts)
├── refresh(hand, swap_idx, redraw_idxs, redraw_mode, on_clicked) — 主渲染入口
├── _clear_all() — 调用 Hand.clear_cards() 清理三墩 (框架官方API)
├── _add_card(hand, card_data, idx, ...) — 创建 NinKingCard 并加入 Hand
├── _update_dun_type_labels() — HandEvaluator3 评估并显示三墩牌型
├── _update_score_preview() — ScoreCalculator.calculate() 实时 chips×mult
├── _update_action_buttons(redraw_mode) — 切换出牌/换牌按钮文本和禁用状态
└── _reset_labels() — 清空所有标签 (手牌<9时调用)

HandInteraction (extends RefCounted) — 交互状态机
├── 管理 swap 选中源 / redraw 选中目标
├── set_cards_interactable(bool) — 批量开关卡牌交互
└── 对接 ui_manager.gd 的状态流转控制

CardData (RefCounted)
├── enum Suit, Rank, HandType3, Enhancement, Seal, Edition
├── class PlayingCard (suit, rank, enhancement, seal, edition)
├── const: HAND_TYPE3_BASE_VALUES, STAR_CHART_UPGRADES, RANK_CHIP_VALUES
└── static: create_standard_deck()

HandEvaluator3 (RefCounted)
├── class EvalResult (hand_type, base_chips, base_mult, strength)
└── static: evaluate(cards: Array[PlayingCard]) → EvalResult

ScoreCalculator (RefCounted)
├── class ScoreResult (total_score, chips_sum, mult_sum, x_mult_product, breakdown)
└── static: calculate(head, mid, tail, evals, ninjas, star_charts, xi_result, seal_effects, gold) → ScoreResult

DeckManager (RefCounted)
├── draw_pile, discard_pile
├── draw(count) → Array[PlayingCard]
├── discard(cards)
└── reset(), shuffle()

NinKingGameState (Node, Autoload)
├── current_state, barrier_num, seal_idx, gold, hand, owned_ninjas, star_chart_levels
├── start_new_run() / continue_run() / has_saved_run()
├── buy_ninja() / sell_ninja() / buy_item()
├── swap_cards() / execute_play() / execute_redraw()
└── Signals: state_changed, score_updated, plays_changed, seal_started, xi_triggered 等

SealController (RefCounted, 静态方法)
├── prepare_play() / finalize_play() — 计分 prepare/finalize 模式
├── execute_redraw() / swap_cards()
├── _complete_seal() — 过关奖励 + 利息
└── _collect_play_gold() — 经济效果统一结算（福神/金尾/镀金/金封印）

NinjaData (RefCounted)
├── ALL_NINJAS: Array[Dictionary] — 47 张定义（45 active + 2 deferred）
├── get_random_ninjas(count) / get_ninja_by_id(id)
└── process_scaling() — 成长修炼引擎

ConsumableData (RefCounted)
├── FUJUTSU_CARDS / STAR_CHART_CARDS / KINJUTSU_CARDS
└── get_random_fujutsu(count) / get_random_star_charts(count) / get_random_kinjutsu(count)

LevelConfig (RefCounted)
├── LEVELS: Array[Dictionary]
└── get_level(n) → Dictionary

ShopManager (RefCounted)
├── available_jokers, available_items
└── generate_stock()

SaveManager (RefCounted)
├── save_run() / load_run() / delete_run() / has_run_save() / build_run_data()
└── load_progress() / save_progress() / record_run_result() / unlock_deck()
```
