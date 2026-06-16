## 变更内容

**新增 HTML 可视化体系（自包含页面 + 全自动同步）**

### 🎯 核心变更

| 文件 | 说明 |
|------|------|
| `docs/ninking/ninja_card_viewer.html` | **单文件整合版** — 忍者牌数据 + 喜数据 + 场景树 + 最近更新合为单一 HTML |
| `docs/ninking/html-visualization-guide.md` | **统一可视化指南** — 替代旧的 scene-tree-visualizer-methodology.md |
| `tools/pre-commit` | **自动同步 hook** — commit 时自动更新 HTML |
| `.github/workflows/deploy-pages.yml` | **CI 自动部署** — merge 到 master 自动发布到 GitHub Pages |
| `tools/extract_ninja_data.py` | 从 ninja_data.gd 提取卡牌数据 |
| `tools/extract_xi_data.py` | 从 xi_data.gd 提取喜定义 |
| `tools/tscn_parser.py` | 从 .tscn 解析场景树（注释保留） |
| `tools/inject_recent_updates.py` | 注入最近 git 提交记录 |

### 🗑️ 移除

- `docs/ninking/scene-tree-visualizer.html` — 数据合并入 `ninja_card_viewer.html`
- `docs/ninking/scene-tree-visualizer-methodology.md` — 内容合并入 `html-visualization-guide.md`

### 部署

**Merge 后自动部署**，约 1-2 分钟后：
https://ruitong1983.github.io/NinKing/ninking/ninja_card_viewer.html

🤖 Generated with [Claude Code](https://claude.com/claude-code)
