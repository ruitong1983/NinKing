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
- StyleBox 全部 0 圆角、2px 硬边、金色边框（像素忍者风）
- 按钮三态：normal/hover/pressed（瞬时切换 + 按下时 content_margin 下移）
- 三墩边框递进：DunHead(1px) → DunMiddle(2px) → DunTail(3px)
- 原 `button_theme.tres` 已废弃删除

### UI 字号速查 (ninking_main.tscn)

| 类别 | 节点 | 字号 | 网格 |
|------|------|------|------|
| 标题 | TitleLabel "N I N K I N G" | 72 | 交集 ✓ |
| 中文标签 | SubtitleLabel, DeckLabel, StatusLabel 等 | 24 | 交集 ✓ |
| 中文大号 | LevelLabel, CompleteLabel, GameOverLabel, HandNameLabel | 48 | 交集 ✓ |
| 分数 | ChipsLabel, MultLabel | 48 | 交集 ✓ |
| 分数弹出 | ScoreValueLabel | 72 | 交集 ✓ |
| 按钮 | StartButton, PlayBtn, RedrawBtn 等 | 24 | 交集 ✓ |
| 牌面 | CORNER_FONT_SZ / CENTER_FONT_SZ | 24 / 56 | PS2P ✓ |
| 特殊 | MultSign ("×"), VersionLabel, TitleBar | 40 / 16 / 24 | PS2P ✓ |

---

## 状态机

```
   (启动器 main_menu.gd 调用 start_new_run() / continue_run() 后加载本场景)
                    ┌──────┐
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
              └────── 死亡后点"重新开始" → reload 场景 → SEAL_INTRO（_on_state_changed 驱动）
```

### 状态枚举

```gdscript
enum State {
    MAIN_MENU,       # ⛔ 已废弃 — 启动器替代，保留枚举值防引用断裂
    SEAL_INTRO,      # 封印入场（2秒倒计时）
    PLAYING,         # 手牌操作（出牌/换牌/交换）
    SCORING,         # 计分动画播放中（仅在 game_manager 动画流程中使用）
    SEAL_COMPLETE,   # 封印达成 → 萬屋
    SHOP,            # 商店（独立场景）
    GAME_OVER,       # 永久死亡 → 记录战绩 + 删档
    VICTORY,         # 通关 → 记录战绩 + 删档
}
```

> **注意:** `SCORING` 状态仅在 `game_manager.gd` 的计分动画流程中短暂使用，防止动画期间重复操作。
> SealController 使用 prepare/finalize 模式直接在 PLAYING 状态下计算分数，不经过 SCORING 状态转换。

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
│   ├── shop.tscn                   ← 商店（萬屋）场景
│   ├── card_button.tscn            ← 手牌按钮组件
│   ├── ninking_card.tscn           ← 卡牌组件 (NinKingCard)
│   ├── ninking_card_factory.tscn   ← 卡牌工厂 (Card-Framework)
│   ├── ability_slot.tscn           ← 忍者牌槽位组件
│   ├── shop_ability_card.tscn      ← 商店忍者牌卡片
│   ├── shop_item_card.tscn         ← 商店道具卡片
```

### ninking_launcher.tscn

```
Launcher (Node) [main_menu.gd]
└── LaunchBg (TextureRect) — launch_bg.png 背景
    (UI 全部由 main_menu.gd 程序化构建: CanvasLayer + 按钮 + 牌组面板 + 继续面板)
