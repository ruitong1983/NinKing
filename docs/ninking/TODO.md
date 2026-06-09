# NinKing 工作清单

> **最后更新:** 2026-06-09 | **当前 Phase:** A（核心引擎）
> **使用方式:** AI 每次会话开始时读取此文件。完成任务后更新状态。
> **状态图例:** ⬜ 待做 | 🔵 进行中 | ✅ 已完成 | 🔒 暂缓 | ⛔ 已废弃

---

## 🐛 Bug 修复

| # | 问题 | 位置 | 优先级 | 状态 |
|---|------|------|--------|------|
| B1 | Boss "封印师" 仍用旧逻辑 `random_group_zero` — 已改为 `lowest_group_zero`（分数最低组×0） | `blind_controller.gd:33` | **P0** | ✅ |
| B2 | Boss 效果字典 key 已对齐 10 Boss 定义 | `blind_controller.gd` + `score_calculator.gd` | **P0** | ✅ |
| B3 | XiDetector: 全顺/三顺清/顺清打头/全三条/通锅 5 个喜模式未实现 — 全部 9 喜已实现（通锅=全顺） | `xi_detector.gd:76` | **P1** | ✅ |

---

## 🏗️ Phase A — 核心引擎完善

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| A1 | Boss Blind 系统：实现 10 Boss 完整效果 | 所有 10 Boss 效果已实现（`blind_controller.gd` + `score_calculator.gd` + `level_config.gd`） | **P0** | ✅ |
| A2 | Boss AI 适配 | 6 种 Boss 评分策略已实现：deprioritize/skip_weak/scatter_king/hungry_ghost/balance/constraint_reverse | **P0** | ✅ |
| A3 | 商店 MVP 完善 | 修复场景切换 bug + 方法名更新 + 忍者槽位指示器 + GoldPill 布局调整 | **P0** | ✅ |
| A4 | 喜系统补全 | 全部 9 种喜已实现：全黑/全红/全顺/全同花/四张/三清/三顺清/顺清打头/全三条 | **P1** | ✅ |
| A5 | 换牌 UI 交互 | 选卡 → 确认丢弃 → 重抽 → AI 重排流程完整（已修复 redraw_mode 属性缺失） | **P1** | ✅ |
| A6 | 交换 UI | 点击交换（已有）+ 拖拽交换（新增 NinKingCard 拖拽信号 + HandDisplay 落点检测 + HandInteraction 跨容器交换）| **P1** | ✅ |
| A7 | 出牌/计分动画流程 | 组揭示 → 计分跳动 → 喜触发粒子 → 过关/失败判定。SealController 拆为 prepare/finalize，CountUp 直接调用，零手写 Tween | **P1** | ✅ |
| A8 | 永久死亡存档 | 失败/胜利自动记录战绩+删 run 存档，checkpoint 在封印开始时保存，新增 continue_run/has_saved_run | **P1** | ✅ |
| **A9** | **列分机制** | 3×3 网格纵向列计分（列_i = 影[i]+瞬[i]+滅[i]），列专属基础值 2.5× 横向，AI 只优化横向，交换不自动重排，新增 AI 重排按钮 + 列标签 | **P0** | ✅ |

---

## 🧩 Phase B — 系统完善

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| B4 | 商店刷新机制 (reroll) | $1-2/次，全部商品刷新，上限规则 | P2 | ⬜ |
| B5 | 附魔卡使用流程 | 购买 → 选目标牌 → 应用效果（花色/点数/增强/复制等） | P2 | ⬜ |
| B6 | 星图卡使用流程 | 购买 → 选牌型 → 升级（永久提升该牌型基础筹码/倍率） | P2 | ⬜ |
| B7 | 秘仪卡系统 | 购买即生效的全局限效果（消耗品，不占槽位） | P2 | ⬜ |
| B8 | 忍者牌条件效果 | 部分忍者牌带条件触发（如"影为同花时+x mult"），需实现条件检测 | P2 | ⬜ |
| B9 | **主菜单系统** — 闪屏→按钮→牌组选择→继续确认 | 详见审阅报告。要点：① 按钮 hover/click SFX ② `_ready` 触发菜单 BGM ③ `stagger_slide_in(slide_offset=80)` ④ 牌组中文名映射 `DECK_NAMES` ⑤ 未实现牌组(night/sun)置灰不可点击 ⑥ CRT 滤镜开启 ⑦ `_panel_open` 双击守卫 | **P0** | ✅ |
| B10 | **接入修炼忍者成长系统** — `NinjaScaling.process_scaling()` 接入 `finalize_play` (on_play) 和 `execute_redraw` (on_redraw)，构建 context (head/mid/tail_type + triggered_xis) | `NinjaScaling` 已提取，6 张修炼忍者数据已有，需在出牌/重抽后调用 `process_scaling` | P2 | ⬜ |

