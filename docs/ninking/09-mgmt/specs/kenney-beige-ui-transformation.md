# 方案B：Kenney 暖纸风 UI 改造 — 实施方案

> **建立日期:** 2026-06-22 | **审阅:** 2026-06-22 (review-plan 通过，修正 A1/B3/D1)
> **来源:** `05-art/20-kenney-ui-pack-evaluation.md` §3
> **前置依赖:** `cursor_manager.gd` (KN1/KN2，已完成)
> **风格定位:** 治愈漫画风（暖米纸背景 + 和风圆润按钮），保留卡牌插画高饱和 + BarrierTheme 8属性 accent色
> **⚠️ 代码迁移注記 (2026-06-23):** 本方案中描述的 `barrier_theme.apply_kenney_button_style()` / `main_menu._apply_kenney_button_style_to_all()` 等方法已統一到 `ButtonStyles` (`scripts/ninking/ui/button_styles.gd`)。按鈕視覺效果一致，僅實現方式變更。詳見 `05-art/21-ui-interaction-enhancements.md` §3.4。

---

## 一、改造范围总览

```
          ✅ 面板 6 处       ✅ 按钮 4 类          ❌ 不变
   ┌─────────────────┐  ┌────────────────┐  ┌──────────────────┐
   │ LeftPanel ×4    │  │ 主菜单按钮 ×4  │  │ 卡牌插画 47 张   │
   │ SettlementCard  │  │ 操作按钮 ×5    │  │ Boss 立绘 9 张   │
   │ DeckViewerCard  │  │ 商店按钮 ×5    │  │ 粒子特效/VFX     │
   │ GameOver/Victory│  │ 关闭/次要 ×3  │  │ 光标(KN1/KN2)    │
   └─────────────────┘  └────────────────┘  └──────────────────┘
```

---

## 二、面板改造（6处，用 StyleBoxTexture 覆盖 StyleBoxFlat）

### 2.1 原理

保持 Panel 节点不变（容器功能 + shader + 子节点），只替换样式：

```
当前: Panel → theme_override_styles/panel = StyleBoxFlat(bg_color)
改造: Panel → theme_override_styles/panel = StyleBoxTexture(texture=panel_beige)
```

`StyleBoxTexture` 是 Godot 内置样式，使用 9宫格纹理拉伸，完美适配 Panel。

> ⚠️ **patch_margin 取值：** 纹理边角区约 5px，留 3px 缓冲，实际使用 **8px**。目视确认无变形后可微调。

### 2.2 映射表

| 面板 | 节点路径 | 当前 StyleBoxFlat | 改用纹理 | 9宫格边距 | 保留 shader? |
|------|---------|-----------------|---------|-----------|-------------|
| MatchPanel | `LeftPanel/MatchPanel` | bg=#4A2020FF | `panel_beige` | LTRB=8px | ✅ `panel_edge_fade` |
| AntePanel | `LeftPanel/AntePanel` | bg=#3D2B1AFF | `panel_beige` | LTRB=8px | ✅ `panel_edge_fade` |
| HandTypePanel | `LeftPanel/HandTypePanel` | bg=#0F2822FF | `panel_beigeLight` | LTRB=8px | ✅ `panel_edge_fade` |
| ScorePanel | `LeftPanel/ScorePanel` | bg=#0F282299 | `panel_beigeLight` | LTRB=8px | ✅ `panel_edge_fade` |
| SettlementCard | `SettlementOverlay/CardPanel` | InnerBorder Panel | `panel_beige` | LTRB=8px | — |
| DeckViewer | `DeckViewer/CardPanel` | StyleBoxFlat corner6 | `panel_beigeLight` | LTRB=8px | — |

### 2.3 PanelBg 处理

当前 `LeftPanel/PanelBg` 为 `ColorRect(color=Color(1,1,1,0))`，由 `game_manager.gd:156` 动态设 BarrierTheme 面板色。

**改造后：** PanelBg 颜色改为半透暖金色 `#F5F0E8(0.4)`，弱化底色让 Kenney 面板凸显。修改 `barrier_theme.gd` 中的 `panel` 色值。

### 2.4 GameOver/Victory 新增面板

当前 GameOver 和 Victory 覆盖层只有 `ColorRect` + `Label`，纯文字。

**改造：** 在现有文字下方增加 `NinePatchRect` 作为卡牌式面板背景：