```

### ninking_main.tscn

```
NinKingMain (Control) [game_manager.gd]
├── CardManager (Control) [card_manager.gd] — 卡牌框架核心
├── GameBg (ColorRect) — 桌布背景 (1920×1080, 結界主题动态配色)
└── UIManager (Node) [ui_manager.gd] — UI 总控
    ├── LevelIntro (Control) — 封印入场视图
    │   ├── IntroOverlay / LevelLabel / TargetLabel
    ├── GameLayout (HBoxContainer) — 游戏主视图
    │   ├── LeftPanel (Control) — 左侧信息面板
    │   │   ├── PanelBg (ColorRect)
    │   │   ├── ChipsMultContainer — ChipsLabel / MultSign / MultLabel
    │   │   ├── HandTypeLabel / ScoreLabel / TargetScoreLabel / ProgressBar
    │   │   ├── MatchPanel — HandsLabel / RedrawsLabel / GoldLabel
    │   │   └── AntePanel — BarrierLabel / RoundLabel
    │   └── CenterColumn (VBoxContainer) — 中央区域
    │       ├── AbilityBar (HBoxContainer) — 忍者牌栏 (5槽位)
    │       ├── StatusLabel — 状态提示
    │       ├── HandArea (HBoxContainer) — 操作+三组区
    │       │   ├── PlayBtn "出牌"
    │       │   ├── DunArea (Panel) — 三墩容器
    │       │   │   ├── DunHead (Panel) — 影（1px 边框）
    │       │   │   ├── DunMiddle (Panel) — 瞬（2px 边框）
    │       │   │   └── DunTail (Panel) — 滅（3px 边框）
    │       │   ├── AiRearrangeBtn "陣\n形" — 陣形按钮（初始禁用，PLAYING 时启用）
    │       │   └── RedrawBtn "换牌"
    │       ├── ColumnLabelRow (HBoxContainer) — 列牌型标签行
    │       │   ├── Col0Label — 列0 牌型（≥对子时金色显示）
    │       │   ├── Col1Label — 列1 牌型
    │       │   └── Col2Label — 列2 牌型
    │       └── DeckBtn "🎴 牌库"
    ├── ScoringOverlay (Control) — ⛔ 计分时不再显示 (Balatro 风内联动画) [z_index=10]
    │   └── HandNameLabel / ScoreValueLabel / ScoreBreakdown (保留节点，未被计分流程使用)
    ├── LevelComplete (Control) — 过关弹窗
    │   └── CompleteLabel / RewardLabel / ToShopButton
    ├── GameOver (Control) — 失败弹窗
    │   └── OverlayBg / GameOverLabel / ScoreSummary / RetryButton / BackToMenuButton
    ├── VictoryOverlay (Control) — 通关弹窗 (独立于 GameOver)
    │   └── OverlayBg / VictoryLabel / StatsSummary / MenuButton
    └── DeckViewer (Control) — 牌库查看器 [z_index=10]
        └── ViewerBg / CardPanel / TitleBar / CountRow / CardScroll / CardGrid
```

> **注意:** 三墩内部的手牌节点（HeadCards/MiddleCards/TailCards）和牌型标签（HeadTypeLabel 等）
> 由 `HandDisplay` 在运行时动态创建和管理，不在静态场景树中。
>
> **⚠️ z_index 陷阱:** `Hand._update_target_z_index()` 会给卡牌设 z_index=0/1/2，在 Godot 4 的累加 z_index 模型下会穿透同层 overlay。DeckViewer 已设 `z_index=10` 应对。ScoringOverlay 计分时不显示（Balatro 风内联动画），不再需要 z_index 防护。详见 `docs/card-framework-usage-guide.md` § 已知陷阱。

### shop.tscn

```
Shop (Control) [shop_ui.gd]
├── Overlay (ColorRect) — 全屏半透明遮罩
└── ShopPanel (Panel) — 商店主面板
    ├── TitleBar (ColorRect) — 标题栏背景
    ├── ShopTitle (Label) "萬屋"
    ├── GoldPill (Panel) — 金币显示
    │   ├── CoinIcon (Label) "🪙"
    │   └── GoldLabel (Label)
    ├── RerollBtn (Button) / RerollLabel — 刷新按钮
    ├── AbilityLabel (Label) "--- 忍者牌 ---"
    ├── DecoLineL1 / DecoLineR1 (ColorRect) — 装饰线
    ├── AbilityRow (HBoxContainer) — 忍者牌商品行
    ├── ItemLabel (Label) "--- 道具 ---"
    ├── DecoLineL2 / DecoLineR2 (ColorRect) — 装饰线
    ├── ItemRow (HBoxContainer) — 道具商品行
    ├── BottomBar (ColorRect) — 底部栏背景
    ├── Separator (ColorRect) — 分隔线
    ├── ContinueBtn (Button) "继续闯关"
    ├── NextLevelHint (Label) — 下一封印提示
    └── NinjaSlotLabel (Label) — 忍者槽位指示器
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
| `arrangement_changed` | `arrangement: Arrangement` | AI 重排/原地重评估后（影/瞬/滅 分组变化） |
| `seal_started` | `barrier: int, seal_idx: int, target: int, seal_lord_name: String` | 封印开始 |
| `xi_triggered` | `xis: Array[String]` | 喜触发（全黑/全红等） |

