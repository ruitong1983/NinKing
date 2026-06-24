# 消除模式 — 玩法设计规格书

> **建立日期:** 2026-06-24 | **状态:** Phase 1 ✅ / Phase 2 ✅ / Phase 3 ✅ / CL20-CL21 ✅ / CL26-CL30 ✅ / CL33 ✅ / V1-V9 计分特效 ✅ | **来源:** Grill 10 轮决策 + CL6 + Grill 消除模式发牌/三连/计分修订 (2026-06-24)
> **关联 TODO:** CL6 ✅ CL9 ✅ CL10 ✅ CL11 ✅ CL12 ✅ CL13 ✅ CL17(UI HUD) ✅ CL18(动效) ✅ CL19(文档) ✅ CL20(重构) ✅ CL21(安全) ✅ | CL14(蒙特卡洛) ⬜ CL15(经济审计) ⬜ CL16(目标重标) ⬜
> **参考:** Balatro (消除+连锁), ビッグ (相邻交换三消), `clean_controller.gd` (已有基础设施)

---

## 一、核心概念

**消除模式** 是 NinKing 的第二种游戏模式，与「比鸡模式」共享主体框架（结界/封印/金币/商店/忍者），但玩法完全不同：

| 维度 | 比鸡模式 (bi_ji) | 消除模式 (clean) |
|------|------------------|-----------------|
| 核心操作 | 排列 9 张牌为 3 组（头/中/尾） | 相邻交换，三连消除 |
| 操作限制 | `plays_per_seal=3`（出牌次数） | `clean_swaps_per_seal=5`（交换次数） |
| 计分单位 | 组（头/中/尾）+ 列 + 喜 | 消除波次（chain wave） |
| 匹配类型 | 手役牌型（顺子/同花/豹子等） | **豹子/同花顺/同花/顺子** |
| 约束 | 升序约束（头≤中≤尾） | 相邻约束（只能交换相邻卡） |
| 补充机制 | 无（9 张固定排列） | 重力补牌 + 连锁消除 |
| 喜系统 | ✅ 全局喜 / 组喜 / 列喜 | ❌ 无喜系统 |
| 牌型手役 | ✅ 同花/顺子/豹子等 | ✅ 豹子/同花顺/同花/顺子（行/列消除） |

---

## 二、取消的功能

以下比鸡功能在消除模式中 **不使用**，相关资源/代码保留但不执行：

| 功能 | 原因 | 替代 |
|------|------|------|
| 喜系统（全局喜/组喜/列喜） | 消除模式没有组的定义，列也在消除时动态变化 | ❌ 无 |
| ~~手役牌型~~（已恢复） | 消除模式使用**豹子/同花顺/同花/顺子** 四种匹配类型 | 行/列消除检测 |
| 升序约束 | 消除模式不分组 | 相邻约束 |
| 列 ×mult 系统 | 列无固定分配 | ❌ 无 |
| 出牌 (`plays_remaining`) | 无"出牌"概念 | 交换次数 (`swaps_remaining`) |
| AI 重排按钮 | 无可自动排列的内容 | ❌ 删除 |
| 手替え（换牌/redraw） | 无弃牌的概念 | ❌ 删除 |
| 手牌拖拽跨格交换 | ~~消除模式限制相邻交换~~ | ✅ 自由交换 — v2026-06-24 解除相邻约束 |
| `interest_cap_bonus`（利息上限突破） | 比鸡专属忍者效果 | ❌ 跳过 |
| 封印主效果中的 `constraint` 相关 | 升序约束不存在 | ❌ 跳过 |

---

## 三、核心循环

### 3.1 每封印流程

```
封印开始
  ↓
初始发牌: 从牌组抽 9 张 → 3×3 网格
  ↓ (保证无预先三连)
PLAYING 状态
  ↓
玩家操作: 点击相邻两张牌 → 交换
  ↓
检测: 是否有三连 (行/列 rank 相同)?
  ├── 无三连 → 交换生效 → 等待下一次交换
  └── 有三连 → 进入连锁消除流程
         ↓
      连锁消除 (详见 §四)
         ↓
      多波连锁消除完成
         ↓
      swaps_remaining -1
         ↓
      判定:
        ├── current_score ≥ target_score → 封印突破 → SEAL_COMPLETE
        ├── swaps_remaining ≤ 0 → GAME_OVER
        └── 继续 → PLAYING 等待下一次交换
```

### 3.2 交换规则

1. **任意位置自由交换** — 9 格内任意两位置（含对角/远距）均可交换。v2026-06-24 解除相邻约束，玩家可直接搬运任意牌到目标位置，聚焦牌面策略而非搬运路径。
2. **必须形成三连** — 交换后若无任何行/列三连，**交换仍然生效**但无消除/计分（玩家浪费一次交换机会）
3. **非相邻点击有效** — 任意距离均可交换（不再提示"非相邻无效"）
4. **交换动画** — 两张牌平移互换（~0.15s），然后静止 0.1s 后进入消除检测

### 3.3 补牌规则

1. **重力下落** — 消除后对应列上方牌自然下落填补空位
2. **抽牌补顶** — 空出的顶部位置从牌组抽新牌填入
3. **牌组耗尽** — 若牌组无牌可抽，空位维持 `null`，对应位置不可消除（不会触发匹配）
4. **补给触发** — 补牌后自动进行下一轮三连检测（连锁）

