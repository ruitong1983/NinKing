# NinKing Main Overlay 设计方案

> **建立日期:** 2026-06-10 | **关联场景:** `ninking_main.tscn` 子节点
> **风格权威:** [`../05-art/16-art-direction-principles.md`](../05-art/16-art-direction-principles.md) · 少年漫画风

## §1 概述

Main 场景内嵌 5 个覆盖层，各自对应一个游戏状态。它们通过 `ui_manager.show_view()` 互斥显示。

```
GameLayout (主游戏)
  visible = false → LevelIntro (关卡入场)
  visible = true  → PLAYING 交互
    └── 出牌 → ScoringOverlay (计分动画)
         └── 判定 ─┬→ LevelComplete (过关) → [商店]
                   ├→ GameOver (失败) → [重试] / [返回主菜单]
                   └→ VictoryOverlay (全通关) → [返回主菜单]
```

---

## §2 覆盖层一览

| 覆盖层 | 触发时机 | 可见后状态 | 退出 |
|--------|---------|-----------|------|
| LevelIntro | 新封印开始 | SEAL_INTRO → 2s → PLAYING | 自动 |
| ScoringOverlay | [討伐] 点击 | SCORING → A7 逐墩动画 | 动画结束 |
| LevelComplete | 忍気 ≥ 封印 (非最终) | 过关停留 | [商店] → shop.tscn |
| GameOver | 讨伐次数耗尽且忍気不足 | 失败停留 | [重试] / [返回主菜单] |
| VictoryOverlay | 最終封印突破 (VICTORY) | 通关停留 | [返回主菜单] → Launcher |

---

## §3 LevelIntro — 关卡入场

### 3.1 布局

```
┌──────────────────────────────────────────┐
│                  全屏黑底 (80% opacity)    │
│                                          │
│         結界3 · 明王ノ封印                 │  ← LevelLabel 48px 金色 居中
│                                          │
│    封印 450 | 封印ノ主: 夜叉丸             │  ← TargetLabel 24px 灰白 居中
│                                          │
└──────────────────────────────────────────┘
```

### 3.2 结构

```
LevelIntro (Control 1920×1080)
├── IntroOverlay (ColorRect 1920×1080)   ← 黑底 80%
├── LevelLabel (Label 640×80)           ← "結界N · X封印" 居中
└── TargetLabel (Label 640×40)           ← "封印 N | 封印ノ主: ..." 居中
```

### 3.3 动画

| 阶段 | 方式 | 说明 |
|------|------|------|
| 进入 | `LevelIntro.visible = true` | SEAL_INTRO 状态 |
| Boss 出场 | `GlobalTweens.scale_pop(TargetLabel, 1.2, 0.3)` + 1s 停留 | 有封印ノ主时触发 |
| 等待 | `await _intro_timer()` (2.0s) | game_manager 中 |
| 退出 | `GameLayout.visible = true` | LevelIntro 隐藏 |

### 3.4 当前状态

> **Boss 出场动画已实现** — `_on_seal_started()` 中检测 `seal_lord_name != ""` → `scale_pop`。通用入场动画（墨字浮现 → 属性色炸裂）待 V14 漫画风重设计。

---

## §4 ScoringOverlay — 计分动画

### 4.1 布局

```
┌──────────────────────────────────────────┐
│                  全屏黑底 (70% opacity)    │
│                                          │
│    影: 同花顺 | 瞬: 对子 | 滅: 散牌       │  ← HandNameLabel 48px 白 (三墩汇总)
│                                          │
│                      + 450               │  ← ScoreValueLabel 72px 金
│                                          │
│             筹码 150 × 倍率 3             │  ← ScoreBreakdown 24px
│                                          │
└──────────────────────────────────────────┘
```

### 4.2 结构

```
ScoringOverlay (Control 1920×1080)
├── OverlayBg (ColorRect)              ← 黑底 70%
├── HandNameLabel (Label 640×60)       ← 三墩牌型汇总 "影:X | 瞬:Y | 滅:Z"
├── ScoreValueLabel (Label 640×80)     ← "+ N"
└── ScoreBreakdown (Label 640×40)      ← 筹码×倍率 详细
```

### 4.3 动画流程 (A7)

```
Phase 1: 逐墩揭示 (影→瞬→滅, 间隔 0.55s)
  For each dun:
    - dun_type_label.visible = true
    - text = "影/瞬/滅: <牌型名>"
    - GlobalTweens.scale_pop(label, 1.15, 0.25)
    - _flash_dun(i) — color_flash 该墩所有卡牌 (0.1s 金色)
    - await 0.55s

  → ui.show_scoring_result(head, mid, tail, total) — HandNameLabel 三墩汇总
  → await 0.3s

Phase 2: 总分 CountUp
  - CountUp.play(score_label, old→new, 0.5s, "忍気 ")
  - ScoreBreakdown: "筹码 N × 倍率 M" + 列分详情
  - Column VFX: col ≥ 同花顺 → shuriken burst + color_flash
  - await 0.65s

Phase 3: 喜触发
  - burst_particles + hit_stop + screen_shake
  - ScoreBreakdown 追加 "喜: ..."
  - await 0.5s

Phase 4: 判定
  - pass → sakura burst + punch_in → LevelComplete
  - fail → screen_shake + red flash → GameOver
  - 继续 → fade_out scoring_overlay → PLAYING
```

