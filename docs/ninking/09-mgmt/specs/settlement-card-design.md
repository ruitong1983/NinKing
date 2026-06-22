# 结算卡片「封印解除」— 设计规格书

> **审定中：** 2026-06-22 | **来源：** Grill 方案 B 修订 | **参考：** Balatro round result
> **关联 TODO：** Phase E 结算流程沉浸化 | **Priority：** P0
> **设计目标：** 计分结束后，独立结算环节展示战果，重点凸出金币信息，玩家主动按钮进入商店

---

## 一、设计原则

1. **独立环节：** 结算在计分动画（Phase 1-4）全部完成后触发，作为 SEAL_COMPLETE 状态的唯一内容
2. **金币聚焦：** 计分环节不展示金币信息（`_play_gold_settlement` 移除），全部金币获得在结算卡片上以 count-up 动画呈现
3. **玩家控制：** 没有自动关闭、没有点击空白跳过——玩家必须点击「封印解除」按钮才能进入商店
4. **场景可编辑：** 卡片作为场景树实例加入 `ninking_main.tscn`，所有节点直接在 Godot 编辑器中拖拽调整

---

## 二、流程

```
Phase 4 (win):
  0.0s  SEAL_CLEAR SFX
  0.0s  sakura 粒子 + hit_stop
  0.0s  score_label punch_in (0.4s)
  0.8s  wait （确保 punch_in + 粒子走完）
  0.8s  记录 gold_before_settlement = gs.gold
  0.8s  SealController.finalize_play()
          → 经济忍者产金 + gold_changed.emit (HUD 静默更新)
          → 基础封印金 + 利息 + gold_changed.emit (HUD 静默更新)
          → _transition_to(SEAL_COMPLETE)

SEAL_COMPLETE:
  0.0s  ui.show_view("settlement")
  0.0s  结算卡片入场动画（详见 §四）
  1.5s  卡片完全展示，按钮可用
  ∞     等待玩家点击「封印解除」
  点击  → 卡片退出动画 (0.2s)
        → shop_handler.go_shop_pressed()
        → 状态变 SHOP → show_view("shop") 自动隐藏结算卡片
```

### 2.1 关键时序保证

| 事件 | 位置 | 说明 |
|------|------|------|
| `gold_before_settlement` 捕获 | `animation_handler.gd` Phase 4 win，`finalize_play` 调用前 | 此时 `gs.gold` 尚未被 `_complete_seal` 修改 |
| `gold_changed.emit` 触发 | `seal_controller.gd` `_complete_seal()` + `_collect_play_gold()` | 多次 emit，HUD GoldLabel 被静默 set_text |
| 结算卡片 `show_card()` | `game_manager.gd` SEAL_COMPLETE 分支 | 此时 `NinKingGameState.gold` 已是结算后数值 |

### 2.2 与旧方案对比

| 方面 | 当前 Phase E | 新方案 |
|------|-------------|--------|
| 计分阶段是否展示金币 | `_play_gold_settlement` 带飞行动画 | ❌ 移除，零金币展示 |
| 结算触发方式 | 0.9s timer 自动进商店 | 玩家点击「封印解除」按钮 |
| 金币信息载体 | HUD GoldLabel 动画 | 结算卡片 count-up（重点） |
| 是否可跳过 | 点击任意处跳过 | **不能跳过**，必须按钮 |
| 可编辑性 | 代码动态创建 | 场景树实例，编辑器可直接调 |

---

## 三、场景结构

### 3.1 场景树位置

```
ninking_main.tscn
└── NinKingMain (Control) ← game_manager.gd
    ├── CardManager (实例)
    ├── GameBg (TextureRect) %GameBg
    ├── UIManager (Control) ← ui_manager.gd
    │   ├── LevelIntro
    │   ├── GameLayout
    │   │   ├── LeftPanel
    │   │   ├── CenterColumn
    │   │   └── ...
    │   ├── ScoringOverlay
    │   ├── GameOver
    │   ├── VictoryOverlay
    │   ├── ShopOverlay
    │   ├── SettlementOverlay       ← ✨ 新增, 实例化 settlement_card.tscn
    │   │   ├── Vignette
    │   │   └── CardPanel
    │   │       ├── SealTitle %SealTitle
    │   │       ├── BreakLabel %BreakLabel
    │   │       ├── ScoreLabel %ScoreLabel
    │   │       ├── GoldLabel %GoldLabel
    │   │       ├── TotalGoldLabel %TotalGoldLabel
    │   │       ├── LordLabel %LordLabel
    │   │       └── UnlockBtn %UnlockBtn
    │   ├── DeckViewer
    │   └── StatusLabel
    └── CardGrid
```

### 3.2 节点属性（编辑器默认值）

