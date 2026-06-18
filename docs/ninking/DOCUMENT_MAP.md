# 文档依赖映射 — 代码 → 文档对照表

> **用途：** 每次代码变更后，对照此表检查受影响文档是否需要同步更新。
> **原则：** 改代码前先查此表，改完代码后逐项同步。
> **建立日期：** 2026-06-17 | **最后更新：** 2026-06-18 | 自动生成的 HTML 由 pre-commit hook 触发，不列在此表。

---

## 使用说明

1. 找到你改动的代码文件所在分类
2. 查看"影响文档"列，逐项对照是否需要更新
3. 更新文档后，在 `docs/ninking/09-mgmt/TODO.md` 中标记完成（如有对应条目）
4. 如果新增了代码文件但表中没有映射，**必须加一行到此表**

---

## 一、核心数据定义

### 1.1 `scripts/ninking/card_data.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `02-cards/12-consumable-cards.md` | 附魔/星图/秘仪定义 | 新增/修改消耗品时同步 |
| `01-gameplay/06-complete-redesign.md` | 核心玩法 — 牌型/计分基础 | 牌型表/基础chips×mult/等级公式变更时同步 |
| `02-cards/22-display-card-base-spec.md` | PlayingCard 结构 | 卡牌数据字段变更时同步 |
| `07-data/game-save-schema.md` | 存档格式 | 存档字段引用了 CardData，结构变更时同步 |

### 1.2 `scripts/ninking/ninja_data.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`02-cards/11-ninja-cards.md`** | 忍者牌完整参考 | **每次改忍者牌必同步** — 新增/删除/修改数值/标签 |
| `03-economy/14-economy-and-progression.md` | 价格/经济 | 价格变更、新增经济类忍者牌时同步 |
| `testing/ninja-test-full.csv` | 自动测试数据 | **必须同步** — 新增/修改效果时 gen_test_v2.py 也要更新 |
| `testing/automated-formula-testing.md` | 测试方法论 | 新增机制需要补充测试用例说明时同步 |
| `ninja_card_viewer.html` | HTML 可视化 | 由 pre-commit 自动触发（`tools/extract_ninja_data.py`）⚠️ pre-commit hook 需手动安装：`sh tools/install-hooks.sh` |

### 1.3 `scripts/ninking/consumable_data.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`02-cards/12-consumable-cards.md`** | 消耗品完整定义 | 每次改消耗品必同步 |
| `03-economy/14-economy-and-progression.md` | 价格/经济 | 价格变更时同步 |

---

## 二、计分引擎（`scripts/ninking/score/`）

涉及 6 个文件（`score_calculator.gd` + `score_effect_collector.gd` + `score_group_computer.gd` + `score_xi_handler.gd` + `score_helpers.gd` + `score_result.gd`）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`01-gameplay/06-complete-redesign.md`** | 核心玩法 — §计分公式 | 公式结构/喜×mult/列加分变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 — 计分管线 | 计分流/调用方式变更时同步 |
| `testing/automated-formula-testing.md` | 测试方法论 | 公式变更需要同步说明 |
| `04-ui/24-scoring-ninja-animation.md` | 计分动画 | 计分数据输出格式变更时同步（AnimationHandler 消费端） |
| — `score_helpers.gd` 特有 | 计分基础函数 | 低层数值函数（`group_card_chips` 等）变更时同步 `06-complete-redesign.md` |

---

## 三、排列系统

### 3.1 `scripts/ninking/arrange_controller.gd` + `auto_arranger.gd` + `arrangement.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`01-gameplay/06-complete-redesign.md`** | 核心玩法 — §AI排列 | 排列算法/约束/计分规则变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 | 状态机中排列流程变更时同步 |

### 3.2 `scripts/ninking/hand_evaluator.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `01-gameplay/06-complete-redesign.md` | 核心玩法 — 牌型判定 | 牌型检测逻辑/基础值变更时同步 |

### 3.3 `scripts/ninking/xi_detector.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`01-gameplay/06-complete-redesign.md`** | 核心玩法 — 喜系统 | 新增/修改喜定义时同步 |
| `04-ui/24-scoring-ninja-animation.md` | 计分动画 — 喜×判定 | 喜数据结构变更时同步 |

