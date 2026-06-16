# Ninja Bar → Card-Framework 迁移规格

> **日期:** 2026-06-12 | **来源:** 拖拽 bug 排查定位 | **状态:** ⬜ 待实施

---

## 1. 问题诊断

### 1.1 Bug 根因

通过运行时日志定位，问题出在两处：

| # | Bug | 根因 | 证据 |
|---|-----|------|------|
| 1 | 拖拽预览显示纹理原始尺寸 (1792×2560) | `TextureRect.EXPAND_KEEP_SIZE` 导致 Godot 用纹理原始尺寸覆盖手动设置的 size | `[NinjaBar] 创建预览 纹理原始尺寸=(1792.0, 2560.0) 指定size=120x160 expand_mode=KEEP_SIZE` |
| 2 | 拖拽落点检测始终返回 null | `_find_slot_at()` 使用 `get_global_rect().has_point()` 在 HBoxContainer 动态布局子节点上检测失败 | `[NinjaBar] _end_drag screen_pos=(1052.0, 133.0) target_index=-1`（鼠标在 slot 上但未命中） |

### 1.2 为什么不修 bug 而做迁移

- 当前手工拖拽系统（`_tracking` / `_is_dragging` / `_drag_preview` / `_find_slot_at`）约 110 行，完全重复了 card-framework 已有能力
- card-framework 的 `DraggableObject` 状态机 + `DropZone` 分区检测已在手牌区经过实战验证
- 修 bug 约 5 行，但技术债不减；迁移约 185 行新代码 + 删 300 行旧代码，净减 ~115 行

---

## 2. 架构设计

### 2.1 新旧对比

```
旧：
%NinjaBar (HBoxContainer)
  ├── NinjaSlotNode ×N (Panel, _draw() 渲染, 手工 _on_gui_input 检测拖拽)
  └── NinjaBarNode (Node, _input() 全局跟踪, 手工 TextureRect 预览, _find_slot_at 落点)

新：
%NinjaBar (Control)
  ├── NinjaBarContainer (CardContainer, 复用 DropZone + move_cards + undo)
  │   └── Cards (Control, 框架自动)
  │       └── NinjaInventoryCard ×N (Card, 复用 DraggableObject 状态机 + return_card)
  └── NinjaBarNode (Node, 只做生命周期管理: refresh / stagger / detail_popup)
```

### 2.2 Card-Framework 复用层

```
DraggableObject  状态机: IDLE→HOVERING→HOLDING→MOVING
                 ↑
Card             set_faces / front_face_texture / return_card / card_container 引用
                 ↑
NinjaInventoryCard   (本项目新建)

CardContainer    add_card / remove_card / move_cards / update_card_ui / undo 历史
  ├── DropZone   set_vertical_partitions / get_vertical_layers / check_mouse_is_in_drop_zone
  └── Cards      子节点容器 (mouse_filter=PASS)
                 ↑
NinjaBarContainer   (本项目新建)

CardManager      全局 holding_card_count 互斥 / scene_root meta / 容器发现
```

### 2.3 数据流

```
┌─────────────────────────────────────────────────────────────────┐
│ 拖拽流程                                                        │
├─────────────────────────────────────────────────────────────────┤
│ 1. mouse_entered → DraggableObject → HOVERING (scale 1.15)     │
│ 2. mouse_pressed  → DraggableObject → HOLDING                  │
│ 3. mouse_motion   → DraggableObject._process() 跟随鼠标         │
│ 4. Card.hold_card() → CardManager 记录 holding_card_count++     │
│ 5. 鼠标移动 → DropZone.get_vertical_layers() 实时返回落点索引     │
│ 6. mouse_released → CardManager._on_drag_dropped()              │
│    → NinjaBarContainer.move_cards([card], to_index)             │
│    → GameState.owned_ninjas 持久化 → refresh()                   │
│ 7. Card.return_card() → move() 动画弹回最终位置                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 文件变更详细规格

### 3.1 `ninja_slot.gd` + `ninja_slot.tscn` → 删除

**删除内容：** NinjaSlotNode 类（178 行）
- Panel + _draw() 纹理渲染 → `Card.set_faces()` 替代
- _on_gui_input 手势检测 → `DraggableObject` 状态机替代
- _on_drag_enter/exit/notify_drag_ended → `CardContainer` drop zone 高亮替代

### 3.2 `ninja_inventory_card.gd` → 新建 (~100 行)

```gdscript
class_name NinjaInventoryCard
extends Card

