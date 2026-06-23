# NinKing 工作清单

> **最后更新:** 2026-06-23 | **当前 Phase:** Kenney 暖纸风 UI 改造 Phase KUI  + Shader 内部优化 S1-S7 + shaderlist 优化 S8-S14 | 本次: S8 清理完成 ✅ S10 HaloFX 实施完成 ✅ S11-S14 暂缓
> **使用方式:** AI 每次会话开始时读取此文件。完成任务后更新状态。
> **状态图例:** ⬜ 待做 | 🔵 进行中 | ✅ 已完成 | 🔒 暂缓 | ⛔ 已废弃

---

## 🆕 新喜设计定案 (2026-06-16 ✅ 已实施)

| # | 任务 | 详情 | 优先级 | 状态 |
|---|------|------|--------|------|
| X1 | **昇龍 实现** — 影<瞬<滅 牌型严格递增 ×3 | `xi_detector.gd` + `score_calculator.gd` + `animation_handler.gd` + `hand_type_labeler.gd` | **P1** | ✅ |
| X2 | **背水 实现** — 尾墩散牌 ×4 | `xi_detector.gd` + `score_calculator.gd` + `animation_handler.gd` + `hand_type_labeler.gd` | **P1** | ✅ |
| X3 | **貧打 实现** — 某墩含2-3-5 ×4 | `xi_detector.gd` + `score_calculator.gd` + `animation_handler.gd` + `hand_type_labeler.gd` | **P1** | ✅ |
| X4 | **陣眼 实现** — 中心牌全局最小或最大(含并列) ×3 | `xi_detector.gd` + `score_calculator.gd` + `animation_handler.gd` + `hand_type_labeler.gd` | **P1** | ✅ |
| X5 | **均爵 实现** — 每墩至少一张J/Q/K ×3 | `xi_detector.gd` + `score_calculator.gd` + `animation_handler.gd` + `hand_type_labeler.gd` | **P1** | ✅ |
| X6 | **三等 实现** — 三行chip总和相等 ×5 | `xi_detector.gd` + `score_calculator.gd` + `animation_handler.gd` + `hand_type_labeler.gd` | **P1** | ✅ |
| X9 | **豹子 实现** — 某墩牌型=豹子 ×2 (组级, per-group) | `xi_detector.gd` + `score_calculator.gd` | **P1** | ✅ |
| X10 | **满堂 实现** — 3行+3列全部非散牌 ×5 | `xi_detector.gd` + `score_calculator.gd` + display files | **P1** | ✅ |
| X11 | **三合/双合/一合 实现** — 行↔列对角匹配 3/2/1组 (互斥) | ×6/×4/×2 | **P1** | ✅ |
| X7 | **喜展示UI** — 需要一种机制展示已触发的喜类型和数量 | 待设计（Grill session中列为代办） | **P2** | ✅ |
| X8 | **门清理** — 删除`shop.tscn`及11个orphan文件 | 2026-06-16已执行 | **P3** | ✅ |

## 🐛 Bug 修复

| # | 问题 | 位置 | 优先级 | 状态 |
|---|------|------|--------|------|
| B25 | **18 个布局喜未加入 `global_xi_names` 白名单，计分时不乘** — XiDetector 检测并显示这些喜，但 `ScoreXiHandler.get_global_xi_x_stack()` 的 `global_xi_names` 数组遗漏了 2026-06-19 新增的 18 个布局喜（四角/中十字/倒影/双壁/对影/连环/天九/压牌/至尊/独尊/文武/廿一点/一气/无将/长套/无忧角/慢打/四对半），导致它们仅显示在 Debug 面板中，不参与实际计分。修复：追加到白名单 | `scripts/ninking/score/score_xi_handler.gd:32-38` | **P0** | ✅ |
| B1 | Boss "封印师" 仍用旧逻辑 `random_group_zero` — 已改为 `lowest_group_zero`（分数最低组×0） | `blind_controller.gd:33` | **P0** | ✅ |
| B2 | Boss 效果字典 key 已对齐 10 Boss 定义 | `blind_controller.gd` + `score_calculator.gd` | **P0** | ✅ |
| B3 | XiDetector: 全顺/三顺清/顺清打头/全三条/通锅 5 个喜模式未实现 — 全部 9 喜已实现（通锅=全顺） | `xi_detector.gd:76` | **P1** | ✅ |
| B4 | SEAL_INTRO → PLAYING timer 被 change_scene_to_file 销毁，导致新游戏/继续/商店返回时卡在结界标题 | `game_state.gd:312` + `game_manager.gd:48-52` | **P0** | ✅ |
| B5 | SVG 卡牌尺寸错误 — Godot 4 TextureRect KEEP_SIZE + non-SCALE stretch 每帧覆盖 size 为纹理原始尺寸(240×334)，卡牌显示过大 | `ninking_card.gd:87-107` | **P0** | ✅ |
| B6 | **商店入场动画竞态守卫** — `_play_entrance()` 加入口 `_entrance_active` 标志位 + `NinKingTween.play_shop_entrance()` 每个 `await` 后 `is_instance_valid(panel)` 守卫，防场景切换时访问已 free 节点崩溃 | `shop_ui.gd` + `nin_king_tween.gd` | **P0** | ✅ |
| B7 | **商店入场 shake 改用 `shake_node(panel)`** — `screen_shake()` 依赖 Camera2D，商店场景(Control)无 Camera2D 会静默失败。改用 `GlobalTweens.shake_node(panel, 6.0, 0.15)` 震动面板 | `nin_king_tween.gd` | **P0** | ✅ |
| B14 | **忍者栏拖拽失效** ✅ — 原手工拖拽 `get_global_rect().has_point()` 在 HBoxContainer 内误检 + TextureRect EXPAND_KEEP_SIZE 展示原始尺寸。整栏迁移至 card-framework：新建 `NinjaInventoryCard`(Card 子类) + `NinjaBarContainer`(CardContainer 子类，DropZone 垂直分区检测落点) + `ninja_bar_node.gd` 重写。删 `ninja_slot.gd`/`ninja_slot.tscn`。`ninja_bar_display.gd` 改用 NinjaInventoryCard。| `ninja_inventory_card.gd`(新) + `ninja_bar_container.gd`(新) + `ninja_bar_node.gd` + `ui_manager.gd` + `ninking_main.tscn` + `debug_ninking_main.tscn` + `debug_controller.gd` + `ninja_bar_display.gd` | **P0** | ✅ |
| B15 | **计分动画忍者条件不匹配误触发** — `ninja_affected_groups()` 返回 `[]` 的语义歧义（无条件→全组 vs 条件不匹配→无组）导致条件型忍者在不匹配的牌型上也触发动效和计分。原修复仅覆盖 `animation_handler.gd` 旧路径，遗漏 `score_calculator.gd` `analyze_effects()` 的 Phase H 预计算路径和 `score_effect_collector.gd` `collect_ninja_per_group()` 计分引擎路径。**完整修复** (2026-06-18)：三个调用处均添加条件存在判断，`groups.is_empty()` 且 `condition` 含 `hand_type`/`group` 时 `continue`/`return` 跳过 | `animation_handler.gd:518-525` + `score_calculator.gd:451-458` + `score_effect_collector.gd:142-145` | **P0** | ✅ |
| B16 | **`ninja_affected_groups()` 不识别 `head_or_mid` 组值** — 双头蛇 n_g05 的 condition.group `"head_or_mid"` 未在单组匹配分支中识别，掉落 `return []` 导致被当作"所有组"。修复：添加 `head_or_mid` 多组检查分支，分别验证 head/mid 各自条件。同时影响计分(collect_ninja_per_group)和动画 | `scripts/ninking/score_calculator.gd:551-559` | **P0** | ✅ |
| B17 | **手牌拖拽交换不生效** — 3 个隐藏 bug 逐步排查修复：① `_card_can_be_added` 同容器重排时满容量（9/9）误拒，修复为检查是否全部已存在则跳过容量检查；② `get_partition_index` 基类只返回列索引（0-2），需覆盖为行×COLS+列的网格索引（0-8）；③ `SealController.swap_cards` 内有 `gs.current_state != PLAYING` 守卫，Debug/MAIN_MENU 状态下不 emit `hand_swapped` 信号 → `swap_two_cards` 不触发，需在非 PLAYING 状态直接调用 | `ninking_card.gd` + `hand_card_container.gd` + `hand_display.gd` + `hand_interaction.gd` + `ui_manager.gd` | **P0** | ✅ |
| B18 | **Debug 场景 讨伐按钮约束不满足时灰色样式不生效** — `_update_button_states()` 只检查牌数（≠9），不检查 head ≤ mid ≤ tail 约束。即使 `_on_play_pressed()` 中有约束检查阻止行为，按钮视觉上仍是启用状态（红色）。修复：`_update_button_states()` 牌数=9时增加 `Arrangement.is_legal()` 检查，不满足时 `play_btn.disabled = true` 触发 `theme_override_styles/disabled` 灰色样式 | `debug_controller.gd` | **P0** | ✅ |
| B19 | **ScoreResult.chips_sum/mult_sum 未赋值 → debug 场景显示 "0 × 1 = 总分"** — 两个字段声明后全项目无任何代码赋值，debug_controller.gd:490 直接用它们格式化 `_score_label.text`，导致始终显示 `"0 × 1 = N"`。主场景不受影响（走 `_score_subtotal` 路径）。修复：`ScoreCalculator.calculate()` 和 `calculate_with_summary()` 中各加两行求和赋值 | `scripts/ninking/score/score_calculator.gd`（+4行） | **P0** | ✅ |
| B20 | **barrier_config.gd 关卡分值同步 v5.1** — 设计文档和模拟器已更新 24 个 target 值，但游戏代码仍用旧 v3.3 值（B1 修羅 300→15K 等）。全量同步 `barrier_config.gd` 的 24 个封印 target 与 `sim_config.py`/`13-blinds-and-bosses.md` 一致 | `scripts/ninking/barrier_config.gd`（24 target + 版本注释） | **P0** | ✅ |
| B21 | **商店中间卡牌无法购买 + 右键无效** — CardGrid（UIManager 兄弟节点，z_index=10）渲染在 ShopOverlay 之上，卡牌 MOUSE_FILTER_STOP 拦截中间两张商店卡区域的鼠标事件。修复：① `ui_manager.gd:214` shop 时隐藏 CardGrid ② `shop_slot.gd:52-55` 卡牌本体点击连接 `card_clicked → _on_buy_pressed` | `ui_manager.gd` + `shop_slot.gd` | **P0** | ✅ |
| B22 | **删除 B14 忍者替换购买系统** — 删 `ninja_replace_overlay.gd`(含.uid) + `_start_replace_flow()` + `_replace_guard` + `show/hide_replace_overlay()` + `ShopManager.replace_ninja()` | `shop_handler.gd` + `ninja_replace_overlay.gd` + `shop_manager.gd` + `ui_manager.gd` | **P0** | ✅ |
| B23 | **满员购买 → Toast + 忍栏脉冲 + UI_ERROR 音效** — `on_purchase_requested()` 满员分支改为 `ToastManager.show("忍者栏已满，请先出售", 2.0)` + `_ui.pulse_ninja_bar()` + `GlobalTweens.play_sfx(SB.UI_ERROR)` | `shop_handler.gd` | **P0** | ✅ |
| B24 | **新增 `pulse_cards()` 集体脉冲动画** — 忍者栏卡片集体 pulse: scale 1.0→1.08→1.0, 0.15s×2轮, 用 `GlobalTweens.scale_pop()` 链式调用。ui_manager 委托到 ninja_bar_node | `ui_manager.gd` + `ninja_bar_node.gd` | **P0** | ✅ |
| B26 | **牌库面板已出牌无灰色 + 尺寸异常** — `fake3d.gdshader` fragment 直接 `COLOR = texture(...)` 覆盖了 Godot 内置的 `MODULATE`，导致 `pc.modulate = Color(0.35, 0.35, 0.35, 0.65)` 无效。修复：三个 fake3d shader 末尾加 `COLOR *= MODULATE;`；`ninking_card.gd` `_apply_fake3d_material()` 中 `can_be_interacted_with == false` 时跳过（deck viewer 卡牌不需要 3D 倾斜+消除 vertex 膨胀导致的尺寸问题） | `shaders/fake3d/fake3d.gdshader` + `fake3d_flash.gdshader` + `fake3d_shadow.gdshader` + `scripts/ninking/ui/ninking_card.gd` | **P0** | ✅ |

---

## 🏗️ Phase C — 同场景沉浸化通关流程

> **Grill 19 轮 + review-plan 审阅通过, 2026-06-11**
> **核心改动：** 消除 SEAL_COMPLETE→SHOP→下一封印 间的场景切换，全流程在 ninking_main.tscn 内完成。
> 决策树详见记忆 `flow-immersion-decisions-2026-06-11.md`

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| S1 | **shop_panel.tscn 场景片段提取** | 从当前 `shop.tscn` 提取根节点 Content 为 `res://scenes/ninking/shop_panel.tscn`（CanvasLayer 或 Control），保留所有 unique_name 引用。shop_ability_card / shop_item_card 子场景保持独立 | **P0** | ✅ |
| S2 | **shop_ui.gd 重写为 panel 模式** | 接受 init data（stock, gold, barrier_colors），通过信号上报操作（`purchase_requested` 已有、新增 `reroll_requested` / `continue_requested`）。删除对 `NinKingGameState` 的直接引用。`_on_continue_pressed` 删 `change_scene_to_file` 改为 emit 信号 | **P0** | ✅ |
| S3 | **NinKingTween 扩展** | 新增：① `play_shop_exit(config)` — 卡片 gather 回中心 + panel slide_out + overlay fade_out，~50 行 ② `play_reroll_vfx(old_cards, new_cards)` — 飘出飘入，~30 行 ③ `play_ninja_pop_in(slot_node)` — 新忍者入槽 pop_in + color_flash，~15 行 | **P0** | ✅ |
| S4 | **ui_manager.gd 加 ShopOverlay 引用** | `@onready var shop_overlay: Control = %ShopOverlay` + `show_view("shop")` 映射。新增 `show_shop()` / `hide_shop()` 方法 | **P0** | ✅ |
| S5 | **ninking_main.tscn 加 ShopOverlay 子树** | UIManager 下新增 ShopOverlay (Control) 节点，包含 Overlay (ColorRect) + ShopPanel 实例化入口。运行时动态 `add_child(shop_panel.instance())` | **P0** | ✅ |
| S6 | **game_manager.gd 重写 go_shop + SHOP 状态 + intro_timer** | `_on_state_changed` 加 SHOP 分支逻辑；`_on_go_shop_pressed()` 从 scene 切换改为：清理牌桌 → LevelComplete fade_out → 触发 ShopOverlay 入场；`_intro_timer` 2s→0.5s | **P0** | ✅ |
| S7 | **Boss 揭示移到 PLAYING 中** | 非 Boss 封印：0.5s 浮水印 → PLAYING。Boss 封印：0.5s 浮水印 → PLAYING 站稳(0.3s 延迟) → Boss 立绘 punch_in + 浮水 1.5s | **P0** | ✅ |
| S8 | **牌桌清理序列** | ShopOverlay 入场同时，GameLayout 进行 fade_out。ShopOverlay 关闭时，GameLayout 重新 visible+modulate 还原 | **P1** | ✅ |
| S9 | **文档同步** | ① `07-shop-ui-design.md` 节点结构从 Shop→shop_panel；② `03-technical-design.md` 场景树补 ShopOverlay、状态图更新、删除 shop.tscn 行；③ `06-ui-layout-reference.md` 补 ShopOverlay 视图 + show_view 表 + 更新接口 | **P1** | ✅ |
| S10 | **删除旧 shop.tscn** | 确认所有引用清理后删除 `scenes/ninking/shop.tscn` | **P1** | ✅ |

---

