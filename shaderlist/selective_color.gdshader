shader_type canvas_item;

// ---- 颜色模式参数 ----
uniform vec3 target_color : source_color = vec3(1.0, 0.0, 0.0); // 目标颜色（默认红色）
uniform float hue_tolerance : hint_range(0.0, 1.0) = 0.2;      // 颜色匹配容差
uniform float saturation_threshold : hint_range(0.0, 1.0) = 0.3; // 饱和度阈值
uniform float effect_strength : hint_range(0.0, 1.0) = 1.0;     // 效果强度

// 浮点数比较阈值
const float FLOAT_EPS = 1e-5;

// 计算颜色的饱和度
float get_saturation(vec3 c) {
    float max_c = max(c.r, max(c.g, c.b));
    float min_c = min(c.r, min(c.g, c.b));
    float delta = max_c - min_c;
    // 使用阈值判断最大值是否接近零，避免除零错误
    return abs(max_c) < FLOAT_EPS ? 0.0 : delta / max_c;
}

// 计算颜色的色相（简化版本）
float get_hue(vec3 c) {
    float max_c = max(c.r, max(c.g, c.b));
    float min_c = min(c.r, min(c.g, c.b));
    float delta = max_c - min_c;
    
    if (abs(delta) < FLOAT_EPS) return 0.0;
    
    float hue;
    // 使用阈值判断哪个颜色通道与最大值相等
    if (abs(max_c - c.r) < FLOAT_EPS) {
        hue = (c.g - c.b) / delta;
    } else if (abs(max_c - c.g) < FLOAT_EPS) {
        hue = 2.0 + (c.b - c.r) / delta;
    } else {
        hue = 4.0 + (c.r - c.g) / delta;
    }
    
    hue *= 60.0;
    if (hue < 0.0) hue += 360.0;
    
    return hue / 360.0; // 归一化到 [0, 1]
}

void fragment() {
    // 1. 获取原始颜色
    vec4 original_color = texture(TEXTURE, UV);
    vec3 rgb = original_color.rgb;
    
    // 2. 计算灰度值（使用亮度公式）
    float gray = dot(rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(gray);
    
    // 3. 计算颜色模式混合因子
    float blend_factor = 0.0;
    
    // 计算当前像素颜色与目标颜色的色相差
    float pixel_hue = get_hue(rgb);
    float target_hue = get_hue(target_color);
    float hue_diff = abs(pixel_hue - target_hue);
    hue_diff = min(hue_diff, 1.0 - hue_diff); // 处理色相环的循环
    
    // 获取当前像素的饱和度
    float sat = get_saturation(rgb);
    
    // 判断是否保留彩色：色相近且饱和度高
    if (abs(hue_diff) < hue_tolerance && sat > saturation_threshold) {
        blend_factor = 1.0;
    } else {
        blend_factor = 0.0;
    }
    
    // 4. 混合彩色和灰度结果
    vec3 final_color = mix(grayscale, rgb, blend_factor);
    
    // 5. 应用整体效果强度
    final_color = mix(original_color.rgb, final_color, effect_strength);
    
    COLOR = vec4(final_color, original_color.a);
} 