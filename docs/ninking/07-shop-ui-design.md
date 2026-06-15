# NinKing 商店 UI 设计方案 v7

> 参考：Balatro 小丑牌商店界面 | 适配：NinKing 扑克牌型计分闯关
> **风格权威：**[`16-art-direction-principles.md`](16-art-direction-principles.md) · [`specs/shop-ink-wash-redesign.md`](specs/shop-ink-wash-redesign.md)
> **审定：** 2026-06-13 水墨风改造 — 和纸底 + 印章按钮 + 毛笔字体
> **关联 Figma：** `docs/ninking/figma-shop-v2.png`

---

## 一、设计目标

基于底部舞台式重构商店视觉语言，从「弹窗面板」转型为「漫画下一格」：

- **底部舞台 (y:380 → 1080)** — 全底 1500px 宽，从左栏右缘 (x:420) 延伸至屏幕右缘
- **漫画格质感** — 纸色底 + 属性色极淡染色 + 半调网点叠加，替代纯色面板
- **漫画格分割线** — 顶部 4px `#1A1A1A` 直角粗墨线，非圆角面板边框
- **游戏场景在上方可见** — 左边栏和牌桌保持可见，做购买决策时不丢失上下文
- **卡片 4 列等宽展示** — 4 张忍者牌在上排，2 张星图卡居中在下排
- **入场动画化** — 墨线画出 → 背景刷出 → 卡片 stagger 弹入，模拟翻页感

---

## 二、整体布局 (1500×700) — 全底舞台 · 左边栏可见

```
┌─── 左边栏 420px ──┬──── 中央牌桌 (约 1500-420=1080px) ─────────┐
│                    │  🥷🥷🥷🥷🥷  忍者栏                       │
│  忍気 450          │  [手牌区]                                 │
│  討伐 3            │                                           │
│  $12               │                                           │
│                    │                                           │
├════════════════════╪═══════════════════════════════════════════┤ ← 4px 漫画格分割线
│ ══ 萬屋！══                    $0         [入替 $3]           │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                     │
│  │ 忍者1 │  │ 忍者2 │  │ 忍者3 │  │ 忍者4 │   ← 4 张大卡    │
│  └──────┘  └──────┘  └──────┘  └──────┘                     │
│  ────────────────────────────────────────── 分隔线             │
│       ┌──────┐                      ┌──────┐                 │
│       │ 星図1 │                      │ 星図2 │                 │
│       └──────┘                      └──────┘                 │
│                                    [ 討伐へ ▶ ]              │
└──────────────────────────────────────────────────────────────┘
```

### 尺寸规格 (2026-06-12)

| 元素 | 尺寸 | 位置 |
|------|------|------|
| 画布 | 1920×1080 | — |
| 商店舞台 | **1500×700** | **x:420 y:380** (左边栏右缘起), 无圆角 |
| 舞台顶部分割线 | 1500×4 | 舞台顶部, `#1A1A1A` 墨色直角粗线 |
| 舞台左边框 | 2×700 | 舞台左缘, `#1A1A1A` |
| 舞台右边框 | 2×700 | 舞台右缘 x:1918, `#1A1A1A` |
| 顶栏 | 1500×44 | 舞台顶部, 纸色调暗 5% |
| 顶栏标题 | "萬屋！" 32px | 左对齐 x:24, v_center |
| 金币标签 | Label, 20px | 右上 x:1340, "$0" |
| Reroll 按钮 | 97×28 | 右上 x:1400, "入替 $3" |
| 底栏 | 1500×40 | 舞台底部 y:660, 纸色调暗 5% |
| 忍者牌区 | 1420×390 | GridContainer 4列, x:40-1460 y:58-448, h_sep:20 |
| 星图卡区 | 710×180 | GridContainer 2列, x:375-1085 y:468-648, 居中 |
| 分隔线 | 1420×1 | 忍者区/星图区间 y:458, #000 15% |
| 横排 Slot | 355×190 | 卡画 125×175 左 + 文字区 180×160 右 |
| 继续按钮 | 180×32 | 底栏居中 (x:660) |

### 三层背景材质