---

## 四、连锁消除系统

### 4.1 波次定义

```
波次 (chain wave):
  一次消除检测 → 匹配组移除 → 重力补牌 的完整过程。

连锁 (chain):
  一次交换触发多波消除。（波次 1 消除后补牌 → 新牌形成新的三连 → 波次 2 ...）
```

### 4.1a 视觉分步流程 (v2026-06-24 CL33 增强)

每波消除在视觉上拆为 **五阶段**，让玩家充分感知消除→重力→补牌的完整过程：

```
Phase A — 高亮（0.35s）:
  匹配行/列的卡牌闪烁红光（REDRAW_TARGET）
  → 玩家看到"哪些牌组成了消除"
  → await 0.35s（重置卡牌闪烁状态）

Phase B — 消除（瞬间）:
  remove_matches → hand_updated.emit()
  → 匹配卡牌消失（网格出现空洞）

Phase C — 空洞（0.4s）:
  → 玩家观察空槽位
  → await 0.4s

Phase D1 — 旧牌下沉（0.55s v2 增强）:
  gravity_and_draw 执行数据层操作
  检测：哪些旧牌在列内从高行落到了低行
  动画：卡牌节点 y 上移 100px → EASE_IN + TRANS_CUBIC 重力加速落位（0.26s）
        → 着陆 squash scale(1.0→1.10,0.86) 软胶压缩（0.05s）
        → spring 弹回 scale(1.10→1.0) TRANS_BOUNCE 小幅度回弹（0.14s）
        → 着陆时 modulate 暖光波纹 (1.20,1.15,0.7) 闪烁 0.02s → 渐隐 0.18s
  列交错：左→中→右依次延迟 0.04s，最左列先落
  初始停顿：0.06s 轻微卡顿后再统一滑落
  → 玩家看到"存活的牌加速落下来了，着陆时弹了一下"
  → await 0.55s

Phase D2 — 新牌坠落（0.50s v2 增强）:
  检测：哪些位置的牌是牌库新抽的（不在 gravity 前的手牌中）
  动画：新牌从网格上方 130px 坠入 + scale(0.65→1.0) overshoot 成长
        着陆 squash(1.0→1.12,0.84) → spring 弹回（0.16s）
        着陆暖光波纹 + 落地 sparkle 粒子迸发
        第一行(row 0)的新牌追加橙色 REDRAW_TARGET 闪光
  列交错：左→中→右依次延迟 0.04s
  → 玩家看到"新牌从高处掉落，伴随着星尘迸发"
  → await 0.50s（重置 row 0 闪光状态）

结束后 → 弹出该波次的分数浮标（"+N"黄金字，上浮淡出 0.7s）
        连锁 ≥2 时显示橙色 COMBO ×N 徽章（网格上方，淡入→保持→淡出）
```

**波次定时汇总（v2 增强动效）：**

```
Phase  | 名称 | 时长
A      | 高亮 | 0.35s
B      | 消除 | 瞬间
C      | 空洞 | 0.4s
D1     | 下沉 | 0.55s  ← 重力加速 + squash + spring + 列交错
D2     | 坠落 | 0.50s  ← 更高落距 + squash + spring + 粒子迸发
分数   | 弹出 | 0.7s（异步，不阻塞下一波）
合计   |     | ~1.8s/波
```

**实现注意（更新版）：**
- `_highlight_matches(wave_data)` — 遍历 `remove_positions`，调 `nk.set_visual_state(REDRAW_TARGET)`
- `_reset_card_visuals(wave_data)` — 消除前重置被回收节点的视觉状态（防残留闪材质）
- `_animate_replenishment(gs)` — 快照 pre_hand → `gravity_and_draw()` → 逐列追踪旧牌落点和新牌来源 → D1 100px 重力加速落位 + squash(1.10,0.86) + spring bounce + 暖光波纹 → D2 130px 坠落+scale(0.65→1.0)+squash(1.12,0.84)+spring+sparkle 粒子
- `HandCardContainer.update_card_faces()` — 遇到 `hand[i] == null` 时隐藏对应卡牌节点
- `HandCardContainer.get_card_at(idx)` — 公开方法访问 `_held_cards[idx]`，供高亮/动画使用
- `NinKingCard.set_visual_state(VisualState)` — 标准 API 切换红闪材质
- 消除链期间 `_cascading = true` 锁定并发拖拽，`_transition_to(PLAYING)` 时自动解锁

### 4.2 波次计分

```
每波计分 = Σ(匹配组基础分) × 连锁倍率

匹配组基础分 = Σ(卡牌 chip 值) × 手役倍率

卡牌 chip 值（RANK_CHIP_VALUES）:
  2-10 = 面值, J/Q/K = 10, A = 11

手役倍率（参考比鸡 HAND_TYPE3_BASE_VALUES）:
  豹子 (THREE_OF_KIND_3)  = ×8
  同花顺 (STRAIGHT_FLUSH_3) = ×5
  同花 (FLUSH_3)          = ×4
  顺子 (STRAIGHT_3)       = ×3

连锁倍率 = 1 + (chain_level - 1) × 0.5
  chain_level=1 → ×1.0
  chain_level=2 → ×1.5
  chain_level=3 → ×2.0
  chain_level=4 → ×2.5  (上限)
```

