---
name: update-html
description: 手动触发的 HTML 可视化更新流程。仅当用户明确说「更新HTML」时执行，不随 update-docs 自动触发。
---

# 更新 HTML 可视化 · Skill

## 触发条件

**必须触发**此 skill 的情况：
- 用户明确说「更新HTML」/「update HTML」/「更新可视化」
- 用户说「同步HTML」/「sync HTML」

**不触发**此 skill 的情况：
- 用户说「更新文档」/「update docs」— 走 `update-docs` skill
- 普通代码修改、修 bug、素材替换

## 管辖范围

| HTML 文件 | 内容 | 数据来源 |
|-----------|------|---------|
| `docs/ninking/scene-tree-visualizer.html` | 场景树节点结构可视化 | `scenes/ninking/*.tscn` |
| `docs/ninking/ninja_card_viewer.html` | 忍者牌数据浏览 | `scripts/ninking/ninja_data.gd` |
| `docs/ninking/testing/ninja-test-viewer.html` | 计分/喜测试数据可视化 | `docs/ninking/testing/ninja-test-full.csv` |

## 执行流程

### 1. 询问范围

用户说「更新HTML」时，先确认更新范围：

```
📊 更新HTML，涉及哪些？
  1️⃣ 场景树（scene-tree-visualizer.html）
  2️⃣ 忍者牌（ninja_card_viewer.html）
  3️⃣ 测试/喜（ninja-test-viewer.html）
  4️⃣ 全部
```

如果用户已明确指定范围，跳过此步。

### 2. 场景树 HTML

**方法文档：** `docs/ninking/html-visualization-guide.md` §三

**命令：**
```bash
python tools/tscn_parser.py docs/ninking/scene-tree-visualizer.html
```

**自动同步 pre-commit hook（可选安装）：**
```bash
sh tools/install-hooks.sh
```

**手动更新检查清单：**

按 `docs/ninking/html-visualization-guide.md` §3.5–3.6 执行：

- [ ] 扫描 `scenes/ninking/` 确认无新增/删除的场景文件
- [ ] 运行 `tscn_parser.py` 重新提取节点数据
- [ ] 检查每个场景的节点名/类型/层级与 `.tscn` 一致
- [ ] 检查 `unique_name_in_owner` 节点标记了 `%Name`
- [ ] 检查脚本绑定节点标记了脚本名
- [ ] 检查废弃标注（`.stale-note`）是否完整
- [ ] 打开 HTML 验证折叠/展开功能正常

**补充数据（如 tscn_parser.py 不支持的部分）：**
- 手动在 `SCENES` 中添加 `note` 说明文字
- 手动添加 `unique: true` 标记（如脚本未自动识别）
- 手动添加 `script: 'xxx.gd'` 标记

### 3. 忍者牌 HTML

**方法文档：** `docs/ninking/html-visualization-guide.md` §四

**命令：**
```bash
python tools/extract_ninja_data.py docs/ninking/ninja_card_viewer.html
```

**检查清单：**
- [ ] 确认 `ninja_data.gd` 中的 `ALL_NINJAS` 数据已更新
- [ ] 运行 extract 脚本嵌入数据
- [ ] 打开 HTML 验证筛选/搜索功能正常

### 4. 测试/喜 HTML

**位置：** `docs/ninking/testing/ninja-test-viewer.html`

**数据来源：** `docs/ninking/testing/ninja-test-full.csv`

**检查清单：**
- [ ] 确认测试 CSV 数据是最新的（计分公式/喜检测修改后需要重新生成）
- [ ] 如需重新生成测试数据，走 `docs/ninking/testing/automated-formula-testing.md` 流程
- [ ] HTML 自动读取同目录下的 CSV，无需单独注入

## 执行后检查

- [ ] 所有 HTML 文件在浏览器中打开正常
- [ ] 数据与实际项目状态一致
- [ ] `docs/ninking/html-visualization-guide.md` 已同步（如新增了可视化类型）

## 与 update-docs 的关系

```
用户说「更新文档」 → update-docs skill（不碰 HTML）
用户说「更新HTML」  → update-html skill（仅碰 HTML）
```

两个 skill 互不自动触发。`update-docs` 的同步检查清单中仅提醒「是否需要更新HTML」，但不自动执行。
