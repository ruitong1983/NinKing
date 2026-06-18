# Shader 外部来源清单

> 本目录存放从外部 shader 库复制的原始 .gdshader 文件。
> **不直接使用** — 集成到项目时从 `shaders/effects/` / `shaders/filters/` 加载。

| 文件 | 来源 | 引入依据 | 状态 |
|------|------|---------|------|
| `robust_shine.gdshader` | shaderlist 项目 | Phase K K0a — **已决定不引入**，改扩展现有 `fake3d_flash.gdshader` | ⏸️ 参考 |
| `blink.gdshader` | shaderlist 项目 | Phase K K0b — **已决定不引入**，改扩展 GlowFX `emissive_add` 模式 | ⏸️ 参考 |
| `ripple.gdshader` | shaderlist 项目 | Phase K K0c — 待引入 `shaders/effects/ripple.gdshader` | ⬜ 待复制 |
| `chromatic_aberration.gdshader` | shaderlist 项目 | Phase K K1b — 待引入 `shaders/effects/chromatic_aberration.gdshader` | ⬜ 待复制 |
| `grayscale.gdshader` | shaderlist 项目 | Phase K K1a — 并入 `multi_filter.gdshader` (mode=0) | ⬜ 待合并 |
| `vignette.gdshader` | shaderlist 项目 | Phase K K1a — 并入 `multi_filter.gdshader` (mode=1) | ⬜ 待合并 |
| `color_overlay.gdshader` | shaderlist 项目 | Phase K K1a — 并入 `multi_filter.gdshader` (mode=2) | ⬜ 待合并 |
| `split_glitch.gdshader` | shaderlist 项目 | Phase K K2a — 待引入 `shaders/effects/split_glitch.gdshader` | ⬜ 待复制 |
| `pixel_explosion.gdshader` | shaderlist 项目 | Phase K K2b — 待引入 `shaders/effects/pixel_explosion.gdshader` | ⬜ 待复制 |
| `liquid_distortion.gdshader` | shaderlist 项目 | Phase K K2c — 按需引入 | ⬜ 待定 |
| `wave.gdshader` | shaderlist 项目 | Phase K K2c — 按需引入 | ⬜ 待定 |

## 引入流程

1. 从 `sources/` 复制 .gdshader → `shaders/effects/` 或 `shaders/filters/`
2. 检查 Godot 4.6 `source_color` / `hint_range` 语法兼容性
3. 新建/扩展 `scripts/shader/*_fx.gd` 子系统
4. `global_shaders.gd` 注册 API
5. 更新 `SOURCES.md` 状态列