**示例（chain=1，无连锁）：**
- 顺子 5-6-7: (5+6+7)×3 = **54**
- 同花 K♠7♠3♠: (10+7+3)×4 = **80**
- 同花顺 5♠6♠7♠: (5+6+7)×5 = **90**
- 豹子 AAA: (11+11+11)×8 = **264**
- 豹子 777: (7+7+7)×8 = **168**

**示例（多波连锁，chain=3 → ×2.0）：**
- 波次 1: 顺子 5-6-7 = 54, chain=1 → 54×1.0 = **54**
- 波次 2: 同花 K♠7♠3♠ + 豹子 222 = 80+48=128, chain=2 → 128×1.5 = **192**
- 波次 3: 豹子 AAA = 264, chain=3 → 264×2.0 = **528**

**单次交换总分 = Σ(各波次分数) = 54 + 192 + 528 = 774**

> 忍者 `add_chips` +N 在 hand_type_mult 乘之前加到 Σ(card_chip) 上。

### 4.3 连锁最大波次

- 自然连锁上限: 链到无三连为止
- 硬编码上限: **10 波**（防御极端 RNG 死循环）
- 达到上限时强制结束连锁，进入结算

### 4.4 双消除奖励

当 **行列交叉消除**（同一张牌同时属于行匹配组和列匹配组——即「十字消除」）：

```
十字消除奖励 = +50 额外分（该次 swap 的总分额外 +50）
```

十字消除的共享牌只移除一次（不重复扣除），但两组都计分。

---

## 五、忍者牌整合

### 5.1 触发时机

消除模式中忍者按如下方式触发：

| 忍者 trigger | 比鸡模式 | 消除模式 | 说明 |
|-------------|---------|---------|------|
| `on_play` | 每次出牌 | **每次 swap** 的首波消除开始时触发 | 即每次交换只触发 1 次，多波连锁不重复触发 |
| `on_seal_start` | 封印开始 | 同左 ✅ | 无变化 |
| `on_redraw` | 换牌时 | ❌ 不触发 | 消除模式无手替え |
| `on_boss_clear` | Boss 过关 | 同左 ✅ | 封印突破触发 |
| `on_ritual_use` | 秘仪卡使用 | 同左 ✅ | 无变化 |

### 5.2 效果映射

忍者牌大多使用 `add_chips` / `add_mult` / `x_mult` 效果。消除模式下语义重新映射：

| 效果字段 | 比鸡语义 | 消除语义 |
|---------|---------|---------|
| `add_chips` | 加到组 chips 上 | **直接加法加到该次 swap 的总波次分数上** |
| `add_mult` | 加到组 mult 上 | **加法加到该次 swap 的总倍率上（初始化=1）** |
| `x_mult` | 乘到组 x_stack | **乘法乘到该次 swap 的总分上** |
| `extra_plays` | +1 出牌次数 | +1 `swaps_remaining`（一次额外的交换机会） |
| `gold_on_play` | 出牌产金 | 每次 swap 首波产金 |
| `only_one_play` | 强制仅 1 次出牌 | 强制仅 **1 次交换**（swaps_remaining=1） |
| `interest_cap_bonus` | 利息上限突破 | ⛔ 不生效 |
| `gold_per_discarded_face` | 弃牌产金 | ⛔ 不生效（无手替え） |

**计分公式（含忍者）：**

```
swap_score = 0
base_multiplier = 1

for each wave:
    for each match in wave:
        match_base_score = (Σ(card_chip) + Σ(ninja_add_chips_for_this_swap)) × hand_type_mult
    raw_wave_score = Σ(match_base_scores) × chain_multiplier
    base_multiplier += Σ(ninja_add_mult_for_this_swap)
    swap_score += raw_wave_score

swap_score = swap_score × base_multiplier
for each x_mult_ninja:
    swap_score = ceil(swap_score × ninja_x_mult_value)

current_score += swap_score
```

> `add_chips` 在 `hand_type_mult` 乘之前加到 Σ(card_chip) 上（Q1 确认）。

### 5.3 条件判定

忍者的 `condition` 字段需要重新解释：

| condition 类型 | 比鸡含义 | 消除含义 |
|---------------|---------|---------|
| `hand_type: N` | 组牌型 = N | ⛔ 永远不满足（消除模式无牌型概念） |
| `group: "head"/"mid"/"tail"` | 组位置 | ⛔ 永远不满足 |
| `"head_or_mid"` | 组位置组合 | ⛔ 永远不满足 |
| `xi: "..."` | 喜触发 | ⛔ 永远不满足 |
| `rank_odd` | 手牌有奇数 | ✅ 条件不变，检查 9 张手牌中是否有奇数 rank |
| `mult_per_hand_rank` | 每张 rank 贡献 mult | ✅ 条件不变 |

**总结：** 消除模式下只有 **无条件忍者**（effect 无 condition）+ **rank_odd** + **mult_per_hand_rank** 条件会生效。其他条件类忍者（手役型/组型/喜型）在消除模式下**永久不满足**。

