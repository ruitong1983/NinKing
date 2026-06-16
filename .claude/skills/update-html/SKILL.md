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
| `docs/ninking/ninja_card_viewer.html` | 忍者牌 + 喜系统 + 场景树（三选项卡合一） | `scripts/ninking/ninja_data.gd` · `scripts/ninking/xi_detector.gd` · `scenes/ninking/*.tscn` |
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

### 2. 忍者牌 + 喜系统 + 场景树（三合一）

**文件：** `docs/ninking/ninja_card_viewer.html` — 三个选项卡合一。

**四个提取脚本依次执行：**

```bash
python tools/extract_ninja_data.py docs/ninking/ninja_card_viewer.html
python tools/extract_xi_data.py docs/ninking/ninja_card_viewer.html
python tools/tscn_parser.py docs/ninking/ninja_card_viewer.html
python tools/inject_recent_updates.py docs/ninking/ninja_card_viewer.html
```

或一行跑完：

```bash
for s in extract_ninja_data extract_xi_data tscn_parser inject_recent_updates; do
  python tools/$s.py docs/ninking/ninja_card_viewer.html || exit 1
done
```

**自动同步 pre-commit hook（可选安装）：**
```bash
sh tools/install-hooks.sh
```

**手动更新检查清单：**
- [ ] 运行四个提取脚本无报错
- [ ] 打开 HTML 验证忍者牌筛选/搜索正常
- [ ] 验证喜系统三张表（基础/Phase E/合）正常显示
- [ ] 验证场景树每个场景可折叠/展开，图例显示正常
- [ ] 最近更新显示最新提交
- [ ] 数据与实际项目状态一致

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

### 5. 部署到 GitHub Pages

HTML 更新完成后，提交并触发部署：

```bash
git add docs/ninking/ninja_card_viewer.html
git commit -m "docs: 同步最新数据到 HTML"
git push
```

然后在 GitHub 上提 PR `dev → master`，merge 后 GitHub Actions 自动部署。

**查看部署状态：** Actions 页面 → `Deploy NinKing Pages` workflow
**访问地址：** `https://ruitong1983.github.io/NinKing/ninking/ninja_card_viewer.html`

