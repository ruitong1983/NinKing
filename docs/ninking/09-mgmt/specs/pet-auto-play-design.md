# 忍猫自走棋 — 宠物自动消除设计案

> **状态:** 方案已定，待实施 | **日期:** 2026-06-24
> **Grill 决策汇总，共 18 轮问答**

---

## 概述

在现有消除模式（clean mode）上新增"忍猫自走棋"玩法：AI 猫自动决策每一步交换，玩家按压"执行"按钮确认，全程旁观。开局选定猫的性格（5 种不可改），每大局（barrier）结束后玩家调教算法——对战日志 + 可编辑提示词 → HTTP 调 Anthropic API → 在该猫性格框架内优化 → 返回新算法 → validate → 写入该猫文件。

玩家不再手动拖牌，角色从"玩家"转为"猫主人"。

---

## 设计决策

| 决策 | 结论 |
|------|------|
| 宠物存在形式 | UI 装饰精灵 + 独立算法模块 (`PetAlgorithm` RefCounted) |
| 建议内容 | 精确输出 `{src_idx, tgt_idx}` |
| 交互流程 | AI 思考→高亮→玩家按"执行"→自动交换→chain动画→AI 再思考 |
| 玩家可否拒绝 | 否，只能执行（卡片拖拽在宠物模式下被禁用） |
| 询问次数 | 每步都可问（无限次） |
| 算法载体 | `.gd` 骨架 + `AI EDITABLE ZONE` 标记区 |
| 策略框架 | 性格驱动（5 种性格，开局确定，不可更改） |
| 初始算法 | 性格基础策略 + 随机抖动 15% |
| 天花板 | ~85%（性格约束下最优），不同性格差距 ≈5% |
| 进化时机 | 每个 barrier 结束后 |
| 进化方式 | 游戏内面板 → 日志+提示词 → HTTP Anthropic API → validate → 写入 |
| 日志内容 | 每步 `{board, ai_suggested, result}` + barrier 汇总，无 ground truth |
| API Key | 先硬编码在配置中 |
| MVP 范围 | 1 只宠物 + 1 个算法基线 |
| 商店 | 保留，玩家手动操作（猫不介入） |

---

## 宠物性格

### 核心理念

宠物性格 = 对局面的**不同估值体系**，而非"缺根筋"。每只猫都有完整的决策能力，只是**优先注意到什么不同**。同等调教水平下，五种性格胜率差距控制在 5% 以内。

性格在开局确定（随机 roll 或三选一），之后**不可更改**。LLM 调教只能在性格框架内优化策略参数，不能把一条"先读"猫训练成"即断"猫。

### 五种性格

| 性格 | 核心理念 | 估值倾向 | 自然优势局 | 自然劣势局 |
|------|---------|---------|-----------|-----------|
| **先读** | 优先评估连锁潜力，宁舍小分等大 combo | 潜在连锁价值 ×1.5 | 高连锁密度的牌序 | 连锁稀疏的散牌局 |
| **即断** | 当前可消最高分立即执行，不猜未来 | 当前确认值 ×1.2，预测值 ×0 | 散牌局、稳定输出 | 有隐藏连锁的局 |
| **同调** | 倾向同花色聚集，为同花/同花顺布局 | 同花色相邻 +30% | 花色集中的牌序 | 花色均匀的牌序 |
| **顺序** | 倾向连续数字排列，为顺子/豹子布局 | 连续数字相邻 +30% | 数字成段的牌序 | 数字跳跃的牌序 |
| **均衡** | 维持手牌类型多样性，不压注单一策略 | 多样性冗余 +10% | 不被任何局面针对 | 单一策略绝对最优时 |

### 为何每只猫都不弱

- **先读 vs 即断**：不是"聪明 vs 笨"，而是"看长远 vs 看当下"。先读在连锁稀少的局里可能等空；即断在有隐藏连锁的局里会错过。两种策略在不同局面下各有优劣，无法互相替代。
- **同调 vs 顺序**：两种同分的牌型路线——前者走花色，后者走数字。在任意局面下至少有一条路可行。不存在"花色和数字都不行"的绝境（因为豹子/同花顺覆盖两者）。
- **均衡**：放弃极端路线的爆发上限，换来不被任何局面制裁的稳定性。是五种性格的锚——其他四种性格的调教上限是对标均衡的。

---

## 涉及文件

### 新建 (11 个)

