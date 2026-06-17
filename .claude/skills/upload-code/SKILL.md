---
name: upload-code
description: 上传代码 — 自动执行 git add . / commit / push。用户说 "上传代码" / "push" / "提交推送" / "sync" 时触发。
---

# 上传代码 · Skill

## 概述

自动化 `git add . → commit → push` 流程，确保每次上传前做基本检查，避免误推/漏提。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 "上传代码" / "上传"
- 用户说 "push" / "提交推送" / "推上去"
- 用户说 "git add commit push" / "帮我提交"
- 用户说 "同步代码" / "更新一下"

以下情况**不需**触发：
- 用户明确说只 `add` 或只 `commit`（不完整同步）
- 用户自行执行了 git 命令并贴了结果
- 涉及 merge / rebase / 分支操作（非简单同步）

## 同步流程

```
用户触发 sync
    │
    ├─ 1. 前置检查
    │   ├─ 检查是否在 git 仓库中（没有则报错退出）
    │   ├─ 检查当前分支（拒绝在 master/main 直接 push）
    │   │   └─ 如果在 master/main → 提示切到 dev 或新建分支
    │   ├─ 检查是否配置了 `.gitattributes` 的编码规则（一次性提醒）
    │   │   └─ 如缺失 → 提示建议添加以下配置确保文件编码一致：
    │   │       *.gd   text utf-8
    │   │       *.tscn text utf-8
    │   │       *.tres text utf-8
    │   │       *.godot text utf-8
    │   │       *.cfg  text utf-8
    │   │       *.md   text utf-8
    │   │       *.json text utf-8
    │   │       *.csv  text utf-8
    │   │       * text=auto
    │   └─ 检查是否有未跟踪/修改文件（没有则提示"无变更，跳过"）
    │
    ├─ 2. 暂存全部（预防遗漏）
    │   ├─ 执行 `git add .` 将工作区所有变更加入暂存区
    │   ├─ 目的：确保后续审查和提交使用同一快照，避免工作区还有未暂存的内容
    │   └─ 不会提交，仅暂存，用户可随时 `git reset` 反悔
    │
    ├─ 3. 审查变更
    │   ├─ 执行 `git status --short` 展示文件清单（按 新增/修改/删除/重命名 分组）
    │   ├─ 执行 `git diff --cached --stat` 展示暂存区中的变更量
    │   │   └─ ⚠️ 使用 `--cached`：因为所有变更都已 `git add .`，不带参数的 `git diff` 会显示为空
    │   └─ 询问用户是否确认同步这些变更
    │       ├─ 确认 → 继续
    │       └─ 拒绝 → 退出（暂存区保留，不丢弃）
    │
    ├─ 4. 获取提交信息
    │   ├─ 从变更内容自动生成建议的提交信息（遵循项目惯用的 conventional commit 格式）
    │   ├─ 展示建议信息给用户
    │   └─ 用户可接受、修改、或自行输入
    │
    ├─ 5. 执行同步
    │   ├─ `git add .`（第 2 步已执行，此步是安全冗余）
    │   ├─ `git commit -m "<提交信息>"`
    │   │   └─ 如果失败（如空提交）→ 提示并退出
    │   ├─ `git push`
    │   │   └─ 如果失败（如远程冲突）→ 提示冲突文件，建议先 pull
    │   └─ 输出同步结果（commit hash + 推送目标）
    │
    └─ 6. 输出报告
```

## 交互设计

### 步骤 3 — 变更审查

展示格式：

```
📂 变更概览
──────────────────────────────
 新增:  3 个文件
 修改:  12 个文件
 删除:  1 个文件
 重命名: 2 个文件

📋 详细清单
  M  scripts/ninking/core/score_calculator.gd       (+42/-8)
  M  scripts/ninking/ui/ninking_card.gd              (+12/-3)
  A  scripts/ninking/core/new_module.gd              (+156/-0)
  D  scripts/ninking/legacy/old_file.gd
  R  docs/old-name.md → docs/new-name.md

──────────────────────────────
确认同步以上变更？(Y/n)
```

### 步骤 4 — 提交信息

根据变更内容自动生成建议信息，格式：

```
<type>: <简短描述>

<可选详细说明>
```

Type 推断规则：
- 新文件为主 → `feat`
- 修复类改动 → `fix`
- 文档改动 → `docs`
- 重构/重命名 → `refactor`
- 素材/资源 → `asset`
- 测试 → `test`
- 混合 → 取占比最大的类型

示例输出：

```
建议提交信息：
  feat: 新增积分倍率计算模块 + 重构卡牌悬停交互

可输入自定义信息，或直接回车接受建议。
```

## 编码规范

> ⚠️ **NinKing 项目铁律：所有 Godot 资源文件必须 UTF-8 无 BOM、LF 换行。**

### 风险场景

| 场景 | 后果 |
|------|------|
| PowerShell `Set-Content -Encoding UTF8` | 文件头带 BOM，Godot 解析报错 |
| PowerShell `>` / `Out-File` 重定向 | 默认 UTF-16 LE，Godot 无法识别 |
| Windows 记事本编辑 `.gd` / `.tscn` | 可能追加 BOM |
| Read/Write/Edit 工具写入 | ✅ 无 BOM 的 UTF-8（正确） |

### 提交前 BOM 检查

`git add .` 之前扫描变更文件中的 `.gd` / `.tscn` / `.tres` / `.godot` / `.cfg`：
- 检查文件头是否包含 UTF-8 BOM（`0xEF 0xBB 0xBF`）→ 如有则报错拒绝提交
- 修复方法：`$c = Get-Content f; [IO.File]::WriteAllText((Resolve-Path f), $c)`（PowerShell）
- 或 VSCode 重新打开 → 右下角 UTF-8 with BOM → 点击选择 Save with encoding → UTF-8

### 推荐 .gitattributes

在项目根目录创建 `.gitattributes`：

```
# 所有文本文件自动换行符规范化
* text=auto

# Godot 资源文件 — 强制 UTF-8 + LF
*.gd    text utf-8
*.tscn  text utf-8
*.tres  text utf-8
*.godot text utf-8
*.cfg   text utf-8

# 文档/配置
*.md    text utf-8
*.json  text utf-8
*.yaml  text utf-8
*.csv   text utf-8

# 二进制 — 不转换
*.png   binary
*.jpg   binary
*.wav   binary
*.ogg   binary
*.ttf   binary
*.import binary
```

## 安全原则

- **禁止直接推 master/main** — 必须在特性/开发分支操作，危险
- **commit 前展示变更内容** — 用户确认后再提交，避免误提交
- **push 失败时不要 force push** — 提示用户先 pull，避免覆盖远程
- **大文件提醒** — 检测到超过 50MB 的文件变更时，警告用户确认是否真的需要加入版本控制
- **不自动 push** — 必须等待用户确认 commit 后的 push 操作（或提供 --yes 参数跳过部分确认）
