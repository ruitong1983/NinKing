# Card-Framework 使用指南

> `addons/card-framework/` — Godot 4.6+ MIT 开源2D卡牌框架 v1.4.0
> 源码仓库：https://github.com/chun92/card-framework

## 架构总览

```
场景树层次（自上而下）：
  Scene
  ├── CardManager          ← 必须第一个节点（或注册 scene root meta）
  │   ├── CardFactory      ← 卡牌创建统一入口
  │   ├── Hand             ← 扇形手牌容器（玩家手牌区）
  │   ├── Pile             ← 堆叠容器（牌库/弃牌堆）
  │   └── ...其他容器
  └── UI（独立于CardManager的商店/菜单等）
```

**继承链：**
```
Control
  └─ DraggableObject  →  状态机驱动拖拽 (IDLE ↔ HOVERING ↔ HOLDING → MOVING)
       └─ Card        →  + 正反面纹理 + 容器集成 + 全局悬停互斥
            └─ NinKingCard (项目扩展) → + PlayingCardData + click-vs-drag 检测 + swap/discard 视觉状态

Control
  └─ CardContainer    →  抽象容器基类 (add/remove/move/undo/shuffle/drop-zone)
       ├─ Hand        →  + 扇形弧线布局 (曲线可控弧度/起伏)
       └─ Pile        →  + 四方向堆叠 + 堆叠深度限制

Node
  └─ CardFactory      →  抽象工厂
       └─ JsonCardFactory → + JSON 驱动 + 素材预加载
       └─ NinKingCardFactory (项目扩展) → ⚠️ 当前占位空壳
```

---

## 核心组件

### DraggableObject — 拖拽状态机基类

```
IDLE ──(mouse_enter)──→ HOVERING ──(press)──→ HOLDING
  ↑                        ↑        ↑             │
  └──(mouse_exit)──────────┘        └──(press)────┘  (release)
         ←─────────────────────────────────────────────┘
  MOVING ← 任何状态 (程序调用 move())
     │
     └──(动画完成)──→ IDLE
```

**关键属性：**

| 属性 | 默认值 | 说明 |
|---|---|---|
| `can_be_interacted_with` | `true` | 是否可交互 |
| `hover_distance` | `10` | 悬停上浮距离 (px) |
| `hover_scale` | `1.1` | 悬停缩放倍数 |
| `hover_rotation` | `0.0` | 悬停旋转角度 (度) |
| `hover_duration` | `0.10` | 悬停动画时长 (秒) |
| `moving_speed` | `2000` | 移动速度 (px/s) |
| `stored_z_index` | — | Z 层基准值，拖拽时 +1000 |

**关键方法：**

- `move(target_destination: Vector2, degree: float)` — 带动画移动到目标位置
- `return_to_original()` — 弹回原位
- `change_state(new_state: DraggableState)` — 手动切换状态
- `_can_start_hovering()` — 覆写以控制悬停条件

---

### Card — 卡牌节点

继承 `DraggableObject`，增加：

- **正反面**：`show_front` / `front_image` / `back_image` / `set_faces(front, back)`
- **容器归属**：`card_container: CardContainer`（框架自动管理）
- **全局互斥**：`hovering_card_count` / `holding_card_count` — 全局同时只能悬停/拖拽一张牌
- **容器回调**：按下时通知 `container.on_card_pressed()`，移动完成通知 `container.on_card_move_done()`
- **return_card()**：不同于 `return_to_original()`，会先问容器要当前位置再弹回

**关键方法：**

| 方法 | 说明 |
|---|---|
| `set_faces(front, back)` | 设置正反面纹理 |
| `return_card()` | 弹回容器指定位置（优先容器坐标，兜底原始坐标） |
| `get_string()` | 返回 `card_name`，用于调试 |
| `_update_card_size(size)` | 调整尺寸 + 自动更新 pivot_offset |

---

### CardContainer — 抽象容器基类

所有卡牌容器的基类，定义标准接口。

**关键属性：**

| 属性 | 说明 |
|---|---|
| `_held_cards: Array[Card]` | 持有的卡牌列表 |
| `cards_node: Control` | 子节点容器 (`$Cards`)，mouse_filter=PASS |
| `drop_zone: DropZone` | 拖放检测区（自动创建） |
| `enable_drop_zone` | 是否启用拖放接收 |

**关键方法：**

| 方法 | 说明 |
|---|---|
| `add_card(card, index)` | 添加卡牌到容器 |
| `remove_card(card)` | 移除卡牌 |
| `move_cards(cards, index, with_history)` | 移动卡牌（支持 undo） |
| `undo(cards, from_indices)` | 撤销移动 |
| `shuffle()` | Fisher-Yates 洗牌 |
| `clear_cards()` | 清空所有卡牌 |
| `get_card_count()` | 卡牌数量 |
| `update_card_ui()` | 刷新全部视觉（顺序→Z→位置→状态） |

**三个虚拟方法必须覆写**（自定义容器时）：

