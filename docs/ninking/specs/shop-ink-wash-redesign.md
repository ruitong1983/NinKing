# 商店水墨风改造 — 实现规格

> **日期:** 2026-06-13 | **来源:** grill-me 19 轮决策 | **状态:** 待实施
> **关联:** [`07-shop-ui-design.md`](../07-shop-ui-design.md) · [`16-art-direction-principles.md`](../16-art-direction-principles.md)

---

## 一、设计决策（已确认）

| 决策项 | 结论 |
|--------|------|
| 美术方向 | 日式水墨/浮世绘风（C 选项） |
| 配色策略 | 8 属性 accent 降饱和 20-30% + 灰度混入，模拟矿物颜料和纸发色 |
| 字体体系 | 标题/按钮/数字 → 站酷妙典体（毛笔行楷）；正文 → 思源黑体 Regular |
| 面板造型 | 大面板卷轴 + 小元素墨框 + 按钮印章（C 选项） |
| 背景 | 和纸/麻纸纹理底，米白淡茶区间 |
| 按钮 | 朱砂印章（购买）/ 蓝锖印章（刷新）/ 金泥印章（继续） |
| 粒子 | 墨痕绽放 / 墨迹飞溅 / 枯笔飞白拖尾 / 金泥粉末 |
| 商店入口动画 | **不改**（保留漫画格展开时序） |

### 待定项（本次不改）

描边实现方式 / 牌面 / 牌背 / 过渡动画 / 忍者栏 / ScoreCard / Launcher / 三墩区域 / 拖拽交互 / 卡牌详情弹窗 / ShopSlot / DeckViewer

---

## 二、改动范围

### 只改商店，边界清晰

```
✅ 改: shop_panel.tscn / shop_ui.gd / shop_slot.gd / 字体文件
❌ 不改: manga_theme.tres / BarrierTheme / display_card_base.gd / NinKingTween
         / LeftPanel / NinjaBar / Launcher / HandArea / DunArea / GameOver
```

### 涉及文件（4 个）

| # | 文件 | 改动 |
|---|------|------|
| 1 | `assets/fonts/` | 重命名 `mianfeiziti.com.ttf` → `zcool_miaodianti_regular.ttf` + `.import` |
| 2 | `scenes/ninking/shop_panel.tscn` | 底色→和纸白；边框色→淡墨；取消 ScreentoneOverlay；标题栏/底栏色→纸色暗 |
| 3 | `scripts/ninking/ui/shop_ui.gd` | 新增水墨色板常量；`_apply_barrier_theme()` 重写；字体 override；印章按钮样式 |
| 4 | `scripts/ninking/ui/shop_slot.gd` | `apply_barrier_theme()` 重写：卡框纸白+墨线、文字墨色、购买按钮→朱砂印章 |

---

## 三、水墨色板（独立于 BarrierTheme）

商店内部自维持色板，不从 `barrier_colors` 取色做视觉决策。

### 纸色系

```gdscript
const COLOR_PAPER       := Color(0.961, 0.941, 0.910)  # #F5F0E8  和纸白
const COLOR_PAPER_DARK  := Color(0.910, 0.878, 0.835)  # #E8E0D0  纸色暗（顶栏/底栏）
```

### 墨色系

```gdscript
const COLOR_SUMI        := Color(0.169, 0.118, 0.063)  # #2B1E10  焦墨（主文字/边框）
const COLOR_PALE_INK    := Color(0.420, 0.420, 0.412)  # #6B6B6B  淡墨（副文字/分隔线）
```

### 印章色系

```gdscript
const COLOR_CINNABAR    := Color(0.722, 0.227, 0.165)  # #B83A2A  朱砂（购买按钮）
const COLOR_BLUE_ZAN    := Color(0.180, 0.361, 0.541)  # #2E5C8A  蓝锖（刷新按钮）
const COLOR_GOLD_MUD    := Color(0.769, 0.639, 0.353)  # #C4A35A  金泥（继续按钮）
```

### 8 属性 accent 降饱和对照（供未来 BarrierTheme 改造参考，本次不用）

