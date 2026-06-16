# UI 信号架构与数据流

> **最后更新：** 2026-06-16
> **关联文档：** [`04-ui/06-ui-layout-reference.md`](../04-ui/06-ui-layout-reference.md) · `scripts/ninking/ui/ui_manager.gd` · `scripts/ninking/game_state.gd`

---

## UIManager 公开方法

> **校验依据：** `scripts/ninking/ui/ui_manager.gd` 实际 API。[`方括号`] 内为可选参数，`→` 为返回类型。

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
func shop_panel_update_reroll_cost(cost: int) -> void
func shop_panel_refresh_stock() -> void
func shop_panel_mark_item_purchased(item_id: String) -> void  # 标记星图卡为已购
func get_current_shop_panel() -> Control
func show_replace_overlay(new_ninja: Dictionary, old_ninjas: Array[Dictionary]) -> NinjaReplaceOverlay
  # 创建替换弹窗（全屏模态 CanvasLayer），返回 overlay 实例供 await replacement_chosen
func hide_replace_overlay() -> void
  # queue_free 当前替换弹窗
```

## UIManager 信号

```gdscript
# 🏪 商店 — game_manager 连接这些信号
signal shop_purchase_requested(ability_data: Dictionary)
signal shop_item_purchase_requested(item_data: Dictionary)
signal shop_reroll_requested()
signal shop_continue_requested()
```

## 数据流

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