> ⚠️ **设计平衡提示：** 这意味着消除模式的忍者池有效缩小约 60%。建议未来引入消除模式专属忍者，或者在消除模式下为条件型忍者提供 fallback 效果（如 "手役条件不满足时提供 50% 基础加成"）。后文 §八 讨论。

### 5.4 衰减型忍者

原 `DecayTracker` 机制保留，衰减按每次 swap 扣减：
- `decay_per_play` → `decay_per_swap`（每次交换扣减）
- `x_decay_per_seal` → 同左

### 5.5 成长型忍者

- `on_play` trigger → `on_swap`（每次交换触发成长）
- `on_boss_clear` → 同左

---

## 六、封印/Boss 系统

### 6.1 封印主（Seal Lord）

封印主效果保留，但与消除模式适配：

| 封印主效果 | 比鸡效果 | 消除模式效果 |
|-----------|---------|------------|
| `skip_head` | 头组×0 | ⛔ 不生效（无头组） |
| `scatter_king` | 重分 K | ✅ **K 不参与消除匹配**（置换为 `null`） |
| `hungry_ghost` | 尾组×0 | ⛔ 不生效 |
| `tail_x2` | 尾组×2 | ⛔ 不生效 |
| `deprioritize_suit` | 某花色降序 | ⛔ 不生效 |
| `lowest_group_zero` | 最低组×0 | ⛔ 不生效 |
| `constraint_reverse` | 升序→降序 | ⛔ 不生效 |
| `ninja_slots_minus` | 忍槽-1 | ✅ 同左 |
| `only_one_play` | 强制1次出牌 | ✅ 转换为 `only_one_swap` |

**消除模式专属封印主效果（新增）：**

| 效果 | 说明 |
|------|------|
| `column_blocked: int` | 某列被封印，该列不参与消除检测 |
| `row_blocked: int` | 某行被封印，该行不参与消除检测 |
| `max_chain: int` | 连锁上限降低（如 max_chain=2） |
| `wild_seal: true` | 每局有一张卡变为百搭 |

### 6.2 约束

消除模式无升序约束。当前配置如下：

| 约束 | 说明 |
|------|------|
| `free_swap` (默认) | 9 格内任意两位置自由交换 — v2026-06-24 |
| `adjacent_only` | (可选配置) 回退到相邻交换模式 |
| `locked_cells: Array[int]` | 某些格子不可移动（封印主效果） |

### 6.3 封印名称

消除模式的封印与比鸡共用 `BarrierConfig` 的 target 值和封印主池，但封印名后缀由「修羅/明王/夜叉」改为「序/破/急」：

| 封印 # | 比鸡名 | 消除名 |
|--------|--------|--------|
| 0 | 修羅 | 序 |
| 1 | 明王 | 破 |
| 2 | 夜叉 | 急 |

---

## 七、经济

### 7.1 保留项

| 项目 | 说明 |
|------|------|
| 金币系统 | gs.gold，全保留 |
| 商店系统 | ShopOverlay + shop_panel，全保留 |
| 忍者购买 | 商店购买忍者，保留 |
| 星图购买 | 保留（但消除模式无 HandType3 概念 ⚠️ 见下） |
| 符術/秘儀/道具 | 保留，效果重新映射 |
| 利息机制 | 保留（`interest_divisor=5`，`interest_cap=5`） |
| 刷新递进费 | 保留（`$3+$1/次`） |

### 7.2 修改项

| 项目 | 修改 |
|------|------|
| 星图卡 | **消除模式不出售**（star_chart_levels 基于 HandType3，消除模式无牌型） |
| 金币初始值 | 同 bi_ji $8（已验证适合早期购买力） |
| 封印奖励金 | 待 CL16 重标定后确定 |
| `gold_per_discarded_face` | 不生效 |
| `gold_on_play` | 改为 `gold_on_swap`，每次 swap 首波前产金 |

### 7.3 金牌子卡

| 增强 | 原效果 | 消除效果 |
|------|--------|---------|
| GOLD (镀金) | 该组计分时 +$3 | 该卡被消除时 +$3 |
| STEEL (淬火) | 散牌组 ×2 | ⛔ 不生效（无散牌） |
| STONE (玄铁) | +50 chips | +50 分（消除时加到该波次） |
| GLASS (琉璃) | 组 ×2，1/4 碎 | 该卡消除时 ×2，1/4 碎片（碎片时该卡得分归零） |
| BONUS (强化) | +30 chips | +30 分（消除时） |
| MULT (魔能) | +4 mult | +4 倍率（该次 swap） |
| WILD (混沌) | 全花色 | ✅ 同左（但消除模式不看花色 ⚠️ 实际上无效果） |
| LUCKY (鸿运) | 1/5 +20 mult; 1/15 +$20 | ✅ 同左（消除时触发） |

### 7.4 附魔/封印/版本

- **附魔** — 同上表。购买即用弹窗选择目标卡牌（复用 `EnchantTargetSelector`）
- **封印 (seal)** — RED(×2 分) / GOLD(+$3) / BLUE(升星但消除模式无效) / PURPLE(得符術卡) 中仅 RED/GOLD/PURPLE 有效
- **版本 (edition)** — FOIL(+50分) / HOLO(+10倍率) / POLY(×2) 全部有效，加到该波次

---

## 八、平衡性考量

### 8.1 忍者触发频率对比

