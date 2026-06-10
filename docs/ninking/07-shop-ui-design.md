# NinKing 商店 UI 设计方案 v4

> 参考：Balatro 小丑牌商店界面 | 适配：NinKing 扑克牌型计分闯关
> **风格权威：**[`16-art-direction-principles.md`](16-art-direction-principles.md)
> **审定：** 2026-06-10 Grill 27 轮 + review-plan 审阅通过
> Figma 设计稿：`docs/ninking/figma-shop-v2.png` (待更新至漫画风)

---

## 一、设计目标

基于少年漫画风重构商店视觉语言：

- **冲击帧标题** — "商 店"标题栏+「萬屋！」拟声词印章 + 分区标题带常驻集中线放射，如漫画冲击帧
- **卡片即主角** — 商品以大尺寸卡片展示，含艺术插画区、名称牌、效果描述。卡片安静读取，购买按钮轻击
- **亮色漫画风** — 属性 `panel` 底色 + 粗黑描边 `#1A1A1A` + accent 色点缀（替代暗底+金色系）。面板色通过 `BarrierTheme.get_colors()` 运行时动态切换
- **视觉层级** — 标题栏重炸 → 分区标题轻炸 → 卡片安静 → 底栏重炸。对称冲击结构
- **圆角卡框 + 仿手绘描边 + 柔和投影 + 稀有度色彩区分**
- **适配项目配色**：动态 8 属性亮色板（`BarrierTheme` §2.2） / `#1A1A1A` 墨色描边 / accent 动态色

---

## 二、整体布局 (1920×1080)

```
┌──────────────────────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │ 65% 黑遮罩
│  ┌────────────────────────────────────────────────────┐ │
│  │  ╲  ╱  商  店  【萬屋！】   💰15  [入替$5] 替！  │ │ 标题栏 90px
│  │   ╲╱        重炸冲击帧 (常驻集中线10-12条)         │ │ + 印章
│  ├────────────────────────────────────────────────────┤ │
│  │       ╲  ╱                                        │ │
│  │  ═══【 忍 者 牌 】══════════════════════════       │ │ 轻炸分区标题
│  │      ╱  ╲    常驻集中线4-6条                        │ │
│  │                                                    │ │
│  │  ┌──────┐    ┌──────┐    ┌──────┐                  │ │
│  │  │▓▓▓▓▓▓│    │▓▓▓▓▓▓│    │▓▓▓▓▓▓│  ← 夜叉商店: 3张 │ │
│  │  │▓插画▓│    │▓插画▓│    │▓插画▓│                  │ │
│  │  │▓▓▓▓▓▓│    │▓▓▓▓▓▓│    │▓▓▓▓▓▓│  修羅/明王: 2张  │ │
│  │  │幸运筹码│    │顺子达人│    │皇家礼炮│                  │ │
│  │  │+10筹码 │    │+30/+3 │    │×2.0   │                  │ │
│  │  │  💰3  │    │  💰7  │    │  💰15 │                  │ │
│  │  │[入手] │    │[入手] │    │[入手] │  ← 轻击按钮     │ │
│  │  └──────┘    └──────┘    └──────┘                  │ │
│  │                                                    │ │
│  │       ╲  ╱                                        │ │
│  │  ═══【 道 具 卡 】══════════════════════════       │ │ 轻炸分区标题
│  │      ╱  ╲                                         │ │
│  │                                                    │ │
│  │  ┌─────┐    ┌─────┐    ┌─────┐                     │ │ 260×340
│  │  │▓▓▓▓▓│    │▓▓▓▓▓│    │▓▓▓▓▓│                     │ │ 道具卡片
│  │  │▓图▓▓│    │▓图▓▓│    │▓图▓▓│                     │ │
│  │  │幸运星│    │倍率药│    │暴击骰│                     │ │
│  │  │💰2  │    │💰3  │    │💰8  │                     │ │
│  │  │[入手]│    │[入手]│    │[入手]│                      │ │
│  │  └─────┘    └─────┘    └─────┘                     │ │
│  │                                                    │ │
│  ├────────────────────────────────────────────────────┤ │
│  │  ╲  ╱                  ╲  ╱                       │ │ 重炸底栏
│  │   ╲╱   [ 討伐へ ▶ ]    ╲╱    結界1·修羅·封印300  │ │ 集中线 + 冲击按钮
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 尺寸规格

| 元素 | 尺寸 | 位置 |
|------|------|------|
| 画布 | 1920×1080 | — |
| 遮罩 | 1920×1080 | `#000` 65% |
| 商店面板 | 1520×960 | x:200 y:60, 圆角 8px（漫画非硬角） |
| 标题栏 | 1520×90 | 面板顶部 |
| 标题文字 | "商 店" 52px Bold | 居中 |
| 金币胶囊 | 200×52 | 右上, 圆角 26px |
| Reroll 按钮 | 90×52 | 金币右侧 |
| 能力牌卡片 | 340×470 | 3列, 间距 40px |
| 道具卡片 | 260×340 | 3列, 间距 36px |
| 继续按钮 | 340×56 | 底部居中 |

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
NinKingTween.play_shop_entrance():
  0.00s  遮罩 fade_in 0.4s (慢入)
  0.20s  溜め — 遮罩到位后静默一瞬
  0.40s  面板 slam 从下方 TRANS_BACK 0.5s + whoosh 音效
  0.65s  落地 → hit_stop(0.08s) + shake_node(panel, 6.0, 0.15s)
         + shuriken 粒子临时替代速度线 (V38)
         + impact 音效踩点
  0.75s  溜め — 冲击余韵停顿
  0.90s  标题栏集中线 fade_in 0.3s
  1.00s  忍者分区集中线 fade_in → 道具分区集中线 fade_in (stagger 0.15s)
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

