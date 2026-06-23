# Shader 外部来源清单

> 本目录存放从外部 shader 库复制的原始 .gdshader 文件。
> **不直接使用** — 集成到项目时从 `shaders/effects/` / `shaders/filters/` 加载。
>
> 最后更新: 2026-06-23 | S8 清理完成: 删除 shaderlib/ 3 未用 + sources/ 2 已覆盖

| 文件 | 来源 | 引入依据 | 状态 |
|------|------|---------|------|
| `ripple.gdshader` | shaderlist 项目 | Phase K K0c — 待引入 `shaders/effects/ripple.gdshader` | ⬜ 待定 |
| `chromatic_aberration.gdshader` | shaderlist 项目 | `shaders/effects/chromatic_aberration.gdshader` + `ChromaticAberrationFX` | ✅ 已完成 |
| `grayscale.gdshader` | shaderlist 项目 | 并入 `shaders/filters/multi_filter.gdshader` (mode=0) | ✅ 已完成 |
| `vignette.gdshader` | shaderlist 项目 | 并入 `shaders/filters/multi_filter.gdshader` (mode=1) | ✅ 已完成 |
| `color_overlay.gdshader` | shaderlist 项目 | 并入 `shaders/filters/multi_filter.gdshader` (mode=2) | ✅ 已完成 |
| `split_glitch.gdshader` | shaderlist 项目 | `shaders/effects/split_glitch.gdshader` + `SplitGlitchFX` | ✅ 已完成 |
| `pixel_explosion.gdshader` | shaderlist 项目 | `shaders/effects/pixel_explosion.gdshader` + `PixelExplosionFX` | ✅ 已完成 |
| `liquid_distortion.gdshader` | shaderlist 项目 | Phase K K2c — 按需引入 | ⬜ 待定 |
| `wave.gdshader` | shaderlist 项目 | Phase K K2c — 按需引入 | ⬜ 待定 |

## 引入流程

1. 从 `sources/` 复制 .gdshader → `shaders/effects/` 或 `shaders/filters/`
2. 检查 Godot 4.6 `source_color` / `hint_range` 语法兼容性
3. 新建/扩展 `scripts/shader/*_fx.gd` 子系统
4. `global_shaders.gd` 注册 API
5. 更新 `SOURCES.md` 状态列

## 已删除的 shader

| 文件 | 原因 | 删除日期 |
|------|------|---------|
| `shaderlib/2d_holographic_card_shader.gdshader` | 与 fake3d 双重透视冲突，无使用场景 | 2026-06-23 |
| `shaderlib/balatro_card_hover.gdshader` | 被 CardTilt 系统覆盖，无使用场景 | 2026-06-23 |
| `shaderlib/balatro_foil_card_effect.gdshader` | 被 fake3d_flash 覆盖，无使用场景 | 2026-06-23 |
| `shaderlib/card_shadow_pseudo_3d_shader.gdshader` | 被 fake3d_shadow 覆盖，无使用场景 | 2026-06-23 |
| `robust_shine.gdshader` | 被 fake3d_flash 增强后覆盖，源文件已删 | 2026-06-23 |
| `blink.gdshader` | 被 GlowFX emissive_mode 覆盖，源文件已删 | 2026-06-23 |
| `shaders/card_glow.gdshader.uid` | 迁移残留文件，本体已无 | 2026-06-23 |