```
GameOver/Victory Overlay:
  ├── OverlayBg (ColorRect, 半透明遮罩)
  ├── ContentPanel (NinePatchRect, texture=panel_beigeLight)  ← 新增
  │   ├── GameOverLabel / VictoryLabel
  │   ├── ScoreSummary / StatsSummary
  │   └── RetryButton~ / MenuButton
```

NinePatchRect 尺寸 500×400，居中，pop_in 入场。

---

## 三、按钮改造（4类 × 2色，用 9宫格纹理覆盖 StyleBoxFlat）

### 3.1 当前按钮样式现状

追溯当前按钮获得样式的方式：

| 按钮组 | 当前样式来源 | 视觉效果 |
|-------|------------|---------|
| 主菜单 4 按钮 | `manga_theme.tres` | 暗底金边粗框 |
| PlayBtn / AiRearrangeBtn | `BarrierTheme.apply_impact_button_style()` | 属性 accent 底 + 白字 |
| 商店按钮 | `BarrierTheme.apply_impact_button_style()` | 同上，accent 动态色 |
| DeckViewer CloseBtn | 无显式样式 | 纯文字 flat |
| 结算 UnlockBtn | `manga_theme.tres` | 暗底金边 |
| GameOver Retro/Menu | `BarrierTheme` 字体色 override | 金边红底 |

### 3.2 各类按钮适配方案

| 按钮类型 | 场景 | Kenney 纹理 | pressed 态 | 字体配色 |
|---------|------|------------|-----------|---------|
| **长按钮** `buttonLong` | 主菜单 4 按钮、结算 UnlockBtn | `_beige` 190×49 stretch | `_beige_pressed` | 深褐字 #3D2B1A |
| **操作按钮** `buttonLong` | PlayBtn / AiRearrangeBtn / DeckBtn | `_brown` 190×49（重感强调） | `_brown_pressed` | 白字 #FFFFFF |
| **次要按钮** `buttonSquare` | CloseBtn / 关闭/取消类 | `_beige` 45×49 | `_beige_pressed` | 深褐字 |
| **商店按钮** `buttonRound` | 购买/刷新按钮 | `_brown`（刷新重感）/ `_beige`（购买轻感） | — | 白字 / 深褐字 |

### 3.3 主菜单按钮详细适配

当前：`manga_theme.tres` 中 Theme 统一定义按钮样式。4 个按钮尺寸 300×70。

改造步骤：
1. 取消 `manga_theme.tres` 对这四个按钮的 StyleBox 覆盖
2. 程序化设置：`main_menu.gd` _ready 中为 4 按钮创建 StyleBoxTexture
3. `buttonLong_beige.png` 190×49 → Stretch 到按钮尺寸
4. Patch margins: 16px 保护四角
5. Hover: scale 1.03 保留（GlobalTweens.card_hover）

```gdscript
# main_menu.gd _build_ui() 中追加
for btn in _buttons:
	var s := StyleBoxTexture.new()
	s.texture = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_beige.png")
	s.patch_margin_left = 8
	s.patch_margin_top = 8
	s.patch_margin_right = 8
	s.patch_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)
	
	var sp := StyleBoxTexture.new()
	sp.texture = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_beige_pressed.png")
	sp.patch_margin_left = 8
	sp.patch_margin_top = 8
	sp.patch_margin_right = 8
	sp.patch_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", sp)
	
	btn.add_theme_color_override("font_color", Color(0.24, 0.17, 0.10))  # 深褐
```

### 3.4 游戏内操作按钮适配（PlayBtn / AiRearrangeBtn）

当前使用 `BarrierTheme.apply_impact_button_style()` 动态生成 accent 色背景。

**改造方案：** `buttonLong_brown` 作为基础（重感强调 + 暖棕统一），文字色 = `BarrierTheme.accent`（动态），保留 8 属性身份：

```gdscript
# barrier_theme.gd 新增方法
static func apply_kenney_button_style(btn: Button, accent: Color) -> void:
	var s := StyleBoxTexture.new()
	s.texture = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown.png")
	s.patch_margin_left = 8
	s.patch_margin_top = 8
	s.patch_margin_right = 8
	s.patch_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)
	
	# Hover: lighter — modulate_color 无法直接用 >1.0，用白色混合逼近
	var sh := StyleBoxTexture.new()
	sh.texture = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown.png")
	sh.modulate_color = Color(1.05, 1.03, 1.0)
	sh.patch_margin_left = 8
	sh.patch_margin_top = 8
	sh.patch_margin_right = 8
	sh.patch_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", sh)
	
	# Pressed
	var sp := StyleBoxTexture.new()
	sp.texture = preload("res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/buttonLong_brown_pressed.png")
	sp.patch_margin_left = 8
	sp.patch_margin_top = 8
	sp.patch_margin_right = 8
	sp.patch_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", sp)
	
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", accent)
```