## 🏗️ Phase A — 核心引擎完善

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| A1 | Boss Blind 系统：实现 10 Boss 完整效果 | 所有 10 Boss 效果已实现（`blind_controller.gd` + `score_calculator.gd` + `level_config.gd`） | **P0** | ✅ |
| A2 | Boss AI 适配 | 6 种 Boss 评分策略已实现：deprioritize/skip_weak/scatter_king/hungry_ghost/balance/constraint_reverse | **P0** | ✅ |
| A3 | 商店 MVP 完善 | 修复场景切换 bug + 方法名更新 + 忍者槽位指示器 + GoldPill 布局调整 | **P0** | ✅ |
| A4 | 喜系统补全 | 全部 9 种喜已实现：全黑/全红/全顺/全同花/四张/三清/三顺清/顺清打头/全三条 | **P1** | ✅ |
| A5 | ~~换牌 UI 交互~~ | 9张牌策略下不适合，已移除（2026-06-11） | **P1** | 🗑️ |
| A6 | 交换 UI | 点击交换（已有）+ 拖拽交换（新增 NinKingCard 拖拽信号 + HandDisplay 落点检测 + HandInteraction 跨容器交换）| **P1** | ✅ |
| A7 | 出牌/计分动画流程 | 组揭示 → 计分跳动 → 喜触发粒子 → 过关/失败判定。SealController 拆为 prepare/finalize，CountUp 直接调用，零手写 Tween | **P1** | ✅ |
| A8 | 永久死亡存档 | 失败/胜利自动记录战绩+删 run 存档，checkpoint 在封印开始时保存，新增 continue_run/has_saved_run | **P1** | ✅ |
| **A9** | **列分机制** | 3×3 网格纵向列计分（列_i = 影[i]+瞬[i]+滅[i]），列专属基础值 2.5× 横向，AI 只优化横向，交换不自动重排，新增 AI 重排按钮 + 列标签 | **P0** | ✅ |
| **A10** | **score_calculator.gd 完全重写** ✅ | 扁平池→三行独立计分+列×mult(2/4/8/16/32)累乘+全局喜×mult。新 ScoreResult。忍者/卡片×mult 跟组走 | `scripts/ninking/score_calculator.gd` | **P0** | ✅ |
| **A11** | **auto_arranger._fast_score() 同步新公式** ✅ | AI 排列评分改用 per-group + 列近似奖励 + 同点离散惩罚。接口改为 per-group ninja dicts | `scripts/ninking/auto_arranger.gd` | **P0** | ✅ |
| **A12** | **arrange_controller 忍者跟组走** ✅ | `_compute_per_group_ninja_effects()` 预计算分组忍者效果，调用 `ScoreCalculator.collect_ninja_per_group()` | `scripts/ninking/arrange_controller.gd` | **P0** | ✅ |
| **A13** | **card_data.gd 清理列基础值函数** ✅ | 删 COLUMN_HAND_TYPE3_BASE_VALUES 及 4 个列函数 | `scripts/ninking/card_data.gd` | P1 | ✅ |
| A14 | **xi_detector.gd 四张 ×5** ✅ | 四张 chips:50→0, x_mult:1→5 | `scripts/ninking/xi_detector.gd` | P1 | ✅ |
| A15 | **item_data.gd 道具整化** ✅ | 暴击骰子 x_mult:1.5→2，其余保持整型 | `scripts/ninking/item_data.gd` | P1 | ✅ |
| A16 | **animation_handler.gd breakdown 格式更新** ✅ | "影: N 瞬: N 滅: N\n列: ×N×N×N\n喜: ×N×N"。删旧 col_chips/col_mult | `scripts/ninking/ui/animation_handler.gd` | P1 | ✅ |
| A17 | **hand_type_labeler.gd 预览更新** ✅ | 无需修改 — 签名兼容 | `scripts/ninking/ui/hand_type_labeler.gd` | P1 | ✅ |
| A18 | **seal_controller.gd 调用点适配** ✅ | 无需修改 — calculate() 签名相同 | `scripts/ninking/seal_controller.gd` | P1 | ✅ |
| A19 | **列 VFX 庆祝阈值调低** ✅ | 同花(×8)以上列触发粒子庆祝 | `scripts/ninking/ui/animation_handler.gd` | 🟢 | ✅ |
| A20 | **场景节点替换：CMC → ColXiLabel** ✅ | 删 `ChipsMultContainer`，新建 `ColXiLabel` 32px 金+accent | `ninking_main.tscn` | **P0** | ✅ |
| A21 | **ui_manager 引用更新** ✅ | 删 chips/mult，增 col_xi_label | `scripts/ninking/ui/ui_manager.gd` | **P0** | ✅ |
| A22 | **HandTypeLabeler 列喜预览** ✅ | `_update_col_xi_preview()` 列 eval + xi detect | `scripts/ninking/ui/hand_type_labeler.gd` | **P0** | ✅ |
| A23 | **HandDisplay 适配** ✅ | setup 签名更新 | `scripts/ninking/ui/hand_display.gd` | **P0** | ✅ |
| A24 | **BounceScore 删参** ✅ | 删 chips/mult，改闪 col_xi_label | `scripts/tween/bounce_score.gd` | P1 | ✅ |
| A25 | **animation_handler Phase 1 分数动效** ✅ | 每墩揭示后 ShadowScore flash + 完整 chips×mult | `scripts/ninking/ui/animation_handler.gd` | **P0** | ✅ |
| A26 | **card_data 列 ×mult 字典** ✅ | `COL_X_MULT_VALUES` 公开常量 | `scripts/ninking/card_data.gd` | P1 | ✅ |
| A27 | **文档同步：06-ui-layout-reference** ✅ | §3.3a + 场景树更新 | `docs/ninking/06-ui-layout-reference.md` | P2 | ✅ |
| A28 | **文档同步：10-main-ui-design** ✅ | §3.2 更新 | `docs/ninking/10-main-ui-design.md` | P2 | ✅ |

---

## 🧩 Phase B — 系统完善

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| B4 | **商店刷新机制 (reroll)** ✅ — 递进式费用 $3+$1/次（Balatro 风），每趟商店重置，无硬上限。shop_handler._reroll_count 跟踪刷新次数 + _get_reroll_cost() 计算动态费用。shop_ui: 删 REROLL_COST 常量，加 update_reroll_cost() 动态更新按钮禁用状态。ui_manager 加 shop_panel_update_reroll_cost() 委托。金币不足时 Toast 提示 | `shop_handler.gd` + `shop_ui.gd` + `ui_manager.gd` | P2 | ✅ |
| B5 | **附魔卡使用流程** 🔒 — Balatro 风购买即用：`consumable_data.gd` 花色符 1→4 拆分 + `get_random_fujutsu` 过滤放逐令。新建 `enchant_target_selector.gd`（手牌 SVG 渲染选牌弹窗）。`shop_ui.gd` 加 `enchant_purchase_requested` 信号 + `start_enchant_targeting`。`shop_handler.gd` 加 `on_enchant_purchase_requested`（扣钱→选牌→应用效果）。`ui_manager`/`game_manager` 接线。影响 6 文件 | `consumable_data.gd` + `enchant_target_selector.gd`(新) + `shop_ui.gd` + `shop_handler.gd` + `ui_manager.gd` + `game_manager.gd` | **P3** | 🔒 |
| B6 | **星图卡使用流程** ✅ — 购买即用（Balatro 风不进背包）。`shop_handler._purchase_star_chart()` 检测 `item.has("hand_type")` → 扣钱 → `ShopManager.apply_star_chart()` +1 等级 → Toast → ShopSlot 灰色标记 | `shop_handler.gd` + `shop_slot.gd` + `shop_ui.gd` + `ui_manager.gd` | P2 | ✅ |
| B7 | 秘仪卡系统 | 购买即生效的全局限效果（消耗品，不占槽位） | P2 | ✅ |
| B8 | **忍者牌条件效果** | 已实现：score_calculator.gd _ninja_condition_met() 完整支持 group/hand_type/xi 条件检测 | P2 | ✅ |
| B9 | **主菜单系统** — 闪屏→按钮→牌组选择→继续确认 | 详见审阅报告。要点：① 按钮 hover/click SFX ② `_ready` 触发菜单 BGM ③ `stagger_slide_in(slide_offset=80)` ④ 牌组中文名映射 `DECK_NAMES` ⑤ 未实现牌组(night/sun)置灰不可点击 ⑥ CRT 滤镜开启 ⑦ `_panel_open` 双击守卫 | **P0** | ✅ |
| B10 | **接入修炼忍者成长系统** ✅ — `NinjaScaling.process_scaling()` 接入 `finalize_play` (on_play)，构建 context (head/mid/tail_type + triggered_xis)。n_s04 忍法帖 已删除（trigger: on_redraw 对应手替え已废弃）| `seal_controller.gd` `finalize_play` xi_triggered 后、win/lose 前调用。剩余 5 张修炼忍者全部正常工作 | P2 | ✅ |
| B12 | **右键卡牌详情弹窗** ✅ — DisplayCardBase._on_gui_input 右键分支 → CardDetailPopup 弹窗（大图+名+描述）。ShopSlot 调用 set_detail_data() 提供弹窗数据 | P2 | ✅ |
| **B13** | **NinjaBar Balatro 风改造** ✅ — Grill 12 轮 + review-plan 审阅通过（2026-06-12）。详见决策汇总。分步实施：<br>**Step 1** — `NinjaBarDisplay` RefCounted→Node 重写（`ninja_bar_node.gd`），挂载场景树，_ready 时序守卫<br>**Step 2** — `NinjaSlot` 增强：悬停放大(`GlobalTweens.card_hover`)；点击 zoom-in 信号；Godot 内置拖放 skeleton<br>**Step 3** — 差值更新：`refresh()` diff 模式；新卡 stagger pop_in(80ms)；移除卡 fade_out+shrink；间距 8-24px 弹性压缩<br>**Step 4** — 拖拽排序完整实现：`move_ninja(from,to)` 原子操作；数组顺序自动持久化（不触发 AI 重排）<br>**Step 5** — 详情浮层：Balatro 风 zoom-in（全屏遮罩→卡面 4x 居中→名+desc→稀有度边框→点击遮罩/ESC 关闭）<br>**Step 6** — SFX 接入：弹入 `SB.DEAL`；拖拽落位 `SB.SWAP`；移除 `SB.SEAL_FAIL`；浮层 `select.ogg`<br>涉及文件：`ninja_bar_display.gd`→`ninja_bar_node.gd`(新)、`ninja_slot.gd`(增强)、`ui_manager.gd`(引用更新) | P0 | ✅ |
| B11 | **BGM 3 段变奏完成** ✅ — DOVA-SYNDROME 3 首战忍BGM下载 → `game_bgm_light/medium/heavy.mp3` → `MusicManager.set_game_variation(barrier)` 根据结界 1-3(轻)/4-6(中)/7-8(重) 自动 crossfade → `_on_seal_started()` + 商店退出统一触发 | MusicManager + game_manager + sound_bank | P1 | ✅ |
| B14 | **满员忍者替换购买** — 槽位满(=5)时 Balatro 风替换交互：先扣钱→弹 NinjaReplaceOverlay（左新牌大图+右现存5卡副本+取消钮）→选旧牌→ShopManager.replace_ninja（半价退$）→Toast。`_replace_guard` 防重入 + overlay 全屏模态。详见 `docs/ninking/specs/ninja-replace-flow.md` | `shop_handler.gd` + 新建 `ninja_replace_overlay.gd/.tscn` + `shop_manager.gd` + `ui_manager.gd` | P1 | ✅ |

---

## 🎨 Phase 1-2 — 素材与视觉

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| V1 | 卡牌背面 (Card Back) | 140×196 像素风 PNG，程序绘制：`card_back_generator.gd` → `card_back.png`（手里剑十字星+交叉纹底+金色硬边框+内边框+角钻），已集成到 `ninking_card.gd` | **P0** | ✅ |
| V2 | 像素中文字体 | Press Start 2P (EN) + 凤凰点阵体 12px/16px (CJK) 三套已导入并配置回退链 | **P0** | ✅ |
| V3 | pixel_theme.tres | 全局 Theme 资源（字体/颜色/按钮样式） → **已由 V16 完成** | **P0** | ✅ |
| V4 | ~~按钮素材（普通/按下）~~ | 🗑️ 像素风旧计划，当前 manga_theme.tres StyleBoxFlat 三态方案已覆盖 | P1 | 🗑️ |
| V5 | **商店面板/顶部信息栏背景** | 已完成：Overlay + TitleBar + BottomBar + FocusLines + ScrollFrame + 动态 BarrierTheme 配色 | P1 | ✅ |
| V6 | 忍者牌槽位背景 | 100×140 像素风边框，`CardBackGenerator.generate_slot_bg()` 程序绘制：深蓝底+交叉纹+金边框+内凹区域+中央小手里剑+角钻+上下装饰线，已接入 `ability_slot.tscn` TextureRect | **P0** | ✅ |
| V7 | ~~CRT 扫描线效果接入~~ | ⛔ 已废弃 — 漫画风移除 CRT。见 V24 | P1 | ⛔ |
| V8 | **VFX 粒子纹理替换** ✅ — 豆包出图 2 张（`shuriken_particle.png`/`sakura_particle.png`）→ 替换 `particle_pool.gd` 程序绘制 8×8 占位，改用 `load()` 运行时加载。`manga_ink` 仍预载未触发、`speed_line` 死资产未清理 | `particle_pool.gd` | P2 | ✅ |
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
| V15 | **屏风转场增强** — logo 遮罩版 | ⚠️ 主路径(过关→商店)已无场景切换(Phase C)，仅重试/回菜单仍用 change_scene_to_file 硬切。可叠加 logo ColorRect 但效益有限 | P3 | ✅ |
| V22 | **商店 BGM** ✅ — 接线完成：`MusicManager.play_shop_bgm()` + `sound_bank.gd SHOP_BGM` + shop_ui 入场触发 + 离开时恢复 game BGM | 和风店 BGM `dova_Cooler...mp3` → MusicManager + shop_ui.gd + game_manager.gd | P1 | ✅ |
| V23 | **音效素材替换+新增** — Anime Game Pack(1,433 WAV) 自动匹配 20/20 需求 → ffmpeg WAV→OGG 转换 → 复制到项目。P0 核心(11)：deal/group_reveal/count_tick/xi_trigger/xi_fanfare/seal_clear/seal_fail/swap/discard/redraw_pop/ninja_activate。P1 关卡+UI(9)：boss_reveal/boss_final_layer/shop_enter/ui_coin/item_purchase/shop_reroll/shop_exit/ui_click/ui_error。旧 FanKing 占位已备份至 `legacy_placeholders/`，待 C8 SoundBank 更新后清理 | 详情见 `18-audio-asset-matching-guide.md`。旧文件仍保留在目录中待 sound_bank.gd 更新 | P0 | ✅ |
| V24 | **CRT 滤镜移除** — 删除 `crt_filter.gd` + `crt_filter.gdshader` + `GlobalTweens` CRT 引用 + `game_manager.gd` 6 处 CRT 调用 | 漫画风不需要扫描线。覆盖 V7/V18。详见 `16-art-direction-principles.md` §9 | **P0** | ✅ |
| V25 | **barrier_theme.gd 八属性亮色重写** — 8 結界冷暖交替暗色系 → 8 属性（火水風雷土光暗无）亮色版；新增 `particle_color` 字段；name 改为「壱·火」格式 | 覆盖 V17。详见 `16-art-direction-principles.md` §2 | **P0** | ✅ |
| V26 | **漫画粒子预设** — `ParticlePool` 新增 `manga_burst`(集中线) + `manga_ink`(墨迹) + `TweenFX.speed_line_trail()`(速度线) | 覆盖 V9 的像素粒子(shuriken/sakura)。详见 `16-art-direction-principles.md` §8。纹理已部署 `assets/images/effects/` | P1 | ✅ |
| V27 | **卡背漫画风重绘** — 豆包 AI 生成：漫画网点+粗黑描边+中心「忍」字 | 覆盖 V1 的像素卡背。详见 `16-art-direction-principles.md` §7.2。纹理已部署 `assets/images/cards/card_back.png` | P1 | ✅ |
| V36 | **人牌 J/Q/K 漫画插图** ✅ — 3 张 PNG 豆包出图（332×524, 透明背景）→ nanosvg 不支持 `<image>` 标签 → 改用 imagetracer 矢量路径追踪 → 12 个 SVGs 内嵌（~400-800KB/张）→ 额外清理：蓝色内框 `<rect>` + 中心叠层小花色 `<use height='52'>`。实际渲染通过。工具脚本 `tools/trace_face_portraits.js` | 规格书 `V36-face-card-prompts.md` | P2 | ✅ |
| V37 | **图像素材匹配 Phase 0-3 全线完成** 🎉 — Phase 0: 双包闸门+豆包样板验证 ✅ Phase 1: 16 张 Layer 1 匹配部署 ✅ Phase 2: 31 张 Layer 3 AI 生成→部署 ✅ Phase 3: 45 张后处理（pngquant+网点叠加+dilate检查）✅ | 累计交付 47 张到项目。现成包匹配 16 张 = 节省 34% AI 额度。详见 `19-image-asset-matching-guide.md` | P1 | ✅ |
| V28 | **UI 组件漫画风更新** — `06-ui-layout-reference.md` §6 重写（配色表→8属性亮色版、像素风原则→漫画风原则）；按钮/面板/三墩区分按新规范更新 | 覆盖 V16/V19/V20/V21。详见 `16-art-direction-principles.md` §3/§9 | **P0** | ✅ |
| V29 | **06-ui-layout-reference.md §2 场景树按实际代码重写** ✅ — HandTypeRow VBox/3行/Dun+Type+Score 修复、ScoringOverlay 注释修正、VictoryOverlay 无 % 标注、DeckViewer 展开+ViewerBg 补全。**追加：** ink-bleed 右侧渐隐 shader 挂载、ScoreCard content_margin_right=68 + layout_mode=2 (进度条止于渐隐起始)、MatchPanel/AntePanel 去圆角去边框加 content_margin_left=16、字体提升 (MatchTitle 20px / 内容 28px)、SpacerTop 删除实现 ScoreCard 顶对齐、左边 3 面板统一挂 panel_edge_fade.gdshader、三文档同步更新 | 对照 `ninking_main.tscn` 实际结构 | P1 | ✅ |
| V30 | **06-ui-layout-reference.md OVL_→实际节点名统一** ✅ — §1 前缀表加注"逻辑分类前缀，非实际节点名"，示例加 `OVL_Scoring → ScoringOverlay` 对照 | review-plan 审阅 A2 | P2 | ✅ |
| V31 | **06-ui-layout-reference.md §5 API 方法名/签名/信号名更新** ✅ — 全部方法加完整类型注解、补充 shop 信号、删除不存在的旧方法 swap_used/level_started/update_seal_info/show_upgrade_option/on_shop_exit、数据流图补全 signal 签名、§6/§7 同时恢复（被 linter 压缩）。对照 `ui_manager.gd` + `game_state.gd` 实际代码 | review-plan 审阅 A4/A5 | P1 | ✅ |
| V32 | **06-ui-layout-reference.md §4 补充 VICTORY 视图** ✅ — show_view() 映射表已有 victory 行 + 流程图有 VictoryOverlay 分支。V31 恢复时自动完成 | review-plan 审阅 A6 | P2 | ✅ |
| V33 | **06-ui-layout-reference.md §7 文件索引更新** ✅ — hand_display/hand_interaction 等已新增，main_menu.gd 已删除，barrier_theme 描述已更新。V31 恢复时自动完成 | review-plan 审阅 C2/C3 | P2 | ✅ |
| V34 | **VictoryOverlay 独立覆盖层** ✅ — 场景节点+视图切换+文字显示已有；补 celebration VFX（manga_burst + screen_shake + do_hit_stop + XI_FANFARE + Light BGM）共 5 行到 `game_manager.gd` VICTORY 分支 | review-plan 10-main-ui-design 审阅 Q1/A2 | P1 | ✅ |
| V35 | **GameOver 补充 ScoreSummary + MenuButton** ✅ — 场景节点已有（GameOverLabel/ScoreSummary/RetryButton/BackToMenuButton），`10-main-ui-design.md` §2 场景树展开 GameOver 子树 | review-plan 10-main-ui-design 审阅 Q2/A3 | P2 | ✅ |
| V38 | **商店入场临时粒子替代速度线** — 面板 slam 落地用 `GlobalTweens.burst_particles("shuriken")` 临时替代速度线拖尾，V26 `manga_speed` 预设到位后替换 | `nin_king_tween.gd` `play_shop_entrance()` | P1 | ✅ |
| V40 | **牌桌背景 `table_bg.png` 接入** — GameBg ColorRect → TextureRect, modulate 跟随 BarrierTheme | `ninking_main.tscn` + `ui_manager.gd` + `game_manager.gd` | **P1** | ✅ |
| V41 | **Boss 揭示立绘接入** — 9 Boss PNG → LevelIntro 场景加 BossPortrait TextureRect, seal_lord_name→portrait 映射, scale_pop 动画 | `ninking_main.tscn` + `ui_manager.gd` + `game_manager.gd` | **P1** | ✅ |
| V42 | **漫画粒子预设接入** — ParticlePool 新增 `manga_burst`(集中线) + `manga_ink`(墨迹) 预设, 预加载 AI 纹理 | `particle_pool.gd` | P2 | ✅ |
| V43 | **忍者图标接入** ✅ — 11 PNG 按 id 前缀分 11 类映射 + 忍槽显示图标 + 商店卡片图标替换 | `ninja_data.gd` + `ability_slot.tscn/.gd` + `ninja_bar_display.gd` + `shop_ability_card.tscn/.gd` | P1 | ✅ |
| V44 | **物品底板与图标接入** ✅ — 3 底板 + 4 图标按 id 前缀映射, ArtArea 加底板 TextureRect + 图标 Label→TextureRect | `consumable_data.gd` + `shop_item_card.tscn/.gd` | P1 | ✅ |
| V39 | **集中线 + 卷轴匾额全部就绪** ✅ 3 张 PNG 已部署 + 场景 6 个 TextureRect 全部接入（TitleFocusLines/AbilityFocusLines+ScrollFrame/ItemFocusLines+ScrollFrame/BottomFocusLines）。pngquant 下次 editor 环境执行 | 豆包 AI → `assets/images/ui/focus_lines_heavy.png` + `focus_lines_light.png` + `section_scroll_frame.png` | P0 | ✅ |
| V39.1 | ~~集中线纹理接入~~ | ✅ 已合并到 V39 | P0 | ✅ |
| V45 | **商店卡片图标差异化 — 按子类别细分** ✅ — 通用加成拆 3 子类(chips/mult/both)新 PNG + `get_icon_path()` 加 effect 参数做子类解析 + 稀有度4档视觉系统（边框色/宽/阴影/Badge）+ `apply_barrier_theme()` 稀有度边界保护 + 忍条同步子类图标。验证通过 | `ninja_data.gd` + `shop_ability_card.gd` + `ninja_bar_display.gd` + `assets/images/ninjas/icons/+3PNG` | **P0** | ✅ |
| V46 | **ArtIcon 归入 ArtArea 子节点** ✅ — ArtIcon(TextureRect) 从根 Panel 直子移入 ArtArea 子节点，锚定居中(Ability 80×80/Item 64×64)。`@onready` 路径改为 `$ArtArea/ArtIcon`，`_cache_nodes()`同步。2 tscn + 2 gd 改动，场景树/运行时验证通过 | `shop_ability_card.tscn` + `shop_item_card.tscn` + `shop_ability_card.gd` + `shop_item_card.gd` | P1 | ✅ |
| V47 | **商店稀有度视觉系统接入** ✅ — 已随 V45 一并实现：RarityBadge 4 档（common无/ uncommon无/ rare红"稀有"标签/ legend金"伝説"标签）+ 边框色/宽度/阴影跟随稀有度 | `shop_ability_card.gd` | P1 | ✅ |
| V48 | **素材注册表 AssetRegistry 统一管理** ✅ — 新建 `asset_registry.gd`(class_name AssetRegistry)，合并 `ninja_data.gd` 的 `CATEGORY_ICONS`+`get_icon_path()`+`_get_effect_subtype_suffix()` 和 `consumable_data.gd` 的 `ITEM_CATEGORY_MAP`+`get_item_icon_path()`+`get_item_base_path()` 到单一源。3 调用文件直接引用 `AssetRegistry.get_xx()`。旧文件保留 delegation stub。运行时验证通过 | 新建 `asset_registry.gd` + 3 调用文件 | P2 | ✅ |
| V49 | **物品 `icon_upgrade.png` 死资产清理** ✅ — 无任何物品类别使用升级图标，文件已删除（含 `.import`） | `assets/images/items/icons/` | P2 | ✅ |
| V50 | **卡牌框纹理叠层系统** ✅ — StyleBoxFlat → PNG 框纹理叠层；4 张框素材 1760×2464→500×700；`22-display-card-base-spec.md` 同步 | 6 文件 + 4 PNG | P2 | ✅ |
| V51 | **⚠️ 透明底框素材约束（永久提醒）** — 框纹理必须保持中心透明，插画透过透明区显示。任何新增/替换框素材时严格遵守：① 500×700 PNG ② 中心区域完全透明（alpha=0）③ 边框装饰仅限边缘（~80px 内边框以内）④ 避免框中任何不透明色块遮挡插画。当前 4 套（common/uncommon/rare/legendary）已符合。此条目永久保留，不用划掉。 | `assets/images/ninjas/frames/` + `22-display-card-base-spec.md §五` | P2 | ⚠️ |
| V52 | **Kenney 自定义光标接入** — 集成 `cursorSword_gold`（少年漫画方向）或 `cursorHand_beige`（治愈系方向）。新建 `cursor_manager.gd` + `main_menu.gd` `_ready()` 调用。约 30 分钟。详见下文 **📋 Kenney 素材执行计划** 方向决策后再实施。 | `scripts/ninking/ui/cursor_manager.gd`(新) + `main_menu.gd` | P3 | ✅ |

