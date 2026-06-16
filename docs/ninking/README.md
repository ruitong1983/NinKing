# NinKing 设计文档索引

> **最后更新:** 2026-06-16 | **关联:** [`09-mgmt/TODO.md`](09-mgmt/TODO.md)
> **目录结构:** 文档按以下 9 分类存放。每个文档只能归到一个分类，README 提供跨分类索引。

---

## 🎮 核心玩法 (01-gameplay/)

| 文档 | 内容 |
|------|------|
| [`06-complete-redesign.md`](01-gameplay/06-complete-redesign.md) | **核心玩法主文档 (v5.0):** 核心循环、AI排列、计分公式(行+列双维度加总)、喜系统 |
| [`13-blinds-and-bosses.md`](01-gameplay/13-blinds-and-bosses.md) | **关卡与Boss:** 分数目标、10 Boss 设计、AI 适配 |

## 🃏 卡牌系统 (02-cards/)

| 文档 | 内容 |
|------|------|
| [`11-ninja-cards.md`](02-cards/11-ninja-cards.md) | **忍者牌完整参考:** 分类/效果/价格/条件、45 张忍者牌定义、设计原则 |
| [`12-consumable-cards.md`](02-cards/12-consumable-cards.md) | **消耗品独立参考:** 15 附魔 + 6 星图 + 4 秘仪 |
| [`22-display-card-base-spec.md`](02-cards/22-display-card-base-spec.md) | **NinjaCard 规格书:** 统一忍者卡场景 (忍者栏+商店)、交互行为 |
| [`23-ninja-card-expansion-plan.md`](02-cards/23-ninja-card-expansion-plan.md) | **忍者牌扩展方案:** 45→80 张三阶段补齐计划 |

## 🏪 经济与进程 (03-economy/)

| 文档 | 内容 |
|------|------|
| [`14-economy-and-progression.md`](03-economy/14-economy-and-progression.md) | **经济与进程:** 金币/利息/奖励/路线图/待定清单 |

## 🖥️ UI/界面设计 (04-ui/)

| 文档 | 内容 |
|------|------|
| [`06-ui-layout-reference.md`](04-ui/06-ui-layout-reference.md) | **UI 布局参考:** 节点命名/层级结构/场景树路径 (§5 API/信号已移至 06-tech) |
| [`07-shop-ui-design.md`](04-ui/07-shop-ui-design.md) | 商店 UI 设计 |
| [`08-figma-naming-convention.md`](04-ui/08-figma-naming-convention.md) | Figma 命名规范 |
| [`09-launch-ui-design.md`](04-ui/09-launch-ui-design.md) | Launch UI 设计 — 主菜单/牌组选择/继续确认 |
| [`10-main-ui-design.md`](04-ui/10-main-ui-design.md) | Main Game UI 设计 — 游戏主界面完整布局 |
| [`11-main-overlay-design.md`](04-ui/11-main-overlay-design.md) | Main Overlay 设计 — 入场/计分/过关/失败覆盖层 |
| [`24-scoring-ninja-animation.md`](04-ui/24-scoring-ninja-animation.md) | **计分忍者触发动画设计:** 三幕式计分动画、忍者触发视觉反馈、跳过机制 |

## 🎨 美术与资产 (05-art/)

| 文档 | 内容 |
|------|------|
| [`05-image-asset-generation-plan.md`](05-art/05-image-asset-generation-plan.md) | 图像素材 AI 生成方案 |
| [`15-sound-design-plan.md`](05-art/15-sound-design-plan.md) | 音效设计计划 |
| [`16-art-direction-principles.md`](05-art/16-art-direction-principles.md) | **美术方向设计原则:** UI/音效/图像/卡牌/VFX 全局风格规范 |
| [`17-font-design-plan.md`](05-art/17-font-design-plan.md) | **字体设计方案:** 漫画ゴシック体选型/获取/命名/导入/配置 |
| [`18-audio-asset-matching-guide.md`](05-art/18-audio-asset-matching-guide.md) | **音效匹配指南:** Anime Game 素材包 → NinKing 需求逐项映射 |
| [`19-image-asset-matching-guide.md`](05-art/19-image-asset-matching-guide.md) | **图像素材匹配指南:** 现成包匹配 + AI 兜底生成混合策略、三层分类、5 阶段流程 |

## ⚙️ 技术架构 (06-tech/)

| 文档 | 内容 |
|------|------|
| [`03-technical-design.md`](06-tech/03-technical-design.md) | 状态机、场景树、信号架构（技术参考） |
| [`ui-signal-architecture.md`](06-tech/ui-signal-architecture.md) | **UI 信号架构与数据流:** UIManager API 签名、信号定义、GameState 数据流 |

## 📊 数据与数值 (07-data/)

| 文档 | 内容 |
|------|------|
| [`game-save-schema.md`](07-data/game-save-schema.md) | **存档格式 JSON Schema:** 字段说明、存档路径、存档行为 |

## 🧪 测试 (08-testing/)

| 文档 | 内容 |
|------|------|
| [`20-debug-scene-design.md`](08-testing/20-debug-scene-design.md) | **Debug 计分测试场景:** 独立于主场景，52牌选择+忍者/星图测试 |
| [`testing-guide.md`](08-testing/testing-guide.md) | **测试指南:** Godot MCP Pro 测试流程/常见陷阱/命令速查 |

## 📐 项目管理 (09-mgmt/)

| 文档 | 内容 |
|------|------|
| [`90-troubleshooting.md`](09-mgmt/90-troubleshooting.md) | **疑难问题解决手册:** 非显而易见的坑及解决方案 |
| [`TODO.md`](09-mgmt/TODO.md) | **工作清单:** Bug / 待实现 / 优化 / 素材缺口 |
| [`specs/`](09-mgmt/specs/) | **方案文档:** 已归档的实施方案与规格书 |

## 参考资料 (references/)

| 文档 | 内容 |
|------|------|
| [`references/balatro-game-design-cf1.md`](references/balatro-game-design-cf1.md) | Balatro 游戏设计参考 |
| [`references/balatro-joker-design.md`](references/balatro-joker-design.md) | Balatro 小丑牌设计参考 |
| [`references/ninking-balatro-gap-analysis.md`](references/ninking-balatro-gap-analysis.md) | NinKing vs Balatro 差距分析 |

## 🛠️ 工具与可视化

| 文件 | 内容 |
|------|------|
| [`scene-tree-visualizer.html`](scene-tree-visualizer.html) | **场景树可视化 HTML：** 项目全部 .tscn 节点树浏览（双击打开） |
| [`scene-tree-visualizer-methodology.md`](scene-tree-visualizer-methodology.md) | **场景树 HTML 生成/维护方法：** tscn 解析规则、数据格式、更新流程 |
| [`ninja_card_viewer.html`](ninja_card_viewer.html) | **忍者牌数据可视化 HTML：** 双击浏览忍者可选项 |

## 测试数据 (testing/)

| 内容 | 说明 |
|------|------|
| [`testing/`](testing/) | 计分交叉验证测试数据（CSV/JSON） |
| [`testing/automated-formula-testing.md`](testing/automated-formula-testing.md) | 自动化公式测试方法论 |

## 技术参考（docs/ 根目录）

| 文档 | 内容 |
|------|------|
| [`../card-framework-usage-guide.md`](../card-framework-usage-guide.md) | Card-Framework API 速查 |
| [`../tween-library-reference.md`](../tween-library-reference.md) | Tween 三库 API + 选库决策树 |
| [`../vfx-system-design.md`](../vfx-system-design.md) | VFX 底层框架 API |
