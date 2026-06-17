# Phase H — 忍者牌效果集中分析：方案审阅定案

> 审阅日期: 2026-06-16 | 状态: ✅ 审阅通过 | 关联: `score_calculator.gd`, `seal_controller.gd`, `animation_handler.gd`, `arrange_controller.gd`

## 问题

当前 `owned_ninjas: Array[Dictionary]` 每次出牌被完整遍历 **至少 7 次**，每次做同样的 `.get("effect", {})` 字典解析，且解析逻辑散布在 5 个文件中。同时 3 种工具类效果（extra_plays/death_save/wild）**悬空未处理**（extra_redraws 已随换牌系统移除）。

## 方案（审阅修正版）

砍掉独立类 `NinjaEffectsSummary`，改为在 `ScoreCalculator` 上增加单个静态方法 `analyze_effects()`，返回 Dictionary。

### Phase 1a — `analyze_effects()` 核心方法
文件: `score_calculator.gd`
- 新增 `static func analyze_effects(...) -> Dictionary` — 单次遍历，返回聚合摘要
- 新增 `static func calculate_with_summary(..., summary) -> ScoreResult` — 用预计算摘要计分
- 旧 `calculate()` 重构为: `analyze_effects()` → `calculate_with_summary()` (向后兼容)

### Phase 1b — SealController 消费
- `prepare_play()` 一次调用 `analyze_effects()`
- `_collect_play_gold()` 改用 summary

### Phase 1c — AnimationHandler 消费
- 删除 `_compute_ninja_contributions()`, 改用 `summary.anim_contribs`

### Phase 1d — ArrangeController 消费
- `_compute_per_group_ninja_effects()` 改用 `summary.per_group`

### Phase 1e — 工具效果可见性
- `analyze_effects()` 中收集 extra_plays/death_save 到 `summary.tools`（extra_redraws 已随换牌系统移除）

## 数据结构

```gdscript
## analyze_effects() 返回 dict keys:
{
    per_group: {
        head: {chips: int, mult: int, x_stack: Array[int]},
        mid: {...},
        tail: {...},
    },
    col: [
        {chips: int, mult: int, x_stack: Array[int]},  # col 0
        {...},                                           # col 1
        {...},                                           # col 2
    ],
    anim_contribs: [
        {id: String, chips: int, mult: int, groups: Array[int], is_economy: bool},
    ],
    gold_on_play: int,                  # 福神 + 金尾
    interest_cap_bonus: int,             # 利息之印
    constraint_override: String,         # 均衡/独尊/天下人
    scoring_override: String,            # tail_only 等
    scaling_ninjas: Array[Dictionary],   # 引用 gs.owned_ninjas 元素
    tools: {                             # 悬空效果
        extra_plays: int,
        death_save: bool,
    },
    # 原始数据（非聚合，供调试/验证用）
    _version: 1,
}
```

## 验收标准

- Phase 1a: `analyze_effects()` + `calculate_with_summary()` 产出与旧 `calculate()` 一致的 `ScoreResult`
- Phase 1b: 同牌局 gold_on_play 值不变
- Phase 1c: 同牌局 ninja_contribs 数组完全一致（含 B15/B16 修复后行为）
- Phase 1d: 同配置 auto_arrange 输出相同
- Phase 1e: `summary.tools` 准确反映悬空效果
