---
name: update-docs
description: 实现设计变更时，主动检查并更新对应文档。触发时机：涉及游戏机制、数值、UI 布局、关卡、经济等设计层面改动时。
---

# 更新文档 · Skill

## 触发判断

以下情况**必须**触发此 skill：
- 修改游戏规则/玩法机制（牌型、计分公式、Joker 效果、扑克牌逻辑）
- 修改数值/公式（关卡目标、金币经济、商店定价、能力价格、概率表）
- 修改 UI 布局/交互流程（界面结构、按钮功能、用户操作路径）
- 修改状态机/信号架构（GameManager 状态流转、场景切换）
- 新增/删除功能模块

以下情况**不需**触发：
- 修 bug
- 重构/代码整理
- 命名统一
- 素材替换
- 性能优化
- 纯视觉调整（颜色、间距、字号）

## UI 改动 → 必须更新的文档内容

涉及 UI 界面修改（场景节点增删改、布局调整、配色变更）时，需要同步更新的内容：

| 文档 | 必须更新的内容 | 颜色要求 |
|------|---------------|----------|
| `04-ui/06-ui-layout-reference.md` §2 场景树结构图 | 新增/修改的节点：**类型 + access_name + 位置** | **所有 ColorRect/Modulate 色值用 `#RRGGBB AA%` 注明** |
| `04-ui/06-ui-layout-reference.md` §4 `show_view()` 映射表 | 各视图下子视图可见性 | — |
| `04-ui/07-shop-ui-design.md` | 商店面板节点结构 + 配色同步 | 同左 |
| `06-tech/ui-signal-architecture.md` | 新增/变更的 API 签名 + 信号 | — |

> **铁律：** 任何 ColorRect/Modulate 的颜色修改，必须在场景树中注明色值，不接受"见代码"的省略。

## 项目文档清单与维护范围

| 文档 | 维护范围 |
|------|----------|
| `docs/ninking/01-gameplay/06-complete-redesign.md` | 核心玩法、计分公式、喜系统、AI排列 |
| `docs/ninking/01-gameplay/13-blinds-and-bosses.md` | 关卡目标、Boss 机制、封印值 |
| `docs/ninking/02-cards/11-ninja-cards.md` | 忍者牌定义、稀有度、效果维度 |
| `docs/ninking/02-cards/12-consumable-cards.md` | 附魔卡、星图卡、秘仪卡 |
| `docs/ninking/02-cards/22-display-card-base-spec.md` | 忍者卡场景规格、交互行为 |
| `docs/ninking/03-economy/14-economy-and-progression.md` | 金币经济、商店定价、路线图 |
| `docs/ninking/04-ui/06-ui-layout-reference.md` | UI 布局参考与场景树规范 |
| `docs/ninking/04-ui/07-shop-ui-design.md` | 商店 UI 设计规范 |
| `docs/ninking/04-ui/09-launch-ui-design.md` | 主菜单/启动 UI |
| `docs/ninking/04-ui/10-main-ui-design.md` | 主游戏界面 UI |
| `docs/ninking/04-ui/11-main-overlay-design.md` | 覆盖层 UI（计分/过关/失败） |
| `docs/ninking/04-ui/24-scoring-ninja-animation.md` | 计分忍者触发动效设计 |
| `docs/ninking/05-art/16-art-direction-principles.md` | 美术方向设计原则、配色规范 |
| `docs/ninking/05-art/17-font-design-plan.md` | 字体选型与配置 |
| `docs/ninking/05-art/18-audio-asset-matching-guide.md` | 音效匹配指南 |
| `docs/ninking/05-art/19-image-asset-matching-guide.md` | 图像素材匹配指南 |
| `docs/ninking/06-tech/03-technical-design.md` | 状态机、场景树、信号架构、存档格式 |
| `docs/ninking/06-tech/ui-signal-architecture.md` | UI 信号定义与数据流 |
| `docs/ninking/07-data/game-save-schema.md` | 存档 JSON Schema |
| `docs/vfx-system-design.md` | VFX 底层框架 API、子系统功能 |
| `docs/tween-library-reference.md` | Tween 三库 API + 选库决策树 |

## 执行流程

### 1. 识别影响范围

完成实现后，对照上表逐项判断：本次改动是否落在某个文档的维护范围内？

### 2. 主动询问

若落在范围内，向用户汇报：

```
📝 本次改动涉及：
- [文档名] → [具体改了什么，映射到文档的哪一章节]
是否需要更新这些文档？
```

### 3. 执行更新

用户确认后：
- Read 目标文档 → 定位具体章节 → Edit 修改 → 更新文档末尾的"最后更新"日期
- 只改受影响的章节，不动无关内容

### 4. 新建文档（如适用）

若改动内容没有对应文档，询问：

```
⚠️ 本次改动暂未找到对应文档。是否需要新建文档来记录？
```

用户确认后，在合适的目录下新建 `.md` 文件，并在本 skill 的文档清单中追加。

## 场景树文档同步（铁律）

> 修改 `.tscn` 场景文件（增/删/改节点名、类型、层级）时，**必须**同步更新对应场景树文档。

| 场景文件 | 对应文档 | 需更新的内容 |
|----------|---------|------------|
| `scenes/ninking/ninking_main.tscn` | `04-ui/06-ui-layout-reference.md` §2 | 节点树全图 + §3 分区描述 |
| `scenes/ninking/ninking_launcher.tscn` | `04-ui/09-launch-ui-design.md` | 场景树 + 交互流程 |
| `scenes/ninking/shop_panel.tscn` | `04-ui/07-shop-ui-design.md` | 节点结构 + 布局参数 |
| `scenes/ninking/ninja_card.tscn` | `02-cards/22-display-card-base-spec.md` | 场景树 + 交互行为 |
| `scenes/ninking/debug_ninking_main.tscn` | `08-testing/20-debug-scene-design.md` | §4 场景树 |
| 新增场景 | 无 → 询问用户是否需要新建文档 | — |

**同步检查清单：**
- [ ] 节点名/类型/层级与 `.tscn` 一致
- [ ] `unique_name_in_owner` 节点标注 `[%Name]`
- [ ] 脚本绑定标注 `[script.gd]`
- [ ] 已删除的节点从文档移除（不要留 `⛔` 注释超过 2 个版本）

## 更新原则

- **最小修改**：只改受影响的部分，不顺手改格式、措辞、结构
- **保持一致性**：匹配文档已有的表格/列表/代码块格式
- **日期标注**：更新文档顶部的 `> 最后更新:` 日期

## 项目适配说明

> 此 skill 模板源自 FanKing 项目，已为 NinKing 项目适配文档路径和触发条件。
> 两个项目的 skill 独立维护，互不影响。
