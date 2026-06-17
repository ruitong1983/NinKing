# Kenney UI 素材包评估报告

> **建立日期:** 2026-06-17 | **评估人:** Claude Code
> **关联文档:** [`16-art-direction-principles.md`](16-art-direction-principles.md) · [`07-shop-ui-design.md`](../04-ui/07-shop-ui-design.md) · [`09-mgmt/specs/shop-ink-wash-redesign.md`](../09-mgmt/specs/shop-ink-wash-redesign.md) · [`19-image-asset-matching-guide.md`](19-image-asset-matching-guide.md)
> **素材位置:** `assets/images/ui/kenney_ui-pack/` + `assets/images/ui/kenney_ui-pack-rpg-expansion/`

---

## 目录

1. [素材包总览](#一素材包总览)
2. [少年漫画风评估（当前方向）](#二少年漫画风评估当前方向)
3. [治愈漫画风评估（备选方向）](#三治愈漫画风评估备选方向)
4. [两方向对比总结](#四两方向对比总结)
5. [附录：素材清单](#五附录素材清单)

---

## 一、素材包总览

### 1.1 `kenney_ui-pack`（基础包 — CC0）

| 分类 | 内容 | 颜色 |
|------|------|------|
| 按钮 | 矩形/圆角/方形 × 10 种风格（flat/border/gloss/gradient/depth/line） | 🔵🟢🔴🟡⚪ Extra |
| 滑动条 | 横/竖 × 带滑块手柄 | 同上 × 彩色+灰色 |
| 复选框 | 圆形/方形 × 彩色+灰色 | 🔵🟢🔴🟡⚪ |
| 图标 | checkmark / cross / circle / square / star | 🔵🟢🔴🟡⚪ |
| 箭头 | 基础 + 装饰 × 4 方向 | 🔵🟢🔴🟡⚪ |
| 输入框 | 文本输入框（Extra 色系） | ⬜ |
| 分割线 | divider | ⬜ |
| 字体 | Kenney Future + Kenney Future Narrow | TTF |
| 音效 | click-a/b · switch-a/b · tap-a/b | 6 × ogg |
| Extra | play/repeat/arrow_up/arrow_down 图标 | ⬜ |

### 1.2 `kenney_ui-pack-rpg-expansion`（RPG 扩展 — CC0）

| 分类 | 内容 | 颜色 |
|------|------|------|
| 面板 | 普通 + 凹入（inset） | 米黄/浅米黄/蓝/棕 |
| 按钮 | 长/圆/方 × 含 pressed 态 | 米黄/蓝/棕/灰 |
| 血条/进度条 | 横/竖 × 9 宫格部件 | 蓝/绿/红/黄/灰 + 背景 |
| 光标 | 手/铁手套/剑 | 金/银/铜/蓝/灰/米黄 |
| 箭头 | 左右方向 | 米黄/蓝/棕/银 |
| 图标 | check / circle / cross | 米黄/蓝/棕/灰 |

### 1.3 授权

两套均为 **CC0**（Creative Commons Zero），可用于商业项目，无需署名。详见 `license.txt`。

---

## 二、少年漫画风评估（当前方向）

### 2.1 项目当前美术方向

> 来源: [`16-art-direction-principles.md`](16-art-direction-principles.md)

| 维度 | 规范 |
|------|------|
| **主风格** | 少年漫/热血漫（Shonen Manga） |
| **色调** | 亮色英雄向 — 高饱和 accent + 开阔明快的底色 |
| **面板描边** | 2-3px `#1A1A1A` 仿手绘描边，6-8px 圆角 |
| **按钮 normal** | 属性 accent 色底 + 2px `#1A1A1A` 描边 + 白色粗体字 |
| **按钮 hover** | 底色调亮 10% + 描边 3px + scale 1.03 |
| **按钮 pressed** | 底色调暗 15% + content 下移 2px |
| **进度条** | StyleBoxFlat 纯色填充，动态跟随 8 属性色 |
| **商店** | 已确定水墨风改造（2026-06-13 Grill），和纸底+印章按钮 |

### 2.2 匹配度矩阵

| 素材 | 匹配度 | 结论 | 原因 |
|------|--------|------|------|
| panel_beige | ❌ | 不匹配 | 热血的少年漫不需要暖米面板，现有暗色半透明+属性色更契合 |
| buttonLong_beige | ❌ | 不匹配 | 与 #1A1A1A 粗黑边+accent 底规范冲突 |
| buttonRound 系列 | ❌ | 不匹配 | 圆润扁平风 vs 漫画粗描边风 |
| barGreen/barYellow | ❌ | 不匹配 | 静态纹理无法跟随 8 属性动态变色 |
| cursorSword_gold | 🟢 | 可用 | 剑形光标在忍者主题中合理，风格中性 |
| cursorHand_* | 🟡 | 备选 | 手形光标可用但剑形更贴合忍者主题 |
| iconCheck/iconCircle | 🟡 | 备而不用 | 当前无对应交互需求 |
| 箭头/分割线 | 🟡 | 备而不用 | 当前无对应交互需求 |
| Kenney 音效 6 ogg | ❌ | 不引入 | C8 已于 2026-06-14 完成全线音效接线（Anime Game Pack） |
| Kenney Future 字体 | 🟡 | 备选 | 英文装饰字体，与现有思源黑体+凤凰点阵体不冲突 |
| 滑动条/输入框 | 🔴 | 不引入 | 项目当前无设置页面需求 |

### 2.3 少年漫画风下唯一可行项

```
只有 cursorSword_gold —— 自定义光标替换系统默认箭头
工作量: ~10 分钟 (Input.set_custom_mouse_cursor)
```

其余 Kenney 素材与已确认的少年漫画风方向存在根本性视觉冲突，不建议引入。

---

## 三、治愈漫画风评估（备选方向）

### 3.1 假设风格定义

> 基于治愈系漫画通用视觉语言，非 NinKing 已确认方向。

| 维度 | 特征 |
|------|------|
| **色调** | 暖色低饱和（米白/淡茶/鹅黄/浅粉/薄荷） |
| **描边** | 细或无描边，柔和过渡 |
| **按钮** | 圆润色块 + 柔和阴影，无硬边 |
| **面板** | 暖色不透明底 + 柔和投影 |
| **气质** | 温暖、友好、干净、有呼吸感 |

### 3.2 匹配度矩阵

| 素材 | 匹配度 | 用途 | 来源 |
|------|--------|------|------|
| panel_beige / panel_beigeLight | ⭐⭐⭐⭐⭐ | 商店背景、弹窗背景、卡牌底板 | RPG |
| panelInset_beige | ⭐⭐⭐⭐⭐ | TitleBar/BottomBar 凹陷感头栏 | RPG |
| buttonLong_beige (+pressed) | ⭐⭐⭐⭐ | 主菜单 4 按钮、商店继续按钮 | RPG |
| buttonRound_beige | ⭐⭐⭐⭐ | 购买按钮、討伐/陣形按钮 | RPG |
| buttonSquare_beige (+pressed) | ⭐⭐⭐⭐ | 牌库按钮、方形操作按钮 | RPG |
| buttonLong_brown (+pressed) | ⭐⭐⭐⭐ | 商店刷新按钮（暖棕强调） | RPG |
| buttonRound_brown | ⭐⭐⭐⭐ | 次要操作按钮 | RPG |
| buttonLong_grey | ⭐⭐⭐ | disabled 态按钮 | RPG |
| buttonSquare_grey (+pressed) | ⭐⭐⭐ | 关闭按钮（✕） | RPG |
| barGreen_horizontal 9宫格 | ⭐⭐⭐⭐ | 进度条（暖绿 = 治愈+成长感） | RPG |
| barYellow_horizontal 9宫格 | ⭐⭐⭐ | 进度条备选（暖金） | RPG |
| cursorHand_beige | ⭐⭐⭐⭐⭐ | 全局光标（友好手形） | RPG |
| cursorHand_blue | ⭐⭐⭐⭐ | 可点击元素 hover 光标 | RPG |
| iconCheck_beige | ⭐⭐⭐⭐ | 已拥有/已购买标记 | RPG |
| iconCircle_beige | ⭐⭐⭐⭐ | 选中态圆点 | RPG |
| iconCross_beige | ⭐⭐⭐ | 错误/取消标记 | RPG |
| arrowBeige_left/right | ⭐⭐⭐ | 翻页导航（未来） | RPG |
| base pack Yellow flat/gradient | ⭐⭐⭐⭐ | 主色调暖色按钮备选 | base |
| base pack Yellow round | ⭐⭐⭐⭐ | 圆角按钮备选 | base |
| base pack star/star_outline | ⭐⭐⭐⭐ | 稀有度/收藏标记 | base |
| base pack icon_checkmark/cross | ⭐⭐⭐ | 通用图标 | base |
| base pack Extra divider | ⭐⭐⭐ | 场景分割线 | base |
| base pack 音效 6 ogg | ⭐⭐⭐ | UI 音效补充池 | base |
| Kenney Future 字体 | ⭐⭐⭐ | 英文装饰字体备选 | base |
| base pack 滑动条/输入框 | ⭐⭐ | 设置页面（未来） | base |
| cursorSword_gold | 🔴 | 剑形与治愈系矛盾 | RPG |

### 3.3 治愈系下的推荐实施路线

#### Phase 1 — 面板替换（高影响）

| 组件 | 当前 | 治愈系方案 | 来源 |
|------|------|-----------|------|
| 商店背景 | 深色半透明 | `panel_beigeLight` #F5F0E8 暖米底 | RPG |
| 商店 TitleBar/BottomBar | 暗色强化 | `panelInset_beige` 提供凹陷感 | RPG |
| 卡牌底板（shop_slot） | 深色半透明 | `panel_beige` 暖纸色底 | RPG |
| GameOver/Victory 弹窗 | ColorRect 纯色 | `panel_beige` 作背景 | RPG |

#### Phase 2 — 按钮替换（中影响）

| 组件 | 当前 | 治愈系方案 | 来源 |
|------|------|-----------|------|
| 主菜单 4 按钮 | 暗底+金边 StyleBox | `buttonLong_beige` | RPG |
| 商店购买按钮 | StyleBox 红底 | `buttonRound_beige` | RPG |
| 商店刷新按钮 | StyleBox 蓝底 | `buttonRound_brown` | RPG |
| 商店继续按钮 | StyleBox 金底 | `buttonLong_beige` | RPG |
| 討伐/陣形按钮 | StyleBox 深红/灰 | `buttonRound_beige` | RPG |
| 牌库按钮 | StyleBox 金底 | `buttonSquare_beige` | RPG |
| ✕ 关闭按钮 | 纯文字 flat | `buttonRound_grey` | RPG |

#### Phase 3 — 进度条 + 光标

| 组件 | 方案 | 说明 |
|------|------|------|
| ProgressBar | `barGreen_horizontal` 9 宫格 | 固定暖绿（治愈+成长感），不跟随属性色 |
| 全局光标 | `cursorHand_beige` | `Input.set_custom_mouse_cursor()` |
| hover 光标 | `cursorHand_blue` | 按钮/可交互元素悬停时切换 |

#### Phase 4 — 装饰 + 音效补充

| 组件 | 方案 | 说明 |
|------|------|------|
| 分割线 | `divider.png`（Extra） | 替换场景中纯色 ColorRect |
| 已购买标记 | `iconCheck_beige` | 备而不用 |
| 稀有度标记 | `star_outline_yellow` | 备而不用 |
| UI 音效 | 6 ogg → SoundBank 可选池 | 不推翻 C8，仅补充 |

### 3.4 仍需要 AI/专业素材的部分

Kenney 两套包在治愈系下可覆盖约 **60% 的 UI 图素需求**，以下仍需额外素材：

- 卡牌插画 47 张（当前已部署少年漫画风，需重新生成）
- Boss 立绘 9 张（需重新生成）
- 卡背（当前「忍」字粗黑风，需重绘）
- 粒子特效（manga_burst/ink/speed_line → sparkle/柔光/花瓣）
- 三墩区分视觉（1px/2px/3px 递进需重新设计）
- 卡牌框纹理 4 套（当前粗黑边 → 软圆角框）

---

## 四、两方向对比总结

| 维度 | 少年漫画（当前） | 治愈漫画（备选） |
|------|---------------|----------------|
| Kenney 可用项 | `cursorSword_gold` 仅 1 项 | 面板+按钮+进度条+光标+装饰 ~15 项 |
| 覆盖 UI 图素需求 | ~2% | ~60% |
| 已实施资产需重做 | 无 | 卡牌插画 47 张、Boss 立绘 9 张、粒子特效、卡背等 ≥50 项 |
| 当前开发任务影响 | 无 | Phase F1/G/H 工作不受影响，但 V 系列视觉任务需全部重评 |
| 风格切换成本 | — | 高（整个美术管线翻新） |

---

## 五、附录：素材清单

### 5.1 RPG expansion — 推荐引入清单（治愈系）

| 文件名 | 用途 | 9宫格 |
|--------|------|--------|
| `panel_beige.png` | 商店背景、卡牌底板 | ✅ |
| `panel_beigeLight.png` | 浅色场景背景 | ✅ |
| `panelInset_beige.png` | 头栏/底栏凹陷面板 | ✅ |
| `buttonLong_beige.png` + `_pressed` | 主菜单/继续按钮 | ❌ 拉伸缩放 |
| `buttonRound_beige.png` | 购买/討伐按钮 | ❌ 拉伸缩放 |
| `buttonSquare_beige.png` + `_pressed` | 牌库按钮 | ❌ 拉伸缩放 |
| `buttonLong_brown.png` + `_pressed` | 刷新按钮 | ❌ 拉伸缩放 |
| `buttonRound_brown.png` | 次要操作按钮 | ❌ 拉伸缩放 |
| `buttonSquare_grey.png` + `_pressed` | 关闭按钮 | ❌ 拉伸缩放 |
| `barGreen_horizontal{Left,Mid,Right}.png` | 进度条填充 | ✅ 9宫格 |
| `barBack_horizontal{Left,Mid,Right}.png` | 进度条背景 | ✅ 9宫格 |
| `cursorHand_beige.png` | 全局光标 | — |
| `cursorHand_blue.png` | 悬停光标 | — |
| `iconCheck_beige.png` | 购买标记 | — |
| `iconCircle_beige.png` | 选中态 | — |
| `arrowBeige_left.png` / `arrowBeige_right.png` | 翻页/指示 | — |

### 5.2 base pack — 推荐引入清单（治愈系）

| 文件名 | 用途 | 说明 |
|--------|------|------|
| Yellow 系 `button_round_flat/gradient` | 暖色按钮备选 | 如 beige 按钮不够用 |
| Yellow `star.png` / `star_outline.png` | 稀有度/收藏标记 | — |
| Yellow `icon_checkmark.png` / `icon_cross.png` | 通用图标 | — |
| Extra `divider.png` | 场景分割线 | — |
| `Sounds/` 6 ogg | UI 音效补充池 | 可选 |
| `Font/Kenney Future.ttf` | 英文装饰字体 | 备选 |
