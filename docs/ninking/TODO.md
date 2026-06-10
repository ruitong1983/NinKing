# NinKing 工作清单

> **最后更新:** 2026-06-10 | **当前 Phase:** A（核心引擎）
> **使用方式:** AI 每次会话开始时读取此文件。完成任务后更新状态。
> **状态图例:** ⬜ 待做 | 🔵 进行中 | ✅ 已完成 | 🔒 暂缓 | ⛔ 已废弃

---

## 🐛 Bug 修复

| # | 问题 | 位置 | 优先级 | 状态 |
|---|------|------|--------|------|
| B1 | Boss "封印师" 仍用旧逻辑 `random_group_zero` — 已改为 `lowest_group_zero`（分数最低组×0） | `blind_controller.gd:33` | **P0** | ✅ |
| B2 | Boss 效果字典 key 已对齐 10 Boss 定义 | `blind_controller.gd` + `score_calculator.gd` | **P0** | ✅ |
| B3 | XiDetector: 全顺/三顺清/顺清打头/全三条/通锅 5 个喜模式未实现 — 全部 9 喜已实现（通锅=全顺） | `xi_detector.gd:76` | **P1** | ✅ |
| B4 | SEAL_INTRO → PLAYING timer 被 change_scene_to_file 销毁，导致新游戏/继续/商店返回时卡在结界标题 | `game_state.gd:312` + `game_manager.gd:48-52` | **P0** | ✅ |
| B5 | SVG 卡牌尺寸错误 — Godot 4 TextureRect KEEP_SIZE + non-SCALE stretch 每帧覆盖 size 为纹理原始尺寸(240×334)，卡牌显示过大 | `ninking_card.gd:87-107` | **P0** | ✅ |
| B6 | **商店入场动画竞态守卫** — `_play_entrance()` 加入口 `_entrance_active` 标志位 + `NinKingTween.play_shop_entrance()` 每个 `await` 后 `is_instance_valid(panel)` 守卫，防场景切换时访问已 free 节点崩溃 | `shop_ui.gd` + `nin_king_tween.gd` | **P0** | ✅ |
| B7 | **商店入场 shake 改用 `shake_node(panel)`** — `screen_shake()` 依赖 Camera2D，商店场景(Control)无 Camera2D 会静默失败。改用 `GlobalTweens.shake_node(panel, 6.0, 0.15)` 震动面板 | `nin_king_tween.gd` | **P0** | ✅ |

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
| B11 | **MusicManager 扩展 BGM 3 段变奏** — 新增 `set_game_variation(barrier)`，根据結界 1-3(轻)/4-6(中)/7-8(重) 自动切换变奏，`_crossfade_to()` 已有 | 3 首 game_bgm 变奏素材 + MusicManager ~15 行扩展 + `_on_seal_started()` 触发 | P1 | ⬜ |

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
| V7 | ~~CRT 扫描线效果接入~~ | ⛔ 已废弃 — 漫画风移除 CRT。见 V24 | P1 | ⛔ |
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
| V22 | **商店 BGM** — 轻松明亮短循环 | 和风 chioptune 商店主题，`assets/audio/music/shop_bgm.ogg`，MusicManager 新增 `play_shop_bgm()` | P1 | ⬜ |
| V23 | **音效素材替换+新增** — Anime Game Pack(1,433 WAV) 自动匹配 20/20 需求 → ffmpeg WAV→OGG 转换 → 复制到项目。P0 核心(11)：deal/group_reveal/count_tick/xi_trigger/xi_fanfare/seal_clear/seal_fail/swap/discard/redraw_pop/ninja_activate。P1 关卡+UI(9)：boss_reveal/boss_final_layer/shop_enter/ui_coin/item_purchase/shop_reroll/shop_exit/ui_click/ui_error。旧 FanKing 占位已备份至 `legacy_placeholders/`，待 C8 SoundBank 更新后清理 | 详情见 `18-audio-asset-matching-guide.md`。旧文件仍保留在目录中待 sound_bank.gd 更新 | P0 | ✅ |
| V24 | **CRT 滤镜移除** — 删除 `crt_filter.gd` + `crt_filter.gdshader` + `GlobalTweens` CRT 引用 + `game_manager.gd` 6 处 CRT 调用 | 漫画风不需要扫描线。覆盖 V7/V18。详见 `16-art-direction-principles.md` §9 | **P0** | ✅ |
| V25 | **barrier_theme.gd 八属性亮色重写** — 8 結界冷暖交替暗色系 → 8 属性（火水風雷土光暗无）亮色版；新增 `particle_color` 字段；name 改为「壱·火」格式 | 覆盖 V17。详见 `16-art-direction-principles.md` §2 | **P0** | ✅ |
| V26 | **漫画粒子预设** — `ParticlePool` 新增 `manga_burst`(集中线) + `manga_ink`(墨迹) + `TweenFX.speed_line_trail()`(速度线) | 覆盖 V9 的像素粒子(shuriken/sakura)。详见 `16-art-direction-principles.md` §8。纹理已部署 `assets/images/effects/` | P1 | ✅ |
| V27 | **卡背漫画风重绘** — 豆包 AI 生成：漫画网点+粗黑描边+中心「忍」字 | 覆盖 V1 的像素卡背。详见 `16-art-direction-principles.md` §7.2。纹理已部署 `assets/images/cards/card_back.png` | P1 | ✅ |
| V36 | **人牌 J/Q/K 漫画插图** — 豆包 AI 生成：少年漫画风人物（Jack 忍者学徒 / Queen 女忍大师 / King 忍皇），每花色不同角色 | 原 `04-asset-gap-list.md` §1 唯一未迁移缺口。4 花色 × 3 人牌 = 12 张 | P2 | ⬜ |
| V37 | **图像素材匹配 Phase 0-3 全线完成** 🎉 — Phase 0: 双包闸门+豆包样板验证 ✅ Phase 1: 16 张 Layer 1 匹配部署 ✅ Phase 2: 31 张 Layer 3 AI 生成→部署 ✅ Phase 3: 45 张后处理（pngquant+网点叠加+dilate检查）✅ | 累计交付 47 张到项目。现成包匹配 16 张 = 节省 34% AI 额度。详见 `19-image-asset-matching-guide.md` | P1 | ✅ |
| V28 | **UI 组件漫画风更新** — `06-ui-layout-reference.md` §6 重写（配色表→8属性亮色版、像素风原则→漫画风原则）；按钮/面板/三墩区分按新规范更新 | 覆盖 V16/V19/V20/V21。详见 `16-art-direction-principles.md` §3/§9 | **P0** | ✅ |
| V29 | **06-ui-layout-reference.md §2 场景树按实际代码重写** — GameLayout 类型(HBoxContainer)、LeftPanel/CenterColumn 层级、RedrawBtn/AiRearrangeBtn/ColumnLabelRow、CardManager 全部补全。对照 `ninking_main.tscn` 实际结构 | review-plan 审阅 A1。文档当前与实际代码严重脱节 | P1 | ⬜ |
| V30 | **06-ui-layout-reference.md OVL_→实际节点名统一** — ScoringOverlay/LevelComplete/GameOver（或注明 OVL_ 为逻辑分类前缀，非实际节点名） | review-plan 审阅 A2 | P2 | ⬜ |
| V31 | **06-ui-layout-reference.md §5 API 方法名/签名/信号名更新** — refresh_abilities→refresh_ninjas、update_match_info 参数修正、删除不存在的 4 方法、swap_used→redraws_changed、level_started→seal_started | review-plan 审阅 A4/A5 | P1 | ⬜ |
| V32 | **06-ui-layout-reference.md §4 补充 VICTORY 视图** — show_view() 映射表加 victory 行；状态切换图补 VICTORY 分支 | review-plan 审阅 A6 | P2 | ⬜ |
| V33 | **06-ui-layout-reference.md §7 文件索引更新** — 新增 hand_display/hand_interaction/deck_viewer_controller/auto_arranger/seal_controller；删除 main_menu.gd；barrier_theme.gd 描述更新为"8 属性亮色色板" | review-plan 审阅 C2/C3 | P2 | ⬜ |
| V34 | **VictoryOverlay 独立覆盖层** — 新建通关覆盖层（VictoryLabel + StatsSummary + MenuButton），`ui_manager.gd` `show_view("victory")` 切换至 VictoryOverlay 而非复用 GameOver，通关粒子庆祝（manga_burst + screen_shake + hit_stop） | review-plan 10-main-ui-design 审阅 Q1/A2 | P1 | ⬜ |
| V35 | **GameOver 补充 ScoreSummary + MenuButton** — 场景加 ScoreSummary（战绩摘要 Label） + MenuButton（返回主菜单），`11-main-overlay-design.md` §6 同步更新 | review-plan 10-main-ui-design 审阅 Q2/A3 | P2 | ⬜ |
| V38 | **商店入场临时粒子替代速度线** — 面板 slam 落地用 `GlobalTweens.burst_particles("shuriken")` 临时替代速度线拖尾，V26 `manga_speed` 预设到位后替换 | `nin_king_tween.gd` `play_shop_entrance()` | P1 | ✅ |
| V39 | **集中线 AI 出图 2 套 + 卷轴匾额 1 套** — 重集中线(600×120, 10-12条放射线, 4-5px粗, 尾端渐尖G-pen手绘感, 透明底纯白线条)用于标题栏+底栏 / 轻集中线(500×70, 4-6条放射线, 2-3px粗)用于分区标题 / 卷轴匾额(500×60, 横向卷轴, 两端轴杆, 粗墨描边, 透明底)用于分区标题衬底。Prompt关键词: `少年漫画集中线, 放射线, 手绘G-pen, 粗细不均, 尾端尖细, 透明底, 纯白线条, manga focus lines, radial speed lines, G-pen tip`。出图后用 modulate 染 BarrierTheme accent 色 | 豆包 AI → `assets/textures/ui/focus_lines_heavy.png` + `focus_lines_light.png` + `section_scroll_frame.png` | P0 | ⬜ |

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
| C7 | 确认清理 `ninking_main.tscn` 中旧 MainMenu 视图节点 | `scenes/ninking/ninking_main.tscn` | P2 | ✅ |
| C8 | **SoundBank 忍者主题重命名** — 废弃 FanKing 遗留名（`HU`→`GROUP_REVEAL` / `YAKU_REVEAL`→`XI_TRIGGER` / `BAO_ACTIVATE`→`NINJA_ACTIVATE` 等），旧常量保留 alias 到全部接线完毕 | `scripts/config/sound_bank.gd` | P1 | ⬜ |
| C10 | **漫画风字体替换** — F1 思源黑体 SC Heavy（粗体）+ F2 SC Regular（正文）+ F3 Yusei Magic（手写/P2）。Phase 1 ✅：字体下载、import 配置（抗锯齿/fallback）、manga_theme.tres 新建、3 tscn 引用切换、旧字体→legacy/、游戏测试通过。 | `pixel_theme.tres` → `manga_theme.tres` / `17-font-design-plan.md` | P1 | ✅ |
| C11 | **术语统一：能力牌→忍者牌** — 文档 §1 术语表更新 + 代码 `ABILITY_SLOT_SCENE`→`NINJA_SLOT_SCENE` + `%AbilityBar`→`%NinjaBar` + `ability_slot.tscn`→`ninja_slot.tscn`。三套术语（忍者/能力/ability）统一为"忍者牌" | review-plan 审阅 Q2 / C4。`ui_manager.gd` 已用 `refresh_ninjas()`，文档和场景未跟上 | P2 | ⬜ |
| C12 | **ScoreCard 节点加 `unique_name_in_owner`** — 计分动效 BounceScore 需要 `%ScoreCard` 引用；`ui_manager.gd` 加 `@onready var score_card: Panel = %ScoreCard` | 审阅 C1。当前 ScoreCard 有 unique_id 但未勾选 unique_name flag | P2 | ⬜ |
| C13 | **game_manager.gd 删除 `const CountUp = preload(...)` 死代码** — 已替换为 `const BounceScore = preload(...)`，CountUp 由 BounceScore 内部加载 | `scripts/ninking/ui/game_manager.gd:6` | P2 | ✅ |
| C14 | **BounceScore 峰值"咚"音效素材缺失** — 过冲峰值处需短促有重量感的音效，当前 SoundBank 无匹配。候选：试听 `redraw_pop.ogg` 或 `item_purchase.ogg`，不合适则需新素材 | `scripts/tween/bounce_score.gd` — `bounce_sfx` 参数当前默认 null | P2 | ⬜ |
| C15 | **shop_ability_card.gd `setup()` 存 `_card_style` 成员变量** — `apply_barrier_theme()` 直接改 `_card_style.bg_color` 等属性，避免重建 StyleBox 覆盖问题 | `shop_ability_card.gd` + `shop_item_card.gd` | **P0** | ✅ |
| C16 | **SoundBank 新增商店音效常量** — `SHOP_ENTER` / `SHOP_EXIT` / `ITEM_PURCHASE` / `SHOP_REROLL` 接入 `sound_bank.gd`（素材已匹配 V23，待常量命名+preload） | `scripts/config/sound_bank.gd` | P1 | ⬜ |

