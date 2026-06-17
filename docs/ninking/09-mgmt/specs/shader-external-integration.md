# Phase J — 外部 Shader 资源集成方案

> 审阅日期: 2026-06-17 | 状态: ✅ 审阅通过 | 关联: `shader-library-reference.md`, `fake3d_flash.gdshader`, `dissolve2d.gdshader`, `shaders/shaderlib/`, `addons/shaderV/`

## 背景

项目已引入 3 个外部 Shader 来源：
1. **ShaderLib 插件** (`addons/shader_library/`) — godotshaders.com 浏览器，已下载 4 个 .gdshader 到 `shaders/shaderlib/`
2. **ShaderV 插件** (`addons/shaderV/`) — VisualShader 节点库 + ~80 个 .gdshaderinc 工具函数
3. **gdquest-demos/godot-shaders** — 已集成 `baked_sprite_glow` + `outline2D_inner_outer`

GlobalShaders 框架已建好（4 子系统：EdgeFade/Dissolve/Glow/Outline），但外部资源中仍有高价值算法未被利用。

## 资产全景

| 来源 | 文件 | 状态 | 评估 |
|------|------|------|------|
| **项目自有** | `fake3d/fake3d.gdshader` | 使用中 | 卡牌 3D 透视，不归 GlobalShaders |
| **项目自有** | `fake3d/fake3d_flash.gdshader` | 使用中 | 稀有度闪光，3 种 flash_type（纯色/彩虹/渐变） |
| **项目自有** | `fake3d/fake3d_shadow.gdshader` | 未接入 | — |
| **项目自有** | `fake3d/dissolve2d.gdshader` | 使用中 | 溶解燃烧，依赖外部噪声纹理 |
| **项目自有** | `panel_edge_fade.gdshader` | 使用中 | — |
| **gdquest** | `baked_sprite_glow.gdshader` | 使用中 | GlowFX 子系统 |
| **gdquest** | `outline2D_inner_outer.gdshader` | 使用中 | OutlineFX 子系统 |
| **ShaderLib** | `shaderlib/balatro_foil_card_effect.gdshader` | 待集成 | **有机箔片闪光算法** → 作为 flash_type=3 并入 fake3d_flash |
| **ShaderLib** | `shaderlib/2d_holographic_card_shader.gdshader` | 待评估 | Phase 3：全息卡（与 fake3d vertex 冲突） |
| **ShaderLib** | `shaderlib/balatro_card_hover.gdshader` | **跳过** | Vertex 冲突，card-framework 已覆盖悬停 |
| **ShaderLib** | `shaderlib/card_shadow_pseudo_3d.gdshader` | **跳过** | 过度工程，当前阴影够用 |
| **ShaderV** | `rgba/noise/generic2d.gdshaderinc` | **改用简化方案** | 见 §2.2 |
| **ShaderV** | `rgba/chromaticAberration.gdshaderinc` | Phase 2 | Boss 揭示 VFX |
| **ShaderV** | `rgba/blurCustom.gdshaderinc` | Phase 2 | 过渡 VFX |

## 方案（审阅修正版）

### Phase 1a — 箔片闪光增强（~4h）

**目标：** 将 `balatro_foil_card_effect.gdshader` 的有机液态箔片算法作为新的 `flash_type` 并入 `fake3d_flash.gdshader`，提升传说级稀有度卡牌质感。

**改动文件：**
- `shaders/fake3d/fake3d_flash.gdshader` — 新增 `flash_type = 3`（有机箔片）

**具体实施：**

1. 新增 `group_uniforms foil_uniforms` 包装 9 个新 uniform + 4 个 sampler2D：
   ```glsl
   group_uniforms foil_uniforms;
   uniform vec3 foilcolor : source_color;
   uniform float threshold : hint_range(0.0, 2.0, 0.1) = 0.1;
   uniform float fuzziness : hint_range(0.0, 1.0, .01) = 0.1;
   uniform float foil_period = 1.0;
   uniform float foil_scroll = 1.0;
   uniform float effect_alpha_mult : hint_range(0, 1) = 1.0;
   uniform float foil_direction : hint_range(0, 1.0) = 0.5;
   uniform sampler2D foil_mask;
   uniform sampler2D foil_gradient;
   uniform sampler2D foil_noise;
   uniform sampler2D foil_normal_map;
   ```

2. 在 `fragment()` 开头声明统一时间基准：
   ```glsl
   float _flash_time = TIME * move_speed * speed;
   ```

3. 移植箔片算法的 `effect()` 函数（~25 行三角函数链），注意：
   - **不修改 alpha** — 仅对 COLOR.rgb 作用，alpha 保留 fake3d_flash 原有的裁剪逻辑
   - 使用 `_flash_time` 而非直接引用 `TIME`
   - 采样器都加 `: filter_linear` 标记

4. 默认值：`flash_type=3` 时 `use_flash=true` 自动激活

**配置文件：**
- `fake3d_legendary.tres` — `flash_type=3, intensity=0.8, move_speed=0.5`

**向后兼容：** `flash_type=0/1/2` 不受影响，统一份新增 uniform 的默认值

**验证：**
- [ ] 传说卡 side-by-side 对比新旧箔片效果
- [ ] uncommon/rare 的 flash_type=0/2 无退化
- [ ] GL Compatibility 编译通过
- [ ] uniform 总数在 `gl_MaxFragmentUniformVectors` 限制内

---

### Phase 1b — 溶解动画增强（~2h，简化版）