| | 比鸡 | 消除（估算） |
|--|------|------------|
| 操作次数/封印 | plays=3 | swaps=5 |
| 忍者触发/操作 | 1 次（首波） | 1 次（首波） |
| 忍者触发/封印 | 3 次 | 5 次 |
| 经济忍者触发/封印 | 3 次 | 5 次（通胀 ~1.67×） |

> **结论：** 直接使用原触发频率会导致经济型忍者收益膨胀 67%。建议 CL15 经济审计时考虑：
> - 经济效果在消除模式下 **减半**（`gold_on_play: 2 → gold_on_swap: 1`）
> - 或 `clean_swaps_per_seal` 从 5 降至 4

### 8.2 条件型忍者失效

约 60% 的忍者带有 `hand_type` / `group` / `xi` 条件，在消除模式下永久不触发。这意味着消除模式的可用忍者池显著缩小。

**短期方案：** 带条件且不满足的忍者不报错、不触发、不显示特殊提示。玩家在消除模式商店中仍然会看到它们，但买入后知道它们不会生效。

**长期方案（此版本暂不实现）：**
- 为条件型忍者设计消除模式 fallback 效果（如「手役条件不满足时，改为 +20% 基础分」）
- 新增消除模式专属忍者池（关键词：`per_chain` / `per_elimination` / `row_bonus` / `col_bonus`）

### 8.3 连锁收益天花板

新计分公式下（Σ(card_chip) × hand_type_mult），收益显著提高：

| 匹配组 | 旧公式 | 新公式 |
|--------|:-----:|:------:|
| 豹子 KKK | 130 | (10+10+10)×8 = **240** |
| 豹子 AAA | 140 | (11+11+11)×8 = **264** |
| 豹子 222 | 20 | (2+2+2)×8 = **48** |
| 顺子 5-6-7 | —（无） | (5+6+7)×3 = **54** |
| 同花 K♠7♠3♠ | —（无） | (10+7+3)×4 = **80** |

理论上单次 swap 最大得分（全部 A + 双消除 + chain=4 + 十字奖励）:
- 两组豹子 AAA: (11+11+11)×8×2 = 528
- 十字消除: +50
- 连锁倍率 ×2.5: (528+50)×2.5 = 1445
- FOIL 版: +50 → 1495
- 约 **1495 分/swap**

封印目标建议范围（基于 5 swaps, 待 CL14 蒙特卡洛确认）:
- 序: 500~800
- 破: 1500~2500
- 急: 4000~6000
- 结界 3以降: 呈指数增长至 ~15000

> ⚠️ **以上目标为初步估算，需 CL16 基于新计分公式重新标定。**

> ⚠️ **最终数值需 CL14 蒙特卡洛模拟 + CL16 重标定，此处仅为设计参考。**

---

## 九、UI 适配

### 9.1 变更总览

| UI 元素 | 比鸡 | 消除 | 说明 |
|---------|------|------|------|
| HandTypePanel | 三墩手役+列牌型 | **改造为动态 match 明细面板** | 逐波追加 match 组行（见 §9.3） |
| ColXiLabel | 喜列表 | **隐藏** | 无喜 |
| ColumnLabelRow | 列手役 | **隐藏** | 无列概念 |
| ScoreCard | 行/列/喜 breakdown | **隐藏** | 总分在 ScorePanel 展示，match 明细在 HandTypePanel |
| PlayCounter | "出牌 3" | 改为 **SwapCounter** "交换 5" | 标签+图标 |
| PlayBtn | 讨伐 | **隐藏** | 不适用 |
| AiRearrangeBtn | AI 重排 | **隐藏** | 不适用 |
| HandTypeLabeler | 手役+约束预览 | **隐藏** | 无手役无约束 |
| 手牌区 | 3×3 分组排列 | **3×3 网格** | 视觉上无变化但交互不同 |
| RedrawBtn | 手替え | **隐藏** | 无换牌 |
| 牌库按钮 | 查看牌库 | **保留** | 同左 |
| 结算卡 | 封印解除 | **保留** | 同左 |

### 9.2 SwapCounter 设计

原 PlayCounter 位置改为 SwapCounter：

```
┌─────────────────────────┐
│ 🔄 交換 5/5             │  ← 图标(双箭头循环) + 剩余次数
│                         │
│ ─────────────────────── │
│                         │
│ スコア: 1250 / 3000     │  ← 当前分数 / 目标分数
│ ████████░░░░░░░░░░ 42%  │  ← 进度条
│                         │
│ ─────────────────────── │     ← MatchPanel/AntePanel 之间不加分隔线
│ 结界: 壱·火 序          │  ← 封印名称
│ Target: 3000            │
└─────────────────────────┘
```

交换图标优先使用已在项目中的 Kenney 图标，若无则用双箭头循环 emoji 🔄。

### 9.3 左面板精简

```
比鸡:         消除:
┌──────┐     ┌─────────┐
│ Match│     │ SwapCnt │  ← 仅保留上半部分
│ Ante │     │ Score   │
│ Hand │     │ Progress│
│ Score│     │ SealInfo│
│ ColXi│     └─────────┘
└──────┘
```

