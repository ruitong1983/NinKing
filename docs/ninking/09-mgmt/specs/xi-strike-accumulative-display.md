# 喜 Strike 动画累积式展示 — 实现方案

> 版本: v2 | 日期: 2026-06-23 | 状态: 已实施

## 1. 改动范围

| 文件 | 改动量 | 说明 |
|------|--------|------|
| `scripts/ninking/ui/xi_strike_overlay.gd` | ~+20 行 | v12: 金色→红色系配色, 新增半透明暗底, font_shadow |
| `scripts/ninking/ui/animation_handler.gd` | 无改动 | — |
| `docs/ninking/04-ui/24-scoring-ninja-animation.md` | ~+10 行 | §5.2 色表同步 |

## 2. 最终设计

### 2.1 展示布局

```
 center_box (600×400, z=1)

  喜 (水印 alpha=0.12, scale=0.8, 持续呼吸)
  
  +3 喜              ← 溢出折叠行 (Stage A 结束后 0.1s 闪入, 无 tier 特效)
  
  均爵    ×3         ← Row 0 (y=-75)
  三等    ×5         ← Row 1 (y=-10)
  慢打    ×5         ← Row 2 (y=55)
  四对半  ×4         ← Row 3 (y=120)
  ──────────         ← 分割线 (y=170)
    ×7200            ← 乘积 (y=190~290) Stage C
```

### 2.2 流程

```
Stage A (不变)
  ├─ "喜" 280px 从 3× crash-in → 1.0, modulate alpha 0→0.35
  ├─ do_hit_stop(0.06) + screen_shake(0.08)
  └─ watermark_breathe(1.3, 1.0) → 持续呼吸

Stage A→B 过渡 (微调)
  最多同时展示行数 MAX_ROWS = 4
  ├─ if triggered.size() > MAX_ROWS:
  │    ├─ 溢出数 = triggered.size() - MAX_ROWS
  │    ├─ 水印淡化 (alpha=0.12, scale=0.8, 保持呼吸)
  │    └─ 溢出行 "+{N} 喜" 从右滑入 (0.1s, 无特效)
  └─ else:
       └─ 水印淡化 (alpha=0.12, scale=0.8, 保持呼吸)

Stage B (重写)
  只遍历 triggered 数组的最后 MAX_ROWS 个
  ├─ 每行: 名字 + ×N 作为整体从右侧滑入 (0.35s SPRING)
  ├─ 已有行保持可见, 新行加入时伴 tier 分级特效
  ├─ SFX + score_formula 更新不变 (animation_handler 原有逻辑)
  └─ 每行间隔 0.25s

Stage C (微调)
  ├─ 分割线 "──────────" 横穿 (0.2s 淡入)
  ├─ ×N 从 scale 0.01→2.2 explode (0.25s)
  ├─ settle 2.2→1.0 (0.4s SPRING)
  ├─ do_hit_stop(0.1) + manga_burst + shake(0.2, 0.15) 不变
  └─ 最终脉冲 + gold_flash(0.6s) 不变

Stage C 后
  ├─ overlay.queue_free() → 所有子节点自动清理
  ├─ formula settle 不变
  └─ Phase 4 结果判定不变
```

## 3. `xi_strike_overlay.gd` 修改明细

### 3.1 成员变量变更

**删除:**
- `_current_xi_name: Label` — 不再有"当前活跃"喜名
- `_current_mult: Label` — 不再有"当前活跃"×N

**新增:**
- `_rows: Array[Label]` — 累积行数组（每行一个 Label, 内容格式 "名字  ×N"）
- `_divider: Label` — 分割线 Label
- `_overflow_row: Label` — 溢出行 Label
- `_watermark: Label` — 已有, 不变
- `const MAX_ROWS: int = 4` — 最大展示行数

### 3.2 方法变更

| 方法 | 变更 | 说明 |
|------|------|------|
| `_init()` | 修改 | center_box 尺寸: offset_top=-200, offset_bottom=200 (600×400) |
| `stage_a_buildup()` | 不变 | 已有逻辑 |
| `watermark_hide()` | → `_dim_watermark()` | 不销毁, 降 alpha 到 0.12, scale 到 0.8, 呼吸继续 |
| `show_overflow(count: int)` | **新增** | 生成顶部溢出行 "+N 喜", 从右滑入 0.1s |
| `stage_b_reveal()` | **重写** | 改为累积式: 从右滑入新行到指定 Y slot |
| `_create_row(name, x_mult, tier, row_idx)` | **新增** | 创建单行 Label (喜名+ ×N 合成一行文本) |
| `_get_row_y(row_idx: int)` | **新增** | 计算第 N 行的 Y 坐标 |
| `_clear_current()` | 删除 | 不再需要 |
| `stage_c_final()` | 微调 | 加分割线 |
| `_create_divider()` | **新增** | 创建分割线 Label |
| `_create_final_label()` | 不变 | 已有(已修 bug) |

### 3.3 颜色 tier 红色系（v12 更新: 金色→喜红）

| ×倍率 | Tier | 主色 | 色值 | 描边色 | 描边厚 |
|:-----:|:----:|------|------|--------|:------:|
| ×2 | 1 | **朱砂红** | `#E84040` | `#4A0A0A` 暗红棕 | 3px |
| ×3 | 2 | **绯红** | `#F02828` | `#5A0808` 暗红褐 | 4px |
| ×4 | 3 | **赤红** | `#FF1A1A` | `#6A0000` 深血红 | 5px |
| ×5 | 4 | **血焰红** | `#FF0A0A` | `#7A0000` 黑绛红 | 6px |
| ×6+ | 5 | **白炽红** | `#FF4444` | `#8A0000` 黑红 | 8px |

所有行增加 `font_shadow` (黑色 25%, 1px offset) 增强复杂纹理可读性。
底部新增半透明暗底 `Color(0.04, 0.04, 0.08, 0.45)` 覆盖全 260×400 区域，隔离 table_bg 草地纹理。

已删除金色系旧色值 (`#FFD700` / `#FFBF1A` / `#FF8C1A` / `#FF400D` / `#FF1A1A`)。

## 4. `animation_handler.gd` 修改明细

`Phase 3` 循环前 (第 320-346 行) 增加溢出判断：

```gdscript
# 在 Stage A 之后、Stage B 循环之前
var triggered: Array[String] = xi_result.triggered if xi_result else []
const MAX_SHOW: int = 4

if triggered.size() > MAX_SHOW:
    var overflow_count: int = triggered.size() - MAX_SHOW
    xi_overlay.show_overflow(overflow_count)
    triggered = triggered.slice(-MAX_SHOW)  # 只保留最后 4 个
else:
    xi_overlay.dim_watermark()

# 然后循环 triggered (此时最多 4 个)
```

## 5. 文档同步

`24-scoring-ninja-animation.md` 更新 §5:
- center_box 尺寸: 600×300 → 600×400
- Stage B 描述: "逐一爆裂" → "累积式展示"
- 时序表: Phase 3 B 行 "K × 1.15s" → "min(K, 4) × 1.15s + (K>4 ? 0.1s : 0)"
- 代码摘要区: 更新 handler 循环片段

## 6. 不修改的内容

- Stage A 已有逻辑和时长不变
- Stage C 核心动画不变 (仅加分分割线)
- Phase 4 结果判定不动
- TweenFX / GlobalTweens 不动
- ScoreCalculator / XiDetector / ScoreXiHandler 不动
- 场景文件不动
- 其他 UI 元素不动
