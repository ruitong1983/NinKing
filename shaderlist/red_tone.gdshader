shader_type canvas_item;

// 红色滤镜强度 (0.0 - 5.0)
uniform float tint_strength : hint_range(0.0, 10.0, 0.01) = 0.8;
// 阴影区域蓝色抑制强度 (0.0 - 1.0)
uniform float shadow_blue_suppress : hint_range(0.0, 1.0, 0.01) = 0.5;
// 对比度 S 曲线强度 (0.0 - 2.0)
uniform float contrast_s_curve : hint_range(0.0, 5.0, 0.01) = 1.1;
// 新增：着色混合曲线控制 (0.5 - 3.0)
uniform float tint_curve : hint_range(0.5, 3.0, 0.01) = 1.2;
// 新增：肤色保护强度 (0.0 - 1.0)
uniform float skin_tone_protection : hint_range(0.0, 5.0, 0.01) = 0.3;

// 辅助函数：应用 S 曲线对比度
float curve(float x, float c) {
    if (abs(c-1.0)<0.001) return x;
    float a = 0.5 * pow(2.0, 2.0 * (c - 1.0));
    return clamp(x * (1.0 + x * a) / (1.0 + x * a - a), 0.0, 1.0);
}

// 新增：智能混合因子计算
float calculate_tint_blend(float strength, float luma) {
    // 使用曲线控制混合强度，避免线性过度
    float base_blend = strength * 0.6; // 保持原有的基础系数
    
    // 根据亮度动态调整混合强度
    // 中间调区域着色更强，高光和阴影区域着色较弱
    float luma_adjust = 1.0 - abs(luma - 0.5) * 1.5; // 中间调增强
    luma_adjust = clamp(luma_adjust, 0.3, 1.0);
    
    // 应用曲线控制
    float curved_blend = pow(base_blend, 1.0 / tint_curve);
    
    return curved_blend * luma_adjust;
}

// 新增：肤色检测和保护
float detect_skin_tone(vec3 color) {
    // 基于常见肤色范围的简单检测
    vec3 hsv = vec3(0.0);
    
    // RGB转HSV的简化版本
    float max_rgb = max(color.r, max(color.g, color.b));
    float min_rgb = min(color.r, min(color.g, color.b));
    float delta = max_rgb - min_rgb;
    
    // 计算色调（简化）
    float hue = 0.0;
    if (delta > 0.0) {
        if (max_rgb == color.r) {
            hue = (color.g - color.b) / delta;
        } else if (max_rgb == color.g) {
            hue = 2.0 + (color.b - color.r) / delta;
        } else {
            hue = 4.0 + (color.r - color.g) / delta;
        }
        hue = mod(hue * 60.0, 360.0);
        if (hue < 0.0) hue += 360.0;
    }
    
    // 检测肤色范围（橙黄色调）
    float skin_mask = 0.0;
    if (hue >= 15.0 && hue <= 45.0) { // 典型肤色色调范围
        float saturation = (max_rgb - min_rgb) / max_rgb;
        if (saturation > 0.1 && saturation < 0.8) { // 合理的饱和度范围
            skin_mask = 1.0 - smoothstep(0.1, 0.3, abs(hue - 30.0) / 30.0);
        }
    }
    
    return skin_mask;
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec3 color = original_color.rgb;
    
    // --- 1. 对比度 S 曲线调整 ---
    color.r = curve(color.r, contrast_s_curve);
    color.g = curve(color.g, contrast_s_curve);
    color.b = curve(color.b, contrast_s_curve);
    
    // --- 2. 肤色检测 ---
    float skin_mask = detect_skin_tone(color);
    
    // --- 3. 核心红色调着色 ---
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    
    // 目标红色调：偏暖的橘红色
    vec3 target_red = vec3(1.0, 0.4, 0.1); 
    
    // 智能混合因子计算（替换硬编码的 tint_strength * 0.6）
    float tint_blend = calculate_tint_blend(tint_strength, luma);
    
    // 基础着色
    vec3 tinted_color = mix(
        color,
        color * target_red * (1.0 + luma * 0.5),
        tint_blend
    );
    
    // --- 4. 肤色保护 ---
    if (skin_tone_protection > 0.0 && skin_mask > 0.0) {
        float protection = skin_mask * skin_tone_protection;
        // 在肤色区域减少红色调影响
        tinted_color = mix(tinted_color, color, protection * 0.5);
        // 特别保护肤色的自然感，减少过度红化
        tinted_color.g = mix(tinted_color.g, color.g, protection * 0.7);
        tinted_color.b = mix(tinted_color.b, color.b, protection * 0.3);
    }
    
    // --- 5. 阴影互补色抑制 ---
    float shadow_mask = 1.0 - smoothstep(0.0, 0.4, luma);
    
    // 改进的阴影蓝色抑制：保持阴影细节
    float blue_reduction = shadow_mask * shadow_blue_suppress * 0.8;
    
    // 在阴影区域应用蓝色抑制，但保护最暗部分的细节
    float shadow_detail = smoothstep(0.0, 0.15, luma);
    blue_reduction *= shadow_detail;
    
    tinted_color.b = max(tinted_color.b - blue_reduction, 0.0);
    
    // --- 6. 最终微调 ---
    // 确保颜色不会过度饱和
    float max_component = max(tinted_color.r, max(tinted_color.g, tinted_color.b));
    if (max_component > 1.0) {
        tinted_color /= max_component;
    }
    
    COLOR = vec4(tinted_color, original_color.a);
}