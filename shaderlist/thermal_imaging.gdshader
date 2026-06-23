shader_type canvas_item;

// 热成像温度范围参数（滑条控制，支持可视化调试）
uniform float temperature_min : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float temperature_max : hint_range(0.0, 2.0, 0.01) = 1.0;

// ITU BT.709 标准亮度公式（保留精准温度计算）
float luminance_bt709(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// 恢复简洁版核心颜色节点（黑→蓝→青→黄→红→白），对比强烈更"好看"
vec4 thermal_gradient(float t) {
    t = clamp(t, 0.0, 1.0);
    
    if (t < 0.2) {
        // 0.0 - 0.2：黑 → 深蓝（简洁版核心节点）
        return mix(vec4(0.0, 0.0, 0.0, 1.0), vec4(0.0, 0.0, 0.8, 1.0), t / 0.2);
    } else if (t < 0.4) {
        // 0.2 - 0.4：深蓝 → 青（简洁版核心节点）
        return mix(vec4(0.0, 0.0, 0.8, 1.0), vec4(0.0, 0.8, 0.8, 1.0), (t - 0.2) / 0.2);
    } else if (t < 0.6) {
        // 0.4 - 0.6：青 → 黄（简洁版核心节点）
        return mix(vec4(0.0, 0.8, 0.8, 1.0), vec4(1.0, 1.0, 0.0, 1.0), (t - 0.4) / 0.2);
    } else if (t < 0.8) {
        // 0.6 - 0.8：黄 → 红（简洁版核心节点）
        return mix(vec4(1.0, 1.0, 0.0, 1.0), vec4(1.0, 0.1, 0.1, 1.0), (t - 0.6) / 0.2);
    } else {
        // 0.8 - 1.0：红 → 白（简洁版核心节点）
        return mix(vec4(1.0, 0.1, 0.1, 1.0), vec4(1.0, 1.0, 1.0, 1.0), (t - 0.8) / 0.2);
    }
}

void fragment() {
    // 获取原始纹理颜色
    vec4 original_color = texture(TEXTURE, UV);
    
    // 使用 ITU BT.709 标准计算温度（保留精准度）
    float temperature = luminance_bt709(original_color.rgb);
    
    // 归一化温度（带除零保护，避免画面异常）
    float temp_range = max(temperature_max - temperature_min, 0.001);
    temperature = (temperature - temperature_min) / temp_range;
    temperature = clamp(temperature, 0.0, 1.0);
    
    // 应用简洁版热成像颜色渐变
    vec4 thermal_color = thermal_gradient(temperature);
    
    // 输出最终颜色（保留原始透明度）
    COLOR = thermal_color;
    COLOR.a = original_color.a; // 新增：保留图片/精灵的透明区域（如 PNG 透明背景）
}