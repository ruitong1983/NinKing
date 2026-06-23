# NinKing Launch UI 设计方案

> **建立日期:** 2026-06-10 | **最后更新:** 2026-06-23 (消除模式通道) | **关联场景:** `ninking_launcher.tscn` + `ninking_clean_main.tscn` + `deck_select_panel.tscn` + `continue_panel.tscn` + `main_menu.gd`
> **风格权威:** [`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) · 治愈漫画风（旧少年漫画方向已于 2026-06-23 废弃）
## §1 概述

Launch 场景是玩家接触的第一个界面。从闪屏过渡到主菜单，再通过模态面板进入游戏。

```
 闪屏（0.8s）
    │
    ▼
 主菜单（5 按钮 stagger slide-in）
   ├── [開始] → 牌组选择面板 → [确认] → start_new_run(deck_key, "bi_ji") → Main
   ├── [消除] → 牌组选择面板 → [确认] → start_new_run(deck_key, "clean") → CleanMain
   ├── [繼續] → 继续确认面板 → [继续冒险] → continue_run() → Main
   ├── [設置] → (预留)
   └── [退出] → quit()
```

---

## §2 场景结构

```
Launcher (Control) [main_menu.gd]
├── LaunchBg (TextureRect)            ← 背景图 (launch_bg.png)
│
├── StartBtn (Button)                  ← 「開始」P0 (比鸡模式)
├── CleanBtn (Button)                  ← 「消除模式」P0 (消除模式, brown 色)
├── ContinueBtn (Button)               ← 「繼續」P0
├── SettingsBtn (Button)               ← 「設置」P2
├── QuitBtn (Button)                   ← 「退出」P2
├── %DebugBtn (Button)                ← 「DEBUG」(右下角, `apply_kenney_long("grey")`)
│
├── Overlay (ColorRect)               ← 全屏半透明遮罩 (程序化构建)

### §2.1 按钮入场动效

所有 Launch 按钮经 `ButtonStyles.attach_entrance_animation()` 统一挂载交互生命周期：
- **stagger slide-in 入场** → 随后挂载 hover 放大 + click squash 反馈
- **呼吸脉冲** (Scale 1.0↔1.05, TRANS_SINE, 无限循环): **仅 StartBtn 保留**
- ContinueBtn / SettingsBtn / QuitBtn / DebugBtn: `pulse: false`（只保留 hover + click，简洁化）
- 样式: 全部 `apply_kenney_long()`，beige 底色 / grey(DebugBtn)

│
├── %DeckSelectPanel (Control)       ← 子场景: deck_select_panel.tscn [deck_select_panel.gd]
│   └── PanelBg (PanelContainer, 960×600 居中)
│       └── VBox (VBoxContainer)
│           ├── Title (Label)           ← "選擇牌組" 32px 金
│           ├── %CardsRow (HBoxContainer) ← 牌组卡片行
│           └── BtnRow (HBoxContainer)
│               ├── %ConfirmBtn (Button 160×48)  ← "開始"
│               └── %BackBtn (Button 160×48)     ← "返回"
│
├── %ContinuePanel (Control)         ← 子场景: continue_panel.tscn [continue_panel.gd]
│   └── ContinuePanelBg (PanelContainer, 560×400 居中)
│       └── ContinueVBox (VBoxContainer)
│           ├── %ContinueTitle (Label)  ← "繼續冒險" 32px 金
│           ├── %ContinueInfo (Label)   ← run 信息摘要 24px 灰
│           └── ContinueBtnRow (HBoxContainer)
│               ├── %GoBtn (Button 180×48)    ← "继续冒险"
│               └── %BackBtn (Button 160×48)  ← "返回"
│
└── ParticleLayer (CanvasLayer)        ← 樱花粒子层 layer=128 (程序化构建)
    └── AmbientTimer (Timer)           ← 驱动粒子爆发
```

---

## §3 主菜单屏

### 3.1 按钮

| 按钮 | text | 默认状态 | 备 注 |
|------|------|---------|------|
| StartBtn | `开始游戏` | 可用 | 打开牌组选择面板 → 比鸡模式 |
| CleanBtn | `消除模式` | 可用 | 打开牌组选择面板 → 消除模式 |
| ContinueBtn | `继续游戏` | 无存档时 disabled | 打开继续确认面板 |
| SettingsBtn | `设置` | disabled | 预留，暂无功能 |
| QuitBtn | `退出游戏` | 可用 | `get_tree().quit()` |

### 3.2 动画

| 阶段 | 时长 | 效果 |
|------|------|------|
| 闪屏 | 0.8s | 按钮 `modulate.a = 0`，背景可见 |
| 滑入 | 0.4s/btn | `GlobalTweens.stagger_slide_in()`，间隔 0.08s，偏移 80px |

### 3.3 环境动效

| 效果 | 实现 | 参数 |
|------|------|------|
| 背景呼吸 | `create_tween().set_loops()` | scale 1.0↔1.04，14s 循环，SINE EASE_IN_OUT |
| 樱花粒子 | CPUParticles2D 程序构建 | 每 1-2s 随机爆发，40 粒子，3s 寿命，120px 散布 |

### 3.4 按钮交互

| 事件 | 效果 |
|------|------|
| hover | `GlobalTweens.card_hover(btn, Vector2(1.05, 1.05), -2.0)` + hover SFX |
| unhover | `GlobalTweens.card_unhover(btn, Vector2.ONE, 0.0)` |
| click | click SFX |

---

## §4 牌组选择面板

### 4.1 布局

```
┌─────────────────────────────────────────┐
│              選擇牌組                     │  ← DeckTitle (32px, 金色)
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │ 标准牌组  │ │ 暗夜牌组  │ │ 赤阳牌组  │ │  ← 220×300 卡片
│  │          │ │          │ │          │ │
│  │ 最佳: N  │ │ 暂无记录  │ │ 暂无记录  │ │  ← 最佳结界记录
│  └──────────┘ └──────────┘ └──────────┘ │    (未开放: modulate 0.4 置灰)
│                                         │
│         [確認]    [返回]                 │  ← 160×48 按钮
└─────────────────────────────────────────┘
```

- 面板容器: `PanelContainer` 960×600，居中
- 卡片间距: 32px (HBox separation)
- 垂直段间距: 32px (VBox separation)

### 4.2 牌组卡片

| 牌组 | key | 状态 | 显示 |
|------|-----|------|------|
| 标准牌组 | `standard` | 可用 | 正常 modulate，可点击选中 |
| 暗夜牌组 | `night` | 未实现 | modulate(0.4, 0.4, 0.4, 0.6) 置灰，点击无响应 |
| 赤阳牌组 | `sun` | 未实现 | 同上 |

### 4.3 选中态

选中卡片高亮：`StyleBoxFlat` 暖棕边框 (2px, `#8B6F4E`) + 暖米底 (`#F0EBDC`) + 暖棕阴影 (6px)。与 KUI 暖纸风面板协调。

### 4.4 交互流

```
[開始] / [消除] click
  ├── _panel_open 守卫（防双击）
  ├── 设置 _pending_mode ("bi_ji" / "clean")
  ├── Overlay fade_in 0.25s
  ├── DeckPanel pop_in 0.25s
  │
  ├── 点击牌组卡片 → 更新选中态 + 切换 _selected_deck
  ├── [確認] → start_new_run(deck_key, _pending_mode) + change_scene
  │            ├── "bi_ji"  → ninking_main.tscn
  │            └── "clean" → ninking_clean_main.tscn
  ├── [返回] → fade_out 0.2s + hide
  └── 点击遮罩 → 同 [返回]
```

---

## §5 继续确认面板

### 5.1 布局

```
┌─────────────────────────────────┐
│          繼續冒險                │  ← 32px 深褐
│                                 │
│    结界 3 · 明王封印             │  ← 24px info 行
│    当前忍気: 450 / 600          │
│    金币: $12 · 忍者: 4 人       │
│                                 │
│    [繼續冒險]    [返回]          │  ← 180/160×48
└─────────────────────────────────┘
```

- 面板容器: `PanelContainer` 560×400，居中
- 间距: 24px (VBox separation)

### 5.2 数据来源

`SaveManager.load_run()` → 解析字段:

| 字段 | 显示 |
|------|------|
| `barrier_num` | 结界 N |
| `seal_idx` | 修罗/明王/夜叉 封印 |
| `current_score` / `target_score` | 忍気 N / M |
| `gold` | 金币 $N |
| `owned_ninjas.size()` | 忍者 N 人 |

### 5.3 交互流

```
[繼續] click
  ├── 无存档 → ToastManager "没有可继续的存档"
  └── 有存档 → Overlay fade_in + ContinuePanel pop_in
        ├── [繼續冒險] → continue_run() + change_scene → Main
        ├── [返回] → fade_out + hide
        └── 点击遮罩 → 同 [返回]
```

---

## §6 字体与配色

### 6.1 旧 vs 新

| 项目 | 旧 (已废弃) | 新 (KUI 暖纸风) |
|------|-----------|----------------|
| 全局字体 | `vonwaon_bitmap_16px.ttf` | `manga_theme.tres` → LXGWWenKai-Medium |
| 标题色 | `(0.91, 0.77, 0.27)` 金色 | `(0.24, 0.17, 0.10)` 深褐 |
| info 色 | `(0.78, 0.78, 0.82)` 灰白 | `(0.48, 0.42, 0.35)` 暖棕 |
| 字号·标题 | 32px | 32px (不变) |
| 字号·按钮 | 24px | 24px (不变) |
| 字号·info | 20px | 20px (不变) |

### 6.2 Panel 内边距

PanelContainer 使用 `panel_beigeLight` `StyleBoxTexture` (9宫格) → patch_margin=8px。

### 6.3 按钮高度
ContinuePanel 里面的 继续冒险 按钮高度 48px

## §7 状态守卫

| 守卫 | 机制 | 位置 |
|------|------|------|
| 双击 | `_panel_open` bool | `_on_start_pressed` / `_on_continue_pressed` |
| 继续无档 | `has_saved_run()` 检测 + disabled 按钮 | `_update_continue_button()` |
| 违规牌组 | `PLAYABLE_DECKS.has()` 检测 | `_on_deck_card_clicked` |

---

## §8 与 Main 场景的衔接

```
Launch                            Main / CleanMain
  │                                 │
  ├─ start_new_run(deck_key, mode) → NinKingGameState 初始化
  │  change_scene_to_file()          game_manager._ready()
  │  ├─ "bi_ji"  → ninking_main.tscn     ├── 加载场景
  │  └─ "clean" → ninking_clean_main.tscn├── 发牌
  │                                       └── SEAL_INTRO → 0.5s → PLAYING
  │
  └─ continue_run() ──────────────→ NinKingGameState 恢复存档
     change_scene_to_file()          同 new run 但跳过初始化
     (仅比鸡模式, 消除模式无继续)
```

> **场景切换无过渡动画** — 当前 `change_scene_to_file` 是硬切。后期可加屏风转场 (V15)。

---

## §9 待实现

| # | 内容 | 优先级 |
|---|------|--------|
| 1 | 漫画风背景替换 — 当前用 FanKing `launch_bg.png` 占位 | P1 |
| 2 | 按钮漫画风重绘 — 当前复用 manga_theme StyleBox (V28 同步) | P1 |
| 3 | ~~DeckPanel / ContinuePanel 字体加载 pixel_theme~~ — ✅ 已修复 (manga_theme 统一) | ✅ |
| 4 | 暗夜/赤阳牌组解锁后移除置灰 — 待 Phase D 牌组系统 | D1 |
| 5 | 樱花粒子 → 漫画风粒子替换 (V26) | P1 |