| 属性 | 旧 accent（漫画） | 新（水墨） |
|------|-----------------|-----------|
| 火 | `#E62E1A` | `#C0392B` 朱砂 |
| 水 | `#1F73E0` | `#2E5C8A` 蓝锖 |
| 風 | `#26B861` | `#4A7C59` 萌葱 |
| 雷 | `#F2B814` | `#C8963A` 山吹 |
| 土 | `#BF661A` | `#8B5E3C` 赭石 |
| 光 | `#E6C726` | `#C4A35A` 金箔淡 |
| 暗 | `#8C38C8` | `#5B3A7A` 紫苑 |
| 无 | `#8C8C94` | `#6B6B6B` 墨色淡 |

---

## 四、舞台配色映射

| 层级 | 旧色 | 新色 | 说明 |
|------|------|------|------|
| StageBg | `barrier.panel.darkened(0.06)` | `COLOR_PAPER` #F5F0E8 | 和纸白底 |
| ScreentoneOverlay | 网点 modulate `#00000026` | **删除节点** | 水墨不用网点 |
| TopBorder | `#1A1A1A` | `COLOR_PALE_INK` #6B6B6B | 淡墨分割线 |
| LeftBorder | `#1A1A1A` | `COLOR_PALE_INK` #6B6B6B | 淡墨边框 |
| RightBorder | `#1A1A1A` | `COLOR_PALE_INK` #6B6B6B | 淡墨边框 |
| TitleBar | `barrier.panel.darkened(0.35)` | `COLOR_PAPER_DARK` #E8E0D0 | 纸色暗顶栏 |
| BottomBar | `barrier.panel.darkened(0.35)` | `COLOR_PAPER_DARK` #E8E0D0 | 纸色暗底栏 |
| Separator | `barrier.accent` 30% | `COLOR_PALE_INK` 40% | 淡墨分隔 |
| ShopSubtitle 文字 | `barrier.accent` | `COLOR_SUMI` #2B1E10 | 焦墨标题 |
| GoldLabel 文字 | `COLOR_GOLD` | `COLOR_SUMI` #2B1E10 | 焦墨数字 |

---

## 五、按钮印章三态

### 购买按钮（每槽 buy_button）— 朱砂印章

```
尺寸: 80×34（保持不变）
字体: 站酷妙典体 14px 白色

normal:  bg = COLOR_CINNABAR  border = COLOR_SUMI 2px  radius = 4
hover:   bg.lightened(0.10)   border = COLOR_SUMI 3px
pressed: bg.darkened(0.15)    content_margin_top += 2, content_margin_bottom -= 2
disabled: bg = COLOR_PALE_INK 50%  border = COLOR_PALE_INK 30%
```

### 刷新按钮（RerollBtn）— 蓝锖印章

```
尺寸: 97×34（保持不变）
字体: 站酷妙典体 14px 白色

normal:  bg = COLOR_BLUE_ZAN  border = COLOR_SUMI 2px  radius = 4
hover:   bg.lightened(0.10)   border = COLOR_SUMI 3px
pressed: bg.darkened(0.15)    content_margin_top += 2
disabled: bg = COLOR_PALE_INK 50%  border = COLOR_PALE_INK 30%
```

### 继续按钮（ContinueBtn）— 金泥印章

```
尺寸: 180×32（保持不变）
字体: 站酷妙典体 18px 白色（比购买/刷新大一号）

normal:  bg = COLOR_GOLD_MUD  border = COLOR_SUMI 2px  radius = 4
hover:   bg.lightened(0.10)   border = COLOR_SUMI 3px
pressed: bg.darkened(0.15)    content_margin_top += 2
disabled: bg = COLOR_PALE_INK 50%  border = COLOR_PALE_INK 30%
```

---

## 六、卡牌纸片样式（shop_slot 内部）

DisplayCard 底板通过 `apply_barrier_theme()` + `set_card_border()` 逐实例覆盖：

