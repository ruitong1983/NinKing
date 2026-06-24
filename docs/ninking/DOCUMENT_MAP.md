# 文档依赖映射 — 代码 → 文档对照表

> **用途：** 每次代码变更后，对照此表检查受影响文档是否需要同步更新。
> **原则：** 改代码前先查此表，改完代码后逐项同步。
> **建立日期：** 2026-06-17 | **最后更新：** 2026-06-24 (CL33 Phase D 落位动效增强 v2 — 重力加速/squash/spring/粒子) | **更新：** 2026-06-24

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
| **`06-tech/03-technical-design.md`** | 技术架构 — 状态机 | State enum/信号定义/核心字段（含 `game_mode`）/`start_new_run()` 签名变更时同步 |
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

### 4.6 `scripts/ninking/clean_controller.gd` + `clean_layout_generator.gd`

> 消除模式核心引擎。`class_name CleanController / CleanLayoutGenerator`，`extends RefCounted`，静态方法。匹配 4 种类型：豹子/同花顺/同花/顺子。计分公式：Σ(card_chip)×hand_type_mult。

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`01-gameplay/06-complete-redesign.md`** §5 | 消除模式玩法/计分公式 | 算法/计分公式变更时同步 |
| **`06-tech/03-technical-design.md`** | 状态机-消除模式/数据流 | 连锁流程/交换逻辑变更时同步 |
| **`09-mgmt/specs/clean-mode-design.md`** | 消除模式方案规格书 | 代码实现与方案描述不一致时同步 |
| 本表（DOCUMENT_MAP.md） | 文档依赖映射 | 新增/删除消除模式文件时同步 |

### 4.8 `scripts/ninking/clean_chain_handler.gd` — 消除链处理器（new 2026-06-24）

> `class_name CleanChainHandler`，`extends Node`，消除模式链式消除 UI 流程控制器。从 `game_manager.gd` 提取（A1 行数优化）。`setup(ui)` → `resolve_clean_chain()`。持有 `_match_display: CleanMatchDisplay` 实例。

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `09-mgmt/specs/clean-mode-design.md` §4.1a + §9.3 | 消除链视觉分步流程 + match 明细面板 | 链解析 UI 时序/动画变更、match 显示逻辑变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 | 消除流程/游戏管理器拆分变更时同步 |
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 — HandTypePanel | CleanMatchDisplay 集成/可见性变更时同步 |

### 4.8a `scripts/ninking/ui/clean_match_display.gd` — 消除模式计分明细展示（new 2026-06-24）

> `class_name CleanMatchDisplay`，`extends RefCounted`，消除模式 HandTypePanel 中逐波追加 match 组行的展示控制器。
> 格式：`手役名  chip×mult=score`。行间距分隔波次，ScrollContainer 自动滚底。

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/06-ui-layout-reference.md`** §3.3.2a | UI 布局参考 — HandTypePanel 场景树 | 消除模式 HandTypePanel 子节点结构变更时同步 |
| **`09-mgmt/specs/clean-mode-design.md`** §9.3 | 消除模式方案 — 左面板精简 | 显示格式/配色/流程变更时同步 |

### 4.9 `scripts/ninking/score/score_calculator.gd` — 消除模式扩展

> `calculate_clean()` + `_is_ninja_valid_for_clean()` 新增方法。计分引擎扩展。

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`01-gameplay/06-complete-redesign.md`** §5.3 | 消除模式计分公式 | 计分公式/忍者效果映射变更时同步 |
| `06-tech/03-technical-design.md` | 消除模式数据流 | ScoreCalculator 消除API变更时同步 |

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

### 5.6 `scripts/ninking/ui/ninja_bar_container.gd` + `ninja_bar_display.gd` + `ninja_bar_node.gd` + `ninja_inventory_card.gd` + `ninja_detail_tooltip.gd` + `ninja_sell_button.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `04-ui/06-ui-layout-reference.md` | UI 布局 — 忍者栏（含悬停 tooltip + 右键售卖按钮） | 忍者栏布局/交互变更时同步 |
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
| **`04-ui/09-launch-ui-design.md`** | Launch UI 设计 | 主菜单/牌组选择/继续确认变更时同步（含 CleanBtn / _pending_mode 路由） |
| `06-tech/03-technical-design.md` | 技术架构 | 场景切换/存档读取变更时同步 |