---

## 🎨 Phase 1-2 — 素材与视觉

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| V1 | 卡牌背面 (Card Back) | 140×196 像素风 PNG，程序绘制：`card_back_generator.gd` → `card_back.png`（手里剑十字星+交叉纹底+金色硬边框+内边框+角钻），已集成到 `ninking_card.gd` | **P0** | ✅ |
| V2 | 像素中文字体 | Press Start 2P (EN) + 凤凰点阵体 12px/16px (CJK) 三套已导入并配置回退链 | **P0** | ✅ |
| V3 | pixel_theme.tres | 全局 Theme 资源（字体/颜色/按钮样式） → **已由 V16 完成** | **P0** | ✅ |
| V4 | 按钮素材（普通/按下） | 可拉伸像素风边框 PNG | P1 | ⬜ |
| V5 | 商店面板/顶部信息栏背景 | 半透明深色背景 | P1 | ⬜ |
| V6 | 忍者牌槽位背景 | 100×140 像素风边框，`CardBackGenerator.generate_slot_bg()` 程序绘制：深蓝底+交叉纹+金边框+内凹区域+中央小手里剑+角钻+上下装饰线，已接入 `ability_slot.tscn` TextureRect | **P0** | ✅ |
| V7 | CRT 扫描线效果接入 | crt_filter.gd 已复用 → **已细化至 V18**（shader time_offset 扩展 + 微下移动效） | P1 | ⬜ |
| V8 | VFX 接入（卡牌翻转/粒子/闪烁/震动） | Tween/FX 框架已有，接入各流程 | P2 | ⬜ |
| V9 | **ParticlePool 扩展** — shuriken + sakura 粒子预设 | 程序绘制 8×8 纹理，shuriken=铁灰十字星(4尖)，sakura=淡粉圆点+径向渐变，写入 `scripts/tween/particle_pool.gd`，后续全局复用 | **P0** | ✅ |
| V16 | **pixel_theme.tres 像素忍者风重写** | StyleBox 全部 corner_radius→0、border→2px 硬边；按钮三态（normal/hover/pressed 瞬间切换 + content_margin 下移）；面板双层硬边框（外层 2px 暗色 + 内层 1px 强调色）；三墩 DunHead(1px)/DunMiddle(2px)/DunTail(3px) 边框递进区分。覆盖 V3 原占位 Theme | P1 | ✅ |
| V17 | **barrier_theme.gd 新建** | 8 結界冷暖交替配色表 `class_name BarrierTheme`，字典 `BARRIER_COLORS`：冷(紫/青/蓝/翠) 暖(红/橙/金/粉) 交替，每結界含 bg/panel/accent/name 四字段。`scripts/ninking/barrier_theme.gd` | P1 | ✅ |
| V18 | **CRT shader time_offset 扩展** | `crt_filter.gdshader` 新增 `uniform float time_offset`，sin() 中加 offset 实现扫描线微下移；`CRTFilter` 新增 `set_offset()`；`GlobalTweens` 新增委托；`game_manager._process` 每帧 +0.003 驱动。替代 V7 的静态 CRT 接入 | P1 | ✅ |
| V19 | **game_manager.gd 結界主题应用** | `_on_seal_started()` → `BarrierTheme.get_colors(barrier_num)` 切换 GameBg/PanelBg/ProgressBar 配色；`_process` 驱动 CRT time_offset；Boss 揭示改 visible 硬切；PlayBtn/RedrawBtn/DeckBtn 字体色跟随結界强调色。场景加 LeftPanel+PanelBg unique_name + ui_manager 加 left_panel/panel_bg/deck_btn 引用 | P1 | ✅ |
| V20 | **ui_manager.gd 三墩标题区分** | 影/瞬/滅 Label 用 `theme_override_colors/font_outline_color` + `font_outline_size` 递进：影(alpha 0.3→1px暗)、瞬(alpha 0.6→2px标准)、滅(alpha 1.0→3px亮+glow)。场景加 HeadLabel/MiddleLabel/TailLabel unique_name，纯 Theme override | P1 | ✅ |
| V21 | **06-ui-layout-reference.md 配色表更新** | §6 旧单套配色（`#1A3A32` 等）→ 动态 8 結界配色引用 `BarrierTheme.BARRIER_COLORS`；场景结构名与实际一致（StatusPanel→LeftPanel, PlayArea→CenterColumn）；新增像素风设计原则条目 | P2 | ✅ |
| V10 | **发牌动画** — 卷轴展开 | `TweenFX.stagger_spread()` + `GlobalTweens.stagger_spread()` 委托。`particle_pool.gd` → `tween_fx.gd` → `global_tweens.gd` | P1 | ✅ |
| V11 | **换牌动画** — 烟遁消失+瞬身出现 | `ui_manager.gd` `_run_redraw_with_vfx()`: 弃牌 `fade_out` + `burst_particles("dust")` → await 0.18s → 新牌 pop_in | P1 | ✅ |
| V12 | **计分动画主题化** — 粒子替换 | `game_manager.gd` `_run_scoring_animation()`: sparkle→shuriken、confetti→sakura | P2 | ✅ |
| V13 | **过关过渡** — 屏风转场 | `game_manager.gd` `_on_go_shop_pressed()`: `fade_out(ui, 0.3)` → change_scene | P1 | ✅ |
| V14 | **Boss 封印揭晓** — 墨字浮现 | `game_manager.gd` `_on_seal_started()`: CRT vignette+aberration → Boss 名 scale_pop → 1s 恢复 | P2 | ✅ |
| V15 | **屏风转场增强** — logo 遮罩版 | 过关时在 fade 中间叠 NinKing logo/忍字 ColorRect，需评估 autoload vs 场景内实现方案 | P3 | ⬜ |

