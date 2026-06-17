# HTML 可视化页面 — 生成与维护指南

> **建立日期:** 2026-06-16 | **关联 Skill:** `update-html` · `.claude/skills/update-html/SKILL.md`
> **引用来源:** `CLAUDE.md` · `.claude/skills/update-docs/SKILL.md`

---

## 一、总览

NinKing 项目使用自包含 HTML 页面展示运行时数据/结构的可视化，方便开发时快速查阅。

| HTML 页面 | 数据来源 | 提取脚本 | 触发机制 |
|-----------|---------|---------|---------|
| `scene-tree-visualizer.html` | `.tscn` 场景文件 | `tools/tscn_parser.py` | `.tscn` 变更 → pre-commit |
| `ninja_card_viewer.html` | `ninja_data.gd` | `tools/extract_ninja_data.py` | `ninja_data.gd` 变更 → pre-commit |

**统一模式：**
1. Python 脚本从 GDScript/tscn 中提取结构化数据
2. 将数据嵌入自包含 HTML（作为 JS `const`）
3. Pre-commit hook 自动检测数据源变更并同步

---

## 二、前置条件

```bash
# 安装 pre-commit hook（只需一次）
sh tools/install-hooks.sh
```

安装后，`git commit` 时自动检测 `.tscn` / `ninja_data.gd` 变更并同步对应 HTML。

---

## 三、场景树可视化 — scene-tree-visualizer.html

### 3.1 概览

| 项目 | 说明 |
|------|------|
| **文件** | `docs/ninking/scene-tree-visualizer.html` |
| **数据源** | `scenes/ninking/*.tscn`（9 个场景） |
| **脚本** | `tools/tscn_parser.py` |
| **人工注释** | 按节点路径继承保留 |
| **覆盖场景** | main / launcher / shop / ninja / debug / card / popup / deck / continue |

### 3.2 数据流

```
.tscn 文件 ─→ tscn_parser.py ─→ 读取现有 HTML 提取注释
         │                          │
         │                    按 (scene, 节点路径) 匹配
         │                          │
         ├─ 逐行解析 [node] 条目 ──→ 建树 ──→ 嵌入 SCENES 数据 → HTML
         │   name, type, parent, unique_id, script, instance
         │
         └─ `parent` 字段层级规则:
             无 parent         → 根节点
             parent="."        → 根的直接子节点
             parent="X/Y/Z"    → X/Y/Z 路径下的子节点
```

### 3.3 同步方法

```bash
# 手动同步
python tools/tscn_parser.py docs/ninking/scene-tree-visualizer.html
```

### 3.4 注释继承

脚本读取现有 HTML 的 SCENES 数据，提取所有 `note` 字段，按 `(scene_key, 节点完整路径)` 索引。每次重跑时：

- 路径匹配 → 注释保留
- 节点删除 → 注释输出到 stderr 孤儿列表，人工确认可清理
- 新增节点 → 无注释，可手动添加 `note` 后重跑保留

### 3.5 节点数据格式

```javascript
{ type: 'NodeType', name: 'NodeName', unique?: true, script?: 'file.gd', note?: '说明文字', children?: [...] }
```

| 字段 | 说明 |
|------|------|
| `type` | Godot 节点类型（Control / Label / Button / TextureRect / ColorRect 等） |
| `name` | 节点名称（与 .tscn `name=` 一致） |
| `unique` | `true` 表示 `unique_name_in_owner=true`（%Name 引用） |
| `script` | 脚本文件名（如 `game_manager.gd`） |
| `note` | 人工说明文字（尺寸、颜色、锚点、角色等上下文信息） |
| `children` | 子节点数组 |
| `instance` | 实例化场景文件名（如 `card_manager.tscn`） |

### 3.6 新增场景

1. 在 `tools/tscn_parser.py` 的 `SCENE_MAP` 和 `SCENE_HTML` 中添加条目
2. 在 `scene-tree-visualizer.html` 中添加对应的 `.scene-card` HTML 区块和导航链接
3. 重跑脚本注入数据

---

