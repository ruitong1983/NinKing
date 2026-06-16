# 场景树 HTML 可视化 — 生成与维护方法

> **建立日期:** 2026-06-16 | **关联文件:** `scene-tree-visualizer.html`
> **引用来源:** `CLAUDE.md` · `.claude/skills/update-docs/SKILL.md`

---

## 一、概述

`scene-tree-visualizer.html` 是一个自包含的单文件 HTML 页面，用于可视化浏览 NinKing 项目全部 `.tscn` 场景文件的节点树结构。

**用途：**
- 快速查阅场景节点层级，无需打开 Godot 编辑器
- 对照设计文档验证节点名/类型/层级是否对齐
- 新人上手时理解场景结构

**文件位置：** `docs/ninking/scene-tree-visualizer.html`

---

## 二、HTML 文件结构

```
scene-tree-visualizer.html
├── <style>                  CSS：配色、树形布局、折叠动画
├── <body>
│   ├── <h1> + 图例        标题 + 12 种节点类型色块图例
│   ├── .page-nav           场景切换导航栏（锚点链接）
│   ├── .stale-note         废弃场景标注栏
│   └── .scene-card × N    每个场景一张卡片
│       ├── <h2>            文件名
│       ├── .info           根节点信息（类型、尺寸、脚本）
│       └── .tree           树形容器（JS 渲染填充）
└── <script>
    ├── const SCENES = {}   场景树数据（纯 JS 对象）
    ├── renderTree()        递归渲染函数
    └── Object.entries()    初始化循环
```

---

## 三、核心数据结构

所有场景树数据集中定义在 `SCENES` 对象中，key 为场景 ID（与 HTML 中 `id` 属性一致），value 为树节点。

### 节点格式

```javascript
{ type: 'NodeType', name: 'NodeName', unique?: true, script?: 'file.gd', note?: '说明文字', children?: [...] }
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `type` | ✅ | Godot 节点类型：Control / Panel / Label / Button / TextureRect / ColorRect / HBoxContainer / VBoxContainer / GridContainer / ProgressBar / RichTextLabel / ScrollContainer / CardManager 等 |
| `name` | ✅ | 节点名称（与 .tscn `name=` 字段一致） |
| `unique` | ❌ | `true` 表示该节点设了 `unique_name_in_owner=true`（即 `%Name` 引用） |
| `script` | ❌ | 脚本文件名（`ninking_card.gd`），只标注根节点或关键脚本节点 |
| `note` | ❌ | 说明文字——尺寸、颜色、锚点、角色等上下文信息 |
| `children` | ❌ | 子节点数组 |

### 场景 ID → HTML id 映射

SCENES 的 key 必须与 HTML 中 `<div class="scene-card" id="XXX">` 以及 `<div class="tree" id="tree-XXX">` 一致。

初始化循环 `Object.entries(SCENES).forEach(([id, data]) => ...)` 自动匹配 `tree-{id}` 元素渲染，新增场景只需同时添加 SCENES 数据和 HTML 卡片。

---

## 四、从 .tscn 提取数据的方法

### 4.1 理解 .tscn 文本格式

Godot 4.6.2 的 `.tscn` 文件是纯文本，每个节点一个段落：

```
[node name="NodeName" type="NodeType" parent="ParentPath" ...]
```

关键规则：
- **根节点**：没有 `parent=` 属性
- **子节点**：`parent="."` 表示父节点是上一段落（紧邻的根/父节点）
- **深层子节点**：`parent="GrandParent/Parent"` 表示完整的父路径
- **unique_id** ≠ `unique_name_in_owner`。`unique_name_in_owner=true` 才是 `%Name` 标志（4.x 新语法），`unique_id` 是内部 UID 忽略

### 4.2 提取步骤

步骤 1：读取 .tscn 文件，用 Grep 提取所有 `[node ...]` 行

```bash
grep -n '^\[node' scenes/ninking/ninking_main.tscn
```

步骤 2：构建节点层级树

```
[node name="UIManager" type="Control" parent="."]
  └→ parent="." → 根节点的直接子节点

[node name="GameLayout" type="HBoxContainer" parent="UIManager"]
  └→ parent="UIManager" → UIManager 的子节点

[node name="LeftPanel" type="Control" parent="UIManager/GameLayout"]
  └→ parent="UIManager/GameLayout" → GameLayout 的子节点