| 文件 | 类型 | 用途 |
|------|------|------|
| `scripts/ninking/pet/pet_algorithm_base.gd` | RefCounted | 共享保护区 helper（拷贝手牌、交换、评分） |
| `scripts/ninking/pet/pet_algorithm_sente.gd` | RefCounted (extends base) | 先读猫策略，含 AI EDITABLE ZONE |
| `scripts/ninking/pet/pet_algorithm_sokudan.gd` | RefCounted (extends base) | 即断猫策略，含 AI EDITABLE ZONE |
| `scripts/ninking/pet/pet_algorithm_douchou.gd` | RefCounted (extends base) | 同调猫策略，含 AI EDITABLE ZONE |
| `scripts/ninking/pet/pet_algorithm_junjo.gd` | RefCounted (extends base) | 顺序猫策略，含 AI EDITABLE ZONE |
| `scripts/ninking/pet/pet_algorithm_kinkou.gd` | RefCounted (extends base) | 均衡猫策略，含 AI EDITABLE ZONE |
| `scripts/ninking/pet/pet_controller.gd` | Node (class_name) | 主协调器，管理建议/执行/进化循环 + 性格注册表 |
| `scripts/ninking/pet/pet_highlight.gd` | Control (class_name) | 金色边框 + 虚线连线 + 执行按钮 |
| `scripts/ninking/pet/pet_sprite.gd` | TextureRect (class_name) | 右下角猫精灵（待机/思考动画） |
| `scripts/ninking/pet/pet_logger.gd` | RefCounted | 猫专用日志，调 `GameRunLogger.on_custom_event()` |
| `scripts/ninking/pet/pet_train_panel.gd` | Control (class_name) | 进化面板 UI |
| `scripts/ninking/pet/pet_api_client.gd` | RefCounted | HTTP 调 Anthropic Messages API |

### 修改 (6 个)

| 文件 | 改动 |
|------|------|
| `scripts/ninking/game_state.gd` | 新增 `pet_auto_mode: bool` + 状态切换时禁用卡片拖拽 |
| `scripts/ninking/ui/game_manager.gd` | 创建 PetController/PetSprite/PetHighlight，连接信号，新增 `_on_pet_execute()` |
| `scripts/ninking/ui/ninking_card.gd` | VisualState 枚举新增 `PET_SUGGEST`，`set_visual_state()` 处理金色闪烁 |
| `scripts/ninking/ui/ui_manager.gd` | `show_view()` 控制宠物可见性 |
| `scripts/ninking/clean_chain_handler.gd` | chain 完成后通知 pet_controller 自动请求下一建议 |
| `config/game_config.json` + `scripts/config/config_manager.gd` | 新增 pet 配置项 |

---

## 数据流

```
SEAL_INTRO → PLAYING
  → PetController._on_playing() → request_suggestion()
  → personality_algo.advise(hand, ninjas) → {src_idx, tgt_idx}
    (personality_algo = 当前猫的算法文件实例)
  → PetHighlight.show(src, tgt) → 金色边框脉冲 + 虚线
  → 玩家点"执行"
  → PetController.execute_suggestion()
    → ui.card_grid.set_cards_interactable(false)  [拖拽锁]
    → NinKingGameState.swap_cards(src, tgt)
      → CleanController.do_swap() → hand_swapped 信号
      → CleanChainHandler.resolve_clean_chain()  [现有流程]
        → 5 阶段动画 + chain loop
        → ScoreCalculator.calculate_clean()
        → CleanController.finalize_swap()
          → SEAL_COMPLETE / GAME_OVER / PLAYING
  → 如果切回 PLAYING → PetController._on_playing()
    → request_suggestion()  [自动循环，不需再点宠物]
  → 如果切到 SEAL_COMPLETE → PetController._on_seal_complete()
    → 累加 barrier 汇总 → 结算面板显示"忍猫训练"按钮
```

### 关键约束

- **宠物模式下卡片不可手动拖拽**：`HandCardContainer.set_cards_interactable(false)` 在进入 PLAYING + pet_auto_mode 时设置
- **cascading 期间不触发新建议**：`gs.is_cascading()` 为 true 时跳过
- **swaps_remaining <= 0 时停止**：不再请求建议
- **只限 clean 模式**：`_game_mode != "clean"` 时整个宠物系统不激活
- **商店由玩家手动操作**：猫只接管消除阶段的决策，商店保留玩家手动购买。SEAL_COMPLETE → 进入商店 → 玩家操作完毕 → 下一 barrier → 猫继续自动消除

---

## 算法文件设计

### 文件架构：一猫一文件

```
scripts/ninking/pet/
├── pet_algorithm_base.gd       # 共享 helper（保护区，永不发给 AI）
├── pet_algorithm_sente.gd      # 先读猫（extends base）
├── pet_algorithm_sokudan.gd    # 即断猫（extends base）
├── pet_algorithm_douchou.gd    # 同调猫（extends base）
├── pet_algorithm_junjo.gd      # 顺序猫（extends base）
├── pet_algorithm_kinkou.gd     # 均衡猫（extends base）
```

选中一只猫 = 加载对应 `.gd` 文件。物理隔离——LLM 调教时**只能看到这一只猫的代码**，无法偷看或偷渡其他性格逻辑。