---

## 📐 代码质量

| # | 问题 | 位置 | 优先级 | 状态 |
|---|------|------|--------|------|
| C1 | `ui_manager.gd` 444 行 → 已拆分至 `hand_display.gd` + `hand_interaction.gd`，现 284 行 | `scripts/ninking/ui/ui_manager.gd` | P2 | ✅ |
| C2 | `game_state.gd` 345 行 → 库存移至 ShopManager，BlindController 转发删除，现 268 行 | `scripts/ninking/game_state.gd` | P2 | ✅ |
| C3 | `game_state.gd` BlindController 静态方法类型检查冲突 | `scripts/ninking/game_state.gd` | P2 | ✅ |
| C4 | `ui_manager.gd` class_name 与全局脚本类冲突（Godot 编辑器已知现象，不影响运行） | `scripts/ninking/ui/ui_manager.gd` | P2 | ⚠️ |
| C5 | `blind_controller.gd` class_name 与全局脚本类冲突（同上） | `scripts/ninking/blind_controller.gd` | P2 | ⚠️ |
| C6 | `03-technical-design.md` 全文档同步至实现 — 场景树列表(5→11)、shop.tscn 重写、节点命名(BarrierLabel/RedrawBtn)、目录结构(10+7→19+13)、类图(新增 ArrangeController/NinjaPool/NinjaScaling/BarrierTheme、修正 NinjaData/ShopManager/BarrierConfig) | `docs/ninking/03-technical-design.md` | P1 | ✅ |
| R2 | 计分公式更新 `06-complete-redesign.md` — 加列 chips/mult | P2 | ✅ |
| R3 | 散牌王说明更新 `13-blinds-and-bosses.md` — 注明列不受影响 | P2 | ✅ |
| R4 | 交换行为变更同步 `06-complete-redesign.md` — 交换不再触发 AI 重排 | P2 | ✅ |
| R5 | AI 重排按钮补充 `03-technical-design.md` 场景树 | P2 | ✅ |
| C7 | 确认清理 `ninking_main.tscn` 中旧 MainMenu 视图节点（UIManager/MainMenu 含 LaunchBg/TitleLabel/SubtitleLabel/DeckLabel/StartButton/VersionLabel）。⏸ 暂不删除：被 game_manager.gd 引用，需先评估影响面 | `scenes/ninking/ninking_main.tscn` | P2 | 🔒 |

