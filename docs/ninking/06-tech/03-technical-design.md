# NinKing 技术设计文档

> **最后更新: 2026-06-20** — 配置外部化：ConfigManager 加载 `game_config.json`，游戏启动参数（金币/次数/槽位/利息/商店）统一配置。

## 技术栈

- **引擎**: Godot 4.6.2
- **语言**: GDScript 2.0（纯脚本，无 C++ 扩展）
- **渲染**: GL Compatibility (纯 2D)
- **分辨率**: 1920×1080
- **玩法**: 双模式 — 比鸡模式 (9张牌三墩 + 小丑牌 Roguelike) / 消除模式 (Balatro 式消除, 开发中)

---

## 字体 & 主题

### 当前字体 (LXGW WenKai 霞鹜文楷)

| 字体 | 用途 | 文件 |
|------|------|------|
| LXGW WenKai Medium (OFL) | 默认 UI — 按钮/标题/数字/标签 | `assets/fonts/LXGWWenKai-Medium.ttf` |
| LXGW WenKai Regular (OFL) | 正文备用 — 卡牌描述/小字 | `assets/fonts/LXGWWenKai-Regular.ttf` |

> 前代字体（Press Start 2P / 凤凰点阵体 / 思源黑体 / 站酷妙典体）已全部清理。
> 详见 `05-art/17-font-design-plan.md`。

**导入设置:** 抗锯齿=开, 子像素定位=开, Mipmap=关, 轻度微调(hinting=1)

### 全局主题

**`assets/themes/manga_theme.tres`** — 挂载在 `ninking_main.tscn` / `ninking_clean_main.tscn` / `ninking_launcher.tscn` 根节点

- `default_font` = LXGWWenKai-Medium (font_size=16)
- StyleBoxFlat 全部 hard-edge（0 圆角、2px 边框、金色描边）
- 按钮三态：normal(深色) / hover(亮色) / pressed(按下偏移)
- 面板深色半透明底 + 金色边框 2px

### UI 字号速查 (ninking_main.tscn)

| 类别 | 节点 | 字号 |
|------|------|------|
| 标题 | TitleLabel | 72 |
| 分数 | ScoreLabel, ScoreValueLabel | 48 / 72 |
| 分数预览 | ColXiLabel | 32 |
| 按钮 | PlayBtn, AiRearrangeBtn, DeckBtn 等 | 18-24 |
| 中文标签 | SubtitleLabel, DeckLabel, StatusLabel 等 | 24 |
| 中文大号 | LevelLabel, CompleteLabel, HandNameLabel | 48 |
| 牌面角标 | CORNER_FONT_SZ | 24 |
| 牌面中央 | CENTER_FONT_SZ | 56 |
| 特殊 | VersionLabel, TitleBar | 16 / 24 | PS2P ✓ |

---

## 状态机

```
   (启动器 main_menu.gd 调用 start_new_run(deck_name, mode) / continue_run() 后加载本场景)
                    ┌──────────┐
                    │ SEAL_INTRO │ ← 0.5s 结界浮水印（Phase C 极简化）
                    └─────┬──────┘
                          │ auto-transition (0.5s)
                   ┌──────▼──────┐
              ┌────│   PLAYING   │◄──────────────────────┐
              │    └──┬──┬──┬───┘                       │
              │       │  │  │                           │
              │  swap │  │  execute_play()              │
              │  cards│  │  (讨伐 3次)                 │
              │       │  └──────────┐                    │
              │       │             ▼                    │
              │       │         SCORING                  │
              │       │     (动画 → 判定)               │
              │       │          │                       │
              │       │   ┌──────┴──────┐                │
              │       │   ▼              ▼               │
              │       │SEAL_          GAME_              │
              │       │COMPLETE        OVER              │
              │       │   │                              │
              │       │   ▼                              │
              │       │  SHOP (同场景 Overlay) ←─ Phase C │
              │       │   │   无 scene 切换               │
              │       │   ▼                              │
              │       │ continue_from_shop() ────────────┘
              │       │
              │       ▼
              │    VICTORY
              │
              └────── 死亡后点"重新开始" → reload 场景 → SEAL_INTRO
```

> **Phase C 变更 (2026-06-11):** SHOP 改为同场景 Overlay，不再涉及 `change_scene_to_file`。
> SEAL_INTRO 从 2s 缩短为 0.5s 结界浮水印。Boss 封印的揭示动画移至 PLAYING 中（战中出现）。

