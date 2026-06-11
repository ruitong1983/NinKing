# NinKing 商店 UI 设计方案 v5

> 参考：Balatro 小丑牌商店界面 | 适配：NinKing 扑克牌型计分闯关
> **风格权威：**[`16-art-direction-principles.md`](16-art-direction-principles.md)
> **审定：** 2026-06-10 Grill 27 轮 + review-plan 审阅通过 / 2026-06-11 Phase D 左右分栏重设
> Figma 设计稿：`docs/ninking/figma-shop-v2.png` (待更新至漫画风)

---

## 一、设计目标

基于少年漫画风重构商店视觉语言：

- **极简左右分栏** — 左 60% 忍者牌 2×2 网格，右 40% 道具卡竖排 2 张，固定 4+2
- **去装饰化** — 移除集中线 / 分区标题 / 分隔线 / 忍者槽计数 / 独立 reroll 费用标签，纯留白区分
- **卡片即主角** — 商品以大尺寸卡片展示，含艺术插画区、名称牌、效果描述。卡片安静读取，购买按钮轻击
- **弱化动态主题** — 属性 `panel` / `bg` / `accent` 三色切换，砍掉边框层次
- **减淡遮罩** — 45% 黑，隐约透出背景场景
- **对称顶底栏** — 全宽 60px，顶栏 "萬屋！" 56px 左 + 金币/入替右，底栏 "討伐へ ▶" 居中
- **圆角卡框 + 仿手绘描边 + 柔和投影 + 稀有度色彩区分**
- **适配项目配色**：动态 8 属性亮色板（`BarrierTheme` §2.2） / `#1A1A1A` 墨色描边 / accent 动态色

---

## 二、整体布局 (1920×1080) — Phase D 左右分栏

```
┌──────────────────────────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ 45% 黑遮罩
│  ┌─────────────────────────────────────────────────────────┐│
│  │ 萬屋！                         💰15          [入替 $3] ││ 顶栏 60px
│  ├────────────────────────────┬────────────────────────────┤│
│  │                            │                            ││
│  │  ┌──────┐    ┌──────┐     │       ┌─────────┐         ││
│  │  │▓▓▓▓▓▓│    │▓▓▓▓▓▓│     │       │▓▓▓▓▓▓▓▓▓│         ││
│  │  │▓插画▓│    │▓插画▓│     │       │▓ 图标 ▓│         ││
│  │  │▓▓▓▓▓▓│    │▓▓▓▓▓▓│     │       │▓▓▓▓▓▓▓▓▓│         ││
│  │  │幸运筹码│    │顺子达人│     │       │ 幸运星  │         ││
│  │  │+10筹码 │    │+30/+3 │     │       │ +25筹码 │         ││
│  │  │  💰3  │    │  💰7  │     │       │  💰2   │         ││
│  │  │[入手] │    │[入手] │     │       │[入手]  │         ││
│  │  └──────┘    └──────┘     │       └─────────┘         ││
│  │                            │                            ││
│  │  ┌──────┐    ┌──────┐     │       ┌─────────┐         ││
│  │  │▓▓▓▓▓▓│    │▓▓▓▓▓▓│     │       │▓▓▓▓▓▓▓▓▓│         ││
│  │  │▓插画▓│    │▓插画▓│     │       │▓ 图标 ▓│         ││
│  │  │▓▓▓▓▓▓│    │▓▓▓▓▓▓│     │       │▓▓▓▓▓▓▓▓▓│         ││
│  │  │皇家礼炮│    │倍率狂人│     │       │ 倍率药  │         ││
│  │  │×2.0   │    │×1.5   │     │       │ ×1.5   │         ││
│  │  │  💰15 │    │  💰5  │     │       │  💰3   │         ││
│  │  │[入手] │    │[入手] │     │       │[入手]  │         ││
│  │  └──────┘    └──────┘     │       └─────────┘         ││
│  │                            │                            ││
│  │      左 60% (忍者牌 2×2)   │     右 40% (道具卡 2张)    ││
│  ├────────────────────────────┴────────────────────────────┤│
│  │                   [ 討伐へ ▶ ]                         ││ 底栏 60px
│  └─────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

### 尺寸规格

| 元素 | 尺寸 | 位置 |
|------|------|------|
| 画布 | 1920×1080 | — |
| 遮罩 | 1920×1080 | `#000` 45% |
| 商店面板 | 1520×960 | x:200 y:60, 圆角 8px |
| 顶栏 | 1520×60 | 面板顶部, bg 暗 8% |
| 顶栏标题 | "萬屋！" 56px | 左对齐, 与金币/入替基线对齐 |
| 金币胶囊 | 190×50 | 右上 x:1130, y:5 |
| Reroll 按钮 | 156×50 | 金币右侧 x:1340, 费用嵌按钮内 "入替 $3" |
| 底栏 | 1520×60 | 面板底部 y:900, bg 暗 8% |
| 能力牌卡片 | 280×400 | 左区 (60%), GridContainer 2列, 列间距 40px, 行间距 0 |
| 道具卡片 | 260×340 | 右区 (40%), VBoxContainer 1列居中, 间距 36px |
| 继续按钮 | 340×56 | 底栏居中 |

