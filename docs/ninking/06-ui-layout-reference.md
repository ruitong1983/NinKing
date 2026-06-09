# NinKing UI 布局参考文档

> **维护索引：** 本文档定义全部 UI 区域命名、层级结构、节点访问路径和更新接口。
> 代码中所有 `%` 引用、`@onready` 变量、信号绑定均以此文档为准。

---

## 1. 命名约定

### 术语替换

| 旧称 | 新称 | 说明 |
|------|------|------|
| 小丑牌 (Joker) | **能力牌** (Ability) | 持续被动加成 |
| JokerContainer | **AbilityBar** | 顶部横向能力槽 |
| JokerSlot | **AbilitySlot** | 单个能力槽位 |
| JOKER_SLOT_SCENE | **ABILITY_SLOT_SCENE** | 槽位组件场景 |

### 节点命名规则

| 前缀 | 类别 | 示例 |
|------|------|------|
| `%` 前缀 | 跨层级引用节点 (unique_name_in_owner) | `%ChipsLabel` |
| `PNL_` | 面板容器 | `PNL_MatchInfo` |
| `LBL_` | 标签文字 | `LBL_Score` |
| `BTN_` | 按钮 | `BTN_Play` |
| `BAR_` | 进度/容器条 | `BAR_Progress` |
| `GRID_` | 网格布局 | `GRID_Hand` |
| `AB_` | 能力栏相关 | `AB_Slot` |
| `OVL_` | 覆盖弹窗 | `OVL_Scoring` |

### 与 Figma 命名的分层

> **Figma 设计稿** 使用中文功能描述命名（详见 `08-figma-naming-convention.md`），
> 用于设计沟通和团队协作。**Godot 代码层** 使用英文前缀命名（上表），用于节点引用。
> 两者不直接映射——Figma 关注"设计师看到什么"，Godot 关注"代码如何访问"。

---

## 2. 场景树全图