### 5.13 `scripts/ninking/ui/nin_king_tween.gd` + `launch_ambience.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `docs/tween-library-reference.md` | Tween API | 新增公开 Tween 方法时同步 |
| `05-art/15-sound-design-plan.md` | 音效设计 | 背景音乐/环境音变更时同步 |
| `05-art/18-audio-asset-matching-guide.md` | 音效匹配 | 音效素材映射变更时同步 |

### 5.14 `scripts/ninking/ui/xi_strike_overlay.gd` (v9 新增)

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/24-scoring-ninja-animation.md`** §5 | 喜 Strike Reveal 三段式动画 | 动画流程/时序/视觉效果变更时同步 |

### 5.15 `CursorManager` Autoload — `scripts/ninking/ui/cursor_manager.gd` (Kenney 光标集成)

> Autoload 注册名: `CursorManager` (`*res://scripts/ninking/ui/cursor_manager.gd`)

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `05-art/20-kenney-ui-pack-evaluation.md` | Kenney 素材评估报告 | 光标图片路径/形状映射变更时同步 |
| `06-tech/03-technical-design.md` | 技术架构 — 光标系统 | Autoload 注册 / `SceneTree.node_added` 策略变更时同步 |
| **`05-art/21-ui-interaction-enhancements.md`** | UI 交互增强指南（含 Kenney 光标/面板/按钮改造） | **新增/修改任何交互增强素材时必同步** |

### 5.16 Kenney 暖纸风 UI 改造 — `kenney-beige-ui-transformation.md` 方案 + 实现

> **方案文件:** `docs/ninking/09-mgmt/specs/kenney-beige-ui-transformation.md`
> **相关脚本:** `button_styles.gd` / `barrier_theme.gd` / `main_menu.gd` / `game_manager.gd` / `shop_ui.gd` / `shop_slot.gd`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `05-art/21-ui-interaction-enhancements.md` §3 | Kenney 面板/按钮纹理映射 | 新增纹理或修改映射表时同步 |
| `04-ui/06-ui-layout-reference.md` | UI 布局参考 | 面板样式变更不影响布局，无需同步 |
| `04-ui/10-main-ui-design.md` | Main Game UI | 按钮样式不影响结构，无需同步 |

### 5.17 `scripts/ninking/ui/button_styles.gd` — 按钮样式统一工具类 (v2026-06-23)

> 新增文件。`class_name ButtonStyles`，`extends RefCounted`，静态方法集中管理所有按钮样式。

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| `05-art/21-ui-interaction-enhancements.md` §3.4 | 按钮样式实现方式 | 新增/修改 API 时同步更新实现描述 |
| `CLAUDE.md` | 编码规范 — ButtonStyles 铁律 | 新增/移除方法时同步 |

---

---

## 六、场景文件（`.tscn`）

### 6.1 `scenes/ninking/ninking_main.tscn` + `ninking_clean_main.tscn` + `ninking_launcher.tscn`

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`04-ui/06-ui-layout-reference.md`** | UI 布局参考 — §场景树全图 | 节点名/层级/%引用变更时**必须同步** |
| **`04-ui/09-launch-ui-design.md`** | Launch UI — §场景结构 | Launch 场景结构变更时同步 |
| **`04-ui/10-main-ui-design.md`** | Main Game UI — §场景结构 | Main/CleanMain 场景结构变更时同步 |
| `04-ui/11-main-overlay-design.md` | Overlay 设计 | 覆盖层结构变更时同步 |
| `scene-tree-visualizer.html` | HTML 可视化 | 由 pre-commit 自动触发（`tools/tscn_parser.py`）⚠️ pre-commit hook 需手动安装：`sh tools/install-hooks.sh` |

> `ninking_clean_main.tscn` 是 `ninking_main.tscn` 的 1:1 复刻，用于消除模式。玩法实现后需独立维护。

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
| `05-art/~~05-image-asset-generation-plan.md~~`（已删除） | 素材生成计划（已废弃） | 资产路径/加载逻辑变更时同步 |
| `05-art/19-image-asset-matching-guide.md` | 图像素材匹配 | 资产映射变更时同步 |