HandTypePanel 改造为动态 match 明细面板（HandTypeVBox 隐藏，CleanMatchScroll 显示），ColumnLabelRow / ColXiLabel 全部隐藏。
ScoreCard 只显示总分进度（不展示波次 breakdown）。

**HandTypePanel 消除模式展示（v2026-06-24 实现）：**

```
HandTypePanel 顶部 30% — anchor_top=0 anchor_bottom=0.3
├── HandTypeVBox         ← 隐藏（比鸡内容）
└── CleanMatchScroll     ← ScrollContainer，锚定填满面板
    └── MatchVBox        ← VBoxContainer，动态追加行
```

动态行由 `CleanMatchDisplay` (`scripts/ninking/ui/clean_match_display.gd`) 管理：

- 一次 swap 触发连锁 → `reset_for_new_swap()` 清空面板
- 每波消除 → `append_wave(wave_data)` 追加 match 组行
- 行格式（RichTextLabel，bbcode 着色）：

```
[color=#F24D4D]豹子[/color]    [color=#3D2B1A]30 × 8 = 240[/color]
```

| 手役 | 配色 |
|------|------|
| 豹子 | `#F24D4D` 烈红 |
| 同花顺 | `#D4A843` 暗金 |
| 同花 | `#3A6FD8` 深蓝 |
| 顺子 | `#7A7A7A` 中灰 |

- 波次之间 8px 行间距分隔
- 超出面板高度自动滚底
- 连锁结果保留到下一次 swap 开始
- 忍者效果不写入手役行，通过忍者栏卡片 flash + 浮字 `+N筹码 +M倍率` 体现（同比鸡模式）

---

## 十、VFX 动效（CL18 参考）

### 10.1 消除动效 (v2026-06-24 CL33 五阶段动画)

消除链每波拆为五阶段，对应动效：

| 阶段 | 事件 | 动效 | 参数 | 音效 |
|------|------|------|------|------|
| 交换 | 两牌互换位置 | 平移 0.15s | `card.move(target, 0)` | `SB.SWAP` |
| Phase A | 高亮匹配牌 | `REDRAW_TARGET` 红光闪烁，匹配行/列发红 | `set_visual_state(REDRAW_TARGET)` — 0.35s | — |
| Phase B | 消除瞬间 | 卡牌瞬间消失（`visible=false`） | `remove_matches()` + `hand_updated.emit()` | — |
| Phase C | 空洞观察 | 网格显示空槽位，无动画 | `await 0.4s` | — |
| Phase D1 | 旧牌下沉 (v2) | 旧牌从上方 100px 重力加速落位 + squash 软胶压缩 + spring 弹回 + 着陆暖光波纹 | `position.y -= 100` → EASE_IN+TRANS_CUBIC 0.26s → squash scale(1.10,0.86) 0.05s → spring TRANS_BOUNCE 0.14s + modulate 暖光(1.20,1.15,0.7) 0.02s→渐隐0.18s；列交错 0.04s×col | — |
| Phase D2 | 新牌坠落 (v2) | 新牌从网格上方 130px 坠入 + scale 0.65→1.0 overshoot 成长 + squash + spring + 着陆 sparkle 粒子迸发 | `position.y -= 130` + `scale=0.65` → EASE_IN+TRANS_CUBIC 0.28s + scale TRANS_BACK 0.16s → squash(1.12,0.84) 0.05s → spring 0.16s + modulate 暖光 0.02s→渐隐0.18s + `GlobalTweens.burst_particles("sparkle")`；列交错 0.04s×col | `SB.DEAL` |
| 波次计分 | 该波得分浮出 | 金色浮字 `+N` 从网格中心上浮淡出 | Label 32pt gold → `position:y -50` 0.7s + `modulate:a 0→0` 0.5s delay 0.35s | — |
| 连锁徽章 | chain ≥2 显示 | 橙色 `COMBO ×N` 徽标从网格上方淡入→保持→淡出 | Label 24pt orange → fade_in 0.15s → hold 0.6s → fade_out 0.3s | — |
| 连锁屏幕震 | chain ≥3 | 屏幕震荡 + hit_stop 顿帧 | `screen_shake(0.2, 0.12)` + `do_hit_stop(0.08, 0.04)` | — |
| 交换无匹配 | 无消除 | 牌桌轻微摇头否定动画 | `shake_node(0.5, 0.1)` | `SB.UI_ERROR` |
| 封印突破 | 达标 | 同比鸡 SEAL_CLEAR | 复用 | `SB.SEAL_CLEAR` |

### 10.2 连锁计数器

屏幕上方出现连锁数字指示器：
```
             COMBO ×3
          ┌────────────┐
          │  🔥  3  🔥 │
          └────────────┘
```
- 波次 1: 不显示（单波正常消除）
- 波次 2+: 出现橙色 COMBO 徽章（24pt Label + 描边），淡入 0.15s → 保持 0.6s → 淡出 0.3s
- 数字跟随 chain_level 递增（COMBO ×2 → ×3 → ...）
- 每波结束后淡出，下一波重新淡入（若有下一波）
- chain ≥4: 徽章周围追加橙色火星粒子（`burst_custom`, 6粒, 360°, 0.4s）

### 10.3 分组飘字系统 — CleanScoringVFX

**新增文件:** `scripts/ninking/clean/clean_scoring_vfx.gd` (class_name: `CleanScoringVFX`)