| 方法 | 职责 |
|---|---|
| `_card_can_be_added(cards)` → bool | 校验能否加入 |
| `_update_target_positions()` | 计算每张牌的 position+rotation（**不含** show_front/can_be_interacted_with） |
| `_update_card_states()` | 设置每张牌的 show_front、can_be_interacted_with |

⚠️ **重要分离**：`_update_target_positions` 只做布局计算，`_update_card_states` 只做显示/交互状态。框架的 deferred reapply 路径只调前者，确保外部游戏逻辑对卡牌状态的控制不被覆盖。

---

### Hand — 扇形手牌

**布局模型**：所有牌均匀分布在 `(max_hand_spread + card_w)` 宽的布局盒内居中排列，`hand_anchor` 只控制盒子相对 `global_position` 的对齐方式。

**关键属性：**

| 属性 | 默认值 | 说明 |
|---|---|---|
| `max_hand_size` | `10` | 最大手牌数 |
| `max_hand_spread` | `700` | 扇形展开范围 (px) |
| `card_face_up` | `true` | 是否正面朝上 |
| `card_hover_distance` | `30` | 卡牌悬停上浮距离 |
| `hand_rotation_curve` | — | Curve 资源：X轴→旋转角度 (度) |
| `hand_vertical_curve` | — | Curve 资源：X轴→垂直偏移 (px) |
| `hand_anchor` | `CENTER` | 布局盒锚点：CENTER / LEFT / RIGHT |
| `swap_only_on_reorder` | `false` | true=交换两张牌; false=移位插入 |
| `align_drop_zone_size_with_current_hand_size` | `true` | 拖放区随手牌动态缩放 |

**常用方法：**

| 方法 | 说明 |
|---|---|
| `get_random_cards(n)` | 随机取 n 张牌 |
| `swap_card(card, index)` | 交换两张牌的位置 |
| `get_target_pose_for(card)` → `{position, rotation}` | 查询卡牌当前应处位置 |

---

### Pile — 堆叠容器

**关键属性：**

| 属性 | 默认值 | 说明 |
|---|---|---|
| `layout` | `UP` | 堆叠方向：UP/DOWN/LEFT/RIGHT |
| `stack_display_gap` | `8` | 卡牌间距 (px) |
| `max_stack_display` | `6` | 可见堆叠深度（超出隐藏） |
| `card_face_up` | `true` | 正面/背面 |
| `allow_card_movement` | `true` | 允许拖走卡牌 |
| `restrict_to_top_card` | `true` | 仅顶牌可拖（需要 allow_card_movement=true） |
| `align_drop_zone_with_top_card` | `true` | 拖放区跟随顶牌位置 |

**常用方法：**

| 方法 | 说明 |
|---|---|
| `get_top_cards(n)` | 获取顶部 n 张牌（不移除） |

---

### CardManager — 中央调度器

**关键属性：**

| 属性 | 说明 |
|---|---|
| `card_size` | 统一卡牌尺寸（传递给 Factory） |
| `card_factory_scene` | 工厂场景引用 |
| `debug_mode` | 开/关调试边框 |

**关键方法：**

| 方法 | 说明 |
|---|---|
| `undo()` | 撤销最后一次移动 |
| `reset_history()` | 清空历史 |

**容器发现机制**（双策略）：
1. 优先：`scene_root.get_meta("card_manager")` — 最灵活，容器和 Manager 不必父子关系
2. 兜底：向上遍历父节点查找 `CardManager` 类型

---

### CardFactory / JsonCardFactory — 卡牌工厂

`JsonCardFactory` 目录结构要求：
```
res://
├── card_assets/          ← card_asset_dir
│   ├── ace_spades.png
│   └── ...
├── card_data/            ← card_info_dir
│   ├── ace_spades.json
│   └── ...
```

JSON 格式：
```json
{
  "name": "ace_spades",
  "front_image": "ace_spades.png",
  "suit": "spades",
  "value": "ace"
}
```

---

### DropZone — 拖放检测区

| 方法 | 说明 |
|---|---|
| `init(parent, accept_types)` | 初始化，accept_types 如 `["card"]` |
| `set_sensor(size, position, texture, visible)` | 设置检测区 |
| `set_sensor_size_flexibly(size, pos)` | 临时调整（可恢复） |
| `change_sensor_position_with_offset(offset)` | 偏移传感器位置 |
| `set_vertical_partitions(positions)` | 设置垂直分区线（用于插入位置判定） |
| `get_vertical_layers()` | 返回鼠标所在分区索引 |
| `check_mouse_is_in_drop_zone()` | 鼠标是否在检测区内 |

---

## 项目扩展类

### NinKingCard

```gdscript
class_name NinKingCard
extends Card

signal ninking_card_clicked(index: int)

enum VisualState { NORMAL, SWAP_SOURCE, DISCARD_TARGET }

var playing_card_data: CardData.PlayingCard
var card_index: int = -1
```