```
NinKingMain (Control) 1920×1080
│  脚本: game_manager.gd
│
├── GameBg (ColorRect)                     [%GameBg]
│   └── 深绿桌布 #1A3A32
│
└── UIManager (Node)                       [%UIManager]
    脚本: ui_manager.gd
    │
    ├── MainMenu (Control)                 [%MainMenu]    视图: 主菜单
    │   ├── MenuBg (ColorRect)             #1A3A32
    │   ├── MenuBgOverlay (ColorRect)      #000 30%
    │   ├── TitleLabel                     "N I N K I N G"  64px 金色
    │   ├── SubtitleLabel                  "扑克牌型计分闯关" 24px
    │   ├── DeckLabel                      [%DeckLabel]   18px
    │   ├── StartButton                    [%StartButton] "开始游戏"
    │   └── VersionLabel                   "v0.1.0"
    │
    ├── LevelIntro (Control)               [%LevelIntro]  视图: 关卡入场
    │   ├── IntroOverlay (ColorRect)       #000 80%
    │   ├── LevelLabel                     [%LevelLabel]  "第 X 关"
    │   └── TargetLabel                    [%TargetLabel] "封印: XXX"
    │
    ├── GameLayout (VBoxContainer)         [%GameLayout]  视图: 游戏主界面
    │   │
    │   ├── AbilityBar (HBoxContainer)     [%AbilityBar]  能力栏 (原JokerContainer)
    │   │   └── 动态生成 AbilitySlot × 5
    │   │
    │   └── MainArea (HBoxContainer)
    │       │
    │       ├── StatusPanel (Control)      左侧状态面板 380×1080
    │       │   ├── PanelBg (ColorRect)    #0F2822 92%
    │       │   │
    │       │   ├── ScoreDisplay (HBoxContainer)   筹码×倍率区
    │       │   │   ├── ChipsLabel         [%ChipsLabel]   "0" 64px 金色
    │       │   │   ├── MultSign           "x" 48px 灰色
    │       │   │   └── MultLabel          [%MultLabel]    "0" 64px 红色
    │       │   │
    │       │   ├── HandTypeLabel          [%HandTypeLabel] "高牌" 28px
    │       │   ├── ScoreLabel             [%ScoreLabel] "忍気 0" 22px
    │       │   ├── TargetScoreLabel       [%TargetScoreLabel] "封印 300" 18px
    │       │   ├── ProgressBar            [%ProgressBar] 进度条
    │       │   │
    │       │   ├── PNL_MatchInfo (Panel)          比赛信息面板
    │       │   │   ├── LBL_MatchTitle             "比赛信息" 16px 金色
    │       │   │   ├── HandsLabel        [%HandsLabel] "出牌 X"
    │       │   │   ├── DiscardsLabel     [%DiscardsLabel] "手替え X"
    │       │   │   └── GoldLabel         [%GoldLabel] "$X"
    │       │   │
    │       │   └── PNL_LevelInfo (Panel)          关卡信息面板
    │       │       ├── AnteLabel         [%AnteLabel] "結界 X/8"
    │       │       └── RoundLabel        [%RoundLabel] "回合 X"
    │       │
    │       └── PlayArea (VBoxContainer)   右侧操作区
    │           ├── StatusLabel            [%StatusLabel] 居中提示文字
    │           │
    │           ├── ActionBar (HBoxContainer)  [%ActionBar]
    │           │   ├── DiscardBtn         [%DiscardBtn] "换牌(剩X次)" 180×50
    │           │   └── PlayBtn            [%PlayBtn]    "确认出牌" 180×50
    │           │
    │           └── HandArea (HBoxContainer)  [%HandArea]  三组手牌区
    │               ├── PlayBtn            [%PlayBtn]    "出牌" 84×f
    │               ├── DunArea (VBoxContainer)
    │               │   ├── DunHead [%DunHead] (影: hand[0-2])
    │               │   ├── DunMiddle [%DunMiddle] (瞬: hand[3-5])
    │               │   └── DunTail [%DunTail] (滅: hand[6-8])
    │               └── DiscardBtn         [%DiscardBtn] "换牌" 84×f
    │           │
    │           └── DeckBtn                [%DeckBtn] "🎴 牌库: XX" 140×44
    │
    ├── DeckViewer (Control)               [%DeckViewer]  视图: 牌库查看器
    │   ├── ViewerBg (ColorRect)           #000 75% (点击关闭)
    │   └── CardPanel (Panel)              900×640 居中
    │       ├── TitleBar (HBoxContainer)
    │       │   ├── ViewerTitle            "牌库" 24px 金色
    │       │   └── CloseBtn [%CloseBtn]   "✕" 按钮
    │       ├── CountRow (HBoxContainer)
    │       │   ├── DrawCountLabel [%DrawCountLabel]   "牌堆: XX 张"
    │       │   └── DiscardCountLabel [%DiscardCountLabel] "手替札: XX 张"
    │       └── CardScroll (ScrollContainer)
    │           └── CardGrid (GridContainer, 13列) [%CardGrid]
    │               └── 动态生成 card_button 实例 (disabled, 只读)
    │
    ├── OVL_Scoring (Control)              [%ScoringOverlay]  视图: 计分弹窗
    │   ├── OverlayBg                      #000 70%
    │   ├── HandNameLabel                  [%HandNameLabel] "高牌" 48px
    │   ├── ScoreValueLabel                [%ScoreValueLabel] "+ X" 72px 金色
    │   └── ScoreBreakdown                 [%ScoreBreakdown] 计分明细 20px
    │
    ├── OVL_LevelComplete (Control)        [%LevelComplete]  视图: 过关
    │   ├── OverlayBg                      #000 70%
    │   ├── CompleteLabel                  [%CompleteLabel] "过关！" 56px 金色
    │   ├── RewardLabel                    [%RewardLabel] "+X 金币"
    │   └── ToShopButton                   [%ToShopButton] "进入商店"
    │
    └── OVL_GameOver (Control)             [%GameOver]  视图: 失败
        ├── OverlayBg                      #000 80%
        ├── GameOverLabel                  "失败" 56px 红色
        └── RetryButton                    [%RetryButton] "重新开始"
```

---

## 3. 区域定义

### 3.1 主菜单视图 `MainMenu`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/MainMenu` |
| 访问名 | `%MainMenu` |
| 默认状态 | 可见 |
| 用途 | 游戏启动后的第一个界面 |

**交互：** 点击 `StartButton` → `game_manager._on_start_pressed()` → `NinKingGameState.start_new_run()`

### 3.2 关卡入场视图 `LevelIntro`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/LevelIntro` |
| 访问名 | `%LevelIntro` |
| 默认状态 | 隐藏 |
| 用途 | 每关开始前的 2 秒倒计时展示 |

**数据源：** `LevelConfig.get_level(n)` → 关卡号 + 封印值

### 3.3 游戏主视图 `GameLayout`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/GameLayout` |
| 访问名 | `%GameLayout` |
| 默认状态 | 隐藏 |
| 用途 | 游戏进行中的主操作界面 |

#### 3.3.1 能力栏 `AbilityBar`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/GameLayout/AbilityBar` |
| 访问名 | `%AbilityBar` |
| 布局 | 水平居中，间距 24px |
| 槽位数 | 5 |
| 组件场景 | `res://scenes/ninking/ability_slot.tscn` |

**刷新方法：** `ui_manager.refresh_abilities(owned_abilities, max_slots)`

#### 3.3.2 状态面板 `StatusPanel`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/GameLayout/MainArea/StatusPanel` |
| 宽度 | 380px |
| 背景色 | `#0F2822` 92% 不透明 |
| 用途 | 显示全部计分与状态数据 |