---

## 三、配色方案

> 全局风格规范见 [`16-art-direction-principles.md`](16-art-direction-principles.md) §2（色彩体系）+ §3（UI 组件规范）。
> 以下为商店场景专用配色。

### 面板层级

| 层级 | 色值 | 说明 |
|------|------|------|
| 遮罩 | `#000000` 70% | 聚焦商店内容 |
| 面板背景 | 当前属性 `panel` 色 + 5-8% 半调网点 | 动态跟随当前 Ante 属性 |
| 面板边框 | `#1A1A1A` 3px 仿手绘描边 | 漫画墨色 |
| 标题栏底 | 当前属性 `bg` 色调暗 8% | 与面板形成层次 |
| 底栏 | 同标题栏 | — |

### 卡片配色 (漫画风)

| 部位 | 能力牌 | 道具卡 |
|------|--------|--------|
| 卡底 | 属性 `panel` 色 + 网点 | 属性 `panel` 色 |
| 卡框 | `#8B5CF6` 2-3px 粗描边 (紫) | `#4080D0` 2-3px 粗描边 (蓝) |
| 稀有卡框 | `#E04040` 3px 粗描边 (红) | — |
| 投影 | `#00000020` offset 4px | `#00000018` offset 3px |
| 艺术区底 | `#1D1B2E` (紫向暗底) | `#1B232E` (蓝向暗底) |
| 艺术内框 | `#252236` + `#3D3570` | `#212B38` + `#2A4060` |
| 名称牌 | 属性 `panel` 色调暗 5% | 同左 |
| 价格徽章 | 属性 `panel` 色 + `#1A1A1A` 粗描边 | 同左 |

### 文字配色

| 用途 | 色值 | 字号/字重 |
|------|------|-----------|
| 商店标题 | 属性 `accent` 色 | 52px Black |
| 卡片名称 | `#1A1A1A` | 22px Bold / 18px Bold |
| 效果描述 | `#4A4A4A` | 16px / 14px Regular |
| 条件说明 | `#7A7A7A` | 13px / 12px Regular |
| 乘数效果 | `#E04040` | 16px Bold |
| 价格数字 | `#F0D060` | 20px Bold |
| 购买按钮 | `#FFFFFF` (accent 底上的白字) | 16px Bold |
| 继续按钮 | `#FFFFFF` (accent 底白字) | 24px Bold |
| 分区标题 | 属性 `accent` 色 | 36px Black + 2px outline |
| 拟声词印章 | 属性 `accent` 色 | 24px Bold + rotation ±5° |

### 按钮中二化命名 (v4)

| 旧名 | 新名 | 说明 |
|------|------|------|
| 刷新 | **入替** | 换一批商品 |
| 购买 | **入手** | 获得宝物感 |
| 已购买 | **入手済** | 完成态 |
| 继续闯关 | **討伐へ ▶** | 和牌桌「討伐」按钮呼应 |
| — | **萬屋！** | 标题栏拟声词印章 (P0 Label) |
| — | **替！** | 刷新按钮旁小印章 (P0 Label) |
| 稀有标签 | `#FFFFFF` | 12px Bold |

### 按钮配色 (漫画三态)

| 状态 | 背景 | 文字 | 边框 |
|------|------|------|------|
| 购买 (可买) | 属性 `accent` 色 | `#FFFFFF` | `#1A1A1A` 2px |
| 购买 (hover) | accent 调亮 10% | `#FFFFFF` | `#1A1A1A` 3px |
| 购买 (已购) | `#CCCCCC` | `#999999` | `#999999` 2px |
| 继续闯关 | 属性 `accent` 色 | `#FFFFFF` | `#1A1A1A` 2px |
| Reroll | 属性 `panel` 色 | `#1A1A1A` | `#1A1A1A` 2px |