---

## 🎯 Kenney 素材执行计划（少年漫画方向·光标集成）

> **评估文档:** [`05-art/20-kenney-ui-pack-evaluation.md`](../05-art/20-kenney-ui-pack-evaluation.md) | **交互增强指南:** [`05-art/21-ui-interaction-enhancements.md`](../05-art/21-ui-interaction-enhancements.md)
> **重新审查:** 2026-06-22 | **2026-06-22 v2 修复:** `_ready`→`_enter_tree` 时序问题，Launch 界面光标生效
> **决策结果:** ✅ 少年漫画方向（仅光标），撤销原 K2/K3-K7 错误标记已完成
> **执行发现:** K2/V52 原标记 ✅ 但代码从未实现（无 `cursor_manager.gd`，无 `set_custom_mouse_cursor` 调用）。已重新规划为 KN1-KN4 实施

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| K1 | **美术方向决策** | 确定少年漫画方向，仅光标 | **P0** | ✅ |
| K2 | ~~光标集成~~ — 旧条目，从未实施 | 🔄 替换为 KN1-KN2 细化项 | P3 | 🔄 |
| KN1 | **光标本体集成** — `cursorSword_gold` 全局默认 + `cursorHand_blue` hover 光标 | 新建 `cursor_manager.gd` → `main_menu.gd` 初始化调用。已实施 | P3 | ✅ |
| KN2 | **全局 hover 光标反馈** — 按钮 hover 时自动切到 `cursorHand_blue` | **终版方案：** `cursor_manager.gd` 改为 **Autoload**，`_enter_tree()` 中注册金剑→ARROW + 蓝手→POINTING_HAND，并连接 `SceneTree.node_added` → 任何 Button 加入场景树时自动设 `mouse_default_cursor_shape = POINTING_HAND`。**零手动接入，全局生效。** `main_menu.gd` 已清空所有光标专用代码。<br>⚠️ **v2 修复:** 原用 `_ready()` 导致 Launch 界面不生效，改为 `_enter_tree()` 解决时序问题。| P3 | ✅ |
| KN3 | **(可选) Kenney 星级图标** — `star.png`/`star_outline.png` 稀有度装饰 | `card_visual_composer.gd` 增补 rarity star 装饰层 ~0.5h | P3 | ⬜ |
| KN4 | **(可选) Kenney divider 分割线** — 替换纯色 ColorRect | 装饰性，视觉提升有限 ~0.3h | P3 | ⬜ |
| K3-K7 | ~~治愈漫画方向~~ — 🗑️ 已废弃 | 当前少年漫画方向稳定，无需切换 | — | 🗑️ |

---

## 🎨 Phase KUI — Kenney 暖纸风 UI 改造（方案B）

> **方案文档:** [`09-mgmt/specs/kenney-beige-ui-transformation.md`](specs/kenney-beige-ui-transformation.md)
> **审阅:** 2026-06-22 review-plan 通过（A1/B3/D1 修正）
> **决策:** ✅ 面板+按钮改用 Kenney beige/brown 纹理，保留 BarrierTheme accent 文字色

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| KUI1 | **面板改造（6处）** — LeftPanel×4 / SettlementCard / DeckViewer 的 StyleBoxFlat → StyleBoxTexture 用 `panel_beige`/`panel_beigeLight`。Patch margins=8px。保留 `panel_edge_fade` shader | `ninking_main.tscn` + `settlement_card.tscn` + `barrier_theme.gd` PanelBg 色值调整 | **P1** | ✅ |
| KUI2 | **GameOver/Victory 面板卡片化** — 新增 NinePatchRect 暖米面板，文字/按钮移入面板内。pop_in 入场（`GlobalTweens.pop_in()`） | `ninking_main.tscn` + `ui_manager.gd` | P2 | ⬜ |
| KUI3 | **主菜单按钮换皮** — 4 主菜单按钮 + Debug 按钮改用 `buttonLong_beige`/`buttonSquare_grey` + pressed 纹理。深褐字 #3D2B1A。不删 theme 样式（用 override 覆盖） | `main_menu.gd` | **P1** | ✅ |
| KUI4 | **游戏内操作按钮换皮** — `barrier_theme.gd` 新增 `apply_kenney_button_style()` + `apply_kenney_square_style()`，PlayBtn/AiRearrangeBtn/DeckBtn/重试/回菜单按钮改用 `buttonLong_brown`/`buttonSquare_brown` 纹理，白字 + pressed 时显示 accent 色 | `barrier_theme.gd` + `game_manager.gd` | **P1** | ✅ |
| KUI5 | **商店按钮换皮** — 购买 `buttonRound_beige`（pressed 用 modulate_color 调暗），刷新 `buttonLong_brown`，继续 `buttonLong_beige` | `shop_ui.gd` + `shop_slot.gd` | P2 | ✅ |
| KUI6 | **Debug 场景同步** — `debug_ninking_main.tscn` 同步面板/按钮改造（**DebugPanel 及其子面板除外**） | `debug_ninking_main.tscn` | P2 | ✅ |
| KUI7 | **文档同步** — `21-ui-interaction-enhancements.md` + `DOCUMENT_MAP.md` 更新 | 2 文档 | P2 | ✅ |

**旧 Kenney 任务：** KN3(星级图标) / KN4(分割线) 取消，KN1/KN2(光标) 已完成不在此阶段。

---

## 🖥️ UI 交互优化 — 待定项

> **2026-06-22 评估后新增** — 4 个可选方向，优先级待定，实施前需确认方向。

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| U1 | **设置面板** — 设置按钮 `_on_settings_pressed` 当前为 `pass`，补全为弹出面板：BGM音量 + SFX音量 → ConfigManager 持久化。半透明遮罩 + 面板 pop_in 动画 | `main_menu.gd` + 新建 settings_panel.tscn/·gd | ? | ⬜ |
| U2 | **卡牌拖拽手感增强** — 拖起时卡牌升起+阴影，合法落点发光高亮，非法落点淡红提示，松手弹回动画 | card-framework 相关文件 + `ninking_card.gd` | ? | ⬜ |
| U3 | **GameOver/Victory 画面卡片化** — 当前为纯 Label + Button，改为带背景卡牌样式的面板 + pop_in 入场动效 | `ui_manager.gd` + `ninking_main.tscn` + 相关 gd | ? | ⬜ |
| U4 | **结算金币 count-up 视觉加强** — 每 $5 金色粒子 burst + 递增音高 tick + 落定微震 + 小额回退音效 | `settlement_card.gd` only | ? | ✅ |

## ⚡ Shader 优化 — 内部重构（Phase J/K 已完成外部集成，此为内部清理）