**子区域：**

##### a. 筹码倍率区 `ScoreDisplay`

```
┌──────────────┐
│ 0  ×  0     │  ChipsLabel (金色64) ×  MultLabel (红色64)
└──────────────┘
```

##### b. 牌型预览

```
┌──────────────┐
│ 高牌          │  HandTypeLabel — 选中 5 张时实时预览
└──────────────┘
```

##### c. 忍気区

```
┌──────────────┐
│ 忍気 0   │  ScoreLabel
│ 封印 300    │  TargetScoreLabel
│ ████░░░░░░░  │  ProgressBar
└──────────────┘
```

##### d. 比赛信息面板 `PNL_MatchInfo`

| 字段 | 节点 | 格式 |
|------|------|------|
| 标题 | `LBL_MatchTitle` | "比赛信息" |
| 已出牌数 | `HandsLabel` | "出牌 X" |
| 手替え | `DiscardsLabel` | "手替え X" |
| 金币 | `GoldLabel` | "$X" |

##### e. 关卡信息面板 `PNL_LevelInfo`

| 字段 | 节点 | 格式 |
|------|------|------|
| 結界 | `AnteLabel` | "結界 X/8" |
| 回合 | `RoundLabel` | "回合 X" |

#### 3.3.3 操作区 `PlayArea`

| 属性 | 值 |
|------|-----|
| 位置 | 状态面板右侧，自适应填充 |

**子区域：**

##### a. 操作栏 `ActionBar`

| 按钮 | 节点 | 尺寸 | 显示条件 |
|------|------|------|----------|
| 出牌 | `PlayButton` | 220×60 | 选中 5 张卡牌 |
| 换牌 | `SwapBtn` | 220×60 | 选中 1-5 张卡牌 |
| — | — | — | 未选中时整栏隐藏 |

##### b. 手牌区 `HandArea` (三组)

| 属性 | 值 |
|------|-----|
| 组件场景 | `res://scenes/ninking/card_button.tscn` |
| 卡牌数 | **9** (3×3 三组) |
| 单牌尺寸 | 90×130 |
| 交互 | 点击两张牌互换（蓝高亮=交换源）；换牌模式（红高亮=标记丢弃） |
| 约束 | 影牌力 ≤ 瞬牌力 ≤ 滅牌力 |
| 约束满足 | 箭头绿色"≤" |
| 约束违规 | 箭头红色"≰"，Tooltip显示违规原因 |

### 3.4 计分弹窗 `OVL_Scoring`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/OVL_Scoring` |
| 访问名 | `%ScoringOverlay` |
| 用途 | 出牌后展示牌型名称与忍気 |
| 动画 | Tween 2s 后自动消失 |

### 3.5 过关弹窗 `OVL_LevelComplete`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/OVL_LevelComplete` |
| 访问名 | `%LevelComplete` |
| 用途 | 展示过关奖励 |

### 3.6 失败弹窗 `OVL_GameOver`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/OVL_GameOver` |
| 访问名 | `%GameOver` |
| 用途 | 展示失败信息与重试按钮 |

---

### 3.7 牌库查看器 `DeckViewer`

| 属性 | 值 |
|------|-----|
| 节点路径 | `UIManager/DeckViewer` |
| 访问名 | `%DeckViewer` |
| 默认状态 | 隐藏 |
| 用途 | 点击 `DeckBtn` 打开，显示牌堆剩余卡牌（按花色排序） |

**打开方式：** 点击游戏界面中的 `DeckBtn`（位于 `DunArea` 下方）
**关闭方式：** 点击 `✕` 按钮 或 点击遮罩背景

**数据源：** `NinKingGameState.deck_manager.draw_pile` → 牌堆剩余卡牌列表（CardGrid 中每个只读卡牌按钮）
`NinKingGameState.deck_manager.discard_pile` → 手替札数量

**更新时机：** 每次牌库变化（抽牌/手替え/换牌后）→ `game_manager._update_deck_display()` → `ui_manager.update_deck_count()`

**`DeckBtn` 样式：**
- 金色文字 `🎴 牌库: XX`，18px
- 背景 `#0F2822` + 1px 金色描边 `#D4A843` + 圆角 8px + 阴影
- hover 时文字变亮金色 `#F0D060`
- 尺寸 200×48，居中位于 HandArea 下方

**CardPanel 尺寸：** 900×640，居中于 1920×1080 遮罩内
**动画：** 打开淡入 0.25s / 关闭淡出 0.2s（`GlobalTweens.fade_in/fade_out`）

---
## 4. 视图状态切换