---

## 四、卡片组件结构

### 能力牌卡片 (340×470)

```
┌──────────────────────┐
│ ░░░ 艺术插画区 ░░░░░░ │ ← 340×280 渐变背景
│ ░ [内框]  🍀/🔄/👑 ░ │   内框 308×248, 带描边
│ ░░░░░░░░░░░░░░░░░░░░ │
├──────────────────────┤
│ 幸运筹码              │ ← 名称牌 340×44 (属性 panel 色调暗 5%)
├──────────────────────┤
│ +10 筹码              │ ← 效果 16px
│ 无条件触发            │ ← 条件 13px
│           [💰 3]     │ ← 价格徽章 (右下)
│    [ 购买 ]          │ ← 购买按钮 (中下)
└──────────────────────┘
   粗描边 + 投影
```

**稀有卡额外元素**：
- 艺术区右上角 "稀有" 红色标签
- 加粗红色描边 (3px)
- 更大投影 (blur 32)

### 道具卡片 (260×340)

```
┌───────────────────┐
│ ░ 图标区 ░░░░░░░░ │ ← 260×160
│ ░ [内框] ⭐/🧪/🎲 │   内框 232×132
│ ░░░░░░░░░░░░░░░░░ │
├───────────────────┤
│ 幸运星             │ ← 名称牌 260×36
├───────────────────┤
│ +25 筹码           │ ← 效果 14px
│ 本回合筹码+25      │ ← 描述 12px
│        [💰 2]     │ ← 价格徽章
│   [ 购买 ]        │ ← 购买按钮
└───────────────────┘
   粗描边 + 投影
```

---

## 五、交互流程

### 5.1 进入商店 (v4: 电影感漫画冲击节奏 ~1.6s)

```
NinKingTween.play_shop_entrance() (Phase D: 无集中线, 简化版):
  0.00s  遮罩 fade_in 0.4s (慢入)
  0.20s  溜め — 遮罩到位后静默一瞬
  0.40s  面板 slam 从下方 TRANS_BACK 0.5s + whoosh 音效
  0.65s  落地 → hit_stop(0.08s) + shake_node(panel, 6.0, 0.15s)
         + shuriken 粒子临时替代速度线
         + impact 音效踩点
  0.75s  溜め — 冲击余韵停顿
  1.10s  卡片 stagger_slide_in 开始 (每张 0.1s, 间隔 30px)
  1.60s  全部到位
```

> **实现：** `NinKingTween.play_shop_entrance()` 静态方法（`scripts/ninking/ui/nin_king_tween.gd`），
> 内部委托 GlobalTweens/TweenFX。每个 await 后 guarded by `is_instance_valid(panel)` 防场景切换崩溃。
> shop_ui.gd `_play_entrance()` await NinKingTween 调用，`_entrance_active` 守卫防重入。

> **Tween 实现说明：** 面板 `slide_in` 无现成方向化 API，方案建议抽象为 `TweenFX.slide_in(node, direction, distance, duration)` 静态方法（~15 行），商店/Boss入场/过关转场复用。P0 阶段可临时手写 `create_tween()` 过渡，P1 替换为基建调用。

### 5.2 购买

```
点击 [购买] →
  ✓ 成功: 金币递减动画 + 卡片 scale_pop 金色闪烁 + 按钮变灰 "已购买"
       + [P2] 拟声词弹出（「買った！」）
  ✗ 金币不足: 按钮红色闪烁 + GlobalTweens.toast("金币不足!", 1.5)
  ✗ 槽位已满: GlobalTweens.toast("能力牌槽位已满 (5/5)!", 1.5)
  ⚠ 稀有卡 (rarity == "rare" 或 "legendary"): 红色粗描边(3px) + 右上角"稀有"标签 + 更大投影(blur 32)
     由 `ninja_data.gd` 的 `rarity` 字段驱动，不再用 `cost >= 12` 推断
```

### 5.3 Reroll (刷新商店)

**B4 (2026-06-11):** 递进式费用，参考 Balatro 设计。

