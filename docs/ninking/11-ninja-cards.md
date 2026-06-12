# 忍者牌 — 设计与实现

> **最后更新:** 2026-06-12
> **关联文档:** [`05-image-asset-generation-plan.md`](05-image-asset-generation-plan.md) · [`07-shop-ui-design.md`](07-shop-ui-design.md) · [`03-technical-design.md`](03-technical-design.md) · [`12-consumable-cards.md`](12-consumable-cards.md) · [`14-economy-and-progression.md`](14-economy-and-progression.md) · [`22-display-card-base-spec.md`](22-display-card-base-spec.md)
>
> **关键文件:** [`asset_registry.gd`](../../scripts/ninking/asset_registry.gd) · [`ninja_data.gd`](../../scripts/ninking/ninja_data.gd) · [`display_card_base.gd`](../../scripts/ninking/ui/display_card_base.gd) · [`shop_slot.gd`](../../scripts/ninking/ui/shop_slot.gd) · [`shop_slot.tscn`](../../scenes/ninking/shop_slot.tscn)
>
> **⭐ 后续设计方案前必须先读此文档。** 记忆索引: `pending-ninja-card-visual-plan.md`

---

## 目录

1. [概述](#1-概述)
2. [视觉拼装系统](#2-视觉拼装系统)
3. [场景结构](#3-场景结构)
4. [数据流](#4-数据流)
5. [素材清单](#5-素材清单)
6. [稀有度视觉系统](#6-稀有度视觉系统)
7. [当前实现问题](#7-当前实现问题)
8. [后续设计方案待办](#8-后续设计方案待办)
9. [游戏数据 — 45 张忍者牌](#9-游戏数据--45-张忍者牌)
10. [相关文件索引](#10-相关文件索引)

---

## 1. 概述

忍者牌是 NinKing 商店中出售的能力卡牌（对应 Balatro 的小丑牌 Joker），玩家购入后在"讨伐"阶段自动生效，影响计分、经济、手牌等。

**核心设计原则：** 45 张忍者牌不逐张 AI 生成独立插画，而是用"模板拼装"方案——稀有度底板 + 分类图标 + 文字标签，通过 Godot 程序化组合。

---

## 2. 视觉拼装系统

### 2.1 拼装公式

```
忍者牌视觉 = ninja_frame_{rarity}.png   ← 稀有度底板（AI 生成 4 张，❌ 尚未生成）
           + icon_{category}.png        ← 分类图标（AI 生成 14 张，✅ 已存在）
           + name_label                 ← Godot 字体渲染
           + effect_desc                ← Godot 字体渲染
           + condition_desc             ← Godot 字体渲染
           + cost_label                 ← Godot 字体 + 金币图标
           + RarityBadge                ← Godot StyleBox（程序绘制）
```

### 2.2 稀有度底板（4 张 — ❌ 未生成）

| 文件名 | 稀有度 | 边框 | 底板色调 | 关联张数 |
|--------|--------|------|----------|----------|
| `ninja_frame_common.png` | 普通 (N) | 灰色粗描边 | 灰色网点底 | 10 |
| `ninja_frame_uncommon.png` | 稀有 (R) | 蓝色粗描边 + 细银边 | 蓝色网点底 | 18 |
| `ninja_frame_rare.png` | 史诗 (SR) | 紫色粗描边 + 金边 | 紫色网点底 | 14 |
| `ninja_frame_legendary.png` | 传说 (UR) | 红色粗描边 + 粗金边 + 光晕 | 红色网点底 | 3 |

**规格：** 140×196 PNG，透明背景（拼装到底板节点上）。
**AI 提示词模板：** 详见 `05-image-asset-generation-plan.md` §5.2。

### 2.3 分类图标（14 张 — ✅ 已存在）

路径 `assets/images/ninjas/icons/`：

| 文件名 | 内容 | 覆盖忍者牌 |
|--------|------|-----------|
| `icon_coin.png` | 金币 $ | 经济类 (7) |
| `icon_sword.png` | 忍刀 | 组别定向 (5) |
| `icon_mult.png` | "×" 符号 | 倍率加成 (5) |
| `icon_star.png` | 星星/星光 | 喜之强化 + 南斗六星 (10+) |
| `icon_fire.png` | 火焰 | 手替え激励 (6) |
| `icon_card.png` | 扑克牌 | 通用加成 (12+) — 基础 |
| `icon_card_chips.png` | 扑克牌 + 筹码 | 通用加成 — 筹码子类 |
| `icon_card_mult.png` | 扑克牌 + 倍率 | 通用加成 — 倍率子类 |
| `icon_card_both.png` | 扑克牌 + 筹码+倍率 | 通用加成 — 双效子类 |
| `icon_seal.png` | 封印符 | 规则变更 (6) |
| `icon_crown.png` | 王冠 | 传说 (5) |
| `icon_heart.png` | 红心 | 跨组联动（预留） |
| `icon_shield.png` | 盾牌 | 忍具（预留） |
| `icon_scroll.png` | 卷轴 | 成长修炼 |

**规格：** 24×24 PNG，透明背景。在卡面上显示为 64×64。

---

## 3. 场景结构

### 3.1 继承体系

```
Card (card-framework)
  ├── NinKingCard              ← 扑克牌（纹理体系 + 手牌拖拽）
  └── DisplayCardBase          ← ⭐ 非扑克牌统一基类（v2026-06-12）
       ├── ShopAbilityCard     ← 商店忍者卡
       ├── ShopItemCard        ← 商店道具/星图卡
       └── (未来) DeckPreviewCard / CollectionCard
```

所有非扑克牌共享 `DisplayCardBase` 的统一视觉层：外框/阴影/圆角/结界染色/content_slot/name_plate/入场动效/悬停光效(scale 1.03)/右键详情弹窗。
详见规格书 [`22-display-card-base-spec.md`](22-display-card-base-spec.md)。

### 3.2 `ShopAbilityCard` — 场景树（继承自 DisplayCardBase）

```
ShopAbilityCard (Control → DisplayCardBase)    280×400  ← custom_minimum_size
  extends DisplayCardBase → Card → DraggableObject → Control
  
  FrontFace (Control, hidden)                   ← Card 框架要求，不使用
  └── TextureRect (TextureRect, hidden)
  BackFace (Control, hidden)
  └── TextureRect (TextureRect, hidden)
  
  card_panel (Panel)                            ← 铺满整卡
    StyleBoxFlat: 圆角12, 边框2, 阴影8, bg_color 随结界染色
    
    content_slot (Control)                      ← 角色插画区（子类填充）
      anchors: L=0.04, T=0.04, R=0.96, B=0.50
      clip_contents = true
      └── [TextureRect]                         ← _add_content_texture() 统一加载
    
    rarity_badge (Panel)                        ← 稀有度徽章（覆盖在插图右上）
      anchors: L=0.55, T=0.04, R=0.95, B=0.12
      └── RarityLabel (Label)
    
    effect_label (Label)                        ← 效果描述
      anchors: L=0.04, T=0.52, R=0.96, B=0.62
    
    condition_label (Label)                     ← 触发条件
      anchors: L=0.04, T=0.62, R=0.96, B=0.72
    
    name_plate (Panel)                          ← 名称帖
      anchors: L=0.04, T=0.72, R=0.96, B=0.82
      └── name_label (Label)
    
    price_badge (Panel)                         ← 价格标签
      anchors: L=0.04, T=0.84, R=0.42, B=0.95
      └── PriceLabel (Label)
    
    buy_button (Button)                         ← 购买按钮
      anchors: L=0.50, T=0.84, R=0.96, B=0.95
```

### 3.3 `ShopItemCard` — 场景树（继承自 DisplayCardBase）

与 ShopAbilityCard 共享 DisplayCardBase 基类，差异点：
- 无 `rarity_badge` / `condition_label`
- 增加 `desc_label`（道具描述）
- `content_slot` 放星图/道具插画

```
card_panel
  content_slot (anchors B=0.55)                ← 星图/道具插画
  effect_label (T=0.56, B=0.66)                ← 效果文本（星图显示 Lv.N）
  desc_label (T=0.66, B=0.74)                  ← 道具描述
  name_plate (T=0.74, B=0.82)
  price_badge (T=0.84, B=0.95)
  buy_button (T=0.84, B=0.95)
```

### 3.4 场景文件位置

- 基类场景（纯卡面 120×160）：`scenes/ninking/display_card_base.tscn`
- 基类脚本：`scripts/ninking/ui/display_card_base.gd`
- 商店展示容器（Balatro 风）：`scenes/ninking/shop_slot.tscn`（内嵌 DisplayCard + 购买UI）
- 容器脚本：`scripts/ninking/ui/shop_slot.gd`（数据驱动 ability/item）
- 商店批量渲染：`shop_ui.gd._render_abilities()`

---

## 4. 数据流

### 4.1 全链路

```
数据定义层
  ninja_data.gd → NinjaData.ALL_NINJAS      ← 45 张忍者牌数据
       ↓
  NinjaPool / ShopManager.generate_stock()  ← 商店库存生成
       ↓
渲染层
  shop_ui.gd._render_abilities()            ← 遍历库存
       ↓
  ShopSlot.instantiate()                    ← 商店容器实例化
       ↓
  slot.setup(ninja_data)                    ← DisplayCard.setup() + 加载插画 + 设置文本/价格/按钮
       ↓
  slot.apply_barrier_theme(colors)          ← 结界配色 + 稀有度边框/辉光
```

### 4.2 `ShopSlot.setup()` — 实际实现 (Balatro 风)

```gdscript
# shop_slot.gd — 数据驱动 ability/item 统一场景
func setup(data: Dictionary) -> void:
    _data = data
    _is_item = data.has("hand_type") or data.get("type") == "item"

    # 1. Init DisplayCard (纯卡面 120×160)
    display_card.setup(data)

    # 2. 加载插画
    _load_illustration(data)

    # 3. 标签 (卡名/效果/条件 — 在卡下方)
    name_label.text = data.get("name", "???")
    effect_label.text = data.get("desc", "")
    var cond: String = data.get("condition_desc", "")
    condition_label.visible = not cond.is_empty()
    condition_label.text = cond + "触发" if not cond.is_empty() else ""

    # 4. 价格 + 购买按钮
    price_label.text = "$%d" % data.get("cost", 0)
    buy_button.pressed.connect(_on_buy_pressed)

# 稀有度：边框色 + 辉光 (无浮标 badge)
func _apply_rarity_border(rarity: String, colors: Dictionary) -> void:
    match rarity:
        "uncommon":
            display_card.set_card_border(2, colors.accent, 6, ...)
        "rare":
            display_card.set_card_border(3, #E04040, 10, ...)
        "legendary":
            display_card.set_card_border(3, #FFD700, 14, ...)

    # ── 价格 + 按钮 ──
    price_label.text = str(data.get("cost", 0))
    buy_button.pressed.connect(_on_buy_pressed)
```

### 4.3 忍者 ID → 图标路径映射

`asset_registry.gd` 按 `id` 前缀匹配分类：

```gdscript
"n_g": "icon_sword",   # 组别定向
"n_r": "icon_seal",    # 规则变更
"n_x": "icon_star",    # 喜之强化
"n_s": "icon_scroll",  # 成长修炼
"n_e": "icon_coin",    # 经济
"n_t": "icon_shield",  # 忍具
"n_l": "icon_crown",   # 传说
"n_d": "icon_fire",    # 手替え激励
"n_c": "icon_heart",   # 跨组联动
"n_f": "icon_mult",    # 点数/人牌
"n_":  "icon_card",    # 通用加成 (catch-all)
```

通用加成（`n_` + 第 3 位为数字）进一步按 `effect` 字段拆子类：`icon_card_chips`（仅筹码）/ `icon_card_mult`（仅倍率）/ `icon_card_both`（双效）。

参考调用：`AssetRegistry.get_icon_path(ninja_id, effect_dict)`

---

## 5. 素材清单

### 5.1 已有素材（✅ 在磁盘）

| 类别 | 路径 | 数量 |
|------|------|------|
| 分类图标 | `assets/images/ninjas/icons/icon_*.png` | 14 张 |
| `.import` | `assets/images/ninjas/icons/*.png.import` | 14 个 |

### 5.2 缺失素材（❌ 待生成）

| 路径 | 说明 | 优先级 |
|------|------|--------|
| `assets/images/ninjas/frames/ninja_frame_common.png` | 普通底板 | **P0** |
| `assets/images/ninjas/frames/ninja_frame_uncommon.png` | 稀有底板 | **P0** |
| `assets/images/ninjas/frames/ninja_frame_rare.png` | 史诗底板 | **P0** |
| `assets/images/ninjas/frames/ninja_frame_legendary.png` | 传说底板 | **P0** |

`frames/` 目录也不存在，需同时创建。

### 5.3 此前标记 ✅ 但被素材清理回退的 TODO 项

在 2026-06-11 商店素材清理中（所有 TextureRect 贴图 → ColorRect 纯色），以下 TODO 被回退：

| TODO | 描述 | 当前状态 |
|------|------|----------|
| V43 | 商店卡片图标替换 | ❌ ArtIcon 为透明 ColorRect，纹理代码已删除 |
| V45 | 图标差异化 + 子类细分 | ❌ 加载链路已删除 |
| V46 | ArtIcon 归入 ArtArea 居中 | ❌ 结构保留但类型从 TextureRect 改成了 ColorRect |
| V47 | 稀有度视觉系统（Badge） | ✅ Badge 正常工作，底板缺素材 |
| V48 | AssetRegistry 统一注册表 | ✅ 路径映射完整，只缺调用方 |

---

## 6. 稀有度视觉系统

稀有度系统由 `shop_slot.gd`（商店容器）管理，不在 `DisplayCardBase` 基类中。
`shop_slot.gd` 的 `_apply_rarity_border()` 方法控制：

| 稀有度 | 边框宽 | 边框色 | 阴影 | Badge |
|--------|--------|--------|------|-------|
| common | 2px | 墨色 `#1A1A1A` | 4px 黑12% | 隐藏 |
| uncommon | 2px | 随 BarrierTheme accent | 6px 黑15% | 隐藏 |
| rare | 3px | 红色 `#E04040` | 12px 红20% | 🔴 "稀有" 红底白字 |
| legendary | 3px | 金色 `#FFD700` | 16px 金25% | 🟡 "伝説" 金底黑字 |

`apply_barrier_theme(colors)` 运行时对 uncommon 类覆盖边框色为 `colors.accent`，rare/legendary 保留预设。

---

## 7. 当前实现问题

> **v2026-06-12 DisplayCardBase 迁移后：** 旧拼装系统（ArtArea/ArtFrame/ArtIcon/ArtNameLabel/FrameTexture）已完全删除。
> 所有展示卡统一使用 `content_slot` + `_add_content_texture()` 加载插画。以下仅保留未解决的问题。

| # | 问题 | 说明 | 涉及文件 | 影响 |
|---|------|------|----------|------|
| 2 | **缺少底板节点** | 旧拼装系统删除后，稀有度底板(`ninja_frame_*.png`)暂无挂载位置 | 已废弃 (Balatro 边框+辉光替代) | 关闭 |
| 5 | **底板素材缺失** | 4 张 `ninja_frame_*.png` 从未 AI 生成 | — | 需先有素材再设计接入 |
| 8 | **忍者槽位图标正常** | `ninja_slot.tscn` 的 TextureRect + AssetRegistry 调用正确 | `ninja_slot.gd` | 参考实现 ✅ |

### 已关闭的问题（DisplayCardBase 迁移所致）

| # | 问题 | 关闭原因 |
|---|------|----------|
| 1 | ArtIcon 类型错误 | 旧拼装系统删除，`content_slot` 统一加载插画 |
| 3 | 图标加载代码缺失 | 图标在 `_add_content_texture()` 中统一加载 |
| 4 | 底板加载代码缺失 | 待重做，不再依赖旧拼装层 |
| 6 | 临时 ArtNameLabel | 删除 — 不再需要文字替代图标 |
| 7 | 商店道具卡同类问题 | 道具卡同样迁移到 `content_slot` 模式 |

---

## 8. 后续设计方案待办

> **v2026-06-12 DisplayCardBase 迁移后：** 旧 ArtArea 拼装系统已删除。底板需要重新设计挂载方式。

- [ ] **底板素材生成** — AI 生成 4 张 `ninja_frame_*.png`（规格 280×400，透明 PNG，适配 DisplayCardBase 尺寸）
  - 参考 `05-image-asset-generation-plan.md` §5.2 提示词模板
  - 豆包 Seedream 4.0 少年漫画风，粗描边 + 半调网点
- [ ] **底板接入方式设计** — 底板作为 `content_slot` 中 TextureRect 的背景叠层？或在 card_panel 上叠加 overlay？
  - 旧方案（ArtArea 多层拼装）已废弃，需基于 DisplayCardBase 重新设计
  - 加载底板：`frame_texture.texture = load("ninja_frame_%s.png" % rarity)`
- [ ] **低配回退方案** — 底板素材未就绪时卡面至少显示分类图标 + 名称文字
- [ ] **ArtNameLabel 存废** — 图标恢复后是否保留半透明水印文字
- [ ] **道具卡图标同步恢复** — `shop_item_card.tscn` 同理解冻

---

## 9. 游戏数据 — 45 张忍者牌

> 完整效果定义见 [`ninja_data.gd`](../../scripts/ninking/ninja_data.gd)。

### 稀有度分布

| 稀有度 | 数量 | 价格范围 | 商店出现率 |
|--------|------|---------|-----------|
| common | 10 | $3~5 | 高 |
| uncommon | 18 | $4~8 | 中 |
| rare | 14 | $7~14 | 低 |
| legendary | 3 | 不出售 | 仅秘仪/特殊获取 |
| **合计** | **45** (+2 暂缓 = 47 定义) | | |

### 🌿 通用加成 (6) — ID 前缀 `n_`

无条件 +chips/+mult，每次计分自动生效。

| ID | 名称 | 效果 | 价格 | 稀有度 |
|----|------|------|------|--------|
| n_001 | 手里剑 | +10 chips | 3 | common |
| n_002 | 苦无 | +4 mult | 4 | common |
| n_003 | 风魔手里剑 | +15 chips +2 mult | 5 | common |
| n_004 | 重刃 | +20 chips | 4 | common |
| n_005 | 影缝 | +10 mult | 8 | uncommon |
| n_006 | 奥义之卷 | +30 chips +10 mult | 14 | rare |

### 📐 组别定向 (6) — ID 前缀 `n_g`

条件触发，鼓励特定三组排列策略。触发条件在 `score_calculator.gd._ninja_condition_met()` 中评估。

| ID | 名称 | 效果 | 条件 | 价格 | 稀有度 |
|----|------|------|------|------|--------|
| n_g01 | 虎头 | +5 mult | 影牌型 ≤ 对子 | 5 | uncommon |
| n_g02 | 龙尾 | ×2 | 滅为同花顺或豹子 | 12 | rare |
| n_g03 | 中流砥柱 | +50 chips | 瞬 | 6 | uncommon |
| n_g04 | 藏锋 | ×mult 按影强度 | 散牌×2 / 对子×1.5 / 顺子同花×1.2 / 同花顺豹子×1 | 8 | rare |
| n_g05 | 双头蛇 | +40 chips | 影或瞬为顺子或同花 | 5 | uncommon |
| n_g06 | 金字塔 | ×2 | 头<中<尾牌型严格递升 | 12 | rare |

### 🔗 规则变更 (2) — ID 前缀 `n_r`

改变排列约束或计分规则。**组内互斥**（`mutex_group`）。

| ID | 名称 | 效果 | 价格 | 稀有度 |
|----|------|------|------|--------|
| n_r02 | 均衡之印 | 三组必须相同牌型，各组 ×1.5 | 7 | rare |
| n_r03 | 独尊之印 | 滅 ×2，影和瞬必须 ≥ 对子 | 9 | rare |

> ~~n_r01~~ 自由之印 已删除 — 移除核心 Puzzle 无趣。

### 🎯 喜之强化 (4 + 2 暂缓) — ID 前缀 `n_x`

触发或增强喜（9 种全局模式）。喜系统详见 `06-complete-redesign.md` Part 4。

| ID | 名称 | 效果 | 条件 | 价格 | 稀有度 |
|----|------|------|------|------|--------|
| n_x01 | 喜鹊 | 喜 ×mult +0.3 | 触发任意喜时 | 4 | uncommon |
| n_x02 | 四张猎人 | +30 chips（四张）/ 保底 +5 | 四张触发/否则 | 4 | uncommon |
| n_x03 | 清一色 | ×2 | 三清（替代默认 ×1.3） | 7 | rare |
| n_x04 | 黑龙 | ×1.5 | 全黑触发时 | 8 | 🔒 暂缓 |
| n_x05 | 赤凤 | ×1.5 | 全红触发时 | 8 | 🔒 暂缓 |
| n_x06 | 龙之眼 | 每多一张 ×1.3（上限 2 次） | 四张以上 | 12 | rare |

> n_x04/n_x05 需牌组系统支持，Phase D 实施。

### 📈 成长修炼 (5) — ID 前缀 `n_s`

效果随使用次数/条件累积。由 `NinjaScaling.process_scaling()` 在 `seal_controller.finalize_play()` 中触发。

| ID | 名称 | 效果 | 成长条件 | 重置 | 价格 | 稀有度 |
|----|------|------|---------|------|------|--------|
| n_s01 | 修行者 | +1 mult/次出牌 | on_play | 否 | 6 | uncommon |
| n_s02 | 三清道人 | +25 chips/次 | 打出三清时 | 否 | 7 | uncommon |
| n_s03 | 龙脉 | +30 chips/次 | 滅同花顺时 | 否 | 8 | uncommon |
| n_s05 | 头悬梁 | +3 mult/次 | 影为散牌时 | 影非散牌重置 | 5 | uncommon |
| n_s06 | 尾刺骨 | +5 mult/次 | 滅为豹子或同花顺时 | 滅不满足重置 | 6 | uncommon |

> ~~n_s04~~ 忍法帖 已删除 — on_redraw 触发对应手替え已废弃。

### 💰 经济 (6) — ID 前缀 `n_e`

金币产出 + 钱→数值转化。

| ID | 名称 | 效果 | 价格 | 稀有度 |
|----|------|------|------|--------|
| n_e01 | 福神 | 出牌后每触发一个喜 +$2 | 6 | uncommon |
| n_e02 | 金尾 | 滅有镀金增强牌时 +$3/张 | 5 | uncommon |
| n_e03 | 俭约 | 换牌张数 ≤ 2 时 +$4 | 4 | common |
| n_e04 | 利息之印 | 利息上限 +$5 | 7 | uncommon |
| n_e05 | 金剛力 | 每 $5 持有 +1 倍率（上限 +10） | 8 | rare |
| n_e06 | 黄金律 | 每 $15 持有 ×2（上限 ×3） | 14 | rare |

### 🔧 忍具 (4) — ID 前缀 `n_t`

改变资源/规则的工具类忍者牌。

| ID | 名称 | 效果 | 价格 | 稀有度 |
|----|------|------|------|--------|
| n_t01 | 分身之术 | +1 出牌次数 | 8 | uncommon |
| n_t02 | 替身之术 | +1 换牌次数 | 6 | uncommon |
| n_t05 | 疾风 | 首回合出牌 ×2，之后 ×0.5 | 7 | uncommon |
| n_t06 | 烟幕 | 过关失败保留金币回到 Ante 开头（一局 1 次） | 10 | rare |

> ~~n_t03~~ 千里眼 / ~~n_t04~~ 镜像之术 已删除 — 占槽位价值低 + 实现复杂度高。

### ⭐ 传说 (3) — ID 前缀 `n_l`

改变游戏方式的超级稀有牌。**不在商店出售**，仅通过秘仪卡或特殊事件获取。

| ID | 名称 | 效果 | 稀有度 |
|----|------|------|--------|
| n_l01 | 天下人 | 排列约束完全移除 + 三组各 ×1.5 | legendary |
| n_l02 | 幻术大师 | 50% 手牌视为万能花色，出牌时 1/10 概率销毁 1 张 | legendary |
| n_l03 | 影武者 | 每次出牌随机 1 组获得 ×3 | legendary |

### 🆕 换牌激励 (2) — ID 前缀 `n_d`

| ID | 名称 | 效果 | 价格 | 稀有度 |
|----|------|------|------|--------|
| n_d01 | 忍法·换 | 每次换牌后本 Blind 内 +10 chips（累计不跨 Blind） | 4 | common |
| n_d02 | 赌命 | 换牌上限 +1 张（可换 4 张），但出牌次数 -1 | 7 | uncommon |

### 🆕 跨组联动 (2) — ID 前缀 `n_c`

| ID | 名称 | 效果 | 条件 | 价格 | 稀有度 |
|----|------|------|------|------|--------|
| n_c01 | 镜像 | ×1.5 | 影牌型 = 滅牌型 | 6 | uncommon |
| n_c02 | 铁索连环 | 两组各 +15 chips +3 mult | 三组中有两组牌型相同 | 8 | rare |

### 🆕 点数/人牌 (2) — ID 前缀 `n_f`

| ID | 名称 | 效果 | 价格 | 稀有度 |
|----|------|------|------|--------|
| n_f01 | 影之眷顾 | 手中每张 J/Q/K +3 chips | 5 | common |
| n_f02 | 王牌侍从 | 手中每张 Ace +5 mult（上限 +20 mult） | 8 | rare |

### 商店版本系统 (Editions)

商店忍者牌 **5% 概率**附带版本加成。

| 版本 | 边框 | 效果 | 获取 |
|------|------|------|------|
| 金印 (Foil) | 金边 | +50 chips | 商店 5% |
| 彩印 (Holo) | 彩虹边 | +10 mult | 商店 5% |
| 极印 (Poly) | 闪烁彩边 | ×1.5 mult | 商店 5% |
| 负印 (Negative) | 暗紫边 | +1 忍者牌槽位（不占槽） | 仅秘仪卡 |

---

## 10. 相关文件索引

| 文件 | 说明 |
|------|------|
| `scripts/ninking/ninja_data.gd` | 45 张忍者牌数据定义 + ALL_NINJAS 数组 |
| `scripts/ninking/asset_registry.gd` | 图标路径映射（忍者 id→icon.png） |
| `scripts/ninking/ui/shop_slot.gd` | 🆕 商店展示容器（DisplayCard + 购买UI，数据驱动） |
| `scenes/ninking/shop_slot.tscn` | 🆕 商店展示容器场景 |
| `scripts/ninking/ui/shop_ui.gd` | 商店面板（_render_abilities 批量生成忍者牌） |
| `scripts/ninking/ui/ninja_slot.gd` | ✅ 忍者槽位（图标加载逻辑正确，可作参考实现） |
| `scripts/ninking/ui/ninja_bar_node.gd` | ✅ 忍条管理（diff 刷新/拖拽排序/Balatro zoom-in 详情） |
| `scripts/ninking/ninja_scaling.gd` | 修炼成长引擎（n_s* 忍者效果） |
| `scripts/ninking/score_calculator.gd` | 计分计算（忍者条件/效果评估） |
| `docs/ninking/05-image-asset-generation-plan.md` | 拼装系统原始设计（§5.2 底板/§7.1 拼装） |
| `docs/ninking/07-shop-ui-design.md` | 商店 UI 设计（卡牌布局/图标槽） |
| `docs/ninking/03-technical-design.md` | 技术设计（类图/数据流） |
| `docs/ninking/14-economy-and-progression.md` | 经济与成长系统设计 |
| `assets/images/ninjas/icons/` | 14 个分类图标 PNG |
| `assets/images/ninjas/frames/` | ❌ 目录不存在（4 底板待生成） |