### 数据流（出牌）

```
玩家点击出牌 → GameManager._on_play_pressed()
    │
    ▼
NinKingGameState.execute_play()
    │ 委托
    ▼
SealController.execute_play(gs)
    ├── prepare_play(gs) → 验证 + 计分（不修改状态）
    │   ├── AutoArranger (排列评估)
    │   ├── XiDetector.detect() → XiResult
    │   ├── Column evaluation (列_j = 影[j]+瞬[j]+滅[j]) → col_evals
    │   └── ScoreCalculator.calculate() → ScoreResult
    └── finalize_play(gs, play_data) → 应用状态变更
        ├── gs.plays_remaining -= 1
        ├── gs.current_score += score
        ├── _collect_play_gold() → 经济结算
        ├── DeckManager.discard() + draw(9)
        ├── ArrangeController.auto_arrange(gs)
        └── 判定: 过关/失败/继续
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
    "current_deck_name": "standard",
    "owned_ninjas": [
        {
            "id": "n_x01",
            "name": "喜鹊",
            "effect": { "xi_x_bonus": 1 },
            "cost": 4
        }
    ],
    "owned_items": [],
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
| `unlock_deck(deck_name)` | 解锁新牌组 |

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
├── scenes/ninking/          # 场景文件 (11 tscn)
├── scripts/
│   ├── ninking/             # NinKing 核心逻辑 (19 脚本)
│   │   ├── ui/              # NinKing UI (13 脚本)
│   │   │   ├── ninking_card.gd           ← 卡牌渲染 (NinKingCard)
│   │   │   ├── ninking_card_factory.gd   ← 卡牌工厂 (NinKingCardFactory)
│   │   │   ├── game_manager.gd           ← 主场景控制器
│   │   │   ├── ui_manager.gd             ← UI 总控
│   │   │   ├── main_menu.gd              ← 主菜单
│   │   │   ├── shop_ui.gd                ← 商店 UI
│   │   │   ├── hand_display.gd           ← 手牌渲染器
│   │   │   ├── hand_interaction.gd       ← 交互状态机
│   │   │   ├── deck_viewer_controller.gd ← 牌库查看器
│   │   │   ├── card_button.gd            ← 手牌按钮
│   │   │   ├── ability_slot.gd           ← 忍者牌槽位
│   │   │   ├── shop_ability_card.gd      ← 商店忍者牌卡片
│   │   │   └── shop_item_card.gd         ← 商店道具卡片
│   │   ├── card_data.gd                  ← 扑克牌数据 (CardData)
│   │   ├── deck_manager.gd               ← 牌库管理 (DeckManager)
│   │   ├── hand_evaluator.gd             ← 牌型评估 (HandEvaluator3)
│   │   ├── auto_arranger.gd              ← 排列求解器 (AutoArranger)
│   │   ├── score_calculator.gd           ← 计分引擎 (ScoreCalculator)
│   │   ├── xi_detector.gd                ← 喜检测器 (XiDetector)
│   │   ├── game_state.gd                 ← 游戏状态机 (NinKingGameState, Autoload)
│   │   ├── seal_controller.gd            ← 出牌/封印逻辑 (SealController)
│   │   ├── arrange_controller.gd         ← 排列/规则收集 (ArrangeController)
│   │   ├── ninja_data.gd                 ← 忍者牌数据 (NinjaData)
│   │   ├── ninja_pool.gd                 ← 忍者牌随机抽取 (NinjaPool)
│   │   ├── ninja_scaling.gd              ← 修炼成长引擎 (NinjaScaling)
│   │   ├── consumable_data.gd            ← 道具卡数据 (ConsumableData)
│   │   ├── item_data.gd                  ← 物品数据 (ItemData)
│   │   ├── barrier_config.gd             ← 封印/結界配置 (BarrierConfig)
│   │   ├── barrier_theme.gd              ← 結界主题配色 (BarrierTheme)
│   │   ├── card_back_generator.gd        ← 卡牌背面程序绘制
│   │   ├── shop_manager.gd               ← 商店逻辑 (ShopManager)
│   │   └── save_manager.gd               ← 存档管理 (SaveManager)
│   ├── system/             # 系统工具 (源自 FanKing)
│   ├── tween/              # 动效框架 (源自 FanKing)
│   ├── config/             # 配置 (源自 FanKing)
│   └── ui/                 # 通用 UI (源自 FanKing)
├── assets/
│   ├── images/ui/          # UI 素材
│   ├── audio/              # 音频素材
│   └── themes/             # 主题 (pixel_theme.tres)
├── shaders/                # 着色器 (crt_filter.gdshader)
├── docs/ninking/           # 设计文档
├── memory/                 # AI 记忆
└── tests/                  # 测试
```