### 状态枚举

```gdscript
enum State {
    MAIN_MENU,       # ⛔ 已废弃 — 启动器替代，保留枚举值防引用断裂
    SEAL_INTRO,      # 封印入场（0.5s 结界浮水印 — Phase C 极简化）
    PLAYING,         # 手牌操作（出牌/换牌/交换）
    SCORING,         # 计分动画播放中（仅在 game_manager 动画流程中使用）
    SEAL_COMPLETE,   # 封印达成 → 萬屋
    SHOP,            # 🏪 商店（同场景 UIManager/ShopOverlay）— 无 scene 切换
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
| ConfigManager | `scripts/config/config_manager.gd` | 配置管理 — 加载 `config/game_config.json`，校验后暴露只读参数（默认值硬编码兜底） |
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
│   ├── ninking_main.tscn           ← 主游戏场景（含 ShopOverlay Phase C, 比鸡模式）
│   ├── ninking_clean_main.tscn      ← 消除模式场景 (1:1 复刻 ninking_main.tscn, 玩法待实现)
│   ├── debug_ninking_main.tscn          ← Debug 计分测试场景 (2026-06-12)
│   ├── shop_panel.tscn             ← 🆕 商店面板场景片段 (替代旧 shop.tscn)
│   ├── ninja_card.tscn               ← 🆕 统一忍者卡场景 (替代旧 display_card_base.tscn)
│   ├── ninking_card.tscn           ← 卡牌组件 (NinKingCard)
│   ├── ninking_card_factory.tscn   ← 卡牌工厂 (Card-Framework)
│   ├── ability_slot.tscn           ← 忍者牌槽位组件 (已重命名)
│   ├── shop_slot.tscn              ← 🆕 商店展示容器 (NinjaCard + 购买UI)
```

### ninking_launcher.tscn

```
Launcher (Control) [main_menu.gd]
├── LaunchBg (TextureRect) — launch_bg.png 背景
├── StartBtn (Button) "开始游戏"      ← 比鸡模式入口
├── CleanBtn (Button) "消除模式"      ← 消除模式入口
├── ContinueBtn (Button) "继续游戏"
├── SettingsBtn (Button) "设置" (disabled)
├── QuitBtn (Button) "退出游戏"
├── DebugBtn (Button) "DEBUG"
│   (牌组面板 + 继续面板由 main_menu.gd 程序化构建)
```

### ninking_main.tscn