## 四、忍者牌可视化 — ninja_card_viewer.html

### 4.1 概览

| 项目 | 说明 |
|------|------|
| **文件** | `docs/ninking/ninja_card_viewer.html` |
| **数据源** | `scripts/ninking/ninja_data.gd`（ALL_NINJAS 数组） |
| **脚本** | `tools/extract_ninja_data.py` |
| **数据量** | 43 张（含 2 张 deferred） |

### 4.2 数据流

```
ninja_data.gd ─→ extract_ninja_data.py ─→ 提取 ALL_NINJAS Array[Dictionary]
                                              │
                                          JSON 格式化
                                              │
                                          嵌入 HTML（const NINJAS = ...）
```

### 4.3 同步方法

```bash
# 手动同步
python tools/extract_ninja_data.py docs/ninking/ninja_card_viewer.html

# 生成 inline JS const（供手动嵌入参考）
python tools/extract_ninja_data.py --inline

# 查看原始 JSON
python tools/extract_ninja_data.py
```

### 4.4 卡牌数据字段

```javascript
{ "id": "n_001", "category": "universal", "name": "手里剑",
  "rarity": "common", "cost": 3, "desc": "+10 筹码",
  "effect": {"add_chips": 10} }
```

| 字段 | 说明 |
|------|------|
| `id` | 卡牌 ID（n_001 ~ n_f02） |
| `tags` | 效果标签数组（筹码 / 倍率+ / 倍率X / 经济 / 操控 / 成长 / 特殊） |
| `name` | 卡牌名称 |
| `rarity` | 稀有度（common / uncommon / rare / legendary） |
| `cost` | 售价（传说牌为 999） |
| `desc` | 效果描述文本 |
| `effect` | 效果参数对象 |
| `deferred` | `true` 表示暂缓实现 |
| `mutex_group` | 互斥组 ID |
| `scaling` | 成长参数（触发条件/每次增量/重置条件） |

### 4.5 页面功能

- **筛选**：按稀有度 × 标签交叉筛选
- **搜索**：实时搜索名称/ID/描述（ESC 清空）
- **排序**：ID / 名称 / 费用 ↑↓ / 稀有度
- **展开详情**：点击卡牌查看效果参数、条件、成长数据
- **统计**：稀有度/维度分布柱状图 + 均价统计

---

## 五、如何新增一个 HTML 可视化页面

### 步骤 1：确定数据源

数据源必须是程序可读的结构化数据。NinKing 支持两种源：

| 类型 | 示例 | 提取方式 |
|------|------|---------|
| GDScript 常量 | `const DATA: Array[Dictionary] = [...]` | Python 正则 + ast.literal_eval |
| `.tscn` 文件 | `[node name="..." type="..." ...]` | Python 逐行解析 + 建树 |

### 步骤 2：写提取脚本

模式参考 `tools/extract_ninja_data.py` 或 `tools/tscn_parser.py`：

```python
# 1. 从数据源提取结构化数据
data = extract_data(source_path)

# 2. 生成 JS const 字符串
js = json.dumps(data, ensure_ascii=False)

# 3. 嵌入 HTML（替换占位符或直接写新文件）
embed_into_html(html_path, js)
```

### 步骤 3：创建 HTML 页面

- 自包含（无外部依赖，纯 CSS+Vanilla JS）
- 深色主题（与现有页面风格一致）
- 方便筛选/搜索的数据展示方式

### 步骤 4：注册 pre-commit hook

编辑 `tools/pre-commit`，添加检测和同步逻辑。

### 步骤 5：更新文档

- 在此文档的 §一 总览表中添加新条目
- 在 `.claude/skills/update-docs/SKILL.md` 同步清单中添加检查项
- 在 `CLAUDE.md` 中添加说明

---

## 六、提取脚本通用规范

### 6.1 输出模式

Python 提取脚本应支持三种模式：

```bash
python tools/xxx.py                    # stdout 输出 JSON（检查数据用）
python tools/xxx.py --inline           # 输出 JS const（手动嵌入用）
python tools/xxx.py path/to/page.html  # 直接嵌入 HTML
```