关键：**按钮底色统一暖棕，accent 色通过文字和 pressed 态间接体现**，不丢失 BarrierTheme 身份。

### 3.5 商店按钮适配 ✅ 已实施

商店按钮由 `shop_ui.gd` 和 `shop_slot.gd` 程序化设置，不再依赖 `BarrierTheme.apply_impact_button_style()`。

- **购买按钮 (BuyBtn)：** `buttonSquare_brown`（125×40），白字，disabled 态用 `buttonSquare_grey`。由 `shop_slot.gd:_apply_purchase_button_style()` 实施
- **刷新按钮 (RerollBtn)：** `buttonLong_brown`（190×49），白字。由 `shop_ui.gd:_apply_long_button(reroll_button, "brown")` 实施
- **继续按钮 (ContinueBtn)：** `buttonLong_beige`（190×49），深褐字。由 `shop_ui.gd:_apply_long_button(continue_button, "beige")` 实施

> 面板整体方案详见 [`../../04-ui/07-shop-ui-design.md`](../../04-ui/07-shop-ui-design.md) v8。

### 3.6 按钮映射汇总

| 具体按钮 | 当前 | 改造用纹理 | 颜色 | 文字色 |
|---------|------|-----------|------|-------|
| 开始游戏 | theme 金边暗底 | `buttonLong_beige` | 暖米 | 深褐 |
| 继续游戏 | 同上 | `buttonLong_beige` | 暖米 | 深褐 |
| 设置 | 同上 | `buttonLong_beige` | 暖米 | 深褐 |
| 退出游戏 | 同上 | `buttonLong_beige` | 暖米 | 深褐 |
| DebugBtn | 红字 flat | `buttonSquare_grey` | 灰 | 深灰 |
| PlayBtn | accent 色底 | `buttonLong_brown` | 暖棕 | 白（pressed→accent） |
| AiRearrangeBtn | accent 色底 | `buttonLong_brown` | 暖棕 | 白 |
| DeckBtn | accent 色底 | `buttonSquare_brown` | 暖棕 | 白 |
| 商店购买 | accent 色底 | `buttonSquare_brown` | 暖棕 | 白（disabled→grey） |
| 商店刷新 | accent 色底 | `buttonLong_brown` | 暖棕 | 白 |
| 商店继续 | accent 色底 | `buttonLong_beige` | 暖米 | 深褐 |
| 结算 UnlockBtn | theme 金边 | `buttonLong_beige` | 暖米 | 深褐 |
| 重试 | accent 色底 | `buttonSquare_brown` | 暖棕 | 白 |
| 回菜单 | accent 色底 | `buttonSquare_brown` | 暖棕 | 白 |
| 胜利回菜单 | accent 色底 | `buttonSquare_brown` | 暖棕 | 白 |
| 牌库 CloseBtn | flat | `buttonSquare_beige` | 暖米 | 深褐 |

---

## 四、BarrierTheme 适配

### 4.1 面板色调整

当前 `barrier_theme.gd` 的 `panel` 字段是暗色调（用于 ColorRect PanelBg）。改造后：

```gdscript
# 旧: 暗色 panel 底色 → 改为暖调半透，与 Kenney beige 协调
1: { panel: Color(0.96, 0.94, 0.90, 0.3), ... }  # 火 → 暖米半透
2: { panel: Color(0.92, 0.95, 0.96, 0.3), ... }  # 水 → 极淡青
...
```

### 4.2 按钮字体色保留

BarrierTheme 的 `accent` 色继续用于字体颜色 override，按钮底色改为 Kenney 纹理后，属性色通过字体色保持可见。

---

## 五、涉及文件清单