**架构:** CleanChainHandler 创建并持有 `CleanScoringVFX` 实例。每波消除结束调 `on_wave_scored(wave_data)`，连锁结束调 `on_swap_finalized(result, old_score)`。

#### 10.3.1 分组飘字 — 原位出生 → 贝塞尔汇合

| 属性 | 规格 |
|------|------|
| **出生位置** | 每个匹配组的网格位置几何中心（通过 `_compute_positions_center(positions[])` 计算）|
| **出生动画** | scale 1.3x->TRANS_BACK 0.10s 弹回 1.0x + alpha 0->1 0.06s |
| **文字分级** | <50分: 28pt 金色 / 50-199: 28pt 金色 / >=200 或豹子: 34pt 暗金 |
| **粒子 burst** | 出生瞬间 `GlobalTweens.burst_particles("sparkle")` |
| **墨染高潮** | 高分(>=200)或豹子消除: `burst_custom(黑色, 8粒, 180度, 0.3s)` 模仿墨迹溅开 |
| **飞行路径** | 二次贝塞尔曲线：出生位 -> 随机偏移控制点(+-30px, -40~-15px) -> ScorePanel 位置，1.0s EASE_OUT CUBIC |
| **尾部光轨** | 飞行 20%/50% 进度时 `burst_particles("sparkle")` 在 Label 当前位置爆发 |
| **汇入收敛** | 抵达后 scale 1.0->0.3 缩小 + alpha 渐隐 0.15s -> queue_free |
| **同屏上限** | 6 组（超出不再生成新飘字） |

#### 10.3.2 十字 +50 标识

行列交叉消除时，在网格中心生成独立的碧蓝「十」标 + `+50` 蓝光飘字。

### 10.4 连锁结算 — 总分联动

所有飘字汇入完毕后触发 `on_swap_finalized()` 调用链：

```
CleanScoringVFX.on_swap_finalized()
  +-- _show_combo_badge(chain_level)      -> COMBO xN 徽章（橙色，淡入->保持->淡出）
  +-- ui.play_clean_score_jump()          -> 1.数字滚动 2.弹性缩放 3.金闪扫过 4.边框光晕 5.进度条
  +-- burst_particles("confetti")         -> ScorePanel 汇入礼花
  +-- _flash_ninja(nc)                   -> 每位触发忍者的卡片 flash + 浮字
```

#### 10.4.1 总分弹性跳（`UIManager.play_clean_score_jump()`）

| 步骤 | 效果 | 参数 |
|------|------|------|
| 1 | 数字老虎机滚动（旧值->新值）| CountUp.play_eased(score_label, old, new, 0.35s) |
| 2 | 旧字缩小 0.9x | 0.06s |
| 3 | 新字放大 1.25x | 0.08s EASE_OUT |
| 4 | 弹性回弹 1.0x | 0.12s TRANS_BOUNCE |
| 5 | 金色闪光扫过 | ColorRect 从左扫到右 0.15s |
| 6 | ScorePanel 边框光晕 | modulate 暖色 0.02s -> 恢复 0.15s |
| 7 | ProgressBar 同步 | progress_bar.value = new_score |

#### 10.4.2 忍者浮字（`_flash_ninja()`）

| 属性 | 规格 |
|------|------|
| **忍者栏 flash** | GlobalTweens.ninja_trigger(card_node) — 弹起->wobble->squash 落回 |
| **浮字内容** | 组装 chips/mult/x_mult: "+15" / "+5倍率" / "x2" |
| **浮字位置** | 忍者卡上方 20px |
| **浮字动画** | scale 0.8->1.0 pop_in 0.08s -> 上浮 25px 0.6s -> 淡出 0.3s |

### 10.5 文件清单

| 文件 | 类型 | 说明 |
|------|------|------|
| scripts/ninking/clean/clean_scoring_vfx.gd | 新增 ~230行 | 计分特效中央编排器 (class_name) |
| scripts/ninking/ui/ui_manager.gd | 修改 +15行 | 加 score_panel 引用 + play_clean_score_jump() + SB preload |
| scripts/ninking/clean_chain_handler.gd | 修改 | 集成 CleanScoringVFX，删旧方法 |
| scripts/ninking/ui/ninking_card.gd | 修改 +3行 | 加 play_ninja_flash() |
| scripts/ninking/score/score_calculator.gd | 修改 +45行 | calculate_clean 返回 per_match_scores + ninja_contribs |

---

## 十一、实施计划

按实施顺序排列（依赖关系排序）：

### Phase 0 — 基础设施已完成 ✅
- CL1: `game_state.gd` game_mode 字段 ✅
- CL2: 启动器 CleanBtn ✅
- CL3: main_menu 路由 ✅
- CL4: `ninking_clean_main.tscn` 复制 ✅
- CL5: game_manager 读取 mode ✅
- CL7: 文档同步（通道部分）✅
- CL8: `clean_controller.gd` 基础设施 ✅

### Phase 1 — 核心玩法（P0）
| # | 任务 | 说明 | 前置 |
|---|------|------|------|
| CL9 | **CleanLayoutGenerator** | peek 9 张 → 验证 4 种匹配类型无三连 → 无效则 shuffle 重试（无上限，不消耗牌） | CL8 |
| CL10 | **game_state 模式分支** | execute_play/swap_cards/_begin_seal_phase 按 mode 分发 CleanController | CL9 |
| CL11 | **Cascading 锁** | `_cascading` 标志位，连锁期间锁定输入 | CL10 |