```
点击 🔄$5 →
  - 消耗 5 金币
  - 速度线横扫 0.2s → 所有卡片翻转动画 0.3s
  - 重新随机抽取商品
```

### 5.4 继续闯关

```
面板向下滑出 0.3s → 遮罩淡出 → 进入下一关 LevelIntro
```

---

## 六、Godot 实现规划

### 需要新增/修改的文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `scenes/ninking/shop.tscn` | **重写 ✅** | 漫画风商店场景 — 新增 4 个集中线 TextureRect + 2 个拟声词印章 Label + ImpactButton type_variation + 按钮中二化。删除 4 条装饰分隔线 (集中线天然分隔) |
| `scripts/ninking/ui/shop_ui.gd` | **重写 ✅** | 新增 `_apply_barrier_theme()` 集中配色管理 + `_play_entrance()` 改用 `await NinKingTween.play_shop_entrance()` + `_entrance_active` 守卫 + `_render_*` 调 `card.apply_barrier_theme(barrier_colors)` |
| `scripts/ninking/ui/nin_king_tween.gd` | **新建 ✅** | `class_name NinKingTween` 项目级动画序列层。静态方法 `play_shop_entrance(config)` ~90 行，每个 await 后 `is_instance_valid(panel)` 守卫 |
| `scripts/ninking/shop_manager.gd` | **确认** | reroll/generate_stock/buy 方法已实现，无需修改 |
| `scripts/ninking/game_state.gd` | **确认** | buy_ability/buy_item 方法已实现 |
| `scripts/ninking/ui/shop_ability_card.gd` | **修改 ✅** | 删除硬编码 COLOR_* / 新增 `_card_style` 成员 + `apply_barrier_theme(colors)` 方法 / 稀有判断改为 `cost>=12` 占位 / 按钮"入手""入手済" |
| `scripts/ninking/ui/shop_item_card.gd` | **修改 ✅** | 同上 |
| `assets/themes/manga_theme.tres` | **修改 ✅** | 新增 ImpactButton type_variation (normal/hover/pressed/disabled 四态) |
| `docs/ninking/07-shop-ui-design.md` | **同步 ✅** | v3→v4 — 冲击帧标题 / 视觉层级 / 按钮中二化 / 入场动画 1.6s / 节点结构更新 |

### 场景节点结构

```
Shop (Control) [shop_ui.gd]                          ← theme = manga_theme.tres
├── Overlay (ColorRect, #000 65%)
├── %ShopPanel (Panel, 1520×960, 属性panel色, 圆角8, 3px #1A1A1A仿手绘描边)
│   ├── TitleBar (ColorRect, 属性bg调暗8%)           ← _apply_barrier_theme() 运行时赋值
│   │   └── %TitleFocusLines (TextureRect, 600×120)  ← 重集中线, modulate=accent×0.6
│   ├── ShopTitle (Label, "商 店", 52px, accent色)
│   ├── %ShopSubtitle (Label, "萬屋！", 24px Bold, rotation+5°) ← 拟声词印章 P0
│   ├── GoldPill (Panel, 圆角胶囊, 2px粗黑描边)
│   │   ├── CoinIcon (Label→TextureRect 占位)
│   │   └── %GoldLabel
│   ├── %RerollBtn (Button, "入替", ImpactButton)
│   │   ├── %RerollLabel ("$5")
│   │   └── RerollStamp (Label, "替！", rotation-5°)  ← 小印章
│   ├── %AbilityFocusLines (TextureRect, 500×70)     ← 轻集中线, modulate=accent×0.4
│   ├── AbilityLabel (Label, "忍 者 牌", accent色)
│   ├── %AbilityRow (HBoxContainer, 间距40)
│   │   ├── AbilityCard1..N (N=2 修羅/明王, N=3 夜叉)
│   ├── %ItemFocusLines (TextureRect, 500×70)        ← 轻集中线, modulate=accent×0.4
│   ├── ItemLabel (Label, "道 具 卡", accent色)
│   ├── %ItemRow (HBoxContainer, 间距36)
│   │   ├── ItemCard1..M
│   ├── BottomBar (ColorRect, 属性bg调暗8%)
│   │   └── %BottomFocusLines (TextureRect, 600×120) ← 重集中线, modulate=accent×0.6
│   ├── Separator (ColorRect, 1px, accent×0.25)
│   ├── %ContinueBtn (Button, "討伐へ ▶", ImpactButton)
│   ├── %NextLevelHint (Label)
│   └── %NinjaSlotLabel (Label, "忍者 X/5")
```

> **3/2 商店变体（来自 `shop_manager.gd`）：** 修羅/明王商店 = 2 能力 + 1 附魔 + 1 星图。夜叉商店（Boss 后）= 3 能力 + 2 附魔 + 2 星图 + 50% 概率 1 禁術。`AbilityRow` 和 `ItemRow` 动态生成卡片数量，不硬编码 3 列。

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
