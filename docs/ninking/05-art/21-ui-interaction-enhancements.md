# NinKing UI 交互增强素材指南

> **建立日期:** 2026-06-22 | **最后更新:** 2026-06-22 (+§3 Kenney 暖纸风面板/按钮改造)
> **用途:** 汇总所有为提升界面交互体验而集成的 UI 素材，说明架构、使用方法、替换流程和扩展指引。
> **原则:** 每项增强必须在此文档中有记录，否则视为未正式接入。
> **关联:**
>   [`20-kenney-ui-pack-evaluation.md`](20-kenney-ui-pack-evaluation.md) — Kenney 素材包评估
>   [`16-art-direction-principles.md`](16-art-direction-principles.md) — 美术方向原则
>   [`../04-ui/06-ui-layout-reference.md`](../04-ui/06-ui-layout-reference.md) — UI 布局参考
>   [`03-technical-design.md`](../06-tech/03-technical-design.md) — 技术架构

---

## 目录

1. [光标系统 — Kenney 自定义光标](#1-光标系统--kenney-自定义光标)
2. [后续扩展位](#2-后续扩展位)
3. [Kenney 暖纸风面板/按钮改造](#3-kenney-暖纸风面板按钮改造)

---

## 1. 光标系统 — Kenney 自定义光标

### 1.1 素材来源

| 项目 | 内容 |
|------|------|
| **素材包** | `kenney_ui-pack-rpg-expansion` (CC0) |
| **默认光标** | `cursorSword_gold.png` — 金色剑形（34×37 px） |
| **悬停光标** | `cursorHand_blue.png` — 蓝色手掌（27×28 px） |
| **素材路径** | `res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/` |
| **授权** | CC0，可商用无需署名 |
| **选取理由** | 详见 `20-kenney-ui-pack-evaluation.md` §2.3 — 少年漫画风下唯一可用项 |

### 1.2 架构

**文件:** `scripts/ninking/ui/cursor_manager.gd` → 注册为 `CursorManager` Autoload

```
project.godot:
  CursorManager="*res://scripts/ninking/ui/cursor_manager.gd"
```

#### 覆盖范围

| 节点类型 | 说明 | 效果 |
|---------|------|------|
| `Button` | 所有按钮（主菜单/游戏内/商店等） | ✅ 蓝手 |
| `Card` 及其子类 | `NinKingCard`(手牌) / `NinjaInventoryCard`(忍栏) / 商店卡牌 | ✅ 蓝手 |
| 其他 `Control` | 未显式覆盖的控件类 | 🗡️ 金剑（默认） |

#### 核心机制

`_enter_tree()` 时做两件事（⚠️ 必须用 `_enter_tree` 而非 `_ready`）：

1. **注册光标图片** — `Input.set_custom_mouse_cursor()`
   - `CURSOR_ARROW` → `cursorSword_gold.png` (金剑，默认)
   - `CURSOR_POINTING_HAND` → `cursorHand_blue.png` (蓝手，hover)
2. **连接 `SceneTree.node_added`** → 任意 Button 加入场景树时自动设 `mouse_default_cursor_shape = CURSOR_POINTING_HAND`

**结果：全游戏所有 Button 悬停时自动切换金剑→蓝手，零手动接入。**

#### 静态方法（供非 Button 控件手动调用）

| 方法 | 作用 |
|------|------|
| `CursorManager.set_default()` | 切回金剑（ARROW 形状） |
| `CursorManager.set_hover()` | 切换到蓝手（POINTING_HAND 形状） |
| `CursorManager.set_system_arrow()` | 恢复到系统默认箭头 |

### 1.3 工作效果

| 状态 | 光标 | 说明 |
|------|------|------|
| 鼠标在空白/背景上 | 🗡️ 金色剑形 | `CURSOR_ARROW` 自定义图片 |
| 鼠标悬停在任意 Button 上 | ✋ 蓝色手掌 | `CURSOR_POINTING_HAND` 自定义图片 |
| 鼠标悬停在非 Button 自定义控件上 | 🗡️ 金色剑形 | 需手动调用 `set_hover()` |

### 1.4 替换指南

#### 替换光标图片

```gdscript
# 在 cursor_manager.gd 中修改 const 路径即可
const CURSOR_DEFAULT := preload("res://你的新默认光标.png")
const CURSOR_HOVER := preload("res://你的新悬停光标.png")
```

**图片要求：**
- PNG 格式，透明背景
- 建议 24-48px 正方形或接近
- Godot 会自动缩放到光标标准尺寸（32×32）
- hotspot 在 `_register_cursors()` 中通过 `Vector2(x, y)` 设置

#### 更换光标形状映射

```gdscript
# 如需更换注册到哪种光标形状
Input.set_custom_mouse_cursor(图片, Input.CURSOR_ARROW, Vector2(4, 2))
Input.set_custom_mouse_cursor(图片, Input.CURSOR_POINTING_HAND, Vector2(2, 2))
```

完整的 `Input.CURSOR_*` 常量见 Godot 文档。

### 1.5 技术要点

#### 🔴 时序陷阱 — `_enter_tree` 而非 `_ready`

**问题（2026-06-22 发现并修复）：** Autoload 最初在 `_ready()` 中连接 `node_added` 信号，导致 Launch 界面光标不生效。

**根因：** Godot 初始化时序：

```
1. Autoload 创建 → _enter_tree() 触发    ← 应在此连接 node_added
2. 首个场景（Launch）节点依次加入场景树  ← node_added 信号在此阶段触发
3. _ready() 队列处理                     ← 如果在此连接信号，已经错过上一步
```

`_ready()` 虽在场景 `_ready()` 之前运行，但 `_ready()` 是被排入通知队列的，处理队列时场景节点**已经加入场景树完毕**。`_enter_tree()` 在 `add_child` 时立即触发，远早于场景加载。

**修复：** 改为 `_enter_tree()` 中连接信号。

#### 关键技术发现

- Godot 4 `Button.mouse_default_cursor_shape` 默认为 `CURSOR_ARROW`(0)，**不是** `CURSOR_POINTING_HAND`
- `SceneTree.node_added` 信号在 Godot 4.2+ 可用，适合做全局 Button 光标注入
- `Input.set_custom_mouse_cursor(image, shape, hotspot)` 是**注册图片到某个形状**，不改变当前形状 — 当前形状由鼠标所在位置的控件决定
- `*` 前缀的 Autoload 在编辑器中也会运行，需要用 `Engine.is_editor_hint()` 守卫 `_enter_tree()`

### 1.6 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 按钮悬停不切换蓝手 | Button 的 `mouse_default_cursor_shape` 仍为 `CURSOR_ARROW` | 确认 `_on_node_added` 正确设置了 `POINTING_HAND` |
| 光标不生效 | 注册了图片但形状未应用 | 检查 `Input.set_custom_mouse_cursor` 调用的形状常量 |
| Launch 界面无效果 | `_ready()` 时序问题 | 改用 `_enter_tree()` 连接信号 |
| 手牌/忍栏卡牌不变手 | `_on_node_added` 未覆盖 `Card` 类型 | 确认 `node is Card` 判断存在（v2 新增） |
| 非 Button/Card 控件不变光标 | 自动适配仅限 Button + Card | 手动调用 `CursorManager.set_hover()`/`set_default()` |

---

## 2. 后续扩展位

> 以下为待实施的 UI 交互增强，按优先级排列。实施后在此文档补充 §3/§4 等对应章节。

### 2.1 KN3 — Kenney 星星稀有度装饰 (P3 ⬜)

- **素材:** `star.png` / `star_outline.png`（kenney_ui-pack base / Yellow 色系）
- **用途:** `card_visual_composer.gd` 增补 rarity star 装饰层
- **预估:** ~0.5h

### 2.2 KN4 — Kenney 分割线替换 (P3 ⬜)

- **素材:** `divider.png`（kenney_ui-pack base / Extra）
- **用途:** 替换场景中纯色 ColorRect 分割线
- **预估:** ~0.3h

### 2.3 (预留位)

> 新增 UI 交互增强时在此补充 §3，并同步更新 `DOCUMENT_MAP.md` 和 `docs/ninking/README.md`。


## 3. Kenney 暖纸风面板/按钮改造

> **实施: 2026-06-22 | 方案: `kenney-beige-ui-transformation.md` | 状态: Phase 1-2 完成**

### 3.1 概览

所有 Panel 节点和 Button 节点的视觉风格从 `StyleBoxFlat` 纯色替换为 `StyleBoxTexture` 9宫格 Kenney 纹理。

**素材路径:** `res://assets/images/ui/kenney_ui-pack-rpg-expansion/PNG/`

| 纹理 | 尺寸 | 用途 |
|------|------|------|
| `panel_beige.png` | 100×100 | 主面板 (MatchPanel/AntePanel/SettlementCard) |
| `panel_beigeLight.png` | 100×100 | 轻面板 (HandTypePanel/ScorePanel/DeckViewer) |
| `buttonLong_beige.png` | 190×49 | 主菜单按钮/继续按钮 |
| `buttonLong_brown.png` | 190×49 | 操作按钮 (Play/AiRearrange) |
| `buttonSquare_brown.png` | 45×49 | 次要操作按钮 (Deck/Retry/Menu) |
| `buttonSquare_grey.png` | 45×49 | Debug 按钮 |
| `buttonRound_beige.png` | 35×38 | 商店购买按钮 |

### 3.2 面板映射

| 面板 | 纹理 | 9宫格边距 | 保留 shader |
|------|------|-----------|-------------|
| MatchPanel | `panel_beige` | 8px | ✅ `panel_edge_fade` |
| AntePanel | `panel_beige` | 8px | ✅ `panel_edge_fade` |
| HandTypePanel | `panel_beigeLight` | 8px | ✅ `panel_edge_fade` |
| ScorePanel | `panel_beigeLight` | 8px | ✅ `panel_edge_fade` |
| SettlementCard | `panel_beige` | 8px | — |
| DeckViewer CardPanel | `panel_beigeLight` | 8px | — |

### 3.3 按钮映射

| 按钮组 | 纹理 | 文字色 | 特殊处理 |
|--------|------|--------|---------|
| 主菜单 4 按钮 | `buttonLong_beige` + pressed 变体 | 深褐 #3D2B1A | DebugBtn 用 `buttonSquare_grey` |
| PlayBtn / AiRearrangeBtn | `buttonLong_brown` + pressed 变体 | 白 | pressed 时显示 BarrierTheme accent 色 |
| 牌库/重试/回菜单 | `buttonSquare_brown` + pressed 变体 | 白 | — |
| 商店继续 | `buttonLong_beige` | 深褐 | — |
| 商店刷新 | `buttonLong_brown` | 白 | — |
| 商店购买 | `buttonRound_beige` | 深褐 | pressed 用 `modulate_color(0.85)`（无 pressed 纹理） |

### 3.4 实现方式

- **面板:** 场景文件 `.tscn` 中 `StyleBoxFlat` sub_resource → `StyleBoxTexture` sub_resource，保留原有 ShaderMaterial（`panel_edge_fade`）
- **主菜单按钮:** `main_menu.gd` `_apply_kenney_button_style_to_all()` 程序化创建 `StyleBoxTexture`
- **游戏内操作按钮:** `barrier_theme.gd` 新增 `apply_kenney_button_style()` / `apply_kenney_square_style()` 静态方法；`game_manager.gd` 在 `_on_seal_started()` 中调用
- **商店按钮:** `shop_ui.gd` 替换 `_apply_seal_button_style` → `_apply_kenney_beige_style` / `_apply_kenney_brown_style`；`shop_slot.gd` 替换 `_apply_seal_button_style` → `_apply_kenney_round_style`
- **Debug 场景:** 同步修改 `debug_ninking_main.tscn` 中的 sub_resource 和节点引用（DebugPanel 及其子面板除外）

### 3.5 9宫格注意事项

Kenney 纹理边角圆边区域约 5px，留 3px 缓冲，**patch_margin = 8px**。若目视圆角被裁切可微调至 10-12px。

### 3.6 纹理过滤 — `texture_filter = 1` (NEAREST)

**所有使用 StyleBoxTexture 的 Panel 节点必须设置 `texture_filter = 1`（CanvasItem.TEXTURE_FILTER_NEAREST）。**

原因：Kenney 纹理在 9-patch 缩放时，默认 LINEAR 过滤会让纹理边缘产生模糊/渗色，表现为面板纹理模糊不清。NEAREST 过滤保持像素清晰。

| Panel 节点 | 设置位置 |
|-----------|---------|
| HandTypePanel | `texture_filter = 1` |
| ScorePanel | `texture_filter = 1` |
| MatchPanel | `texture_filter = 1` |
| AntePanel | `texture_filter = 1` |