## 信号
signal detail_requested(ninja_data: Dictionary)

## 数据
var ninja_data: Dictionary = {}
var slot_index: int = -1

## 渲染元素
var _rarity_border_style: StyleBoxFlat = null
var _name_label: Label = null

## 常量
const CARD_SIZE: Vector2 = Vector2(130, 170)
const NAME_FONT_SIZE: int = 12
```

**关键方法：**

| 方法 | 职责 | 行数 |
|------|------|------|
| `_ready()` | 调 `_ensure_face_nodes()` → 建 Label → 连接 `gui_input` 右键 | ~15 |
| `_ensure_face_nodes()` | 照搬 `NinKingCard._ensure_face_nodes()` 建 FrontFace/TextureRect/BackFace | ~20 |
| `setup(ninja_name, ninja_data)` | 加载纹理 → `set_faces(tex, null)` → 设边框 → 设标签 | ~25 |
| `_apply_rarity_border(rarity)` | 动态 `add_theme_stylebox_override("panel", style)` 设 border_color/width/shadow | ~20 |
| `_on_gui_input(event)` | 右键 → `detail_requested.emit(ninja_data)` | ~5 |
| `_on_mouse_entered/exited` | 覆盖继承行为，用 `GlobalTweens.card_hover/unhover` | ~10 |

**渲染说明：**
- 纹理用 `front_face_texture.texture`，`expand_mode = EXPAND_IGNORE_SIZE`，`stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`
- 稀有度边框用 `add_theme_stylebox_override("panel", ...)` 直接设到 Card 节点上
- 名字 Label 作为 Card 的直接子节点，anchor bottom-center
- BackFace 隐藏（`back_face_texture.visible = false`）

**与 Card 框架交互：**
- `can_be_interacted_with = true`（默认）
- 悬停效果由 `DraggableObject` 状态机控制（`hover_scale = 1.15`, `hover_distance = 6`）
- 拖拽期间 `holding_card_count` 全局互斥自动生效

### 3.3 `ninja_bar_container.gd` → 新建 (~60 行)

```gdscript
class_name NinjaBarContainer
extends CardContainer

## 水平线性布局容器 — 无曲线、无旋转
## DropZone 垂直分区：每张卡中心一条线，get_vertical_layers() 返回插入索引

signal reorder_requested(from_index: int, to_index: int)

const SLOT_WIDTH: float = 130.0
const SPACING_MIN: int = 8
const SPACING_MAX: int = 24
```

**覆写的虚方法：**

| 方法 | 职责 | 行数 |
|------|------|------|
| `_card_can_be_added(cards)` | 始终返回 `true` | ~2 |
| `_update_target_positions()` | 等间距直线排列 + 设置垂直分区 | ~30 |
| `_update_card_states()` | 全部 `show_front=true`, `can_be_interacted_with=true` | ~8 |
| `on_card_move_done(card)` | 获取 `get_partition_index()` → emit `reorder_requested` | ~10 |

**布局算法（`_update_target_positions`）：**

```
输入: _held_cards, container_size.x
计算:
  count = _held_cards.size()
  if count == 0: return

  total_w = count * SLOT_WIDTH + (count - 1) * sep
  sep = clamp((container_w - count * SLOT_WIDTH) / (count - 1), SPACING_MIN, SPACING_MAX)
  start_x = (container_w - total_w) / 2.0

  partitions = []
  for i in range(count):
      card_center_x = start_x + i * (SLOT_WIDTH + sep) + SLOT_WIDTH / 2.0
      global_x = global_position.x + card_center_x
      target_pos = Vector2(global_position.x + start_x + i * (SLOT_WIDTH + sep), global_position.y)
      _held_cards[i].move(target_pos, 0)
      partitions.append(global_x)

  drop_zone.set_vertical_partitions(partitions)