```
SettlementOverlay (Control)
  ├─ visible = false
  ├─ mouse_filter = MOUSE_FILTER_IGNORE (1)
  ├─ anchors: full rect
  │
  ├─ Vignette (ColorRect)
  │   ├─ color = rgba(0, 0, 0, 0.25)
  │   ├─ mouse_filter = IGNORE
  │   └─ anchors: full rect (遮罩用)
  │
  └─ CardPanel (Panel)
      ├─ anchors: center
      ├─ custom_minimum_size: 520 × 440
      ├─ mouse_filter = IGNORE (按钮自行处理)
      ├─ theme_override: StyleBoxFlat 粗边框
      │
      ├─ SealTitle (Label) %SealTitle
      │   └─ font_size 20, accent 色, 居中, 距顶 30px
      ├─ BreakLabel (Label) %BreakLabel
      │   └─ font_size 48, gold #e8c860, 粗描边 3px, 居中
      ├─ ScoreLabel (Label) %ScoreLabel
      │   └─ font_size 36, 淡灰 #b0b0bf, 居中
      ├─ GoldLabel (Label) %GoldLabel
      │   └─ font_size 32, 金色 #f0d060, 居中（重点高亮）
      ├─ TotalGoldLabel (Label) %TotalGoldLabel
      │   └─ font_size 20, 灰色 #888, 居中
      ├─ LordLabel (Label) %LordLabel
      │   ├─ visible = false
      │   └─ font_size 18, accent 色, 居中（仅 Boss 封印时显示）
      └─ UnlockBtn (Button) %UnlockBtn
          ├─ disabled = true
          ├─ font_size 24, 白字
          ├─ text = "封印解除"
          └─ Size: 200 × 50, 居中底部
```

### 3.3 布局提示

- 所有 Label 和 Button 的 exact offset 值均为编辑器默认值
- 用户可在 Godot 编辑器中直接拖拽调整位置/尺寸/颜色/字号
- `SettlementOverlay` 实例化后，双击即可进入 `settlement_card.tscn` 编辑
- 编辑 `CardPanel` 的 `theme_override` 时建议在 `settlement_card.tscn` 中修改，避免影响主场景

---

## 四、入场动画

### 4.1 序列

```
show_card(data) 被调用
  │
  ├─ 0. GlobalTweens.burst_particles(center, "manga_burst", barrier_particle_color)
  │       → 粒子爆发
  │
  ├─ 1. GlobalTweens.do_hit_stop(0.06, 0.04)
  │       → 定格强调
  │
  ├─ 2. CardPanel tweens:
  │       scale 0 → 1.05 (0.25s, TRANS_BACK, EASE_OUT)
  │       scale 1.05 → 1.0 (0.08s, EASE_OUT)
  │
  ├─ 3. Stagger in (每项 0.08s 间隔):
  │       SealTitle:     modulate.a 0→1 + scale 0.5→1 (0.15s)
  │       BreakLabel:    modulate.a 0→1 + scale 0.5→1 (0.2s)
  │       ScoreLabel:    modulate.a 0→1 (0.15s)
  │
  ├─ 4. GoldLabel count-up:
  │       tween_method(float(val)): label.text = "+%d $" % val
  │       0 → gold_gained, 0.5s
  │       GlobalTweens.play_sfx(SB.UI_COIN) 在完成时
  │
  ├─ 5. TotalGoldLabel: modulate.a 0→1 (0.1s)
  │
  └─ 6. UnlockBtn:
        disabled = false
        pulse tween: modulate 1.0 ↔ 1.1 (循环, 0.6s)
```

### 4.2 退出动画

```
_on_unlock_btn_pressed():
  1. btn.disabled = true（防双击）
  2. CardPanel tween:
       scale 1.0 → 1.05 (0.1s)
       scale 1.05 → 0 (0.2s, TRANS_BACK, EASE_IN)
       modulate.a 1 → 0 (parallel, 0.2s)
  3. await finished
  4. unlock_pressed.emit() → game_manager 接收 → go_shop_pressed()
```

---

## 五、UIManager 接口

### 5.1 `show_view()` 新增分支

```gdscript
func show_view(view: String) -> void:
    game_bg.visible = (view in ["game", "intro", "scoring", "shop", "settlement"])
    level_intro.visible = (view == "intro")
    game_layout.visible = (view in ["game", "scoring", "shop", "settlement"])
    shop_overlay.visible = (view == "shop")
    game_over.visible = (view == "gameover")
    victory_overlay.visible = (view == "victory")
    settlement_overlay.visible = (view == "settlement")     # ← 新增
    card_grid.visible = (view in ["game", "scoring"])
```

### 5.2 新增 @onready 引用

```gdscript
@onready var settlement_overlay: SettlementCard = %SettlementOverlay
```

### 5.3 SettlementCard 公开方法