```
NinKingMain (Control) [game_manager.gd]
├── CardManager (Control) [card_manager.gd] — 卡牌框架核心
├── GameBg (TextureRect) — 桌布背景 (1920×1080, 結界主题动态配色)
└── UIManager (Node) [ui_manager.gd] — UI 总控
    ├── LevelIntro (Control) — 封印入场视图
    │   ├── IntroOverlay / LevelLabel / TargetLabel / BossPortrait
    ├── GameLayout (HBoxContainer) — 游戏主视图
    │   ├── LeftPanel (Control) — 左侧信息面板
    │   │   ├── PanelBg (ColorRect)          — 全透明 (保留节点供代码引用)
    │   │   │
    │   │   ├── ScoreCard (Panel)             — anchors: top=0, bottom=0.5 (上半 1/2)
    │   │   │   └── ScoreCardVBox             — layout_mode=1, anchors_preset=15 (full rect)
    │   │   │       ├── ColXiLabel           — 列x累乘 + 喜预览
    │   │   │       ├── HandTypeRow          — 三墩牌型+分数
    │   │   │       ├── ScoreLabel / ProgressBar / TargetScoreLabel
    │   │   │
    │   │   ├── MatchPanel (Panel)            — anchors: top=0.5, bottom=0.75 (中间 1/4, 无圆角/无边框/挂 fade)
    │   │   │   └── MatchVBox → MatchTitle / HandsLabel / GoldLabel
    │   │   │
    │   │   └── AntePanel (Panel)             — anchors: top=0.75, bottom=1.0 (底部 1/4, 无圆角/无边框/挂 fade)
    │   │       └── AnteVBox → BarrierLabel / RoundLabel
    │   └── CenterColumn (VBoxContainer) — 中央区域
    │       ├── NinjaBar (HBoxContainer) — 忍者牌栏 (5槽位)
    │       ├── StatusLabel — 状态提示
    │       ├── HandArea (HBoxContainer) — 操作+三组区
    │       │   ├── PlayBtn "討伐"
    │       │   ├── DunArea (Panel) — 三墩容器
    │       │   │   ├── DunHead — 影（1px 边框）
    │       │   │   ├── DunMiddle — 瞬（2px 边框）
    │       │   │   └── DunTail — 滅（3px 边框）
    │       │   ├── AiRearrangeBtn "陣\n形"
    │       │   └── RedrawBtn "换牌"
    │       ├── ColumnLabelRow — 列牌型标签
    │       └── DeckBtn "🎴 牌库"
    ├── ScoringOverlay (Control) — ⛔ 未使用 (Balatro 风内联动画)
    │   ⛔ LevelComplete (已删除, 2026-06-12 Phase E)
    │      Phase E 移除: 计分动画结束后金币飞入左面板, ~1.5s 自动进 Shop
    ├── ShopOverlay (Control, z_index=1100, mouse_filter=IGNORE) — ← **Phase C 新增** 商店覆盖层
    │   └── IGNORE 使事件穿透到 GameLayout，游戏交互由 state guard 保护
│   └── 运行时: add_child(load("res://scenes/ninking/shop_panel.tscn").instantiate())
    ├── GameOver (Control) — 失败弹窗
    │   └── OverlayBg / GameOverLabel / ScoreSummary / RetryButton / BackToMenuButton
    ├── VictoryOverlay (Control) — 通关弹窗
    │   └── OverlayBg / VictoryLabel / StatsSummary / MenuButton
    └── DeckViewer (Control) — 牌库查看器 [z_index=10]
        └── ViewerBg / CardPanel / TitleBar / CountRow / CardScroll / CardGrid
```

> **注意:** 三墩内部的手牌节点（HeadCards/MiddleCards/TailCards）和牌型标签（HeadTypeLabel 等）
> 由 `HandDisplay` 在运行时动态创建和管理，不在静态场景树中。
>
> **⚠️ z_index 陷阱:** `Hand._update_target_z_index()` 会给卡牌设 z_index=0/1/2，在 Godot 4 的累加 z_index 模型下会穿透同层 overlay。DeckViewer 已设 `z_index=10` 应对。ScoringOverlay 计分时不显示（Balatro 风内联动画），不再需要 z_index 防护。详见 `docs/card-framework-usage-guide.md` § 已知陷阱。

### shop.tscn → shop_panel.tscn

> **⛔ 已删除 (Phase C, 2026-06-11).** 商店 UI 移至 `ninking_main.tscn` 的 `UIManager/ShopOverlay` 下。
> 原 `Shop (Control) [shop_ui.gd]` 根节点内容改为 `shop_panel.tscn` 场景片段。
>
> 旧节点结构归档如下：

```
Shop (Control) [shop_ui.gd]       ← 改为 shop_panel.tscn (场景片段)
├── Overlay (ColorRect) — 遮罩
└── ShopPanel (Panel) — 商店主面板
    ├── TitleBar (ColorRect)
    ├── ShopTitle (Label) "萬屋"
    ├── GoldPill (Panel) — 金币显示
    ├── RerollBtn / RerollLabel
    ├── AbilityLabel "忍者牌"
    ├── AbilityRow — 忍者牌商品行
    ├── ItemLabel "道具"
    ├── ItemRow — 道具商品行
    ├── BottomBar (ColorRect)
    ├── ContinueBtn "討伐へ ▶"
    └── NinjaSlotLabel "忍者 X/5"
```

> **文件操作：** `shop.tscn` 整文件删除。`shop_ui.gd` 重写为 panel 模式（init + signal）。
> 旧节点中 `NextLevelHint` 已在 Phase C 决策中去除。

---

## 信号架构

### NinKingGameState 信号