### 6.2 编码要求

- 所有输出必须 **UTF-8 无 BOM**
- 写文件用 `path.write_bytes(content.encode("utf-8"))`（避免 Windows CRLF）
- stdout 输出需设 `PYTHONIOENCODING=utf-8` 或 `sys.stdout.reconfigure(encoding="utf-8")`

### 6.3 注释保留

如果 HTML 有人工注释脚注：

1. 解析现有 HTML 提取注释
2. 按 `(数据源key, 节点路径)` 匹配
3. 重跑时未匹配的注释输出到 stderr 作为孤儿列表

---

## 七、Pre-commit Hook 机制

文件：`tools/pre-commit`

```bash
# 每次 commit 时：
# 1. 检测暂存区是否包含 ninja_data.gd
#    → 是：运行 extract_ninja_data.py 更新 ninja_card_viewer.html → git add
# 2. 检测暂存区是否包含 .tscn 文件
#    → 是：运行 tscn_parser.py 更新 scene-tree-visualizer.html → git add
```

需要在 `tools/install-hooks.sh` 中注册。

---

## 八、常见问题

### 8.1 数据更新后 HTML 未变化

- 检查是否安装了 pre-commit hook：`ls .git/hooks/pre-commit`
- 检查脚本是否有语法错误：`python tools/xxx.py` 是否输出正确 JSON
- 手动重跑验证：直接执行对应的同步命令

### 8.2 注释丢失

- 重跑脚本时 stderr 会输出孤儿注释列表
- 节点路径变更（改名/移动层级）会导致旧注释丢失
- 解决方案：在生成的 HTML 中手动补 `note`，下次重跑自动继承

### 8.3 HTML 显示乱码

- 确认文件 UTF-8 无 BOM
- 确认 `<meta charset="UTF-8">` 在 `<head>` 中
- Windows 下用浏览器直接打开（不要用旧版记事本编辑）

---

## 九、GitHub Pages 部署

> **工作流文件：** `.github/workflows/deploy-pages.yml`

### 9.1 架构

GitHub Actions 自动部署 `ninja_card_viewer.html` 到 GitHub Pages。

```
PR merged to master
    ↓
Actions: Deploy NinKing Pages
    │
    ├─ 1. Checkout 仓库（fetch-depth: 0）
    ├─ 2. 提取 4 种数据注入 HTML（extract_ninja_data / extract_xi_data / tscn_parser / inject_recent_updates）
    ├─ 3. 复制 assets/images/cards/ninjas/ → docs/assets/images/cards/ninjas/   ← CI 时复制，不进 git
    └─ 4. Upload artifact（path: docs/）→ Deploy to Pages
```

### 9.2 关键约束

| 约束 | 说明 |
|------|------|
| **只发布 `docs/`** | `actions/upload-pages-artifact` 的 `path: docs/` 限定，仓库根目录的 `assets/` 不在 Pages 上 |
| **图片需 CI 复制** | `assets/images/cards/ninjas/*.png` 在 CI 中复制到 `docs/assets/images/cards/ninjas/`，不进 git 仓库 |
| **HTML 路径** | `ninja_card_viewer.html` 中图片引用为 `../assets/images/cards/ninjas/{id}.png`（相对于 `docs/ninking/`） |

### 9.3 部署三种方式

| 方式 | 操作 | 说明 |
|------|------|------|
| **A — 快速同步** | 本地跑 4 个提取脚本 | 只更新本地 HTML，不提交 |
| **B — 部署上线** | 修改 → commit → push → `gh pr create` → merge | PR 合入 master 后自动部署 |
| **C — 一步到位** | `bash tools/publish_html.sh --pr` | 提取 + 提交 + PR 一条命令 |

### 9.4 验证部署

1. 访问 `https://ruitong1983.github.io/NinKing/ninking/ninja_card_viewer.html`
2. 确认卡牌图片正常加载（按 F12 → Network 标签检查图片请求无 404）
3. 确认忍者牌/喜系统/场景树三个选项卡数据最新

> **最后更新:** 2026-06-17
