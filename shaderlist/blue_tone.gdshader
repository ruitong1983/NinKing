shader_type canvas_item;

// 统一变量：蓝调的强度 (对阴影的影响程度)
uniform float blue_tone_strength : hint_range(0.0, 5.0) = 0.6;

// 统一变量：阴影的颜色分量 (用于混合的蓝色/青色调)
uniform float shadow_tint_color_r : hint_range(0,1) = 0.1;
uniform float shadow_tint_color_g : hint_range(0,1) = 0.2;
uniform float shadow_tint_color_b : hint_range(0,1) = 0.3;

// 统一变量：黑场提升 (Lift Shadows) - 模拟胶片褪色，提升暗部亮度。
uniform float shadow_lift : hint_range(0.0, 1.0) = 0.05;

// 辅助函数：计算图像亮度 (Luminance)
float get_luminance(vec3 color) {
    // ITU-R BT.709 标准加权
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    vec3 color = base_color.rgb;

    // 1. 亮度分离与分色调 (Split Toning)

    float lum = get_luminance(color);

    // a. 提升阴影 (Shadow Lift / Fade)
    color = color + shadow_lift;

    // b. 混合因子：使用平滑步进函数 (smoothstep)
    // 确保混合平滑地过渡。我们将让阴影 (lum < 0.5) 混合蓝色。
    // smoothstep(min, max, value)
    // 这里我们将 lum 从 0.4 到 0.6 之间平滑过渡，低于 0.4 时混合因子为 1 (全蓝)，高于 0.6 时为 0 (全原色)。
    float mix_factor = 1.0 - smoothstep(0.4, 0.6, lum);

    // c. 从分量构建阴影颜色
    vec3 shadow_tint_color = vec3(shadow_tint_color_r, shadow_tint_color_g, shadow_tint_color_b);

    // d. 应用蓝调：将原始颜色向阴影目标颜色混合
    // 阴影区域 (mix_factor 接近 1.0) 会被染蓝
    color = mix(color, shadow_tint_color, mix_factor * blue_tone_strength);

    // 2. 钳制颜色并输出
    color = clamp(color, 0.0, 1.0);

    COLOR = vec4(color, base_color.a);
}