```
                    ┌──────────┐
   game_manager     │ MainMenu │  ← 启动默认显示
   _on_state_changed│ visible=T │
        │           └────┬─────┘
        │ 点击开始        │
        ▼                ▼
   ┌──────────┐    ┌──────────┐
   │LevelIntro│    │ GameBg   │
   │ visible=T│    │ visible=T│
   └────┬─────┘    └──────────┘
        │ 2s 后
        ▼
   ┌──────────┐
   │GameLayout│  ← 游戏主界面
   │ visible=T│
   └────┬─────┘
        │
   ┌────┴─────┬──────────┬──────────┐
   ▼          ▼          ▼          ▼
Scoring  LevelComplete  GameOver  (出牌→计分
Overlay  (忍気达标)    (换牌用完)   →过关→商店)
```

**`show_view()` 映射：**

| view 参数 | MainMenu | GameBg | LevelIntro | GameLayout | Scoring | LevelComplete | GameOver |
|-----------|----------|--------|------------|------------|---------|---------------|----------|
| `"menu"` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `"intro"` | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `"game"` | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `"scoring"` | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| `"complete"` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| `"gameover"` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 5. 更新接口速查

### UIManager 公开方法

```gdscript
# 视图
show_view(view: String)

# 关卡入场
set_intro(level_num: int, target: int)
on_level_start(level_num: int, target: int)

# 计分
update_score(current: int, target: int)
update_gold(amount: int)
update_match_info(swaps_remaining: int, level_num: int)
update_ante(level_num: int)
update_target(target: int)

# 手牌
refresh_hand(hand: Array)
refresh_abilities(owned: Array, max_slots: int)   # ← 原名 refresh_jokers
clear_selection()
toggle_card_selection(idx: int, btn: Button)

# 牌型预览
update_hand_type_preview(hand: Array, indices: Array[int])
clear_hand_type_preview()

# 过关
set_level_complete(gold_reward: int)
restore_ui_state()
```

### 数据流

```
NinKingGameState (autoload)
  │
  ├── state_changed ──→ game_manager._on_state_changed()
  ├── score_updated ──→ game_manager._on_score_updated()
  ├── swap_used ──────→ game_manager._on_swap_used()
  ├── gold_changed ───→ game_manager._on_gold_changed()
  ├── hand_updated ───→ game_manager._on_hand_updated()
  └── level_started ──→ game_manager._on_level_started()
        │
        └── 全部委托给 UIManager 对应方法
```

---

## 6. 配色速查

| 名称 | 色值 | 用途 |
|------|------|------|
| `COLOR_TABLE` | `#1A3A32` | 桌布底色 |
| `COLOR_DARK_BG` | `#0F2822` (92%) | 左侧面板底色 |
| `COLOR_GOLD` | `#D4A843` | 金色文字/筹码/进度填充 |
| `COLOR_GOLD_LIGHT` | `#F0D060` | 金币文字 |
| `COLOR_RED` | `#E04040` | 倍率数字/出牌按钮 |
| `COLOR_BLUE` | `#4080D0` | 换牌按钮 |
| `COLOR_WHITE` | `#F0EDE4` | 通用白色文字 |
| `COLOR_DIM` | `#7A7A6A` | 次要文字 |
| `COLOR_PANEL_RED` | `#4A2020` | 比赛信息面板 |
| `COLOR_PANEL_BROWN` | `#3D2B1A` | 关卡信息面板 |
| `COLOR_CARD` | `#F8F4E8` | 卡牌白底 |
| `COLOR_CARD_BORDER` | `#3A3A3A` | 卡牌边框 |
| `COLOR_OVERLAY` | `#000000` (70%/80%) | 弹窗遮罩 |

---

## 7. 文件索引

| 文件 | 职责 |
|------|------|
| `scenes/ninking/ninking_launcher.tscn` | 启动场景（自动跳转） |
| `scenes/ninking/ninking_main.tscn` | 主UI场景（本文档所述） |
| `scripts/ninking/ui/main_menu.gd` | 启动器脚本 |
| `scripts/ninking/ui/game_manager.gd` | 游戏流程控制 |
| `scripts/ninking/ui/ui_manager.gd` | UI显示管理 |
| `scripts/ninking/game_state.gd` | 游戏状态 autoload |
| `scripts/ninking/card_data.gd` | 卡牌数据定义 |
| `scripts/ninking/hand_evaluator.gd` | 牌型评估 |
| `scripts/ninking/score_calculator.gd` | 计分计算 |
| `scripts/ninking/joker_data.gd` | 能力牌配置（待重命名） |
| `scripts/ninking/level_config.gd` | 关卡配置 |
| `scripts/ninking/shop_manager.gd` | 商店管理 |
| `docs/ninking/01-game-design.md` | 游戏设计文档 |
| `docs/ninking/03-technical-design.md` | 技术设计文档 |
| `docs/ninking/05-image-asset-generation-plan.md` | 素材生成方案 |
| `docs/ninking/06-ui-layout-reference.md` | 本文档 |
