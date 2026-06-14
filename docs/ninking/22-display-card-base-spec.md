# DisplayCardBase — 非扑克牌统一展示卡规格

> **实施状态：✅ 已实现 (2026-06-12)**
> **最后更新：2026-06-12 — Balatro 风大重构：纯卡面 125×175 + ShopSlot 容器**
>
> 目标：游戏内所有非 52 张扑克牌的卡牌（忍者能力、星图、道具、牌组预览等）**卡牌本身视觉统一**。
> 卡上无文字、无按钮 — 纯卡面 + 上下文容器提供额外 UI。

---

## 一、继承体系

```
Control
  └── DraggableObject (card-framework)
       └── Card (card-framework)
            ├── NinKingCard              ← 扑克牌（不动，纹理体系+手牌拖拽）
            └── DisplayCardBase          ← ⭐ 纯卡面基类 125×175
                 └── (无子类 Scene)
                     所有上下文由外部容器提供：
                     ├── ShopSlot        ← 商店：DisplayCard + 购买UI
                     ├── DeckPreviewCard (未来) ← 牌组预览容器
                     └── CollectionCard  (未来) ← 牌库查看器容器
```

- **DisplayCardBase 只有卡面内容**，不持有商店/牌组特有的 UI 节点
- 上下文容器（如 ShopSlot）管理名称/效果文字/价格/按钮

---

## 二、场景结构

### DisplayCardBase.tscn (125×175)

```
DisplayCardBase.tscn (Control, 125×175)
  inherits: Card

  # Card 带来的节点（隐藏不使用）
  FrontFace (TextureRect, visible=false)
  BackFace (TextureRect, visible=false)

  # 统一外框
  card_panel (Panel, 125×175)
    StyleBoxFlat:
      bg_color = #1A1A2E (默认暗底，结界染色覆盖)
      corner_radius_all = 6 (小卡用 6px)
      border_width = 2
      border_color = #1A1A1A (COLOR_INK)
      shadow_size = 6
      shadow_color = black @ 15%

    # 内容插槽 — 填满整卡
    content_slot (Control)
      clip_contents = true
      anchors: L0 T0 R1 B1
      mouse_filter = IGNORE (2)
```

### ShopSlot.tscn (300×370) — 商店容器

```
ShopSlot.tscn (Control, 300×370)
  ├── DisplayCard (实例化)      ← 125×175，居中于上部 (offset: 90, 10)
  ├── name_label (Label)        ← L0.04 T0.52 R0.96 B0.62 — 卡名
  ├── effect_label (Label)      ← L0.04 T0.63 R0.96 B0.74 — 效果文本
  ├── condition_label (Label)   ← L0.04 T0.75 R0.96 B0.83 — 条件文本（ability 专属）
  ├── price_badge (Panel)       ← L0.04 T0.85 R0.27 B0.95 — 价格徽章
  │   └── PriceLabel (Label)
  └── buy_button (Button)       ← L0.58 T0.85 R0.96 B0.95 — "購入"
```

---

## 三、DisplayCardBase 公共 API

| 方法 | 说明 |
|------|------|
| `setup(data: Dictionary)` | 初始化外框样式，存储 `_detail_name` / `_detail_desc` |
| `apply_barrier_theme(colors)` | 结界染色：`bg_color` + `border_color` |
| `set_content_texture(texture: Texture2D)` | 设置插画（供父容器调用） |
| `set_card_border(width, border_color, shadow_size, shadow_color)` | 稀有度边框+辉光 |
| `set_detail_data(name, desc, texture)` | 供父容器设置右键详情弹窗数据 |
| `get_card_id()` → String | 子类覆写，返回唯一 ID |
| `play_entrance(delay)` | 入场动效（scale 0.8→1.0 + fade in） |

### 信号

| 信号 | 说明 |
|------|------|
| `card_clicked(card: DisplayCardBase)` | 左键点击（父容器监听后决定购买/查看/选中） |

---

## 四、交互行为

| 行为 | 效果 |
|------|------|
| 悬停 | scale 1.03 (0.12s, EASE_OUT_CUBIC) |
| 左键 | 发射 `card_clicked` 信号（不入 drag 态） |
| 右键 | 弹出 `CardDetailPopup` 详情浮层（含大图+名称+描述） |

---

## 五、稀有度视觉（在 ShopSlot 中控制）

Balatro 风：稀有度以**卡牌边框颜色 + 辉光**表示，无浮标 badge。

| 稀有度 | 边框宽 | 边框色 | 阴影辉光 |
|--------|:------:|--------|----------|
| Common | 2px | COLOR_INK | 4px black 12% |
| Uncommon | 2px | accent 色 | 6px accent 15% |
| Rare | **3px** | **#E04040** | **10px #E04040 25%** |
| Legendary | **3px** | **#FFD700** | **14px #FFD700 30%** |

---

## 六、数据流

```
ninja_data.gd → NinjaData.ALL_NINJAS
     ↓
shop_ui.gd._render_abilities() → ShopSlot.instantiate()
     ↓
slot.setup(data)
     ├── display_card.setup(data)        ← 基类初始化
     ├── _load_illustration(data)         ← AssetRegistry 路径 → Image.load → resize → set_content_texture
     ├── name_label.text                  ← 卡名（在卡下方）
     ├── effect_label.text                ← 效果
     ├── condition_label.visible/text     ← 条件（ability 专属）
     ├── price_label.text                 ← "$N"
     └── buy_button.pressed.connect       ← 购买
     ↓
slot.apply_barrier_theme(colors)
     ├── display_card.apply_barrier_theme ← 结界底色
     └── _apply_rarity_border(rarity)     ← 边框色+辉光
```

---

## 七、设计原则

1. **卡牌纯面** — 卡上无任何文字/按钮/overlay
2. **上下文容器** — 额外 UI（名称/效果/价格/按钮）由父容器提供
3. **容器数据驱动** — ShopSlot 根据 data 中是否有 `hand_type` 分 ability/item 显示
4. **稀有度 = 边框 + 辉光** — 不额外加文字浮标
5. **像素完美** — DisplayCard 125×175 对齐标准扑克 5:7 比例
6. **容器可换** — 牌组预览、图鉴、收藏用不同容器，DisplayCard 保持不变