| 信号 | 参数 | 触发时机 |
|---|---|---|
| `state_changed` | `new_state: State` | 状态切换 |
| `score_updated` | `current: int, target: int` | 计分后 |
| `plays_changed` | `remaining: int` | 出牌次数变化 |
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
├── scenes/ninking/          # 场景文件 (12 tscn)
├── scripts/
│   ├── ninking/             # NinKing 核心逻辑 (22 脚本)
│   │   ├── ui/              # NinKing UI (13 脚本)
│   │   ├── debug/           # Debug 场景 (3 脚本 — 2026-06-12)
│   │   │   ├── ninking_card.gd           ← 卡牌渲染 (NinKingCard)
│   │   │   ├── ninking_card_factory.gd   ← 卡牌工厂 (NinKingCardFactory)
│   │   │   ├── game_manager.gd           ← 主场景控制器
│   │   │   ├── ui_manager.gd             ← UI 总控
│   │   │   ├── main_menu.gd              ← 主菜单
│   │   │   ├── shop_ui.gd                ← 商店 UI
│   │   │   ├── hand_display.gd           ← 手牌渲染器
│   │   │   ├── hand_interaction.gd       ← 交互状态机
│   │   │   ├── deck_viewer_controller.gd ← 牌库查看器
│   │   │   ├── ninja_inventory_card.gd     ← 统一忍者卡 (忍者栏 + 商店, 替代旧 DisplayCardBase)
│   │   │   ├── shop_slot.gd              ← 🆕 商店展示容器 (NinjaCard + 购买UI)
│   │   │   ├── ability_slot.gd           ← 忍者牌槽位
│   │   ├── card_data.gd                  ← 扑克牌数据 (CardData)
│   │   ├── deck_manager.gd               ← 牌库管理 (DeckManager)
│   │   ├── hand_evaluator.gd             ← 牌型评估 (HandEvaluator3)
│   │   ├── auto_arranger.gd              ← 排列求解器 (AutoArranger)
│   │   ├── arrangement.gd                ← 排列结果类 (Arrangement)
│   │   ├── score_calculator.gd           ← 计分引擎 (ScoreCalculator)
│   │   ├── score_result.gd               ← 计分结果类 (ScoreResult)
│   │   ├── score_helpers.gd              ← 计分/排列共享辅助函数
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
│   └── expand_mode=IGNORE_SIZE + stretch_mode=KEEP_ASPECT_COVERED + size=125×175 (5:7)
│       (IGNORE_SIZE 防止 Godot 4 每帧覆盖 size 为 SVG viewBox 240×334)
├── _get_card_svg_path() — suit/rank → SVG 文件路径
├── update_display() — 重载 SVG 纹理（换牌/数据变更时）
├── set_visual_state(VisualState) — SWAP_SOURCE(蓝) / REDRAW_TARGET(红) / NORMAL
├── _handle_mouse_released/pressed() — 点击 vs 拖拽判定（CLICK_THRESHOLD=10px）
│   Click: emit ninking_card_clicked → HandInteraction 点选交换
│   Drag:  super._handle_mouse_released() → 框架 drop 处理 →
│          HandCardContainer.move_cards() → SealController.swap_cards() → 游戏状态同步
└── signal ninking_card_clicked(index) — 点选交换（点击触发）

NinKingCardFactory (extends CardFactory) — 框架合约占位 (create_card() 返回 null, 实际创建由 HandDisplay 负责)

HandCardContainer (extends CardContainer) — 3×3 手牌网格容器
├── _card_can_be_added() — 容量检查：同容器重排时跳过容量上限（已含卡片不需位置）
├── _update_target_positions() — 三等份水平和垂直间距布局 9 张卡
│   └── 设置 drop_zone sensor size = 容器 size，2 条垂直 + 2 条水平 partition
├── get_partition_index() — **覆盖基类：** 返回 `row×COLS+col` 网格索引(0-8)
│   基类只返回列索引(0-2)，对 3×3 网格不足
├── move_cards(cards, index) — **覆盖框架 drop 入口：** 同容器单卡拖放 →
│   ├── `SealController.swap_cards()` 同步游戏状态 + emit `hand_swapped`
│   │   → `swap_two_cards()` 视觉交换（经信号链）
│   └── 非 PLAYING 状态时 `swap_cards` 不 emit 信号 → 直接调 `swap_two_cards()`
├── swap_two_cards(src, tgt) — 直接交换 _held_cards 中两张卡的引用+子序+位置
├── grid_index_at(pos) — 从全局坐标解析网格索引（读 partition 数组）
└── get_target_pose_for(card) — 返回卡片在容器中的目标位置（用于 return_card）

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