**扩展功能**：
- 程序化生成卡牌正面纹理（米色底+深色边框）
- 自动创建 Label 显示 suit+rank（红色/黑色）
- click-vs-drag 检测（移动距离 < 10px 判定为点击）
- `set_visual_state()` — NORMAL/SWAP_SOURCE(蓝)/DISCARD_TARGET(红)
- `update_display()` — 刷新标签文字

### NinKingCardFactory

⚠️ 当前为占位空壳：
```gdscript
func create_card(_card_name, _target) -> Card:
    return null  # 卡牌由 UIManager 直接实例化
```

---

## ⚠️ 已知陷阱 — Z-Index 穿透 Overlay

### 症状

全屏半透明遮罩（ScoringOverlay / DeckViewer 等）出现后，手牌卡牌仍然浮在遮罩上方，只遮暗了第一张。

### 根因

`Hand._update_target_z_index()` 会给每张牌设 `z_index = 0, 1, 2, ...`（保证右侧牌叠在左侧上方）。

Godot 4 中 `z_as_relative = true`（默认），有效渲染层 = **根节点到当前节点的 z_index 累加值**。整个场景树按此值排序渲染：

```
Card[0]: 有效 z = 0  →  与 overlay 同层  →  树顺序靠前  →  遮暗 ✓
Card[1]: 有效 z = 1  →  > overlay(z=0)   →  渲染在 overlay 上方  →  未遮暗 ✗
Card[2]: 有效 z = 2  →  > overlay(z=0)   →  渲染在 overlay 上方  →  未遮暗 ✗
```

即使 overlay 是 `GameLayout` 的后续兄弟节点（正常应在上面），只要卡牌的累加 z_index 大于 overlay，就会穿透。

### 修复

所有与 `GameLayout` 同级、需要在手牌上方的 overlay 节点，必须显式设 `z_index` 大于手牌最大 z_index：

```gdscript
# 手牌 z_index 范围: 0 ~ (max_hand_size - 1)，本项目 max_hand_size=3 → max=2
# overlay z_index 至少设为 10（留余量）
ScoringOverlay.z_index = 10
DeckViewer.z_index = 10
```

> **原则：任何覆盖游戏画面的 overlay/panel，只要和 Hand 容器处于同一场景树且需要叠在手牌上方，就必须设 z_index > max_hand_size。**

### 为什么不用负值

给卡牌设负 z_index（如 `stored_z_index = i - hand_size`）也能解决，但会让卡牌渲染到 Dun 面板背景下方，得不偿失。给 overlay 加 z_index 是副作用最小的方案。

---

## 使用规则

1. **手牌卡牌** → 必须继承 `NinKingCard`，场景用 `Hand` 容器
2. **牌库/弃牌堆** → 用 `Pile`，不可手写堆叠
3. **拖放交互** → 走 `DraggableObject` 状态机，禁止手写 `_input`/`_process` 拖拽
4. **卡牌创建** → 走 `NinKingCardFactory` 统一入口
5. **商店卡牌/能力卡**（无拖拽需求）→ 用 `Panel`/`Button`，不继承 `Card`
6. **新增容器** → 继承 `CardContainer`，覆写三个虚方法
7. **场景结构** → `CardManager` 必须在容器层之上
8. **Overlay z_index** → 全屏遮罩必须设 `z_index > max_hand_size`，防止卡牌 z_index 穿透

---

## 配置常量

全部定义在 `CardFrameworkSettings` (`addons/card-framework/card_framework_settings.gd`)：

| 常量 | 值 | 说明 |
|---|---|---|
| `ANIMATION_MOVE_SPEED` | `2000.0` | 卡牌移动速度 (px/s) |
| `ANIMATION_HOVER_DURATION` | `0.10` | 悬停动画时长 (秒) |
| `ANIMATION_HOVER_SCALE` | `1.1` | 悬停缩放倍数 |
| `ANIMATION_HOVER_ROTATION` | `0.0` | 悬停旋转角度 (度) |
| `PHYSICS_HOVER_DISTANCE` | `10.0` | 全局悬停检测距离 |
| `PHYSICS_CARD_HOVER_DISTANCE` | `30.0` | 卡牌悬停上浮距离 |
| `VISUAL_DRAG_Z_OFFSET` | `1000` | 拖拽时 Z-index 偏移 |
| `VISUAL_PILE_Z_INDEX` | `3000` | 牌堆 Z-index 基准 |
| `LAYOUT_DEFAULT_CARD_SIZE` | `Vector2(150, 210)` | 默认卡牌尺寸 |
| `LAYOUT_STACK_GAP` | `8` | 堆叠间距 |
| `LAYOUT_MAX_STACK_DISPLAY` | `6` | 堆叠可见深度 |
| `LAYOUT_MAX_HAND_SIZE` | `10` | 手牌上限 |
| `LAYOUT_MAX_HAND_SPREAD` | `700` | 手牌扇形展开范围 |
| `DEBUG_OUTLINE_COLOR` | `Color(1,0,0,1)` | 调试边框色 |
| `DEBUG_PREVIEW_COLOR` | `Color(0.2,0.6,1.0,0.3)` | 编辑器预览色 |
