# 商店自动过渡方案 — Balatro 风免确认流程

> **参考：** Balatro（小丑牌）过关→商店零摩擦流程
> **设计文档：** `07-shop-ui-design.md` / `06-ui-layout-reference.md`
> **影响：** 消除 `LevelComplete` 中间确认步骤，SCORING 动画结束后直达商店

---

## 一、现状分析

### 当前流程

```
SCORING Phase 4 (is_pass)
  → SealController.finalize_play()   ← 发金币/利息 + advance_seal
    → gs._transition_to(SEAL_COMPLETE)  ← 状态机跳转
      → _on_state_changed(SEAL_COMPLETE)
        → show_view("complete")        ← LevelComplete 弹窗
        → set_level_complete(gold)     ← "过关！ +X金币"
          → 玩家手动点击「进入商店」
            → _on_go_shop_pressed()    ← fade_out → SHOP
```

### 问题点

| # | 问题 | 后果 |
|---|------|------|
| 1 | 玩家过关后必须点击「进入商店」按钮 | 多余的确认步骤，破坏节奏 |
| 2 | `LevelComplete` 弹窗遮挡牌桌 | 玩家刚看完华丽计分动画，又被弹窗挡住 |
| 3 | `SEAL_COMPLETE` 状态本质上只做一件事：显示弹窗等点击 | 可以合并到 SHOP 状态中 |

### 小丑牌的做法

```
出牌 → SCORING（筹码计数至达标）
  → 「Won!」闪过 0.5s
  → 自动进入商店
  → 利息/奖励在商店里加到金币上
  → 买完 → 点击 Play → 下一关
```

**关键特征：** 零中间确认步骤。赢了=进商店，没有「是否要去商店」的询问。

---

## 二、方案设计

### 2.1 新流程

```
SCORING Phase 4 (is_pass)
  → 庆祝粒子 + hit_stop (保留现有)
  → 极短停顿 0.3s（感受庆祝）
  → 自动触发商店入场

中间态流程：
  [finalize_play → gold/interest 结算]  ← 仍在 scoring 动画内完成
  → 自动过渡 → SHOP
  → 在商店入场动画中展示金奖励额
```

### 2.2 改动文件清单

| 文件 | 改动类型 | 说明 |
|------|---------|------|
| `scripts/ninking/ui/game_manager.gd` | **修改** | `_run_scoring_animation()` Phase 4 is_pass 末尾 → auto-trigger shop |
| `scripts/ninking/seal_controller.gd` | **修改** | 新增 `finalize_and_go_to_shop()` 或拆分 `finalize_play` 的 gold/interest 逻辑 |
| `scripts/ninking/ui/ui_manager.gd` | **修改** | `show_view("complete")` → 可能不再需要；`LevelComplete` 相关代码可保留但不再必经 |
| `scripts/ninking/game_state.gd` | **确认** | `SEAL_COMPLETE` 状态保留（作为回退/调试），但正常流程不经过 |
| `scenes/ninking/ninking_main.tscn` | **可选简化** | `LevelComplete`→`ToShopButton` 按钮可隐藏或保留做备用 |

**新增文件：** 无

---

## 三、详细实现

### 3.1 SealController 调整

**当前：** `finalize_play()` → `_complete_seal()` → `_transition_to(SEAL_COMPLETE)`

**改为：** 在 `_complete_seal` 中分离「结算」与「状态跳转」，新增 `finalize_and_auto_shop()` 方法：

```gdscript
# ── 新增：结算后直接转 SHOP ──
static func finalize_and_go_to_shop(gs) -> void:
    var play_data: Dictionary = gs._last_play_data  # 或由 game_manager 传入
    # 执行 gold/interest 结算（同 finalize_play 的 is_pass 分支）
    _reward_and_advance(gs, play_data)
    # 直接转 SHOP，跳过 SEAL_COMPLETE
    go_to_shop(gs)

# ── 提取：仅做金币奖励 + advance_seal，不做状态跳转 ──
static func _reward_and_advance(gs) -> void:
    # gold reward (seal_cfg.gold)
    # interest (every $5 → $1, cap $5+bonus)
    # _advance_seal (检查是否为最终 barrier → VICTORY)
    # 注意：如果 advance_seal 返回 false（最终胜利），不转 SHOP 而是转 VICTORY
```

或者更轻量的做法：给 `finalize_play()` 加一个 `auto_shop: bool = false` 参数：

```gdscript
static func finalize_play(gs, play_data: Dictionary, auto_shop: bool = false) -> void:
    # ... 现有逻辑 ...
    if gs.current_score >= gs.target_score:
        _complete_seal(gs, auto_shop)  # 传参决定跳转目标
```

