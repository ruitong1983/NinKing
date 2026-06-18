# 关卡难度模拟方案 v2

## 目标

模拟玩家从 **0 忍者起步 → 逐关累积 → 跨关继承** 的真实游戏过程，通过统计每关得分分布，验证关卡阈值合理性。

---

## 一、核心设计：玩家决策模拟

### 1.1 模拟的对象是谁？

一个**理性玩家**，选定一种构筑方向后：
1. 每关打牌 → 过关 → 进商店
2. 商店随机展示 4 张忍者
3. 从这 4 张中决策「买哪张」
4. 忍者持有跨关继承，永不重置

### 1.2 商店模拟（核心决策点）

```
每次进入商店:
  ├─ 当前持有金币 G
  ├─ 当前忍者 N 张 (0~5)
  ├─ 方向策略 S (对子流 / 顺子流 / …)
  │
  ├─ 商店生成 4 张随机忍者:
  │   NinjaPool.get_random_ninjas(4, owned_ids)
  │   └─ 从全忍者池排除已拥有后随机取 4 张
  │   └─ 包含各类稀有度、各方向
  │
  ├─ 玩家审视 4 张:
  │   ├─ 与策略 S 匹配? (见 §2.4 匹配规则)
  │   ├─ 价格 ≤ 当前金币?
  │   └─ 买了不超 5 张?
  │
  ├─ 决策 1: 有没有匹配的、买得起的忍者?
  │   ├─ 有 → 按优先级买最好的那张
  │   ├─ 没有且还有余钱 → 考虑刷新
  │   │   ├─ 刷新费用 = $3 + 已刷新次数
  │   │   ├─ (简化) 最多刷 1 次
  │   │   └─ 刷新后从新 4 张中再选
  │   └─ 没有且不想刷 → 存钱走人
  │
  └─ 购买优先级:
      倍率X > 倍率+ > 筹码 > 经济
      同优先级下, 选最贵的 (越贵越强)
  
  买完 → 更新 N[] 和 G → 进入下一关
```

### 1.3 金币流转模型

### 1.3 金币流转模型

```
起始金币: $8, 起始忍者: 0 张

第 N 关:
  持有金币 = 上一关剩余 + 本关封印奖励 + 利息
  可用预算 = 持有金币 × 预算比例 (80% / 40%)
  实际消费 = min(可用预算, 能买到的最佳忍者总价)
  剩余金币 = 持有金币 - 实际消费
  忍者库存 += 本次购买的忍者
```

| 参数 | 值 |
|------|----|
| 起始金币 | $8 |
| 修羅通关奖励 | +$3 |
| 明王通关奖励 | +$5 |
| 夜叉(Boss)通关奖励 | +$8 |
| 利息 | 每持有$5得$1，上限$5 |
| 极限预算比例 | 持有金币 × 80% |
| 保守预算比例 | 持有金币 × 40% |

### 1.4 忍者持有追踪（跨关继承示例）

```
结界1-1 (修羅):
  进入时: 金币=$8, 忍者=[]
  模拟: 无忍者打关
  通过后: +$3 + 利息$1(每$5得$1) → 金币=$12
  商店: 预算=$12×80%=$9.6 → 买手里剑($4) + 并蒂($5) → 剩余=$3
  忍者=[手里剑, 并蒂]

结界1-2 (明王):
  进入时: 金币=$3, 忍者=[手里剑, 并蒂]
  模拟: 带2张忍者打关
  通过后: +$5 + 利息$0(不够$5) → 金币=$8
  商店: 预算=$8×80%=$6.4 → 加水遁($6, 顺子流) → or 买不起等 → 剩余=$2
  忍者=[手里剑, 并蒂]

...持续到结界8-3, 忍者可逐步满5张
```

---

## 二、模拟配置

### 2.1 输入参数

| 参数 | 值 |
|------|-----|
| 策略方向 | 对子流 / 顺子流 / 同花流 / 同花顺流 / 豹子流 |
| 预算曲线 | extreme (80%) / conservative (40%) |
| 结界 | 1..8 |
| 封印 | 0=修羅 / 1=明王 / 2=夜叉 |
| 每场景模拟次数 | 10 次（原型阶段） |
| 牌库 | 标准 52 张，无放回 |
| 星图 | 不模拟 |
| Boss 效果 | 暂不模拟（安全余量） |
| 卡牌增强/封印 | 暂不模拟 |

### 2.2 单关模拟流程