---

## 四、游戏流程

### 4.1 `scripts/ninking/game_state.gd`（autoload: `NinKingGameState`）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`06-tech/03-technical-design.md`** | 技术架构 — 状态机 | State enum/信号定义/核心字段变更时同步 |
| **`06-tech/ui-signal-architecture.md`** | UI 信号架构与数据流 | 信号定义/emit 时机变更时同步 |
| `07-data/game-save-schema.md` | 存档格式 | 状态字段变更影响存档结构时同步 |

### 4.2 `scripts/ninking/seal_controller.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `01-gameplay/06-complete-redesign.md` | 核心玩法 — 出牌流程 | 出牌流程/计分管线变更时同步 |
| `03-economy/14-economy-and-progression.md` | 金币结算 | `_collect_play_gold()` 逻辑变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 | 游戏状态机转运时同步 |
| — `game_logger.gd` 日志 | 回放日志 — 5 处插桩 | 出牌/换牌/商店进入逻辑变更时同步更新日志调用 |

### 4.3 `scripts/ninking/shop_manager.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`03-economy/14-economy-and-progression.md`** | 经济与进程 | 商店生成逻辑/NINJA_COUNT 变更时同步 |
| `04-ui/07-shop-ui-design.md` | 商店 UI | 商店库存结构变更时同步 |

### 4.4 `scripts/ninking/deck_manager.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `01-gameplay/06-complete-redesign.md` | 牌组系统 | 牌组结构/抽牌逻辑变更时同步 |

### 4.5 `scripts/ninking/ninja_scaling.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `02-cards/11-ninja-cards.md` | 成长修炼卡 | 成长机制/触发条件变更时同步 |
| `01-gameplay/06-complete-redesign.md` | 核心玩法 | 出牌后处理流程变更时同步 |

### 4.6 `scripts/ninking/ninja_pool.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `02-cards/11-ninja-cards.md` | 忍者牌池 | 抽牌逻辑/稀有度权重变更时同步 |
| `03-economy/14-economy-and-progression.md` | 商店生成 | 商店出现率/稀有度分布变更时同步 |

---

## 五、UI 层

### 5.1 `scripts/ninking/ui/ui_manager.gd` + `game_manager.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/06-ui-layout-reference.md`** | UI 布局参考 | 节点命名/层级/场景树变更时同步 |
| **`04-ui/10-main-ui-design.md`** | Main Game UI | 主界面布局/交互变更时同步 |
| **`04-ui/11-main-overlay-design.md`** | Main Overlay | 覆盖层/视图切换变更时同步 |
| `06-tech/ui-signal-architecture.md` | UI 信号架构 | UIManager API 签名变更时同步 |

### 5.2 `scripts/ninking/ui/animation_handler.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/24-scoring-ninja-animation.md`** | 计分动画设计 | 动画流程/时序/跳过机制变更时同步 |
| `docs/tween-library-reference.md` | Tween API | 新增动效如果引入新 Tween 模式需同步 |

### 5.3 `scripts/ninking/ui/shop_handler.gd` + `shop_ui.gd` + `shop_slot.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/07-shop-ui-design.md`** | 商店 UI 设计 | 商店布局/交互/入场动画/槽位逻辑变更时同步 |

### 5.4 `scripts/ninking/ui/hand_display.gd` + `hand_interaction.gd` + `hand_card_container.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 | 手牌容器/交互逻辑变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 | 拖拽/交换逻辑变更时同步 |

### 5.5 `scripts/ninking/ui/hand_type_labeler.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 | 牌型标签显示逻辑变更时同步 |

### 5.6 `scripts/ninking/ui/ninja_bar_container.gd` + `ninja_bar_display.gd` + `ninja_bar_node.gd` + `ninja_inventory_card.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局 — 忍者栏 | 忍者栏布局/交互变更时同步 |
| `02-cards/22-display-card-base-spec.md` | NinjaCard 规格书 | 忍者卡场景规格变更时同步 |