### Phase 2 — 计分与配置（P1）
| # | 任务 | 说明 | 前置 |
|---|------|------|------|
| CL12 | **Config 独立配置** | `game_config.json` 中 `clean_swaps_per_seal` 修正 + 验证 | — |
| CL13 | **消除计分管线** | 忍者效果整合（add_chips/add_mult/x_mult）→ ScoreCalculator 扩展 + game_manager 接入 | CL10 | ✅ |
| CL14 | **蒙特卡洛模拟** | Python `clean_layout_sim.py` 估算初排全散牌概率 + 每 seal 期望得分 | CL9 |
| CL15 | **经济审计** | 忍者触发频率量化 → 确定降频系数 | CL13 |
| CL16 | **目标分数重标定** | 24 封印 target 值基于 CL14+CL15 重新计算 | CL14+CL15 |

### Phase 3 — UI 与 VFX（P1）
| # | 任务 | 说明 | 前置 |
|---|------|------|------|
| CL17 | **UI HUD 适配** | 隐藏不适用元素（HandTypePanel/ColXiLabel/三墩/列/牌型标签）+ SwapCounter + 封印名序/破/急 | CL10 |✅ |
| CL18 | **Tween/VFX 接入** | 消除粒子 burst_particles + screen_shake + hit_stop + shake_node + 分数 popup | CL9+CL10 |✅ |
| CL19 | **文档同步（6+ 文件）** | 方案审查确认后同步 | 全部 |✅ |

### Phase 4 — 清理与重构（P2）
| # | 任务 | 说明 |
|---|------|------|
| CL20 | **抽取 `apply_economy_effects()` 到 ScoreHelpers** | 消除 `calculate_clean()` 与 `ScoreEffectCollector` 的重复代码 |✅ |
| CL21 | **`_is_ninja_valid_for_clean` 安全 fallback** | 白名单 SAFE_KEYS/INVALID_KEYS，未知 condition key 一律 reject |✅ |

### 待办（分析任务，不改代码）
| # | 任务 | 说明 | 状态 |
|---|------|------|:----:|
| CL14 | **蒙特卡洛模拟** | `tools/clean_layout_sim.py` 估算初排散牌概率 | ⬜ |
| CL15 | **经济审计** | 忍者触发频率量化 → 降频系数 | ⬜ |
| CL16 | **目标分数重标定** | 24 封印 target 值基于 CL14+CL15 重新计算 | ⬜ |

---

## 十二、技术架构决策

### 12.1 消除控制器与 SealController 的关系

**决策：`CleanController` 独立于 `SealController`，不继承。**

理由：
- 消除模式的 prepare/finalize 流程完全不同（无分组、有连锁）
- 共用部分（`_complete_seal`、利息计算）已提取到 `clean_controller.gd` 中
- 保持两端互不影响，比鸡改 bug 不波及消除

### 12.2 消除计分管线

**决策：扩展 `ScoreCalculator` 新增 `calculate_clean(hand, ninjas, chain_context)` 静态方法，不新建独立文件。**

理由：
- `ScoreCalculator` 管理所有计分入口，保持统一
- `calculate_clean` 是轻量级方法（与百行级别的 `calculate_with_summary` 相比），不值得独立成文件
- 忍者效果收集复用 `collect_ninja_per_group()` 但 skips group/hand_type/xi 条件

### 12.3 ninking_clean_main.tscn 维护策略

**决策：`ninking_clean_main.tscn` 与 `ninking_main.tscn` 保持同步修改，差异部分通过代码分支控制（`game_mode == "clean"`），而非通过场景差异。**（类比 `debug_ninking_main.tscn` 与 `ninking_main.tscn` 的关系）

理由：
- 消除模式 UI 改动量不大（主要隐藏元素而非重构布局）
- 保持场景同步的维护成本低于维护两套独立场景

### 12.4 消除模式专属忍者

**决策：暂不新增消除模式专属忍者。** 依赖当前忍者池（条件型忍者不触发时静默跳过）。如果测试发现可用池过小，Phase 2 再引入。

---

## 十三、未解决问题

| # | 问题 | 状态 | 决策者 |
|---|------|------|--------|
| Q1 | 消除模式开局是否需要保留部分金币（如 $8）还是调整 | 同 bi_ji $8 | 沿用 |
| Q2 | `hand_type` 条件的忍者在消除模式下商店中是否应该隐藏/标记 | 暂时不标记，不影响 | 沿用 |
| Q3 | 消除模式目标分数是否按结界分层还是统一等比缩放 | 待 CL16 决定 | 待定 |
| Q4 | 消除模式是否保留封印主 Boss 立绘 | 保留（无封印主效果的封印主只影响 UI 名称） | 保留 |
| Q5 | 单封印内需要多少次交换才能达到目标（初步估算） | 序~3次, 破~5次, 急~8次 | 估算，待验证 |
| Q6 | 消除模式下附魔效果（WILD 混沌）因不看花色形同虚设，是否需要替换为其他效果 | 不改 | 沿用 |