```
输入: 当前忍者库存 N[], 当前金币 G, 策略方向 S, 目标阈值 T

Step 1 — 抽牌阶段（3 手，无放回）
  deck = 标准52张牌
  总分 = 0

  hand1: deck抽9张 → 枚举1680排列 → 选最优合法排列 → calc()计分 → 累加 → 弃9张
  hand2: 剩43张抽9 → 枚举1680排列 → 选最优合法排列 → calc()计分 → 累加 → 弃9张
  hand3: 剩34张抽9 → 枚举1680排列 → 选最优合法排列 → calc()计分 → 累加

Step 2 — 判定
  如果 总分 ≥ T → 通关
  否则 → 失败

Step 3 — 通关后商店（更新忍者库存和金币）
  通关金币 += 封印奖励 + 利息
  从忍者池选方向匹配的、未拥有的、预算内的忍者购买
  更新 N[] 和 G

输出: 总分, 是否通关, 各手分数明细
```

### 2.3 排列枚举与约束

```
枚举 C(9,3)×C(6,3)=1680 种分组

每种分组:
  head = combo1 (3张)
  mid  = combo2 (3张)
  tail = 剩余 (3张)

  检查约束: head.strength ≤ mid.strength ≤ tail.strength
  不满足 → 跳过

  对合法排列: 用扩展calc()算分
  选最高分排列

优化: 先用简化版 _fast_score() 筛出 top10，
      对 top10 跑完整 calc() 选最优。
      避免 1680 次完整计分。
```

### 2.4 策略-忍者匹配规则

```
对子流 (hand_type=1):
  匹配: hand_type=1 的忍者 (手里剑/并蒂/风遁)
  匹配: col_hand_type=1 的忍者 (微波/律動/閃光)
  匹配: 组定向忍者 (蓄勢/先阵/开局/中盘/收官)
  匹配: 无条件/经济忍者 (金剛力/黄金律/喜鹊)

顺子流 (hand_type=2):
  匹配: hand_type=2 的忍者 (苦无/流觞/水遁)
  匹配: col_hand_type=2 的忍者 (席卷/共鳴/流光)
  匹配: 组定向忍者
  匹配: 无条件/经济忍者

同花流 (hand_type=3):
  匹配: hand_type=3 的忍者 (忍刀/土遁)
  匹配: col_hand_type=3 的忍者 (震荡/響震/極光)
  匹配: 组定向忍者
  匹配: 无条件/经济忍者

同花顺流 (hand_type=4):
  匹配: hand_type=4 的忍者 (重刃/贯月/火遁)
  匹配: 组定向忍者
  匹配: 无条件/经济忍者

豹子流 (hand_type=5):
  匹配: hand_type=5 的忍者 (影缝/鼎立/雷遁)
  匹配: 组定向忍者
  匹配: 无条件/经济忍者
```

---

## 三、技术实现

### 3.1 文件结构

```
tools/simulation/
├── README.md          ← 本方案文档
├── sim_engine.py      ← 扩展计分引擎（从 calc_engine.py 派生）
├── sim_runner.py      ← 模拟编排器（按结界推进、金币追踪、忍者继承）
├── sim_config.py      ← 参数配置（策略定义、预算比例、忍者池筛选）
└── sim_analyze.py     ← 结果分析（百分位统计、阈值对比、HTML输出）
```

### 3.2 sim_engine.py — 扩展计分引擎

在现有 `calc()` 函数基础上新增:

**3.2.1 完整忍者效果路由 `full_ninja_routing()`**

参考 `score_effect_collector.gd` 实现以下效果类型:

| 效果类型 | 示例忍者 | 逻辑 |
|----------|---------|------|
| `add_chips` + `condition.hand_type` | 手里剑 | 仅对匹配牌型的组加筹码 |
| `add_chips` + `condition.group` | 蓄勢 | 仅对指定组加筹码 |
| `add_chips_to_rows` + `condition.col_hand_type` | 微波 | 检查列牌型，满足则全行加筹码 |
| `add_mult` + `condition.hand_type` | 并蒂 | 类似筹码 |
| `add_mult` + `condition.group` | 先阵 | 类似筹码 |
| `add_mult_to_rows` + `condition.col_hand_type` | 律動 | 列条件→全行加倍率 |
| `x_mult` + `condition.hand_type` | 风遁 | 匹配组倍率× |
| `x_mult` + `condition.group` | 开局 | 指定组倍率× |
| `x_mult_to_rows` + `condition.col_hand_type` | 閃光 | 列条件→全行倍率× |
| `mult_per_gold` | 金剛力 | 金币→倍率 |
| `x_per_gold` | 黄金律 | 金币→倍率× |
| `xi_x_bonus` | 喜鹊 | 喜倍率+1 |
| `xi_max_mult_stack` | 龙之眼 | 喜按最高结算 |

**3.2.2 列计分优化 `column_scoring_v5()`**

- 每列独立评估牌型
- 散牌(HIGH_CARD_3)列得分为 0
- 忍者效果对列的应用规则:
  - 无条件忍者 → 列也生效
  - hand_type条件忍者 → 检查列牌型是否匹配
  - group条件忍者 → 不生效于列
  - col_hand_type条件忍者 → 不生效于列（这是行级触发条件）