| 次数 | 1 | 2 | 3 | 4 | 5+ |
|------|---|---|---|---|----|
| 费用 | $3 | $4 | $5 | $6 | +$1/次 |

每次商店刷新后重置计次。

```
点击 🔄$N →
  - 检查 gold ≥ cost（由 shop_handler._get_reroll_cost() 计算）
  - 消耗 `3 + _reroll_count` 金币，_reroll_count++
  - 通知 shop_ui.update_reroll_cost(new_cost) 刷新按钮价格显示
  - 金币不足时 Toast("需要 $N 才能刷新!")
  - 速度线横扫 0.2s → 所有卡片翻转动画 0.3s
  - 重新随机抽取商品
```

### 5.4 继续闯关 (Phase C: 同场景收缩离场)

```
点击"討伐へ ▶" →
  ── Phase C 同场景流程 ──
  1. 商店卡片 gather 回中心（反向 stagger，0.3s）
  2. ShopPanel slide_out 向下（0.3s） + 内部 Overlay fade_out
  3. 结界名浮水印 0.5s

  如果下一封印有 Boss:
  4. → PLAYING 站稳 → 0.3s 延迟 → Boss立绘punch_in + 浮水1.5s

  如果无 Boss:
  4. → PLAYING

  注: 不涉及场景切换。shop_panel 实例在过渡完成后 queue_free()。
  ShopOverlay 容器节点保留 (visible=false)，下次实例化新 shop_panel。
```

---

## 六、Godot 实现规划

> **Phase C 同场景化更新 (2026-06-11):** 商店从独立场景 `shop.tscn` 改为场景片段 `shop_panel.tscn`，通过 `UIManager` 下的 `ShopOverlay` 在 `ninking_main.tscn` 内动态实例化。详见 `TODO.md` §Phase C。

### 需要新增/修改的文件

| 文件 | 操作 | 说明 |
|------|------|------|
| ~~`scenes/ninking/shop.tscn`~~ | **⛔ 已删除** | 已由 `shop_panel.tscn` 替代 (Phase C, 2026-06-11) |
| `scenes/ninking/shop_panel.tscn` | **新建** | 从旧 `shop.tscn` 提取的商店面板场景片段，根节点为 `Panel`/`Control`。由 `UIManager/ShopOverlay` 动态 `add_child(load(...).instantiate())` |
| `scripts/ninking/ui/shop_ui.gd` | **重写** | 从独立场景控制器改为 ShopPanel 组件脚本。接受 init data + 信号上报（`purchase_requested` / `reroll_requested` / `continue_requested`），不直接读 `NinKingGameState` |
| `scripts/ninking/ui/nin_king_tween.gd` | **扩展** | 已实现 `play_shop_entrance()`。Phase C 新增 `play_shop_exit()` / `play_reroll_vfx()` / `play_ninja_pop_in()` |
| `scripts/ninking/ui/ui_manager.gd` | **修改** | 新增 `%ShopOverlay` 引用、`show_view("shop")`、`show_shop()` / `hide_shop()` |
| `scripts/ninking/ui/game_manager.gd` | **修改** | `_on_state_changed` 加 SHOP 分支；`_on_go_shop_pressed` 从 change_scene 改为同场景过渡；`_intro_timer` 2s→0.5s；Boss 揭示移至 PLAYING 中 |
| `scripts/ninking/shop_manager.gd` | **修改 (Phase D)** | 固定 4+2 库存，assert 兜底，移除修罗/夜叉数量差异 |
| `scripts/ninking/game_state.gd` | **确认** | `SHOP` 状态已存在枚举；`go_to_shop()`/`continue_from_shop()` 已为直接状态切换，无需修改 |
| `scripts/ninking/ui/shop_ability_card.gd` | **✅ 已完成** | 删除硬编码 COLOR_* / 新增 `_card_style` 成员 + `apply_barrier_theme(colors)` 方法 / 按钮"入手""入手済" |
| `scripts/ninking/ui/shop_item_card.gd` | **✅ 已完成** | 同上 |
| `assets/themes/manga_theme.tres` | **✅ 已完成** | 新增 ImpactButton type_variation |
| `scenes/ninking/ninking_main.tscn` | **修改** | UIManager 下新增 ShopOverlay (Control) 节点子树，包含 Overlay (ColorRect) + ShopPanel 运行实例化入口 |
| `docs/ninking/07-shop-ui-design.md` | **同步** | 本文档 — v4→同场景版，节点结构/路径更新 |