---

## 🔒 Phase D-E — 远期（暂缓）

| # | 任务 | 说明 | 状态 |
|---|------|------|------|
| D1 | 牌组系统（暗夜/赤阳/混沌/龙脉） | 4 种特殊牌组 + 解锁条件 | 🔒 |
| D2 | 封印系统重新设计 | 原设计在比鸡 9 张全出下 OP | 🔒 |
| D3 | Tag 系统 | 投资/星图/忍者/优惠/稀有 Tag | 🔒 |
| D4 | 卡包系统 | 附魔包/星图包/封印包/秘仪包 | 🔒 |
| D5 | n_x04 黑龙 / n_x05 赤凤 | 需牌组系统支持 | 🔒 |
| D6 | 商店 BGM | → 已提升至 V22 (P1) | ✅ |
| D7 | 数值平衡调优 | 完整验证难度曲线 + 价格平衡 | 🔒 |
| D8 | 音频替换为扑克风格 | → 已拆分为 V23(素材) + B11(BGM变奏) + C8(重命名)，详见 `15-sound-design-plan.md` | ✅ |

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
| 2026-06-10 | 📋 **方案审阅+Grill: 商店 UI 漫画热血风重制**: 27 轮 grill 决策确认（亮色 BarrierTheme 配色/冲击帧标题栏+分区标题/卡片安静/底栏对称重炸/按钮中二化/入场电影感节奏 1.6s/NinKingTween 新建）。review-plan 审阅 3 维度通过，B6/B7/C15/C16/V38 共 5 项加入 TODO。10 项实施任务待执行。 |
| 2026-06-10 | 📋 **方案审阅+Grill: 计分动效 BounceScore**: 10 轮 grill 决策确认（主分数弹性着陆 0.6s + ProgressBar 延迟 + Chips/Mult 闪 + ScoreCard 发光）。review-plan 审阅 3 维度通过，C12/C13 共 2 项加入 TODO。新文件 `bounce_score.gd`，改 `game_manager.gd` 一行。 |
| 2026-06-10 | 🎨 **V24+V25 漫画风基建完成**: V24 CRT 滤镜移除 — 删 `crt_filter.gd`/`.gdshader` + `global_tweens.gd` CRT 子系统(3 public API + `_on_first_scene_loaded`) + `game_manager.gd` 6 处 CRT 调用(`_crt_offset`/`_process`/Boss reveal vignette+aberration/failure aberration)。V25 `barrier_theme.gd` 八属性亮色重写 — 暗色系(紫/红/青/橙/蓝/金/翠/粉)→亮色版(火水風雷土光暗无)，新增 `particle_color` 字段 + `get_particle_color()` API，name 格式「壱·火」。global_tweens 从 8→7 个子系统。 |
| 2026-06-10 | 📋 **V23 音效匹配指南 v2**: `18-audio-asset-matching-guide.md` 重写为 Claude 可自动执行的机器规范。§1-§5 四阶段流水线（扫描→打分匹配→转换复制→验证），§3.3 完整规则表（20项需求 × 正则/filename/duration/neg_patterns），§3.4 打分算法（关键词权重+目录加权+duration惩罚），§6 Claude 执行协议（9步自动执行+人工介入触发条件），§7 模糊目录映射，§8 后续自动衔接任务。用户只需提供素材包路径，Claude 全自动完成。 |
| 2026-06-10 | 📋 **06-ui-layout-reference.md review-plan 审阅**: A维度 8 项 + B维度合规通过 + C维度 5 项。发现 §2 场景树与代码严重脱节（节点名/类型/层级 10+ 处不同）、§5 API 方法名/签名过时、CRT 文档-代码矛盾。V29-V33 共 5 项 + C11 术语统一 1 项加入 TODO。Q1（场景树对齐当前代码）Q2（能力牌→忍者牌）决策确认。 |
| 2026-06-10 | 📝 **UI 文档漫画风同步**: `06-ui-layout-reference.md` §6 重写（配色表→8属性亮色版，像素风原则→漫画风原则表，旧→新对照），三墩约束显示更新，DeckBtn 样式更新。`07-shop-ui-design.md` v2→v3（设计目标/配色方案全替换为漫画风，交互流程加入漫画FX层）。`08-figma-naming-convention.md` 新增漫画特效元素类型（集中线/速度线/拟声词/网点），Frame 列表更新。`04-asset-gap-list.md` 像素→漫画风格化进度、CRT 移除、漫画粒子预设。V28 标记完成。 |
| 2026-06-10 | 📋 **15-sound-design-plan.md 审阅+修复**: 风格更新为动画 SFX（§1/§2/§4/§5/BGM）。审阅发现 3 处遗漏修复（§3 目标列/§8 目录注释/S12 术语）。 |
| 2026-06-10 | 🔤 **17-font-design-plan.md 字体方案 + 审阅修复**: 漫画ゴシック体选型 — F1 思源黑体 SC Heavy + F2 SC Regular + F3 Yusei Magic(P2)。3 字体全 OFL 免费可商用。Phase 1 下载+导入+Theme 替换估时 1h。审阅 6 项修复：JP→SC、§7.2 改名→新建、fallback 链去循环、F3 楷体→手書き、优先级统一 P1、.import 自动生成说明。 |
| 2026-06-10 | 🏗️ **手牌布局精确对齐**: Card Framework move-tween 竞态导致 3-5px Y 偏差。`_fixup_layout` 改为先 `update_card_ui()` 再 `_force_card_positions()`（按 `_held_cards` 序直接赋值 `global_position`，绕开 move() tween）。Timer 0.1→0.3s。实测 9 张卡牌 X/Y 偏差降至 0.000px。
| 2026-06-10 | 📝 **03-technical-design.md 同步**: NinKingCard 类图更新（程序绘制→SVG 纹理渲染），HandDisplay 类图新增 `_fixup_layout()`. |🔴 Boss 名称全部修正为实际名单（断尾/无头/独柱/铁链/反目/封印师/饿鬼/散牌王/喜之克星/终焉），🟡 卷轴 800×500、商店面板→9-patch、图标 15→10 精简。`05-image-asset-generation-plan.md` 重写完成，~41 张 AI + ~80 张拼装，P0/P1/P2 三阶段可执行。现有 V4/V5/V7/V15 素材项被新方案覆盖。 |
| 2026-06-10 | 📋 **10-main-ui-design.md review-plan 审阅**: A维度 8 项 + B维度合规通过 + C维度 7 项。发现 §2 缺 DeckViewer/VictoryOverlay、GameOver 子树不完整、HandTypeRow 语义偏差。方案已修复（补 DeckViewer + VictoryOverlay + ScoreSummary + MenuButton + 交互流 VICTORY 分支）。V34（VictoryOverlay 实现）+ V35（GameOver 补节点）加入 TODO。 |
| 2026-06-10 | 🐛 **B4 修复: SEAL_INTRO 卡死**: `_begin_seal_phase()` await timer 被 change_scene_to_file 销毁 → 移至 `game_manager._intro_timer()`。影响新游戏/继续/商店返回三个路径 |
| 2026-06-10 | 📋 **测试指南**: `testing-guide.md` — 场景流转图、状态机、MCP 命令速查、常见陷阱与解决方案、快速调试命令集 |
| 2026-06-09 | 🧹 **C7 完成: 清理旧 MainMenu**: ninking_main.tscn 删 MainMenu 子树(76行)，game_manager 删 MAIN_MENU 分支+_on_start_pressed，ui_manager 删 3 个 @onready 引用 |
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
| 2026-06-10 | 🎨 **字体可读性修复**: F1 `manga_theme.tres` 按钮默认字体色 `(0.1,0.1,0.1)`→`(0.95,0.95,0.9)` 白色（深色底上不可见）| F2 `barrier_theme.gd` 结界8「无」accent `(0.35,0.35,0.38)`→`(0.55,0.55,0.58)` 提亮 | F3 `game_manager._on_seal_started()` btns 数组移除 PlayBtn/RedrawBtn/DeckBtn — accent 字体覆盖与场景预设配色冲突（红底红字/蓝底蓝字不可读）| F4 `dun_highlighter.gd` StatusLabel 约束满足时清除 `font_color` override 恢复默认 | 文档同步: `06-ui-layout-reference.md` + `16-art-direction-principles.md` 结界8 accent 色值更新, `10-main-ui-design.md` §4.4 按钮表加字体色列 + accent 覆盖例外说明, §5.1 补动态配色应用范围 |
| 2026-06-10 | 📋 **方案审阅: 19-image-asset-matching-guide v1→v2**: Grill 5 盲区 + review-plan 3 维度审阅。🔴 A1-A3 已修（Layer 2 删除→Layer 3 / GIMP→ImageMagick / ninja_card_renderer.gd 引用修正）。🟡 A4-A7 已修（§7 精简 / Kenney 闸门 / 批次化 prompt 模板 / ImageMagick 命令修正）。Q1 Layer 2 降级 + Q2 Kenney 硬性闸门决策落地。V37 Phase 0 样板验证加入 TODO。 |: Phase 1(扫描 1,433 WAV → 索引) → Phase 2(20 需求自动打分匹配 → 人工去重确认) → Phase 3(ffmpeg WAV→OGG libvorbis -q:a 6 转换) → Phase 4(全部 20 文件存在+时长验证通过)。| 素材源: Epic Stock Media Anime Game Pack。| 关键匹配: S11 boss_reveal='Dark Ominous Reveal'(完美), S15 item_purchase='Loot Chest Equip Gain'(完美)。| 已知限制: 包内无超短音效(<0.2s)，count_tick/ui_click 使用最短可用(0.25-0.29s)。| 旧 FanKing 占位已备份至 `legacy_placeholders/`，待 C8 SoundBank 更新后清理。| 覆盖 03-technical-design §8 + 15-sound-design-plan + 18-audio-asset-matching-guide |
| 2026-06-10 | 📋 **19-image-asset-matching-guide v2→v3 实地资产校准**: Game Icons 2 已下架（404）→ Board Game Icons (255+) 替代。§2.2 数据修正、§2.3 新增 BGI 行、§5.2 全部 15 行改实际文件名（GI/BGI 双包前缀）、§7 拆 #1→1a/1b、§12 附录 B Phase 0 闸门适配双包、§8 同步。V37 TODO 更新源包列表。|
| 2026-06-10 | 🗑️ **删除 `04-asset-gap-list.md`**: 严重过时+三文档冗余（信息已分散至 `05-image-asset`/`15-sound-design`/`16-art-direction`/TODO.md）。唯一未迁移缺口「人牌 J/Q/K 插图」→ V36 加入 TODO。5 处文档引用已清理。 |
| 2026-06-10 | 🐛 **商店卡片 Nil 崩溃修复**: `shop_ability_card.gd`/`shop_item_card.gd` `@onready` 初始化时机问题（`setup()` 在 `add_child()` 前调用，`@onready` 未触发）。修复：① `_cache_nodes()` 懒初始化 ② `%`→`$` 消除 unique_name 依赖 ③ `$PriceLabel`→`$PriceBadge/PriceLabel` 修正嵌套路径 ④ `shop_item_card.gd` `extends PanelContainer`→`Panel` 修正场景类型不匹配 ⑤ 补 `purchase_requested` 信号+连接 ⑥ 参数 `name`→`card_name`/`item_name` 消除 `Node.name` 遮蔽警告。review-plan 审阅通过。 |
| 2026-06-10 | 🖼️ **图像素材匹配 Phase 0-1 执行完成**: Phase 0 双包闸门 star+katana 通过(2/3)，coin→AI 占位。豆包 3 样板全过 §6.4（suit_spade⭐/icon_star✅/boss_broken_tail✅）。Phase 1: 16 张 Layer 1 资产部署（4 花色+10 忍者图标+2 消耗品图标）→ `assets/images/`。`19-image-asset-matching-guide.md` v3 同步。剩余 Layer 3 AI: 31 张。|
| 2026-06-10 | 🖼️ **Phase 2 AI 图像生成全部完成**: 31 张 Layer 3 全部生成+部署（4 忍者底板+3 消耗品底板+10 Boss+4 图标+1 Logo+1 卡背+1 顶栏+1 面板角+1 游戏图标+3 粒子+1 牌桌背景）。V26/V27/V37 标记完成。累计交付 47 张到 `assets/images/`。Phase 1 现成包匹配 16 张 = 节省 34% AI 额度。|
| 2026-06-10 | 🖼️ **Phase 3 后处理统一全部完成**: pngquant --colors 32 批量（45 张）+ ordered-dither h4x4a 漫画网点（13 张底板/卡背/花色/面板/顶栏）+ stroke check 通过。table_bg（800×500）跳过 dither 仅保留 pngquant（网点过粗）。`19-image-asset-matching-guide.md` v4 同步。|