ShopHandler (extends RefCounted) — 商店委托（C21 拆分）
├── setup(ui: UIManager) — 注入 UI 引用
├── go_shop_pressed() — fade 牌桌→缓存商品→触发 SHOP 状态
├── on_enter_shop() — 重置 reroll 计次→ui.show_shop()→通知 UI 刷新价格
├── on_purchase_requested(ability) — 购买忍者牌
├── on_item_purchase_requested(item) — 购买道具（B6: 星图 → _purchase_star_chart）
├── _purchase_star_chart(item) — 星图购买即用：扣钱→apply_star_chart→Toast→VFX（B6）
├── on_reroll_requested() — 递进式刷新 $3+$1/次（B4）
├── on_continue_requested() — 退出商店→下一封印
├── _reroll_count / _get_reroll_cost() — 内部状态
└── game_manager 将 5 个按钮/信号 connect 到 shop_handler

AnimationHandler (extends RefCounted) — 计分动画委托（C21 拆分）
├── setup(ui, mark_auto_shop_cb) — 注入 UI + auto-shop 回调
├── current_play_data: Dictionary — game_manager 在出牌前写入
├── run_scoring() — Phase 1-4 完整计分动画序列
├── _float_score_gain(anchor, gain, color) — "+N" 上浮飘出
├── _show_breakdown_toast(text, color) — 筹码×倍率内幕 toast
└── game_manager 设 current_play_data → SCORING 触发 run_scoring()

CardData (RefCounted)
├── enum Suit, Rank, HandType3, Enhancement, Seal, Edition
├── class PlayingCard (suit, rank, enhancement, seal, edition)
├── const: HAND_TYPE3_BASE_VALUES, STAR_CHART_UPGRADES, RANK_CHIP_VALUES
├── static: get_hand_type3_leveled_chips/mult(ht, levels)  # v5.0: 行+列共享星图升级
└── static: create_standard_deck()

HandEvaluator3 (RefCounted)
├── class EvalResult (hand_type, base_chips, base_mult, strength)
└── static: evaluate(cards: Array[PlayingCard]) → EvalResult

Arrangement (RefCounted, arrangement.gd)
├── head, mid, tail: Array[PlayingCard]
├── head_eval, mid_eval, tail_eval: EvalResult
└── is_legal(constraint: String = "ascending") — checks constraint (ascending: head≤mid≤tail, descending: head≥mid≥tail)

ScoreHelpers (RefCounted, score_helpers.gd)
├── group_card_chips(cards, hungry_ghost, include_seal) — 含封印×2参数
├── group_ench_chips(cards)
└── group_ench_mult(cards)

AutoArranger (RefCounted)
└── static: find_best(hand, head_ninja, mid_ninja, tail_ninja, star_chart_levels, rules) → Arrangement
    └── _fast_score() v4.0: per-group评分 + 列近似奖励 + 同点数量散惩罚

ScoreResult (RefCounted, score_result.gd)
├── total_score, head_score, mid_score, tail_score
├── col_scores, col_total, global_xi_x_stack, chips_sum, mult_sum, breakdown
└── Per-group breakdown: head/mid/tail card_chips, hand_chips, ench_chips, ninja_chips, etc.

ScoreCalculator (RefCounted)
├── static: calculate(head, mid, tail, evals, col_evals, ninjas, star_charts,
│                    xi_result, seal_effects, gold) → ScoreResult
├── static: collect_ninja_per_group() — 忍效果→行三组分账
├── static: _collect_ninja_for_column() — 忍效果→列分账 (v5.0)
├── static: ninja_affected_groups() — 条件→命中行组
├── static: _compute_group_score() — 行/列通用评分公式 (v5.0: 列复用此方法)
└── (helpers delegated to ScoreHelpers)

XiDetector (RefCounted)
├── class XiResult (triggered, chips_add, mult_x_stack)
│   # v4.0: 四张 chips→×5, chips_add 不再使用(全部×mult)
└── static: detect(head, mid, tail, head_eval, mid_eval, tail_eval) → XiResult

DeckManager (RefCounted)
├── draw_pile, discard_pile
├── draw(count) → Array[PlayingCard]
├── discard(cards)
└── reset(), shuffle()