**3.2.3 全量喜检测 `full_xi_detect()`**

参考 `xi_detector.gd` 实现全部 20 项喜 + 3 项合系列:

全局喜: 全黑×2, 全红×2, 全顺×2, 全同花×3, 四张+50筹码, 全三条×4
组级喜: 三清×2, 三顺清×3, 顺清打头×2, 豹子×2
Phase E 喜: 昇龍×3, 背水×4, 貧打×4, 陣眼×3, 均爵×3, 三等×5, 满堂×5
合系列(互斥): 三合×6, 双合×4, 一合×2

### 3.3 sim_runner.py — 模拟编排器

```python
def simulate_run(strategy, budget_ratio):
    """
    模拟一次完整游戏流程（结界1→结界8）
    
    返回: [(barrier, seal, score, passed, ninjas, gold), ...]
    """
    gold = 8
    ninjas = []     # 跨关继承
    results = []
    
    for barrier in 1..8:
        for seal in 0..2:  # 修罗/明王/夜叉
            seal_cfg = load_seal_config(barrier, seal)
            
            # ═══ 打关 ═══
            score = simulate_one_seal(ninjas, gold, strategy)
            passed = score >= seal_cfg.target
            results.append((barrier, seal, score, passed, ninjas[:], gold))
            
            if not passed:
                return results  # 游戏结束
            
            # ═══ 通关奖励 ═══
            gold += seal_cfg.gold_reward
            gold += calc_interest(gold)
            
            # ═══ 商店: 随机展示4张 + 玩家决策 ═══
            if len(ninjas) < 5 and gold >= 3:  # 还有钱才逛商店
                shop_pool = NinjaPool.get_random(4, owned_ids(ninjas))
                to_buy = player_shop_decision(shop_pool, strategy, gold, 
                                              budget_ratio, owned=ninjas)
                gold -= to_buy.cost
                ninjas.append(to_buy)
    
    return results


def player_shop_decision(shop_pool, strategy, gold, budget_ratio, owned):
    """
    模拟玩家在商店面对 4 张随机忍者的购买决策。
    
    Args:
        shop_pool: 商店展示的 4 张忍者
        strategy: 当前构筑方向
        gold: 当前持有金币
        budget_ratio: 预算比例 (0.8 / 0.4)
        owned: 已拥有忍者列表
    
    Returns:
        购买的忍者 (或 None 表示没买)
    """
    max_spend = gold * budget_ratio
    available_slots = 5 - len(owned)
    
    if available_slots <= 0 or max_spend < 3:
        return None  # 没位置或买不起任何东西
    
    # Step 1: 从 4 张中筛选策略匹配的、买得起的
    candidates = [
        n for n in shop_pool
        if matches_strategy(n, strategy)
        and n.cost <= max_spend
    ]
    
    if not candidates:
        # Step 2: 没有策略匹配的 → 考虑刷新一次 (花费 $3)
        refresh_cost = 3
        if gold >= max_spend + refresh_cost:  # 刷新后还有钱买
            shop_pool2 = NinjaPool.get_random(4, owned_ids(owned))
            candidates = [
                n for n in shop_pool2
                if matches_strategy(n, strategy)
                and n.cost <= max_spend
            ]
    
    if not candidates:
        return None  # 真的没有 → 存钱
    
    # Step 3: 按优先级选最好的
    return pick_best_ninja(candidates)
```

### 3.4 忍者选择优先级

```python
NINJA_PRIORITY = {
    "x_mult_to_rows":  10,   # 流光/極光 (全行倍率×)
    "x_mult_hand":      9,   # 雷遁/火遁 (牌型倍率×)  
    "x_mult_group":     8,   # 开局/收官 (定组倍率×)
    "x_per_gold":       7,   # 黄金律 (经济→倍率×)
    "add_mult_to_rows": 6,   # 律動/共鳴 (全行加倍率)
    "mult_per_gold":    5,   # 金剛力 (经济→倍率)
    "add_mult_hand":    4,   # 鼎立/贯月 (牌型加倍率)
    "add_chips_to_rows":3,   # 微波/席卷 (全行加筹码)
    "add_mult_group":   2,   # 先阵/大将 (定组加倍率)
    "add_chips_hand":   1,   # 手里剑 (牌型加筹码)
    "economy_other":    0,   # 福神/利息之印
}

def matches_strategy(ninja, strategy):
    """检查一张忍者是否匹配当前构筑方向"""
    effect = ninja.get("effect", {})
    cond = effect.get("condition", {})
    ht = cond.get("hand_type", -1)
    
    # 直接牌型匹配
    if ht == strategy_to_hand_type(strategy):
        return True
    
    # 列牌型匹配
    col_ht = cond.get("col_hand_type", -1)
    if col_ht == strategy_to_hand_type(strategy):
        return True
    
    # 组定向忍者 — 任何方向都可用
    if cond.get("group", "") in ("head", "mid", "tail", "head_or_mid"):
        return True
    
    # 无条件/经济忍者 — 任何方向都可用
    if not cond:
        return True
    if effect.get("mult_per_gold", 0) > 0 or effect.get("x_per_gold", 0) > 0:
        return True
    
    return False


def pick_best_ninja(candidates):
    """按优先级 + 价格选出最好的忍者"""
    # 先按优先级排序(降序), 同优先级按价格(降序, 越贵越强)
    candidates.sort(key=lambda n: (-classify_priority(n), -n["cost"]))
    return candidates[0]  # 买最好的那张
```

