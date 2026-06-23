---
name: review-plan
description: Use when the user says "review方案", "审阅方案", "review plan", or presents an implementation plan/spec for review. Also use when the user asks "这个方案怎么样" or "帮我看看这个设计" with a plan document.
---

# 方案审阅 · Skill

## 概述

对实现方案做结构化审阅，四个维度逐一检查，输出可执行结论。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 "review方案" / "审阅方案" / "review plan"
- 用户说 "这个方案怎么样" / "帮我看看这个设计" 并指向一个方案文档
- 用户贴出一段实现方案文本要求审阅

以下情况**不需**触发：
- 修 bug 的单行改动
- 纯代码 review（用 `/code-review`）
- 提问式讨论（未形成方案）

## 审阅流程

```
用户提交方案
    │
    ├─ 1. 定位方案来源
    │     方案是文件？贴出的文本？口头描述？
    │     Read 方案文件，或直接解析用户贴出的文本
    │
    ├─ 2. 逐维度审阅（四阶段并行收集信息）
    │
    │   ├─ 维度 A：技术实现（可扩展性 & 可维护性 & 健壮性）
    │   │   ├─ 可扩展性：方案是否预留了合理的扩展点？新增/修改需求时改动面是否可控？
    │   │   ├─ 可扩展性：是否引入了过度设计？（500行能做完的设计了1000行？不必要的抽象/模式？）
    │   │   ├─ 可扩展性：有没有更简洁的等价实现？
    │   │   ├─ 可维护性：是否遵循了单一职责？新类/模块的边界是否清晰？
    │   │   ├─ 可维护性：是否有重复代码需要抽象？
    │   │   ├─ 可维护性：单文件是否超过 300 行？（标记建议拆分）
    │   │   ├─ 健壮性：有没有明显的崩溃/边界/竞态/信号重入风险？
    │   │   ├─ 健壮性：有没有节点不在场景树中调用 `create_tween()` 的风险？
    │   │   ├─ 健壮性：有没有快速连续操作导致的状态不一致？
    │   │   └─ 酷炫度：是否利用了 ScreenShake / ParticlePool / HitStop / CRTFilter？关键操作是否有反馈（视觉+音效）？
    │   │
    │   │   ├─ Tween/VFX 合规（技术实现子项）
    │   │   ├─ 扫描方案中所有动效/Tween 描述
    │   │   ├─ 逐条查 `docs/tween-library-reference.md` 场景速查表
    │   │   ├─ 已有 API 能覆盖的 → 标记"用 GlobalTweens.xxx()"
    │   │   ├─ 已有 API 不能覆盖但接近的 → 标记"建议扩展 TweenFX"
    │   │   ├─ 必须手写 create_tween() 的 → 检查是否在附录 B 合理场景中
    │   │   └─ 手写且可复用 → 标记"建议形成基建文件"
    │   │
    │   ├─ 维度 B：交互设计
    │   │   ├─ 整体交互风格是否与现有设计语言一致？（Kenney 暖纸风治愈漫画）
    │   │   ├─ 操作反馈是否一致？同样的操作（点击/悬停/拖拽/长按）是否产生同样的反馈？
    │   │   ├─ 动画/转场节奏是否一致？时长、缓动曲线是否与项目已有的交互模式匹配？
    │   │   ├─ 是否考虑了操作容错？（误触保护、撤销/确认机制、不可逆操作提示）
    │   │   ├─ 是否考虑了极端状态？（空状态、加载中、错误提示、数据溢出）
    │   │   ├─ 输入方式是否统一？同样类型的操作使用同样的手势/按键组合？
    │   │   ├─ 按钮交互合规 — 所有按钮必须通过 `ButtonStyles` 统一管理：
    │   │   │   ├─ Kenney 风 → `ButtonStyles.apply_kenney_long/square(btn, variant)`
    │   │   │   ├─ 属性动态色 → `ButtonStyles.apply_manga(btn, accent, size_tier)`
    │   │   │   ├─ 入口动效 → `ButtonStyles.attach_entrance_animation(btn, config)`
    │   │   │   └─ 严禁散落手写 `add_theme_stylebox_override` 做按钮样式
    │   │   ├─ 面板交互合规 — Panel 节点须匹配 Kenney 暖纸风映射：
    │   │   │   ├─ 纹理 `panel_beige` / `panel_beigeLight`、9宫格 8px、NEAREST 过滤
    │   │   │   ├─ 参考 `docs/ninking/05-art/21-ui-interaction-enhancements.md §3.2` 面板映射表
    │   │   │   └─ 程序化创建 TextureRect 必须显式 `expand_mode = EXPAND_IGNORE_SIZE`
    │   │   ├─ 光标交互合规 — 新控件是否自动获得蓝手悬停？
    │   │   │   ├─ Button / Card 子类自动继承 `CursorManager`
    │   │   │   └─ 非标准控件需手动调用 `CursorManager.set_hover()`
    │   │   ├─ 画风改造边界 — 参考 `kenney-beige-ui-transformation.md §一` 确认哪些已改造/哪些不动
    │   │   └─ 对照 `docs/ninking/04-ui/` 下的 UI 设计文档 + `21-ui-interaction-enhancements.md` 检查交互对齐
    │   │
    │   ├─ 维度 C：游戏机制
    │   │   ├─ 方案提出的游戏机制是否与现有核心玩法冲突？
    │   │   ├─ 数值/概率是否与 `docs/ninking/03-economy/14-economy-and-progression.md` 一致？
    │   │   ├─ 关卡/Boss 设计是否与 `docs/ninking/01-gameplay/13-blinds-and-bosses.md` 一致？
    │   │   ├─ 新机制是否与 `docs/ninking/01-gameplay/06-complete-redesign.md` 中的核心设计原则矛盾？
    │   │   ├─ 新机制引入后，旧有卡牌/技能/敌人是否需要同步调整？
    │   │   ├─ 经济循环是否闭环？（新机制的产出/消耗是否会导致通货膨胀或资源枯竭）
    │   │   └─ 机制复杂度是否合理？是否有足够的新手引导空间？
    │   │
    │   └─ 维度 D：项目一致性
    │       ├─ 对照项目文档清单逐项检查：
    │       │   ├─ `docs/ninking/01-gameplay/06-complete-redesign.md` — 核心玩法/计分/喜
    │       │   ├─ `docs/ninking/03-economy/14-economy-and-progression.md` — 数值/经济
    │       │   ├─ `docs/ninking/06-tech/03-technical-design.md` — 状态机/信号/存档
    │       │   ├─ `docs/ninking/01-gameplay/13-blinds-and-bosses.md` — 关卡/Boss 设计
    │       │   ├─ `docs/ninking/04-ui/06-ui-layout-reference.md` — UI 布局
    │       │   ├─ `docs/ninking/04-ui/07-shop-ui-design.md` — 商店 UI
    │       │   ├─ `docs/ninking/05-art/21-ui-interaction-enhancements.md` — UI 交互增强（面板/按钮/光标样式基线）
    │       │   ├─ `docs/ninking/06-tech/ui-signal-architecture.md` — UI 信号/数据流
    │       │   ├─ `docs/vfx-system-design.md` — VFX 框架设计原则
    │       │   └─ `docs/tween-library-reference.md` — Tween API 使用合规
    │       ├─ 对照 CLAUDE.md 六项 Code Review 检查项：
    │       │   ├─ 新文件是否超过 300 行？（标记建议拆分）
    │       │   ├─ 是否有重复代码？（标记建议抽象）
    │       │   ├─ 文件/目录命名是否 snake_case？
    │       │   ├─ 函数/方法命名是否 snake_case？私有是否加 `_` 前缀？
    │       │   └─ 变量/常量命名是否规范？（snake_case / CONSTANT_CASE）
    │       ├─ 检查方案是否与现有代码结构冲突（文件路径、class_name、autoload）
    │       └─ 检查方案是否引用了不存在的文件/类/资源
    │
    └─ 3. 输出审阅报告 + 确认
            │
            └─ 4. 整理待定工作项 → 与用户确认 → 写入 docs/ninking/09-mgmt/TODO.md
                   │
                   ├─ 从报告中提取所有待办项：
                   │   ├─ 🔴 必须修改 的条目
                   │   ├─ 🟡 建议修改 的条目
                   │   ├─ "待确认事项" 中的 Q 项
                   │   └─ "手写 Tween 清单" 中的任务（在 A 维度中）
                   │
                   ├─ 按 TODO.md 的 Phase 分类（Bug/功能/代码质量/素材）
                   │
                   ├─ 整理成表格 → 展示给用户确认
                   │
                   └─ 用户确认后 → 读取 `docs/ninking/09-mgmt/TODO.md`
                       → 追加到对应 Phase 表格末尾
                       → 更新「变更记录」
```

