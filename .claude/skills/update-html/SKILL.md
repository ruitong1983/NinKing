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
| `.github/workflows/deploy-pages.yml` | GitHub Pages 自动部署流程 | 维护时注意：**不要加 `cp assets/ → docs/` 步骤**（会覆写已提交的新图）|

## ⚠️ 外部资源依赖（踩坑记录）

`ninja_card_viewer.html` 引用了忍者卡图片 `assets/images/cards/ninjas/<id>.png`，但 HTML 在 `docs/ninking/` 下，相对路径 `../assets/images/cards/ninjas/` 解析为 **`docs/assets/images/cards/ninjas/`** — 与 Godot 项目的 `assets/images/cards/ninjas/` **不是同一个目录**。

**部署时必须将图片从项目根 `assets/` 复制到 `docs/assets/`**，否则 GitHub Pages 上图片 404。

> 已修复：`tools/publish_html.sh` 在 Step 5 自动复制 + `git add`。但如果**手动执行提取脚本**（不走 publish 脚本），必须手动复制图片。

### ⚠️ 踩坑 2：`assets/` 源文件与 `docs/assets/` 不同步（2026-06-18）

**现象：** 用户替换了 `assets/images/cards/ninjas/` 下的素材，部署后网页仍显示旧图。

**根因链：**
```
1. 用户替换 assets/ 下的 PNG ✅
2. publish_html.sh 复制 assets/ → docs/assets/ 并提交 ✅
3. 但 assets/ 本身未 git add/commit ❌ → master 上 assets/ 还是旧图
4. GitHub Actions 部署时执行 cp assets/ → docs/assets/ ❌
5. 旧图覆盖了新图 → 网页展示旧图 ❌
```

**教训：** 两个地方的图片必须同时更新：
- `assets/images/cards/ninjas/` — **Godot 项目源文件**（更换素材后要 `git add`）
- `docs/assets/images/cards/ninjas/` — **GitHub Pages 部署目标**（`publish_html.sh` 自动处理）

**部署前必须确认 `assets/` 已更新：** `git status assets/images/cards/ninjas/`，如有修改先 `git add`。

### ⚠️ 踩坑 3：GitHub Actions 覆写 docs/assets/（2026-06-18）

**问题：** `.github/workflows/deploy-pages.yml` 第 43 行曾有一步 `cp assets/images/cards/ninjas/*.png docs/assets/images/cards/ninjas/`，在 Actions 部署时覆写了 `docs/assets/` 已提交的正确图片。

**修复：** 2026-06-18 删除了该覆写步骤。`docs/assets/` 的图片应由 `publish_html.sh` 负责复制并提交，Actions 不再重复复制。

> 如后续修改 workflow，注意不要在部署时从 `assets/` 复制到 `docs/assets/` — 这会冲掉已提交的正确版本。

## 执行流程

### 1. 询问范围

用户说「更新HTML」时，先确认更新范围：

```
📊 更新HTML，涉及哪些？
  1️⃣ 三合一可视化（忍者牌 + 喜系统 + 场景树）
  2️⃣ 测试/喜（ninja-test-viewer.html）
  3️⃣ 全部
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
- [ ] **确认 `assets/images/cards/ninjas/` 源文件已更新**（`git status assets/images/cards/ninjas/`）
- [ ] 如源文件有修改，**先 `git add assets/images/cards/ninjas/` 提交素材变更**
- [ ] 复制忍者卡图片到 `docs/assets/images/cards/ninjas/`（`cp assets/images/cards/ninjas/*.png docs/assets/images/cards/ninjas/`）
- [ ] `git add docs/assets/images/cards/ninjas/`
- [ ] 打开 HTML 验证忍者卡筛选/搜索正常
- [ ] 验证忍者卡图片正常显示（无裂图）
- [ ] 验证喜系统三张表（基础/Phase E/合）正常显示
- [ ] 验证场景树每个场景可折叠/展开，图例正常显示
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

### 5. 部署到 GitHub Pages — 三大自动化流程

HTML 更新后，有三种方式部署上线：

---

#### Flow A — 快速同步（仅更新本地 HTML）

我自动执行 4 个提取脚本注入最新数据到 `ninja_card_viewer.html`，不做提交。
⚠️ 快速同步不包括图片复制，如需查看图片效果请同步复制忍者卡图片：
```bash
mkdir -p docs/assets/images/cards/ninjas
cp assets/images/cards/ninjas/*.png docs/assets/images/cards/ninjas/
```

适用场景：只想看看最新数据效果，不提交不推送。

```
用户说"更新HTML" → 询问"快速同步还是部署上线？" → 选"快速同步"
    │
    ├─ 我：跑 4 个提取脚本 → 校验 → 输出结果
    └─ ⚠️ 记得手动复制忍者卡图片（见上方命令）
```

#### Flow B — 部署上线（推荐）

我自动执行 提取 + 提交，然后让你跑一条命令完成推送 + PR。

⚠️ **部署前先确认 `assets/images/cards/ninjas/` 源文件已更新：**
- 运行 `git status assets/images/cards/ninjas/` 检查是否有修改
- 如有修改，先 `git add assets/images/cards/ninjas/` 提交素材变更
- 否则 Actions 部署时 `docs/assets/` 的图片可能来源仍然是旧素材

```
用户说"更新HTML" → 询问 → 选"部署上线"
    │
    ├─ 我：检查 assets/ 源文件是否有变更
    ├─ 我：跑 4 个提取脚本 → 复制图片 → 校验
    ├─ 我：git add + git commit
    └─ 你：! bash tools/publish_html.sh --pr
              └─ 推送 + 自动创建 PR → 你去 GitHub 点 Merge
                   └─ GitHub Actions 自动部署到 Pages
```

**查看部署状态：** Actions 页面 → `Deploy NinKing Pages` workflow
**访问地址：** `https://ruitong1983.github.io/NinKing/ninking/ninja_card_viewer.html`

#### Flow C — 一步到位（单命令）

你在终端直接跑，全部自动化：

```bash
! bash tools/publish_html.sh --pr
```

⚠️ **前置检查：** 运行前先确认 `assets/images/cards/ninjas/` 已更新到最新素材：
```bash
git status assets/images/cards/ninjas/     # 检查有无修改
# 如有修改，先提交：
git add assets/images/cards/ninjas/
git commit -m "fix: 同步忍者卡素材"
```

发布脚本做完所有事：
1. ✅ 跑 4 个提取脚本（忍者牌 / 喜系统 / 场景树 / 最近提交）
2. ✅ 复制忍者卡图片到 `docs/assets/images/cards/ninjas/`
3. ✅ 校验 HTML 完整性（卡牌数 > 0、场景存在）
4. ✅ `git add`（HTML + 图片）+ `git commit`
5. ✅ `git push origin dev`
6. ✅ `gh pr create`（dev → master）
7. 输出 PR 链接 → 你去 GitHub 点 Merge → Actions 自动部署

> 如果只想提交不推送跑：`! bash tools/publish_html.sh`

#### 脚本参数

```bash
bash tools/publish_html.sh           # 更新HTML + 本地提交
bash tools/publish_html.sh --pr      # 更新HTML + 提交 + 推送 + 创建PR
bash tools/publish_html.sh --help    # 显示帮助
```

