---
name: fix-gdscript-warnings
description: 消除 GDScript reload 时产生的 UNUSED_VARIABLE / UNUSED_PARAMETER 警告。用户说 "消除告警" / "fix warnings" 或粘贴 Godot 警告日志时触发。
---

# GDScript 告警消除 · Skill

## 概述

在 Godot 编辑器 reload 脚本时，`UNUSED_VARIABLE` 和 `UNUSED_PARAMETER` 警告会频繁出现。
此 skill 提供结构化的修复流程：定位告警 → 判断处理策略 → 批量修复 → 输出报告。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 "消除告警" / "fix warnings" / "fix gdscript warnings"
- 用户直接粘贴 Godot 编辑器输出的 `UNUSED_VARIABLE` / `UNUSED_PARAMETER` 警告日志
- 用户说 "告警太多" / "清理警告" / "warning 太多"

以下情况**不需**触发：
- 运行时错误（用 `diagnose`）
- GDScript 编译报错（语法错误，不是 warning）
- 纯代码 review（用 `/code-review` 或 `review-plan`）
- 仅查询某文件有哪些警告（不修复）

## 告警模式

Godot 4.6.2 的 GDScript reload 告警有两种，格式固定：

```
W 0:00:03:196   GDScript::reload: The local variable "X" is declared but never used in the block.
                 If this is intended, prefix it with an underscore: "_X".
  <GDScript 错误> UNUSED_VARIABLE
  <GDScript 源文件>file.gd:行号 @ GDScript::reload()

W 0:00:03:481   GDScript::reload: The parameter "X" is never used in the function "f()".
                 If this is intended, prefix it with an underscore: "_X".
  <GDScript 错误> UNUSED_PARAMETER
  <GDScript 源文件>file.gd:行号 @ GDScript::reload()
```

关键字段：告警类型（`UNUSED_VARIABLE` / `UNUSED_PARAMETER`）、文件名、行号、变量/参数名。

## 修复流程

```
用户提供告警日志或指定文件
    │
    ├─ 1. 解析告警来源
    │      从用户粘贴的日志中提取：文件路径、行号、变量名、告警类型
    │      或用户直接指定文件 → 用 Read 或 read_script 读取
    │
    ├─ 2. 逐条判断处理策略
    │   ┌─────────────────────────────────────────────────────┐
    │   │ 变量随后被用到但 linter 误判          → 保留，不改  │
    │   │ 变量是遗留计算/中间值，以后可能有用    → 加 _ 前缀  │
    │   │ 变量明显是死代码（声明后从未使用）     → 删声明行   │
    │   │ 参数未在函数体中用到                   → 加 _ 前缀  │
    │   └─────────────────────────────────────────────────────┘
    │
    ├─ 3. 批量实施修复
    │      同一文件/区块内的同类型告警一次性修完
    │      用 Edit / edit_script 执行改动
    │
    ├─ 4. 验证
    │      用 validate_script 检查脚本是否仍能编译
    │      确认无新告警产生
    │
    └─ 5. 输出修复报告 + 确认
```

## 修复报告格式

修复完成后，按以下格式输出：

```markdown
## GDScript 告警消除报告

### 修复摘要
[共处理 N 条告警，涉及 M 个文件]

### 详细修复记录

| # | 文件 | 行号 | 告警类型 | 变量名 | 处理方式 |
|---|------|------|---------|--------|---------|
| 1 | `file.gd` | 42 | UNUSED_VARIABLE | `temp_score` | 加 `_` 前缀 → `_temp_score` |
| 2 | `file.gd` | 88 | UNUSED_PARAMETER | `index` | 加 `_` 前缀 → `_index` |
| 3 | `file.gd` | 15 | UNUSED_VARIABLE | `old_value` | 删除声明行（死代码） |
| 4 | `file.gd` | 56 | UNUSED_VARIABLE | `result` | 保留（变量随后被使用，linter 误判） |

### 未处理（保留）

| # | 文件 | 行号 | 变量名 | 理由 |
|---|------|------|--------|------|
| 1 | `file.gd` | 56 | `result` | 变量随后被使用，linter 误判 |

### 验证结果

- ✅ 所有修改的脚本编译通过
- ⚠️ [如有] 文件 `xxx.gd` 修改后需在 Godot 编辑器中手动 reload 才生效
```

## 修复决策树

```
告警出现
    │
    ├─ UNUSED_PARAMETER
    │   └─ 参数在函数中从未被使用
    │       → 统一加 `_` 前缀（Godot 推荐的官方做法）
    │       → 如果函数签名要保留语义名 → `_param_name`
    │
    └─ UNUSED_VARIABLE
        │
        ├─ 变量在后续代码中被使用？
        │   ├─ 是 → 保留，不改（linter 误判）
        │   └─ 否 →
        │       ├─ 变量是遗留计算/中间值，可能以后有用？
        │       │   ├─ 是 → 加 `_` 前缀
        │       │   └─ 否 →
        │       │       ├─ 变量声明后立即被另一个同名变量覆盖？
        │       │       │   └─ 是 → 删掉第一处声明（典型：`var gf = gain` 然后直接 `gain`）
        │       │       └─ 否 → 删掉声明行（死代码）
        │       │
        │       └─ 变量是 for 循环中的迭代变量？
        │           └─ `for x in list:` 中 x 未使用 → 改为 `for _x in list:`
```

## 修复原则

- **最小改动** — 优先加 `_` 前缀而非删除，保留代码未来可用性
- **批量处理** — 同一文件内同类型告警一次性修完，避免逐个报警
- **保留判断** — 变量随后被用到但 linter 误判 → 不改，标注留痕
- **死代码删除** — 确认变量确实完全不用才删，而非猜测
- **不引入新问题** — 改完用 `validate_script` 确认编译通过
- **不改逻辑** — 只消除告警，不改变程序行为

## 常见问题文件

以下是 Godot reload 时告警的高发文件（基于项目历史记录）：

| 文件 | 典型问题 |
|------|---------|
| `hand_type_labeler.gd` | 分墩 chips/mult/card_chips 计算后未赋值给 label |
| `animation_handler.gd` | 中间变量声明后直接用了原始值 |
| `shop_slot.gd` | `apply_barrier_theme(_colors)` 兼容包装器 |
| `score_calculator.gd` | 临时计算结果变量未使用 |
| `ninja_bar_node.gd` | 布局辅助变量/参数未用 |

## 项目适配说明

> 此 skill 基于 NinKing 项目的 GDScript 告警模式编写。
> GDScript reload 告警格式在 Godot 4.x 各子版本间一致，可直接复用。
> 如需适配至其他 Godot 项目，修改「常见问题文件」表格即可。