| 层 | 类型 | 参数 | 说明 |
|---|------|------|------|
| 纸质基底 | ColorRect | `#F5F0E8` (COLOR_PAPER) | 漫画书页底色 |
| 属性染色 | (合入 StageBg) | BarrierTheme `panel` 色 12% | 运行时由 `_apply_barrier_theme()` 融合 |
| 半调网点 | TextureRect | `screentone.png`, modulate `#00000026` | 增强印刷品质感 |

---

## 三、配色方案 (v7 水墨风)

> **2026-06-13 更新：** 配色由漫画网点+暗底体系 → 日式水墨和纸体系。
> 完整规格见 [`specs/shop-ink-wash-redesign.md`](specs/shop-ink-wash-redesign.md)。

### 舞台层级

| 层级 | 色值 | 说明 |
|------|------|------|
| 舞台底色 | `#F5F0E8` | 和纸白，不再叠加属性色 |
| 半调网点 | **已移除** | 水墨不用网点 |
| 顶部漫画格分割线 | `#6B6B6B` 4px | 淡墨分割线 |
| 顶栏/底栏 | `#E8E0D0` | 纸色暗 |
| 分隔线 | `#6B6B6B` 40% 1px | 淡墨区域分界 |

### 墨色体系

| 常量 | 色值 | 用途 |
|------|------|------|
| 和纸白 | `#F5F0E8` | StageBg / 卡牌底板 |
| 纸色暗 | `#E8E0D0` | TitleBar / BottomBar |
| 焦墨 | `#2B1E10` | 主文字 / 边框 |
| 淡墨 | `#6B6B6B` | 副文字 / 分隔线 |

### 印章色体系（按钮）

| 按钮 | 色值 | 色名 |
|------|------|------|
| 购买按钮 | `#B83A2A` | 朱砂 |
| 刷新按钮 | `#2E5C8A` | 蓝锖 |
| 继续按钮 | `#C4A35A` | 金泥 |

### 卡片配色

| 部位 | 能力牌 | 道具卡 |
|------|--------|--------|
| 卡底 | 和纸白 `#F5F0E8` | 和纸白 `#F5F0E8` |
| 卡框 | 焦墨 `#2B1E10` 2px | 焦墨 `#2B1E10` 2px |
| 稀有卡框 | 蓝锖/朱砂/金泥 2-3px | — |
| 投影 | 柔和 4px `#00000015` | 同左 |

### 文字配色

| 元素 | 颜色 | 字体 |
|------|------|------|
| 标题 "萬屋！" | 焦墨 `#2B1E10` | 站酷妙典体 36px |
| 卡牌名 | 焦墨 `#2B1E10` | 思源黑体 Heavy 16px |
| 卡牌描述 | 淡墨 `#6B6B6B` | 思源黑体 Regular 13px |
| 价格/金币 | 焦墨 `#2B1E10` | 站酷妙典体 |
| 按钮文字 | 白色 | 站酷妙典体 |

---

## 四、卡片组件结构 (不变)

同 v5。ShopSlot (横排 355×190) + NinjaCard (125×175, ninja_card.tscn) 在左，名称/效果/购买按钮在右。

---

## 五、交互流程

### 5.1 进入商店 — 漫画格展开 (~0.95s)

```
NinKingTween.play_shop_entrance_manga() (漫画格展开版):
  0.00s  TopBorder scale_x: 0→1 (0.15s) 墨线画出
         + whoosh 音效 (SB.SHOP_ENTER)
  0.15s  StageBg scale_y: 0→1 (0.2s, from bottom pivot) 背景刷出
         TRANS_BACK, EASE_OUT — 有轻微弹性
  0.35s  TitleBar modulate.a: 0→1 (0.1s)
  0.45s  GlobalTweens.stagger_pop_in(all_cards, 0.06, 0.25)
         each card: scale 0→1.0, BACK EASE_OUT, 0.06s stagger
  ~0.90s impact_sfx 踩点 (SB.BOSS_REVEAL)
  ~0.95s 全部到位
```

每个 `await` 后 `is_instance_valid(panel)` 守卫，防场景切换崩溃。

### 5.2 购买 (不变)

同 v5。

### 5.3 Reroll (不变)

同 v5。

### 5.4 继续闯关 — 反向卷起退场 (~0.55s)