NinKingGameState (Node, Autoload)
├── current_state, barrier_num, seal_idx, gold, hand, owned_ninjas, star_chart_levels
├── game_mode, current_arrangement, current_col_evals
├── gold/plays_remaining/max_ninja_slots ← ConfigManager 初始化（game_config.json）
├── start_new_run(deck_name, mode) → 读取 ConfigManager.starting_gold + 校验/填充 starter_ninja_ids
├── continue_run() / has_saved_run()
├── auto_arrange() / re_evaluate_arrangement() / get_scoring_rules()
├── swap_cards() / execute_play()
├── go_to_shop() / continue_from_shop() / skip_seal()
└── Signals: state_changed, score_updated, plays_changed, gold_changed,
    hand_updated, arrangement_changed, seal_started, xi_triggered

SealController (RefCounted, 静态方法)
├── execute_play(gs) / prepare_play(gs) / finalize_play(gs, data) — 出牌流程
├── swap_cards(gs, idx1, idx2) — 交换（原地重评估，不触发 AI 重排）
├── go_to_shop(gs) / continue_from_shop(gs) / skip_seal(gs, tag_reward)
├── _complete_seal(gs) — 过关奖励 + 利息（divisor/cap 来自 ConfigManager）
├── _collect_play_gold(gs, cards, xi) — 经济效果统一结算
└── _advance_seal(gs) → bool — 封印/結界推进

ArrangeController (RefCounted, 静态方法)
├── auto_arrange(gs) — 排列计算（不 emit 信号）
├── get_scoring_rules(gs) → Dictionary — 收集封印ノ主+忍者规则
├── sum_ninja_effect(gs, key, default) → int
└── collect_ninja_effect(gs, key, threshold) → Array

NinjaData (RefCounted)
├── ALL_NINJAS: Array[Dictionary] — 45 张定义（45 active + 2 deferred）
├── STARTER_IDS: Array[String] — 初始 9 张（硬编码参考，实际起始忍者由 ConfigManager.starter_ninja_ids 控制）
├── get_by_id(id) → Dictionary
└── get_starter_ninjas() → Array[Dictionary]

NinjaPool (RefCounted)
├── get_random_ninjas(count, exclude_ids, rarity_filter) → Array[Dictionary]
└── get_random_legendary() → Dictionary

NinjaScaling (RefCounted)
└── process_scaling(ninjas, trigger_type, context) — 修炼忍者成长引擎（已接入 finalize_play）

ConsumableData (RefCounted)
├── FUJUTSU_CARDS / STAR_CHART_CARDS / KINJUTSU_CARDS
└── get_random_fujutsu(count) / get_random_star_charts(count) / get_random_kinjutsu(count)

BarrierConfig (RefCounted)
├── 封印/結界配置表（目标分数、金币奖励、封印ノ主）
└── get_seal(barrier, seal_idx) / get_seals_per_barrier() / get_total_barriers() / assign_seal_lord()

BarrierTheme (RefCounted)
└── BARRIER_COLORS: 8 結界冷暖交替配色（紫/青/蓝/翠 冷 → 红/橙/金/粉 暖）

ShopManager (RefCounted)
├── available_ninjas, available_star_charts
├── 商店数量由 ConfigManager: shop_ninja_count（默认 4）/ shop_item_count（默认 2）
├── generate_stock(yasha_shop, exclude_ninja_ids)
├── get_ninjas_for_display() / get_star_charts_for_display()
├── buy_ninja(gs, ninja) / replace_ninja(gs, idx, new_ninja) / sell_ninja(gs, idx) / buy_item(gs, item) / apply_star_chart(gs, hand_type)
└── is_yasha_shop: bool

SaveManager (RefCounted)
├── save_run() / load_run() / delete_run() / has_run_save() / build_run_data()
└── load_progress() / save_progress() / record_run_result() / unlock_deck()

ConfigManager (Node, Autoload)
├── _ready() → FileAccess 读 `res://config/game_config.json` → JSON.parse_string()
├── 校验: 9 必填字段 + 值域（divisor>0, counts≥1 等）+ starter_ninja_ids 非空数组
├── 失败兜底: 硬编码 DEFAULT Dictionary + push_warning(原因清单)
├── 暴露只读属性: starting_gold, plays_per_seal, max_ninja_slots,
│   interest_divisor, interest_cap, shop_ninja_count, shop_item_count,
│   reroll_base_cost, starter_ninja_ids
└── is_loaded() → bool — 确认配置已加载
```