## 审阅报告格式

审阅完成后，按以下格式输出：

```markdown
## 方案审阅：[方案名称]

### 总体评价
[一段话概括：方案质量、主要风险、推荐与否]

### A. 技术实现（可扩展性 & 可维护性 & 健壮性）

| # | 问题 | 严重度 | 建议 |
|---|------|--------|------|
| A1 | [技术实现问题] | 🔴/🟡/🟢 | [具体改进建议] |

**Tween/VFX 合规（A 维度子项）：**

| 方案中的动效 | 建议实现 | 备注 |
|-------------|---------|------|
| [方案描述的动效] | `GlobalTweens.xxx()` | 已有 API |
| [方案描述的动效] | 需手写 → 建议加入 TweenFX | 见附录 B 场景 X |

**手写 Tween 清单：**
- [ ] [动效名] — 建议放入 `TweenFX` / `scripts/tween/xxx.gd` — 理由：[…]

### B. 交互设计

| # | 问题 | 严重度 | 建议 |
|---|------|--------|------|
| B1 | [交互一致性问题] | 🔴/🟡/🟢 | [具体改进建议] |

### C. 游戏机制

| # | 冲突点 | 涉及文档 | 说明 |
|---|--------|---------|------|
| C1 | [机制冲突] | [文档路径] | [冲突详情] |

**机制影响面：** [新机制对卡牌/技能/敌人/经济的连锁影响分析]

### D. 项目一致性

| # | 冲突点 | 涉及文档 | 说明 |
|---|--------|---------|------|
| D1 | [具体冲突] | [文档路径] | [冲突详情] |

**信号/状态机影响：** [方案对现有状态机/信号流的影响分析]
**文件冲突：** [是否引入重名文件/class_name/autoload 冲突]

### 待确认事项

| # | 问题 | 上下文 |
|---|------|--------|
| Q1 | [需要用户决策的模糊点] | [为什么需要确认] |

---
🔴 必须修改  🟡 建议修改  🟢 锦上添花
```