```

步骤 3：判断 unique_name
- 找 `unique_name_in_owner = true` 字段
- 注意：`unique_id=123456`（只有数字 ID）≠ `unique_name_in_owner=true`
- 4.0+ 新语法只有 `unique_name_in_owner=true` 才产生 `%Name` 引用

步骤 4：判断脚本绑定
- 根节点：`script = ExtResource("id")` 中的文件名
- 子节点同样可绑脚本

步骤 5：记录说明文字
- 从 `text="..."` `theme_override_font_sizes/font_size = N` 等信息推导
- 从 `color = Color(...)` 推导色值
- 从 `offset_*` 推导位置/尺寸
- 从 `custom_minimum_size = Vector2(W, H)` 推导最小尺寸

### 4.3 父子关系判定速查

| parent 值 | 含义 |
|-----------|------|
| 无 | **根节点** |
| `"."` | 上一段落节点（紧邻的前一个节点）的直接子节点 |
| `"UIManager"` | 名为 UIManager 的节点的子节点（在根节点下） |
| `"UIManager/GameLayout"` | UIManager → GameLayout 路径下的子节点 |
| `"UIManager/GameLayout/LeftPanel"` | 三层深度的子节点 |

> **注意**：.tscn 中节点顺序与父子关系强相关——`parent="."` 引用的是文件中**紧邻的前一个** `[node]` 段落，而非最近实例化的节点。解析时必须按文件顺序逐行处理。

### 4.4 实例节点（PackedScene）

tscn 中实例化子场景用：

```
[node name="CardManager" parent="." instance=ExtResource("id_cm")]
```

处理方式：
- 不递归展开实例场景的子树（否则会无限嵌套）
- 在 `note` 中标注子场景来源：`note: 'instance: card_manager.tscn'`
- 如果实例场景有已知的标准结构（如 `ninja_card.tscn`），可在 note 中简述

---

## 五、新增场景卡片流程

### 步骤 1：添加 SCENES 数据

在 `const SCENES = {...}` 中新增条目：

```javascript
my_scene: {
  children: [
    { type: 'Control', name: 'RootNode', script: 'my_script.gd', note: '1920×1080', children: [
      { type: 'Label', name: 'Title', unique: true, note: '"标题" 32px 金' },
      { type: 'Button', name: 'ConfirmBtn', unique: true, note: '"确认" 160×48' },
    ]},
  ]
},
```

### 步骤 2：添加 HTML 卡片

在 `<!-- ===== 场景名 ===== -->` 注释后添加：

```html
<div class="scene-card" id="my_scene">
  <h2>my_scene.tscn</h2>
  <div class="info">根: RootNode (Control) 1920×1080 · <span class="badge-script">my_script.gd</span></div>
  <div class="tree" id="tree-my_scene"></div>
</div>
```

> `id`、`<h2>` 内容、`#tree-` ID 三者必须与 SCENES key 一致。

### 步骤 3：添加导航链接

```html
<a href="#my_scene">my_scene.tscn</a>
```

按字母顺序或逻辑分组插入 `.page-nav` 中。

### 步骤 4：验证

- 打开 HTML 确认折叠/展开正常
- 确认 `unique_name` 节点显示 `%Name` 蓝标
- 确认脚本绑定节点显示 `[script.gd]` 绿标
- 确认废弃标注中不出现活跃场景

---

## 六、废弃场景处理

### 何时标记为废弃

满足以下任一条件：
- `.tscn` 文件无任何有效代码引用（`git grep -l` 返回空或仅文档引用）
- 已被功能对等的另一个场景替代（如 `ninking_debug.tscn` → `debug_ninking_main.tscn`）

### 操作方法

1. 执行 `git rm` 删除文件
2. 将文件名追加到 `.stale-note` 的 `<code>` 列表中
3. 从 `SCENES` 对象和 HTML 卡片中移除对应的场景数据

---

## 七、数据同步时机

任何涉及 `.tscn` 文件修改的操作后，均需检查是否需要更新 HTML：

| 触发操作 | 处理方式 |
|---------|---------|
| 新增场景文件 | 按 §五 流程添加场景卡片 |
| 修改节点名/类型/层级 | 更新对应 SCENES 条目中的节点数据 |
| 修改 `unique_name_in_owner` | 更新 `unique` 字段 |
| 修改脚本绑定 | 更新 `script` 字段 |
| 删除场景文件 | 按 §六 流程标记废弃并移除数据 |
| 仅修改布局/位置/颜色 | 更新 `note` 中的说明文字 |

---

## 八、节点类型 → CSS 类映射

| Godot 类型 | CSS class | 色标 |
|-----------|-----------|------|
| Control | `node-control` | 蓝紫 #b8b8ff |
| Panel | `node-panel` | 绿 #8fbc8f |
| PanelContainer | `node-panel` | 绿（同 Panel） |
| Label | `node-label` | 金 #e8c88a |
| Button | `node-button` | 红 #ff8a8a |
| TextureRect | `node-texturerect` | 蓝 #8ac8ff |
| ColorRect | `node-colorrect` | 紫 #c88aff |
| HBoxContainer | `node-hbox` | 青 #8affc8 |
| VBoxContainer | `node-vbox` | 浅绿 #a8e6a8 |
| GridContainer | `node-grid` | 黄 #e8e88a |
| ScrollContainer | `node-scroll` | 青蓝 #8ac8e8 |
| ProgressBar | `node-progress` | 绿青 #8ae8a8 |
| RichTextLabel | `node-richtext` | 橙 #e8b88a |
| CardManager | `node-cardmanager` | 粉 #ff8aff |

新增节点类型需要在 `typeClass()` 映射表（约 line 534）中添加对应项，否则默认使用 `node-control`。

---

## 九、常见错误排查

### 9.1 场景卡片不显示

- 检查 `id` 属性大小写是否与导航链接 `href` 一致
- 检查 SCENES key 是否与 `tree-{id}` 中的 `{id}` 一致
- 检查 JS 控制台是否有语法错误（缺少逗号、花括号不配对）

### 9.2 unique_name 没有 `%` 标记

- `tscn` 中必须是 `unique_name_in_owner = true` 而非仅 `unique_id=...`
- `unique_id` 是 Godot 内部 UID，不产生 `%Name` 引用，不标记

### 9.3 hierarchy 错乱

- .tscn 文件中 `parent="."` 引用的是**紧邻的前一个** `[node]` 段落，按文件顺序逐行解析
- 检查 `parent="ParentName/ChildName"` 路径是否与现有节点名完全匹配

---

## 十、引用

- 维护规则见：`.claude/skills/update-docs/SKILL.md` §「场景树文档同步（铁律）」
- 项目约定见：`CLAUDE.md` §「文档更新」
- HTML 文件：`docs/ninking/scene-tree-visualizer.html`
- 姊妹工具：`docs/ninking/ninja_card_viewer.html`（忍者牌数据可视化，独立方法论见 `CLAUDE.md` §「忍者牌 HTML 可视化同步」）
