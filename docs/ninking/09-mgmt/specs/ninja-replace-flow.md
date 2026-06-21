# 满员忍者替换购买 — 设计规格书

> **⛔ 已废弃 (2026-06-21):** 替换系统已删除。满员购买改为 Toast "忍者栏已满，请先出售" + 忍者栏脉冲动画，引导玩家自行出售。
> **原审定：** 2026-06-16 | **来源：** Grill + review-plan | **参考：** Balatro 小丑牌替换交互
> **原关联 TODO：** B14 | **原 Priority：** P1

---

## 一、触发条件

```
玩家在商店点击购买第 N 张忍者牌
    │
    ├── owned_ninjas.size() < max_ninja_slots (5)
    │   └─ 正常购买（现有逻辑）
    │
    └── owned_ninjas.size() >= max_ninja_slots
        └─ 走替换流程（本文档）
```

---

## 二、替换流程（Balatro 风）

### 2.1 先买后换

```
1. 检查金币是否足够购买新牌
       │ 不够 → Toast "金币不足!" → return
       │ 够 → 扣除新牌金额 ✅（先买，不可逆）
       
2. 检查 _replace_guard
       │ 为 true → 静默拦截（防双击）
       │ 为 false → 设 guard = true → 继续

3. 弹出 NinjaReplaceOverlay（全屏模态 CanvasLayer）
       ├─ 左半：新牌大图展示（ninja_card.tscn 实例，不可交互）
       │   ├─ 卡面 + 效果描述
       │   └─ 标签: "花费 $N · 选择一个要替换的忍者"
       ├─ 右半：5 张现有忍者卡副本（ninja_card.tscn 实例，只读模式）
       │   ├─ 每张卡片下显示 "退还 ~$X"（半价向上取整）
       │   ├─ 点击任一旧卡 → 选中高亮（橘色边框 2px）
       │   └─ 二次确认 → 关闭弹窗
       ├─ [取消] 按钮（x 关闭同理）
       └─ ESC / 点击遮罩 → 取消

4. 玩家选择
       ├─ 确认替换 → 
       │   1. ShopManager.replace_ninja(gs, index, new_ninja)
       │   2. 退半价金币（max(1, ceil(old_cost × 0.5))）
       │   3. gold_changed.emit
       │   4. 刷新忍者栏（diff 模式，旧卡 dissolve_out → 新卡 pop_in）
       │   5. Toast: "火遁·初 → 影足轻 (退还 $3)"
       │   6. play_sfx(SB.SWAP) + play_sfx(SB.UI_COIN)
       │
       └─ 取消 →
           1. 全额退还新牌金额
           2. gold_changed.emit
           3. Toast: "已取消"
           4. overlay.close()
       
5. _replace_guard = false（复位）
```

### 2.2 替换期间操作锁定

替换弹窗打开时，以下操作全部被 `_replace_guard` 拦截：

| 操作 | 拦截点 | 行为 |
|------|--------|------|
| 购买另一张忍者 | `on_purchase_requested()` | 静默忽略 |
| 购买星图卡 | `on_item_purchase_requested()` | 静默忽略 |
| 刷新商品 | `on_reroll_requested()` | Toast "替换中，请先完成" |
| 出售忍者 | `on_sell_requested()` | Toast "替换中，请先完成" |
| 继续/离开商店 | `on_continue_requested()` | Toast "替换中，请先完成" |

---

## 三、UI 设计

### 3.1 NinjaReplaceOverlay 场景结构

```
NinjaReplaceOverlay (CanvasLayer) layer=128
├── Bg (ColorRect) — #000 70% mouse_filter=MOUSE_FILTER_STOP
│   └── gui_input → emit cancelled (忽略点击区域)
├── Container (CenterContainer)
│   └── Panel (九宫格背景)
│       ├── Title ("选择替换的忍者")
│       ├── HBoxContainer
│       │   ├── NewCardZone (VBoxContainer)
│       │   │   ├── NinjaCard (新牌, 175×245, 不可交互)
│       │   │   └── CostLabel ("花费 $N")
│       │   ├── ArrowLabel ("↓ 替换 ↓")
│       │   └── OldCardsGrid (GridContainer, 1行5列)
│       │       └── NinjaCard ×5 (只读, 点击选中, 显示售价)
│       └── CancelBtn ("取消")
```

### 3.2 交互细节

| 元素 | 行为 |
|------|------|
| 旧牌悬停 | `GlobalTweens.pop_in()` 微放大, cursor → hand |
| 旧牌选中 | 橘色边框 2px + scale 1.05 |
| 取消按钮 | hover SFX + 点击 emit `cancelled` |
| ESC 键 | 同取消 |
| 点击遮罩 | 同取消 |
| 确认后旧牌消失 | `_animate_out()` dissolve_out 效果（已有的 dissolve 材质） |
| 新牌入槽 | `GlobalTweens.pop_in()` + SFX DEAL |

---

## 四、文件清单

| # | 文件 | 动作 | 改动量 |
|---|------|------|--------|
| R1 | **新建** `scenes/ninking/ninja_replace_overlay.tscn` | 新建场景 | ~30 行 tscn |
| R2 | **新建** `scripts/ninking/ui/ninja_replace_overlay.gd` | class_name NinjaReplaceOverlay extends CanvasLayer | ~120 行 |
| R3 | `scripts/ninking/ui/shop_handler.gd` | + `_replace_guard` + `_start_replace_flow()` + 4 操作锁定 | ~60 行 |
| R4 | `scripts/ninking/ui/ui_manager.gd` | + `show_replace_overlay()` / `hide_replace_overlay()` + 信号转发 | ~30 行 |
| R5 | `scripts/ninking/shop_manager.gd` | + `static func replace_ninja(gs, index, new_ninja)` | ~8 行 |
| R6 | `scripts/ninking/ui/ninja_bar_node.gd` | 无需修改（refresh() 走 diff 已支持替换） | 0 |
| R7 | `docs/ninking/TODO.md` | B14 条目已在 TODO | ✅ |

**总计：** ~248 行新增 / 6 文件（3 新建 + 3 修改）

---

## 五、经济参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 卖出退还 | `max(1, ceil(cost × 0.5))` | 半价向上取整，至少 $1 |
| 取消退还 | `cost`（全额） | 先买后换，取消必须退全款 |

---

## 六、边界情况

| 场景 | 处理 |
|------|------|
| 替换弹窗开着时商店被关闭 | 不会被触发（`_replace_guard` 阻止 continue） |
| 快速点击两张不同的旧卡 | 取最后一次点击 |
| 替换后库存只剩 4 张 | 下次重新满 5 张时再次触发替换 |
| 唯一忍者和新牌一样（同一张） | 不做去重，允许同卡替换（与 Balatro 一致） |
| `min_ninja_slots` 未来可能小于 5 | 硬编码 5 在 `game_state.gd`，非运行时变量 | 

---

## 七、审阅决策记录

| # | 决策 | 结论 |
|---|------|------|
| Q1 | 替换弹窗层级：原位高亮 vs 弹窗内复制渲染 | ✅ **弹窗内复制渲染**（Balatro 风，避免 mouse_filter 穿透） |
| Q2 | 生命周期归属：shop_handler 自管 vs ui_manager 托管 | ✅ **ui_manager 临时管理**（与 CardDetailPopup 同模式，RefCounted 不能 add_child） |
| A1 | `await` 期间二次购买重入 | ✅ `_replace_guard` 解决 |
| A2 | 替换期间其他操作锁定 | ✅ 4 个入口点检查 `_replace_guard` |
| A3 | 半价退款最小值 | ✅ `max(1, ceil(cost × 0.5))` |