---

## 🔒 Phase D-E — 远期（暂缓）

| # | 任务 | 说明 | 状态 |
|---|------|------|------|
| D1 | 牌组系统（暗夜/赤阳/混沌/龙脉） | 4 种特殊牌组 + 解锁条件 | 🔒 |
| D2 | 封印系统重新设计 | 原设计在比鸡 9 张全出下 OP | 🔒 |
| D3 | Tag 系统 | 投资/星图/忍者/优惠/稀有 Tag | 🔒 |
| D4 | 卡包系统 | 附魔包/星图包/封印包/秘仪包 | 🔒 |
| D5 | n_x04 黑龙 / n_x05 赤凤 | 需牌组系统支持 | 🔒 |
| D6 | 商店 BGM | `assets/audio/music/shop_bgm` 缺失 | 🔒 |
| D7 | 数值平衡调优 | 完整验证难度曲线 + 价格平衡 | 🔒 |
| D8 | 音频替换为扑克风格 | 当前全部为 FanKing 占位 | 🔒 |

---

## 🗺️ 实施路线图速查

```
Phase A (当前) ──→ Phase B ──→ Phase C ──→ Phase D ──→ Phase E
 核心可玩            系统完善       Boss深度      扩展          发布

 A1-A8 完成 = 可玩原型
 B4-B8 完成 = 完整体验
 C(10 Boss) = 策略深度
 D = 重玩性
 E = 发布就绪
```

---