### 5.7 `scripts/ninking/ui/ninking_card.gd` + `ninking_card_factory.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`02-cards/22-display-card-base-spec.md`** | NinjaCard 规格书 | 卡牌节点结构/视觉状态/交互变更时同步 |
| `docs/card-framework-usage-guide.md` | Card-Framework API | 扩展方法/接口变更时同步 |

### 5.8 `scripts/ninking/ui/card_detail_popup.gd` + `card_visual_composer.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 | 详情弹窗/卡牌视觉组合变更时同步 |

### 5.9 `scripts/ninking/ui/dun_highlighter.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 | 三墩高亮逻辑变更时同步 |

### 5.10 `scripts/ninking/ui/result_screen_display.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/11-main-overlay-design.md` | 结果屏幕 | 过关/失败/胜利画面变更时同步 |

### 5.11 `scripts/ninking/ui/deck_viewer_controller.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/09-launch-ui-design.md` | Launch UI | 牌组查看器变更时同步 |

### 5.12 `scripts/ninking/ui/main_menu.gd` + `deck_select_panel.gd` + `continue_panel.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/09-launch-ui-design.md`** | Launch UI 设计 | 主菜单/牌组选择/继续确认变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 | 场景切换/存档读取变更时同步 |

### 5.13 `scripts/ninking/ui/ninja_replace_overlay.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 | 忍者替换交互变更时同步 |

### 5.14 `scripts/ninking/ui/nin_king_tween.gd` + `launch_ambience.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `docs/tween-library-reference.md` | Tween API | 新增公开 Tween 方法时同步 |
| `05-art/15-sound-design-plan.md` | 音效设计 | 背景音乐/环境音变更时同步 |
| `05-art/18-audio-asset-matching-guide.md` | 音效匹配 | 音效素材映射变更时同步 |

---

## 六、场景文件（`.tscn`）

### 6.1 `scenes/ninking/ninking_main.tscn` + `ninking_launcher.tscn`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/06-ui-layout-reference.md`** | UI 布局参考 — §场景树全图 | 节点名/层级/%引用变更时**必须同步** |
| **`04-ui/09-launch-ui-design.md`** | Launch UI — §场景结构 | Launch 场景结构变更时同步 |
| **`04-ui/10-main-ui-design.md`** | Main Game UI — §场景结构 | Main 场景结构变更时同步 |
| `04-ui/11-main-overlay-design.md` | Overlay 设计 | 覆盖层结构变更时同步 |
| `scene-tree-visualizer.html` | HTML 可视化 | 由 pre-commit 自动触发（`tools/tscn_parser.py`）⚠️ pre-commit hook 需手动安装：`sh tools/install-hooks.sh` |

### 6.2 `scenes/ninking/debug_ninking_main.tscn`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`08-testing/20-debug-scene-design.md`** | Debug 场景设计 | 场景结构/按钮/功能变更时**必须同步** |
| **同步铁律：** 主场景修改后，若 Debug 场景有相同节点/脚本，必须同步修改（CLAUDE.md 铁律） |

### 6.3 `scripts/ninking/debug/*.gd`（6 文件：`debug_controller.gd`, `debug_panel.gd`, `debug_card_tray.gd`, `debug_score_detail.gd`, `debug_ninja_selector.gd`, `debug_ui_proxy.gd`）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`08-testing/20-debug-scene-design.md`** | Debug 场景设计 | 新增/修改 Debug 面板/功能/交互时**必须同步** |
| `08-testing/testing-guide.md` | 测试指南 | Debug 场景测试流程变更时同步 |

---

## 七、工具脚本（`tools/`）

### 7.1 `tools/gen_test_v2.py`（或 gen_test_v3.py）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`testing/ninja-test-full.csv`** | 测试数据 | 新增/修改测试用例时**必须重新生成** |
| `testing/automated-formula-testing.md` | 测试方法论 | 生成器逻辑变更时同步 |
| `testing/ninja-test-plan.md` | 测试计划 | 覆盖范围变更时同步 |

### 7.2 `tools/review_test_data.py`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `testing/automated-formula-testing.md` | 测试方法论 | Review 逻辑/报告格式变更时同步 |

