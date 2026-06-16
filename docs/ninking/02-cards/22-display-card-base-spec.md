# NinjaCard — 统一忍者卡场景规格

> **实施状态：✅ 已实现 (2026-06-15)**
> **最后更新：2026-06-15 — 统一 `ninja_card.tscn` 替代 `DisplayCardBase` + `NinjaInventoryCard` 双实现**
>
> **2026-06-15 C29 补丁：** 修复忍者栏框不显示 — `setup()`/`setup_shop()` 顶部加 `_ensure_face_nodes()` + `check_and_set_textures()` 在 `_ready()` 之前解析节点引用；`_ensure_face_nodes()` 新增 `frame_overlay` 引用解析；移除 `_ready()` 中覆盖 visible 的行。
>
> 目标：忍者栏和商店使用**同一个场景 `ninja_card.tscn`**，通过 `_shop_mode` 标志切换交互行为。
> 卡面视觉（插画 + 稀有度框叠层 + 悬停发光）统一由 `CardVisualComposer` 管理。

---

## 一、架构

### 统一场景

```
ninja_card.tscn (Control, 125×175)
  script: NinjaInventoryCard (extends Card → DraggableObject → Control)

  ├── FrontFace (Control)            ← 插画层 + Fake3D shader 挂载点
  │   └── TextureRect                ← KEEP_ASPECT_CENTERED
  ├── BackFace (Control)             ← 背面（隐藏）
  │   └── TextureRect                ← visible=false
  ├── FrameOverlay (TextureRect)     ← 稀有度框纹理叠层
  │   PRESET_FULL_RECT, KEEP_ASPECT_COVERED
  └── NameLabel (Label)              ← 卡名（12px, ninja bar 模式显示，shop 模式隐藏）
```

### 双模式概览

| 方面 | Ninja bar 模式 (`_shop_mode=false`) | Shop 模式 (`_shop_mode=true`) |
|------|-------------------------------------|-------------------------------|
| 入口 | `setup(ninja_name, data)` | `setup_shop(data)` |
| 左键 | 进入拖拽 HOLDING 态 | emit `card_clicked`（ShopSlot 监听） |
| 右键 | emit `detail_requested`（NinjaBarNode 弹窗） | 直接打开 `CardDetailPopup` |
| NameLabel | 显示 | 隐藏 |
| 拖拽重排 | ✅ | ❌ |
| Fake3D shader | ✅（插画层挂载） | ✅ |
| CardContainer 集成 | NinjaBarContainer | 无容器，ShopSlot 管理位置 |

---

## 二、节点结构

### ninja_card.tscn (125×175)

```
NinjaCard (Control, 125×175)
  script: NinjaInventoryCard
  custom_minimum_size = 125×175

  FrontFace (Control)
    mouse_filter = IGNORE (2)
    TextureRect (TextureRect)
      expand_mode = EXPAND_IGNORE_SIZE (1)
      stretch_mode = KEEP_ASPECT_CENTERED (4)
      mouse_filter = IGNORE (2)

  BackFace (Control)
    mouse_filter = IGNORE (2)
    TextureRect (TextureRect)
      visible = false
      expand_mode = EXPAND_IGNORE_SIZE (1)
      stretch_mode = KEEP_ASPECT_CENTERED (4)
      mouse_filter = IGNORE (2)

  FrameOverlay (TextureRect)
    visible = false
    anchor_right = 1.0
    anchor_bottom = 1.0
    mouse_filter = IGNORE (2)
    expand_mode = EXPAND_IGNORE_SIZE (1)
    stretch_mode = KEEP_ASPECT_COVERED (5)

  NameLabel (Label)
    position = (0, 177)
    size = (125, 20)
    horizontal_alignment = CENTER (1)
```

**注意：** 场景根节点显式设 `custom_minimum_size = 125×175`，`_ready()` 中进一步设 `size = card_size`，
确保 FrameOverlay 的 PRESET_FULL_RECT 锚点有非零参考尺寸。

### ShopSlot.tscn — 商店容器

参见 [`../04-ui/07-shop-ui-design.md`](../04-ui/07-shop-ui-design.md)。ShopSlot 实例化 `ninja_card.tscn` 作为 `$NinjaCard`，
外加 name_label、effect_label、price_badge、buy_button 等商店特有 UI。

---

## 三、公共 API

### Ninja bar 模式

| 方法 | 说明 |
|------|------|
| `setup(ninja_name: String, data: Dictionary)` | 设置卡名、加载插画+稀有度框、显示 NameLabel |
| `dissolve_out(duration: float = 1.0)` | 溶解消散动画（切换 dissolve2d shader + tween） |

### Shop 模式

| 方法 | 说明 |
|------|------|
| `setup_shop(data: Dictionary)` | 商店模式初始化：存储详情数据、加载稀有度框、隐藏 NameLabel |
| `set_content_texture(texture: Texture2D)` | 设置插画（缩放到 125×175 后 set_faces） |
| `set_frame(rarity: String)` | 加载稀有度框纹理叠层（public wrapper for `_apply_rarity_frame`） |
| `apply_barrier_theme(colors: Dictionary)` | 更新 Panel 背景色（ShopSlot 水墨主题使用） |
| `set_detail_data(n_name, desc, texture, effect)` | 存储详情弹窗数据 |

### 公共属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `ninja_data` | `Dictionary` | 忍者/道具完整数据 |
| `slot_index` | `int` | 忍者栏槽位索引 |
| `frame_overlay` | `TextureRect` | 稀有度框纹理叠层节点 |

### 信号