> **方案审阅: 2026-06-23** | 基于现实 shader 体系分析
> **核心:** P0 Fake3D 抽 `.gdshaderinc` 去重 + .tres 精简 + 内存/性能优化 + 清理残留文件
> **已取消:** P6全息shader（与fake3d冲突）⛔ | P5 FoilFX（暂缓，性价比低）🔒

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| S1 | **P0: Fake3D 系列抽 `.gdshaderinc`** — `fake3d.gdshader`/`fake3d_flash.gdshader`/`fake3d_shadow.gdshader` 三者的 `vertex()` 完全一致(旋转矩阵+透视变换+绿幕去除各70+行)。新建 `shaders/fake3d/fake3d_core.gdshaderinc` 抽提公共 vertex()，三文件 `#include` 继承。修改任一改全部 | `shaders/fake3d/` 4 文件 | **P1** | ✅ |
| S2 | **P1(路径A): 精简稀有度 .tres — 参数合并到 RARITY_FLASH_PARAMS** — 当前 4× .tres(fake3d_common/uncommon/rare/legendary) 与 `RARITY_FLASH_PARAMS` 参数重复且不一致。保留 .tres 中 gradient_texture/flash_type/pure_flash_color 等编辑器可视化字段，其余数值参数(angle/stripe_spacing/speed 等)移入扩展后的 `RARITY_FLASH_PARAMS`。代码在 `duplicate()` 后批量设参。`delete_tolerance` 统一为 0.0 | `asset_registry.gd` + 4× .tres + `ninja_inventory_card.gd` + `card_visual_composer.gd` | **P2** | ✅ |
| S3 | **P2: 全局共享背面 ShaderMaterial** — NinKingCard 的 `_apply_fake3d_material()` 每张牌正面独享材质、反面 `y_rot=0` 可全局共享。加 `static var _back_fake3d_mat: ShaderMaterial` + `static _get_back_fake3d_mat()`，所有卡牌复用同一实例 | `scripts/ninking/ui/ninking_card.gd` | **P2** | ✅ |
| S4 | **P4: Outline LOD 性能** — `outline2D_inner_outer.gdshader` 每像素采 8 邻居。加 `uniform bool high_quality`，低质量模式采 4 对角线方向(4次 texture())。牌组预览 52 张卡从 416→208 次 texture()/帧 | `shaders/outline2D_inner_outer.gdshader` + `outline_fx.gd` | **P3** | ✅ |
| S5 | **P3: GlowFX 扩展 emissive 模式** — `baked_sprite_glow.gdshader` 追加 `uniform bool emissive_mode`，加法发光替代混合发光。覆盖 `sources/blink.gdshader` 功能，不单独引入 | `shaders/baked_sprite_glow.gdshader` + `glow_fx.gd` | **P3** | ✅ |
| S6 | **P8: NinKingCard 材质状态缓存** — `set_visual_state()` 每次 duplicate 材质。加 `_material_cache: Dictionary` 按 VisualState 缓存正反面材质，O(n) → O(1)。`_apply_flash_material()` 也走缓存 | `scripts/ninking/ui/ninking_card.gd` | **P2** | ✅ |
| S7 | **P7: SOURCES 清理 + 残留清理** — ① `card_glow.gdshader.uid` ✅ 删除 ② `shaders/shaderlib/2d_holographic_card_shader.gdshader` + `.uid` ✅ 删除 ③ `sources/SOURCES.md` ✅ 更新状态列，增加已删除清单 | 4+ 文件 | **P2** | ✅ |
| S8 | **shaderlist 优化 Phase 0: 清理 `shaders/shaderlib/` 3 个未用 shader** — 删除 balatro_card_hover / balatro_foil / card_shadow_pseudo_3d（均被项目现有系统覆盖）。同时删除 `sources/` 中已标记✅的 robust_shine + blink（对应 shader）。 | `shaders/shaderlib/*.gdshader` ×3 + `shaders/sources/*.gdshader` ×2 | **P1** | ✅ |
| S9 | **shaderlist 优化 Phase 0: 清理后建 `shaders/reference/INDEX.md`** — 从 shaderlist 项目精选子集索引，按 card_border/card_entry/card_shine/attack_vfx/atmosphere 分类。文档参考，不引入实际 shader。 | `shaders/reference/INDEX.md`(新) | **P4** | ⬜ |
| **S10** | **🔥 shaderlist 优化 Phase 1: HaloFX 子系统 — 边框光晕环** — `halo_01.gdshader`(94行) 移植到 `shaders/effects/halo.gdshader`。**改造要点：** ① 关掉 shader 内 TIME 驱动旋转/脉冲，改为 uniform 暴露，由外部 `GlobalTweens.shader_pulse/tween_shader_param` 控制节奏 ② 颜色取项目稀有度色板（银/青/红橙/蓝紫），不直接使用 shaderlist 默认粉/紫配色 ③ `color_mix_range` 取值 0.2-0.3 保持主色调稳定。新建 `halo_fx.gd`(class_name HaloFX) 遵循 EdgeFadeFX 模式(apply/cleanup/has_halo)。`GlobalShaders` 注册 `apply_halo/clear_halo/has_halo`。用于传说/罕见卡动态边框、选中悬停高亮、结界属性边框。 | `shaders/effects/halo.gdshader` ✅ + `scripts/shader/halo_fx.gd` ✅ + `scripts/shader/global_shaders.gd` ✅ | **P1** | ✅ |
| S11 | **shaderlist 优化 Phase 2: LightningFX 子系统** — `thunder_box.gdshader` 移植。**约束：** ① 雷电范围限制在忍者牌自身 UV（不扩散全屏）② 颜色用结界属性 accent 色而非纯黄 ③ 闪烁频率降为原版 1/3。新建 `lightning_fx.gd`。 | `shaders/effects/lightning.gdshader`(新) + `scripts/shader/lightning_fx.gd`(新) | **P3** | ⬜ |
| S12 | **shaderlist 优化 Phase 2: rainbow foil flash_type=3** — `rainbow.gdshader` 分段调色板算法移植到 `fake3d_flash.gdshader` 新增 `flash_type=3`，保留现有 type=1(sin 彩虹)。作为第 5 隐藏稀有度"彩虹箔"。 | `shaders/fake3d/fake3d_flash.gdshader` | **P3** | ⬜ |
| S13 | **shaderlist 优化 Phase 2: ExplodeFX 子系统** — `pixel_explosion.gdshader` 移植，新建独立 `explode_fx.gd`（不扩展 DissolveFX，两者原理不同）。 | `shaders/effects/pixel_explosion.gdshader`(新) + `scripts/shader/explode_fx.gd`(新) | **P3** | ⬜ |
| S14 | **shaderlist 优化 Phase 2: 内阴影/边缘光（降质版）** — `inner_shadow_rimlight.gdshader` 缩减到 4 方向×3 质量=12 采样(原 72 采样 1/6)后引入，用于卡牌深度增强。 | `shaders/effects/inner_shadow_rimlight.gdshader`(新) | **P3** | ⬜ |
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
| C8 | **SoundBank 忍者主题重命名 + 全部音效接线完成** — 常量重命名(HU→GROUP_REVEAL 等) + 新增 8 常量 + 保留旧 alias + 接线到 game_manager/shop_ui/hand_interaction/redraw_vfx_handler 共 17 处 play_sfx | `scripts/config/sound_bank.gd` + 4 接线文件 | P1 | ✅ |
| C10 | **漫画风字体替换** — F1 思源黑体 SC Heavy（粗体）+ F2 SC Regular（正文）+ F3 Yusei Magic（手写/P2）。Phase 1 ✅：字体下载、import 配置（抗锯齿/fallback）、manga_theme.tres 新建、3 tscn 引用切换、旧字体→legacy/、游戏测试通过。 | `pixel_theme.tres` → `manga_theme.tres` / `17-font-design-plan.md` | P1 | ✅ |
| C11 | **术语统一：能力牌→忍者牌** ✅ — ability_slot.tscn→ninja_slot.tscn + ability_slot.gd→ninja_slot.gd；`ABILITY_SLOT_SCENE`→`NINJA_SLOT_SCENE`；`%AbilityBar`→`%NinjaBar`；变量 `ability_bar`→`ninja_bar_container`。影响 tscn×2 + gd×4 + docs×2 | review-plan 审阅 Q2 / C4 | P2 | ✅ |
| C12 | **ScoreCard 节点加 `unique_name_in_owner`** ✅ — tscn 加 unique_name flag；ui_manager.gd 加 `@onready var score_card: Panel = %ScoreCard`；game_manager.gd get_node 调用改为 `ui.score_card` | 审阅 C1。当前 ScoreCard 有 unique_id 但未勾选 unique_name flag | P2 | ✅ |
| C13 | **game_manager.gd `const CountUp = preload(...)` 保留** — CountUp 非死代码，用于 Phase E 金币结算动画（`_play_gold_settlement`，`game_manager.gd:291`） | `scripts/ninking/ui/game_manager.gd:10` | P2 | ✅ |
| C14 | **BounceScore 峰值音效** — 已传入 `COUNT_TICK` 作为 `bounce_sfx`（C8 接线完成）。如需更重量的"咚"感，后续可替换专用素材 | `game_manager.gd:274` — `SB.COUNT_TICK` 传入 | P2 | ✅ |
| C15 | **shop_ability_card.gd `setup()` 存 `_card_style` 成员变量** — `apply_barrier_theme()` 直接改 `_card_style.bg_color` 等属性，避免重建 StyleBox 覆盖问题 | `shop_ability_card.gd` + `shop_item_card.gd` | **P0** | ✅ |
| C16 | **SoundBank 新增商店音效常量** — `SHOP_ENTER` / `SHOP_EXIT` / `ITEM_PURCHASE` / `SHOP_REROLL` 接入 `sound_bank.gd` + 接线到 shop_ui.gd | `scripts/config/sound_bank.gd` + `shop_ui.gd` | P1 | ✅ |
| C17 | **发牌音效 `DEAL` 接入** — `game_manager.gd` PLAYING 状态入场时 `play_sfx(SB.DEAL)` | `assets/audio/sound/game/deal.ogg` | P2 | ✅ |
| C18 | **忍者能力激活音效 `NINJA_ACTIVATE` 接入** — `game_manager.gd` 计分 Phase 2 前，有忍者牌时 `play_sfx(SB.NINJA_ACTIVATE)` | `assets/audio/sound/game/ninja_activate.ogg` | P2 | ✅ |
| C19 | **最终 Boss 层音效 `BOSS_FINAL_LAYER` 接入** — `game_manager.gd` `_on_seal_started` barrier≥8 时用 `SB.BOSS_FINAL_LAYER` | `assets/audio/sound/game/boss_final_layer.ogg` | P2 | ✅ |
| C20 | **卡牌选择音效 `SELECT` 接入** — `sound_bank.gd` 真常量 + `hand_interaction.gd` 选中分支 `play_sfx(SB.SELECT)` | `assets/audio/sound/game/select.ogg` | P2 | ✅ |
| C21 | **game_manager.gd 拆分** ✅ — 599→275 行（-54%），提取 `shop_handler.gd` (115行) + `animation_handler.gd` (238行)。game_manager 保留状态回调 + 按钮 + BOSS 揭示，商店逻辑委托 ShopHandler，计分动画委托 AnimationHandler。通过 callable 注入 `_auto_shop_pending` 避免循环依赖 | `scripts/ninking/ui/game_manager.gd` | P2 | ✅ |
| C22 | **shop_ui.gd 行数优化** ✅ — `_apply_impact_button_style()` (40行)提取到 `BarrierTheme.apply_impact_button_style()` 静态方法。shop_ui.gd 366→326行。barrier_theme.gd 100→141行 | `scripts/ninking/ui/shop_ui.gd` + `barrier_theme.gd` | P2 | ✅ |
| C23 | **商店自动过渡 — Balatro 风免确认流程** — `_auto_shop_pending` 标记 + SEAL_COMPLETE 1.2s 自动 timer + VICTORY 清除 + game_bg complete 可见。Code Review 修复 A1: flag 移到 finalize_play 之前（信号同步发射时序） | `scripts/ninking/ui/game_manager.gd` + `ui_manager.gd` | P1 | ✅ |
| C24 | **商店忍者槽位数不准** ✅ — `shop_ui.gd` 改为由 `init()`/`update_gold()` 通过 `owned_ninja_count` 参数传入实际拥有数，`_update_ninja_slot_label()` 使用 `_owned_ninja_count` + `_max_ninja_slots`。同步更新 `ui_manager.gd` 两处调用传参。运行时验证: 购买前"忍者 0/5"→购买后"忍者 1/5" ✅ | `shop_ui.gd` + `ui_manager.gd` | P2 | ✅ |
| C25 | **文档同步：NinjaBar 描述更新** ✅ — `06-ui-layout-reference.md` §3.3.3.a + §5 + §7；`10-main-ui-design.md` 场景树；`11-ninja-cards.md` 文件引用 | `docs/ninking/06-ui-layout-reference.md` + `10-main-ui-design.md` + `11-ninja-cards.md` | P1 | ✅ |
| C26 | **梳理 ninja_data.gd 卡牌文字描述** — 确保 desc 字段适合横排 Slot（~180px 宽，14px 字，2 行内）。精简 20+ 字长描述，统一用语 | `scripts/ninking/ninja_data.gd` | P1 | ✅ |
| C27 | **CardVisualComposer 卡片视觉合成抽象层** — 新增 `card_visual_composer.gd`(class_name CardVisualComposer, RefCounted 静态工具类)。L1 原子工具: create_rarity_stylebox/create_frame_overlay/compose_art_texture/compose_art_draw/apply_hover_glow。L2 便捷组合: build_card_face。改造三处消费者: DisplayCardBase(删~60行)/NinjaInventoryCard(删~35行)/CardDetailPopup(删~40行)。双渲染路径(TextureRect保留Fake3D + _draw)。 | `card_visual_composer.gd`(新) + `display_card_base.gd` + `ninja_inventory_card.gd` + `card_detail_popup.gd` + `22-display-card-base-spec.md` | P1 | ✅ |
| C28 | **文档同步: 22-display-card-base-spec.md 更新为 CardVisualComposer 委托模式** | `docs/ninking/22-display-card-base-spec.md` | P1 | ✅ |
| C29 | **统一忍者卡场景 ninja_card.tscn** — 新建场景替代 DisplayCardBase+NinjaInventoryCard 双实现。NinjaInventoryCard 加 `_shop_mode` 标志和 setup_shop/set_content_texture/apply_barrier_theme/set_frame/set_detail_data 方法。ShopSlot 改实例化 ninja_card.tscn。忍者栏改为场景实例化。删 display_card_base.gd/.tscn。文档同步 6 文件。 | `ninja_card.tscn`(新) + `ninja_inventory_card.gd` + `shop_slot.tscn` + `shop_slot.gd` + `ninja_bar_node.gd` + `ninja_bar_display.gd` + docs×6 | P1 | ✅ |
| C30 | **创建 `score_helpers.gd` — 消除重复辅助函数** — 提取 `score_calculator.gd` 和 `auto_arranger.gd` 中 3 组完全相同函数：`group_card_chips`(加 `include_seal` 参数区分封印×2)、`group_ench_chips`、`group_ench_mult`。两文件保留原私有函数作为公共函数包装(向后兼容)。 | `scripts/ninking/score_helpers.gd`(新) + `score_calculator.gd` + `auto_arranger.gd` | **P0** | ✅ |
| C31 | **`ScoreResult` 类从 `score_calculator.gd` 内嵌类→独立 `score_result.gd`** — `class_name ScoreResult extends RefCounted`，更新 3-5 个引用文件。 | `scripts/ninking/score_result.gd`(新) + 引用文件 | P1 | ✅ |
| C32 | **`Arrangement` 类从 `auto_arranger.gd` 内嵌类→独立 `arrangement.gd`** — `class_name Arrangement extends RefCounted`，更新 `game_state.gd`/`game_manager.gd`/`debug_controller.gd` 等引用。 | `scripts/ninking/arrangement.gd`(新) + 引用文件 | P1 | ✅ |
| C33 | **`CardVisualComposer` 新增 `create_tooltip_stylebox(color)`** — 替换 `hand_type_labeler.gd`(Lv tooltip) 和 `debug_controller.gd`(Star tooltip) 中重复的 StyleBoxFlat 构建代码(~20行)。 | `scripts/ninking/ui/card_visual_composer.gd` + `hand_type_labeler.gd` + `debug_controller.gd` | P1 | ✅ |
| C34 | **`ContinuePanel` 场景化** — `main_menu.gd` 中 `_build_continue_panel()`(57行) 提取为 `res://scenes/ninking/continue_panel.tscn`，通过 `.instantiate()` + `show_panel(data)` 接口替换。 | `res://scenes/ninking/continue_panel.tscn`(新) + `main_menu.gd` + `scripts/ninking/ui/continue_panel.gd`(新) | P2 | ✅ |
| C35 | **`CardDetailPopup` 场景化** — `_build()` 中 10+ 程序化节点创建提取为 `res://scenes/ninking/card_detail_popup.tscn`，`open()` 使用场景实例化。覆盖层/名称/描述节点预置在场景中。 | `res://scenes/ninking/card_detail_popup.tscn`(新) + `card_detail_popup.gd` | P2 | ✅ |
| C36 | **CR1 — `gold_before_settlement` fallback 用已结算金币倒推旧值** — `SEAL_COMPLETE` 分支 line 111 的 fallback 计算在 `_complete_seal` 之后执行，`gold_reward` 已入账，倒推公式得到错误旧值。修复：`_on_play_pressed` 中 capture `NinKingGameState.gold` 到 `animation_handler.current_play_data["gold_before_settlement"]`，删 fallback | `game_manager.gd:110-113` + `game_manager.gd:208` | **P0** | ✅ |
| C37 | **CR2 — `calculate()` 路径对每行双调 `compute_group_score` + `row_score`** — `calculate()` 中 line 149-152 先调 `compute_group_score()` 存局部变量，line 151-152 再调 `row_score()` 覆写 `result.head_score`。若两路径内部未来分化，total 与 breakdown 会不一致。修复：对齐 `calculate_with_summary()`，只调 `row_score()`，从 result 取值 | `score_calculator.gd:148-173` | **P0** | ✅ |
| C38 | **CR4 — `calculate()` 与 `calculate_with_summary()` 核心逻辑 80% 重复** — 行评分/列评分/全局 xi/group xi/双头蛇/total 计算在两方法中重复。提取 `_compute_total_after_xi()` 私有方法共用 | `score_calculator.gd` | P1 | ✅ |
| C39 | **CR5 — `NinjaPool.get_random_ninjas` 返回原始 dict 引用** — `result.append(pool[i])` 返回 `NinjaData.ALL_NINJAS` 中的原始引用，调用方误改会污染源数据。修复：`result.append(pool[i].duplicate(true))` | `ninja_pool.gd:43-44` | P1 | ✅ |
| C40 | **CR6 — `BarrierConfig` SEAL_LORD_POOL 注释写"铁链"但池中无此条目** — `barrier_config.gd:102` 注释 `2-3: 参ノ結界 (独柱/铁链)` 但池中第 3 条实际为反目。修正注释为实际条目名 | `barrier_config.gd:102` | P2 | ✅ |
| C41 | **CR3 — `_complete_seal` 利息上限 guard `== 0` 语义模糊** — `seal_controller.gd:240` 用 `extra_interest == 0` 判断是否回退遍历忍者，summary 真正返回 0 时也会误进（虽结果一致但语义不清）。改为 `not summary.has("interest_cap_bonus")` | `seal_controller.gd:240` | P2 | ✅ |
| C42 | **CR7 — `animation_handler` null tween guard** — `GlobalTweens.play_score()` 可能返回 null，`await score_tw.finished` 被跳过但 `punch_in` 照常执行导致重叠。加 `if score_tw == null: continue` 守卫 | `animation_handler.gd:175-180` | P2 | ✅ |
| C43 | **CR8 — 杂项清理** — C13 TODO 更正（CountUp 非死代码）+ `ui_manager.gd` 4行连续空行→1行 + `score_effect_collector.gd:99` 魔法数字 `2/10`→`CardData.Rank.TWO/TEN` | `TODO.md` + `ui_manager.gd:184-187` + `score_effect_collector.gd:99` | P2 | ✅ |
| C44 | **CR9 — 四张喜显示×1 实际计分×5 不一致** — `xi_detector.gd:84` `add_xi("四张", 1, 50)` 写入 mult_x_stack=1（显示用），但 ScoreXiHandler 从 XI_DEFINITIONS 读 x_mult=5（计分用）。debug_controller + hand_type_labeler 显示 ×1，实际 ×5。A14 未更新调用点 | `xi_detector.gd:84` | **P0** | ✅ |
| C45 | **CR10 — `_detect_cross_group_flags` tail_only_x3 嵌套 bug** — `score_calculator.gd:607-608` tail_only_x3 检测被错误嵌套在 duplicate_hand_x2 条件内。若忍者只有 tail_only_x3 没有 duplicate_hand_x2，calculate() 路径无法检测。analyze_effects() 路径（line 276）无此问题 | `score_calculator.gd:607-608` | **P1** | ✅ |
| C46 | **CR11 — `shop_manager.buy_item()` 缺 `.duplicate(true)`** — `buy_ninja()` line 47 正确深拷贝，`buy_item()` line 76 直接存原始引用。若源数组后续被修改，已存储物品受影响 | `shop_manager.gd:76` | P2 | ✅ |
| C47 | **CR12 — `XiResult.chips_add` 全项目死字段** — line 47 写入但全项目无消费者读取。计分管道从 XI_DEFINITIONS 读值，忽略 XiResult 中的 chips/mult_x_stack。移除 add_xi() 的 chips 参数及 chips_add 字段 | `xi_detector.gd:36-49` | P2 | ✅ |
| C48 | **CR13 — `consumable_data.gd` 注释数量不符** — "12 total (was 16)" 实际 FUJUTSU_CARDS 含 15 张（4花色+2点数+8增强+1销毁=15） | `consumable_data.gd:8` | P2 | ✅ |
| C49 | **CR14 — Boss 立绘运行时重复 `load()`** — `ui_manager.on_seal_start()` 每次封印调用 load(BOSS_PORTRAITS[name])，9 个纹理应预加载缓存 | `ui_manager.gd:347-348` | P2 | ✅ |
| C50 | **CR15 — 双版本辅助函数缺交叉引用注释** — ScoreHelpers 含 edition+seal，ScoreGroupComputer 不含。需在 ScoreHelpers 头部加注释说明差异，防新人选错 | `score_helpers.gd` + `score_group_computer.gd` | P2 | ✅ |
| C51 | **CR16 — `ninja_scaling.x_growth` 类型 `int` 与 F1.3 spec `+0.25` float 冲突** — 当前无忍者触发此路径（x_mult_growth 未被使用），但类型错误会导致未来 ×mult 成长卡牌精度丢失 | `ninja_scaling.gd:42` | P2 | ✅ |
| D9 | **设计文档同步 计分公式重构 (3 文件)** ✅ — 06-complete-redesign §3 重写(公式+列+喜整数表)；13-blinds-and-bosses 散牌王列描述更新；03-technical-design 类图 ScoreResult/AutoArranger/XiResult 更新 | `docs/ninking/06-complete-redesign.md` + `13-blinds-and-bosses.md` + `03-technical-design.md` | **P0** | ✅ |
| D10 | **计分公式 v5.0 列加法化** ✅ — 列从 ×mult栈(×2~×32768) 改为 chips×mult 加法项和行平级。score_calculator.gd 重写(新增 _collect_ninja_for_column + _compute_group_score 复用)；animation_handler/debug_controller/hand_type_labeler 列显示更新；13-blinds 封印值全量重标(200~550k)；06-redesign §3 公式重写；03-technical-design/README 同步。Grill 16 轮 + review-plan 审阅通过 | `score_calculator.gd` + `animation_handler.gd` + `debug_controller.gd` + `hand_type_labeler.gd` + `card_data.gd` + 3 文档 | **P0** | ✅ |
| C52 | **清理死代码 `shop_handler.on_sell_requested` + `ShopManager.sell_ninja`** — 两处均为 B14 替换系统遗留，全项目零调用方 | `shop_handler.gd` + `shop_manager.gd` | P1 | ✅ |
| C53 | **文档同步: `07-shop-ui-design.md` 删除 §5.3 替换流程** — 更新 §5.2 购买描述为满员→Toast+脉冲 | `docs/ninking/04-ui/07-shop-ui-design.md` | **P0** | ✅ |
| C54 | **文档同步: `DOCUMENT_MAP.md` 删除 §5.13** — 移除 `ninja_replace_overlay.gd` 映射条目 | `docs/ninking/DOCUMENT_MAP.md` | **P0** | ✅ |
| C55 | **按钮注意力脉冲抽象 `attract_pulse()` + `kill_domain()`** — TweenFX 新增 modulate 呼吸脉冲基建 + GlobalTweens 委托。替换 settlement_card 手写 `_start_button_pulse()`；接入 game_manager 讨伐按钮 + shop_slot 购买按钮。文档同步 | `tween_fx.gd` + `global_tweens.gd` + `settlement_card.gd` + `game_manager.gd` + `shop_slot.gd` + `tween-library-reference.md` | P1 | ✅ |
| C56 | **attract_pulse 修复 + 扩展** — (1) 修复 Compatibility 渲染器下不可见问题：默认 `scale_pulse=true`、modulate 夹紧 ≤1.0； (2) 接入 Launcher StartBtn + DeckSelect ConfirmBtn 两按钮，含入场延时启动 + 点击/返回时 kill_domain | `tween_fx.gd` + `main_menu.gd` + `deck_select_panel.gd` | P1 | ✅ |

---

## 🎯 Phase E — 结算流程沉浸化 (2026-06-12 Grill 决策 ✅)

### ✅ E11: 模拟审查 v5.2 — 阈值整体下调 30% (2026-06-18)