### 性格注册表

性格元数据（名称、描述、文件路径）统一在 `pet_controller.gd` 中维护，算法文件本身不包含自己的名字：

```gdscript
# pet_controller.gd
const PERSONALITY_REGISTRY: Dictionary = {
    "sente": {
        "name": "先读",
        "description": "优先评估连锁潜力...",
        "script_path": "res://scripts/ninking/pet/pet_algorithm_sente.gd",
    },
    "sokudan": { ... },
    "douchou": { ... },
    "junjo": { ... },
    "kinkou": { ... },
}
```

算法文件保持纯粹——不声明性格名，只负责策略逻辑。

### 基类 (`pet_algorithm_base.gd`)

```gdscript
extends RefCounted

# --- Protected helpers (never touched by AI) ---
static func _copy_hand(hand: Array) -> Array: ...
static func _swap_in_place(hand: Array, src: int, tgt: int) -> void: ...
static func _score_matches(matches: Array) -> int: ...
static func _evaluate_position(hand: Array, idx: int) -> Dictionary: ...
```

### 个性猫示例 (`pet_algorithm_sente.gd`)

```gdscript
extends "res://scripts/ninking/pet/pet_algorithm_base.gd"

# ============================================================
# AI EDITABLE ZONE BEGIN
# ============================================================

static func advise(hand: Array, ninjas: Array = []) -> Dictionary:
    # Evaluate all possible swaps for chain potential
    var best: Dictionary = {"src_idx": 0, "tgt_idx": 0, "reason": "", "confidence": 0.0}
    var best_score: float = -1.0
    var rng := RandomNumberGenerator.new()
    rng.randomize()

    for src in range(9):
        for tgt in range(src + 1, 9):
            var score: float = _evaluate_chain_potential(hand, src, tgt)
            score += rng.randf() * 0.15  # jitter
            if score > best_score:
                best_score = score
                best = {"src_idx": src, "tgt_idx": tgt, "reason": "chain potential", "confidence": score}

    return best

static func _evaluate_chain_potential(hand: Array, src: int, tgt: int) -> float:
    var copy := _copy_hand(hand)
    _swap_in_place(copy, src, tgt)
    var matches := _find_matches(copy)
    if matches.is_empty():
        return 0.0
    # Score based on match type + estimated cascade depth
    return _score_matches(matches) * _estimate_cascade(copy, matches)

static func _estimate_cascade(hand: Array, matches: Array) -> float: ...
static func _find_matches(hand: Array) -> Array: ...

# ============================================================
# AI EDITABLE ZONE END
# ============================================================
```

- 每个个性猫文件结构相同：`advise()` 入口 + `AI EDITABLE ZONE` + 该猫独有的辅助函数
- 共享 helper 在 base 中，不发 AI
- LLM 只拿到**这一只猫的 EDITABLE ZONE**，看不到其他猫
- 个性猫不声明 `class_name`，通过基类路径继承

### 统一约束

- 签名固定：`static func advise(hand: Array, ninjas: Array = []) -> Dictionary`
- 返回值固定：`{"src_idx": int, "tgt_idx": int, "reason": String, "confidence": float}`
- `AI EDITABLE ZONE` 内的函数签名不得改变（`advise` 调用者固定）

---

## 日志格式

每步记录（调 `GameRunLogger.on_custom_event("pet_step", {...})`）：

```json
{
  "event": "pet_step",
  "detail": {
    "step": 3,
    "board": ["S3","H7","D10","C5","H5","D8","HK","CQ","SA"],
    "ai_suggested": {"src": 2, "tgt": 7},
    "executed": true,
    "result": {
      "matches": [{"type": "同花", "line": "row_0"}],
      "chains": 2,
      "total_score": 340
    }
  }
}
```

Barrier 结束后追加汇总：

```json
{
  "event": "pet_barrier_summary",
  "detail": {
    "barrier": 1,
    "total_steps": 28,
    "avg_score_per_step": 185,
    "seal_results": ["pass", "pass", "pass"],
    "final": "victory"
  }
}
```

---

## 进化面板 (`PetTrainPanel`)

```
┌────────────────────────────────────────────┐
│  忍猫训练 — 结界 1                          │
│ ┌──────────────────┐ ┌──────────────────┐  │
│ │ 本局日志 (只读)    │ │ 提示词 (可编辑)   │  │
│ │ [JSON 摘要]       │ │ ┌──────────────┐ │  │
│ │                   │ │ │ 系统模板      │ │  │
│ │                   │ │ │ + 游戏规则    │ │  │
│ │                   │ │ │ + 日志        │ │  │
│ │                   │ │ │ + 当前算法    │ │  │
│ │                   │ │ │ + 玩家指令    │ │  │
│ │                   │ │ └──────────────┘ │  │
│ └──────────────────┘ └──────────────────┘  │
│                                              │
│  [发送给AI]          [AI 回复预览 (只读)]     │
│                       [应用] [取消]           │
└────────────────────────────────────────────┘
```

