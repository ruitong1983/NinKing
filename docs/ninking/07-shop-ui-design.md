# NinKing 商店 UI 设计方案 v6

> 参考：Balatro 小丑牌商店界面 | 适配：NinKing 扑克牌型计分闯关
> **风格权威：**[`16-art-direction-principles.md`](16-art-direction-principles.md)
> **审定：** 2026-06-12 底部舞台化重构 — 漫画「下一格」设计
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
| 横排 Slot | 355×190 | 卡画 120×160 左 + 文字区 180×160 右 |
| 继续按钮 | 180×32 | 底栏居中 (x:660) |

### 三层背景材质

| 层 | 类型 | 参数 | 说明 |
|---|------|------|------|
| 纸质基底 | ColorRect | `#F5F0E8` (COLOR_PAPER) | 漫画书页底色 |
| 属性染色 | (合入 StageBg) | BarrierTheme `panel` 色 12% | 运行时由 `_apply_barrier_theme()` 融合 |
| 半调网点 | TextureRect | `screentone.png`, modulate `#00000026` | 增强印刷品质感 |

---

## 三、配色方案

### 舞台层级

| 层级 | 色值 | 说明 |
|------|------|------|
| 舞台底色 | `#F5F0E8` + 属性 `panel` 12% | 纸色为主，属性色极淡染色，运行时由代码计算融合 |
| 半调网点 | `screentone.png` modulate `#00000026` (15%) | 增强漫画印刷品质感 |
| 顶部漫画格分割线 | `#1A1A1A` 4px | 直角粗墨线，不适用圆角规范 |
| 顶栏/底栏 | `#E8E0D0` (纸色调暗 5%) | 不跟随属性色，保持纸质感 |
| 分隔线 | `#000000` 15% 1px | 忍者区和星图区的细分隔 |

### 卡片配色 (不变，同 v5)

| 部位 | 能力牌 | 道具卡 |
|------|--------|--------|
| 卡底 | 属性 `panel` 色 + 网点 | 属性 `panel` 色 |
| 卡框 | `#8B5CF6` 2-3px (紫) | `#4080D0` 2-3px (蓝) |
| 稀有卡框 | `#E04040` 3px (红) | — |
| 投影 | 硬偏移 (3,3), blur 0-2, `#00000040` | 同左 |

### 文字配色 (不变)

同 v5 方案。

---

## 四、卡片组件结构 (不变)

同 v5。ShopSlot (横排 355×190) + DisplayCardBase (120×160) 在左，名称/效果/购买按钮在右。

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

### 场景节点结构 (2026-06-12)

```
ShopPanel (Control) [shop_ui.gd]                 ← 根节点, 1500×700, x:420 y:380
├── StageBg (ColorRect)                           ← 纸色基底 (全尺寸 fill), #F5F0E8
│   └── ScreentoneOverlay (TextureRect)           ← 半调网点纹理, modulate #00000026
├── TopBorder (ColorRect, 1500×4)                 ← 漫画格分割线, #1A1A1A
├── LeftBorder (ColorRect, 2×700)                 ← 左边框, #1A1A1A
├── RightBorder (ColorRect, 2×700, x:1498)        ← 右边框, #1A1A1A
├── TitleBar (ColorRect, 1500×44)                 ← 纸色调暗 5%
├── ShopSubtitle (Label, "萬屋！", 32px, x:24)    ← 左对齐
├── %GoldLabel (Label, "$0", 20px, x:1340)        ← 右上
├── %RerollBtn (Button, x:1400-1497, "入替 $3")   ← 右上
├── %AbilityGrid (GridContainer, 4列, 1420×390)   ← x:40-1460 y:58-448
│   └── [ShopSlot × 4]                            横排 355×190
├── Separator (ColorRect, 1420×1, y:458)          ← #000 15%
├── %ItemColumn (GridContainer, 2列, x:375-1085)  ← y:468-648, 居中
│   └── [ShopSlot × 2]
├── BottomBar (ColorRect, 1500×40, y:660)         ← 纸色调暗 5%
└── %ContinueBtn (Button, 180×32, x:660, y:664)   "討伐へ ▶"
```
