# NinKing 特效设计决策框架

> **建立日期:** 2026-06-23
> **用途:** 任何视觉/动效/Shader/材质效果的设计请求，按此框架逐步骤评估，确保方案可执行、可维护、不重复造轮子。
> **关联:**
>   [`CLAUDE.md`](../CLAUDE.md) — 工作流触发规则
>   [`tween-library-reference.md`](tween-library-reference.md) — Tween 场景速查
>   [`shader-library-reference.md`](shader-library-reference.md) — Shader 场景速查
>   [`scripts/ninking/asset_registry.gd`](../scripts/ninking/asset_registry.gd) — 素材注册表

---

## 目录

1. [框架总览](#1-框架总览)
2. [第一步：效果定性](#2-第一步效果定性)
3. [第二步：查三库](#3-第二步查三库)
4. [第三步：评估缺口](#4-第三步评估缺口)
5. [第四步：方案选择](#5-第四步方案选择)
6. [第五步：入库落地](#6-第五步入库落地)
7. [效果类型→能力映射表](#7-效果类型能力映射表)
8. [一致性检查清单](#8-一致性检查清单)
9. [案例：完整决策演示](#9-案例完整决策演示)
10. [速查卡片](#10-速查卡片)

---

## 1. 框架总览

每个效果设计请求走一遍五步决策树：

```
[需求] 你想要一个视觉/动效效果
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  ① 效果定性                                                │
│  它是什么类型？属于哪个大类？                                │
│  出现/消失 / 强调/高亮 / 受击/反馈 / 氛围/滤镜 / 过渡/转场 │
│  信息展示 / 持续循环                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  ② 查三库 — 盘家底                                         │
│  ├─ Tween库:   docs/tween-library-reference.md §场景速查    │
│  ├─ Shader库:  docs/shader-library-reference.md §场景速查   │
│  └─ 素材注册表: scripts/ninking/asset_registry.gd          │
│     + docs/ninking/05-art/21-ui-interaction-enhancements.md │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  ③ 评估缺口                                                │
│  ├─ ✅ 已有 API 能直接覆盖 → 直接用，不造新                 │
│  ├─ 🟡 接近但缺一块 → 扩展已有子系统（+1 uniform / +1 方法）│
│  └─ 🔴 全新需求 → 新建子系统 + 入库                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  ④ 方案选择 — 多路径时选最优                                │
│  纯 Tween > Tween+Shader > 新建子系统                       │
│  （优先轻量、最小改动、对现有一致性零冲击）                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  ⑤ 入库落地                                                │
│  ├─ 新 Tween   → tween-library-reference.md 追加一行        │
│  ├─ 新 Shader  → shader-library-reference.md 追加一行       │
│  ├─ 新素材依赖 → asset_registry.gd / 交互增强文档同步       │
│  └─ 新子系统   → shader-library-reference.md 注册           │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 第一步：效果定性

收到需求后，先判断它属于哪种**效果大类**。这决定了查库时优先看哪个方向。

### 分类速查

| 大类 | 子类 | 特征 | 典型场景 |
|------|------|------|---------|
| **出现/消失** | 弹入、淡入、滑入、溶解、爆炸、像素化 | 元素从无到有/从有到无 | 卡牌入场、面板弹出、忍者消散、结算爆炸 |
| **强调/高亮** | 描边、发光、呼吸脉冲、缩放、闪烁 | 元素持续吸引注意，不改变存在状态 | 选中高亮、按钮 hover、稀有度闪光 |
| **受击/反馈** | 抖动、色差、闪白、故障爆发、缩放压扁 | 对操作的即时响应，短暂触发后恢复 | 受击闪白、按钮 squash、操作确认 |
| **氛围/滤镜** | 灰度、暗角、色调叠加、纸张纹理、模糊 | 覆盖在整个画面或面板上的持续效果 | 暂停灰度、剧情暗角、结算暖调 |
| **过渡/转场** | 擦除、分裂、波纹、圈入圈出 | 连接两个画面状态的变化过程 | Boss 战入场、关卡切换、GameOver 过渡 |
| **信息展示** | 数字滚动、进度条填充、文字打字机 | 数据从旧值→新值的可视变化 | 计分动画、金币增减、喜爆发 |
| **持续循环** | 呼吸脉冲、旋转、浮动、波形 | 无限循环的装饰性动效，无触发条件 | 背景光晕、装饰粒子、UI 装饰 |

### 如何分类

问自己三个问题：

| 问题 | 判断方向 |
|------|---------|
| 这个效果是一次性的还是持续的？ | 一次性 → 出现/消失/受击/过渡；持续 → 强调/氛围/循环 |
| 这个效果是元素内部的还是全屏的？ | 元素内部 → 出现/消失/强调/受击；全屏 → 氛围/过渡 |
| 这个效果需要操作触发吗？ | 需要 → 受击/反馈/过渡；不需要 → 氛围/持续循环 |

---

## 3. 第二步：查三库

定性后，按类型侧重查库。不是三个库都翻一遍，而是根据定性结果优先查对应方向。

### 针对性查库路线

| 效果大类 | 优先查 | 次优先查 | 素材方向 |
|---------|--------|---------|---------|
| **出现/消失** | Tween 库（入场/出场动画） | Shader 库（溶解/爆炸） | 噪声纹理、粒子贴图 |
| **强调/高亮** | Shader 库（描边/发光） | Tween 库（脉冲/呼吸） | — |
| **受击/反馈** | Shader 库（色差/故障） | Tween 库（抖动/squash） | 音效 |
| **氛围/滤镜** | Shader 库（multi_filter/paper） | — | Kenney 面板纹理 |
| **过渡/转场** | Shader 库（故障/波纹） | Tween 库（缩放入场） | 噪声纹理 |
| **信息展示** | Tween 库（数字滚动/进度） | — | — |
| **持续循环** | Tween 库（脉冲库） | Shader 库（glow/shine） | — |

### 三库快捷导航

| 要查什么 | 去哪查 |
|---------|--------|
| Tween 动效（弹跳/缩放/淡入淡出/数字滚动/抖动/冲量） | `docs/tween-library-reference.md` → **§场景速查**（表格） |
| Shader 特效（溶解/描边/发光/色差/故障/爆炸/滤镜） | `docs/shader-library-reference.md` → **§场景速查**（表格） |
| 按钮交互生命周期（样式+入口动效+呼吸脉冲+hover+click） | `scripts/ninking/ui/button_styles.gd` + `docs/ninking/05-art/21-ui-interaction-enhancements.md §3.4` |
| 面板/光标/StyleBox 素材 | `docs/ninking/05-art/21-ui-interaction-enhancements.md` |
| 其他材质资源（闪光/帧框/图标） | `scripts/ninking/asset_registry.gd` |
| Kenney 暖纸风画风规范 | `docs/ninking/09-mgmt/specs/kenney-beige-ui-transformation.md` |

---

## 4. 第三步：评估缺口

查完三库后，对照需求做缺口判断：

### 判断标准

| 结论 | 条件 | 行动 |
|------|------|------|
| **✅ 已有 API 直接覆盖** | 需求参数完全匹配现有方法签名 | 直接调用，零代码新增 |
| **🟡 接近但缺一块** | 需求主体可用现有 API，但差 1-2 个参数/统一字段 | 扩展已有子系统（加 uniform / 加方法重载） |
| **🟡 可通过组合实现** | 单一 API 不够，但组合 2-3 个现有 API 可达成 | 写一个组合函数，存入最相关的子系统 |
| **🔴 全新需求** | 现有库中找不到对应功能 | 新建 .gdshader + *_fx.gd 子系统 |

### 评估时的红线

- **已有 API 能覆盖的 → 绝不允许另写一套**（禁止重复造轮子）
- **接近但不完全匹配 → 优先扩展，不新建**（保持库的收敛）
- **需要新建 → 必须走完整入流程（步骤⑤）**（不留孤儿代码）

---

## 5. 第四步：方案选择

当同一条需求有多个可行方案时（例如纯 Tween vs Tween+Shader），按以下优先级选择：

### 优先级

```
纯 Tween（轻量、无纹理依赖、无兼容性问题）
    ↑ 优先考虑
Tween + Shader（组合方案，需确认材质不冲突）
    ↑ 中间选择
新建 Shader 子系统（最重，需走完整入库流程）
    ↑ 最后手段
```

### 决策规则

| 规则 | 说明 |
|------|------|
| **能不动纹理就不动** | 纯 Tween 解决的场景不要上 Shader（性能更高、代码更简单） |
| **能扩展就不新建** | 已有的子系统加一个方法，比新建一整套 *_fx.gd 更可控 |
| **能不碰素材就不碰** | 不需要新纹理的效果 > 需要新纹理 > 需要新导入流程 |
| **考虑组合冲突** | 同一节点不能同时挂两个 ShaderMaterial（后挂的覆盖先挂的）。需要叠加时，要么合并到一个 shader 里，要么用 Tween 做上层 |
| **交互一致性优先** | 效果是否符合 Kenney 暖纸风/治愈漫画画风？按钮动效是否统一走 `ButtonStyles`？ |

### 常见冲突判定

| 场景 | 判定 | 理由 |
|------|------|------|
| 卡牌需要有选中高亮+稀有度闪光 | ✅ 可以共存 | 选中高亮走 `OutlineFX`（shader），稀有度闪光走 `fake3d_flash`（材质已内建），两者材质不冲突 |
| 面板需要边缘淡出 + 全屏暗角 | ✅ 可以共存 | 边缘淡出在面板节点，暗角在 overlay 节点，不同节点互不影响 |
| 同一 Sprite 需要溶解消散 + 像素爆炸 | ❌ 不能共存 | 两个 shader 会覆盖，必须选一个或合并 |
| 按钮需要 hover 放大 + 呼吸脉冲 | ✅ 可以共存 | 都是 Tween 动效（`ButtonStyles.attach_entrance_animation` 内置），同一 Tween 管理 |

---

## 6. 第五步：入库落地

效果设计/实现完成后，必须将能力记入库中，供下次查库时发现。

### 入库规则

| 新增了什么 | 必须更新 | 选更 |
|-----------|---------|------|
| 新的 Tween 方法 | `docs/tween-library-reference.md` §场景速查 追加一行 | — |
| 新的 Shader 子系统 | `docs/shader-library-reference.md` §组件表 + §场景速查 + §对应子系统章节 | $SOURCES.md 状态列 ✅ |
| 新的 .gdshader 文件（来自外部） | `shaders/sources/SOURCES.md` 状态列 ✅ | — |
| 新的素材依赖 | `scripts/ninking/asset_registry.gd` | `docs/ninking/05-art/21-ui-interaction-enhancements.md` |
| 新的效果类型或分类 | `docs/design-decision-framework.md` §7 映射表 | — |

### 入库后的确认

```
新能力入库后 → 下次有人问"效果 X 怎么做" → 查库就能发现 → 不需要重复讨论
```

---

## 7. 效果类型→能力映射表

这是当前项目所有能力的一览表。**新增效果后必须在对应分类中追加一行。**

### 出现/消失

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| 面板弹入弹出 | — | `GlobalTweens.pop_in()` / `pop_out()` | 无 | §场景速查 |
| 面板从侧边滑入 | — | `GlobalTweens.slide_in()` / `slide_out()` | 无 | §场景速查 |
| 卡牌溶解消散 | `dissolve_out()` | 内置动画 | 噪声纹理（自动创建） | §1.2 |
| 像素爆炸消散 | `pixel_explode()` | 内置动画 | 法线噪声（自动创建） | §1.7 |
| 淡入淡出 | — | `GlobalTweens.fade_in()` / `fade_out()` | 无 | §场景速查 |
| 缩放 + 淡入 | — | `GlobalTweens.fade_scale_in()` | 无 | §场景速查 |
| 按钮弹跳入场 | — | `ButtonStyles.attach_entrance_animation(btn, {"mild": false})` | Kenney 按钮纹理 | 完整模式含弹跳 |
| 按钮轻量入场 | — | `ButtonStyles.attach_entrance_animation(btn, {"mild": true})` | Kenney 按钮纹理 | 跳过弹跳 |

### 强调/高亮

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| 卡牌选中描边 | `apply_outline()` | — | 无 | 自动检测透明度边缘 |
| Sprite 辉光发光 | `apply_glow()` | — | 无 | 内发光 |
| 辉光呼吸脉冲 | `apply_glow()` | `pulse_glow()` 内置 | 无 | 参数 min/max_intensity |
| 稀有度闪光 | `AssetRegistry.FLASH_MATERIAL_PATHS` | — | `.tres` 材质（已入库） | 走 fake3d_flash |
| 按钮呼吸脉冲 | — | `ButtonStyles.attach_entrance_animation(btn, {"pulse": true})` | Kenney 按钮纹理 | 内置呼吸 |
| 按钮 hover 放大 | — | `ButtonStyles` 默认行为 | 无 | 1.05x scale |
| 颜色强调闪烁 | — | `GlobalTweens.flash_color()` | 无 | 白/红闪 |
| 喜 Xi 爆发光效 | — | `GlobalTweens.xi_flash()` | 无 | 计分喜字 |

### 受击/反馈

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| 受击色差闪烁 | `apply_chromatic_aberration()` | `tween_param("intensity", 0→0.8→0)` | 无 | §1.5 |
| 操作 squash 反馈 | — | `GlobalTweens.squash()` / 按钮 click 自带 | 无 | §场景速查 |
| 抖动/震屏 | — | `GlobalTweens.shake()` / `screen_shake()` | 无 | §场景速查 |
| 冲量弹动 | — | `GlobalTweens.impact_pulse()` | 无 | §场景速查 |
| 按钮 pressed 下沉 | — | `ButtonStyles` 内置 | 无 | content 下移 2px |

### 氛围/滤镜

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| 灰度 | `multi_filter (mode=0)` | — | 无 | §1.8 |
| 暗角 | `multi_filter (mode=1)` | — | 无 | §1.8 |
| 颜色叠加/色调 | `multi_filter (mode=2)` | — | 无 | §1.8 |
| 灰度+暗角混合 | `multi_filter (mode=3)` | — | 无 | §1.8 |
| 纸张纹理 | 见 shaderlist Tier 1 待接入 | — | — | 尚未集成 |
| 面板边缘淡出 | `apply_edge_fade()` | — | 无 | §1.1 |

### 过渡/转场

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| 故障爆发过渡 | `split_glitch_burst()` | 内置动画 | 无 | §1.6 |
| 持续故障扰动 | `apply_split_glitch()` | — | 无 | 内置 TIME 动画 |

### 信息展示

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| 数字滚动计数 | — | `GlobalTweens.score_count()` | 无 | 从旧值→新值 |
| 进度条填充 | — | `GlobalTweens.progress_fill()` | 无 | 兼容 tween_property |
| 文字渐显 | — | `GlobalTweens.fade_in()` | 无 | §场景速查 |

### 持续循环

| 你想要 | Shader API | Tween API | 需要素材 | 备注 |
|--------|-----------|-----------|---------|------|
| Shader 参数呼吸 | `pulse_param(mat, "param", min, max, cycle)` | 内置 | 无 | 委托 GlobalTweens |
| 数字跳动 | — | `GlobalTweens.bounce()` | 无 | 无限循环模式 |
| 漂浮/浮动 | — | `GlobalTweens.float_anim()` | 无 | 上下浮动循环 |

---

## 8. 一致性检查清单

方案确定后，逐项检查以下问题：

### 技术一致性

- [ ] 方案是否优先使用了 `GlobalTweens.xxx()` / `GlobalShaders.xxx()`？
- [ ] 是否有手写 `create_tween()` 在已有 API 覆盖的范围内？
- [ ] 是否有手写 `ShaderMaterial.new()` + `load()` 在已有 API 覆盖的范围内？
- [ ] 同一节点是否同时挂了多个 ShaderMaterial？（后挂会覆盖先挂）
- [ ] 是否需要合并多个独立 shader 效果到一个 shader 里？
- [ ] 程序化创建的 TextureRect 是否显式设了 `expand_mode = EXPAND_IGNORE_SIZE`？

### 交互一致性

- [ ] 按钮效果是否统一通过 `ButtonStyles.xxx()` 管理？
- [ ] 按钮入口动效是否统一通过 `ButtonStyles.attach_entrance_animation()` 管理？
- [ ] Panel 节点样式是否匹配 Kenney 暖纸风映射表（纹理/9宫格 8px/NEAREST 过滤）？
- [ ] 新控件是否自动获得蓝手悬停光标？（Button/Card 子类自动，其他需手动）
- [ ] 整体画风是否符合 Kenney 暖纸风/治愈漫画风？

### 性能一致性

- [ ] Shader 采样次数是否合理？（`chromatic_aberration` 的 samples 默认可控）
- [ ] 是否有不必要的全屏后处理？（考虑只在需要时挂材质，用完立即清除）
- [ ] 是否有无限循环的 Tween 在节点释放后仍运行？（检查 `auto_kill`）

### 入库检查

- [ ] 新 Tween 是否记入 `tween-library-reference.md` §场景速查？
- [ ] 新 Shader 是否记入 `shader-library-reference.md` §组件表 + §场景速查？
- [ ] 新素材依赖是否记入 `asset_registry.gd` 或相关文档？
- [ ] `shaders/sources/SOURCES.md` 状态是否已更新？

---

## 9. 案例：完整决策演示

### 案例 1：Boss 战入场扰动效果

**需求：** Boss 登场时屏幕出现故障扰动，持续 0.8s 后恢复正常。

**① 效果定性：** 过渡/转场 — 一次性故障效果

**② 查三库：**
- Tween 速查 → 无故障类
- Shader 速查 → §场景速查 有「故障爆发动画」→ `split_glitch_burst()`
- 素材 → 无需额外素材

**③ 评估缺口：** ✅ `split_glitch_burst()` 直接覆盖（内置 `duration` + `peak` 参数）

**④ 方案选择：** 直接调用，零新增

```gdscript
# 在 Boss 登场处添加
await GlobalShaders.split_glitch_burst(screen_node, {duration: 0.8, peak: 0.9})
GlobalShaders.clear_split_glitch(screen_node)
```

**⑤ 入库：** 无需入库（已有）

---

### 案例 2：卡牌受击闪白+抖动

**需求：** 忍者牌受到攻击时，闪白 0.1s + 轻微抖动。

**① 效果定性：** 受击/反馈 — 一次性反馈

**② 查三库：**
- Tween 速查 → `GlobalTweens.flash_color()` + `GlobalTweens.shake()`
- Shader 速查 → 也可用色差，但纯 Tween 更轻量
- 素材 → 无

**③ 评估缺口：** ✅ 两个 Tween API 可组合实现

**④ 方案选择：** 纯 Tween（满足需求，不引入 Shader）

```gdscript
# 并行执行闪白和抖动
var tw := create_tween().set_parallel(true)
tw.tween_callback(func(): GlobalTweens.flash_color(card, Color.WHITE, 0.1))
tw.tween_callback(func(): GlobalTweens.shake(card, 0.15, 4.0))
```

**⑤ 入库：** 无需入库（已有）

---

### 案例 3：计分结算时「喜」字金色绽放

**需求：** 每次得分时，喜 Xi 标签从中心放大弹出+金色辉光+轻微上下浮动。

**① 效果定性：** 强调/高亮 + 出现——组合型

**② 查三库：**
- Tween 速查 → `GlobalTweens.xi_flash()` 已存在（喜爆发专有方法）
- Shader 速查 → `apply_glow()` 可加辉光
- 素材 → 无

**③ 评估缺口：** ✅ `xi_flash()` 直接覆盖，或组合 `pop_in()` + `apply_glow()` + `pulse_glow()`

**④ 方案选择：** `xi_flash()` 已封装完整流程

```gdscript
GlobalTweens.xi_flash(xi_label)
```

**⑤ 入库：** 无需入库（已有）

---

### 案例 4：面板背景纸张纹理

**需求：** 结算面板增加发黄的纸张纹理质感。

**① 效果定性：** 氛围/滤镜 — 持续效果

**② 查三库：**
- Tween 速查 → 无相关
- Shader 速查 → 无 paper_style（标注为 Tier 1 待接入）
- 素材 → 需要纸张纹理贴图或噪声 shader

**③ 评估缺口：** 🔴 全新需求（shaderlist 有 `paper_style.gdshader` 但未接入）

**④ 方案选择：** 新建 `PaperStyleFX` 子系统

```gdscript
# 接入 paper_style.gdshader
# 创建 PaperStyleFX → GlobalShaders.apply_paper_style(panel, params)
```

**⑤ 入库：** 需要完整入库流程：
- 复制 `paper_style.gdshader` → `shaders/filters/paper_style.gdshader`
- 新建 `paper_style_fx.gd` → 注册到 `GlobalShaders`
- `SOURCES.md` 标记 ✅
- `shader-library-reference.md` §组件表 + §场景速查 追加

---

## 10. 速查卡片

> 设计时拿不准，看这里。

### 效果查库路线

```
效果类型 → 优先查 Tween 库 → 不够再查 Shader 库 → 还不够再看素材
```

### 方案选择优先级

```
纯 Tween > Tween + Shader（新建 *_fx 子系统） > 新 shader + 新素材
```

### 一致性三问

1. ✋ **所有按钮走 `ButtonStyles` 了吗？**
2. 🔲 **纹理 9 宫格 8px + NEAREST 过滤了吗？**
3. 🗑️ **用完 remove_all_shaders / cleanup 了吗？**

### 入库存根

新增效果后：
- `docs/tween-library-reference.md` → §场景速查 追加行
- `docs/shader-library-reference.md` → §组件表 + §场景速查 追加行
- `shaders/sources/SOURCES.md` → 状态列 ✅
- `docs/design-decision-framework.md` → §7 映射表 追加行