流程：
1. "发送给AI" → `PetAPIClient.send(prompt)` → 等待
2. 回复显示在预览区（提取 ```gdscript ``` 代码块）
3. "应用" → `validate_script("pet_algorithm.gd")` → 通过则 `edit_script` 写入 → reload
4. 失败则 toast 提示 + 回退

---

## 提示词模板

```
你是一个消除游戏策略引擎优化器。

## 宠物性格（不可修改）
{personality_name}: {personality_description}

你只能在上述性格框架内优化策略。禁止改变性格本身。
允许修改：什么局面值得等、等多久、概率阈值、权重参数、评价标准、策略偏好强度。
禁止修改：`advise()` 函数签名、基类 helper 调用方式、返回值格式。

## 游戏规则
- 3×3 网格，每步选择两张牌交换位置
- 匹配类型（按优先级）：豹子(5) > 同花顺(4) > 同花(3) > 顺子(2)
- 消除后有重力下落+新牌补充，可能连锁消除
- 每封印有限次交换机会，总分达标则过关

## 当前算法（仅这一只猫的代码）
[{personality_name} 猫的 AI EDITABLE ZONE 内容，不含其他猫]

## 本局对战日志
[JSON 格式的每步记录 + barrier 汇总]

## 你的任务
分析算法在哪些局面下做出了次优决策，在性格约束内改进策略。
只输出 AI EDITABLE ZONE 内的代码，包裹在 ```gdscript ``` 代码块中。
```

---

## 实施顺序 (6 阶段)

### Phase 1: 视觉基础
1. `NinKingCard.VisualState` 加 `PET_SUGGEST` → `set_visual_state()` 处理金色 modulate
2. 创建 `PetHighlight`（金色边框脉冲 + draw_dashed_line + 执行按钮）
3. 创建 `PetSprite`（TextureRect 角落精灵 + 待机/思考动画）

### Phase 2: 算法核心
4. 创建 `pet_algorithm_base.gd`（共享 helper：拷贝手牌、交换、评分、局面评估）
5. 创建 5 只个性猫文件（`pet_algorithm_sente.gd` 等），extends base，各含独立 `AI EDITABLE ZONE`
6. `pet_controller.gd` 中建立性格注册表（名称、描述、文件路径映射）
7. 每种性格实现基础策略（不依赖 LLM 调教即可用）
8. 手动测试：每种性格的 `advise()` 对不同手牌返回有效索引

### Phase 3: 控制器 + 执行流
6. 创建 `PetController`（建议→执行→chain 完成后自动建议的完整循环）
7. `game_state.gd` 加 `pet_auto_mode`，`_transition_to(PLAYING)` 时通知
8. `game_manager.gd` 创建 PetController/PetSprite/PetHighlight，连接信号
9. `clean_chain_handler.gd` → resolve_clean_chain 完成后回调 pet_controller
10. 运行时测试：完整 clean mode 流程，确认自动建议→执行→chain→再建议

### Phase 4: 日志
11. 创建 `PetLogger`（调 `GameRunLogger.on_custom_event`）
12. barrier 结束时聚合汇总数据

### Phase 5: 进化系统
13. 创建 `PetTrainPanel`（日志展示 + 提示词编辑 + AI 回复预览）
14. 创建 `PetAPIClient`（HTTPRequest → Anthropic API）
15. `game_manager.gd` 连接 SEAL_COMPLETE → 显示训练按钮 → 打开面板
16. 实现 `replace_algorithm()`：validate → edit_script → reload

### Phase 6: 配置
17. `game_config.json` + `ConfigManager` 加 `pet_enabled` 等配置项
18. pet_enabled=false 时不创建宠物系统，回归原始 clean 模式

---

## 验证

### 运行时测试（需 Godot 编辑器 + 运行中场景）

1. **Phase 1-3**: 启动 clean mode → 确认宠物精灵出现 → 进入 PLAYING 后自动出现金色高亮 → 点"执行"→ 交换执行 → chain 动画 → 新牌落位 → 自动出现下一建议
2. **卡片锁定**: 宠物模式下尝试手动拖牌 → 应被阻止
3. **跨界检查**: swaps_remaining 归零 → 不再有新建议 → GAME_OVER 正常显示
4. **Phase 5**: 通关一个 barrier → 结算面板出现"忍猫训练"→ 打开 → 编辑提示词 → 发送 → 查看 AI 回复 → 应用 → 下一 barrier 使用新算法
5. **回归**: 关闭 `pet_enabled` → clean mode 恢复原有手动拖牌 → bi-ji 模式不受影响