## 关键检查清单

审阅时逐项核对以下清单，避免遗漏：

### A 维度检查项 — 技术实现
- [ ] 方案是否预留了合理的扩展点？新增/修改时改动面可控？
- [ ] 有没有过度设计？（500行能做完的设计了1000行？）
- [ ] 有没有引入超过 2 层继承/超过 3 个新类？
- [ ] 是否遵循单一职责？新类/模块边界是否清晰？
- [ ] 有没有可复用的代码可以抽象？
- [ ] 单文件是否超过 300 行？
- [ ] 有没有信号重入风险（含 `await` 的 handler）？
- [ ] 有没有节点不在场景树中调用 `create_tween()` 的风险？
- [ ] 有没有快速连续操作导致的状态不一致？
- [ ] 酷炫度：是否利用了 ScreenShake / ParticlePool / HitStop / CRTFilter？
- [ ] 酷炫度：关键操作是否有反馈（视觉+音效）？
- [ ] **Tween/VFX 子项**：方案中每个动效描述 → 先查 `docs/tween-library-reference.md` §场景速查
- [ ] **Tween/VFX 子项**：已有 API 能覆盖的 → 直接标 `GlobalTweens.xxx()`
- [ ] **Tween/VFX 子项**：需手写的 → 检查是否在 tween-library-reference.md 附录 B 的合理场景中
- [ ] **Tween/VFX 子项**：手写且通用 → 建议加入 TweenFX（静态函数）或新建子系统（class_name）
- [ ] **Tween/VFX 子项**：手写 Tween 必须遵循 §5 补间安全清单的 8 项检查
- [ ] **Tween/VFX 子项**：检查方案中是否有 Tween 冲突风险（见 §4.3 防冲突模式）

