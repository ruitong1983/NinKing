# 识图能力

你的底层模型不具备原生识图能力。遇到图片时，**不要用 Read 工具**，改用 vision.js：

```
node vision.js "<图片路径>" "用中文描述这张图片"
```

## 触发场景

- 用户分享图片路径（本地或网络 URL）
- 消息中出现 "Saved attachments:" 并列出图片
- 用户要求分析、描述、识别图片内容

## 配置好之后

用户直接发图片，自动识图，无需手动打命令。

---

# Claude Code 开发规范 · Godot 4.6.2 纯2D游戏

## 环境与编码
- Godot 4.6.2 / GDScript 2.0 / 纯2D（禁止任何带 `3D` 后缀的类/节点/API/资源）
- 纯原生开发，不依赖第三方插件/SDK/扩展库，资源路径统一 `res://`
- 命名规范（遵循 Godot 4 官方风格指南）：
  - 文件/目录: `snake_case`（`.gd` 脚本文件同样 `snake_case`，如 `card_data.gd`）
  - 类/节点名: `PascalCase`
  - 函数/变量/信号: `snake_case`，私有加 `_` 前缀
  - 常量/enum 成员: `CONSTANT_CASE`
  - enum 类型名: `PascalCase`
  - 所有变量必须加类型注解
- 节点引用 `@onready`，信号用 `signal` / `emit_signal` / callable 绑定
- 禁用 yield、字符串 connect、`get_node()`、`set_process()`、`export()` 变体等所有 Godot 3.x 旧语法（注: `:=` 是 Godot 4 官方推荐的类型推断语法，允许使用）
- 物理/碰撞/AI → `_physics_process`，动画/UI/渲染 → `_process`
- ⚠️ 文件编码: Godot 资源文件 (.tscn/.tres/.gd/.godot/.cfg) 必须 UTF-8 无 BOM, LF 换行
- ⚠️ 文件操作: 必须用 Read/Write/Edit 工具, 禁止用 PowerShell/Bash 做文件内容读写
- ⚠️ Edit 失败处置（铁律）: .gd 文件 Edit 失败一次 → **立刻改用 Write 重写整个文件**，禁止用 Bash/Python/PowerShell 脚本做字符串替换。理由：shell 脚本改文件会引入 BOM / UTF-16 LE / 中文乱码，且违反上一条规则
- ⚠️ PowerShell 陷阱: `Set-Content -Encoding UTF8` 会加 BOM; `>` / `Out-File` 默认 UTF-16 LE — 都会损坏 Godot 文件

## Tween 特效

> **铁律：** 优先用 `GlobalTweens.xxx()`，减少手写 `create_tween()`。仅在所有已有 API 均不匹配时手写。

**调用规范：** 外部代码只调 `GlobalTweens`（唯一对外入口），不直接调 `TweenFX` 或子系统。`TweenFX` 是纯函数库，`GlobalTweens` 是胶水层 autoload。

完整 API、场景速查 → [`docs/tween-library-reference.md`](docs/tween-library-reference.md)。

## 项目目录结构

```
res://
├── scenes/poking/
├── scripts/
│   ├── poking/      # Poking 核心逻辑（card, deck, evaluator, scorer, joker, shop, save）
│   ├── system/       # 系统级工具（crt_filter, leaderboard, music, range_highlighter）
│   ├── tween/        # 动效框架（tween_fx, screen_shake, hit_stop, card_tilt 等）
│   ├── config/       # 配置/常量
│   └── ui/           # UI 组件
├── assets/
│   ├── images/ui/
│   └── audio/
├── docs/
│   └── poking/       # Poking 设计文档
├── memory/           # 需求池/待做
└── tools/
```

## 设计文档同步

> **铁律：** 涉及游戏机制、数值、UI 布局、关卡、经济等**设计变更**时，同步更新 `docs/poking/` 中的设计文档。

项目设计文档：
- `docs/poking/01-game-design.md` — 核心玩法、规则、UI布局、交互流程
- `docs/poking/02-levels-and-economy.md` — 关卡目标、金币经济、商店定价
- `docs/poking/03-technical-design.md` — 状态机、场景树、信号架构、存档格式
- `docs/poking/04-asset-gap-list.md` — 美术/音效/UI/字体 素材缺口与补齐计划
- `docs/tween-library-reference.md` — Tween 三库 API + 选库决策树
- `docs/vfx-system-design.md` — VFX 底层框架 API

## Code Review 检查项

每次代码审查时额外检查以下五项：

1. **单文件行数**：超过 300 行的 `.gd` 文件标记建议拆分。
2. **重复代码**：多处出现相同/相似的实现逻辑时标记建议抽象。
3. **文件与文件夹命名**：所有资源文件与目录必须 `snake_case`。
4. **函数与方法命名**：所有函数/方法必须 `snake_case`，私有方法加 `_` 前缀。
5. **变量命名**：实例变量、局部变量、`@export` 变量、`@onready` 变量必须 `snake_case`，常量必须 `CONSTANT_CASE`。

---

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