| 文件 | 改动内容 |
|------|---------|
| `scenes/ninking/ninking_main.tscn` | 5 处 Panel 的 `theme_override_styles/panel` 改为 StyleBoxTexture（sub_resource 形式）；GameOver/Victory 下新增 NinePatchRect |
| `scenes/ninking/debug_ninking_main.tscn` | 同步改造面板/按钮（**DebugPanel 及其子面板除外**） |
| `scenes/ninking/ninking_launcher.tscn` | 按钮样式通过代码设置，场景文件不改 |
| `scenes/ninking/settlement_card.tscn` | CardPanel/InnerBorder 的 style 改为 StyleBoxTexture |
| `scripts/ninking/ui/main_menu.gd` | `_build_ui()` 追加按钮 StyleBoxTexture 设置 + 字体色 |
| `scripts/ninking/barrier_theme.gd` | 新增 `apply_kenney_button_style()` + `apply_kenney_panel_style()` 方法；PanelBg 颜色值调整 |
| `scripts/ninking/ui/game_manager.gd` | `_on_seal_started()` 中按钮样式改为调 `apply_kenney_button_style()` |
| `scripts/ninking/ui/shop_ui.gd` | 商店按钮样式改为 Kenney 纹理 |
| `scripts/ninking/ui/ui_manager.gd` | GameOver/Victory 面板初始化（如新增 NinePatchRect 的引用） |
| `assets/themes/manga_theme.tres` | ⚠️ **不删 Theme 中的按钮样式**，仅通过 `add_theme_stylebox_override()` 在目标按钮上覆盖。Override 优先级高于 Theme，不影响其他未覆盖按钮 |
| `docs/ninking/05-art/21-ui-interaction-enhancements.md` | 补充面板+按钮改造记录 |
| `docs/ninking/DOCUMENT_MAP.md` | 追加本 spec 文档的映射条目 |

---

## 六、实施步骤

### Phase 1 — 面板改造（~40min）

```
1. ninking_main.tscn: 5 处 Panel 的 StyleBoxFlat → StyleBoxTexture sub_resource
   - MatchPanel / AntePanel → panel_beige
   - HandTypePanel / ScorePanel → panel_beigeLight
   - DeckViewer CardPanel → panel_beigeLight
2. barrier_theme.gd: 调整 PanelBg 色值 → 暖调半透
3. settlement_card.tscn: InnerBorder → panel_beige
4. ninking_main.tscn: GameOver/Victory 新增 NinePatchRect 面板
5. 验证：启动游戏，检查面板纹理加载
```

### Phase 2 — 按钮改造（~50min）

```
1. barrier_theme.gd: 新增 apply_kenney_button_style() 方法
2. main_menu.gd: 4 主菜单按钮 + Debug 按钮样式重写
3. game_manager.gd: PlayBtn / AiRearrangeBtn / DeckBtn 样式切换
4. shop_ui.gd: 商店按钮样式切换
5. 验证：所有按钮纹理加载 + hover/pressed 态正常
```

### Phase 3 — BarrierTheme 适配 + GameOver/Victory（~30min）

```
1. barrier_theme.gd: PanelBg 色值全部调整为暖调
2. game_manager.gd: 按钮字体色保留 accent 动态
3. ui_manager.gd: GameOver/Victory 面板引用
4. 验证：8 属性切换时按钮文字色正确变化
```

---

## 七、风险与注意事项

| 风险 | 级别 | 缓解 |
|------|------|------|
| `buttonLong_beige` (190×49) 拉伸到 300×70 后变形 | 🟡 | 用 9宫格 + patch_margin=16 保护四角圆边；或改用 StyleBox `stretch_mode=scale` 保持比例 |
| `buttonRound_beige` (35×38) 尺寸较小 | 🟡 | 适合购买/关闭等小型按钮；大按钮用 `buttonLong` 系列 |
| 纹理 `modulate_color` 在 StyleBoxTexture 中不如 StyleBoxFlat 的 `bg_color` 可控 | 🟡 | hover 态用 `modulate_color = Color(1.1, 1.1, 1.05)` 提亮，不依赖颜色运算 |
| 面板 `panel_edge_fade` shader 与纹理交互 | 🟢 | 保留 on Panel 的 material，shader 在纹理上层做 fade，不影响纹理显示 |
| 纹理依赖项目文件路径 | 🟢 | 已在项目中，无外部依赖 |
| 整体风格统一性 | 🟡 | 卡牌插画高饱和 x 面板暖纸 — 类似于 Balatro 绿毡 x 彩色卡牌，中性底+鲜艳内容是经典搭配 |