### 7.3 `tools/extract_ninja_data.py` + `tools/tscn_parser.py`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `html-visualization-guide.md` | HTML 生成指南 | 提取逻辑/输出格式变更时同步 |
| `scene-tree-visualizer-methodology.md` | 场景树 HTML 维护方法 | 由 pre-commit hook 配合 `tscn_parser.py` 自动同步 |

### 7.4 `tools/calc_engine.py`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `testing/automated-formula-testing.md` | 测试方法论 | 计分计算引擎逻辑变更时同步 |

### 7.5 `tools/simulation/`（`sim_engine.py` + `sim_runner.py` + `sim_config.py` + `sim_analyze.py`）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`08-testing/21-simulation-methodology.md`** | **关卡难度模拟报告** | 新增/修改模拟逻辑、预算模型、策略定义时**必须同步** |
| `08-testing/data/` | 模拟输出（JSON/CSV/HTML） | 每次批量模拟后自动生成，需随代码更新 |
| `01-gameplay/13-blinds-and-bosses.md` | 关卡阈值 | 模拟结论可用于验证/调整关卡目标值 |

### 7.6 `tools/simulation/player_personality.py` + `sim_runner_personality.py`（玩家人格模型）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`08-testing/21-simulation-methodology.md`** §7 | **人格驱动模拟** | 新增/修改人格类型、决策逻辑时**必须同步** |
| `08-testing/data_personality/` | 人格模拟输出（JSON） | 每次批量模拟后自动生成 |
| `03-economy/14-economy-and-progression.md` | 经济系统 | 人格中的经济偏好影响商店经济循环验证 |

---

## 八、关卡与 Boss 设计

### 8.1 `scripts/ninking/barrier_config.gd` + `barrier_theme.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`01-gameplay/13-blinds-and-bosses.md`** | 关卡与 Boss | 封印值/Boss效果/Ante结构变更时**必须同步** |
| `03-economy/14-economy-and-progression.md` | 经济 — 过关奖励 | 奖励数值/利息变更时同步 |

---

## 九、日志系统

### 9.0 `scripts/ninking/logging/game_logger.gd`

> 新增文件时映射。无 class_name，通过 `const GameRunLogger = preload("...")` 引用。

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `docs/ninking/ninja-game-replay.html` | HTML 回放查看器 | 日志事件结构/序列化格式变更时**必须同步**HTML 查看器 |
| `10-ops/logs-operations-guide.md` | 日志运维指南 | 事件表/JSON Schema/排查指南 — game_logger.gd 接口变更时同步 |
| `09-mgmt/TODO.md` | 工作清单 — Phase L | 日志功能变更/新增/修复时同步 |
| 本表（DOCUMENT_MAP.md） | 文档依赖映射 | 新增日志消费者（新插桩点）时同步 |

### 9.1 日志调用的分布

| 调用方文件 | 插桩事件 | 说明 |
|-----------|---------|------|
| `game_state.gd` | run_started, seal_started, cards_dealt, auto_arranged, game_over, victory | 6 处，覆盖 run 生命周期 + 状态转换 |
| `seal_controller.gd` | play_prepared, play_executed, card_swapped, seal_completed, shop_entered | 5 处，覆盖每次出牌/交换/商店进入 |
| `shop_manager.gd` | ninja_acquired, item_purchased | 2 处，覆盖商店购买 |
| `debug_controller.gd` | cards_dealt, auto_arranged, play_prepared, play_executed, card_swapped, debug_layout_changed, game_over | 8 处，覆盖 Debug 场景全部操作 + 退出时落盘 |

---

## 十、存档与配置

### 10.1 `scripts/ninking/save_manager.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`07-data/game-save-schema.md`** | 存档格式 | 存档键名/结构/迁移逻辑变更时**必须同步** |
| `06-tech/03-technical-design.md` | 技术架构 | 存档流程变更时同步 |

### 10.2 `scripts/ninking/asset_registry.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `05-art/05-image-asset-generation-plan.md` | 素材生成计划 | 资产路径/加载逻辑变更时同步 |
| `05-art/19-image-asset-matching-guide.md` | 图像素材匹配 | 资产映射变更时同步 |

---

## 十一、VFX 与 Tween/Shader 系统