```
点击"討伐へ ▶" →
  1. 卡片 gather + fade: scale→0.1, alpha→0 (0.25s)
  2. 舞台向下滑出 + fade (0.2s, TRANS_QUAD)
  3. ShopOverlay.visible = false, panel.queue_free()
```

---

## 六、Godot 实现规划

### 已变更文件清单 (v6)

| 文件 | 操作 | 说明 |
|------|------|------|
| `scenes/ninking/shop_panel.tscn` | **修改** | 位置 x:420→1920 y:380→1080, StageBg 替代 Overlay, LeftBorder/RightBorder 新增, AbilityGrid 4列, ItemColumn 居中 |
| `scripts/ninking/ui/shop_ui.gd` | **修改** | `_apply_barrier_theme()` 重写为 StageBg 染色逻辑, 删除 overlay/panel_style 引用, 入场调用改为 `play_shop_entrance_manga()` |
| `scripts/ninking/ui/nin_king_tween.gd` | **修改** | 新增 `play_shop_entrance_manga()`, 更新 `play_shop_exit()` 移除 overlay 引用、增加反向卷起动画 |
| `scripts/ninking/ui/ui_manager.gd` | **修改** | `hide_shop()` 删除 `overlay` 参数传递 |
| `scripts/tween/tween_fx.gd` | **新增方法** | `stagger_pop_in(nodes, stagger, duration)` — 卡片逐张 scale 弹入 |
| `scripts/tween/global_tweens.gd` | **新增委托** | `GlobalTweens.stagger_pop_in()` 暴露 |
| `assets/textures/ui/screentone.png` | **新增** | 代码生成 256×256 半调网点, 间距24px 直径10px |

### 已变更文件清单 (v7 水墨风)

> 详见 [`specs/shop-ink-wash-redesign.md`](specs/shop-ink-wash-redesign.md)

| 文件 | 操作 | 说明 |
|------|------|------|
| `assets/fonts/zcool_miaodianti_regular.ttf` | **新增** | 站酷妙典体毛笔行楷 — 标题/按钮/数字用 |
| `scenes/ninking/shop_panel.tscn` | **修改** | 删 ScreentoneOverlay；边框/分隔→淡墨；TitleBar/BottomBar→纸色暗 |
| `scripts/ninking/ui/shop_ui.gd` | **重写** | 水墨色板常量；`_apply_ink_wash_theme()` 替代旧 BarrierTheme 逻辑；印章按钮三态；毛笔字体 override |
| `scripts/ninking/ui/shop_slot.gd` | **重写** | 卡框→纸白+墨线；文字→焦墨/淡墨；购买按钮→朱砂印章；稀有度→水墨色系；`apply_barrier_theme()` 保留为兼容 wrapper |

### 场景节点结构 (v7 — 2026-06-13)

```
ShopPanel (Control) [shop_ui.gd]                 ← 根节点, 1500×700, x:420 y:380
├── StageBg (ColorRect)                           ← 和纸白 #F5F0E8 (全尺寸 fill)
├── TopBorder (ColorRect, 1500×4)                 ← 淡墨分割线 #6B6B6B
├── LeftBorder (ColorRect, 2×700)                 ← 淡墨边框 #6B6B6B
├── RightBorder (ColorRect, 2×700, x:1498)        ← 淡墨边框 #6B6B6B
├── TitleBar (ColorRect, 1500×44)                 ← 纸色暗 #E8E0D0
├── ShopSubtitle (Label, "萬屋！", 36px, x:24)    ← 焦墨毛笔字
├── %GoldLabel (Label, "$0", 20px, x:1340)        ← 焦墨毛笔数字
├── %RerollBtn (Button, x:1400-1497)              ← 蓝锖印章
├── %AbilityGrid (GridContainer, 4列, 1420×390)   ← x:40-1460 y:58-448
│   └── [ShopSlot × 4]                            横排 355×190
├── Separator (ColorRect, 1420×1, y:458)          ← #000 15%
├── %ItemColumn (GridContainer, 2列, x:375-1085)  ← y:468-648, 居中
│   └── [ShopSlot × 2]
├── BottomBar (ColorRect, 1500×40, y:660)         ← 纸色调暗 5%
└── %ContinueBtn (Button, 180×32, x:660, y:664)   "討伐へ ▶"
```