> **倾向：参数方案更小改动，推荐。**

### 3.2 game_manager.gd 调整

**`_run_scoring_animation()` Phase 4 is_pass 块：**

```gdscript
if is_pass:
    # ── 保留现有庆祝动画 ──
    GlobalTweens.play_sfx(SB.SEAL_CLEAR)
    GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "sakura")
    GlobalTweens.do_hit_stop(0.08, 0.05)
    GlobalTweens.punch_in(ui.score_label, 0.4, 1.5)
    await get_tree().create_timer(0.6).timeout

    # ── 改动：finalize + 自动进商店 ──
    SealController.finalize_play(gs, play_data)  # 这会转 SEAL_COMPLETE...

    # 旧方案: SealController.finalize_play(gs, play_data)
    # 新方案: 直接触发 shop 过渡
    _on_auto_shop_transition()
```

注意：`finalize_play` 内部会调 `_complete_seal` → `_transition_to(SEAL_COMPLETE)` → 触发 `_on_state_changed`。这会导致 `LevelComplete` 弹窗闪现。

**所以更干净的做法是：在 scoring 动画内直接做结算，不经过 finalize_play：**

```gdscript
if is_pass:
    # ── 庆祝动画（保留） ──
    GlobalTweens.play_sfx(SB.SEAL_CLEAR)
    # ... 粒子 hit_stop ...
    await get_tree().create_timer(0.6).timeout

    # ── 结算（内联 finalize 的 is_pass 部分） ──
    gs.plays_remaining -= 1
    gs.emit_plays_changed()
    gs.current_score += play_data.score_result.total_score
    # ... discard cards, collect gold, interest ...
    # ... advance_seal → 如果是最终胜利则转 VICTORY ...

    # ── 直接转 SHOP ──
    _on_auto_shop_transition()
```

但这会大量复制 `finalize_play` 逻辑。**更好的折衷：**

保持 `finalize_play` 调用，但在 `_on_state_changed(SEAL_COMPLETE)` 中自动继续，不等待玩家点击。

### 3.3 推荐实现方案 — 自动延续

改动最小、风险最低：

**game_manager.gd `_run_scoring_animation()` Phase 4：**

```gdscript
if is_pass:
    # ── 庆祝动画（保留现有） ──
    GlobalTweens.play_sfx(SB.SEAL_CLEAR)
    GlobalTweens.burst_particles(get_viewport_rect().size * 0.5, "sakura")
    GlobalTweens.do_hit_stop(0.08, 0.05)
    GlobalTweens.punch_in(ui.score_label, 0.4, 1.5)
    await get_tree().create_timer(0.6).timeout

    # ── finalize 会转 SEAL_COMPLETE ──
    SealController.finalize_play(gs, play_data)
    # ── 设置自动进商店标记 ──
    _auto_shop_pending = true
    return  # 让 _on_state_changed(SEAL_COMPLETE) 处理
```

**game_manager.gd `_on_state_changed(SEAL_COMPLETE)`：**

```gdscript
NinKingGameState.State.SEAL_COMPLETE:
    ui.show_view("complete")
    var seal_cfg := BarrierConfig.get_seal(NinKingGameState.barrier_num, NinKingGameState.seal_idx)
    ui.set_level_complete(seal_cfg.get("gold", 0))

    # ── Auto-shop: 短暂展示奖励后自动过渡 ──
    if _auto_shop_pending:
        _auto_shop_pending = false
        await get_tree().create_timer(1.2).timeout  # 让玩家看到奖励数字
        if NinKingGameState.current_state == NinKingGameState.State.SEAL_COMPLETE:
            _on_go_shop_pressed()
```

这样：
- `LevelComplete` 仍然显示（玩家看到过关金币）
- 1.2s 后自动进商店（像小丑牌那样）
- 玩家也可以提前点击「进入商店」（保留按钮）
- `_auto_shop_pending` 标记防止手动点击 + 自动触发冲突

> **注意：** `_on_go_shop_pressed` 有 `_transition_guard` 保护，自动触发时不会重复进入。

### 3.4 时序对比

```
当前:
  ... 庆祝动画 → LevelComplete(弹窗) → 玩家点击[进入商店] → 过渡 → SHOP

方案:
  ... 庆祝动画 → LevelComplete(1.2s自动) → 过渡 → SHOP
                   ↑ 玩家也可提前点击
```

---

## 四、信号/状态机影响

