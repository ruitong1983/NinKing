# NinKing 商店 UI 设计方案 v8

> 参考：Balatro 小丑牌商店界面 | 适配：NinKing 扑克牌型计分闯关
> **风格权威：**[`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) · [`../09-mgmt/specs/kenney-beige-ui-transformation.md`](../09-mgmt/specs/kenney-beige-ui-transformation.md)
> **审定：** 2026-06-22 Kenney 米色改造 — panel_beige 面板 + buttonLong/buttonSquare 按钮
> **关联 Figma：** —

---

## 一、设计目标

统一商店面板至 Kenney 暖纸风（暖纸风），替换旧有水墨风：

- **居中 1000×650 面板** — 于 1920×1080 画布居中 (x:460 y:215)
- **Kenney 纹理面板** — NinePatchRect panel_beige 底 + panel_brown 顶栏，9-slice 拉伸
- **Kenney 纹理按钮** — buttonLong_brown 重感操作 + buttonLong_beige 轻感操作 + buttonSquare_brown 购买
- **无分隔线** — 忍者/道具区通过间距分隔，简洁布局
- **卡片 4+2 布局** — 4 张忍者牌在上 (GridContainer 4列), 2 张星图卡在下 (GridContainer 2列居中)
- **入场动画保留** — 沿用 NinKingTween.play_shop_entrance_manga()，StageBg 从 NinePatchRect 向上刷出

---

## 二、整体布局 (1000×650) — 居中面板

```
        ┌─────────────── TitleBar 1000×44 ───────────────┐
        │  $0                                商店          │
        ├─────────────────────────────────────────────────┤
        │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐      │
        │  │ 忍者1 │  │ 忍者2 │  │ 忍者3 │  │ 忍者4 │    │
        │  │ ¥N   │  │ ¥N   │  │ ¥N   │  │ ¥N   │    │
        │  └──────┘  └──────┘  └──────┘  └──────┘      │
        │                                                 │
        │       ┌──────┐            ┌──────┐            │
        │       │ 星図1 │            │ 星図2 │            │
        │       │ ¥N   │            │ ¥N   │            │
        │       └──────┘            └──────┘            │
        │                                                 │
        │         [ 入替 ¥3 ]      [ 討伐へ ▶ ]          │
        └─────────────────────────────────────────────────┘
```

### 尺寸规格

| 元素 | 类型 | 尺寸/位置 | 说明 |
|------|------|----------|------|
| 画布 | — | 1920×1080 | — |
| ShopPanel | Control | 1000×650, x:460 y:215 | 居中 |
| StageBg | NinePatchRect | 全面板 1000×650 | panel_beige, patch_margin=8 |
| TitleBar | NinePatchRect | 1000×44, y:0 | panel_brown, patch_margin=8/4/8/4 |
| GoldLabel | Label | x:16 y:8, w:134 h:30 | 金色 #FFD700, 22px |
| ShopSubtitle | Label | x:880 y:6, w:104 h:34 | 白色 "商店", 22px, 右对齐 |
| AbilityGrid | GridContainer | x:60 y:76, w:880, 4cols, h_sep:26 | 578px 内容宽, 151px 两侧留白 |
| ItemGrid | GridContainer | x:362 y:317, w:276, 2cols, h_sep:26 | 276px 内容宽, 居中 |
| RerollBtn | Button | x:300 y:558, 190×49 | buttonLong_brown, "入替 ¥3" |
| ContinueBtn | Button | x:510 y:558, 190×49 | buttonLong_beige, "討伐へ ▶" |
| ShopSlot | VBoxContainer | min 125×221 | 卡 (125×175) + separation (6) + 按钮 (125×40) |

---

## 三、配色方案 (v8 Kenney 暖纸风)

### 面板层级

| 层级 | 纹理 | 说明 |
|------|------|------|
| StageBg | `panel_beige.png` | 暖米纸底, NinePatchRect 9-slice |
| TitleBar | `panel_brown.png` | 深暖棕顶栏, NinePatchRect 9-slice |

### 按钮纹理

| 按钮 | 纹理 | 字色 |
|------|------|------|
| 购买按钮 (BuyBtn) | `buttonSquare_brown.png` | 白 |
| 购买按钮 disabled | `buttonSquare_grey.png` | 灰 #808080 |
| 入替按钮 (RerollBtn) | `buttonLong_brown.png` | 白 |
| 继续按钮 (ContinueBtn) | `buttonLong_beige.png` | 深褐 #3D2B1A |

### 卡片样式

| 部位 | 说明 |
|------|------|
| 卡底 | NinjaInventoryCard 纸白 #F5F0E8 + 墨色边框 #2B1E10 |
| 稀有卡框 | 蓝锖/朱砂/金泥 2-3px（不变） |
| 投影 | 柔和 4px |

---

## 四、卡片组件结构

ShopSlot (VBoxContainer, min 125×221, separation=6, alignment=CENTER):

```
ShopSlot (VBoxContainer)
├── NinjaCard (125×175, ninja_card.tscn 实例)
└── BuyBtn (Button, 125×40)
```

- 左键点击卡牌或按钮 → `purchase_requested` 信号
- 右键卡牌 → 详情浮层（NinjaInventoryCard 内置）
- 忍者栏满员时：按钮显示 "満員" + disabled (灰色)

---

## 五、交互流程

### 5.1 进入商店 — 入场动画 (~0.95s)

同 v7，NinKingTween.play_shop_entrance_manga():
- 0.00s TopBorder scale_x: 0→1 (null 跳过)
- 0.15s StageBg scale_y: 0→1 (NinePatchRect, 从底部 pivot 刷出)
- 0.35s TitleBar fade in
- 0.45s Cards stagger_pop_in (0.06s 间隔, 0.25s dur)
- ~0.90s impact_sfx

### 5.2 购买

- 点击购买按钮 / 卡牌本体 → purchase_requested 信号
- 忍者栏满员时：按钮 disabled + 灰色 + 文字 "満員"

### 5.3 Reroll

点击 "入替 ¥3" → reroll_requested 信号 → 旧卡吹飞 → 新卡 stagger_pop_in (NinKingTween.play_reroll_vfx)。使用 `stagger_pop_in`（scale 0→1 弹入）而非 `stagger_slide_in`，避免修改 GridContainer 子节点的 `position` 导致布局冲突。

### 5.4 继续闯关

点击 "討伐へ ▶" → continue_requested 信号 → 退场动画 (NinKingTween.play_shop_exit)

---

## 六、涉及文件

| 文件 | 说明 |
|------|------|
| `scenes/ninking/shop_panel.tscn` | Kenney 米色 1000×650 NinePatchRect 面板 |
| `scenes/ninking/shop_slot.tscn` | VBoxContainer 卡+按钮布局 |
| `scripts/ninking/ui/shop_ui.gd` | 按钮纹理 + 忍者栏满检测 + 渲染逻辑 |
| `scripts/ninking/ui/shop_slot.gd` | 动态按钮状态 (¥N/満員/disabled) + 卡底样式 |
| `scripts/ninking/ui/nin_king_tween.gd` | stage_bg 类型放宽 ColorRect→Control |
| `scripts/ninking/ui/ui_manager.gd` | init() 移除 colors 参数 |

---

## 七、历史版本

| 版本 | 日期 | 变更 |
|------|------|------|
| v5 | 2026-06-11 | 底部舞台式 1500×700, 横排卡+文字 |
| v6 | 2026-06-12 | 漫画格入场动画 |
| v7 | 2026-06-13 | 水墨和纸风 (站酷妙典体 + 印章按钮) |
| **v8** | **2026-06-22** | **Kenney 暖纸风 (panel_beige + buttonLong/buttonSquare 纹理)** |
