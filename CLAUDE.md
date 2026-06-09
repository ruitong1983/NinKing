# 识图：遇图片用 `node vision.js "<路径>" "用中文描述"`，勿用 Read

# ⚠️ Spec-First — 先出方案，再写代码

> **非纯代码的修改请求 → 先输出方案 → 用户确认 → 再动手。优先级最高。**
>
> **触发：** 新增功能/模块、改机制/数值/公式、改UI布局/交互、跨文件重构 — 但凡需要判断"怎么做"就出方案。
> **例外：** 单行修复、精确到行的指令、纯查询。
> **方案：** 列出涉及文件 + 改动概要 + 理由 + 影响面 + 风险（可以只有两行，但必须有）。
>
> Skill（ui-modify-plan / review-plan / update-docs）在方案确认后执行。

# 📋 工作清单 → `docs/ninking/TODO.md`

> 每次会话开始先读取。完成任务后更新状态。

# ⚠️ 任务分派 — 动手前先查 Skill

> 非纯代码任务必须先检查 `.claude/skills/`。Skill 匹配后走完其完整流程。

| 关键词 | Skill | 流程 |
|--------|-------|------|
| 改UI / 调整界面 / 布局 / 按钮 / 配色/字体/间距 | `ui-modify-plan` | 方案 → Figma同步 → 实现 |
| 代码审查 / review | `review-plan` | 对照检查项逐条 |
| 游戏机制/数值/布局变更 | `update-docs` | 判断是否同步 docs/ |

# Claude Code 开发规范 · Godot 4.6.2 纯2D

## 环境与编码
- Godot 4.6.2 / GDScript 2.0 / 纯2D（禁止任何 `3D` 后缀的类/节点/API/资源）
- 纯原生，不依赖第三方插件/SDK/扩展库，路径统一 `res://`
- 命名：文件/目录/函数/变量 `snake_case`，类/节点 `PascalCase`，常量 `CONSTANT_CASE`，私有 `_` 前缀。所有变量加类型注解。
- 节点引用 `@onready`，信号用 `signal` / `emit_signal` / callable 绑定
- 禁用 Godot 3.x 旧语法：yield、字符串 connect、`get_node()`、`set_process()`、`export()` 变体（`:=` 类型推断允许使用）
- 物理/碰撞/AI → `_physics_process`，动画/UI/渲染 → `_process`
- ⚠️ Godot 资源文件 (.tscn/.tres/.gd/.godot/.cfg) 必须 UTF-8 无 BOM, LF 换行
- ⚠️ 文件操作必须用 Read/Write/Edit 工具，禁止 PowerShell/Bash 做文件内容读写
- ⚠️ Edit 失败一次 → 立刻改用 Write 重写整个文件。禁止 shell 脚本做字符串替换（会引入 BOM/UTF-16 LE/中文乱码）
- ⚠️ PowerShell: `Set-Content -Encoding UTF8` 会加 BOM; `>` / `Out-File` 默认 UTF-16 LE

## Card-Framework 卡牌框架

> **铁律：所有卡牌交互（悬停/拖拽/排列/堆叠）必须基于 `addons/card-framework/`，禁止手写轮子。**

API 速查 → `docs/card-framework-usage-guide.md`。扩展类：`NinKingCard` (`scripts/ninking/ui/ninking_card.gd`)、`NinKingCardFactory` (`scripts/ninking/ui/ninking_card_factory.gd`)。

## Tween 特效

> **铁律：优先 `GlobalTweens.xxx()`，减少手写 `create_tween()`。** 外部只调 `GlobalTweens`，不直接调 `TweenFX` 或子系统。

API 速查 → `docs/tween-library-reference.md`。

## 设计文档同步

> **铁律：** 涉及游戏机制/数值/UI布局/关卡/经济的设计变更时，同步更新 `docs/ninking/`。

**设计文档索引 → `docs/ninking/README.md`**

## Code Review 检查项

1. **单文件行数：** 超 300 行 `.gd` 标记建议拆分
2. **重复代码：** 多处相似逻辑标记建议抽象
3. **文件/目录命名：** 必须 `snake_case`
4. **函数/方法命名：** 必须 `snake_case`，私有加 `_` 前缀
5. **变量命名：** 实例/局部/`@export`/`@onready` 必须 `snake_case`，常量 `CONSTANT_CASE`
6. **Card-Framework 复用：** 所有卡牌拖拽/悬停/排列/堆叠必须基于 Card-Framework