| 影响项 | 说明 | 严重度 |
|--------|------|--------|
| `SEAL_COMPLETE` 状态 | 保留但增加 auto-shop 逻辑；正常流程不再在此状态停留等待 | 🟢 |
| `LevelComplete` 弹窗 | 保留但显示 1.2s 后自动消失；`ToShopButton` 按钮保留可提前点击 | 🟢 |
| `_on_go_shop_pressed` | 被自动流程调用，需确认 `_transition_guard` 兼容 | 🟢 |
| VICTORY 状态 | `_advance_seal` 返回 false 时正常转 VICTORY，不受影响 | 🟢 |
| GAME_OVER 状态 | 不受影响 | 🟢 |
| 手动测试 | 需验证 auto-shop 在快速连续操作下不重复触发 | 🟡 |

---

## 五、实现步骤

### Step 1: game_manager.gd — 新增 `_auto_shop_pending` 标记

```gdscript
# ── Auto-shop: scoring → shop 免确认过渡 ──
var _auto_shop_pending: bool = false
```

### Step 2: game_manager.gd — Phase 4 is_pass 末尾设置标记

在 `_run_scoring_animation()` Phase 4 中 `SealController.finalize_play()` 之前设置标记（**必须在** `finalize_play` 之前，因 finalize_play 内部 emit state_changed 到 SEAL_COMPLETE，handler 需读到 flag）：

```gdscript
if is_pass:
    # ... 庆祝动画 ...
    await get_tree().create_timer(0.6).timeout
    _auto_shop_pending = true  # ← 新增，在 finalize_play 之前
    SealController.finalize_play(gs, play_data)
    _current_play_data.clear()
    return
```

### Step 3: game_manager.gd — `_on_state_changed(SEAL_COMPLETE)` 分支

```gdscript
NinKingGameState.State.SEAL_COMPLETE:
    ui.show_view("complete")
    var seal_cfg := BarrierConfig.get_seal(NinKingGameState.barrier_num, NinKingGameState.seal_idx)
    ui.set_level_complete(seal_cfg.get("gold", 0))

    if _auto_shop_pending:
        _auto_shop_pending = false
        await get_tree().create_timer(1.2).timeout
        if is_instance_valid(ui) and NinKingGameState.current_state == NinKingGameState.State.SEAL_COMPLETE:
            _on_go_shop_pressed()
```

### Step 4: 可能需要的防冲突逻辑

`_on_go_shop_pressed` 已有 `_transition_guard`，但需确保：

```gdscript
func _on_go_shop_pressed() -> void:
    if _transition_guard:
        return
    # ...
```

如果玩家在 auto-shop 倒计时内手动点击按钮：
- `_transition_guard` 防止重复执行
- 自动触发时 `_transition_guard` 已释放 → 正常执行

### Step 5: （可选）关卡过渡动画增强

在 auto-shop 等待 1.2s 期间，可以加一个从分数标签飞向商店入口的微动画（硬币飞入店铺），增强"奖励→商店"的连贯感。

```gdscript
# 在 auto-shop 的 1.2s 等待期间
GlobalTweens.play_sfx(SB.COIN_COLLECT)
GlobalTweens.burst_particles(ui.score_label.global_position, "coin_sparkle")
# 金币数字 +X 浮动并飞向屏幕右上角
```

此步骤为 P2 可选增强，非必须。

---

## 六、风险与边界

| # | 风险 | 缓解 |
|---|------|------|
| R1 | `_on_shop_continue_requested` 与 auto-shop 的交互 | 确认 `_on_go_shop_pressed` 的 `_transition_guard` 能防重入 |
| R2 | 如果 `finalize_play` 中 `_advance_seal` 返回 false（最终胜利），状态会变 VICTORY 而非 SEAL_COMPLETE | `_auto_shop_pending` 标记在 VICTORY handler 中应被清除 |
| R3 | 玩家在 LevelComplete 显示期间快速点击「进入商店」+ auto timer 同时触发 | `_transition_guard` 防重复；auto timer 中检查 `state == SEAL_COMPLETE` |
| R4 | Scene reload / game restart 后 `_auto_shop_pending` 残留 | 在 `_ready()` 中初始化为 `false` |

---

## 七、验收标准

- [ ] 过关后能在 1.2s 内看到 `LevelComplete` 弹窗（显示金币奖励）
- [ ] 1.2s 后自动过渡到商店（不需要点击）
- [ ] 玩家在 auto-transition 前点击「进入商店」可提前进入
- [ ] 最终封印通关时（VICTORY）不会触发 auto-shop
- [ ] `_transition_guard` 在 auto + manual 同时触发时正常防重入
- [ ] 关卡全流程（商店→买→继续→下一关→再过关→再进商店）不崩溃
