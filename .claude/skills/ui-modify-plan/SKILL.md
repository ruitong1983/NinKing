---
name: ui-modify-plan
description: Use when the user requests UI/interface adjustments (布局调整, 界面修改, UI change, 改UI, 调整界面). Also use when user describes a visual/interaction change that affects the game screen layout. Triggers BEFORE any code or Figma changes are made.
---

# UI调整方案 · Skill

## 概述

对 UI 调整需求做**方案先行**的三步流程：出方案 → 确认是否更新 Figma → 实现。所有 UI 层面的改动必须经过此流程，禁止直接改代码。

## 触发条件

以下情况**必须**触发此 skill：
- 用户说 "改UI" / "调整界面" / "修改布局" / "换一下排版"
- 用户描述一个界面视觉/交互变更需求
- 用户要求新增/删除/重排 UI 组件（按钮、面板、标签、手牌区等）
- 用户要求修改配色、字体大小、间距等视觉参数
- 实现方案中包含 `ninking_main.tscn` / `shop.tscn` / `ninking_launcher.tscn` 的场景变更

以下情况**不需**触发：
- 纯逻辑修改（不涉及 UI 节点/布局变化）
- 脚本中的 `@onready` 引用调整（跟随场景变更的被动适配）
- 纯代码重构

## 执行流程

```
用户提出 UI 调整需求
    │
    ├─ 阶段 1: 出方案
    │   ├─ Read 相关设计文档（01-game-design.md / 06-ui-layout-reference.md）
    │   ├─ Read 当前场景文件（.tscn）确认现状
    │   ├─ 输出修改方案，格式如下：
    │   │   ### UI 调整方案
    │   │   ├─ 调整目标: [一句话描述]
    │   │   ├─ 影响范围: [场景文件 / 节点 / 脚本]
    │   │   ├─ 节点变更:
    │   │   │   ├─ 新增: [节点名 (类型) — 用途]
    │   │   │   ├─ 删除: [节点名 — 原因]
    │   │   │   └─ 修改: [节点名 → 改什么]
    │   │   ├─ 布局 ASCII 示意图 (新旧对比)
    │   │   └─ 注意事项: [可能的连锁影响]
    │   │
    │   └─ 等待用户确认方案
    │
    ├─ 阶段 2: 确认 Figma 同步
    │   ├─ 询问用户: "是否同步更新 Figma 设计稿？"
    │   ├─ 若用户选择「是」:
    │   │   ├─ mcp__figma-pilot__figma_status 检查连接
    │   │   ├─ mcp__figma-pilot__figma_execute 执行 Figma 变更
    │   │   └─ 导出对比截图（可选）
    │   └─ 若用户选择「否」或「稍后」:
    │       └─ 记录备忘到 memory/，标记 Figma 待同步
    │
    └─ 阶段 3: 实现
        ├─ 修改 .tscn 场景文件
        ├─ 适配相关 .gd 脚本
        ├─ validate_script 验证
        └─ 更新设计文档（调 update-docs skill 判断）
```

## 阶段 1 方案输出格式

```markdown
## UI 调整方案: [简短标题]

### 调整目标
[一句话描述要达成什么效果]

### 影响范围

| 类型 | 文件 | 变更说明 |
|------|------|---------|
| 场景 | `scenes/ninking/xxx.tscn` | [具体变更] |
| 脚本 | `scripts/ninking/xxx.gd` | [具体变更] |
| 文档 | `docs/ninking/xxx.md` | [需更新的章节] |

### 节点变更清单

**新增节点：**
| 路径 | 类型 | 用途 |
|------|------|------|
| `Parent/NewNode` | Button | [用途] |

**删除节点：**
| 路径 | 原因 |
|------|------|
| `Parent/OldNode` | [原因] |

**修改节点：**
| 路径 | 属性 | 旧值 | 新值 |
|------|------|------|------|

### 布局变更 (ASCII)

**变更前：**
```
[旧布局示意图]
```

**变更后：**
```
[新布局示意图]
```

### 连锁影响
- [可能受影响的其他 UI 组件]
- [可能需要适配的脚本方法]
- [可能冲突的设计文档章节]

### 是否需更新 Figma
- [ ] 是 — 将在阶段 2 同步
- [ ] 否 — 原因: [...]
```

## 阶段 2 Figma 同步规范

### 检查清单
- [ ] `mcp__figma-pilot__figma_status` 确认插件连接
- [ ] 理解当前 Figma 画布结构（`figma_execute` + `figma_query`）
- [ ] 明确要修改/新增/删除的 Figma 节点
- [ ] 执行变更前备份思路（先 query 记录旧状态）

### Figma 变更原则
- **最小修改**：只改受影响的 frame/组件，不动无关区域
- **命名一致**：Figma 节点名与场景 `unique_name_in_owner` 保持一致
- **配色同步**：使用 `docs/ninking/04-ui/06-ui-layout-reference.md` §6 配色速查表中的色值
- **尺寸对应**：Figma 画布尺寸与 Godot 项目分辨率 1920×1080 保持一致

### 常见 Figma 操作模式

1. **替换手牌区**：删除旧卡片节点组 → 创建新布局 frame → 批量创建卡片子节点
2. **修改按钮**：modify 现有按钮的 width/height/fill/text
3. **调整面板**：modify 面板 frame 的 layout 参数
4. **新增组件**：create 新 frame → 设置 layout → 添加子元素

## 阶段 3 实现规范

### 场景文件 (.tscn) 操作
- 优先用 `add_node` / `delete_node` / `update_property` MCP 工具
- 复杂变更可用 `execute_editor_script` 批量操作
- 节点 `unique_name_in_owner` 必须正确设置（直接编辑 .tscn 文件，不用 `set_meta`）
- 变更后 `save_scene` + `get_scene_tree` 验证结构

### 脚本适配
- `ui_manager.gd`：更新 `@onready` 引用、信号绑定、刷新方法
- `game_manager.gd`：更新按钮绑定、状态切换逻辑
- 其他脚本：按需适配

### 验证清单
- [ ] `validate_script` 所有修改的 .gd 文件零错误
- [ ] `get_scene_tree` 确认节点结构正确
- [ ] `get_editor_errors` 无新增报错
- [ ] **场景树文档同步**：更新 `docs/ninking/04-ui/06-ui-layout-reference.md`
      - §2 场景树结构图 — 新增/修改的节点、类型、access_name
      - **颜色标注**：所有 ColorRect/Modulate 颜色值用 `#RRGGBB AA%` 格式注明（如 `#000 65%`）
      - §4 `show_view()` 映射表 — 更新视图可见性
      - **API 签名**：更新 `docs/ninking/06-tech/ui-signal-architecture.md`
- [ ] 调 update-docs skill 判断其他文档是否需要更新

## 项目适配说明

> 此 skill 为 NinKing 项目定制，核心原则：**UI 调整必须先出方案，再确认 Figma，最后实现**。
> 适用于 Godot 4.6.2 纯 2D 项目，配合 godot-mcp-pro 和 figma-pilot MCP 工具使用。
