# 计分忍者触发动画设计（Phase G — 三幕式）

> **最后更新:** 2026-06-23 (v12 红色喜配色 + 暗底) | **实现文件:** `scripts/ninking/ui/animation_handler.gd` (~405 行) + `scripts/ninking/ui/xi_strike_overlay.gd`
> **基础设施:** `scripts/tween/tween_fx.gd` → `scripts/tween/global_tweens.gd`
> **数据源:** `scripts/ninking/score_calculator.gd` — `ninja_affected_groups()`
> **决策溯源:** 记忆 `scoring-ninja-trigger-animation-2026-06-15.md`（Grill 12 轮）+ review-plan 审阅

---

## 目录

1. [概述](#1-概述)
2. [核心流程](#2-核心流程)
3. [Phase 1：逐行揭示（影→瞬→滅）](#3-phase-1逐行揭示影瞬滅)
4. [Phase 2：列加分回放（左→中→右）](#4-phase-2列加分回放左中右)
5. [Phase 3：公式展示 & 喜×判定](#5-phase-3公式展示--喜判定)
6. [跳过机制](#6-跳过机制)
7. [忍者贡献计算](#7-忍者贡献计算)
8. [视觉反馈设计](#8-视觉反馈设计)
9. [时序总表](#9-时序总表)
10. [代码架构](#10-代码架构)
11. [维护指南](#11-维护指南)
12. [决策索引](#12-决策索引)

---

## 1. 概述

### 1.1 设计目标

在计分过程中，通过三幕式动画让玩家清晰感知三件事：

1. **每墩得分从何而来** — 筹码 × 倍率 = 乘积，分三步渐次揭示
2. **忍者牌何时生效** — 符合条件的忍者牌弹起 + 金框 + 飘字，直观展示"这张牌起作用了"
3. **全局乘算何时触发** — 喜（XI）伴随屏幕震动 + 粒子 + HitStop 强化冲击感

### 1.2 参考原型

借鉴 Balatro（小丑牌）的计分节奏：

- 手牌逐张翻牌 → 基础筹码/倍率 → 触发小丑依次弹跳 → 最终乘积 → 累计总分
- 保留 Balatro 的"先展示基础值 → 道具依次触发 → 乘积"三阶段结构
- 放慢节奏适配忍者主题（每次忍者触发 ~0.6s，让玩家看清牌面和数值变动）

### 1.3 三幕式结构

```
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase 4
 行×3      列×3        喜×         结果判定
 (影/瞬/滅) (左/中/右)  (全局×)    (过关/失败/继续)
```

每行/列内部为**二段式节奏**：
```
Stage 1: 基础筹码|倍率 ──→ Stage 2: 忍者依次触发 ──→ Stage 3: C×M=R 乘积
(0.35s)                    (N × 0.6s)                 (0.3~0.4s)
```

---

## 2. 核心流程

### 2.1 动画数据流

```
game_manager 调用 animation_handler.run_scoring()
    │
    ├─ 1. _compute_ninja_contributions(play_data)
    │     从 ScoreCalculator.ninja_affected_groups() 获取每张忍者影响的行组
    │     过滤 xi 条件未触发的忍者（R5 修复）
    │
    ├─ 2. Phase 1: 逐行（3 轮）
    │     │  Stage 1: 行高亮 + "筹码 X | 倍率 Y"（fade_in）
    │     │  Stage 2: 匹配忍者依次触发（color_flash + ninja_trigger + 飘字）
    │     │  Stage 3: "C × M = R"（scale_pop）+ 行名闪色 + 累计
    │     └─ 行间过渡: type_label color_flash 脉冲
    │
    ├─ 3. Phase 2: 逐列（3 轮）
    │     │  结构与 Phase 1 相同，但 ninja_contribs 按列过滤
    │     │  忍者动画**重播**（Q2 确认决策）
    │     └─ 庆祝 VFX: 同花+列触发 shuriken 粒子
    │
    ├─ 4. Phase 3: 全局喜×
    │     │  总分 = (行总分 + 列总分) × 喜乘积
    │     │  有全局× → 展示公式 + scale_pop + 金闪
    │     │  有喜触发 → HitStop + ScreenShake + shuriken 粒子 + Toast
    │     └─ 无喜 → 短暂停顿
    │
    └─ 5. Phase 4: 结果判定
          过关 → punch_in + sakura 粒子
          失败 → screen_shake + bg 闪红
          继续 → 短暂停顿后等待玩家操作
```

### 2.2 输入数据（play_data）

| 字段 | 类型 | 来源 | 用途 |
|------|------|------|------|
| `score_result` | `ScoreResult` | ScoreCalculator.calculate() | 行 chips/mult/score, 列 scores, 全局 xi |
| `xi_result` | `XiDetector.XiResult` | xi_detector | 触发喜列表、xi 条件忍者验证 |
| `head_eval/mid_eval/tail_eval` | `HandEvaluator3.EvalResult` | evaluate_hand_type3 | 牌型名称、行忍者匹配 |
| `col_evals` | `Array[EvalResult]` | game_manager 计算 | 列牌型名称、列庆祝条件 |

### 2.3 输出

- 更新所有计分标签到最终值
- 调用 `SealController.finalize_play()` 完成结算
- 销毁 `_skip_listener` 覆盖层
- 清空 `current_play_data`

---

## 3. Phase 1：逐行揭示（影→瞬→滅）

### 3.1 行内二段式节奏图

```
时间轴  0        0.35      0.35+N×0.6    0.35+N×0.6+0.4   0.35+N×0.6+0.75
         │         │           │              │               │
Stage    │── S1 ──►│── S2 ────►│── S3 ──────►│── 过渡 ──────►│
                    (N 张忍者)    (乘积)        (color_flash)  (下一行)
                         每张忍者 0.6s 内部:
                         │─ 弹起 ─│─ 停顿 ─│─ squash 落回 ─│
                         0.15s     0.2s      0.25s
```

> **无忍者行跳过规则（A3/A5 明确）:** Stage 1（基础值）和 Stage 3（乘积结果）**始终播放**，仅 Stage 2（忍者触发注入）在 `_contribs_for_row` 返回空数组时隐式跳过。行间过渡时间不变。

### 3.2 Stage 1：基础筹码 | 倍率

**代码位置:** `animation_handler.gd:195-210`

**流程:**
1. 行内 3 张牌 `color_flash(Color.GOLD, 0.35)` — 行高亮
2. `sl.text = ""` — 先设空文字，由 play_score 从 0 滚数（2026-06-23 删除了旧版 "0 x 0 = 0" 占位）
3. `fade_in(sl, 0.15)` — 渐入显示
4. `play_sfx(COUNT_TICK, 0.0, 0.9)` — 轻微偏高的计分音
5. `await _wait_or_skip(0.35)`

**base_chips[i]** 计算:
```
score_result.{head/mid/tail}_card_chips (单牌筹码)
  + score_result.{head/mid/tail}_hand_chips (牌型筹码)
  + score_result.{head/mid/tail}_ench_chips (附魔筹码)
```

**base_mult[i]** 计算:
```
score_result.{head/mid/tail}_hand_mult (牌型倍率)
  + score_result.{head/mid/tail}_ench_mult (附魔倍率)
```

### 3.3 Stage 2：忍者触发注入

**代码位置:** `animation_handler.gd:212-239`

**流程（每张匹配的忍者牌）:**

1. `_find_ninja_card(ninja_id)` → 定位忍者栏中的 `NinjaInventoryCard`
2. `color_flash(ninja_card, Color.GOLD, 0.3)` — 金框闪烁（0.3s）
3. `ninja_trigger(ninja_card)` — 弹起 → 停顿 → squash 落回（0.6s）

   > **ninja_trigger auto_kill domain: `"ninja"`** — 与 scale/position/modulate 隔离，不影响卡牌的悬浮 hover 动效。

4. `play_sfx(NINJA_ACTIVATE)` — 忍者激活音效

5. `await _wait_or_skip(0.05)` — 短暂延迟后飘字

6. `_float_ninja_text(ninja_card, chips, mult)` — 卡片上方生成浮动 "+N筹码  +M倍率"

7. 更新 **running_chips / running_mult**（累计值）

8. `sl.text = "[color=#588CF2]%d[/color] × [color=#E04040]%d[/color]" % [running_chips, running_mult]` — 实时更新

9. `scale_pop(sl, 1.15, 0.15)` — 标签跳动强调

10. `await _wait_or_skip(0.25)` — 每张忍者间隔

> **从 Stage 1 的 base_{chips,mult} 到 Stage 3 的 final_{chips,mult}:** 忍者贡献在 Stage 2 中逐个累加到 running_chips/running_mult 上。注意 Stage 3 直接使用 `final_{chips,mult}`（来自 `ScoreResult`），因 ScoreCalculator 已聚合所有忍者效果，running 值与 final 值始终一致。

### 3.4 Stage 3：乘积结果脉冲

**代码位置:** `animation_handler.gd:241-268`

1. `GlobalTweens.play_score(sl, dc, dm, dr, 1.2, _sfx_tick)` — 三段式滚动滚数（筹码蓝/倍率红，运算符×/= 及结果统一暖褐 `#7A5C3A`）
2. `scale_pop(sl, 1.2, 0.3)` — 放大脉冲
3. `play_sfx(GROUP_REVEAL)` — 组揭示音效
4. `type_label.text = hand_name` — 牌型名（对子/同花/...）
5. `color_flash(type_label, DUN_FLASH_COLORS[i], 0.25)` — 行名闪色

**第三行（滅）特殊处理:**
- `type_label` scale 1.5→1.0 SPRING 弹性放大（手写 `create_tween`）
- `burst_particles(manga_burst)` 粒子爆发

**累计更新（A5 补充）:**
- `current_cumulative += fs` — 总分累加
- `_ui.set_score_formula(current_cumulative, 0)` — 更新计分公式标签
- `scale_pop(_ui.score_label, 1.15, 0.3)` — 总分跳动
- `_tween_progress(bar, float(old_score + current_cumulative), 0.35)` — 进度条推进

### 3.5 行间过渡

**代码位置:** `animation_handler.gd:274-283`

```
当前行结束 → color_flash(当前行type_label, 0.15s)
           → await 0.15s
           → color_flash(下一行type_label, 0.25s)
           → await 0.2s
           → 下一行 Stage 1 开始
```

DUN_FLASH_COLORS: 影=冷蓝 `(0.3, 0.6, 1.0)` / 瞬=金色 `(1.0, 0.84, 0.0)` / 滅=火红 `(1.0, 0.2, 0.1)`

### 3.6 无忍者行的自动跳过

- `_contribs_for_row(ninja_contribs, i)` 返回空数组 → Stage 2 循环体 `for nc in row_ninjas` 不执行
- Stage 1 → 直接 → Stage 3，中间无延迟
- 行间过渡时间不变，保持节奏一致性

---

## 4. Phase 2：列加分回放（左→中→右）

### 4.1 列的计算与来源

**代码位置:** `animation_handler.gd:398-523`

列得分由 `game_manager` 在 `run_scoring()` 前计算，存入 `play_data["col_evals"]`。

列基础筹码（不带忍者加成）:
```
col_base_chips[i] = 列三张牌的单牌筹码之和 + 列牌型筹码（来自 CardData.get_hand_type3_leveled_chips）
```

列最终分:
```
col_final_scores[i] = score_result.col_scores[i]（已含忍者加成）
```

列倍率:
```
cm = CardData.get_hand_type3_leveled_mult(ct, gs.star_chart_levels)
```

### 4.2 忍者重播原则

**Q2 决策确认：** 列阶段**重新播放**忍者动画（即使行阶段已播过）。

原因：列得分是独立维度，玩家需要感知忍者对列的贡献。重播的是同一张忍者牌同一枚 effect，但动画效果相同（弹起 + 金框 + 飘字）。

列过滤与行过滤的差异：

```gdscript
# 行过滤（_contribs_for_row）:
#   匹配 groups 中包含当前行索引的忍者
def _contribs_for_row(contribs, row_idx):
    return [c for c in contribs if row_idx in c.groups]

# 列过滤（_contribs_for_column）:
#   匹配 economy 忍者 OR groups 包含所有 3 行
def _contribs_for_column(contribs):
    return [c for c in contribs if c.is_economy or len(c.groups) >= 3]
```

> 列仅重播全局忍者（影响所有行）和 economy 型忍者。组定向忍者（只影响影/瞬/滅中的某一行）在列阶段不会重播。

### 4.3 列庆祝 VFX 条件

以 `HandType3` 枚举值判断：`FLUSH_3`（同花）及以上牌型触发：
- `burst_particles(col_labels[i], "shuriken")`
- `color_flash(col_labels[i], Color(0.831, 0.659, 0.263), 0.2)` — 金色闪

---

## 5. Phase 3：喜 Strike Reveal — 三段式

> **v9 (2026-06-22):** 取消旧版 toast+粒子，改用全屏 `XiStrikeOverlay` 三段式动画。
> **v10 (2026-06-22):** Stage B 从逐个替换改为**累积式展示** — 喜名逐行堆叠在屏幕上，超过 4 个时最早喜折叠为 "+N 喜" 行。水印不再隐藏，淡化后持续呼吸作为背景层。
> **v12 (2026-06-23):** 喜配色从金色系改为红色系（喜文化主题色），新增半透明暗底隔离 table_bg 草地纹理，Tier 1-5 红色递进 + 暗红描边 + font_shadow 浮起效果。
> **实现文件:** `scripts/ninking/ui/xi_strike_overlay.gd` (`class_name XiStrikeOverlay extends Control`)

### 5.1 Xi 检测与触发

**代码位置:** `animation_handler.gd:285-371`

```
row_total = Phase 1 累计
col_total = score_result.col_total（列得分总和）
grand_total_before_xi = row_total + col_total

xi_product = score_result.global_xi_x_stack 的乘积（默认 1）
has_global_xi = xi_product > 1  （至少有一项喜产生全局乘法效果）
has_xi = xi_result.has_any()    （有喜条件触发，但不一定产生全局×）
```

> **规则：** 计分公式标签仅在 **`xi_product > 1`**（即有全局倍乘时）显示 `"总分 × N = 结果"`。无喜或 `xi_product == 1` 时只显示纯数字，**不会出现 `× 1`**。

**分支逻辑（A4 明确区分）:**

| 分支 | 视觉效果 | 适用场景 |
|------|---------|---------|
| `has_global_xi` (xi_product>1) | **三段式 XiStrikeOverlay** + 公式 `set_score_formula` + 进度条推进 | 四张、全黑、全红等全局喜生效时 |
| `!has_global_xi && has_xi` | 仅展示喜文本，不做公式 pop + 轻量 burst/shake | 三清、顺清打头等仅修饰性喜 |
| `!has_global_xi && !has_xi` | 0.3s 停顿后直接进入结果判定 | 无喜触发 |

### 5.2 XiStrikeOverlay — 三段式动画

`XiStrikeOverlay` 是一个固定 260×400 的 `Control`（z_index=15），位于 LeftPanel 与 DunArea 之间的间隙（screen x=485~745, y=420~820）。底部有一层 `ColorRect` 半透明暗底（`#0A0A14`, α=0.45, z=1）隔离 table_bg 草地纹理，确保文字可读性。overlay 自身作为容器，子元素以其左上 (0,0) 为原点。

#### 结构

```
XiStrikeOverlay (Control, z=15, fixed 260×400 at x=485~745, y=420~820)
├── [暗底 ColorRect] 黑 #0A0A14, α=0.45 (z=1)                 (v12 新增)
├── [溢出行 Label] "+N 喜" 24px 暗金红 (y=-2)                  (overflow, 可选)
│   ├── [行 Label] ×4 max: "{name}    ×{x_mult}" 34px (y=50~188)  (Stage B)
│   ├── [分割线 Label] "────────────" 16px 金属红 (y=225)      (Stage C 前)
│   └── [乘积 Label] "×N" 90px 炽白红+极黑边 (y=260)          (Stage C)
```

**Tier 映射（v12: 喜红色系 + 半透明暗底）:**

| x_mult | Tier | 喜名 & ×N 颜色 | 描边色 | 描边厚 | 阴影 |
|:------:|:----:|----------------|--------|:------:|:----:|
| ×2 | 1 | `#E84040` **朱砂红** | `#4A0A0A` 暗红棕 | 3px | ✅ |
| ×3 | 2 | `#F02828` **绯红** | `#5A0808` 暗红褐 | 4px | ✅ |
| ×4 | 3 | `#FF1A1A` **赤红** | `#6A0000` 深血红 | 5px | ✅ |
| ×5 | 4 | `#FF0A0A` **血焰红** | `#7A0000` 黑绛红 | 6px | ✅ |
| ×6+ | 5 | `#FF4444` **白炽红** | `#8A0000` 黑红 | 8px | ✅ |

> 所有行均添加 `font_shadow` (黑色 25%, offset 1px) 增强复杂纹理上的可读性。底部暗底 `Color(0.04, 0.04, 0.08, 0.45)` (z=1) 整体隔离 table_bg 草地/石板纹理。

#### 动画流程

```
Stage A — 喜気降臨 (~1.0s)
  ├─ "喜" 水印 280px 从 scale 3× crash-in → 1.0× (0.5s TRANS_BACK)
  ├─ modulate 0→0.35 红 (0.35s)
  ├─ do_hit_stop(0.06, 0.04) + screen_shake(0.08, 0.06)
  └─ watermark_breathe(Vector2(1.3, 1.3), 1.0) 循环呼吸

Stage A→B 过渡 — 水印淡化
  ├─ dim_watermark(): modulate 0.35→0.12 透明, scale 不变 (0.2s)
  └─ 水印继续保持呼吸循环作为背景层 (不销毁)

Overflow (可选, triggered>4时)
  ├─ 折叠行 "+N 喜" 从 x=260 快速滑入 (0.1s TRANS_QUAD)  [v11: 260 overlay]
  ├─ font_size=24, 暗金红 `#BF8050` + 棕黑描边, 无 tier 特效
  └─ 之后 animation_handler 只遍历最后 4 个喜

Stage B — 累积式展示 (~0.9s/行)
  ├─ 1. 累积行单 Label: "{name}    ×{x_mult}" 34px      [v11: 56→34px]
  │    颜色按 tier 分级, 整体从 x=260 滑入至左对齐 (0.35s TRANS_SPRING) [v11: 600→260]
  ├─ 2. Tier 特效 (hit-stop + shake + burst_particles + color_flash)
  │    依 tier 递增: 1(轻)→2(中)→3(强)→4(双重)→5(三重+全屏红闪)
  └─ 3. 脉冲回正: scale 1.1→1.0 (0.32s)
  └─ 已有行保持可见, 不消失, 新行加入时上方行不动

Stage C — 乘积衝擊 (~1.7s)
  ├─ 0. 分割线 "────────────" 从中心展开 (0.1s) [v11: 16px, 260px 宽]
  ├─ 1. ×N 从 scale 0.01→1.8 explode (0.25s TRANS_BACK) [v11: 2.2→1.8]
  ├─ 2. settle 1.8→1.0 (0.4s TRANS_SPRING) [v11: 适配窄框]
  ├─ 3. do_hit_stop(0.1, 0.04) + manga_burst + shake(0.2, 0.15)
  ├─ 4. 第二重 hit_stop(0.06, 0.04) + shake (强调)
  └─ 5. 最终脉冲 1.35→1.0 + gold_flash(0.6s) + hold
```

**Tier 冲击特效明细:**

| Tier | hit-stop | shake | particle | flash |
|:----:|:--------:|:-----:|:--------:|:-----:|
| 1 (×2) | 0.03/0.06 | 0.04/0.03 | manga_burst | — |
| 2 (×3) | 0.05/0.05 | 0.08/0.05 | manga_burst | — |
| 3 (×4) | 0.06/0.04 | 0.10/0.06 | shuriken | 橙红 0.15s |
| 4 (×5) | 0.06/0.04 + 0.04/0.04 双重 | 0.12/0.08 + 0.06/0.04 | shuriken | 红色 0.2s |
| 5 (×6+) | 三重 0.07→0.05→0.03 | 0.15→0.08→0.05 | shuriken | 全屏红闪 0.35s |

#### 代码摘要

```gdscript
# animation_handler.gd Phase 3 入口 (line 293)
if has_xi or has_global_xi:
    var xi_overlay := XI_STRIKE.new()
    _ui.get_parent().add_child(xi_overlay)
    xi_overlay.z_index = 15

    # Stage A — 喜気降臨
    play_sfx(SB.XI_TRIGGER)
    await xi_overlay.stage_a_buildup(tree)
    xi_overlay.dim_watermark()  # v10: 水印淡化保留

    # Overflow folding (v10)
    var max_show := 4
    if triggered.size() > max_show:
        xi_overlay.show_overflow(triggered.size() - max_show)
        triggered = triggered.slice(-max_show)

    # Stage B — 累积式展示
    for xi_name in triggered:
        await xi_overlay.stage_b_reveal(xi_name, x_m, tree)
        play_sfx(SB.XI_TRIGGER)
        _ui.set_score_formula(col_cumulative, show_product)

    # Stage C — 乘积衝擊
    play_sfx(SB.XI_FANFARE)
    await xi_overlay.stage_c_final(actual_product, tree)

    xi_overlay.queue_free()
```

### 5.3 组级喜特殊处理（无全局乘积时）

当只有组级喜（三清/三顺清/顺清打头/豹子）触发、无全局喜时，走轻量化分支：

```gdscript
play_sfx(SB.XI_FANFARE)
burst_particles(viewport_center, "manga_burst")
screen_shake(0.08, 0.06)
await 0.5s
```

### 5.4 Phase 4：结果判定

**代码位置:** `animation_handler.gd:378-401`

| 条件 | 视觉效果 | 后续行为 |
|------|---------|---------|
| `is_pass` (new_score ≥ target) | `play_sfx(SEAL_CLEAR)` + `burst_particles(sakura)` + `do_hit_stop(0.08, 0.05)` + `punch_in(score_label, 0.4, 1.5)` | 标记 `auto_shop_pending` → `finalize_play` → 自动过渡到商店 |
| `is_fail` (plays_remaining ≤ 1 && 未达标) | `play_sfx(SEAL_FAIL)` + `screen_shake(0.2, 0.12)` + `color_flash(game_bg, dark_red, 0.3)` | `finalize_play` → 失败结算 |
| 继续 | 0.4s 停顿 | `finalize_play` → PLAYING 状态 |

### 5.5 标签恢复

`_restore_type_labels()` 在 Phase 3 结束后执行：从 `_saved_original_texts` 恢复三墩牌型标签原文（计分动画中将标签替换为当前揭示的牌型名，结束后需要恢复）。

---

## 6. 跳过机制

### 6.1 设计原理

为缩短重复观看动画的等待，实现 **Balatro 风点击跳过**：玩家在计分动画的任何阶段点击或按键 → 立即跳转到最终结果 → 自动完成结算。

### 6.2 实现

**标志位:** `_skip_requested: bool`

**全屏监听:** `_create_skip_listener()`

```gdscript
var _skip_listener = Control.new()
_skip_listener.mouse_filter = MOUSE_FILTER_STOP
_skip_listener.anchor_right = 1.0
_skip_listener.anchor_bottom = 1.0
_skip_listener.gui_input.connect(_on_skip_input)
tree.root.add_child(_skip_listener)
```

- 透明覆盖层遮住整个视口
- 任何鼠标点击或键盘按键 → `_skip_requested = true`
- 计分动画结束时 `_remove_skip_listener()` → `queue_free()`

### 6.3 50ms 轮询

**代码位置:** `animation_handler.gd:84-94`

```gdscript
func _wait_or_skip(duration: float) -> void:
    if _skip_requested:
        return
    var elapsed: float = 0.0
    while elapsed < duration and not _skip_requested:
        await tree.create_timer(0.05).timeout
        elapsed += 0.05
```

用 50ms 粒度的循环替代 `await create_timer(duration).timeout`，保证跳过请求在 50ms 内被响应。每个动画阶段都以 `_wait_or_skip()` 替代定长等待。

### 6.4 _skip_and_finalize 完整路径

**代码位置:** `animation_handler.gd:99-113`

跳过时的完整路径：

```
_skip_and_finalize()
  ├─ _set_all_labels_final(sr)      — 所有计分标签设最终值
  │   行: "[color=#588CF2]%d[/color] × [color=#E04040]%d[/color] = %d" % [chips, mult, score]
  │   列: "+ %d" % col_scores[i]
  ├─ _ui.set_score_formula(...)      — 计分公式最终值
  ├─ _ui.update_score(...)           — 分数标签最终值
  ├─ _ui.progress_bar.value = ...    — 进度条直接跳转
  ├─ _restore_type_labels()          — 恢复牌型标签
  ├─ _remove_skip_listener()         — 清理覆盖层
  ├─ 判定 pass/fail/continue
  └─ _do_finalize()                  — 调用 SealController.finalize_play
```

> ⚠️ 跳过时**不播放**任何动效（包括 punch_in / shake / 粒子），仅统一设最终值。

---

## 7. 忍者贡献计算

### 7.1 _compute_ninja_contributions

**代码位置:** `animation_handler.gd:532-599`

遍历 `NinKingGameState.owned_ninjas` 中每张忍者牌：

1. 读取 `effect` 字典：`add_chips`、`add_mult`、`mult_per_gold`、`x_per_gold`
2. 跳过 chips≤0 且 mult≤0 且无经济效果的忍者
3. 调用 `ScoreCalculator.ninja_affected_groups()` 获取影响的行组（head/mid/tail → 索引 0/1/2）
4. 返回结构化数据：

```gdscript
{
    "id": String,           # 忍者 ID（如 "n_c01"）
    "chips": int,           # 筹码加成
    "mult": int,            # 倍率加成
    "groups": Array[int],   # 影响的行: [0] 影 / [1] 瞬 / [2] 滅 / [0,1,2] 全行
    "is_economy": bool,     # 纯经济型（无 chips/mult）
}
```

### 7.2 ninja_affected_groups 分组判定

**所在文件:** `scripts/ninking/score_calculator.gd`

通过 `effect` 的 `condition.group` 和当前墩的牌型（hand_type）判断忍者影响哪些行：

| condition.group | 匹配逻辑 |
|----------------|---------|
| `"head"` | 仅影响影组 |
| `"mid"` | 仅影响瞬组 |
| `"tail"` | 仅影响滅组 |
| `"head_or_mid"` | 分别检查影/瞬，各自满足条件的组生效 |
| 无 group 条件 | 影响全部三行 |

### 7.3 Xi 条件过滤（R5 修复）

**代码位置:** `animation_handler.gd:558-563`

某些忍者效果依赖喜触发条件（如 `condition.xi = "全黑"`）。在 _compute_ninja_contributions 中检查：

```gdscript
var xi_cond: String = effect.get("condition", {}).get("xi", "")
if xi_cond != "":
    var xi_res = play_data.get("xi_result")
    if xi_res == null or not xi_res.has_any() or xi_cond not in xi_res.triggered:
        continue  # xi 未触发 → 跳过这张忍者
```

### 7.4 _contribs_for_row vs _contribs_for_column 差异

| 函数 | 过滤规则 | 用于 |
|------|---------|------|
| `_contribs_for_row(contribs, row_idx)` | `row_idx in c.groups` | Phase 1 每行 Stage 2 |
| `_contribs_for_column(contribs)` | `c.is_economy` 或 `len(c.groups) >= 3` | Phase 2 每列 Stage 2 |

列阶段只重播**全局忍者**（影响全部三行）和**经济忍者**（无 chips/mult 但有视觉效果）。

---

## 8. 视觉反馈设计

### 8.1 ninja_pop_trigger 动效曲线（Balatro 风格打击感强化）

**代码位置:** `tween_fx.gd:542-593`

```
Phase 1 (0.00-0.10s): 弹起（snappy pop）
  scale: 1.0 → 1.35（EASE_OUT QUAD）
  position.y: 0 → -18（EASE_OUT QUAD，as_relative）
  rotation: 0 → +3°（EASE_OUT QUAD）
  └─ 并行，0.10s — 比旧版快 33%，幅度更大

Phase 2 (0.10-0.18s): 停顿 + 反向 wobble
  └─ 0.08s interval → rotation +3°→-2°（EASE_IN_OUT SINE, 0.07s）

Phase 3 (0.18-0.48s): 落回
  3a (0.18-0.26s): squash 压缩 scale 1.35→0.85（EASE_IN SINE, 0.08s）
  3b (0.26-0.48s): ELASTIC 弹性归位 scale 0.85→1.0（EASE_OUT ELASTIC, 0.22s）
                    + y 归位（EASE_OUT BACK, 0.22s）
                    + rotation 归零（EASE_OUT SINE, 0.18s）
  └─ 3a/3b 串行，3b 内部并行
```

**打击感强化要点：**
- 弹起幅度：scale +35%（原+20%），Y偏移 +80%（-18px vs -10px）
- 新增 rotation wobble ±3° 模拟卡牌被"打"了一下的冲击感
- squash 压缩更深 0.85（原0.92），回弹用 ELASTIC 替代 BACK 获得更Q弹的归位感
- 触发顺序：白闪(0.06s) → 金闪(0.35s) → ninja_trigger → screen_shake(0.04) → sparkle粒子 → 音效 → 飘字

**auto_kill domain:**
- domain: `"ninja"`（与 `"scale"`/`"position"`/`"modulate"`/`"rotation"` 隔离）
- 不会影响其他子系统（card_hover、pulse 等）对 node 的补间

### 8.2 白闪→金框闪烁（Balatro 风 hi█████）

- **白闪 (0.06s):** `color_flash(ninja_card, Color.WHITE, 0.06)` — 极短白闪模拟"打中"瞬间
- **间隔 0.04s** 后接金闪：`color_flash(ninja_card, Color.GOLD, 0.35)` — 金色渐退
- 白闪与 Phase 1 弹起重叠，玩家先看到白闪（0-0.06s）→ 卡牌已弹到峰值 → 金闪渐退（0.1-0.45s）
- 配合 `screen_shake(0.04, 0.02)` + `burst_particles("sparkle")` 形成完整打击反馈

### 8.3 浮动数字文本

**代码位置:** `animation_handler.gd:636-664`

```gdscript
# 组装文本
chips > 0  → "+N筹码"
mult  > 0  → "+M倍率"
both > 0   → "+N筹码  +M倍率"
none > 0   → "触发!"

# 样式
font_size: 16px
color: Color(1.0, 0.84, 0.0)  # 金色
alignment: center

# 位置
position: ninja_card.global_position + (card_size.x/2 - 60, -30)
         # 卡片上方居中

# 动画
GlobalTweens.float_up(floater, -40.0, 0.8)
```

> **修复记录 R1:** 原代码将 floater 添加到 `scene_tree.root`（z-index 1000+），遮挡了其他 UI。修复为添加到 `_ui`（UIManager），保证正确叠层。

### 8.4 总分飘字

**代码位置:** `animation_handler.gd:721-735`

Phase 1 结束后（R3 修复新增）和 Phase 2 结束后，在 `score_label` 位置生成总分飘字：

```gdscript
var floater := Label.new()
floater.text = "+ %d" % gain
font_size: 36px
color: barrier_color（跟随结界主题色）
animation: Y -60px over 1.0s + modulate.a 1.0→0.0 at 0.2s delay → queue_free
```

### 8.5 BBCode 计分文本颜色

**场景中所有计分标签（`ShadowScore` / `FlashScore` / `DestroyScore` / `left_col_score` / `mid_col_score` / `right_col_score`）均为 `RichTextLabel`，已启用 `bbcode_enabled = true`。**

计分动画的 Stage 1/2/3 文本使用 BBCode 颜色标签区分筹码与倍率：

| 值 | 颜色 | 色码 | 来源 |
|----|------|------|------|
| 筹码 (chips) | 蓝 | `#588CF2` | `count_up.gd` `CHIPS_COLOR` |
| 倍率 (mult) | 红 | `#E04040` | `count_up.gd` `MULT_COLOR` |
| 运算符 (x/=) | 暖褐 | `#7A5C3A` | `count_up.gd` `OP_COLOR` -- 2026-06-23 新增，在米色面板上可见 |
| 乘积 (score) | 暖褐 | `#7A5C3A` | 同上 `OP_COLOR` -- 旧版默认白色，在米色面板不可见 |

**文本格式：**
```
[color=#588CF2]{chips}[/color] [color=#7A5C3A]x[/color] [color=#E04040]{mult}[/color]      <- Stage 1/2
[color=#588CF2]{chips}[/color] [color=#7A5C3A]x[/color] [color=#E04040]{mult}[/color] [color=#7A5C3A]= {score}[/color]  <- Stage 3 (2026-06-23: ops+score unified warm brown)
```

**适用范围：**
- 行 Phase 1: `sl.text` (Stage 1/2/3) — `animation_handler.gd:207,238,249`
- 列 Phase 2: `csl.text` (Stage 1/2/3) — `animation_handler.gd:457,482,491`
- 跳过最终态: `_set_all_labels_final` — `animation_handler.gd:704`

### 8.6 左对齐 & 从左到右视觉流

**场景设置：** 行/列共 6 个计分 RichTextLabel（`ShadowScore` / `FlashScore` / `DestroyScore` / `LeftColScore` / `MidColScore` / `RightColScore`）均设 `horizontal_alignment = 0`（左对齐）及 `normal_font_size = 20`。

> **2026-06-15 放大调整:** 计分面板统一放大字号并收回右侧空隙以提高可读性。
>
> | 项 | 改前 | 改后 |
> |---|---|---|
> | `HandTypeVBox.offset_right` | -200 (内容~272px) | **-130** (内容~342px) |
> | 墩名/列名字号 | 20px | **22px** |
> | 牌型名字号 | 20px | **22px** |
> | 等级字号 | 16px | **18px** |
> | 计分字号 | 默认(~16) | **20px** |
> | 计分 min_width | 130px | **170px** |
>
> 渐隐渐变 `fade_start = 0.72`（≈345.6px），改后内容右缘 350px 处 alpha≈97%，无实质影响。

**设计意图：** 计分动画阶段的数字增长方向应与阅读方向一致 —— 从左到右。

```
Stage 1         Stage 2 (忍者触发时)     Stage 3
30 × 4    →     45 × 4  →  60 × 4   →   60 × 4 = 240
└─ 数值增大时右向延伸 ──┘               └─ 乘积追加在最右
```

- **Stage 1→2**：筹码值在 `×` 左侧增大，文本向右延伸（而非右对齐时的向左延伸）
- **Stage 3**：`= {result}` 追加在最右侧，视觉终点在乘积结果
- 与右对齐相反（右对齐时数字增大会向左扩，感觉"从右往左增加"）

**场景文件：** `ninking_main.tscn` 行424,457,490 / 列532,566,600 · `debug_ninking_main.tscn` 行332,365,398 / 列440,474,508

---

## 9. 时序总表

> 以下为**最慢路径**（3 行各有忍者触发 + 3 列全部同花+ + 喜触发）。实际时长取决于忍者数量。

### 各阶段时长

| 段 | 内容 | 最短 | 最长 | 说明 |
|----|------|------|------|------|
| 启动 | 初始停顿 | 1.2s | 1.2s | |
| **Phase 1 行×3** | | **(3.5s)** | **(6.5s)** | |
| 行_i Stage 1 | fade_in + 等待 | 0.35s | 0.35s | 必有 |
| 行_i Stage 2 | 每张忍者 0.6s | 0s | N × 0.6s | 跳过时不执行 |
| 行_i Stage 3 | scale_pop + type_label | 0.4s | 0.4s | 必有 |
| 行_i 过渡 | 2 行间一闪 | 0.35s | 0.35s | 前 2 行才有 |
| 行后 | 总分飘字 | 0.1s | 0.1s | |
| **Phase 2 列×3** | | **(1.6s)** | **(3.0s)** | |
| 列_i Stage 1 | fade_in + 等待 | 0.3s | 0.3s | |
| 列_i Stage 2 | 忍者重播 | 0s | M × 0.6s | 列仅全局忍者 |
| 列_i Stage 3 | 乘积 + 累计 | 0.3s | 0.3s | |
| 列后 | 总分飘字 | 0.1s | 0.1s | |
| **Phase 3 喜三段式** | | **(1.5s)** | **(3.8s)** | |
| A 喜気降臨 | watermask crash-in + 呼吸 → 水印淡化 | 1.0s | 1.0s | 仅 `has_xi` |
| A→B 溢出折叠 | "+N 喜" 快速滑入 | 0s | 0.1s | 仅 triggered>4 时 |
| B 累积行展示 | 每行 ~0.9s (滑入+tier特效+脉冲) | 0s | min(K,4) × 0.9s | K=触发喜数, 只展示最后 4 个 |
| C 乘积衝擊 | 分割线 + ×N explode + 脉冲 | 0s | 1.7s | 仅 `xi_product>1` |
| 组级喜轻量 | burst + shake | 0s | 0.5s | 仅组级喜 |
| 公式更新 + 停顿 | set_score_formula | 0.5s | 0.5s | |
| **Phase 4** | | **(0.8s)** | **(0.8s)** | |
| 过关VFX | punch_in + 粒子 | 0.8s | 0.8s | |
| 失败VFX | shake + 闪红 | 0.8s | 0.8s | |
| **合计** | | **~7.5s** | **~15s** | |

### 跳过时长

跳过时仅执行 `_skip_and_finalize()`，路径无任何 `_wait_or_skip` 等待，总耗时 <0.1s（设置标签 + 清理 + finalize_play）。

---

## 10. 代码架构

### 10.1 AnimationHandler 职责与生命周期

**类:** `class_name AnimationHandler extends RefCounted`

**定位:** C21 从 `game_manager.gd` 拆出的计分动画委托（`game_manager` 599→275 行，拆分后 `animation_handler.gd` 238→780 行）。

**生命周期:**

```gdscript
# game_manager.gd 中:
var _anim_handler: AnimationHandler = AnimationHandler.new()

func _ready():
    _anim_handler.setup(ui, _mark_auto_shop)

# 计分时:
func _on_play():
    # ... 计算 play_data ...
    _anim_handler.current_play_data = play_data
    await _anim_handler.run_scoring()
    # score_result 已应用，finalize_play 已调用
```

**成员变量一览:**

| 变量 | 类型 | 用途 |
|------|------|------|
| `_ui` | `UIManager` | UI 节点引用（注入） |
| `current_play_data` | `Dictionary` | 每轮计分的完整数据 |
| `_mark_auto_shop` | `Callable` | 设置 game_manager 的 auto_shop 标记 |
| `_skip_requested` | `bool` | 跳过标志 |
| `_skip_listener` | `Control` | 全屏跳过覆盖层 |
| `_saved_original_texts` | `Array[String]` | 计分前保存的牌型标签文本 |
| `SFX_TICK` | `Callable` | count-up 音效回调 |

**Xi Strike Overlay (v9 新增):**

| 临时对象 | 类型 | 用途 |
|----------|------|------|
| `XI_STRIKE` | `GDScript` | `preload("xi_strike_overlay.gd")` 静态引用 |
| `xi_overlay` | `XiStrikeOverlay` | Phase 3 运行时创建，动画结束后 `queue_free` |

**注：** 作为 `RefCounted`，AnimationHandler **不是 Node**，不参与场景树。其子函数创建的临时节点（飘字 Label、XiStrikeOverlay 等）通过 `_ui.add_child()` 或 `_ui.get_parent().add_child()` 挂入场景树，由 Tween 的 `queue_free` 自行清理。

### 10.2 TweenFX / GlobalTweens 新增函数

**TweenFX** (`scripts/tween/tween_fx.gd:542-586`):

```gdscript
static func ninja_pop_trigger(node: Node, duration: float = 0.6, auto_kill: bool = true) -> Tween
```

**GlobalTweens** (`scripts/tween/global_tweens.gd:122-125`):

```gdscript
func ninja_trigger(node: Node, duration: float = 0.6, auto_kill: bool = true) -> Tween:
    return FX.ninja_pop_trigger(node, duration, auto_kill)
```

**详见 `docs/tween-library-reference.md` §2.8 忍者触发**。

### 10.3 与 ScoreCalculator 的协作

AnimationHandler 与 ScoreCalculator 的交互仅限于 **数据读取**，不修改任何计分逻辑：

```
ScoreCalculator.calculate(play_data) → ScoreResult
  └─ animation_handler 读取: score_result.{head,mid,tail}_{chips,mult,score}
                            score_result.col_scores
                            score_result.global_xi_x_stack

ScoreCalculator.ninja_affected_groups(effect, ...) → Array[String]
  └─ animation_handler._compute_ninja_contributions() 调用
```

> ⚠️ 注意：AnimationHandler **不调用** `ScoreCalculator.collect_ninja_per_group()`——它通过 `ninja_affected_groups()` 确定**每组有哪些忍者受影响**，然后直接从 ninja `effect` 字典读取 chips/mult 值（因为动画仅需展示加成量，而非实际参与计分运算）。

---

## 11. 维护指南

### 11.1 修改信号/状态机/数值的注意事项

1. **AnimationHandler 不是 Node** — 不要直接 `add_child()` 或 `scene_tree` 引用。它的生命周期由 game_manager 控制。

2. **信号重入** — AnimationHandler 的 `run_scoring()` 全部 await 驱动。game_manager 在计分进入 `_on_state_changed` SCORING 分支后等待 await 完成。**不要在计分动画期间切换状态**。

3. **`_wait_or_skip` 与 `await` 混合** — 所有时序都必须用 `_wait_or_skip()` 替代 `await create_timer()`。直接 `await timer` 会丢失跳过能力。

4. **`_skip_and_finalize` 的 `return`** — 每个 `if _skip_requested:` 检查后必须 `_skip_and_finalize()` + `return`，不能裸 `return`（R2/R3 修复历史）。

5. **场景切换的时序** — `_skip_listener` 挂载到 `tree.root`，场景切换会销毁。AnimationHandler 不感知场景生命周期，如果计分动画被场景切换打断，`_remove_skip_listener()` 中的 `is_instance_valid` 守卫会静默处理。

### 11.2 新增忍者触发类型的步骤

如果未来需要新增一种忍者触发动画（不仅是当前的弹起 + 金框 + 飘字）：

1. **TweenFX 新增函数** — 如果动效通用，在 `tween_fx.gd` 新建静态函数
2. **GlobalTweens 新增委托** — 添加入口方法暴露给外部
3. **tween-library-reference.md 同步** — 更新场景速查表 + 新函数文档
4. **AnimationHandler 调用点** — 在 `_run_scoring_animation` Phase 1/2 的 Stage 2 循环体中插入新调用
5. **`_skip_and_finalize` 检查** — 确保新动效不会导致跳过路径遗漏（跳过应直接设终值，不播动画）

### 11.3 调试技巧

**G8（未实现）：** Phase 1/2/3 快速跳转快捷键（按 1/2/3 跳到对应幕）。

**当前可用的调试手段：**

- **跳过动画：** 计分过程中单击鼠标或按任意键，直接跳转到最终结果
- **Debug 场景：** 在 Launch 场景右下角点 "Debug" 进入 `debug_ninking_main.tscn`，选择牌型 + 忍者 + 星图等级后点「討伐」触发计分
- **日志调试：** 在 `_compute_ninja_contributions()` 入口加 `print()` 跟踪忍者匹配情况
- **手动触发计分：** Godot 编辑器中执行 `run_scoring()` 前在 `_wait_or_skip` 中设断点观察动画时序

### 11.4 已知限制

| 限制 | 说明 | 可能的影响 |
|------|------|-----------|
| **`_held_cards` 私有成员访问** | `_find_ninja_card()` 访问 card-framework 的 `_held_cards`（私有）| 当前在 SCORING 状态下安全（拖拽状态机不活跃），但 if `card-framework` 重构可能需要适配 |
| **忍者贡献不追踪动画进度** | `_compute_ninja_contributions()` 每次 run_scoring 只调用一次，预计算全部贡献 | 动画中途中忍者的数值变化不会被反映 |
| **简单跳过 = 无动效** | 跳过时所有动效被跳过，直接设终值 | 玩家会错过动画体验，但游戏逻辑不受影响 |
| **Phase 2 列分的近似计算** | `_run_phase2_columns` 中的 `col_base_chips[i]` 手工计算（不含列忍者），仅用于动画展示 | 动画数字与最终 `col_final_scores[i]` 可能有微小差异（忍者加成累积），但最终乘积使用最终分，正确性不受影响 |
| **Phase 2 倍率取基础值** | `cm = CardData.get_hand_type3_leveled_mult(...)` 不含忍者加乘 | 与上面相同，仅动画展示的"倍数"可能是基础值，但乘积结果是最终计算值 |
| **NINJA_ACTIVATE 音效重复** | R6 已修复：Phase 2 末尾去掉了重复的 `play_sfx(NINJA_ACTIVATE)` | 每个忍者触发时播放一次，不再行/列结束时重复播放 |

---

## 12. 决策索引

### Grill 决策记录

| 决策 | 问题 | 结果 | 参考 |
|------|------|------|------|
| Q1 | 每行是否触发所有匹配忍者？ | **是** — 每行 Stage 2 循环触发 | `animation_handler.gd:216-239` |
| Q2 | 列阶段是否重播忍者动画？ | **是** — 与行阶段相同的 ninja_trigger | `animation_handler.gd:461-478` |
| Q3 | 跳过时是否播放忍者动画？ | **否** — 跳过直接设终值 | `_skip_and_finalize()` 不播动画 |

### 相关 TODO 任务

| 任务 | 说明 | 状态 |
|------|------|------|
| G1 | AnimationHandler Phase 1 重写为二段式 + 忍者触发 | ✅ |
| G2 | 跳过机制实现（_wait_or_skip + _skip_and_finalize） | ✅ |
| G3 | Phase 2 列加分对齐二段式 + 忍者重播 | ✅ |
| G4 | 行间过渡 color_flash 脉冲 | ✅ |
| G5 | TweenFX.ninja_pop_trigger() 组合动画 | ✅ |
| G6 | GlobalTweens.ninja_trigger() 入口委托 | ✅ |
| G7 | tween-library-reference.md 同步 | ✅ |
| G8 | 调试快捷键 1/2/3 跳转 | ⬜ |

### Code Review 修复记录

| 修复 | 问题 | 解决 |
|------|------|------|
| R1 | 飘字被遮挡（挂到 scene_tree.root） | 改为 `_ui.add_child(floater)` |
| R2 | `_sfx_tick` 死代码 | 删除 |
| R3 | 总分飘字缺失 | Phase 1 结束后补充 _float_score_gain |
| R4 | 访问私有 `_held_cards` 无注释 | 加说明（SCORING 态安全） |
| R5 | xi 条件忍者无条件播动画 | 加 xi_result 验证 |
| R6 | NINJA_ACTIVATE 音效重复 | Phase 2 末尾去重 |

### 相关文件索引

| 文件 | 定位 | 关键行数 |
|------|------|---------|
| `scripts/ninking/ui/animation_handler.gd` | 实现主体 | ~780 行 |
| `scripts/tween/tween_fx.gd` | ninja_pop_trigger() | 542-586 行 |
| `scripts/tween/global_tweens.gd` | ninja_trigger() 委托 | 122-125 行 |
| `scripts/ninking/score_calculator.gd` | ninja_affected_groups() 数据源 | — |
| `docs/tween-library-reference.md` | §2.8 忍者触发文档 | §2.8 |
| `docs/ninking/TODO.md` Phase G | 任务状态 | G1-G8 |
| 记忆: `scoring-ninja-trigger-animation-2026-06-15.md` | Grill 决策树 | 12 轮 |

---

> **相关文档:** [TODO.md](TODO.md) | [tween-library-reference.md](../tween-library-reference.md) | [TweenFX 源码](../../scripts/tween/tween_fx.gd) | [AnimationHandler 源码](../../scripts/ninking/ui/animation_handler.gd)