**目标：** 让 dissolve 燃烧效果具备动态火焰飘动感，但用 UV 滚动替代完整的程序化噪声嵌入（避免 3 倍 shader 膨胀）。

**改动文件：**
- `shaders/fake3d/dissolve2d.gdshader`
- `scripts/shader/dissolve_fx.gd`

**具体实施：**

1. `dissolve2d.gdshader` 加均匀：
   ```glsl
   uniform float noise_scroll_speed : hint_range(0.0, 2.0, 0.01) = 0.0;
   ```

2. `fragment()` 噪声纹理采样改为：
   ```glsl
   vec2 noise_uv = UV + vec2(0.0, TIME * noise_scroll_speed);
   vec4 noise_texture = texture(dissolve_texture, noise_uv);
   ```

3. `DissolveFX.apply()` 接收 `params["noise_scroll_speed"]` 透传到材质

4. `GlobalShaders.dissolve_out()` 默认传 `{noise_scroll_speed: 0.5}` 启用动态

**验证：**
- [ ] scroll=0 时效果与原版完全一致
- [ ] scroll=0.5 时燃烧火焰有上下飘动感
- [ ] 所有存量调用点不传 `noise_scroll_speed`，默认 0，无退化

---

### Phase 2 — 色差/Blur 工具 VFX（~4h，G/F1 完成后插空）

**目标：** 创建可复用的 `.gdshaderinc` 工具集，用于 Boss 揭示和过渡特效。

**改动文件：**
- `shaders/utils/chromatic_aberration.gdshaderinc`（新建）
- `shaders/effects/boss_reveal.gdshader`（新建）
- 可选：`shaders/utils/gaussian_blur.gdshaderinc`（新建）

**注意：** 项目目前零处使用 `#include`，需先创建最小验证：
```
shaders/test_include.gdshader → #include "res://addons/shaderV/tools/remap.gdshaderinc"
```
确认 `#include` 在 `canvas_item` + GL Compatibility 下编译通过。

**具体实施：**
1. 从 ShaderV 复制 `chromaticAberration.gdshaderinc` 到 `shaders/utils/`（剥离不必要的 `textureLod` 分支）
2. 新建 `shaders/effects/boss_reveal.gdshader`：
   ```glsl
   shader_type canvas_item;
   #include "res://shaders/utils/chromatic_aberration.gdshaderinc"
   // 含 uniform radius / intensity 参数
   // fragment() 内通过 UV 偏移 + TIME 驱动色差
   ```
3. 可选通过 `GlobalShaders` 注册或直接 `create_material_from_path()` 使用

**验证：**
- [ ] `#include` 编译通过
- [ ] Boss 揭幕时色差效果平滑
- [ ] 不影响现有卡牌/UI shader

---

### Phase 3 — 全息卡牌（待设计，Phase D 封印/牌组重设计后再评估）

**核心冲突：** `fake3d.gdshader` 和 `2d_holographic_card_shader.gdshader` 都有 `vertex()` 变换，不能共存。

**推荐路径：** 节点分层（叠两个 TextureRect）
- 底层：`fake3d.gdshader` 负责 3D 透视 + 阴影
- 上层：`holographic.gdshader` 负责箔片流光（透明通道开放区）
- 通过 `use_parent_material` 或自定义材质穿透

**前提条件：** 等 Phase D（封印/牌组重新设计）决定是否引入「全息」作为新稀有度 tier 后再实施。

## 不集成说明

| 资源 | 原因 |
|------|------|
| `balatro_card_hover.gdshader` | vertex 变换与 fake3d 冲突，card-framework 的 `hover_scale` + `hover_distance` 已覆盖悬停反馈 |
| `card_shadow_pseudo_3d.gdshader` | 过度工程（~280 行），当前 `fake3d_shadow` 阴影方案满足需求 |
| ShaderV 完整噪声嵌入 | UV 滚动方案（5 行）与程序化噪声（+44 行）效果等价，选择更轻量的简化方案 |

## 风险与对策

| 风险 | 概率 | 影响 | 对策 |
|------|------|------|------|
| fake3d_flash uniform 超限 | 低 | 编译失败 | 用 `group_uniforms` 包裹箔片参数，GL Compat 实测 |
| `#include` 路径问题 | 中 | 编译失败 | Phase 2 前创建最小验证 shader |
| 箔片纹理采样性能 | 低 | 掉帧 | 4 个 sampler2D 加 `: filter_linear`，不加载过大纹理 |
| 现有 dissolve 调用不传噪滚动参数 | 低 | 无退化 | `noise_scroll_speed` 默认 0，无感知变化 |

## 工作量汇总

| Phase | 内容 | 工作量 | 依赖 |
|-------|------|--------|------|
| 1a | 箔片闪光增强 | ~4h | 无 |
| 1b | 溶解 UV 滚动 | ~2h | 无 |
| 2 | 色差/Blur VFX 工具 | ~4h | G/F1 完成后 |
| 3 | 全息卡牌 | 待设计 | Phase D 牌组重设计后评估 |
| **合计** | | **~10h（Phase 1-2）** | |

## 文档同步

实施后需更新：
- `docs/shader-library-reference.md` §3.1 目录结构（加 `shaders/utils/`、`shaders/effects/`）
- `docs/shader-library-reference.md` §5.1 工作流（加 `#include` 路径验证步骤）
- `docs/shader-library-reference.md` §5.3 外部库手册（ShaderLib/ShaderV 使用说明）
- `shaders/shaderlib/` 中未使用文件加注释头标记 `// @status: NOT_INTEGRATED - kept as reference`