## 📋 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-09 | 📋 **方案审阅: A9 列分机制**: Grill 14 轮 → review-plan 审阅 → R2-R5 共 4 项文档同步加入 TODO。Q1=breakdown 文字体现列分，Q2=列≥同花顺加 VFX 庆祝（shuriken + color_flash）|
| 2026-06-09 | 📝 **A9 文档同步 + 代码审查完成**: R2-R5 四文档已更新（06 公式/交换 + 13 散牌王 + 03 场景树），A9 标记完成。代码审查通过，列分机制完整实现。 |
| 2026-06-09 | 🔢 **牌型基础值重新调整**: 同花 20/3→30/4、同花顺 35/4→50/5、豹子 40/5→100/8。遵循传统扑克排序(同花>顺子)，高牌型拉开差距，星图升级值保持不放大（对标 Balatro 设计）。同步更新 06-complete-redesign / 12-consumable-cards 文档 |
| 2026-06-09 | 🎴 **V1 卡牌背面**: CardBackGenerator 程序绘制 140×196 像素手里剑卡背（深蓝底+交叉纹+金色硬边框+十字手里剑+中心环+角钻+装饰线），已接入 ninking_card.gd set_faces()；同步 V2/V3/V7 标记为已并入完成 |pixel_theme.tres 重写(0圆角/2px硬边/三态按钮/三墩边框递进) + barrier_theme.gd(8結界冷暖交替配色表) + CRT shader time_offset 扩展(扫描线微下移) + game_manager 結界主题应用(配色自动切换/按钮色调跟随) + ui_manager 三墩标题区分(outline递进)。场景仅加 5 个 unique_name_in_owner flag |
| 2026-06-09 | 💰 **金币×忍者牌联动**: 补实现福神/金尾/俭约/镀金/金封印 5 效果（`_collect_play_gold` 统一结算）；新增 金剛力（$5→+1倍率）/ 黄金律（$15→×2）2 张 economy ninja；ScoreCalculator 加 `gold` 参数 |
| 2026-06-09 | ✅ **A8 永久死亡存档**: checkpoint save/delete_run/record_run_result/continue_run/has_saved_run；save_manager build_run_data 扩展 6 字段；清理 get_save_data 死代码 + 死 preload |
| 2026-06-09 | 🐛 **A7 审阅修复**: R1 execute_play 重构为 delegate to prepare/finalize（删 ~70 行重复代码）；R2 xi_triggered 加 SCORING 状态守卫防覆盖动画文本；R3 finalize_play 继续分支加 PLAYING 状态转换防卡死 |
| 2026-06-09 | ✅ **A6 交换 UI**: 拖拽交换 + 点击交换统一共存（NinKingCard 拖拽信号 + HandDisplay 落点检测 + HandInteraction 跨容器交换） |
| 2026-06-09 | ✅ **A7 出牌/计分动画**: 4 阶段动画流程（组揭示→计分跳动→喜触发→判定），SealController.prepare/finalize 拆分，CountUp 直接调用，零手写 Tween |
| 2026-06-09 | ✅ **A3 商店 MVP**: 修复场景切换 bug、方法名更正 (`get_ninjas_for_display` 等)、新增 NinjaSlotLabel 槽位指示器、GoldPill 左移 |
| 2026-06-09 | ✅ **B3+A4 喜系统**: 全部 9 种喜已实现（全黑/全红/全顺/全同花/四张/三清/三顺清/顺清打头/全三条） |
| 2026-06-09 | ✅ **A5 换牌 UI**: 换牌流程完整实现（HandInteraction+HandDisplay+SealController），修复 `redraw_mode` 属性缺失 bug |
| 2026-06-09 | ✅ **命名统一（忍者主题中二化）**: Ante→結界, Blind→封印, Small/Big/Boss→修羅/明王/夜叉, Boss→封印ノ主, Joy→喜(Xi), Discard→手替え, Score→忍気, Target→封印, 商店→萬屋, 附魔→符術, 秘仪→禁術, 星图→南斗六星, 三组→影/瞬/滅 |
| 2026-06-09 | 🔢 **积分整数化 (v3.2)**: 全部计分值 float→int, ×1.3→×2, ×1.5→×2, ×2.5→×3, SUIT_TIEBREAK ×10, 喜鹊 +0.3→+1, 忍法帖 +0.2→+1, 藏锋 scale {3,2,1,1}, 清一色 ×2→×3, 疾风去半折, 淬火修正/desc同步 |
| 2026-06-09 | 🎮 **V9-V14 忍者主题交互实现**: V9 ParticlePool shuriken+sakura / V10 TweenFX.stagger_spread + GlobalTweens 委托 / V11 ui_manager 换牌动画(fade+dust→pop_in) / V12 计分粒子替换 / V13 过关 fade 过渡 / V14 Boss CRT 墨字浮现。5 文件修改，~120 行新增代码 |
| 2026-06-09 | 📋 **方案审阅: 登录界面优化**: B9/C6/C7 共 3 项加入 TODO，7 审阅发现全部落地 |
| 2026-06-09 | 🎨 **方案审阅: 像素复古忍者风 UI L1**: 10 轮 grill → review-plan 审阅 → V16-V21 共 6 项加入 Phase 1-2。核心：pixel_theme 重写(2px硬边/三态按钮/双层面板/三墩边框递进)、barrier_theme.gd 新建(8結界冷暖交替)、CRT shader time_offset 扩展、game_manager/ui_manager 配色应用、文档同步。零场景节点新增 |
| 2026-06-09 | 📐 **代码拆分: game_state.gd + ninja_data.gd**: game_state 401→290行（删死代码+提 ArrangeController），ninja_data 531→409行（提 NinjaPool + NinjaScaling），ShopManager.buy_ninja R2 回归修复，TODO 加 B10 修炼成长接入 |
| 2026-06-09 | 初始创建，基于设计文档 + 代码扫描 |