---

## 核心类图

```
NinKingCard (extends Card) — SVG 牌面渲染
├── _ensure_face_nodes() — 创建 FrontFace/BackFace/TextureRect 节点（new() 兜底）
├── _load_card_texture() — 加载 SVG 纹理 (res://assets/images/cards/4color_deck_by_heratexx/{rank}{suit}.svg)
│   └── expand_mode=IGNORE_SIZE + stretch_mode=KEEP_ASPECT_COVERED + size=card_size
│       (IGNORE_SIZE 防止 Godot 4 每帧覆盖 size 为 SVG viewBox 240×334)
├── _get_card_svg_path() — suit/rank → SVG 文件路径
├── update_display() — 重载 SVG 纹理（换牌/数据变更时）
├── set_visual_state(VisualState) — SWAP_SOURCE(蓝) / REDRAW_TARGET(红) / NORMAL
├── _handle_mouse_released/pressed() — 点击 vs 拖拽判定（CLICK_THRESHOLD=10px）
├── signal ninking_card_clicked(index) — 点击交换/选牌
└── signal ninking_card_dragged(index, drop_position) — 拖拽跨组交换

NinKingCardFactory (extends CardFactory) — 框架合约占位 (create_card() 返回 null, 实际创建由 HandDisplay 负责)

HandDisplay (extends RefCounted) — 手牌渲染器
├── setup(head,mid,tail, labels×6+col_labels×3, buttons×2, status) — 注入节点引用
├── refresh(hand, swap_idx, redraw_idxs, redraw_mode, on_clicked) — 主渲染入口
│   └── 末尾 0.3s Timer → _fixup_layout() 修正 Card Framework move-tween 竞态
├── _clear_all() — 调用 Hand.clear_cards() 清理三墩 (框架官方API)
├── _add_card(hand, card_data, idx, ...) — 创建 NinKingCard 并加入 Hand
├── _fixup_layout(head, mid, tail) — update_card_ui() 修正子序/z-index/状态
├── _force_card_positions(hand) — 按 _held_cards 序直接设 global_position+rotation
│   └── 绕过 move() tween: 先 force 再 update_card_ui(), move() 见已在目标即跳过
├── _update_dun_type_labels() — HandEvaluator3 评估并显示三墩牌型
├── _update_column_type_labels() — 评估 3 列并显示列牌型（≥对子时金色）
├── _update_score_preview() — ScoreCalculator.calculate() 实时 chips×mult
└── _update_action_buttons(redraw_mode) — 切换出牌/换牌按钮文本和禁用状态

HandInteraction (extends RefCounted) — 交互状态机
├── 管理 swap 选中源 / redraw 选中目标
├── set_cards_interactable(bool) — 批量开关卡牌交互
└── 对接 ui_manager.gd 的状态流转控制

CardData (RefCounted)
├── enum Suit, Rank, HandType3, Enhancement, Seal, Edition
├── class PlayingCard (suit, rank, enhancement, seal, edition)
├── const: HAND_TYPE3_BASE_VALUES, COLUMN_HAND_TYPE3_BASE_VALUES, STAR_CHART_UPGRADES, RANK_CHIP_VALUES
├── static: get_hand_type3_column_leveled_chips/mult(ht, levels)
└── static: create_standard_deck()

HandEvaluator3 (RefCounted)
├── class EvalResult (hand_type, base_chips, base_mult, strength)
└── static: evaluate(cards: Array[PlayingCard]) → EvalResult

AutoArranger (RefCounted)
└── static: find_best(hand, ninja_chips, ninja_mult, ninja_x_stack, star_chart_levels, rules) → Arrangement

ScoreCalculator (RefCounted)
├── class ScoreResult (total_score, chips_sum, mult_sum, x_mult_product, breakdown)
└── static: calculate(head, mid, tail, evals, col_evals, ninjas, star_charts, xi_result, seal_effects, gold) → ScoreResult

XiDetector (RefCounted)
├── class XiResult (triggered, chips_add, mult_x_stack)
└── static: detect(head, mid, tail, head_eval, mid_eval, tail_eval) → XiResult

DeckManager (RefCounted)
├── draw_pile, discard_pile
├── draw(count) → Array[PlayingCard]
├── discard(cards)
└── reset(), shuffle()

NinKingGameState (Node, Autoload)
├── current_state, barrier_num, seal_idx, gold, hand, owned_ninjas, star_chart_levels
├── current_arrangement, current_col_evals
├── start_new_run() / continue_run() / has_saved_run()
├── auto_arrange() / re_evaluate_arrangement() / get_scoring_rules()
├── swap_cards() / execute_play() / execute_redraw()
├── go_to_shop() / continue_from_shop() / skip_seal()
└── Signals: state_changed, score_updated, plays_changed, redraws_changed, gold_changed,
    hand_updated, arrangement_changed, seal_started, xi_triggered

SealController (RefCounted, 静态方法)
├── execute_play(gs) / prepare_play(gs) / finalize_play(gs, data) — 出牌流程
├── swap_cards(gs, idx1, idx2) — 交换（原地重评估，不触发 AI 重排）
├── execute_redraw(gs, indices) — 手替え（触发 auto_arrange）
├── go_to_shop(gs) / continue_from_shop(gs) / skip_seal(gs, tag_reward)
├── _complete_seal(gs) — 过关奖励 + 利息
├── _collect_play_gold(gs, cards, xi) — 经济效果统一结算
└── _advance_seal(gs) → bool — 封印/結界推进

ArrangeController (RefCounted, 静态方法)
├── auto_arrange(gs) — 排列计算（不 emit 信号）
├── get_scoring_rules(gs) → Dictionary — 收集封印ノ主+忍者规则
├── sum_ninja_effect(gs, key, default) → int
└── collect_ninja_effect(gs, key, threshold) → Array

NinjaData (RefCounted)
├── ALL_NINJAS: Array[Dictionary] — 47 张定义（45 active + 2 deferred）
├── STARTER_IDS: Array[String] — 初始 10 张
├── get_by_id(id) → Dictionary
└── get_starter_ninjas() → Array[Dictionary]

NinjaPool (RefCounted)
├── get_random_ninjas(count, exclude_ids, rarity_filter) → Array[Dictionary]
└── get_random_legendary() → Dictionary

NinjaScaling (RefCounted)
└── process_scaling(ninjas, trigger_type, context) — 修炼忍者成长引擎（待接入）

ConsumableData (RefCounted)
├── FUJUTSU_CARDS / STAR_CHART_CARDS / KINJUTSU_CARDS
└── get_random_fujutsu(count) / get_random_star_charts(count) / get_random_kinjutsu(count)

BarrierConfig (RefCounted)
├── 封印/結界配置表（目标分数、金币奖励、封印ノ主）
└── get_seal(barrier, seal_idx) / get_seals_per_barrier() / get_total_barriers() / assign_seal_lord()

BarrierTheme (RefCounted)
└── BARRIER_COLORS: 8 結界冷暖交替配色（紫/青/蓝/翠 冷 → 红/橙/金/粉 暖）

ShopManager (RefCounted)
├── available_ninjas, available_fujutsu, available_star_charts, available_kinjutsu
├── generate_stock(yasha_shop, exclude_ninja_ids)
├── get_ninjas_for_display() / get_fujutsu_for_display() / get_star_charts_for_display() / get_kinjutsu_for_display()
├── buy_ninja(gs, ninja) / sell_ninja(gs, idx) / buy_item(gs, item) / apply_star_chart(gs, hand_type)
└── is_yasha_shop: bool

SaveManager (RefCounted)
├── save_run() / load_run() / delete_run() / has_run_save() / build_run_data()
└── load_progress() / save_progress() / record_run_result() / unlock_deck()
```