### 场景节点结构

> **v2026-06-11 (Phase C):** 商店改为场景片段，由 `ninking_main.tscn` 的 `UIManager/ShopOverlay` 在运行时实例化。
> `shop_panel.tscn` 的根节点为 `Control`，不依赖 CanvasLayer（继承自 UIManager 层级）。

**shop_panel.tscn 内部节点（Phase D — 2026-06-12 左右分栏极简化）：**

```
ShopPanel (Control) [shop_ui.gd]                     ← 根节点, 1520×960
├── Overlay (ColorRect, #000 45%)                    ← 首孩子: 渲染在底层, 做背景暗化
├── TitleBar (ColorRect, 1520×60)                    ← bg 暗 8%
├── ShopSubtitle (Label, "萬屋！", 56px, 左对齐)      ← 与金币/入替基线对齐
├── GoldPill (Panel, 190×50, x:1130 y:5)
│   └── %GoldLabel                                    "$0"
├── %RerollBtn (Button, 156×50, x:1340 y:5)           "入替 $3", ImpactButton
├── %AbilityGrid (GridContainer, 2列, x:156-756 y:80-880)
│   └── [shop_ability_card × 4]                      固定 4 张忍者牌
├── %ItemColumn (VBoxContainer, 1列, x:1086-1346 y:122-838, gap=36)
│   └── [shop_item_card × 2]                         固定 2 张道具卡
├── BottomBar (ColorRect, 1520×60, y:900)             bg 暗 8%
├── %ContinueBtn (Button, "討伐へ ▶", ImpactButton, 居中)
└── %NextLevelHint (Label, 次封印提示)
```

**已移除节点 (Phase D)：** TitleFocusLines, ShopTitle, RerollLabel, AbilityFocusLines, AbilityScrollFrame, AbilityLabel, ItemFocusLines, ItemScrollFrame, ItemLabel, Separator, BottomFocusLines, NinjaSlotLabel

**ShopPanel 在 ninking_main.tscn 中的实例化位置：**

```
UIManager (Node) [ui_manager.gd] — 1920×1080 CanvasLayer
├── LevelIntro       ← 关卡入场水印
├── GameLayout       ← 游戏主界面
├── DeckViewer       ← 牌库查看器
├── ScoringOverlay   ← (未使用，Balatro 风内联计分)
├── LevelComplete    ← 过关弹窗
├── ShopOverlay (Control)  ← **新增** — 商店容器节点, visible=false
│   └── 运行时: add_child(load(shop_panel).instantiate())
├── GameOver         ← 失败
└── VictoryOverlay   ← 通关
```

> **固定库存 (Phase D，来自 `shop_manager.gd`)：** 所有商店固定 4 能力牌 + 2 道具牌。附魔 1 + 星图 1，夜叉商店 50% 概率星图替换为禁術。`AbilityGrid` 2×2 固定，`ItemColumn` 2 张固定。pool 不足时 assert 崩溃。

### 组件场景（已存在，需修改）

| 场景 | 路径 | 改动 |
|------|------|------|
| `shop_ability_card.tscn` | 能力牌卡片组件 | 视觉层：StyleBox改用漫画粗描边+网点底+圆角；图标槽从Label改为TextureRect；稀有标签样式更新 |
| `shop_item_card.tscn` | 道具卡片组件 | 同上 |

### 代码改造要点

| 文件 | 当前状态 | 改造内容 |
|------|---------|---------|
| `shop_ability_card.gd` | 116行，含 setup/set_purchased/purchase 信号 | ① 配色常量改为漫画风（暗紫艺术区底 `#1D1B2E` / 3px 粗描边）② 稀有度判断从 `cost >= 12` 改为 `rarity` 字段 ③ `_get_theme_icon()` 返回图标纹理而非 emoji 文本 |
| `shop_item_card.gd` | 64行，含 setup/set_purchased | 配色改漫画风（蓝向暗底 `#1B232E` / `#4080D0` 描边）；图标纹理化 |
| `shop_ui.gd` | 175行，含完整购买/reroll/入场 | 重写：保留购买/reroll/继续信号链 → 入场动画改用 GlobalTweens 栈（见 §5.1）；Toast 统一用 `GlobalTweens.toast()` |