### B 维度检查项 — 交互设计
- [ ] 整体交互风格是否与现有设计语言一致？（Kenney 暖纸风治愈漫画）
- [ ] 操作反馈是否一致？同样的操作（点击/悬停/拖拽/长按）是否产生同样的反馈？
- [ ] 动画/转场节奏是否一致？时长、缓动曲线是否匹配项目已有交互模式？
- [ ] 是否考虑了操作容错？（误触保护、撤销/确认机制、不可逆操作提示）
- [ ] 是否考虑了极端状态？（空状态、加载中、错误提示、数据溢出）
- [ ] 输入方式是否统一？同样类型的操作使用同样的手势/按键组合？
- [ ] 按钮样式合规：所有按钮通过 `ButtonStyles.apply_kenney_long/square/manga()` 管理，无散落手写样式
- [ ] 按钮动效合规：入口动画/呼吸脉冲/hover/click 通过 `ButtonStyles.attach_entrance_animation()` 管理
- [ ] 面板样式合规：Panel 节点匹配 Kenney 映射（纹理/9宫格 8px/NEAREST），TextureRect 显式设 expand_mode
- [ ] 光标交互合规：Button/Card 自动蓝手悬停，非标准控件手动调 `CursorManager.set_hover()`
- [ ] 对照 `docs/ninking/05-art/21-ui-interaction-enhancements.md` 检查交互增强是否对齐
- [ ] 对照 `docs/ninking/04-ui/` 下的 UI 设计文档检查布局/交互是否对齐
- [ ] 交互是否符合平台惯例？（Godot 桌面游戏的操作习惯）

### C 维度检查项 — 游戏机制
- [ ] 新机制是否与 `docs/ninking/01-gameplay/06-complete-redesign.md` 核心设计原则矛盾？
- [ ] 数值/概率与 `docs/ninking/03-economy/14-economy-and-progression.md` 是否一致？
- [ ] 关卡/Boss 设计与 `docs/ninking/01-gameplay/13-blinds-and-bosses.md` 是否一致？
- [ ] 旧有卡牌/技能/敌人是否需要因新机制而同步调整？
- [ ] 经济循环是否闭环？新机制的产出/消耗是否会导致通胀或资源枯竭？
- [ ] 机制复杂度是否合理？是否有足够的新手引导空间？
- [ ] 新机制是否与已有状态机/信号流兼容？

### D 维度检查项 — 项目一致性
- [ ] 玩法逻辑与 `docs/ninking/01-gameplay/06-complete-redesign.md` 是否一致？
- [ ] 数值/经济与 `docs/ninking/03-economy/14-economy-and-progression.md` 是否一致？
- [ ] 状态机/信号/存档与 `docs/ninking/06-tech/03-technical-design.md` 是否一致？
- [ ] 关卡/Boss 设计与 `docs/ninking/01-gameplay/13-blinds-and-bosses.md` 是否一致？
- [ ] UI 布局与 `docs/ninking/04-ui/06-ui-layout-reference.md` 是否一致？
- [ ] 商店 UI 与 `docs/ninking/04-ui/07-shop-ui-design.md` 是否一致？
- [ ] UI 交互增强与 `docs/ninking/05-art/21-ui-interaction-enhancements.md` 是否一致？
- [ ] UI 信号/数据流与 `docs/ninking/06-tech/ui-signal-architecture.md` 是否一致？
- [ ] VFX 设计原则与 `docs/vfx-system-design.md` 是否一致？
- [ ] Tween API 使用与 `docs/tween-library-reference.md` 是否合规？
- [ ] 方案引用的文件/类/资源是否真实存在？
- [ ] 新文件命名是否遵循 `snake_case`？
- [ ] 新 class_name / autoload 是否与已有冲突？