---

## 四、铁律：牌与忍者严格独立

### 4.1 核心原则

> **牌是牌，忍者是忍者，两者独立生成，不能让发牌迎合玩家的忍者牌选择。**

具体含义：

```
玩家决策链路:  选策略 → 商店买忍者 → 独立发牌 → 排列计分
                       ↑              ↑
                   随机出售4张    标准52张无放回抽
                   策略匹配则买    完全随机，不偏袒
```

### 4.2 这意味着什么

- 买了 豹子流 忍者（雷遁+影缝）→ **不代表系统会给你发豹子牌**
- 9 张随机牌大概率不成豹子 → 雷遁 ×6 效果完全浪费
- 买了 同花顺流 忍者（火遁+贯月）→ 9 张随机抽到同色顺子的概率 ~0.5%
- **买了特定牌型忍者 ≈ 赌运气**，大多数时候打水漂

### 4.3 模拟输出的隐式结论

如果某策略的得分曲线接近"无忍者"基线，说明:
- 该策略依赖的牌型在随机发牌下极难凑出
- 玩家选择该策略属于高风险低回报
- 关卡阈值不应基于该策略调整（正常玩家不会选这流派）

### 4.4 效率指标输出

每个场景额外输出 `ninja_trigger_rate`：

```json
{
  "ninja_efficiency": {
    "trigger_rate": 0.15,
    "avg_active_ninjas_per_hand": 1.2,
    "description": "10次中只有1-2次忍者产生了实际效果"
  }
}
```

这能直观看出"你买的这些忍者，实际打牌时用上了几次"。

---

## 五、输出与分析

### 4.1 输出格式（JSON + CSV）

每场景输出:

```json
{
  "scenario": {
    "strategy": "对子流",
    "budget": "extreme",
    "barrier": 3,
    "seal": "明王",
    "target": 3200
  },
  "runs": [
    {"run": 1, "score": 4850, "passed": true, "hands": [2100, 1500, 1250], "ninjas": 4},
    {"run": 2, "score": 3200, "passed": true, "hands": [1200, 1000, 1000], "ninjas": 4},
    ...
  ],
  "stats": {
    "pass_rate": 0.8,
    "p10": 2800,
    "p25": 3200,
    "p50": 4200,
    "p75": 5100,
    "p90": 6000,
    "mean": 4300,
    "std": 1200
  }
}
```

### 4.2 阈值对比表

| 结界 | 封印 | 当前目标 | 对子流P50 | 对子流P75 | 顺子流P50 |
|------|------|---------|----------|----------|----------|
| 1-1 | 修羅 | 300 | ... | ... | ... |
| 1-2 | 明王 | 500 | ... | ... | ... |
| ... | ... | ... | ... | ... | ... |

### 4.3 可视化

每 (strategy, budget) 组合输出一张 HTML 图:

- X 轴: 24 个封印
- Y 轴: 分数（对数刻度）
- 三条线: 当前阈值 / P50 / P75
- 色带: P10-P90 区间

---

## 六、边界与限制

| 限制 | 影响 | 缓解措施 |
|------|------|---------|
| 10 次模拟 | 统计稳定性差（尤其豹子流） | 原型阶段定性观察，后续增加次数 |
| Boss 效果忽略 | Boss 关分数被高估 | 作为安全余量，Boss 关阈值判断留 1.5× 余量 |
| 星图不模拟 | 后期分数被低估 | 结界 6-8 的 P50 判断留 2× 余量 |
| 牌面增强/封印忽略 | 分数略低估 | 同上，统一按安全余量处理 |
| 固定 52 张牌库 | 不模拟牌库膨胀 | 结界 1-4 影响小，结界 5-8 低估可用牌密度 |
| 同花顺流/豹子流概率低 | 10 次可能 0 触发 | 输出跳转统计: "10 次中 X 次触发目标牌型" |