### 10.1 `.tscn` 引用的 shader / `scripts/tween/tween_fx.gd` / `global_tweens.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `docs/tween-library-reference.md` | Tween API 参考 | 新增/修改 Tween 方法时同步 |
| `docs/vfx-system-design.md` | VFX 框架设计 | VFX 系统变更时同步 |
| `05-art/16-art-direction-principles.md` | 美术方向 — VFX 风格 | 视觉效果风格变更时同步 |

### 10.2 `scripts/shader/global_shaders.gd` + `shader_fx.gd` + 各子系统

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `docs/shader-library-reference.md` | Shader API 参考 | 新增/修改 Shader 子系统/API 时**必须同步** |
| `05-art/16-art-direction-principles.md` | 美术方向 — VFX 风格 | 新 Shader 效果引入时同步 |
| 本表（DOCUMENT_MAP.md） | 文档依赖映射 | 新增 Shader 子系统时加一行

---

## 十二、音效

### 11.1 `scripts/config/sound_bank.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`05-art/15-sound-design-plan.md`** | 音效设计计划 | 新增/替换/删除音效时同步 |
| **`05-art/18-audio-asset-matching-guide.md`** | 音效匹配指南 | 音效→素材映射变更时同步 |

---

## 十三、设计文档 — 自更新规则

以下文档本身不依赖具体代码文件，但当游戏设计变更时可能需要同步：

| 文档 | 触发条件 | 同步要点 |
|------|---------|---------|
| `05-art/16-art-direction-principles.md` | UI/视觉风格重大变更 | 配色/组件/字体/特效规范 |
| `05-art/17-font-design-plan.md` | 字体/字号变更 | 字体文件/字号表 |
| `05-art/19-image-asset-matching-guide.md` | 素材策略变更 | 匹配策略/图层结构 |
| `02-cards/23-ninja-card-expansion-plan.md` | 卡牌扩展计划调整 | 扩展路线图/数量 |
| `09-mgmt/specs/*.md` | 对应方案实现或变更 | 方案文档→实现后关闭/标记完成 |
| `testing/ninja-test-plan.md` | 测试策略调整 | 测试覆盖率/方法 |
| `references/balatro-game-design-cf1.md` | 设计参考 | 整体设计方向变化时同步 |
| `references/balatro-joker-design.md` | Balatro 小丑牌参考 | 忍者牌设计方向变化时同步 |
| `references/ninking-balatro-gap-analysis.md` | 差距分析 | 核心玩法/系统变更后复查差距 |
| `scene-tree-visualizer-methodology.md` | 场景树 HTML | tscn_parser 提取逻辑变化时同步 |

---

## 附：快速查找表（按文档→代码反向索引）