```gdscript
class_name SettlementCard extends Control

signal unlock_pressed()     # 玩家点击「封印解除」

func show_card(data: Dictionary) -> void
    # data keys:
    #   barrier_num: int       (1-8)
    #   seal_idx: int          (0=修羅/1=明王/2=夜叉)
    #   score: int             (当前总分)
    #   gold_gained: int       (本局获得金币)
    #   total_gold: int        (结算后总金币)
    #   seal_lord_name: String (可选，封印ノ主名)
```

---

## 六、game_manager.gd 改动

### 6.1 删除

```gdscript
# 全部删除:
var _shop_skip_overlay: Control = null
var _shop_skip_requested: bool = false

func _play_gold_settlement(old_gold, new_gold, gain) -> void     # 整方法删
func _create_shop_skip_overlay() -> void                          # 整方法删
func _on_skip_overlay_input(event: InputEvent) -> void            # 整方法删
func _do_shop_transition() -> void                                # 整方法删
```

### 6.2 修改

```gdscript
# _on_state_changed(SEAL_COMPLETE) 分支:
NinKingGameState.State.SEAL_COMPLETE:
    ui.show_view("settlement")
    if _auto_shop_pending:
        _auto_shop_pending = false
        _show_settlement_card()
```

### 6.3 新增

```gdscript
# _ready() 中:
ui.settlement_overlay.unlock_pressed.connect(_on_settlement_unlock)

# 新方法:
func _show_settlement_card() -> void:
    var old_gold := animation_handler.current_play_data.get("gold_before_settlement", -1)
    var gain := max(0, NinKingGameState.gold - old_gold) if old_gold >= 0 else 0
    ui.settlement_overlay.show_card({
        barrier_num = NinKingGameState.barrier_num,
        seal_idx = NinKingGameState.seal_idx,
        num = NinKingGameState.current_score,
        gold_gained = gain,
        total_gold = NinKingGameState.gold,
        seal_lord_name = NinKingGameState.current_seal_lord_name,
    })

func _on_settlement_unlock() -> void:
    if not is_instance_valid(ui):
        return
    if NinKingGameState.current_state != NinKingGameState.State.SEAL_COMPLETE:
        return
    shop_handler.go_shop_pressed()
```

---

## 七、文件清单

| # | 文件 | 操作 | 说明 | 预估行数 |
|---|------|------|------|---------|
| S1 | `scenes/ninking/settlement_card.tscn` | **新建** | 结算卡片场景（Vignette + CardPanel + 6 Labels + Button） | ~70 tscn |
| S2 | `scripts/ninking/ui/settlement_card.gd` | **新建** | `class_name SettlementCard extends Control`，入场动画 + 信号 | ~130 gd |
| S3 | `scenes/ninking/ninking_main.tscn` | **修改** | 加一行实例化 `settlement_card.tscn`，parent="UIManager" | +1 |
| S4 | `scripts/ninking/ui/ui_manager.gd` | **修改** | `@onready var settlement_overlay` + `show_view` 分支 | +4 |
| S5 | `scripts/ninking/ui/game_manager.gd` | **修改** | SEAL_COMPLETE 分支重写 + 连信号 + 删 4 旧方法 + 2 旧变量 | -50 +35 |
| S6 | `docs/ninking/09-mgmt/TODO.md` | **修改** | 确认 Phase E 同步 | +1 |

**总计：** ~240 行 / 6 文件（2 新建 + 4 修改）

---

## 八、边界情况

| 场景 | 风险 | 防护 |
|------|------|------|
| 玩家疯狂点击按钮 | `unlock_pressed` 多次发射 | 按钮 `_pressed` 后立即 `disabled = true`，之后不再响应 |
| `gold_before_settlement` 不可用 | `gain` 计算为负 | fallback `old_gold = -1`，检测后 `gain = 0`，卡片显示 "+0 $" |
| 结算卡片展示时游戏被最小化/切后台 | 动画暂停后恢复 | 所有 tween 使用 `set_ignore_time_scale(true)` 或默认行为 |
| 结算卡片展示期间触发场景切换 | 节点被 free，tween 报错 | `is_instance_valid(card)` / `is_instance_valid(ui)` 全路径守卫 |
| show_view 被连续调用两次 | 可见性闪烁 | `show_view` 是幂等的，反复调用只影响 visible 属性 |
| `_auto_shop_pending` 为 false | 不触发结算 | 正常情况 Phase 4 win 一定会 mark_auto_shop；VICTORY 分支已清 flag |

---

## 九、文档同步

| 文档 | 改动 |
|------|------|
| `TODO.md` Phase E | 更新状态，标记 E 系列为完成 |
| `04-ui/11-main-overlay-design.md` | 新增 SettlementOverlay 节点描述 + show_view 表 |
| `DOCUMENT_MAP.md` | 新增 `settlement_card.gd` 映射条目 |