### 10.3 `scripts/config/config_manager.gd`（autoload: `ConfigManager`）

| 影响文档 | 说明 | 同步要点 |
|---------|------|---------|
| **`06-tech/03-technical-design.md`** | 技术架构 — Autoload / 配置系统 | 新增/修改可配置参数、校验逻辑、默认值时同步 |
| `03-economy/14-economy-and-progression.md` | 经济参数 | 起始金币/利息/商店/重掷等参数默认值变更时同步 |

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
| `docs/design-decision-framework.md` | 特效设计决策框架 | 新增/修改效果类型或分类时同步 |
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
| `03-economy/14-economy-and-progression.md` | `config_manager.gd`, `shop_manager.gd`, `seal_controller.gd`, `ninja_data.gd`（价格）, `consumable_data.gd`（价格） |
| `04-ui/06-ui-layout-reference.md` | **所有 `.tscn` + `ui_manager.gd` + `game_manager.gd`** |
| `04-ui/07-shop-ui-design.md` | `shop_handler.gd`, `shop_ui.gd` |
| `04-ui/09-launch-ui-design.md` | `main_menu.gd`, `deck_select_panel.gd`, `continue_panel.gd`, `ninking_launcher.tscn` |
| `04-ui/10-main-ui-design.md` | `ui_manager.gd`, `game_manager.gd`, `ninking_main.tscn` |
| `04-ui/11-main-overlay-design.md` | `game_manager.gd`, `result_screen_display.gd`, `ninking_main.tscn` |
| `04-ui/24-scoring-ninja-animation.md` | `animation_handler.gd`, `score_calculator.gd` |
| `05-art/15-sound-design-plan.md` | `sound_bank.gd` |
| `05-art/18-audio-asset-matching-guide.md` | `sound_bank.gd` |
| `05-art/19-image-asset-matching-guide.md` | `asset_registry.gd` |
| `06-tech/03-technical-design.md` | `config_manager.gd`, `game_state.gd`, `seal_controller.gd`, `arrange_controller.gd`, `save_manager.gd`, 所有 UI 相关 |
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
| 2026-06-20 | 📝 **配置外部化**: 新增 §10.3 `config_manager.gd` 映射；快速查找表追加 `config_manager.gd` 引用；`03-economy/14-economy-and-progression.md` 和 `06-tech/03-technical-design.md` 同步更新 |
| 2026-06-20 | 📉 **封印阈值减半**: `barrier_config.gd` v5.3 整体 ×0.5；同步 `01-gameplay/13-blinds-and-bosses.md` 封印值表 + 难度曲线 + 变更日志 |
| 2026-06-21 | 🗑️ **删除 B14 替换系统**: 移除 §5.13 `ninja_replace_overlay.gd` 映射条目（文件已删除）。§5.13 → `nin_king_tween.gd`，节号前移（14→13）。 |
| 2026-06-21 | 🎨 **Toast 视觉强化**: 深色半透明背景面板 (rgba 0,0,0,0.75 + 圆角12px) + 位置从底部移至顶部 20%。`toast_manager.gd` 改为 Panel 容器包裹 Label，动画修正为 toast() 完整淡入→停留→淡出。 |
| 2026-06-23 | 🎨 **计分行配色调整**: ...略...
| 2026-06-23 | 🖌️ **风格统一：少年漫画→治愈漫画**: 更新 `16-art-direction-principles.md` 全篇。同步 6 份文档风格引用。TODO.md 新增风格统一条目。|
| 2026-06-23 | 🏗️ **KUI2 GameOver/Victory 面板卡片化**: ContentPanel 暖米面板 + pop_in 入场 + 文字配色适配。同步 `06-ui-layout-reference.md`/`10-main-ui-design.md`/`11-main-overlay-design.md`/`21-ui-interaction-enhancements.md` 场景树与文字配色描述。|
| 2026-06-23 | 🆕 **消除模式通道**: §4.1 `game_state.gd` 新增 `game_mode` 字段映射；§5.12 `main_menu.gd` 新增 CleanBtn/_pending_mode 路由说明；§6.1 新增 `ninking_clean_main.tscn` 场景映射。同步 `03-technical-design.md` / `09-launch-ui-design.md`。|