> **背景:** 实测 B1-修羅 15K 过难，审查发现 4 项模拟器疏漏。

| # | 任务 | 说明 | 状态 |
|---|------|------|:----:|
| E11a | **散牌 chips 修正** — `sim_engine.py`/`calc_engine.py`/`gen_test_v3.py` H_CHIPS[0]: 5→0 | 3 文件 | ✅ |
| E11b | **阈值整体下调 30%** — 24 封印 target ×0.7 向 5 取整 | `barrier_config.gd` + `sim_config.py` + 2 docs | ✅ |
| E11c | **排列评分偏差记录** — 模拟器用总分、游戏用行分，差异已记入 §10 | 待修复 | ✅ |
| E11d | **交叉验证管道重建** — 三方对齐（sim_engine + calc_engine + ScoreCalculator）| 待办 | ✅ |
| E11e | **重跑模拟更新通过率** — `sim_runner.py 30` + `sim_runner_personality.py --all --runs 10` | 待办 | ✅ |
| E11f | **文档同步** — `21-simulation-methodology.md` §10 审查发现 + `13-blinds-and-bosses.md` 阈值表 | ✅ |
| E11g | **阈值调整建议框架更新** — 方法论 §9 新增 30% 下调适配 | ✅ |

> **Grill 8 轮决策 + review-plan 审阅通过。** 移除独立 LevelComplete。结算卡片「封印解除」：计分结束 → 弹出战果卡（封印名/分数/金币 count-up）→ 玩家点击按钮进商店。

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| E1 | **animation_handler.gd: 捕获金币旧值** | Phase 4 胜利分支 `finalize_play()` 前将 `gs.gold` 存入 `current_play_data["gold_before_settlement"]` | **P0** | ✅ |
| E2 | ~~**`_play_gold_settlement()` 方法**~~ | ⛔ 已废弃 — 被 E12 结算卡片取代 | **P0** | 🗑️ |
| E3 | ~~**skip-on-click 机制**~~ | ⛔ 已废弃 — 改为「封印解除」按钮 | **P0** | 🗑️ |
| E4 | ~~**auto-shop 时序调整**~~ | ⛔ 已废弃 — 不再自动进商店 | **P0** | 🗑️ |
| E5 | **game_manager.gd: SEAL_COMPLETE 分支重写** | 去掉 `show_view("complete")` + `set_level_complete()`，改为结算卡片 | **P0** | ✅ |
| E6 | **ui_manager.gd: 清理 LevelComplete 引用** | 移除 `@onready var level_complete/complete_label/reward_label/to_shop_button` + `set_level_complete()` 包装方法 | P1 | ✅ |
| E7 | **result_screen_display.gd: 清理 `set_level_complete()`** | 移除方法（或保留空壳防引用断裂） | P1 | ✅ |
| E8 | **ninking_main.tscn: 移除 LevelComplete 子树** | 删除节点树 + 4 个 `unique_name_in_owner` | P1 | ✅ |
| E9 | **game_manager.gd: 移除 `to_shop_button` 连线** | 删除 `ui.to_shop_button.pressed.connect(shop_handler.go_shop_pressed)` | P1 | ✅ |
| E10 | **文档同步 (旧)** | `06-ui-layout-reference.md` / `03-technical-design.md` | P1 | ✅ |
| **E12** | **结算卡片「封印解除」** | 独立结算环节：卡片弹出 → 战果展示 → 金币 count-up → 按钮进商店。详见 [`specs/settlement-card-design.md`](specs/settlement-card-design.md) | **P0** | ✅ |

---

## 🃏 Phase F1 — 忍者牌基础补齐 (15新卡 + 3降级)

> **方案文档:** `23-ninja-card-expansion-plan.md`
> **目标:** 普通 9→20, 稀有度倒挂修复, 衰减/×mult成长空白填补
> **新增卡牌:** 11 普通 + 3 衰减 + 2 ×mult成长 = 16 张新卡定义

### F1.0 — 稀有度降级 (3 张)

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| F1.0a | **铁索连环 (n_c02) 史诗→稀有** ✅ | commit 69912fa 已完成: cost 8→6, rarity "rare"→"uncommon" | **P0** | ✅ |
| F1.0b | **王牌侍从 (n_f02) 史诗→稀有** ✅ | commit 69912fa 已完成: cost 8→5, rarity "rare"→"uncommon" | **P0** | ✅ |
| F1.0c | **清一色 (n_x03) 史诗→稀有** ✅ | commit 69912fa 已完成: cost 7→5, rarity "rare"→"uncommon" | **P0** | ✅ |

### F1.1 — 普通卡扩池 (11 张)

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| F1.1a | **通用加成 3 张** — n_007(修行短刀/顺子+30chips) + n_008(影足轻/偶数+3mult) + n_009(火遁·初/首手+10mult) | ninja_data.gd 新增定义 + AssetRegistry 图标 | **P0** | ✅ |
| F1.1b | **组别定向 3 张** — n_g07(断影/影对子+40chips) + n_g08(流瞬/瞬同花+8mult) + n_g09(滅火/滅三条+12mult) | 条件检测: hand_type 精确匹配(已有逻辑, 纯数据) | **P0** | ✅ |
| F1.1c | **人牌/点数 3 张** — n_f03(鬼面/滅组人头+5mult/张) + n_f04(奇数手里剑/奇数+20chips) + n_f05(影之加护/手牌7→+7mult) | 新条件类型: `rank_odd`, `mult_per_hand_rank` | **P0** | ✅ |
| F1.1d | **经济 2 张** — n_e07(猫忍/$2回合) + n_e08(弃财/弃人头$1/张) | 新 effect: `gold_per_turn`, `gold_per_discarded_face` | **P0** | ✅ |

### F1.2 — 衰减型卡牌 (3 张)

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| F1.2a | **DecayTracker 实现** | 新文件 `scripts/ninking/decay_tracker.gd`(class_name DecayTracker): 追踪衰减卡牌的当前 chips/mult/x_mult 值, on_play/on_seal_start 扣减, 归零检测, 信号 `decayed_to_zero(ninja_id)` | **P0** | ✅ |
| F1.2b | **score_calculator.gd 衰减对接** | `collect_ninja_per_group()` 对衰减卡读 DecayTracker 当前值而非 effect 定义值 | **P0** | ✅ |
| F1.2c | **衰减卡定义 3 张** — n_d03(雷遁之术/+40mult-8/手) + n_d04(冰封之印/×2-×0.5/封印) + n_d05(燃烧查克拉/+100chips+20mult-双衰减) | ninja_data.gd 新增, effect 含 `decay_per_play`/`x_decay_per_seal`/`destroy_on_zero` | **P0** | ✅ |
| F1.2d | **归零自毁 + VFX** | decayed_to_zero 信号接线: ShopManager 移除卡牌 + manga_burst 粒子 + 空槽动画 | P1 | ✅ |

### F1.3 — 成长型 ×mult (2 张)

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| F1.3a | **NinjaScaling 扩展 ×mult 成长** | 新增 `x_growth`/`x_cap` 字段支持, `on_ritual_use`/`on_boss_clear` 新 trigger, float 累积→int `round()` 输出 | **P0** | ✅ |
| F1.3b | **score_calculator.gd ×mult 成长接入** | `collect_ninja_per_group()` 从 NinjaScaling 读当前 ×mult 值, 追加到 x_stack | **P0** | ✅ |
| F1.3c | **×mult 成长卡定义 2 张** — n_s07(星见/秘仪→+0.25上限×4) + n_s08(试炼之印/Boss→+0.5上限×3) | ninja_data.gd 新增, scaling 含 `x_growth`/`x_cap` | **P0** | ✅ |
| F1.3d | **秘仪/Boss trigger 接线** | shop_handler 秘仪使用 → NinjaScaling.on_ritual_use; game_manager Boss 过关 → NinjaScaling.on_boss_clear | P1 | ✅ |

### F1.4 — 收尾

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| F1.4a | **AssetRegistry 新卡图标注册** | 16 张新卡按 id 前缀分类, 无专属 PNG 则 fallback 到类别默认图标 | P1 | ✅ |
| F1.4b | **文档同步** | `11-ninja-cards.md` 更新总卡牌数/稀有度分布/新维度说明 | P1 | ✅ |
| F1.4c | **商店刷新池验证** | 确认 NinjaPool 按新稀有度权重出卡, 普通卡出现率显著提升 | P1 | ✅ |

---

## 🧪 Phase T — 计分交叉验证管道

> **Python↔GDScript 端到端公式验证，确保两套计分引擎输出一致。**

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| T1 | **Phase 1: 管道搭建** | calc_engine.py (Python 计分引擎) + gen_test_v2.py (156 测试定义) + diff.py (字段级对比) | **P0** | ✅ |
| T2 | **Phase 2: P0 交叉验证** | test_runner.gd 调 ScoreCalculator.calculate() 输出 actual.json。基准 156 全过 → 4 轮修复（xi_bonus/组代码翻译/x_stack 多值/xi_override）→ 312/312 零差异 | **P0** | ✅ |
| T3 | **Phase 3: Seal Lord 测试** | 4 对（skip_head / scatter_king / hungry_ghost / tail_x2），Python 定义 + Godot 验证 | **P1** | ✅ |
| T4 | **Phase 4: 多忍者测试** | 24 对（4 层 stack × 6 组合 + 2 经济），叠加顺序+取舍验证 | **P1** | ✅ |
| T5 | **Phase 5: 集成** | review_test_data.py 同时处理 CSV + JSON，统一回归入口 | P2 | ✅ |
| T6 | **龙之眼重设计 — 测试数据清理+重建** | 旧逻辑 `x_mult_per_extra_card` 的 T1-T6 测试全部失效，需清理所有测试文件(CSV/JSON)中的龙之眼用例并重建新效果验证用例 | **P1** | ✅ |

---

## 🎬 Phase G — 计分忍法动效（三幕式动画）

> **Grill 12 轮 + review-plan 审阅通过, 2026-06-15**
> **核心设计：** 在计分时注入 Balatro 风格的忍者触发动画，每行二段式（基础值→忍者依次触发→乘积结果），三幕结构（行→列→喜×）。
> 决策树详见 memory `scoring-ninja-trigger-animation-2026-06-15.md`

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| G1 | **AnimationHandler: Phase 1 重写为二段式计分 + 忍者触发注入** | 当前 Phase 1 使用 `play_score("C×M=R")` 顺序滚动。需改为：第一阶段显示 "筹码 X \| 倍率 Y" → 忍者依次触发（卡片动画+数字跳动）→ 第二阶段 "C × M = R" 乘积脉冲。每行内部时序精确控制，无忍者行直接跳第二阶段。Q1 确认：每行符合条件的忍者都播动画 | **P0** | ✅ |
| G2 | **AnimationHandler: 跳过机制实现** | 加 `_skip_requested: bool`，每个动画段落后检查。计分开始时创建全屏 Control 监听点击/按键→设 flag。每段动画前加极短 `await` 让引擎处理 input 队列。跳过时所有数字直接设终值，0.2s 后直接 `finalize_play`。Q3 确认：跳过不播忍者动画 | **P0** | ✅ |
| G3 | **AnimationHandler: Phase 2 列加分对齐 Phase 1 二段式 + 忍者触发** | 列加分也走同样节奏：列牌型高亮 → 基础筹码/倍率出现 → 列条件忍者依次触发（卡片动画+数字跳动）→ 乘积。Q2 确认：列阶段重新播放忍者动画（即使行阶段已播过） | **P1** | ✅ |
| G4 | **AnimationHandler: 行间过渡 + 行高亮** | 行结束→下一行开始：当前行名标签（影/瞬/滅）0.3s 闪烁脉冲过渡。当前行手牌区3张牌发光高亮。均使用已有 `GlobalTweens.color_flash()` | **P1** | ✅ |
| G5 | **TweenFX: 新增 `ninja_pop_trigger()` 组合动画** | 忍者触发组合：scale 1.0→1.2 + offset_y -10px (0.15s EASE_OUT QUAD) → 停顿 0.2s → scale 1.2→0.95→1.0 (0.25s EASE_OUT BACK)。返回 Tween 可 await。通用性好（将来可用于商店购买/升级触发） | **P1** | ✅ |
| G6 | **GlobalTweens: 新增入口委托** | 委托调 TweenFX `ninja_pop_trigger()`，同步绑定 `NINJA_ACTIVATE` 音效 + 粒子触发 | **P1** | ✅ |
| G7 | **同步更新 tween-library-reference.md** | 新增函数文档：`TweenFX.ninja_pop_trigger()` + `GlobalTweens.ninja_trigger()` | **P2** | ✅ |
| G8 | **调试快捷键：Phase 1/2/3 快速跳转** | 调试时按 1/2/3 跳到对应幕，方便后续迭代调试 | **P2** | ✅ |

---

## 📐 Phase H — 忍者牌效果集中分析（消除冗余遍历）

> **方案审阅通过, 2026-06-16** | **Spec:** [`specs/ninja-effect-consolidation.md`](specs/ninja-effect-consolidation.md)
> **核心:** 7 次冗余遍历 → 1 次集中分析。在 `ScoreCalculator` 加 `analyze_effects()` 单次遍历方法，聚合忍者效果供所有消费者复用。保留旧 `calculate()` 签名向后兼容。

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| H1 | **`ScoreCalculator.analyze_effects()` 单次遍历** — 返回 Dictionary 汇总所有忍者效果（per_group/col/anim_contribs/gold/tools/scaling/constraint）| `scripts/ninking/score_calculator.gd` + `calculate_with_summary()` + `_row_score()`/`_apply_group_xi()` 提取 | **P0** | ✅ |
| H2 | **SealController 消费 summary** — `prepare_play()` 调用一次 `analyze_effects()`，`_collect_play_gold()` 改用 summary.gold_on_play | `scripts/ninking/seal_controller.gd` | **P1** | ✅ |
| H3 | **AnimationHandler 消费 summary** — 删除 `_compute_ninja_contributions()`（~70 行），改用 `summary.anim_contribs` | `scripts/ninking/ui/animation_handler.gd` | **P1** | ✅ |
| H4 | **ArrangeController 消费 summary** — `_compute_per_group_ninja_effects()` 改用 `summary.per_group` | `scripts/ninking/arrange_controller.gd` | **P2** | ✅ |
| H5 | **工具效果可见性** — `analyze_effects()` 中收集 extra_plays 等悬空效果到 `summary.tools`（extra_redraws 已随换牌系统移除；death_save 已随土遁改造删除） | `scripts/ninking/score_calculator.gd` | **P2** | ✅ |
| H6 | **Phase 2 预研文档** — 最终效果 pipeline（5 阶段）+ `NinjaCardInstance` 运行时类设计文档 | 文档 | **P2** | ✅ |

---

## 📐 Phase I — score_calculator.gd 性能评估与拆分重构可行性

> **1056 行，静态类，双路径（旧 `calculate()`/新 `calculate_with_summary()+analyze_effects()`）。**
> **前置依赖：** Phase H（`analyze_effects()` 全量接入各消费者）完成后进行，确保调用路径已经稳定。

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| I1 | **性能基准测试** — 测量 `calculate()` vs `calculate_with_summary()` 在 0/5/10/15 忍者数下的单次执行耗时（GDScript `Time.get_ticks_usec()` 插桩），找出瓶颈函数（`_collect_ninja_for_column` 嵌套循环、`analyze_effects` 遍历等）。关注 3×3 网格算满的极端情况 | `scripts/ninking/score_calculator.gd` | P2 | ✅ |
| I2 | **重复逻辑消除评估** — 量化 `calculate()` 与 `calculate_with_summary()` 间的代码重复度（预估 40-60% 重叠）。评估弃用旧路径的可行性（哪些调用方仍用旧 `calculate()`，能否全部迁移到 summary 路径）。识别 `_compute_group_score()` 与 `_row_score()` 的合并空间 | 全项目 grep `ScoreCalculator.calculate\b` + 手动比对 | P2 | ✅ |
| I3 | **领域拆分方案** — 评估按关注点拆分为多个小文件的可行性：① **`ninja_row_collector.gd`** — `collect_ninja_per_group()` + `ninja_affected_groups()` + `_collect_ninja_for_column()` 等忍者效果分配逻辑（~250 行）② **`xi_applicator.gd`** — `_get_global_xi_x_stack()` + `_apply_group_xi()` + `_apply_group_xi_to_group()`（~70 行）③ **`economy_effects.gd`** — `_apply_economy_effects()`（~30 行）④ **`score_calculator.gd`** 保留主入口 + `_compute_group_score()` + `_row_score()`（~400 行）。评估跨文件静态方法 vs 注入式 vs 单一职责 RefCounted 类的架构取舍 | 设计方案文档 | P2 | ✅ |
| I4 | **Phase H 全量接入后并行去旧** — H3(H4) 消费 summary 完成后，将剩余 `calculate()` 调用方改为 `analyze_effects()+calculate_with_summary()`，删除旧路径（或标记 `@deprecated`）。净消除重复逻辑，单次忍者遍历 | 全项目调用点分析 | P2 | ✅ |
| I5 | **NinjaCardInstance 运行时类设计** — Phase H spec 中 H6 的延续。将 `Dictionary` summary 升级为强类型 `NinjaCardInstance` 类（含 effect/condition/scaling/decay/current_values 字段），代替散装 Dictionary。减少运行时 `effect.get("add_chips", 0)` 式字符串键访问，提升类型安全 + 可读性 | `scripts/ninking/ninja_card_instance.gd`(新) | P3 | ✅ |

---

## 🎨 Phase J — 外部 Shader 资源集成