```

**DropZone 分区线含义：**
- 每张卡中心 x 坐标 = 一条分区线
- `get_vertical_layers()` 返回鼠标穿过了几条线 = 插入到此索引之后
- 例：2 张卡，线在 x=500, x=654。鼠标在 x=520 → layers=1 → 插入到 index=1（卡1之后）
- 如果鼠标在 x=400（所有线左侧）→ layers=0 → 插入到 index=0（最前）

### 3.4 `ninja_bar_node.gd` → 修改

**删除（~110 行）：**

| 删除区域 | 行数 | 原因 |
|----------|------|------|
| `var _drag_*` 状态变量 (4 个) | ~4 | 框架接管 |
| `func _input(event)` | ~20 | 框架接管 |
| `func _on_slot_drag_started()` | ~20 | 框架接管 |
| `func _update_drag()` | ~25 | 框架接管 |
| `func _end_drag()` | ~20 | 框架接管 |
| `func _cancel_drag()` | ~12 | 框架接管 |
| `func _find_slot_at()` | ~5 | 框架接管 |

**保留（不变）：**
- `refresh()` — diff 比对 + 增删卡牌
- `_animate_out()` — fade+shrink queue_free
- `_make_slot()` — 改为创建 `NinjaInventoryCard` 并用 `_container.add_card()`
- `_apply_stagger_pop_in()` — stagger 弹入动画
- `_apply_spacing()` — 交给容器的 `_update_target_positions()`，此方法删除
- `_on_slot_clicked()` → `_on_detail_requested()` — 右键详情弹窗
- `move_ninja()` / `_on_reorder_requested()` — GameState 持久化

**新增/修改（~25 行）：**

| 变更 | 说明 |
|------|------|
| `var _container` 类型 | `HBoxContainer` → `NinjaBarContainer` |
| `_on_reorder_requested(from, to)` | 连接容器的 `reorder_requested` 信号 |
| `_make_slot()` | `NINJA_SLOT_SCENE.instantiate()` → `NinjaInventoryCard.new()` + `_container.add_card(card, index)` |
| 删除 `slot.drag_started` 信号连接 | Card 不再 emit 此信号 |
| 删除 `slot.notify_drag_ended()` 调用 | 框架管理拖拽生命周期 |

**`_make_slot()` 新实现：**
```gdscript
func _make_slot(ninja_data: Dictionary, index: int = -1) -> NinjaInventoryCard:
    var card := NinjaInventoryCard.new()
    # Card.size 在 _ready 中设为 CARD_SIZE
    card.setup(ninja_data["name"], ninja_data)
    card.slot_index = index
    card.detail_requested.connect(_on_detail_requested)
    _container.add_card(card, index)
    card.scale = Vector2(0.1, 0.1)  # 为 stagger pop-in 准备
    return card
```

### 3.5 `ninking_main.tscn` → 修改

**变更点：** `%NinjaBar` 节点

| 属性 | 旧值 | 新值 |
|------|------|------|
| type | `HBoxContainer` | `Control` |
| script | — | `NinjaBarContainer` (或通过实例化) |

Wait — `%NinjaBar` 是 `unique_name_in_owner` 节点，其 `type` 需要改为 `Control`。但 CardContainer 是自定义类，在 .tscn 中需要 `script = ExtResource(...)` 或实例化子场景。

**实施方案：**
- `%NinjaBar` 保持为 `Control`（unique_name 不变）
- `ui_manager.gd` 在 `_ready` 中创建 `NinjaBarContainer` 实例并 add_child 到 `%NinjaBar`
- `NinjaBarNode` 同样动态创建并 add_child

这与当前 `ui_manager.gd:174-175` 的初始化模式一致：
```gdscript
# 当前
ninja_bar = load("res://scripts/ninking/ui/ninja_bar_node.gd").new()
ninja_bar_container.add_child(ninja_bar)

# 新
var bar_container := NinjaBarContainer.new()
ninja_bar_container.add_child(bar_container)
bar_container.reorder_requested.connect(ninja_bar._on_reorder_requested)