```
底板色:  COLOR_PAPER     #F5F0E8（替代暗蓝底）
卡框:    COLOR_SUMI 2px  #2B1E10（替代金边/紫边）
投影:    4px #00000015（纸片浮在纸面上的柔和阴影）

稀有度边框（只改颜色不改宽度）:
  common:    无特殊边框
  uncommon:  COLOR_BLUE_ZAN 2px
  rare:      COLOR_CINNABAR 3px
  legendary: COLOR_GOLD_MUD 3px
```

### 卡牌文字

| 元素 | 旧色 | 新色 | 字体 |
|------|------|------|------|
| name_label | `COLOR_CREAM` #F0EDE4 | `COLOR_SUMI` #2B1E10 | 思源黑体 Heavy 16px |
| effect_label | `COLOR_GRAY_OLIVE` #7A7A6A | `COLOR_PALE_INK` #6B6B6B | 思源黑体 Regular 13px |

---

## 七、字体加载与 override

### 文件操作

```
1. 重命名: mianfeiziti.com.ttf → zcool_miaodianti_regular.ttf
2. 创建:   zcool_miaodianti_regular.ttf.import（参考 SourceHanSansSC-Heavy.otf.import）
3. 旧字体不删（legacy/ 已存在）
```

### .import 参数

```ini
importer="font_data_dynamic"
type="FontFile"
antialiasing=1
generate_mipmaps=false
disable_embedded_bitmaps=true
allow_system_fallback=false
hinting=1
subpixel_positioning=1
oversampling=0.0
```

### 字体分配（全在商店脚本内 override，不动全局 Theme）

| 节点 | 字体 | 字号 | 理由 |
|------|------|------|------|
| ShopSubtitle | 站酷妙典体 | 36px | 大标题，毛笔张力 |
| GoldLabel | 站酷妙典体 | 20px | 数字大字 |
| RerollBtn | 站酷妙典体 | 14px | 按钮文字 |
| ContinueBtn | 站酷妙典体 | 18px | 按钮文字（稍大） |
| buy_button | 站酷妙典体 | 14px | 价格毛笔数字 |
| name_label | 思源黑体 Heavy | 16px | 小字可读性 |
| effect_label | 思源黑体 Regular | 13px | 小字可读性 |

---

## 八、与 BarrierTheme 的关系

```
shop_handler.gd
  └→ BarrierTheme.get_colors(barrier_num)  ← 保留调用，不删
       └→ shop_panel.init(shop_mgr, gold, colors)
            └→ _apply_barrier_theme()  ← 内部改为忽略 colors 做视觉决策
                                          colors 仅在将来需要时可用
```

方法签名不变，向后兼容。当前 `barrier_colors` 传入后被忽略。

---

## 九、不改动清单（防止越界）

| 文件/组件 | 原因 |
|-----------|------|
| `manga_theme.tres` | 全局 Theme，改默认字体会影响 Launcher/GameOver/所有按钮 |
| `display_card_base.gd:_init_card_style()` | NinjaBar/Preview/Debug 场景复用 |
| `barrier_theme.gd` | LeftPanel/GameBg 等全局组件依赖 |
| `nin_king_tween.gd` | 入口动画不改 |
| `ui_manager.gd` | shop 入口/出口流程不变 |
| `shop_handler.gd` | 信号流/购买逻辑不变 |

---

## 十、验收标准

| 场景 | 期望 |
|------|------|
| 商店背景 | 和纸米白色 #F5F0E8，无网点纹理 |
| 标题 "萬屋！" | 焦墨毛笔大字 36px |
| 卡牌底板 | 纸白底 + 墨线边框 + 柔和投影 |
| 卡牌名字 | 焦墨色黑体 16px（非白色） |
| 卡牌描述 | 淡墨灰黑体 13px |
| 购买按钮 | 朱砂红底 + 墨框 + 白色毛笔数字 |
| 刷新按钮 | 蓝锖底 + 墨框 + 白色毛笔文字 |
| 继续按钮 | 金泥底 + 墨框 + 白色毛笔文字 |
| 顶栏/底栏 | 纸色暗 #E8E0D0（非暗蓝黑） |
| 分隔线 | 淡墨灰（非纯黑） |
| 其他 UI | 不受影响（LeftPanel/NinjaBar/HandArea 保持原样） |