| 信号 | 说明 | 使用场景 |
|------|------|----------|
| `card_clicked(ninja_data: Dictionary)` | 左键点击（shop 模式） | ShopSlot 监听后触发购买 |
| `detail_requested(ninja_data: Dictionary)` | 右键详情（ninja bar 模式） | NinjaBarNode 监听后弹窗 |

---

## 四、交互行为

| 行为 | Ninja bar 模式 | Shop 模式 |
|------|----------------|-----------|
| 悬停 | scale 1.15 + **框 `self_modulate` 亮至白色** (`CardVisualComposer.apply_hover_glow`) | 同左（**不进入拖拽态**，但悬停动画由 DraggableObject.`_can_start_hovering` 控制） |
| 左键 | 进入 HOLDING → 拖拽重排 | emit `card_clicked`，ShopSlot 的 `buy_button` 处理购买 |
| 右键 | emit `detail_requested` | 直接打开 `CardDetailPopup` |
| ESC | — | 关闭详情弹窗 |

悬停发光统一通过 `CardVisualComposer.apply_hover_glow(frame_overlay, is_hovering)` 实现，
在 `_enter_state()` 的 `HOVERING`/`IDLE` 分支中调用。

---

## 五、稀有度视觉

### 框纹理方案

完整规格见原 §5（不变）：
- 4 套 500×700 PNG：`ninja_frame_{rarity}.png`
- 中心透明（⚠️ V51 永久提醒）
- 加载失败时降级为 `CardVisualComposer.create_rarity_stylebox()`

### StyleBoxFlat 回退

稀有度色值由 `AssetRegistry.RARITY_BORDER_COLORS` 统一管理，
`CardVisualComposer.create_rarity_stylebox(rarity, mode)` 回退构建。

---

## 六、数据流

```
ninja bar 数据流:
  NinjaBarNode._make_slot(data)
    └→ NINJA_CARD_SCENE.instantiate() as NinjaInventoryCard
       ├── setup(ninja_name, data)        ← _ready() 未触发（尚未 add_child）
       │   ├── _ensure_face_nodes()       ← 提前解析节点引用
       │   ├── check_and_set_textures()   ← 提前解析 texture rect
       │   ├── _apply_rarity_frame(rarity)← frame_overlay 已就绪
       │   └── set_faces(tex, null)       ← front_face_texture 已就绪
       └── _container.add_card(card, index)
            └→ _ready() 触发 → 同路径安全重入

shop 数据流:
  ShopSlot.setup(data)  ← _ready() 已触发（父节点已入场景树）
    └→ ninja_card.setup_shop(data)
       ├── _ensure_face_nodes()           ← 重入安全（has_node 守卫）
       ├── _apply_rarity_frame(rarity)
       └── _load_illustration(data)
           └→ ninja_card.set_content_texture(tex)
              ├── check_and_set_textures()
              ├── set_faces(...)
              └── ninja_card.set_detail_data(name, desc, tex, effect)
```

---

## 七、设计原则

1. **统一场景** — `ninja_card.tscn` 同时服务忍者栏和商店，通过 `_shop_mode` 切换
2. **双 API 表面** — ninja bar 用 `setup(name, data)`，shop 用 `setup_shop(data)`，互不干扰
3. **交互模式分离** — 拖拽态仅 ninja bar 启用，shop 模式左键→信号 右键→弹窗
4. **视觉方案统一** — 稀有度框/插画/悬停发光全部委托 `CardVisualComposer`
5. **TextureRect 渲染路径** — 插画通过 `set_faces()` 设置到 FrontFace/TextureRect，保留 Fake3D shader 挂载点
6. **Pixel perfect** — 125×175 对齐标准扑克 5:7 比例
7. **向后兼容** — `_ensure_face_nodes()` 保留 `has_node()` 守卫，`ninja_card.new()` 仍可工作（但建议用场景实例化）
8. **时序安全** — `setup()`/`setup_shop()` 在调用方任意时序下都安全：
   - 顶部调 `_ensure_face_nodes()` + `check_and_set_textures()`，不依赖 `_ready()` 触发
   - `_ready()` 中再次调 `_ensure_face_nodes()` → 重入安全（`has_node()` / `== null` 守卫）
   - `_apply_rarity_frame()` 在设 `frame_overlay` 前不做 `_ready` 假设

---

## 八、相关文件索引

| 文件 | 职责 |
|------|------|
| `scenes/ninking/ninja_card.tscn` | **统一忍者卡场景**（替代旧 display_card_base.tscn） |
| `scripts/ninking/ui/ninja_inventory_card.gd` | NinjaInventoryCard 脚本（双模式，class_name） |
| `scenes/ninking/shop_slot.tscn` | 商店展示容器（实例化 NinjaCard） |
| `scripts/ninking/ui/shop_slot.gd` | ShopSlot 脚本（通过 NinjaCard API 操作） |
| `scripts/ninking/ui/ninja_bar_node.gd` | 忍者栏管理（实例化 NinjaCard） |
| `scripts/ninking/ui/ninja_bar_display.gd` | Debug 忍者栏显示（实例化 NinjaCard） |
| `scripts/ninking/ui/card_detail_popup.gd` | 详情弹窗（通过 `CardVisualComposer.build_card_face()` 渲染） |
| `scripts/ninking/ui/card_visual_composer.gd` | **卡片视觉合成抽象层** |
| `scripts/ninking/asset_registry.gd` | 素材注册表（load_frame_texture / RARITY_BORDER_COLORS） |
| `assets/images/ninjas/frames/ninja_frame_{rarity}.png` | 4 张框纹理素材 (500×700) |