> **方案审阅通过, 2026-06-17** | **Spec:** [`specs/shader-external-integration.md`](specs/shader-external-integration.md)
> **核心:** 利用 ShaderLib 下载资源和 ShaderV 函数库，增强卡牌箔片闪光 + 溶解动画 + VFX 工具集。不涉及 GlobalShaders 框架改动。
> **前置:** Phase G（计分动效）+ F1（忍者补齐）完成后插空进行

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| J1 | **箔片闪光增强 — fake3d_flash 新增 flash_type=3** | 将 `balatro_foil_card_effect` 的有机液态箔片算法移植入 fake3d_flash.gdshader。新增 `group_uniforms foil_uniforms`（9 uniform + 4 sampler2D）。注意 TIME 统一基准、alpha 裁剪隔离、GL Compatibility uniform 数验证。fake3d_legendary.tres 设 `flash_type=3` | `shaders/fake3d/fake3d_flash.gdshader` + `resources/materials/fake3d_legendary.tres` | **P2** | ✅ |
| J2 | **溶解动画增强 — dissolve2d 加 noise_scroll_speed** | dissolve2d.gdshader 加 `uniform float noise_scroll_speed`（默认 0），fragment() 噪声纹理采样 UV 加 TIME 驱动偏移动画。DissolveFX.apply() 透传参数。GlobalShaders.dissolve_out() 默认传 {noise_scroll_speed: 0.5} 启用动态火焰飘动感。无需程序化噪声嵌入。| `shaders/fake3d/dissolve2d.gdshader` + `scripts/shader/dissolve_fx.gd` | **P2** | ✅ |
| J3 | **`#include` 路径验证** | Phase 2 前置：创建最小验证 shader `shaders/test_include.gdshader`，确认 `#include "res://addons/shaderV/tools/remap.gdshaderinc"` 在 canvas_item + GL Compatibility 下编译通过。通过后删除验证文件 | `shaders/test_include.gdshader`（临时） | **P2** | ✅ |
| J4 | **色差 VFX 工具集**（G/F1 后） | 从 ShaderV 复制 chromaticAberration 到 `shaders/utils/`（剥离 textureLod 分支）。新建 `shaders/effects/boss_reveal.gdshader`，用 `#include` 引入色差，用于 Boss 揭示入场效果。通过 `GlobalShaders.create_material_from_path()` 直接加载 | `shaders/utils/chromatic_aberration.gdshaderinc`(新) + `shaders/effects/boss_reveal.gdshader`(新) | **P3** | ✅ |
| J5 | **文档同步** | shader-library-reference.md §3.1 加 `shaders/utils/` + `shaders/effects/` 目录；§5.1 工作流加 `#include` 路径验证步骤；§5.3 外部库手册补充 ShaderLib/ShaderV 更新使用说明；`shaders/shaderlib/` 未使用文件加注释 `// @status: NOT_INTEGRATED` | `docs/shader-library-reference.md` | **P2** | ✅ |

## 🎬 Phase K — 外部 Shader 库引入整合

> **方案审阅通过, 2026-06-18** | **来源:** `shaders/sources/SOURCES.md` — 已预存的原始 .gdshader 文件
> **前置:** F1（忍者牌补齐）完成后插空执行。K0 子项可提前到 F1 同期做
> **核心原则：**
> - **优先扩展已有 shader，不重复造轮子** — `fake3d_flash` 补 3 uniform 即覆盖 robust_shine，不建 ShineFX
> - **有状态的交互效果才建子系统** — 纯参数效果走 `FilterFX` 统一管线
> - **遵守 VFX 框架** — 零项目依赖、自初始化、参数可覆盖、信号通知外部
> - **漫画风方向约束** — 风格化 shader（CRT/old_movie/sketch/water_color）暂不引入

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| **K0** | **复用扩展（零新文件/最小改动，可提前到 F1 同期）** |
| K0a | **`fake3d_flash.gdshader` 增强 — 补循环方向+软边** | 加 3 uniform: `one_way_loop`(单向循环)、`loop_direction`(正反向)、`softness`(闪光软边)。效果覆盖 `shaders/sources/robust_shine.gdshader` 全部能力。修改 1 个 `.gdshader` 文件。**不新建 ShineFX 子系统，不引入新 shader** | **P2** | ✅ |
| K0b | **`GlowFX` 扩展 — 新增 `emissive_add` 闪烁模式** | `shaders/sources/blink.gdshader` 本质是 sin(TIME) 驱动的 RGB 加法辉光。在 GlowFX 新增 `emissive_add` 模式参数（纯加法叠加而非 glow 纹理）。调用方 `GlobalShaders.apply_glow(node, {mode: "emissive_add", blink_frequency: 2.0})`。效果覆盖 `shaders/sources/blink.gdshader`。不新建 BlinkFX | **P2** | ✅ |
| K0c | **`RippleFX` 新建** | 唯一真正需要新子系统的效果。波纹点击反馈 — 按钮按下/出牌区域选中。新建 `scripts/shader/ripple_fx.gd`(class_name RippleFX) + 复制 `shaders/sources/ripple.gdshader` → `shaders/effects/ripple.gdshader`。支持中心扰动/距离衰减/密度控制。`GlobalShaders` 注册 `apply_ripple()`/`clear_ripple()` | **P2** | ✅ |
| **K1** | **子系统新增（F1 完成后执行）** |
| K1a | **`FilterFX` 新建 — 统一滤镜管线** | 1 shader 多模式设计：`shaders/filters/multi_filter.gdshader` 内含 `uniform int mode` 切换（0=灰度 1=暗角 2=颜色叠加 3=选色）。新建 `scripts/shader/filter_fx.gd`(class_name FilterFX)。覆盖 `grayscale`/`vignette`/`color_overlay`/`selective_color` 四种滤镜（源文件在 `shaders/sources/`）。`GlobalShaders` 注册 `apply_grayscale()`/`apply_vignette()`/`apply_overlay()`/`clear_filter()` | **P2** | ✅ |
| K1b | **Sprite 级色差效果注册** | Chromatic aberration 作为 Sprite 级别效果（非全屏）。复制 `shaders/sources/chromatic_aberration.gdshader` → `shaders/effects/chromatic_aberration.gdshader`。通过 `GlobalShaders.create_material_from_path()` 加载 + `tween_param()` 驱动强度。不需要新建子系统。全屏色差暂缓（当前漫画风不需要） | **P3** | ✅ |
| **K2** | **场景补全（按需排期）** |
| K2a | **`GlitchFX` 新建 — 分裂故障特效** | 复制 `shaders/sources/split_glitch.gdshader` → `shaders/effects/split_glitch.gdshader`。新建 `scripts/shader/glitch_fx.gd`(class_name GlitchFX)。用于 Boss 登场/转场过渡。网格量化+动态扰动纹理 | **P3** | ✅ |
| K2b | **`ExplosionFX` 新建 — 像素爆炸消散** | 复制 `shaders/sources/pixel_explosion.gdshader` → `shaders/effects/pixel_explosion.gdshader`。新建 `scripts/shader/explosion_fx.gd`(class_name ExplosionFX)。用于忍者"遁"术/卡牌销毁 | **P3** | ✅ |
| K2c | **环境氛围 shader 引入** | 按需从 `shaders/sources/` 复制 `liquid_distortion.gdshader`(水遁 Boss)/`wave.gdshader`(风遁)/`rainy_surface.gdshader`(雨战)。不走子系统，通过 `GlobalShaders.create_material_from_path()` 直接加载 | **P3** | ✅ |
| K2d | **风格化/限定 shader（需漫画风确认）** | `rainbow`(限定卡牌)/`halo_01`(选中光环)/`jelly_wobble`(果冻反馈)。需先确认不与漫画风方向冲突 | **P3** | ✅ |

---

## 🔒 Phase D-E — 远期（暂缓）

| # | 任务 | 说明 | 状态 |
|---|------|------|------|
| D1 | 牌组系统（暗夜/赤阳/混沌/龙脉） | 4 种特殊牌组 + 解锁条件 | 🔒 |
| D2 | 封印系统重新设计 | 原设计在比鸡 9 张全出下 OP | 🔒 |
| D3 | Tag 系统 | 投资/星图/忍者/优惠/稀有 Tag | 🔒 |
| D4 | 卡包系统 | 附魔包/星图包/封印包/秘仪包 | 🔒 |
| D5 | ~~n_x04 黑龙 / n_x05 赤凤~~ | 与喜系统冲突，已删除 | ⛔ |
| D6 | 商店 BGM | → 已提升至 V22 (P1) | ✅ |
| D7 | 数值平衡调优 | 完整验证难度曲线 + 价格平衡 | 🔒 |
| D8 | 音频替换为扑克风格 | → 已拆分为 V23(素材) + B11(BGM变奏) + C8(重命名)，详见 `15-sound-design-plan.md` | ✅ |
| D10 | **Debug 计分测试场景** ✅ | Grill 20 轮 + review-plan 审阅通过。独立于主场景，零侵入。Launch 右下角 Debug 按钮进入。底栏 52 牌四排 ♠♣♥♦ 点选放入 9 格。右手面板忍者多选+星図等级+1。「討伐」调用 ScoreCalculator 刷新 LeftPanel。文件: `debug_ninking_main.tscn` / `debug_controller.gd` / `debug_card_tray.gd` / `debug_ninja_selector.gd` + `ninking_launcher.tscn` 改一行。修复排查：`ninja_bar_node.gd` 语法错误、`card_factory_scene` 导出缺失 | **P1** | ✅ |
| D11 | **DisplayCardBase + ShopSlot Balatro 风重构** ✅ | 新建 DisplayCardBase 125×175 纯卡面。删 shop_ability_card/shop_item_card (2 tscn + 2 gd)。ShopSlot 数据驱动容器。稀有度=边框+辉光无浮标。规格书见 `22-display-card-base-spec.md` | **P1** | ✅ |

---

## 🗺️ 实施路线图速查

```
Phase A ──→ Phase B ──→ Phase C ──→ Phase E ──→ Phase F1
 核心可玩    系统完善    Boss深度    发布就绪    忍者牌补齐

Phase F1 ──→ Phase F2 ──→ Phase F3 ──→ Phase H ──→ Phase I
 基础补齐     机制扩展     深度打磨     效果集中     运行时Pipeline
 (15新+3降)   (12售出/重触发/Boss/牌组)  (10喜/三组/资源)   (消除7×遍历)  (NinjaCardInstance + 5阶段)

 A1-A8 完成 = 可玩原型
 B4-B8 完成 = 完整体验
 C(Phase C) = 沉浸流程
 F1 = 70 张卡池 + 衰减/×mult 成长
 F2 = 10 维度全覆盖
 F3 = 差异化打磨
 H1 = 消除 6/7 冗余遍历
 H6 = Phase 2 设计就绪
 I1 = 运行时类 + 5 阶段 Pipeline
 J1-J2 = 箔片闪光加强 + 溶解动态
 J4 = 色差 VFX 工具集
 K0 = 复用扩展: fake3d_flash 增强 + GlowFX 闪烁模式
 K1 = RippleFX 波纹反馈 + FilterFX 统一滤镜 + Sprite 色差
 K2 = GlitchFX 故障 / ExplosionFX 消散 / 场景氛围 shader
```

---

## 📝 Phase L — 游戏回放日志系统 (Game Replay Logger)

> **Grill 9 轮设计决策, 2026-06-18**
> **核心：** 记录每次 run 的操作序列到 `user://logs/` 供 Bug 复现。HTML 可视化回放。
>
> **文件：** `scripts/ninking/logging/game_logger.gd`（静态类，无 autoload/class_name，通过 preload 引用）
> **查看器：** `docs/ninking/ninja-game-replay.html`（拖拽 JSON 日志 → 可视化回放）
> **接入面：** `game_state.gd` / `seal_controller.gd` / `shop_manager.gd` — 13 种事件全覆盖

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| L1 | **GameRunLogger 核心类** — 13 种事件记录 + JSON 序列化 + 全量/增量快照 + 文件管理 | `scripts/ninking/logging/game_logger.gd` | **P2** | ✅ |
| L2 | **game_state.gd 插桩** — run_started/seal_started/cards_dealt/auto_arranged/game_over/victory | 6 处调用 | **P2** | ✅ |
| L3 | **seal_controller.gd 插桩** — play_prepared/play_executed/card_swapped/seal_completed/shop_entered | 5 处调用 | **P2** | ✅ |
| L4 | **shop_manager.gd 插桩** — ninja_acquired/item_purchased | 2 处调用 | **P2** | ✅ |
| L5 | **HTML 回放查看器** — 拖拽加载/时间线/卡牌渲染/计分展示/键盘导航 | `docs/ninking/ninja-game-replay.html` | **P2** | ✅ |
| L6 | **Debug 场景接入** — 7 处插桩（发牌/随机/AI排列/討伐/拖拽交换），与主场景共用日志格式 | `debug_controller.gd` | **P2** | ✅ |
| L7 | **手动运行验证** — 主场景 + Debug 场景各记录一局并回放确认 | 由用户操作确认 | **P2** | ✅ |

---

## 📋 变更记录