| 文档 | 主要依赖代码 |
|------|------------|
| `01-gameplay/06-complete-redesign.md` | `card_data.gd`, `score/*.gd`, `arrange_controller.gd`, `auto_arranger.gd`, `hand_evaluator.gd`, `xi_detector.gd`, `seal_controller.gd` |
| `01-gameplay/13-blinds-and-bosses.md` | `barrier_config.gd`, `barrier_theme.gd` |
| `02-cards/11-ninja-cards.md` | **`ninja_data.gd`**, `ninja_scaling.gd`, `ninja_pool.gd` |
| `02-cards/12-consumable-cards.md` | `consumable_data.gd`, `card_data.gd` |
| `02-cards/22-display-card-base-spec.md` | `ninking_card.gd`, `ninking_card_factory.gd`, `ninja_inventory_card.gd` |
| `02-cards/23-ninja-card-expansion-plan.md` | —（规划文档，无直接代码依赖） |
| `03-economy/14-economy-and-progression.md` | `shop_manager.gd`, `seal_controller.gd`, `ninja_data.gd`（价格）, `consumable_data.gd`（价格） |
| `04-ui/06-ui-layout-reference.md` | **所有 `.tscn` + `ui_manager.gd` + `game_manager.gd`** |
| `04-ui/07-shop-ui-design.md` | `shop_handler.gd`, `shop_ui.gd` |
| `04-ui/09-launch-ui-design.md` | `main_menu.gd`, `deck_select_panel.gd`, `continue_panel.gd`, `ninking_launcher.tscn` |
| `04-ui/10-main-ui-design.md` | `ui_manager.gd`, `game_manager.gd`, `ninking_main.tscn` |
| `04-ui/11-main-overlay-design.md` | `game_manager.gd`, `result_screen_display.gd`, `ninking_main.tscn` |
| `04-ui/24-scoring-ninja-animation.md` | `animation_handler.gd`, `score_calculator.gd` |
| `05-art/15-sound-design-plan.md` | `sound_bank.gd` |
| `05-art/18-audio-asset-matching-guide.md` | `sound_bank.gd` |
| `05-art/19-image-asset-matching-guide.md` | `asset_registry.gd` |
| `06-tech/03-technical-design.md` | `game_state.gd`, `seal_controller.gd`, `arrange_controller.gd`, 所有 UI 相关 |
| `docs/ninking/ninja-game-replay.html` | `game_logger.gd` — 日志事件结构决定 HTML 解析逻辑 |
| `06-tech/ui-signal-architecture.md` | `game_state.gd`（信号）, `ui_manager.gd`（API） |
| `07-data/game-save-schema.md` | `save_manager.gd`, `game_state.gd` |
| `08-testing/20-debug-scene-design.md` | `debug_ninking_main.tscn`, `debug_controller.gd`, `debug_panel.gd` |
| `08-testing/testing-guide.md` | —（使用方法，非代码依赖） |
| `testing/automated-formula-testing.md` | `tools/gen_test_v2.py`, `tools/calc_engine.py`, `ninja-test-full.csv` |
| `testing/ninja-test-plan.md` | —（规划文档） |
| `docs/tween-library-reference.md` | `scripts/tween/*.gd` |
| `docs/shader-library-reference.md` | `scripts/shader/*.gd` + `shaders/*.gdshader` |
| `docs/vfx-system-design.md` | `scripts/tween/*.gd` |
| `docs/card-framework-usage-guide.md` | Card-Framework addon |
| `scene-tree-visualizer-methodology.md` | `tools/tscn_parser.py` |
| `html-visualization-guide.md` | `tools/tscn_parser.py`, `tools/extract_ninja_data.py` |
| `references/balatro-game-design-cf1.md` | —（设计参考，无直接代码依赖） |
| `references/balatro-joker-design.md` | —（设计参考） |
| `references/ninking-balatro-gap-analysis.md` | —（差距分析） |

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-17 | 创建初始版本，覆盖全部 50+ 代码文件 → 30+ 文档映射 |
| 2026-06-17 | 🔧 review-plan 审阅修复: 补 `debug/*.gd` 6文件(A1)、`shop_slot.gd`(A2)、`references/*.md`(A5)、`scene-tree-visualizer-methodology.md`(A4)；合并 §2.1(C1)；加 pre-commit warning(C2)；补全逆向索引 |
| 2026-06-18 | 📝 **新增 §9 日志系统**: `game_logger.gd` 映射 + 插桩分布表 + 全文档节号后移；快速查找表加 `ninja-game-replay.html` |
| 2026-06-18 | 🐛 **§9.1 插桩分布表更新**: debug_controller.gd 新增 `game_over` 插桩点（退出落盘），8 处 |
| 2026-06-18 | 📗 **新增 §7.5**: `tools/simulation/` 模拟框架映射 → `08-testing/21-simulation-methodology.md`；`README.md` 追加引用 |
| 2026-06-18 | 🧠 **新增 §7.6**: `player_personality.py` + `sim_runner_personality.py` 玩家人格模型映射；模拟报告同步更新
| 2026-06-18 | 🐛 **save_manager.gd 修复 + GameOver 布局优化**: `.duplicate(true)` 修复只读字典崩溃；`06-ui-layout-reference.md`/`10-main-ui-design.md`/`11-main-overlay-design.md` 同步更新 GameOver ScoreSummary/BackToMenuButton 节点描述 |
| 2026-06-18 | ✨ **CardDetailPopup 入场动效 + Flash 材质**: `asset_registry.gd` 新增共享 flash 常量；`card_visual_composer.gd` 新增 L3 `build_card_face_with_flash()`；`card_detail_popup.gd` rarity 分阶入场/退场动效 + 卡面 flash shader |