ninja_bar = NinjaBarNode.new()  # 或 load .gd
ninja_bar_container.add_child(ninja_bar)
ninja_bar._container = bar_container
```

### 3.6 `ui_manager.gd` → 修改

| 行 | 旧 | 新 |
|----|-----|-----|
| L75 | `@onready var ninja_bar_container: HBoxContainer = %NinjaBar` | `@onready var ninja_bar_wrapper: Control = %NinjaBar` |
| L126 | `var ninja_bar` | `var ninja_bar: NinjaBarNode` |
| L174-175 | `ninja_bar = load("...").new(); ninja_bar_container.add_child(ninja_bar)` | 创建 NinjaBarContainer + NinjaBarNode，连线信号 |

### 3.7 `debug_controller.gd` → 修改

```gdscript
# L40 旧
@onready var ninja_bar_container: HBoxContainer = %NinjaBar

# L40 新
@onready var ninja_bar_wrapper: Control = %NinjaBar
```

---

## 4. 行为兼容性检查

| 现有行为 | 迁移后 | 状态 |
|----------|--------|------|
| 鼠标悬停放大 (scale 1.15) | `DraggableObject.hover_scale = 1.15` | 兼容 ✓ |
| 拖拽半透明预览 | `Card` 拖拽时 modulate 由框架控制 | 行为略变 — 框架用 z_index+1000 而非手动 TextureRect |
| 右键查看详情 | `NinjaInventoryCard.detail_requested` 信号 | 兼容 ✓ |
| stagger pop-in | `NinjaBarNode._apply_stagger_pop_in()` 不变 | 兼容 ✓ |
| fade-out 移除 | `NinjaBarNode._animate_out()` 不变 | 兼容 ✓ |
| 重排持久化到 GameState | `move_ninja()` 不变 | 兼容 ✓ |
| ESC 取消拖拽 | DraggableObject + `_cancel_drag` 略改 | 需验证 |
| 与其他 UI 的 z_index 穿透 | Card 拖拽时 z_index+1000，Overlay 需设 z_index>1000 | 需检查现有 overlay z_index 值 |

---

## 5. 实现步骤

| 步骤 | 内容 | 验证 |
|------|------|------|
| **S1** | 新建 `ninja_inventory_card.gd` — 继承 Card，setup + 纹理 + 边框 + 标签 | `print` 日志确认 _ready 调用链 |
| **S2** | 新建 `ninja_bar_container.gd` — 继承 CardContainer，水平布局 + 分区 | 单元：`add_card` 后打印位置 |
| **S3** | 修改 `ninja_bar_node.gd` — 删除拖拽代码，改用 CardContainer API | diff 确认变更范围 |
| **S4** | 修改 `ninking_main.tscn` — `%NinjaBar` 类型调整 | 场景加载不报错 |
| **S5** | 修改 `ui_manager.gd` — 初始化容器 + 连线 | `print` 确认容器创建 |
| **S6** | 修改 `debug_controller.gd` — 类型标注更新 | 编译通过 |
| **S7** | 游戏测试 — 悬停 / 拖拽重排 / 右键详情 / ESC 取消 | 用 godot-mcp 测试 |
| **S8** | 删除 `ninja_slot.gd` + `ninja_slot.tscn` | grep 确认无残留引用 |
| **S9** | 同步 `docs/ninking/03-technical-design.md` + `TODO.md` | 文档更新 |

---

## 6. 风险与缓解

| 风险 | 概率 | 缓解 |
|------|------|------|
| Card._ready() 依赖 CardManager 发现失败 | 低 | 场景根 meta `card_manager` 已由 CardManager._ready() 设置（ninking_main.tscn 第 157 行） |
| NinjaBarContainer 和 Hand 共享 CardManager 互斥冲突 | 低 | CardManager 用 group 发现所有容器，按场景树遍历，多容器天然支持 |
| stagger pop-in 用 `card.scale = 0.1` 与 DraggableObject 缓存值冲突 | 中 | 在 `add_card` 之后、`_apply_stagger_pop_in` 之前设 scale；框架只在 IDLE 状态缓存原始值，此时卡尚未交互 |
| z_index 穿透到 ShopOverlay / ScoringOverlay | 中 | 现有 overlay 已设 `z_index=10`，Card 拖拽时 `z_index=stored_z_index+1000`。需确认 overlay z_index > 1000 |