| 日期 | 变更 |
|------|------|
| 2026-06-22 | 🖱️ **Kenney 光标集成完成** — `cursor_manager.gd` 新建，`main_menu.gd` 初始化 + 按钮 `mouse_default_cursor_shape=POINTING_HAND`。默认金剑+悬停蓝手，经实测验证通过。KN3/KN4 保留可选待办。 |
| 2026-06-22 | 🖱️ **Kenney 评估重新审查 — KN1-KN4 入 TODO** — K2/V52 原标记 ✅ 但代码从未实现（无 `cursor_manager.gd`）。重新审查后拆分为 KN1(光标管理器)+KN2(hover 反馈)+KN3(星级图标)+KN4(分割线)。旧 K2/K3-K7 更新为正确状态。 |
| 2026-06-22 | 🔒 **B5 附魔卡降级暂缓** — 附魔卡选牌弹窗 (enchant_target_selector) 优先级 P2→P3，状态 🔵→🔒。当前聚焦核心玩法与稳定性，附魔交互靠后处理。 |
| 2026-06-22 | ✋ **光标扩展 Card 覆盖** — `_on_node_added` 新增 `or node is Card`，手牌/忍栏/商店卡牌悬停变蓝手。同步更新 `21-ui-interaction-enhancements.md` 和记忆文件。 |
| 2026-06-22 | 🏗️ **Kenney 暖纸风 UI 改造方案 B 审阅通过** — spec `kenney-beige-ui-transformation.md` 经历 review-plan 四维审阅，A1(patch_margin 16→8px)/B3(buttonRound pressed)/D1(theme 只加不删) 已修正。KUI1-KUI7 入 TODO。KN3/KN4 废弃。 |
| 2026-06-22 | 🏗️ **KUI3/KUI4 按钮换皮完成** — KUI3: main_menu.gd `_apply_kenney_button_style_to_all()` 为 4 主菜单按钮应用 buttonLong_beige + 深褐字，DebugBtn 用 buttonSquare_grey。KUI4: barrier_theme.gd 新增 `apply_kenney_button_style()`(buttonLong_brown) + `apply_kenney_square_style()`(buttonSquare_brown)；game_manager.gd `_on_seal_started()` 为 PlayBtn/AiRearrangeBtn/DeckBtn/Retry/Menu 6 按钮应用 Kenney 暖棕纹理 |
| 2026-06-22 | 🏗️ **KUI5 商店按钮换皮完成** — shop_ui.gd 继续按钮用 buttonLong_beige + 深褐字，刷新按钮用 buttonLong_brown + 白字。shop_slot.gd 购买按钮用 buttonRound_beige + 深褐字，pressed 态用 modulate_color(0.85) 替代缺失的 _pressed 纹理 |
| 2026-06-22 | 🏗️ **KUI6/KUI7 Debug 场景同步 + 文档同步完成** — KUI6: debug_ninking_main.tscn 面板(StyleBoxFlat→StyleBoxTexture) + 按钮(buttonLong_brown)同步改造，DebugPanel 及其子面板除外。KUI7: 21-ui-interaction-enhancements.md 新增§3 暖纸风面板/按钮改造记录 + DOCUMENT_MAP.md §5.16 新增 Kenney 改造条目 |
| 2026-06-22 | 📋 **新增 U1-U4 UI 交互优化待定项** — 设置面板/拖拽手感/GameOver 卡片化/金币 count-up 加强。优先级待定，需确认方向后再实施。 |
| 2026-06-22 | 🏗️ **左边栏喜信息重构 — ColXiLabel 移出 VBox 改为 Label**：去掉 `×N` 仅保留喜名；改用 `Label` + `fit_content`+`autowrap_mode` 自动换行；脱离 `ScoreVBox` 绝对定位 + `offset_top` 负值向上扩展（最多 4 行）；不推下方 ScoreLabel/ProgressBar。同步 debug 场景 + UI layout 文档。影响文件：`hand_type_labeler.gd`/`ui_manager.gd`/`hand_display.gd`/`debug_controller.gd`/`ninking_main.tscn`/`ninking_debug.tscn`/`06-ui-layout-reference.md` |
| 2026-06-21 | 🐛 **ShopOverlay mouse_filter=IGNORE 修复商店遮挡忍者栏交互**: `ninking_main.tscn` ShopOverlay `mouse_filter` 从 STOP→PASS→IGNORE。根因: Godot 4 `gui_find_control()` 按 z_index 降序找顶层 Control 分发事件，ShopOverlay(z_index=1100, 全屏) 始终为事件入口，PASS 也不穿透到 GameLayout(z_index=0)。IGNORE 排除该节点后 GameLayout 成为忍者栏区域顶层，ShopPanel 为 ShopOverlay 子节点仍独立接收事件。deck_viewer_controller.gd `_on_deck_btn_pressed` 加 state guard 防止商店时误开牌库。文档 06-ui-layout-reference.md / 03-technical-design.md 同步更新。 |
| 2026-06-15 | 🀄 **CardVisualComposer 卡片视觉合成抽象层**: 新增 `card_visual_composer.gd`(class_name CardVisualComposer, RefCounted 静态工具类)。L1 原子工具: create_rarity_stylebox/create_frame_overlay/compose_art_texture/compose_art_draw/apply_hover_glow。L2: build_card_face。三处消费者改造: DisplayCardBase(删~60行) / NinjaInventoryCard(删~35行) / CardDetailPopup(删~40行)。双渲染路径(TextureRect 保留 Fake3D + _draw)。C27/C28 加入 TODO。
| 2026-06-15 | 🐛 **忍者计分动画条件过滤修复 (B15/B16)**: `animation_handler.gd` 加 `has_condition` 判断，区分 `[]` 的"无条件→所有组"和"条件不匹配→跳过"语义；`score_calculator.gd` 加 `"head_or_mid"` 组识别分支。双头蛇 n_g05 计分和动画同时修正。文档 `24-scoring-ninja-animation.md` §7.2 同步更新 condition.group 表格 |
| 2026-06-15 | 🎴 **Fake3D VFX Phase 4 完成 — dissolve 场景接入**: `ninja_inventory_card.gd` 新增 `_dissolve_mat` 加载 + `dissolve_out()` 方法(swap 材质→GlobalTweens.dissolve_out)。`ninja_bar_node.gd` `_animate_out()` 新增 `use_dissolve` 参数分支。`refresh()` 新增 `use_dissolve` 贯穿参数。`ui_manager.gd` `refresh_ninjas()` 新增 `use_dissolve` 透传。`shop_handler.gd` 新增 `on_sell_requested()` 方法(含 dissolve 退场)。NinjaBarNode `remove_ninja()` 实现为 dissolve 式移除 + GameState 同步。|
| 2026-06-14 | 🧪 **Phase 2 交叉验证完成**: Python↔GDScript 312/312 全匹配。4 轮修复 — test_runner 传 xi_bonus+xi_override + 组代码翻译(h/m/t→head/mid/tail) + x_stack 多值支持 + score_calculator xi_override 参数。Phase 3-5 排入后续。 |
| 2026-06-14 | 🃏 **忍者牌扩展方案 Phase F1 启动**: 新增 `23-ninja-card-expansion-plan.md`。F1 目标 43→58 张。16 项任务入 TODO。README 文档索引更新。 |
| 2026-06-12 | 🐛 **LeftPanel v2.1 修复 — 列积分接续 + 行分数初始空置**: `game_manager.gd` 新增 col_evals 计算(Phase 2 列动画数据源)；animation_handler 删除开篇 "0×0" 重置块，改为每行动画起始动态设 "0×0" 再渐入终值；6 个 score label `text="0×0"` 从场景文件+debug_controller 移除，统一为空字符串初始态。|
| 2026-06-12 | ♠️ **Balatro 风大重构 — DisplayCardBase 纯卡面 + ShopSlot 容器**: DisplayCardBase 缩至 125×175 纯卡面(删 info_overlay/name_label)。删 shop_ability_card/shop_item_card(4 文件)。新建 ShopSlot 数据驱动容器(ability/item 统一场景)。稀有度=边框色+辉光无浮标。文档 03/06/07/11/22 同步更新。|
| 2026-06-12 | 🏪 **商店底部舞台化 v6 — 漫画「下一格」转型**: Grill→review-plan 审阅通过。shop_panel.tscn 全底 1500×700, x:420 起, StageBg 纸色+网点+属性染色三层替代纯色 Overlay, 4px 直角漫画格分割线, AbilityGrid 4列, ItemColumn 2列居中。shop_ui.gd `_apply_barrier_theme()` 重写。nin_king_tween.gd 新增 `play_shop_entrance_manga()` (墨线画出→背景刷出→卡片 stagger_pop_in), `play_shop_exit()` 更新。tween_fx.gd + global_tweens.gd 新增 `stagger_pop_in()`。ui_manager.gd hide_shop overlay 删除。screentone.png 代码生成。16-art-direction-principles.md §3.1 加漫画格例外。07-shop-ui-design.md v6 全篇同步。|
| 2026-06-12 | 🃏 **D11 DisplayCardBase 非扑克牌统一展示卡实现**: Grill 16 轮设计确认 → 新建 `DisplayCardBase` (extends Card)，统一外框/阴影/结界染色/content_slot/name_plate/入场动效/悬停光效(scale 1.03)/右键详情。ShopAbilityCard/ShopItemCard 重写为子类。删 CardButton。规格书 `22-display-card-base-spec.md`。 |: D10 ✅。新文件: `debug_ninking_main.tscn` / `debug_controller.gd` / `debug_card_tray.gd` / `debug_ninja_selector.gd`。改文件: `ninking_launcher.tscn` + `main_menu.gd`(右下角按钮)。修复: `ninja_bar_node.gd` line203 语法错误(t#→#)、CardManager `card_factory_scene` 导出缺失。运行验证：Launch→Debug 按钮→全场景加载通过。 |
| 2026-06-12 | 🏪 **Phase D 商店布局重设 — 左右分栏极简化**: Grill 12 轮确认 → 左 6:4 右 / 2x2 忍者 Grid + 2 道具 VBox / 固定 4+2 / 顶底栏 60px 对称 / 去所有装饰 / 遮罩 45% / 弱化主题。shop_panel.tscn 重写 / shop_ui.gd 重写 / shop_manager.gd 固定库存+assert / ui_manager.gd 去死参。07-shop-ui-design.md 场景树+布局同步。 |
| 2026-06-11 | 🐛 **C24 商店忍者槽位数修正**: `shop_ui.gd._update_ninja_slot_label()` 从读库存数改为接收参数 `_owned_ninja_count` + `_max_ninja_slots`。`init()` 和 `update_gold()` 由 `ui_manager.gd` 传入 `NinKingGameState.owned_ninjas.size()`。运行时验证: 购买前"忍者 0/5"→购买后"忍者 1/5" ✅ |
| 2026-06-11 | 🗂️ **V48 AssetRegistry 统一素材注册表**: 新建 `asset_registry.gd`，合并 `ninja_data.gd`(CATEGORY_ICONS+get_icon_path) 和 `consumable_data.gd`(ITEM_CATEGORY_MAP+get_item_xx_path)。3 调用文件改为直接引用 `AssetRegistry`。旧文件保留 delegation stub ✅ |
| 2026-06-11 | 🗑️ **V49 死资产清理: icon_upgrade.png 删除** — 无任何物品类别需要升级图标（3 类为 transform/constellation/ritual），PNG + `.import` 一并删除 |
| 2026-06-11 | 📐 **C22 shop_ui.gd 行数优化**: `_apply_impact_button_style()` (40行) 提取到 `BarrierTheme.apply_impact_button_style()` 静态方法。shop_ui.gd 366→326行 ✅ |
| 2026-06-11 | 🎴 **V46 ArtIcon 归入 ArtArea 完成**: 商店 Ability/Item 卡 ArtIcon 从根 Panel 直子移入 ArtArea 内居中（Ability 80×80/Item 64×64）。`@onready` + `_cache_nodes()` 路径同步为 `$ArtArea/ArtIcon`。2 tscn + 2 gd 改动，场景树验证通过。 |
| 2026-06-11 | 🎴 **V45+V47 商店卡片图标差异化+稀有度视觉系统完成**: 通用加成 n_ 按效果拆 3 子类图标(chips/mult/both, 新 PNG 3 张) + `get_icon_path()` 加 effect 参数做子类解析 + 4 档稀有度边框(common墨/uncommon accent/rare红/legend金) + RarityBadge(rare"稀有"/legend"伝説") + `apply_barrier_theme()` 保护稀有度边框不被覆盖 + 忍条同步传参。3 脚本+3 PNG, 验证通过。覆盖 V45(P0)+V47(P1)。 |
| 2026-06-11 | 🃏 **B5 附魔卡使用流程实现**: 花色符 1→4 拆分(Balatro 风固定花色)。新建 `EnchantTargetSelector`(手牌 SVG 渲染+点击选牌)。shop_ui 加 `enchant_purchase_requested` 信号 + `start_enchant_targeting`。shop_handler 加 `on_enchant_purchase_requested`(扣钱→选牌→应用效果: set_suit/rank_shift/enhancement)。ui_manager/game_manager 全链路接线。影响 6 文件。 |
| 2026-06-11 | 🧹 **TODO 清理**: V5(商店背景)✅已实现, B8(条件效果)✅已实现, V4(按钮素材)🗑️废弃, V15(屏风转场)保留P3但标注范围缩小。实际待做项: B5/B6/B7/B10/C22。 |
| 2026-06-11 | 🏗️ **LeftPanel 三块锚定重构 + 文档同步**: ContentVBox 删除，ScoreCard(上半 1/2)/MatchPanel(中间 1/4)/AntePanel(底部 1/4) 直属于 LeftPanel，全部 anchor-based。`03-technical-design.md`/`06-ui-layout-reference.md`/`10-main-ui-design.md` §2-§3 同步更新。 |
| 2026-06-11 | 🎬 **计分动画增强: Phase 1 渐强三幕 + Phase 2.5 定格脉冲**: Phase 1 重写为每墩逐卡翻牌(0.06/0.09/0.12s) + 三档递进(scale_pop→加震→punch_in+粒子+hit_stop)。Phase 2.5 新增数字呼吸脉动(1.06↔1.0, 1.2s) + 面板泛光。BounceScore 各阶段放慢 ~1.7×。PlayBtn 灰色 bug 修复(disabled 在 `_refresh_internal` 中同步 `is_constraint_satisfied`)。文档同步: 10-main-ui-design.md §6 + 06-ui-layout-reference.md §3.4。 |
| 2026-06-11 | 🏪 **Phase C 实施完成**: S1-S10 全部 ✅ — shop_panel.tscn 提取/shop_ui 重写 panel 模式/NinKingTween 扩展/ui_manager 加 ShopOverlay/ninking_main 子树/game_manager SHOP 状态+0.5s 水印/Boss 战中揭晓/牌桌清理/文档同步/shop.tscn 删除。10 文件修改，~550 行新增。 |
| 2026-06-11 | 🖼️ **图像素材接入 3 项**: V40 牌桌背景 table_bg → GameBg TextureRect / V41 Boss 揭示立绘 9 张映射+动画 / V42 漫画粒子预设 manga_burst+manga_ink |
| 2026-06-11 | 🖼️ **V43+V44 图标接入**: 忍者 11 图标按 id 前缀映射到忍槽+商店卡片 + 物品 3 底板+4 图标按类别映射到商店卡片。ArtIcon Label→TextureRect, `ninja_data.gd` 加 `CATEGORY_ICONS`+`get_icon_path()`, `consumable_data.gd` 加 `ITEM_CATEGORY_MAP`+`get_item_icon_path()`/`get_item_base_path()`, 3 场景+4 脚本改动 |
| 2026-06-11 | 🖼️ **V39 集中线+卷轴匾额全量完成**: 3 张 PNG（focus_lines_heavy 600×120 / focus_lines_light 500×70 / section_scroll_frame 500×60）AI 出图+部署到 `assets/images/ui/`，场景 `shop_panel.tscn` 6 个 TextureRect 全部接入纹理：TitleFocusLines(重)/AbilityFocusLines(轻)/AbilityScrollFrame(匾额)/ItemFocusLines(轻)/ItemScrollFrame(匾额)/BottomFocusLines(重) |
| 2026-06-11 | 🔊 **V22 商店 BGM 接线完成**: MusicManager `play_shop_bgm()` + shop_ui 入场触发 + game_manager 离开恢复 game BGM |
| 2026-06-11 | 🔊 **B11 BGM 3 段变奏全面完成**: DOVA-SYNDROME 3 首 BGM（Light 216s / Medium 198s / Heavy 102s）→ MusicManager `set_game_variation(barrier)` 按 结界 1-3/4-6/7-8 自动 crossfade + `sound_bank.gd` 3 常量 + `_on_seal_started()` + 商店退出统一触发。**本次会话音频素材全部完成** |
| 2026-06-11 | 🔊 **C8+C16 音效全面接入**: `sound_bank.gd` 常量忍者主题重命名(HU→GROUP_REVEAL 等) + 新增 8 常量(SHOP_ENTER/SHOP_EXIT/ITEM_PURCHASE/SHOP_REROLL/BOSS_REVEAL/XI_FANFARE/REDRAW_POP/NINJA_ACTIVATE) + 旧名 alias 保留。接线到 `game_manager.gd`(8 处: BOSS_REVEAL/GROUP_REVEAL×3/COUNT_TICK→bounce_sfx/XI_TRIGGER/XI_FANFARE/SEAL_CLEAR/SEAL_FAIL/SHOP_EXIT)、`shop_ui.gd`(4 处: ITEM_PURCHASE+UI_COIN×2/SHOP_REROLL/SHOP_EXIT)、`hand_interaction.gd`(2 处: SWAP×2)、`redraw_vfx_handler.gd`(2 处: DISCARD+REDRAW_POP)。覆盖 16/20 音效素材接入。 |
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
| 2026-06-11 | 📋 **Phase C Code Review + 文档同步**: 审查 Phase C 4 文件 → 🔴 R4 修复（`ui._current_shop_panel` 封装破坏 → 加 getter）、🟢 R2 修复（冗余 `@onready var panel`）、🟢 R3 修复（`-> Array`→`-> Array[Node]`）。C21/C22 加入 TODO（game_manager 拆分建议、shop_ui 行数优化）。`06-ui-layout-reference.md` §2/§3/§5/§7 对齐实际 tscn + API。`07-shop-ui-design.md` shop.tscn 删除标记更新。|
| 2026-06-11 | 🧹 **商店素材↔框架结合问题盘点 — V45-V49 + C24 加入 TODO**: 梳理商店卡片 7 项问题 — V45 图标差异化不足(P0)、V46 ArtIcon 布局修复(P1)、V47 稀有度视觉接入(P1)、V48 AssetRegistry 统一注册表(P2)、V49 死资产引用(P2)、C24 忍者槽位数不准(P2)。源自 shop_ui/shop_ability_card/shop_item_card 代码审查。|
| 2026-06-11 | 📋 **商店自动过渡 Codereview**: 审查 `game_manager.gd` auto-shop 实现 → 🔴 A1 修复（`_auto_shop_pending` 设在 `finalize_play` 之后，信号同步发射导致 handler 读不到 flag → 移到之前）。C23 加入 TODO（✅ 已完成）。计划文档 Step 2 同步更新。|
| 2026-06-11 | 📝 **V29 完成: §2 场景树对照 ninking_main.tscn 重写** — HandTypeRow(VBox+3行)修复、ScoringOverlay 注释、VictoryOverlay 无 %、DeckViewer ViewerBg 展开。|
| 2026-06-11 | 📝 **V31 完成: §4-§7 恢复+重写** — §5 API 全部加类型注解、删除 5 个不存在旧方法、数据流补 signal 签名、§6 配色表+漫画风原则恢复、§7 文件索引按当前代码全面更新（hand_display/hand_interaction 等）。同时修复被 linter 覆盖的 §2 ScoringOverlay/DeckViewer。|
| 2026-06-11 | 📝 **V30 完成: OVL_ 前缀注明逻辑分类** — §1 前缀表加注释 + 示例对照。|
| 2026-06-11 | 🧹 **C21 game_manager.gd 拆分**: 599→275 行（-54%）。shop_handler.gd (115行) + animation_handler.gd (238行) 提取。商店逻辑委托 ShopHandler，计分动画委托 AnimationHandler。03-technical-design.md + 06-ui-layout-reference.md 同步。|
| 2026-06-11 | 🛒 **B4 商店刷新递进费用**: Balatro 风 $3+$1/次递进，每趟商店重置，无硬上限。shop_handler._reroll_count + _get_reroll_cost(), shop_ui 删 REROLL_COST 常量改用动态 update_reroll_cost(), ui_manager 加委托。14-economy + 07-shop-ui 文档同步。|
| 2026-06-11 | ⭐ **B6 星图卡购买流程实现**: 购买即用（不进背包）。shop_handler._purchase_star_chart() 检测 hand_type → 扣钱 → apply_star_chart +1 级 → Toast "散牌 Lv.2 → Lv.3!" → manga_burst 粒子。卡面显示当前 Lv.。4 文件改动。文档同步。|
| 2026-06-11 | 📈 **B10 修炼忍者成长接入 + n_s04 忍法帖删除**: `NinjaScaling.process_scaling()` 接入 `finalize_play`（on_play），xi_triggered 后、win/lose 前调用。构建 ctx 包含 head/mid/tail_type + triggered_xis。n_s04 忍法帖 删除（on_redraw 触发因手替え废弃永不生效）。剩余 5 张修炼忍者正常成长。|
| 2026-06-11 | 📋 **Grill 20 轮 → review-plan → 实施: 计分公式 v4.0 重构 — 扁平池→各行独立×列累乘**: A10(score_calculator)完全重写 | A11(auto_arranger)_fast_score per-group | A12(arrange_controller)分组忍者 | A13(card_data)列函数清理 | A14(xi_detector)四张×5 | A15(item_data)暴击骰子×2 | A16(animation_handler)breakdown格式新 | A17(hand_type_labeler)无需改 | A18(seal_controller)无需改 | A19(列VFX阈值降为同花) | D9(三文档同步: 06/13/03)。12 项全部完成 ✅ |
| 2026-06-11 | 📋 **Grill 20 轮 + review-plan: 计分公式重构 — 扁平池→各行独立×列累乘**: 完整决策链（各行独立计分、列×mult 2/4/8/16/32 累乘、星图只影响横排、忍者/附魔/卡片×mult/金剛力/黄金律/道具跟组走三组各得一份、全局喜最终级、四张 +50→×5、暴击骰子 1.5→2、约束不变、Ante 暂不变）。A10-A19 + D9 共 12 项加入 TODO。|
| 2026-06-11 | 📋 **方案审阅: LeftPanel 展示调整（计分 v4.0 后）**: 9 轮 grill 决策确认（CMC→列喜预览同排行、HandTypeRow 保持 `37×2`、Phase 1 ShadowScore color_flash + text、ColumnLabelRow 保留、BounceScore 删参）。review-plan 3 维度通过。A20-A28 共 9 项加入 TODO。|
| 2026-06-11 | 🎴 **A20-A28 全部完成: LeftPanel 展示调整**: 场景节点替换(CMC→ColXiLabel) + ui_manager/hand_display/hand_type_labeler 接口更新 + BounceScore 删参 + animation_handler Phase 1 分数动效 + card_data 列×mult 字典 + 3 文档同步。9 项全部 ✅ |
| 2026-06-12 | 💰 **方案审阅+Grill: 移除 LevelComplete 中间页 — 金币飞入左面板 + 自动进 Shop**: Grill 8 轮决策确认（移除独立页/自动进Shop但要过渡呼吸/金币飞入左面板/~1.5s/画面定格/数值滚动+飘字/可跳过）。review-plan 3 维度审阅通过，2 个待确认项落地（金币动画与 punch_in 重叠、保留 0.3s cross-fade）。E1-E10 共 10 项加入 TODO Phase E。 |
| 2026-06-12 | ⚡ **Phase E 实装完成 — E1-E10 全部 ✅**: animation_handler.gd 捕获旧值 → game_manager.gd SEAL_COMPLETE 分支重写(_play_gold_settlement + _create_shop_skip_overlay + _do_shop_transition) → ui_manager.gd + result_screen_display.gd 清理旧引用 → ninking_main.tscn 移除 LevelComplete 子树 → 文档同步。5 脚本 + 1 场景 + 2 文档修改。 |
| 2026-06-12 | 🔢 **计分公式 v5.0 列加法化**: Grill 16 轮决策 + review-plan 审阅。列从 ×mult栈(×2~×32768) 改为 chips×mult 加法和行平级。score_calculator.gd 重写(_collect_ninja_for_column + _compute_group_score 复用) + animation_handler/debug_controller/hand_type_labeler 列显示更新 + card_data deprecated。封印值 300~380k → 200~550k。文档 06/13/03/README 全部同步。D10 加入 TODO。 |
| 2026-06-12 | 🃏 **B14 忍者栏拖拽 card-framework 迁移**: 主界面忍者栏整栏迁移至 card-framework。新建 `NinjaInventoryCard`(Card 子类，125×175，hover_scale 1.15) + `NinjaBarContainer`(CardContainer 子类，DropZone 垂直分区拖拽排序)。`ninja_bar_node.gd` 重写（删 ~110 行手工拖拽代码，_make_slot 改用 NinjaInventoryCard.new()）。删 `ninja_slot.gd`/`ninja_slot.tscn`。`ninja_bar_display.gd` 改用 NinjaInventoryCard。z_index 覆盖层提升至 1100（Card drag = stored_z + 1000）。`ninking_main.tscn`/`debug_ninking_main.tscn` %NinjaBar type HBoxContainer→Control。`ui_manager.gd`/`debug_controller.gd` 引用更新。|
| 2026-06-12 | 📊 **LeftPanel v2 — 列积分+公式展示**: Grill 14 轮决策。ScoreCard 新增 ColumnTypeRow(左列/中列/右列)镜像 HandTypeRow、ScoreLabel 内嵌公式 "{subtotal}×{xi}={total} 忍気}"、ColXiLabel 纯喜。LeftPanel 420→480px 宽度。动画重排 Phase 行→列→喜→结局。5 脚本 + 2 场景 + 1 文档同步。BounceScore 解耦。 |
| 2026-06-12 | 🐛 **NinjaBar 长距离拖拽交换修复**: `ninja_bar_container.gd` 新增 `get_partition_index()` 重写，直接读取 `get_global_mouse_position().x` 与 `drop_zone.vertical_partition` 分区线对比，绕过 DropZone 内部 `check_mouse_is_in_drop_zone()` 传感器门控。配合已有的 `check_card_can_be_dropped` 重写（已持有卡牌直接返回 true），实现任意距离拖拽重排。|
| 2026-06-13 | 🎬 **计分动画渐进式累加 + 进度条分段变色**: Phase 1/2 每行每列计分后总分逐步累加上去(set_score_formula+scale_pop)，进度条同步推进(_tween_progress)。Phase 3 跳过无意义的 ×1 展示(仅 xi_product>1 时显示公式+金色闪烁)。`score_calculator.gd` 修复 col_scores 散牌列索引错位(散牌列追加 0 保持 3 元素对齐)。进度条按百分比自动变色: <50%白→50%淡黄(α0.65)→80%橙黄(α0.75)→100%红(α0.85)，常驻不闪。计分开始自动重置为白色。 | `animation_handler.gd` + `score_calculator.gd` |
| 2026-06-15 | 🃏 **CardDetailPopup Balatro 风改造 — chips蓝/mult红效果数值行**: 新增 `effect` 字典传入通路(display_card_base→shop_slot/ninja_bar_node/CardDetailPopup)。`_parse_effect_rows()` 解析 add_chips/add_mult/x_mult(跳过零值/×1)，`_build_effect_row()` 渲染 蓝筹码/红倍率 彩色数値行。纯数值卡 desc 自动隐藏避免冗余，有条件卡保留 desc 作为条件说明。Code Review 修复 2 项: `%d`→`%s` 防浮点截断、`setup()` 补 `_detail_effect`。Debug 场景同步传 effect。7 文件。 |
| 2026-06-14 | 📝 **Debug 场景文档同步**: `20-debug-scene-design.md` §4 场景树更新 — CardGrid 命名、ColumnLabelRow 补全、AiRearrangeBtn/DeckBtn 位置修正为与主场景对齐，§8 已知限制 #2 标记已修复 |
| 2026-06-13 | 🖌️ **商店水墨风改造 — 第一阶段**: Grill 19 轮决策。风格方向→日式水墨、配色降饱和、字体站酷妙典体+思源黑体、按钮印章化。shop_panel.tscn 和纸底色+删网点层、shop_ui.gd 水墨色板+`_apply_ink_wash_theme()`+印章按钮三态、shop_slot.gd 纸片卡框+朱砂购买按钮+稀有度水墨色系。不改任何全局文件(BarrierTheme/manga_theme/display_card_base/NinKingTween)。4 文件修改 + spec 文档。详见 [`specs/shop-ink-wash-redesign.md`](specs/shop-ink-wash-redesign.md)。|
| 2026-06-15 | 🎬 **方案审阅+Grill: 计分忍法动效（三幕式动画）**: Grill 12 轮决策确认（逐行二段式/忍者弹起+金框+飘字+squash/行间过渡/列加分重新播忍者/跳过机制）。review-plan 3 维度审阅通过。G1-G8 共 8 项加入 TODO Phase G。|
| 2026-06-15 | 🎬 **Phase G 实施完成 G1-G7 + Code Review 修复 6 项**: G5 `TweenFX.ninja_pop_trigger()` + G6 `GlobalTweens.ninja_trigger()` 基础设施。G1 animation_handler 重写为二段式计分+忍者触发注入。G2 跳过机制(_wait_or_skip + _skip_and_finalize)。G3 Phase 2 列加分+忍者重播。G4 行间过渡。G7 tween-library-reference 同步。Code Review 修复: R1 飘字改用 `_ui.add_child` 防遮挡、R2 删 `_sfx_tick` 死代码、R3 Phase 1 总分飘字、R4 `_find_ninja_card` 注释说明私有访问、R5 xi 条件忍者需 `xi_result` 验证才触发、R6 去重 `NINJA_ACTIVATE` 音效。4 文件修改。|
| 2026-06-15 | 🃏 **C29 统一忍者卡场景 ninja_card.tscn**: 新建场景替代 DisplayCardBase+NinjaInventoryCard 双实现。NinjaInventoryCard 加 `_shop_mode` 标志 + setup_shop/set_content_texture/apply_barrier_theme/set_frame/set_detail_data 方法。ShopSlot 改实例化 ninja_card.tscn。忍者栏改为场景实例化。删 display_card_base.gd/.tscn + .uid。文档同步 6 文件 + spec 重写。|
| 2026-06-15 | 🐛 **C29 时序安全补丁**: 忍者栏框不显示 + 编译错误修复。`setup()`/`setup_shop()` 顶部加 `_ensure_face_nodes()` + `check_and_set_textures()` 在 `_ready()` 前解析节点引用；`_ensure_face_nodes()` 新增 `frame_overlay` 引用解析；`_ready()` 移除 `frame_overlay.visible = false`；`apply_barrier_theme()` 改用 `has_theme_stylebox_override() + get_theme_stylebox() as StyleBoxFlat`；`game_manager.gd:35` 删多余参数；`count_up.gd` `gap2`→`_gap2`。|
| 2026-06-15 | 📋 **深度 Code Review 方案审阅: 6 项代码质量任务加入 TODO**: 审阅发现 `_group_card_chips` 两处有 `include_seal` 差异，经 review-plan 确认修正方案。C30(score_helpers.gd, P0) + C31(score_result.gd) + C32(arrangement.gd) + C33(tooltip StyleBox 共享) + C34(ContinuePanel 场景化) + C35(CardDetailPopup 场景化) 共 6 项。取消 `CardFaceFactory` 抽象(过度设计)。|
| 2026-06-16 | 🃏 **方案审阅+Grill: 满员忍者替换购买(Balatro风)**: 先买后换 → 全屏模态弹窗(新牌+5卡副本) → 半价退款 → `_replace_guard` 防重入。review-plan 3 维度审阅通过，A1(重入守卫)/A2(操作锁定)/Q1(弹窗内渲染)/Q2(ui_manager 临时管理) 决策确认。B14 加入 TODO Phase B。|
| 2026-06-16 | ✨ **忍者牌稀有度闪光材质效果调优**: 边框纹理 resize fix(_resize_to_card() 500x700 to 125x175); Uncommon 静态转缓慢银光(speed=0.5/int=0.35); Rare 降速降强度(speed=1.0/int=0.3); Legendary 多次降强度(1.0 to 0.6 to 0.45)+呼吸范围同步调低; 所有参数三文件同步(.tres+RARITY_FLASH_PARAMS+脉冲范围)。附: 恢复缺失 card_preview.gd。|
| 2026-06-15 | 📐 **全部 6 项代码质量任务实施完成** 🎉: C30 创建 `score_helpers.gd`(含 `include_seal` 参数) + 两处调用替换; C31 `ScoreResult`→`score_result.gd`(更新 5 引用文件); C32 `Arrangement`→`arrangement.gd`(更新 4 引用文件); C33 `CardVisualComposer.create_tooltip_stylebox()`+ 替换两处; C34 `ContinuePanel`→`continue_panel.tscn`(新建脚本 `continue_panel.gd`); C35 `CardDetailPopup`→`card_detail_popup.tscn`(节点预置于场景)。净消除 ~100 行重复代码, 新增 3 文件 + 2 场景。|
| 2026-06-17 | 📋 **Kenney UI 素材包双方向评估 + 执行计划**: 创建 `20-kenney-ui-pack-evaluation.md`（少年漫画/治愈漫画完整匹配度矩阵）。创建执行计划，含方向决策框架、方案 A（光标+维持少年漫画）、方案 B（治愈系 5 阶段过渡）。V52 + K1-K7 加入 TODO。详见 `.claude/plans/delightful-forging-cocke.md`。 |
| 2026-06-18 | 🐛 **Debug 场景日志落盘修复**: debug_controller.gd `_on_back_pressed()` 退出前未调用 `on_game_over()` → `_finalize_run()` 从未触发 → events 累积内存不写盘。修复: 退出前调 `GameRunLogger.on_game_over(...)` 触发 JSON 写入。同时修 `game_logger.gd` UNUSED_PARAMETER 警告。|
| 2026-06-18 | 📢 **start_run() 输出窗口提醒**: 启动时打印日志 ID/牌组名/保存目录(真实路径)/HTML 回放查看器路径，方便快速跳转和打开回放 |
| 2026-06-18 | 📝 **Phase L 游戏回放日志系统完成**: Grill 9 轮设计决策。`game_logger.gd` 核心类(13 种事件 + JSON 序列化 + 全量/增量快照) + `game_state.gd`/`seal_controller.gd`/`shop_manager.gd` 插桩 + `ninja-game-replay.html` HTML 可视化回放查看器(拖拽加载/时间线/卡牌渲染/键盘导航)。详见 TODO Phase L。 |
| 2026-06-18 | 🐛 **save_manager 只读字典崩溃**: `load_progress()` 对 `DEFAULT_PROGRESS` 使用浅拷贝 `.duplicate()`，内层嵌套空字典保持只读 → `record_run_result()` 写入时崩溃。修复: `.duplicate(true)` 深拷贝。同步更新 `06-ui-layout-reference.md`/`10-main-ui-design.md`/`11-main-overlay-design.md` 的 GameOver 节点描述（ScoreSummary 28px 居中 + BackToMenuButton 20px flat）|
| 2026-06-17 | 📋 **方案审阅+Grill: 外部 Shader 资源集成**: 审阅 3 外部库（ShaderLib/ShaderV/gdquest）→ 选定箔片闪光增强(flash_type=3) + 溶解 UV 滚动 + 色差工具集 3 方向。跳过全息卡(vertex冲突)/悬停(已覆盖)/阴影(过度工程)。J1-J5 共 5 项加入 TODO Phase J。Spec: `specs/shader-external-integration.md` |
| 2026-06-18 | 🎬 **方案审阅: 外部 Shader 整合引入 → Phase K**: 归档 11 枚源 .gdshader → `shaders/sources/`。review-plan 发现: ① fake3d_flash 已覆盖 robust_shine 不重复引入 ② GlowFX 扩展 emissive_add 覆盖 blink ③ 纯参数效果合并为 FilterFX 统一管线 ④ 全屏色差暂缓。K0-K2 共 11 项加入 TODO Phase K。K0 子项可 F1 同期做 |
| 2026-06-21 | 🖱️ **忍者栏交互重设计**: Grill + review-plan 审阅通过后实施。① NinjaBarNode 新增 hover 工具提示（0.3s SceneTreeTimer 延迟）→ `ninja_detail_tooltip.tscn/.gd`（面板位置/尺寸/颜色完全在编辑器中调整，不锁死在代码里）② 右键弹出红色售卖按钮 → `ninja_sell_button.tscn/.gd`（价格=ceil(cost/2)，pop_in 动效）③ VFX: 右键售卖调用卡面 `GlobalTweens.scale_pop(card, 1.15, 0.15)` + `SB.UI_CLICK` SFX ④ ShopManager.sell_ninja() 金币退款已验证（半价 refund + 刷新）⑤ 文档同步: `06-ui-layout-reference.md` §3.3.3.a（6 行交互行为表 + tooltip/sell 场景信息表 + 编辑器可调整约束） + §7 文件索引 + `DOCUMENT_MAP.md` §5.6 更新 |
| 2026-06-21 | 📋 **方案审阅: 删除忍者替换购买 → Toast+脉冲**: B22(删替换系统) + B23(满员→Toast+脉冲) + B24(pulse_cards) + C52(清死代码) + C53/C54(文档同步) 共 6 项加入 TODO。替换系统 UI 太复杂，改为引导玩家自行出售。 |
| 2026-06-21 | ✅ **删除忍者替换购买系统 — 全部完成**: B22/B23/B24/C52/C53/C54 共 6 项 ✅。删 `ninja_replace_overlay.gd/.uid` + `_start_replace_flow()`(78行) + `_replace_guard` + `show/hide_replace_overlay()` + `ShopManager.replace_ninja()`/`sell_ninja()` + `shop_handler.on_sell_requested()`。满员购买 → Toast "忍者栏已满，请先出售" + 脉冲动画 + UI_ERROR。文档同步: `07-shop-ui-design.md` §5.3 删除 + `DOCUMENT_MAP.md` §5.13 移除 + `ui-signal-architecture.md` 更新 + `specs/ninja-replace-flow.md` 标记废弃。 |
| 2026-06-23 | 🔴 **attract_pulse 修复 — Compatibility 渲染器下不可见**。根因：`gl_compatibility` 不支持 Color >1.0，modulate 脉冲被夹紧为无色。修复：`scale_pulse` 默认 `true`，modulate 范围改为 ≤1.0 (`0.90↔1.0`)。扩展至 Launcher StartBtn + DeckSelect ConfirmBtn。C56 入 TODO。|
| 2026-06-23 | 🎨 **按钮统一展示动效 KUI8-KUI17**: 10 场景全部实施
| 2026-06-23 | 🐛 **B26 牌库面板已出牌灰色 + 尺寸修复**: `fake3d.gdshader` fragment 写 `COLOR = texture(...)` 覆盖 Godot 内置 `MODULATE`，导致 `modulate` 灰度无效。修复：三个 fake3d shader 末尾加 `COLOR *= MODULATE`; `ninking_card.gd` `_apply_fake3d_material()` 在 `can_be_interacted_with == false` 时跳过（deck viewer 卡牌无需 fake3d，同时消除 vertex 膨胀导致的尺寸异常）。涉及 4 文件。|
| 2026-06-23 | ⚡ **Shader 优化 S2/S4/S5 完成** — S2: 4× .tres 精简(删除 12 个冗余闪参数→RARITY_FLASH_PARAMS 批量循环)；S4: Outline LOD (`high_quality`低质量4对角线采样)；S5: GlowFX emissive 加法发光模式(覆盖 blink.gdshader)。|
| 2026-06-23 | ⚡ **Shader 优化方案审阅完成 — S1-S7 入 TODO**: 分析 18 个 shader 文件发现 Fake3D 3× 重复代码(核心问题) + 5× 冗余 .tres + 材质复制爆炸 + 4 闲置 shader。review-plan 四维度审阅通过，P1 因 .tres 参数实际复杂度高于预想修正为路径 A。P6(Holographic)删除，P5(Foil)暂缓。S1(P0)+S2(P1)+S3(P2)+S4(P4)+S5(P3)+S6(P8)+S7(清理) 共 7 项加入 TODO。Q1(路径A)/Q2(删除全息)/Q3(清理card_glow残留)全部确认。|
| 2026-06-23 | 📋 **shaderlist 优化方案审阅 + 修正**: 分析 shaderlist 85+ shader 对 NinKing 的优化价值。review-plan 发现 🔴A1(架构边界/GlobalTweens控制) + A2(pixel_explosion独子系统) 必须修正。用户确认后写入 S8-S14 共 7 项。**仅 S8(清理) + S10(HaloFX) 为 P1 优先实施，其余 P3/P4暂缓。**|
| 2026-06-23 | ⚡ **S8 清理完成** — 删除 `shaderlib/` 3 个未用 shader(含 .uid) + `sources/` 中已覆盖的 robust_shine/blink。`SOURCES.md` 同步更新。shaderlib/ 目录已清空。|
| 2026-06-23 | 🔥 **S10 HaloFX 实施完成** — `shaders/effects/halo.gdshader` 移植(halo_01 改造版: animate 开关+uniform 外部控制+稀有度色板适配) + `scripts/shader/halo_fx.gd`新建(遵循 EdgeFadeFX 模式) + `GlobalShaders` 注册 `apply_halo/clear_halo/has_halo`。脚本编译验证通过。|

## 🎨 按钮统一展示动效 — 弹跳入场 + 金色粒子 + 呼吸脉冲 + hover + 点击反馈

| # | 任务 | 说明 | 优先级 | 状态 |
|---|------|------|--------|------|
| KUI8 | **TweenFX 基础设施**: entrance_bounce + button_click_feedback | tween_fx.gd + global_tweens.gd | P0 | ✅ |
| KUI9 | **ButtonStyles.attach_entrance_animation**: 统一入口动效全生命周期 | button_styles.gd | P0 | ✅ |
| KUI10 | **Launcher StartBtn mild** (pulse: true) + 其他按钮 pulse: false | main_menu.gd | P0 | ✅ |
| KUI11 | **DeckSelect ConfirmBtn** 完整入场 | deck_select_panel.gd | P0 | ✅ |
| KUI12 | **Main PlayBtn/AiRearrangeBtn** 完整+mild | game_manager.gd | P0 | ✅ |
| KUI13 | **GameOver/Victory 按钮** mild 模式 | game_manager.gd | P0 | ✅ |
| KUI14 | **Shop RerollBtn/ContinueBtn** mild | shop_ui.gd | P0 | ✅ |
| KUI15 | **ShopSlot BuyBtn** 完整入场 | shop_slot.gd | P0 | ✅ |
| KUI16 | **ContinuePanel GoBtn/BackBtn** mild | continue_panel.gd | P0 | ✅ |
| KUI17 | **SettlementCard UnlockBtn** mild | settlement_card.gd | P0 | ✅ |
| KUI18 | **Debug 场景同步** (待接入 manga 样式后) | debug_controller.gd | P2 | ⬜ |
| KUI19 | **呼吸脉冲重写**: direct scale pulse, StyleBoxFlat fallback, pulse config | tween_fx.gd + button_styles.gd | P0 | ✅ |