### 4.4 粒子效果

| 事件 | 粒子 | 备注 |
|------|------|------|
| 逐墩揭示 | color_flash (金色) | 单墩卡牌闪烁 |
| 列分庆祝 | shuriken burst | 漫画风后替换为 manga_ink (V26) |
| 喜触发 | shuriken burst + hit_stop | 漫画风后替换为 manga_burst (V26) |
| 过关 | sakura burst + punch_in | — |

---

## §5 LevelComplete — 过关

### 5.1 布局

```
┌──────────────────────────────────────────┐
│                  全屏黑底 (70% opacity)    │
│                                          │
│                过关！                     │  ← CompleteLabel 48px 金
│                                          │
│            +N 金币                        │  ← RewardLabel
│                                          │
│              [商店]                       │  ← ToShopButton
│                                          │
└──────────────────────────────────────────┘
```

### 5.2 结构

```
LevelComplete (Control 1920×1080)
├── OverlayBg (ColorRect)
├── CompleteLabel (Label 640×70)        ← "过关!"
├── RewardLabel (Label)                 ← "+N 金币"
└── ToShopButton (Button)              ← "商店"
```

### 5.3 交互

| 操作 | 结果 |
|------|------|
| [商店] | `GlobalTweens.fade_out(ui, 0.3)` → `change_scene_to_file("shop.tscn")` |

> **注意:** Victory (全通关) 不走 LevelComplete，走专属 `VictoryOverlay`。

---

## §6 GameOver — 失败

### 6.1 布局

```
┌──────────────────────────────────────────┐
│                  全屏黑底 (70% opacity)    │
│                                          │
│                忍気不足                   │  ← GameOverLabel
│                                          │
│          战绩: 结界 3 · 忍気 380          │  ← ScoreSummary
│                                          │
│          [重试]      [返回主菜单]          │
│                                          │
└──────────────────────────────────────────┘
```

### 6.2 结构

```
GameOver (Control 1920×1080)
├── OverlayBg (ColorRect)
├── GameOverLabel (Label)              ← "忍気不足" / "封印失败"
├── ScoreSummary (Label)               ← 战绩摘要
├── RetryButton (Button)              ← "重试"
└── BackToMenuButton (Button)         ← "返回主菜单"
```

### 6.3 永久死亡 (A8)

| 操作 | 结果 |
|------|------|
| 失败触发 | `SaveManager.record_run_result("lost")` + `delete_run()` |
| [重试] | `start_new_run("standard")` + `change_scene` → Main |
| [返回主菜单] | `change_scene` → Launcher |

> **无「继续」— 永久死亡**。失败后只能新游戏或退出。checkpoint 在封印开始时保存，失败即清除。

---

## §7 VictoryOverlay — 通关

### 7.1 布局

```
┌──────────────────────────────────────────┐
│                  全屏黑底 (70% opacity)    │
│                                          │
│              忍道制霸!                    │  ← VictoryLabel 48px 金
│                                          │
│    通关! 全8 结界制霸 · 忍気 2400         │  ← StatsSummary
│                                          │
│            [返回主菜单]                    │  ← MenuButton
│                                          │
└──────────────────────────────────────────┘
```

### 7.2 结构

```
VictoryOverlay (Control 1920×1080)
├── OverlayBg (ColorRect)
├── VictoryLabel (Label)               ← "忍道制霸!"
├── StatsSummary (Label)               ← "通关! 全N 结界制霸 · 忍気 M"
└── MenuButton (Button)                ← "返回主菜单"
```

### 7.3 交互

| 操作 | 结果 |
|------|------|
| [返回主菜单] | `change_scene` → Launcher |

### 7.4 实现

| 方法 | 位置 | 说明 |
|------|------|------|
| `ui.set_victory(barrier, score)` | `ui_manager.gd:337` | 设 VictoryLabel + StatsSummary 文本 |
| `ui.show_view("victory")` | `ui_manager.gd:157` | 显示 VictoryOverlay |
| `_on_back_to_menu_pressed()` | `game_manager.gd:192` | MenuButton 信号 → Launcher |

---

## §8 视觉层级

```
layer 0: GameBg (背景, ColorRect)
layer 1: GameLayout (游戏 UI, HBoxContainer)
layer 2: LevelIntro (入场覆盖层)
layer 3: ScoringOverlay (计分覆盖层)
layer 4: LevelComplete (过关覆盖层)
layer 5: GameOver (失败覆盖层)
layer 6: VictoryOverlay (通关覆盖层)
```

所有覆盖层通过 `visible` 互斥。`ui_manager.gd:show_view()` 管理显示/隐藏切换。

---

## §9 待实现

| # | 内容 | 优先级 |
|---|------|--------|
| 1 | LevelIntro 漫画风入场动画（墨字浮现 → 属性色炸裂 → 集中线收束） | P1 |
| 2 | ScoringOverlay 漫画粒子替换（shuriken/sakura → manga_ink/manga_burst, V26） | P1 |
| 3 | LevelComplete 屏风转场增强（V15: logo 遮罩版 fade） | P3 |
| 4 | GameOver 战绩统计面板美化（当前为简单 Label） | P2 |
| 5 | 覆盖层间过渡动画（当前 visible 硬切） | P2 |
| 6 | VictoryOverlay 通关粒子庆祝（全屏 sakura + 墨字特效） | P2 |