## 审阅原则

- **方案未提供的信息 → 标记为"待确认"，不猜测**
- **文档没覆盖的领域 → 如实说"文档未记录此部分，无法验证"**
- **不确定的实现细节 → 列出具体问题向用户确认**
- **发现设计文档与方案冲突 → 明确指出冲突点，让用户决策**
- **审阅结论必须可执行**：每条问题都要给出具体的修改建议，而非抽象评价

## 4. 整理待定工作项 → 确认 → 写入 TODO.md

审阅报告输出后，**必须**执行以下流程将待办项落地到 `docs/ninking/09-mgmt/TODO.md`：

### 4.1 提取待办项

从审阅报告中提取所有待定工作项：

| 来源 | 提取内容 |
|------|---------|
| A 维度 🔴/🟡 | 技术实现问题、手写 Tween 清单中的 `- [ ]` 任务 |
| B 维度 🔴/🟡 | 交互设计问题 |
| C 维度 🔴/🟡 | 游戏机制冲突点 |
| D 维度冲突点 | 项目一致性冲突 |
| 待确认事项 Q 项 | 每个需用户决策的模糊点 |

### 4.2 分类映射

按 TODO.md 现有的 Phase 对工作项进行分类：

| 工作项类型 | 映射到 |
|-----------|--------|
| Bug/逻辑错误/崩溃风险 | `## 🐛 Bug 修复` |
| 新功能/机制实现 | `## 🏗️ Phase A/B` 对应阶段 |
| 素材/视觉/UI | `## 🎨 Phase 1-2 — 素材与视觉` |
| 代码质量/重构/命名 | `## 📐 代码质量` |
| 远期/低优先级 | `## 🔒 Phase D-E — 远期（暂缓）` |

### 4.3 向用户确认

整理后的待办项以表格形式展示给用户：

```markdown
### 审阅发现待定工作项，建议加入 TODO.md

| # | 任务 | 分类 | 优先级 | 来源 |
|---|------|------|--------|------|
| R1 | [任务描述] | Bug修复 / 功能 / 代码质量 | P0/P1/P2 | A1 / B1 / C1 |

**请确认：** 哪些项加入 TODO.md？优先级是否合理？有无需要合并/拆分的？
```

### 4.4 写入 TODO.md

用户确认后：

1. **先 Read** `docs/ninking/09-mgmt/TODO.md`（获取最新内容）
2. 将确认的条目**追加到对应 Phase 表格末尾**（分配下一个可用编号）
3. 在「变更记录」表格中追加一行：
   ```
   | YYYY-MM-DD | 📋 **方案审阅: [方案名称]**: R1/R2/... 共 N 项加入 TODO |
   ```
4. 写入文件，确保 UTF-8 无 BOM，LF 换行

### 4.5 确认项处理

- 用户明确说不做的 → 不写入，在报告中标注"用户决定暂缓"
- 用户说"合并到已有任务 X" → 在报告中标注"并入 X"，不新增条目
- 待确认事项 (Q) 用户已答复 → 如形成新任务则加入，否则仅标注结论

## 项目适配说明

> 此 skill 模板源自 FanKing 项目，已为 NinKing 项目适配文档路径。
> 如需同步回 FanKing 或适配至其他项目，修改 §D 维度中的文档路径列表即可。
